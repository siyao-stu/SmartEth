/*
 * SmartEth RISC-V Smart NIC PCIe device (QEMU QOM)
 *
 * PCIe endpoint function simulating a Smart NIC.
 * Provides:
 *   - BAR0: 4KB MMIO register space
 *   - BAR1: MSI-X table (via msix_init_exclusive_bar)
 *   - 2 MSI-X vectors (DMA complete, interrupt test)
 *   - DMA engine with timer-based transfer simulation
 *   - Scratch/test registers for firmware verification
 *
 * Usage:
 *   qemu-system-riscv64 -M virt -m 256M \
 *       -device smarteth \
 *       -kernel smartnic_rtos.elf
 *
 * Copyright (c) 2026 SmartEth Project
 * SPDX-License-Identifier: MIT
 */

#include "qemu/osdep.h"
#include "qemu/log.h"
#include "qemu/units.h"
#include "hw/pci/pci.h"
#include "hw/pci/msi.h"
#include "hw/pci/msix.h"
#include "qemu/timer.h"
#include "qom/object.h"
#include "qemu/module.h"
#include "qemu/main-loop.h"
#include "qapi/visitor.h"

/* ------------------------------------------------------------------ */
/*  Type & macro definitions                                          */
/* ------------------------------------------------------------------ */

#define TYPE_SMARTETH_PCI "smarteth"
OBJECT_DECLARE_SIMPLE_TYPE(SmartEthState, SMARTETH_PCI)

/* MMIO register offsets */
#define REG_CTRL        0x000   /* RW: device control */
#define REG_STATUS      0x004   /* RO: device status */
#define REG_IRQ_EN      0x008   /* RW: interrupt enable mask */
#define REG_IRQ_STS     0x00C   /* RW: interrupt status (W1C) */
#define REG_MAC_LO      0x010   /* RW: MAC address low 32 bits */
#define REG_MAC_HI      0x014   /* RW: MAC address high 16 bits */
#define REG_SCRATCH0    0x020   /* RW: scratch register 0 */
#define REG_SCRATCH1    0x024   /* RW: scratch register 1 */
#define REG_SCRATCH2    0x028   /* RW: scratch register 2 */
#define REG_SCRATCH3    0x02C   /* RW: scratch register 3 */
#define REG_DMA_SRC     0x040   /* RW: DMA source address (guest phys) */
#define REG_DMA_DST     0x048   /* RW: DMA destination address */
#define REG_DMA_LEN     0x050   /* RW: DMA transfer length */
#define REG_DMA_CTRL    0x058   /* WO: DMA control (write 1 to start) */
#define REG_DMA_STS     0x05C   /* RO: DMA status */
#define REG_MSI_ADDR    0x060   /* RO: MSI-X table address (debug) */
#define REG_DEV_ID      0x100   /* RO: returns device identifier */
#define REG_IRQ_TEST    0x200   /* WO: write 1 to trigger test interrupt */

#define REG_COUNT       (0x400 / 4)  /* 256 x 32-bit registers */

/* CTRL register bits */
#define CTRL_RESET      0x00000001
#define CTRL_INT_EN     0x00000002

/* STATUS register bits */
#define STATUS_READY    0x00000001
#define STATUS_DMA_BSY  0x00000002
#define STATUS_DMA_ERR  0x00000004

/* IRQ bits */
#define IRQ_DMA_DONE    0x00000001
#define IRQ_TEST        0x00000002

/* DMA control bits */
#define DMA_START       0x00000001
#define DMA_DIR_READ    0x00000000  /* device reads from guest mem */
#define DMA_DIR_WRITE   0x00000002  /* device writes to guest mem */
#define DMA_IRQ_EN      0x00000004

/* Internal DMA buffer size */
#define DMA_BUF_SIZE    4096

/* Device identification */
#define SMARTETH_DEV_ID 0x52414D53  /* "SMAR" in ASCII (32-bit LE: S M A R) */

/* ------------------------------------------------------------------ */
/*  Device state                                                      */
/* ------------------------------------------------------------------ */

struct SmartEthState {
    PCIDevice pdev;
    MemoryRegion mmio;

    /* Registers */
    uint32_t regs[REG_COUNT];

    /* State */
    bool msix_enabled;

    /* DMA */
    struct {
        uint64_t src;
        uint64_t dst;
        uint32_t len;
        uint32_t ctrl;
    } dma;
    QEMUTimer dma_timer;
    uint8_t dma_buf[DMA_BUF_SIZE];

