/*
 * smarteth_main.c — SmartEth NIC PCI driver (Phase 4)
 *
 * Minimal PCI network driver for the SmartEth NIC in QEMU.
 * Supports MMIO register access, MSI-X interrupts, DMA descriptor rings,
 * and a sysfs test interface.
 *
 * Usage:
 *   insmod smarteth.ko
 *   echo regs > /sys/devices/pci0000:00/.../test   # register test
 *   echo dma  > /sys/devices/pci0000:00/.../test   # DMA test
 *   echo tx   > /sys/devices/pci0000:00/.../test   # TX packet test
 *   echo intr > /sys/devices/pci0000:00/.../test   # MSI-X test
 */

#include <linux/module.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/dma-mapping.h>
#include <linux/delay.h>
#include <linux/completion.h>
#include <linux/device.h>
#include <linux/io.h>

#define DRV_NAME "smarteth"
#define DRV_VERSION "0.4.0"

/* BAR indices */
#define SMARTETH_BAR_MMIO   0   /* BAR0: 4KB MMIO register space */
#define SMARTETH_BAR_MSIX   1   /* BAR1: MSI-X table (exclusive) */

/* Ring size (must be power of 2) */
#define SMARTETH_RING_SIZE   64
#define SMARTETH_RX_BUF_SIZE 2048

/* Register offsets (must match firmware/rtos/pci_test.h) */
#define REG_CTRL          0x000
#define REG_STATUS        0x004
#define REG_IRQ_EN        0x008
#define REG_IRQ_STS       0x00C
#define REG_MAC_LO        0x010
#define REG_MAC_HI        0x014
#define REG_SCRATCH0      0x020
#define REG_DMA_SRC       0x040
#define REG_DMA_DST       0x048
#define REG_DMA_LEN       0x050
#define REG_DMA_CTRL      0x058
#define REG_DMA_STS       0x05C
#define REG_TX_RING_BASE_LO  0x300
#define REG_TX_RING_BASE_HI  0x304
#define REG_TX_RING_SIZE     0x308
#define REG_TX_DOORBELL      0x30C
#define REG_TX_TAIL          0x310
#define REG_RX_RING_BASE_LO  0x320
#define REG_RX_RING_BASE_HI  0x324
#define REG_RX_RING_SIZE     0x328
#define REG_RX_DOORBELL      0x32C
#define REG_RX_TAIL          0x330
#define REG_DEV_ID        0x100
#define REG_IRQ_TEST      0x200

/* Control bits */
#define CTRL_RESET       0x00000001

/* Status bits */
#define STATUS_READY     0x00000001
#define STATUS_DMA_BSY   0x00000002

/* IRQ bits */
#define IRQ_DMA_DONE     0x00000001
#define IRQ_TEST         0x00000002
#define IRQ_TX_DONE      0x00000004
#define IRQ_RX           0x00000008

/* DMA control */
#define DMA_START        0x00000001
#define DMA_DIR_WRITE    0x00000002
#define DMA_IRQ_EN       0x00000004

/* Descriptor flags */
#define DESC_FLAG_OWN    0x80000000u
#define DESC_FLAG_DONE   0x40000000u
#define DESC_FLAG_ERR    0x20000000u

/* Descriptor ring entry */
struct smarteth_desc {
    __le64 addr;     /* DMA address */
    __le32 length;
    __le32 flags;
} __attribute__((packed));

/* Per-NIC private data */
struct smarteth_adapter {
    struct pci_dev        *pdev;
    void __iomem          *bar0;

    /* MSI-X */
    int                    msix_vector;

    /* TX ring */
    struct smarteth_desc  *tx_ring;
    dma_addr_t             tx_ring_dma;
    u32                    tx_head;
    u32                    tx_pending;

    /* RX ring */
    struct smarteth_desc  *rx_ring;
    dma_addr_t             rx_ring_dma;
    u32                    rx_head;

    /* RX buffers */
    u8                   **rx_buf;      /* kernel virtual addresses */
    dma_addr_t            *rx_dma;      /* DMA addresses */

    /* Test completions */
    struct completion      test_done;
    atomic_t               irq_count;
};

/* ─── MMIO helpers ─── */

