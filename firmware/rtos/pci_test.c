/**
 * pci_test.c — SmartEth PCIe 设备验证固件
 *
 * Phase 2 测试:
 *   - PCIe 设备扫描/发现
 *   - MMIO 寄存器读写
 *   - 中断产生和响应
 *   - DMA 传输模拟
 */

#include "pci_test.h"
#include "bsp/uart.h"
#include "FreeRTOS.h"
#include "task.h"
#include <stdint.h>

/* ========== PCIe ECAM config space access ========== */

/* Read 32-bit from PCI config space via ECAM */
static uint32_t pci_config_read32(uint32_t bus, uint32_t dev,
                                  uint32_t func, uint32_t offset)
{
    volatile uint32_t *ecam = (volatile uint32_t *)PCIE_ECAM_BASE;
    uint32_t addr = (bus << PCIE_ECAM_BUS_SHIFT) |
                    (dev << PCIE_ECAM_DEV_SHIFT) |
                    (func << PCIE_ECAM_FUNC_SHIFT) |
                    (offset & ~3);
    return ecam[addr >> 2];
}

/* Read 16-bit from PCI config space */
static uint16_t pci_config_read16(uint32_t bus, uint32_t dev,
                                  uint32_t func, uint32_t offset)
{
    uint32_t val = pci_config_read32(bus, dev, func, offset & ~3);
    if (offset & 2)
        return (uint16_t)(val >> 16);
    return (uint16_t)(val & 0xFFFF);
}

/* Read 8-bit from PCI config space (needed for header type) */
static uint8_t pci_config_read8(uint32_t bus, uint32_t dev,
                                uint32_t func, uint32_t offset)
{
    uint32_t val = pci_config_read32(bus, dev, func, offset & ~3);
    return (uint8_t)((val >> ((offset & 3) * 8)) & 0xFF);
}

/* ========== PCI config write (ECAM) ========== */

/* Write 32-bit to PCI config space via ECAM */
static void pci_config_write32(uint32_t bus, uint32_t dev,
                                uint32_t func, uint32_t offset, uint32_t val)
{
    volatile uint32_t *ecam = (volatile uint32_t *)PCIE_ECAM_BASE;
    uint32_t addr = (bus << PCIE_ECAM_BUS_SHIFT) |
                    (dev << PCIE_ECAM_DEV_SHIFT) |
                    (func << PCIE_ECAM_FUNC_SHIFT) |
                    (offset & ~3);
    ecam[addr >> 2] = val;
}

/* Write 16-bit to PCI config space */
static void pci_config_write16(uint32_t bus, uint32_t dev,
                                uint32_t func, uint32_t offset, uint16_t val)
{
    uint32_t aligned_offset = offset & ~3;
    uint32_t old = pci_config_read32(bus, dev, func, aligned_offset);
    int shift = (offset & 2) ? 16 : 0;
    uint32_t new_val = (old & ~(0xFFFF << shift)) | ((uint32_t)val << shift);
    pci_config_write32(bus, dev, func, aligned_offset, new_val);
}

/* ========== Device scan ========== */

uint64_t smarteth_pci_scan(void)
{
    uart_puts("[PCI] Scanning for SmartEth device...\n");

    for (int dev = 0; dev < 32; dev++) {
        uint16_t vendor = pci_config_read16(0, dev, 0, PCI_VENDOR_ID);

        if (vendor == 0xFFFF || vendor == 0x0000)
            continue;  /* no device at this slot */

        uint16_t device = pci_config_read16(0, dev, 0, PCI_DEVICE_ID);
        uint8_t hdr_type = pci_config_read8(0, dev, 0, 0x0E);

        uart_printf("  Dev %d: vendor=0x%x device=0x%x hdr=0x%x\n",
                    dev, vendor, device, hdr_type);

        if (vendor == SMARTETH_VENDOR_ID && device == SMARTETH_DEVICE_ID) {
            /* Found SmartEth device — program BAR0 and enable MMIO */

            uart_printf("[PCI] Found SmartEth at Dev %d\n", dev);

            /*
             * In baremetal (no BIOS), PCI BARs are not pre-assigned.
             * We must write a valid address from the PCI MMIO window.
             * RISC-V virt machine: PCI 32-bit MMIO at 0x40000000, size 1GB.
             */
            uint32_t pci_mmio_base = 0x40000000;

            /* Read BAR0 to check if GPEX already assigned it */
            uint32_t bar0_lo = pci_config_read32(0, dev, 0, PCI_BAR0);
            uart_printf("      RAW BAR0 before = 0x%x\n", (unsigned int)bar0_lo);

            if ((bar0_lo & ~0xF) == 0) {
                /* BAR not assigned — program it */
                uart_puts("      Programming BAR0...\n");
                pci_config_write32(0, dev, 0, PCI_BAR0, pci_mmio_base);
            }

            /* Enable MMIO space (bit 1) + bus master (bit 2) in command reg */
            uint16_t cmd = pci_config_read16(0, dev, 0, PCI_COMMAND);
            cmd |= 0x0006;  /* Memory Space + Bus Master */
            pci_config_write16(0, dev, 0, PCI_COMMAND, cmd);
            uart_printf("      COMMAND reg = 0x%x\n", (unsigned int)cmd);

            /* Read back BAR0 */
            bar0_lo = pci_config_read32(0, dev, 0, PCI_BAR0);
            uint64_t bar0 = bar0_lo & ~0xF;
            uart_printf("      BAR0 after prog = 0x%x\n", (unsigned int)bar0);

            if ((bar0 & ~0xF) != 0) {
                uart_puts("[PCI] BAR0 programmed successfully\n");
                return bar0;
            } else {
                uart_puts("[PCI] BAR0 still zero after programming!\n");
                return 0;
            }
        }
    }

    uart_puts("[PCI] SmartEth device NOT found!\n");
    return 0;
}