    /* Property */
    uint8_t mac_addr[6];
};

/* ------------------------------------------------------------------ */
/*  Interrupt helpers                                                 */
/* ------------------------------------------------------------------ */

static bool smarteth_msix_enabled(SmartEthState *s)
{
    return msix_enabled(&s->pdev);
}

static void smarteth_raise_irq(SmartEthState *s, uint32_t bits)
{
    s->regs[REG_IRQ_STS >> 2] |= bits;

    if (smarteth_msix_enabled(s)) {
        /* Use vector 0 for DMA, 1 for test */
        int vec = (bits & IRQ_DMA_DONE) ? 0 : 1;
        msix_notify(&s->pdev, vec);
    } else if (msi_enabled(&s->pdev)) {
        msi_notify(&s->pdev, 0);
    } else {
        pci_set_irq(&s->pdev, 1);
    }
}

/* ------------------------------------------------------------------ */
/*  DMA engine                                                        */
/* ------------------------------------------------------------------ */

static void smarteth_dma_timer_cb(void *opaque)
{
    SmartEthState *s = opaque;
    bool raise = false;

    if (!(s->dma.ctrl & DMA_START)) {
        return;
    }

    if (s->dma.len > DMA_BUF_SIZE) {
        s->dma.len = DMA_BUF_SIZE;
    }

    if (s->dma.ctrl & DMA_DIR_WRITE) {
        /* Device writes to guest memory: copy from internal buffer */
        pci_dma_write(&s->pdev, s->dma.dst, s->dma_buf, s->dma.len);
    } else {
        /* Device reads from guest memory: copy to internal buffer */
        pci_dma_read(&s->pdev, s->dma.src, s->dma_buf, s->dma.len);
    }

    s->dma.ctrl &= ~DMA_START;
    s->regs[REG_DMA_STS >> 2] = 0;  /* clear busy */

    if (s->dma.ctrl & DMA_IRQ_EN) {
        raise = true;
    }

    if (raise) {
        smarteth_raise_irq(s, IRQ_DMA_DONE);
    }
}

static void smarteth_start_dma(SmartEthState *s)
{
    s->dma.src  = s->regs[REG_DMA_SRC >> 2];
    s->dma.dst  = s->regs[REG_DMA_DST >> 2];
    s->dma.len  = s->regs[REG_DMA_LEN >> 2];
    s->dma.ctrl = s->regs[REG_DMA_CTRL >> 2];

    s->regs[REG_DMA_STS >> 2] = STATUS_DMA_BSY;

    /* Simulate DMA with a timer (1ms delay) */
    timer_mod(&s->dma_timer,
              qemu_clock_get_ms(QEMU_CLOCK_VIRTUAL) + 1);
}

/* ------------------------------------------------------------------ */
/*  MMIO access handlers                                              */
/* ------------------------------------------------------------------ */

static uint64_t smarteth_mmio_read(void *opaque, hwaddr addr,
                                   unsigned size)
{
    SmartEthState *s = opaque;
    uint64_t val = 0;

    if (addr >= REG_COUNT * 4) {
        return 0;
    }

    switch (addr) {
    case REG_DEV_ID:
        val = SMARTETH_DEV_ID;
        break;
    case REG_STATUS:
        val = STATUS_READY;
        break;
    default:
        val = s->regs[addr >> 2];
        break;
    }

    return val;
}

static void smarteth_mmio_write(void *opaque, hwaddr addr,
                                uint64_t val, unsigned size)
{
    SmartEthState *s = opaque;

    if (addr >= REG_COUNT * 4) {
        return;
    }

    switch (addr) {
    case REG_CTRL:
        if (val & CTRL_RESET) {
            /* Device reset: clear all regs (except MAC) */
            memset(s->regs, 0, sizeof(s->regs));
            s->regs[REG_MAC_LO >> 2] = (uint32_t)(s->mac_addr[0] |
                (s->mac_addr[1] << 8) | (s->mac_addr[2] << 16) |
                (s->mac_addr[3] << 24));
            s->regs[REG_MAC_HI >> 2] = (uint32_t)(s->mac_addr[4] |
                (s->mac_addr[5] << 8));
            break;
        }
        s->regs[REG_CTRL >> 2] = val;
        break;

    case REG_IRQ_STS:
        /* Write-1-to-clear */
        s->regs[REG_IRQ_STS >> 2] &= ~(uint32_t)val;
        if (!s->regs[REG_IRQ_STS >> 2] && !smarteth_msix_enabled(s)) {
            pci_set_irq(&s->pdev, 0);
        }
        break;

    case REG_DMA_CTRL:
        s->regs[REG_DMA_CTRL >> 2] = (uint32_t)val;
        if (val & DMA_START) {
            smarteth_start_dma(s);
        }
        break;

    case REG_IRQ_TEST:
        if (val) {
            smarteth_raise_irq(s, IRQ_TEST);
        }
        break;

    case REG_STATUS:
    case REG_DEV_ID:
        /* Read-only registers */
        break;

    default:
        s->regs[addr >> 2] = (uint32_t)val;
        break;
    }
}