static inline u32 smarteth_read_reg(struct smarteth_adapter *adapter, u32 reg)
{
    return ioread32(adapter->bar0 + reg);
}

static inline void smarteth_write_reg(struct smarteth_adapter *adapter,
                                       u32 reg, u32 val)
{
    iowrite32(val, adapter->bar0 + reg);
}

/* ─── RX buffer management ─── */

static int smarteth_prepare_rx_buffers(struct smarteth_adapter *adapter)
{
    int i;

    for (i = 0; i < SMARTETH_RING_SIZE; i++) {
        dma_addr_t dma;

        adapter->rx_buf[i] = kmalloc(SMARTETH_RX_BUF_SIZE, GFP_KERNEL | GFP_DMA);
        if (!adapter->rx_buf[i])
            return -ENOMEM;

        dma = dma_map_single(&adapter->pdev->dev, adapter->rx_buf[i],
                             SMARTETH_RX_BUF_SIZE, DMA_FROM_DEVICE);
        if (dma_mapping_error(&adapter->pdev->dev, dma)) {
            kfree(adapter->rx_buf[i]);
            adapter->rx_buf[i] = NULL;
            return -ENOMEM;
        }
        adapter->rx_dma[i] = dma;

        /* Fill descriptor */
        adapter->rx_ring[i].addr   = cpu_to_le64(dma);
        adapter->rx_ring[i].length = cpu_to_le32(SMARTETH_RX_BUF_SIZE);
        wmb();
        adapter->rx_ring[i].flags  = cpu_to_le32(DESC_FLAG_OWN);
    }
    return 0;
}

static void smarteth_free_rx_buffers(struct smarteth_adapter *adapter)
{
    int i;
    for (i = 0; i < SMARTETH_RING_SIZE; i++) {
        if (adapter->rx_buf[i]) {
            dma_unmap_single(&adapter->pdev->dev, adapter->rx_dma[i],
                             SMARTETH_RX_BUF_SIZE, DMA_FROM_DEVICE);
            kfree(adapter->rx_buf[i]);
            adapter->rx_buf[i] = NULL;
        }
    }
}

/* ─── IRQ handler ─── */

static irqreturn_t smarteth_irq_handler(int irq, void *dev_id)
{
    struct smarteth_adapter *adapter = dev_id;
    u32 irq_sts;

    irq_sts = smarteth_read_reg(adapter, REG_IRQ_STS);
    if (!irq_sts)
        return IRQ_NONE;

    /* Clear handled IRQs (write-1-to-clear) */
    smarteth_write_reg(adapter, REG_IRQ_STS, irq_sts);

    atomic_inc(&adapter->irq_count);

    if (irq_sts & IRQ_DMA_DONE)
        complete(&adapter->test_done);

    if (irq_sts & IRQ_TX_DONE)
        complete(&adapter->test_done);

    if (irq_sts & IRQ_RX)
        complete(&adapter->test_done);

    if (irq_sts & IRQ_TEST)
        complete(&adapter->test_done);

    return IRQ_HANDLED;
}

/* ─── Test functions ─── */

static int smarteth_test_regs(struct smarteth_adapter *adapter)
{
    u32 dev_id, status, scratch;

    dev_id = smarteth_read_reg(adapter, REG_DEV_ID);
    pr_info("[TEST] DEV_ID = 0x%08x %s\n", dev_id,
            dev_id == 0x52414D53UL ? "PASS" : "FAIL");

    status = smarteth_read_reg(adapter, REG_STATUS);
    pr_info("[TEST] STATUS = 0x%08x %s\n", status,
            (status & STATUS_READY) ? "PASS" : "FAIL");

    /* Scratch write/readback */
    smarteth_write_reg(adapter, REG_SCRATCH0, 0x12345678);
    scratch = smarteth_read_reg(adapter, REG_SCRATCH0);
    pr_info("[TEST] SCRATCH0 = 0x%08x %s\n", scratch,
            scratch == 0x12345678 ? "PASS" : "FAIL");

    return 0;
}