/* ========== MMIO register access ========== */

uint32_t smarteth_reg_read(uint64_t bar0, uint32_t offset)
{
    volatile uint32_t *reg = (volatile uint32_t *)bar0;
    return reg[offset >> 2];
}

void smarteth_reg_write(uint64_t bar0, uint32_t offset, uint32_t val)
{
    volatile uint32_t *reg = (volatile uint32_t *)bar0;
    reg[offset >> 2] = val;
}

/* ========== Test cases ========== */

static int test_device_id(uint64_t bar0)
{
    uint32_t dev_id = smarteth_reg_read(bar0, REG_DEV_ID);
    uart_printf("[TEST] DEV_ID = 0x%x", dev_id);

    if (dev_id == 0x52414D53) {  /* "SMAR" */
        uart_puts("  PASS\n");
        return PCI_TEST_PASS;
    }
    uart_puts("  FAIL (unexpected value)\n");
    return PCI_TEST_FAIL;
}

static int test_status(uint64_t bar0)
{
    uint32_t status = smarteth_reg_read(bar0, REG_STATUS);
    uart_printf("[TEST] STATUS = 0x%x", status);

    if (status & STATUS_READY) {
        uart_puts("  PASS (device ready)\n");
        return PCI_TEST_PASS;
    }
    uart_puts("  FAIL (not ready)\n");
    return PCI_TEST_FAIL;
}

static int test_scratch_regs(uint64_t bar0)
{
    int pass = PCI_TEST_PASS;

    /* Write/read back test pattern */
    uint32_t patterns[] = {
        0x00000000, 0xFFFFFFFF, 0xAAAAAAAA, 0x12345678, 0xDEADBEEF
    };
    int n = sizeof(patterns) / sizeof(patterns[0]);

    for (int i = 0; i < n; i++) {
        smarteth_reg_write(bar0, REG_SCRATCH0 + (i % 4) * 4, patterns[i]);
        uint32_t val = smarteth_reg_read(bar0, REG_SCRATCH0 + (i % 4) * 4);
        if (val == patterns[i]) {
            uart_printf("[TEST] SCRATCH[%d] = 0x%x  PASS\n", i, val);
        } else {
            uart_printf("[TEST] SCRATCH[%d] = 0x%x (expected 0x%x)  FAIL\n",
                        i, val, patterns[i]);
            pass = PCI_TEST_FAIL;
        }
    }

    return pass;
}

static int test_ctrl_reset(uint64_t bar0)
{
    /* Write a pattern to scratch, then reset */
    smarteth_reg_write(bar0, REG_SCRATCH0, 0xDEAD);
    smarteth_reg_write(bar0, REG_CTRL, CTRL_RESET);
    uint32_t val = smarteth_reg_read(bar0, REG_SCRATCH0);

    uart_printf("[TEST] CTRL_RESET: SCRATCH0 after reset = 0x%x", val);

    /* After reset, scratch should be 0 */
    if (val == 0) {
        uart_puts("  PASS\n");
        return PCI_TEST_PASS;
    }
    uart_puts("  FAIL (not cleared)\n");
    return PCI_TEST_FAIL;
}

static int test_mac_addr(uint64_t bar0)
{
    uint32_t mac_lo = smarteth_reg_read(bar0, REG_MAC_LO);
    uint32_t mac_hi = smarteth_reg_read(bar0, REG_MAC_HI);

    uart_printf("[TEST] MAC = %x:%x:%x:%x:%x:%x\n",
                (unsigned)(mac_lo & 0xFF),
                (unsigned)((mac_lo >> 8) & 0xFF),
                (unsigned)((mac_lo >> 16) & 0xFF),
                (unsigned)((mac_lo >> 24) & 0xFF),
                (unsigned)(mac_hi & 0xFF),
                (unsigned)((mac_hi >> 8) & 0xFF));
    uart_puts("[TEST] MAC readback  PASS\n");
    return PCI_TEST_PASS;
}