static const MemoryRegionOps smarteth_mmio_ops = {
    .read  = smarteth_mmio_read,
    .write = smarteth_mmio_write,
    .endianness = DEVICE_NATIVE_ENDIAN,
    .valid = {
        .min_access_size = 4,
        .max_access_size = 8,
    },
    .impl = {
        .min_access_size = 4,
        .max_access_size = 8,
    },
};

/* ------------------------------------------------------------------ */
/*  PCIe device lifecycle                                             */
/* ------------------------------------------------------------------ */

static void smarteth_realize(PCIDevice *pdev, Error **errp)
{
    SmartEthState *s = SMARTETH_PCI(pdev);
    uint8_t *pci_conf = pdev->config;

    /* PCI config space */
    pci_config_set_interrupt_pin(pci_conf, 1);

    /* MMIO region (BAR0) — must register before MSI-X */
    memory_region_init_io(&s->mmio, OBJECT(s), &smarteth_mmio_ops,
                          s, "smarteth-mmio", 4 * KiB);
    pci_register_bar(pdev, 0, PCI_BASE_ADDRESS_SPACE_MEMORY,
                     &s->mmio);

    /* MSI-X: 2 vectors, exclusive BAR (BAR1) */
    if (msix_init_exclusive_bar(pdev, 2, 1, errp)) {
        return;
    }

    /* DMA timer */
    timer_init_ms(&s->dma_timer, QEMU_CLOCK_VIRTUAL,
                  smarteth_dma_timer_cb, s);

    /* Initialize MAC address from property */
    s->regs[REG_MAC_LO >> 2] = (uint32_t)(s->mac_addr[0] |
        (s->mac_addr[1] << 8) | (s->mac_addr[2] << 16) |
        (s->mac_addr[3] << 24));
    s->regs[REG_MAC_HI >> 2] = (uint32_t)(s->mac_addr[4] |
        (s->mac_addr[5] << 8));
}

static void smarteth_exit(PCIDevice *pdev)
{
    SmartEthState *s = SMARTETH_PCI(pdev);

    timer_del(&s->dma_timer);
    msix_uninit_exclusive_bar(pdev);
}

static void smarteth_instance_init(Object *obj)
{
    SmartEthState *s = SMARTETH_PCI(obj);

    /* Default MAC address (52:54:00:12:34:56 = QEMU range) */
    s->mac_addr[0] = 0x52;
    s->mac_addr[1] = 0x54;
    s->mac_addr[2] = 0x00;
    s->mac_addr[3] = 0x12;
    s->mac_addr[4] = 0x34;
    s->mac_addr[5] = 0x56;
}

static void smarteth_class_init(ObjectClass *class, const void *data)
{
    DeviceClass *dc = DEVICE_CLASS(class);
    PCIDeviceClass *k = PCI_DEVICE_CLASS(class);

    k->realize   = smarteth_realize;
    k->exit      = smarteth_exit;
    k->vendor_id = 0x1efd;   /* placeholder vendor ID */
    k->device_id = 0x0001;   /* SmartEth NIC */
    k->revision  = 0x01;
    k->class_id  = PCI_CLASS_NETWORK_ETHERNET;
    set_bit(DEVICE_CATEGORY_NETWORK, dc->categories);
}

static const TypeInfo smarteth_info[] = {
    {
        .name          = TYPE_SMARTETH_PCI,
        .parent        = TYPE_PCI_DEVICE,
        .instance_size = sizeof(SmartEthState),
        .instance_init = smarteth_instance_init,
        .class_init    = smarteth_class_init,
        .interfaces = (const InterfaceInfo[]) {
            { INTERFACE_PCIE_DEVICE },
            { },
        },
    }
};

DEFINE_TYPES(smarteth_info)