static int smarteth_test_dma(struct smarteth_adapter *adapter)
{
    void *buf;
    dma_addr_t dma;
    u32 val;
    int timeout;

    /* Allocate DMA buffer */
    buf = kzalloc(256, GFP_KERNEL | GFP_DMA);
    if (!buf)
        return -ENOMEM;

    dma = dma_map_single(&adapter->pdev->dev, buf, 256, DMA_BIDIRECTIONAL);
    if (dma_mapping_error(&adapter->pdev->dev, dma)) {
        kfree(buf);
        return -ENOMEM;
    }

    /* Fill pattern */
    memset(buf, 0xA5, 256);
    wmb();

    /* Program DMA: device reads from guest memory */
    smarteth_write_reg(adapter, REG_DMA_SRC, lower_32_bits(dma));
    smarteth_write_reg(adapter, REG_DMA_DST, upper_32_bits(dma));
    smarteth_write_reg(adapter, REG_DMA_LEN, 256);
    smarteth_write_reg(adapter, REG_DMA_CTRL, DMA_START | DMA_IRQ_EN);

    /* Wait for completion */
    timeout = wait_for_completion_timeout(&adapter->test_done, HZ / 2);
    pr_info("[TEST] DMA %s (timeout=%d, irq=%d)\n",
            timeout > 0 ? "PASS" : "TIMEOUT",
            timeout > 0 ? 0 : 1,
            atomic_read(&adapter->irq_count));

    dma_unmap_single(&adapter->pdev->dev, dma, 256, DMA_BIDIRECTIONAL);
    kfree(buf);
    return timeout > 0 ? 0 : -ETIMEDOUT;
}

static int smarteth_test_tx(struct smarteth_adapter *adapter)
{
    u8 *pkt;
    dma_addr_t dma;
    int timeout;
    u32 tail_before, tail_after;

    pkt = kzalloc(256, GFP_KERNEL | GFP_DMA);
    if (!pkt)
        return -ENOMEM;

    /* Craft a minimal Ethernet frame */
    memset(pkt, 0xAA, 256);
    dma = dma_map_single(&adapter->pdev->dev, pkt, 256, DMA_TO_DEVICE);
    if (dma_mapping_error(&adapter->pdev->dev, dma)) {
        kfree(pkt);
        return -ENOMEM;
    }

    tail_before = smarteth_read_reg(adapter, REG_TX_TAIL);

    /* Fill descriptor */
    u32 head = adapter->tx_head;
    adapter->tx_ring[head].addr   = cpu_to_le64(dma);
    adapter->tx_ring[head].length = cpu_to_le32(256);
    wmb();  /* ensure data visible before ownership transfer */
    adapter->tx_ring[head].flags  = cpu_to_le32(DESC_FLAG_OWN);

    adapter->tx_head = (head + 1) % SMARTETH_RING_SIZE;

    /* Ring doorbell */
    smarteth_write_reg(adapter, REG_TX_DOORBELL, 1);

    /* Wait for TX to complete */
    timeout = wait_for_completion_timeout(&adapter->test_done, HZ);

    tail_after = smarteth_read_reg(adapter, REG_TX_TAIL);

    pr_info("[TEST] TX: head=%u tail_before=%u tail_after=%u %s\n",
            head, tail_before, tail_after,
            (timeout > 0) ? "PASS" : "TIMEOUT");

    dma_unmap_single(&adapter->pdev->dev, dma, 256, DMA_TO_DEVICE);
    kfree(pkt);
    return timeout > 0 ? 0 : -ETIMEDOUT;
}

static int smarteth_test_irq(struct smarteth_adapter *adapter)
{
    int timeout;
    int cnt_before = atomic_read(&adapter->irq_count);

    /* Trigger test interrupt via IRQ_TEST register */
    smarteth_write_reg(adapter, REG_IRQ_TEST, 1);

    timeout = wait_for_completion_timeout(&adapter->test_done, HZ);

    pr_info("[TEST] IRQ: count=%d %s\n",
            atomic_read(&adapter->irq_count),
            (timeout > 0) ? "PASS" : "TIMEOUT");

    return timeout > 0 ? 0 : -ETIMEDOUT;
}

/* ─── Sysfs test interface ─── */

