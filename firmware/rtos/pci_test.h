#ifndef PCI_TEST_H
#define PCI_TEST_H

#include <stdint.h>

/* SmartEth PCI device IDs */
#define SMARTETH_VENDOR_ID  0x1efd
#define SMARTETH_DEVICE_ID  0x0001

/* RISC-V virt machine PCIe ECAM base */
#define PCIE_ECAM_BASE      0x30000000UL
#define PCIE_ECAM_BUS_SHIFT 20
#define PCIE_ECAM_DEV_SHIFT 15
#define PCIE_ECAM_FUNC_SHIFT 12

/* MMIO register offsets */
#define REG_CTRL       0x000
#define REG_STATUS     0x004
#define REG_IRQ_EN     0x008
#define REG_IRQ_STS    0x00C
#define REG_MAC_LO     0x010
#define REG_MAC_HI     0x014
#define REG_SCRATCH0   0x020
#define REG_DMA_SRC    0x040
#define REG_DMA_DST    0x048
#define REG_DMA_LEN    0x050
#define REG_DMA_CTRL   0x058
#define REG_DMA_STS    0x05C
#define REG_DEV_ID     0x100
#define REG_IRQ_TEST   0x200

/* Control bits */
#define CTRL_RESET      0x00000001

/* Status bits */
#define STATUS_READY    0x00000001
#define STATUS_DMA_BSY  0x00000002

/* IRQ bits */
#define IRQ_DMA_DONE    0x00000001
#define IRQ_TEST        0x00000002

/* DMA control */
#define DMA_START       0x00000001

/* PCI config register offsets */
#define PCI_VENDOR_ID   0x00
#define PCI_DEVICE_ID   0x02
#define PCI_COMMAND     0x04
#define PCI_BAR0        0x10
#define PCI_BAR1        0x18  /* MSI-X table bar */

/* Test result codes */
typedef enum {
    PCI_TEST_PASS = 0,
    PCI_TEST_FAIL = -1,
} pci_test_result_t;

/**
 * Scan PCIe bus 0 for SmartEth device.
 * Returns BAR0 base address, or 0 if not found.
 */
uint64_t smarteth_pci_scan(void);

/**
 * Read a 32-bit register via BAR0 MMIO.
 */
uint32_t smarteth_reg_read(uint64_t bar0, uint32_t offset);

/**
 * Write a 32-bit register via BAR0 MMIO.
 */
void smarteth_reg_write(uint64_t bar0, uint32_t offset, uint32_t val);

/**
 * Run all PCIe device tests.
 * Returns 0 on success, -1 on failure.
 */
int smarteth_run_tests(uint64_t bar0);

#endif /* PCI_TEST_H */