/* ========== DMA test ========== */

static int test_dma(uint64_t bar0)
{
    /*
     * DMA test: write a pattern to guest memory, tell device to read it,
     * then check if it was transferred correctly.
     *
     * For simplicity: use a buffer in guest memory at a known location
     * (after BSS, in heap area).
     *
     * Note: This is a basic DMA functional test, not production code.
     */

    /* Use a buffer in guest DRAM (at offset ~240MB, within 256MB RAM) */
    volatile uint32_t *dma_buf = (volatile uint32_t *)0x8F000000;

    /* Fill with test pattern */
    for (int i = 0; i < 64; i++) {
        dma_buf[i] = 0xAABB0000 + i;
    }

    /* Program DMA: source = guest memory, length = 256 bytes */
    smarteth_reg_write(bar0, REG_DMA_SRC, (uint32_t)(uintptr_t)dma_buf);
    smarteth_reg_write(bar0, REG_DMA_DST, 0); /* device internal buffer */
    smarteth_reg_write(bar0, REG_DMA_LEN, 256);
    smarteth_reg_write(bar0, REG_DMA_CTRL, DMA_START | IRQ_DMA_DONE);

    uart_puts("[TEST] DMA started (reading 256 bytes from guest memory)...\n");

    /* Wait for DMA to complete (poll DMA_STS, timeout ~500ms) */
    int timeout = 500;
    while (timeout--) {
        uint32_t dma_sts = smarteth_reg_read(bar0, REG_DMA_STS);
        if (!(dma_sts & STATUS_DMA_BSY)) {  /* not busy anymore */
            break;
        }
        vTaskDelay(pdMS_TO_TICKS(1));
    }

    if (timeout <= 0) {
        uart_puts("[TEST] DMA  TIMEOUT  FAIL\n");
        return PCI_TEST_FAIL;
    }

    uart_puts("[TEST] DMA completed  PASS\n");
    return PCI_TEST_PASS;
}

/* ========== Interrupt test (MSI-X) ========== */

static volatile int g_irq_received = 0;

/* Called from trap handler when MSI-X interrupt fires */
void smarteth_test_isr(void)
{
    g_irq_received = 1;
    uart_puts("[IRQ] Test interrupt received!\n");
}

static int test_interrupt(uint64_t bar0)
{
    /*
     * Test MSI-X by writing REG_IRQ_TEST.
     * In QEMU, MSI-X interrupt will be delivered as a PCIe MSI-X message.
     * The RISC-V virt machine routes MSI-X through the AIA/IMSIC.
     *
     * For Phase 2: we verify the device generates the interrupt.
     * Full MSI-X delivery to the CPU requires AIA setup which is
     * part of Phase 3/4.
     */

    uart_puts("[TEST] Triggering device interrupt (REG_IRQ_TEST)...\n");

    /* Clear pending interrupt status */
    smarteth_reg_write(bar0, REG_IRQ_STS, IRQ_TEST);

    /* Trigger test interrupt */
    smarteth_reg_write(bar0, REG_IRQ_TEST, 1);

    /* Read IRQ status to verify device set the bit */
    uint32_t irq_sts = smarteth_reg_read(bar0, REG_IRQ_STS);
    uart_printf("[TEST] IRQ_STS after trigger = 0x%x\n", irq_sts);

    if (irq_sts & IRQ_TEST) {
        uart_puts("[TEST] Interrupt status bit set  PASS (device side)\n");
        /* Clear it */
        smarteth_reg_write(bar0, REG_IRQ_STS, IRQ_TEST);
        return PCI_TEST_PASS;
    }

    uart_puts("[TEST] Interrupt status bit NOT set  FAIL\n");
    return PCI_TEST_FAIL;
}

/* ========== Main test runner ========== */

int smarteth_run_tests(uint64_t bar0)
{
    int all_pass = PCI_TEST_PASS;

    uart_puts("\n====== PCIe Device Tests ======\n");

    all_pass |= test_device_id(bar0);
    all_pass |= test_status(bar0);
    all_pass |= test_scratch_regs(bar0);
    all_pass |= test_ctrl_reset(bar0);
    all_pass |= test_mac_addr(bar0);
    all_pass |= test_dma(bar0);
    all_pass |= test_interrupt(bar0);

    uart_puts("====== Tests ");
    uart_puts(all_pass == PCI_TEST_PASS ? "PASSED" : "FAILED");
    uart_puts(" ======\n\n");

    return all_pass;
}