static ssize_t test_store(struct device *dev, struct device_attribute *attr,
                          const char *buf, size_t count)
{
    struct pci_dev *pdev = to_pci_dev(dev);
    struct smarteth_adapter *adapter = pci_get_drvdata(pdev);

    if (strncmp(buf, "regs", 4) == 0) {
        smarteth_test_regs(adapter);
    } else if (strncmp(buf, "dma", 3) == 0) {
        smarteth_test_dma(adapter);
    } else if (strncmp(buf, "tx", 2) == 0) {
        smarteth_test_tx(adapter);
    } else if (strncmp(buf, "intr", 4) == 0) {
        smarteth_test_irq(adapter);
    } else {
        dev_warn(dev, "Unknown test: %s (try: regs, dma, tx, intr)\n", buf);
    }

    return count;
}
static DEVICE_ATTR_WO(test);

static struct attribute *smarteth_attrs[] = {
    &dev_attr_test.attr,
    NULL,
};
ATTRIBUTE_GROUPS(smarteth);

/* ─── Probe / Remove ─── */

static int smarteth_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    struct smarteth_adapter *adapter;
    int err, i;

    adapter = devm_kzalloc(&pdev->dev, sizeof(*adapter), GFP_KERNEL);
    if (!adapter)
        return -ENOMEM;

    adapter->pdev = pdev;
    pci_set_drvdata(pdev, adapter);
    init_completion(&adapter->test_done);
    atomic_set(&adapter->irq_count, 0);

    /* Enable PCI device */
    err = pci_enable_device(pdev);
    if (err) {
        dev_err(&pdev->dev, "pci_enable_device failed: %d\n", err);
        return err;
    }

    /* Set DMA mask (32-bit) */
    err = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(32));
    if (err) {
        dev_err(&pdev->dev, "DMA mask error\n");
        goto err_disable;
    }

    /* Request BAR0 and iomap */
    err = pci_request_region(pdev, SMARTETH_BAR_MMIO, DRV_NAME);
    if (err) {
        dev_err(&pdev->dev, "BAR0 request failed\n");
        goto err_disable;
    }

    adapter->bar0 = pci_iomap(pdev, SMARTETH_BAR_MMIO, 4096);
    if (!adapter->bar0) {
        dev_err(&pdev->dev, "BAR0 iomap failed\n");
        err = -ENOMEM;
        goto err_release;
    }

    /* Enable bus mastering */
    pci_set_master(pdev);

    /* Verify device ID */
    {
        u32 dev_id = smarteth_read_reg(adapter, REG_DEV_ID);
        if (dev_id != 0x52414D53UL) {
            dev_err(&pdev->dev, "Unexpected DEV_ID: 0x%08x\n", dev_id);
            err = -ENODEV;
            goto err_iounmap;
        }
        dev_info(&pdev->dev, "SmartEth NIC found (DEV_ID=0x%08x)\n", dev_id);
    }

    /* Setup MSI-X (1 vector) */
    err = pci_alloc_irq_vectors(pdev, 1, 1, PCI_IRQ_MSIX);
    if (err < 0) {
        dev_err(&pdev->dev, "MSI-X setup failed: %d\n", err);
        goto err_iounmap;
    }
    adapter->msix_vector = pci_irq_vector(pdev, 0);

    /* Request IRQ */
    err = request_irq(adapter->msix_vector, smarteth_irq_handler, 0,
                      DRV_NAME, adapter);
    if (err) {
        dev_err(&pdev->dev, "IRQ request failed: %d\n", err);
        goto err_vectors;
    }

    /* Allocate TX ring (DMA-coherent) */
    adapter->tx_ring = dmam_alloc_coherent(&pdev->dev,
        SMARTETH_RING_SIZE * sizeof(struct smarteth_desc),
        &adapter->tx_ring_dma, GFP_KERNEL);
    if (!adapter->tx_ring) {
        dev_err(&pdev->dev, "TX ring alloc failed\n");
        err = -ENOMEM;
        goto err_irq;
    }
    memset(adapter->tx_ring, 0,
           SMARTETH_RING_SIZE * sizeof(struct smarteth_desc));

    /* Allocate RX ring (DMA-coherent) */
    adapter->rx_ring = dmam_alloc_coherent(&pdev->dev,
        SMARTETH_RING_SIZE * sizeof(struct smarteth_desc),
        &adapter->rx_ring_dma, GFP_KERNEL);
    if (!adapter->rx_ring) {
        dev_err(&pdev->dev, "RX ring alloc failed\n");
        err = -ENOMEM;
        goto err_irq;
    }
    memset(adapter->rx_ring, 0,
           SMARTETH_RING_SIZE * sizeof(struct smarteth_desc));

    /* Allocate RX buffer tracking arrays */
    adapter->rx_buf = devm_kcalloc(&pdev->dev, SMARTETH_RING_SIZE,
                                   sizeof(u8*), GFP_KERNEL);
    adapter->rx_dma = devm_kcalloc(&pdev->dev, SMARTETH_RING_SIZE,
                                   sizeof(dma_addr_t), GFP_KERNEL);
    if (!adapter->rx_buf || !adapter->rx_dma) {
        err = -ENOMEM;
        goto err_irq;
    }

    /* Prepare RX buffers */
    err = smarteth_prepare_rx_buffers(adapter);
    if (err) {
        dev_err(&pdev->dev, "RX buffer prep failed: %d\n", err);
        goto err_irq;
    }

    /* Configure NIC descriptor rings */
    smarteth_write_reg(adapter, REG_TX_RING_BASE_LO,
                       lower_32_bits(adapter->tx_ring_dma));
    smarteth_write_reg(adapter, REG_TX_RING_BASE_HI,
                       upper_32_bits(adapter->tx_ring_dma));
    smarteth_write_reg(adapter, REG_TX_RING_SIZE, SMARTETH_RING_SIZE);

    smarteth_write_reg(adapter, REG_RX_RING_BASE_LO,
                       lower_32_bits(adapter->rx_ring_dma));
    smarteth_write_reg(adapter, REG_RX_RING_BASE_HI,
                       upper_32_bits(adapter->rx_ring_dma));
    smarteth_write_reg(adapter, REG_RX_RING_SIZE, SMARTETH_RING_SIZE);

    /* Enable IRQs */
    smarteth_write_reg(adapter, REG_IRQ_EN,
                       IRQ_DMA_DONE | IRQ_TX_DONE | IRQ_RX | IRQ_TEST);

    /* Notify NIC of available RX descriptors */
    smarteth_write_reg(adapter, REG_RX_DOORBELL, SMARTETH_RING_SIZE);

    dev_info(&pdev->dev, "SmartEth NIC probed: bar0=%p tx_ring=%pad rx_ring=%pad\n",
             adapter->bar0, &adapter->tx_ring_dma, &adapter->rx_ring_dma);
    return 0;

err_irq:
    free_irq(adapter->msix_vector, adapter);
err_vectors:
    pci_free_irq_vectors(pdev);
err_iounmap:
    pci_iounmap(pdev, adapter->bar0);
err_release:
    pci_release_region(pdev, SMARTETH_BAR_MMIO);
err_disable:
    pci_disable_device(pdev);
    return err;
}

static void smarteth_remove(struct pci_dev *pdev)
{
    struct smarteth_adapter *adapter = pci_get_drvdata(pdev);
    if (!adapter)
        return;

    /* Disable IRQs */
    smarteth_write_reg(adapter, REG_IRQ_EN, 0);

    /* Free RX buffers */
    smarteth_free_rx_buffers(adapter);

    free_irq(adapter->msix_vector, adapter);
    pci_free_irq_vectors(pdev);
    pci_iounmap(pdev, adapter->bar0);
    pci_release_region(pdev, SMARTETH_BAR_MMIO);
    pci_disable_device(pdev);

    dev_info(&pdev->dev, "SmartEth NIC removed\n");
}

/* ─── PCI device ID table ─── */

static const struct pci_device_id smarteth_ids[] = {
    { PCI_DEVICE(0x1efd, 0x0001) },  /* SmartEth */
    { 0, }
};
MODULE_DEVICE_TABLE(pci, smarteth_ids);

static struct pci_driver smarteth_driver = {
    .name     = DRV_NAME,
    .id_table = smarteth_ids,
    .probe    = smarteth_probe,
    .remove   = smarteth_remove,
    .driver   = {
        .dev_groups = smarteth_groups,
    },
};

module_pci_driver(smarteth_driver);

MODULE_AUTHOR("SmartEth Team");
MODULE_DESCRIPTION("SmartEth NIC PCI driver");
MODULE_LICENSE("GPL");
MODULE_VERSION(DRV_VERSION);
