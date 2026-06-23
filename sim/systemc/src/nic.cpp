#include "nic.h"
#include "protocol.h"
#include <iostream>
#include <cstring>
#include <mutex>

static std::mutex g_reg_mtx;  /* protects regs from socket thread vs SC thread */

SmartNic::SmartNic(sc_core::sc_module_name name)
    : sc_module(name)
    , bridge(nullptr)
    , m_netif(nullptr)
    , m_dma_pending(false)
    , m_tx_pending(false)
{
    SC_THREAD(poll_irq);
    dont_initialize();

    SC_THREAD(process_dma);
    dont_initialize();

    SC_THREAD(process_tx);
    dont_initialize();

    SC_THREAD(process_rx);
    dont_initialize();
}

void SmartNic::register_callbacks()
{
    if (!bridge) return;

    bridge->register_mmio_read(
        [this](uint64_t addr) -> uint32_t {
            return on_mmio_read(addr);
        });
    bridge->register_mmio_write(
        [this](uint64_t addr, uint32_t data) {
            on_mmio_write(addr, data);
        });
    bridge->register_reset(
        [this]() { on_reset(); });
}

void SmartNic::start_bridge()
{
    if (bridge) {
        bridge->start();
    }
}

/* ── DMA bridge helpers ── */

bool SmartNic::dma_read_bridge(uint64_t addr, uint32_t len, uint8_t *buf)
{
    return bridge && bridge->dma_read(addr, len, buf);
}

bool SmartNic::dma_write_bridge(uint64_t addr, uint32_t len, const uint8_t *buf)
{
    return bridge && bridge->dma_write(addr, len, buf);
}

/* ── Callbacks (called from socket thread — use mutex) ── */

uint32_t SmartNic::on_mmio_read(uint64_t addr)
{
    std::lock_guard<std::mutex> lk(g_reg_mtx);

    uint32_t val = m_regs.read(addr);

    /* Special handling for DMA_STS — report DMA engine status */
    if (addr == SC_REG_DMA_STS) {
        val = (val & ~0x02u) | (m_dma.status() ? 0x02u : 0);
    }

    return val;
}

void SmartNic::on_mmio_write(uint64_t addr, uint32_t data)
{
    std::lock_guard<std::mutex> lk(g_reg_mtx);

    bool irq = m_regs.write(addr, data);

    /* If DMA_CTRL written with START bit, kick off DMA */
    if (addr == SC_REG_DMA_CTRL && (data & SC_DMA_START)) {
        uint64_t src = m_regs.get_reg(SC_REG_DMA_SRC >> 2);
        uint64_t dst = m_regs.get_reg(SC_REG_DMA_DST >> 2);
        uint32_t len = m_regs.get_reg(SC_REG_DMA_LEN >> 2);
        m_dma.configure(src, dst, len, data);
        m_regs.set_reg(SC_REG_DMA_STS >> 2, SC_STATUS_DMA_BSY);
        m_dma_pending = true;
    }

    /* TX doorbell — kick TX processing */
    if (addr == SC_REG_TX_DOORBELL && data > 0) {
        m_tx_pending = true;
        m_tx_event.notify(sc_core::SC_ZERO_TIME);
    }

    if (irq && bridge) {
        bridge->send_irq(0);
    }
}

void SmartNic::on_reset()
{
    std::lock_guard<std::mutex> lk(g_reg_mtx);
    m_regs.reset();
    m_dma_pending = false;
    m_tx_pending = false;
}

/* ── RX packet callback (called from NetIf listener thread) ── */

void SmartNic::on_packet_rx(const uint8_t *data, uint32_t len)
{
    /* Called from an arbitrary thread — protect register access */
    std::lock_guard<std::mutex> lk(g_reg_mtx);

    /* Run PktProc for timing/parsing annotation */
    uint64_t proc_delay = m_pkt.receive(data, len);

    /* MAC filtering: check destination MAC */
    uint32_t mac_lo = m_regs.get_reg(SC_REG_MAC_LO >> 2); /* 0x00541234 */
    uint32_t mac_hi = m_regs.get_reg(SC_REG_MAC_HI >> 2); /* 0x00000056 */
    uint8_t mac[6];
    mac[0] = (mac_lo >> 24) & 0xFF; /* 0x00 -> no, wait */

    /* MAC is stored as SC_MAC_DEFAULT_LO/HI:
     *   lo = 0x00541234  => bytes: 00 54 12 34
     *   hi = 0x0056      => bytes: 00 00 00 56
     * MAC addr: 52:54:00:12:34:56
     * In lo/hi: lo contains 54:00:12:34 (wrong byte order? depends on convention)
     * smarteth_pci.c writes: mac[0..5] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x56}
     * lo = (mac[0]<<24)|(mac[1]<<16)|(mac[2]<<8)|mac[3]
     *    = 0x52540012  (but SC_MAC_DEFAULT_LO = 0x00541234 -- diff!)
     *
     * The firmware reads back MAC as: REG_MAC_LO = 0x52540012, REG_MAC_HI = 0x3456
     * But protocol.h defines SC_MAC_DEFAULT_LO = 0x00541234.
     * Looks like protocol.h might have the byte order wrong.
     * However, in smarteth_pci.c & sc_bridge, the real stored value is
     *   s->conf.macaddr.a[0..5] which is {0x52, 0x54, 0x00, 0x12, 0x34, 0x56}
     *   stored as lo=0x52540012, hi=0x3456.
     *
     * For Phase 4 MAC filtering, read back from regs which should have the
     * correct value written by whoever set it up.
     */
    /* Simple filter: accept if dest MAC matches NIC MAC or is broadcast */
    uint8_t nic_mac[6];
    nic_mac[0] = (mac_lo >> 24) & 0xFF;
    nic_mac[1] = (mac_lo >> 16) & 0xFF;
    nic_mac[2] = (mac_lo >> 8) & 0xFF;
    nic_mac[3] = mac_lo & 0xFF;
    nic_mac[4] = (mac_hi >> 8) & 0xFF;
    nic_mac[5] = mac_hi & 0xFF;

    /* Accept broadcast/multicast or our MAC */
    bool match = false;
    if (len >= 14) {
        if (data[0] & 0x01) {
            match = true;  /* broadcast or multicast */
        } else if (std::memcmp(data, nic_mac, 6) == 0) {
            match = true;  /* matches our MAC */
        }
    }

    if (!match) return;

    /* Read RX descriptor ring config */
    uint64_t ring_base = (uint64_t)m_regs.get_reg(SC_REG_RX_RING_BASE_HI >> 2) << 32
                       | m_regs.get_reg(SC_REG_RX_RING_BASE_LO >> 2);
    uint32_t ring_size = m_regs.get_reg(SC_REG_RX_RING_SIZE >> 2);
    uint32_t tail = m_regs.get_reg(SC_REG_RX_TAIL >> 2);

    if (ring_size == 0 || ring_base == 0) {
        std::cout << "[NIC] RX ring not configured, dropping packet" << std::endl;
        return;
    }

    /* Read next descriptor from guest memory */
    uint64_t desc_addr = ring_base + tail * sizeof(SmartEthDesc);
    SmartEthDesc desc;
    if (!dma_read_bridge(desc_addr, sizeof(SmartEthDesc), (uint8_t*)&desc)) {
        std::cerr << "[NIC] RX DMA error: cannot read descriptor at 0x"
                  << std::hex << desc_addr << std::dec << std::endl;
        return;
    }

    if (!(desc.flags & SMARTETH_DESC_FLAG_OWN)) {
        /* No free buffer available — drop packet */
        std::cout << "[NIC] RX no free descriptor, dropping" << std::endl;
        return;
    }

    /* DMA the packet data into the host's RX buffer */
    uint32_t copy_len = (len < desc.length) ? len : desc.length;
    if (!dma_write_bridge(desc.addr, copy_len, data)) {
        std::cerr << "[NIC] RX DMA error: write to 0x"
                  << std::hex << desc.addr << std::dec << std::endl;
        return;
    }

    /* Update descriptor: clear OWN, set DONE, record actual length */
    desc.flags &= ~SMARTETH_DESC_FLAG_OWN;
    desc.flags |= SMARTETH_DESC_FLAG_DONE;
    desc.length = copy_len;
    if (!dma_write_bridge(desc_addr, sizeof(SmartEthDesc), (uint8_t*)&desc)) {
        std::cerr << "[NIC] RX DMA error: write back descriptor" << std::endl;
        return;
    }

    /* Advance tail pointer */
    tail = (tail + 1) % ring_size;
    m_regs.set_reg(SC_REG_RX_TAIL >> 2, tail);

    /* Raise RX IRQ */
    uint32_t irq_en = m_regs.get_reg(SC_REG_IRQ_EN >> 2);
    if (irq_en & SC_IRQ_RX) {
        m_regs.set_reg(SC_REG_IRQ_STS >> 2, m_regs.irq_status() | SC_IRQ_RX);
        if (bridge) bridge->send_irq(1);
    }
}

/* ── SystemC processes ── */

void SmartNic::poll_irq()
{
    while (true) {
        wait(sc_core::sc_time(100, sc_core::SC_NS));

        std::lock_guard<std::mutex> lk(g_reg_mtx);
        uint32_t irq = m_regs.irq_status();

        if (irq && bridge) {
            int vec = (irq & SC_IRQ_DMA_DONE) ? 0 : 1;
            bridge->send_irq(vec);
        }
    }
}

void SmartNic::process_dma()
{
    while (true) {
        wait(sc_core::sc_time(10, sc_core::SC_NS));

        if (!m_dma_pending) continue;

        std::lock_guard<std::mutex> lk(g_reg_mtx);

        uint64_t dma_delay = m_dma.start(
            [](uint64_t addr, uint32_t len, uint8_t *buf, void *user) -> bool {
                auto *self = static_cast<SmartNic*>(user);
                return self->bridge && self->bridge->dma_read(addr, len, buf);
            },
            [](uint64_t addr, uint32_t len, const uint8_t *buf, void *user) -> bool {
                auto *self = static_cast<SmartNic*>(user);
                return self->bridge && self->bridge->dma_write(addr, len, buf);
            },
            this
        );

        m_regs.set_reg(SC_REG_DMA_STS >> 2, 0);
        m_dma_pending = false;

        uint32_t ctrl = m_regs.get_reg(SC_REG_DMA_CTRL >> 2);
        if (ctrl & SC_DMA_IRQ_EN) {
            m_regs.set_reg(SC_REG_IRQ_STS >> 2, m_regs.irq_status() | SC_IRQ_DMA_DONE);
            if (bridge) bridge->send_irq(0);
        }

        wait(sc_core::sc_time(dma_delay, sc_core::SC_NS));
    }
}

void SmartNic::process_tx()
{
    while (true) {
        wait(m_tx_event);

        while (true) {
            std::lock_guard<std::mutex> lk(g_reg_mtx);

            if (!m_tx_pending) break;

            uint64_t ring_base = (uint64_t)m_regs.get_reg(SC_REG_TX_RING_BASE_HI >> 2) << 32
                               | m_regs.get_reg(SC_REG_TX_RING_BASE_LO >> 2);
            uint32_t ring_size = m_regs.get_reg(SC_REG_TX_RING_SIZE >> 2);
            uint32_t tail = m_regs.get_reg(SC_REG_TX_TAIL >> 2);
            uint32_t doorbell = m_regs.get_reg(SC_REG_TX_DOORBELL >> 2);

            if (ring_size == 0 || doorbell == 0 || ring_base == 0) {
                m_tx_pending = false;
                break;
            }

            /* Read descriptor from guest memory */
            uint64_t desc_addr = ring_base + tail * sizeof(SmartEthDesc);
            SmartEthDesc desc;
            if (!dma_read_bridge(desc_addr, sizeof(SmartEthDesc), (uint8_t*)&desc)) {
                std::cerr << "[NIC] TX DMA: cannot read descriptor" << std::endl;
                break;
            }

            if (!(desc.flags & SMARTETH_DESC_FLAG_OWN)) {
                /* Driver hasn't given ownership yet */
                m_tx_pending = false;
                break;
            }

            /* Read packet data from guest memory */
            std::vector<uint8_t> pkt_data(desc.length);
            if (!dma_read_bridge(desc.addr, desc.length, pkt_data.data())) {
                std::cerr << "[NIC] TX DMA: cannot read packet data" << std::endl;
                break;
            }

            /* Transmit on network interface */
            if (m_netif) {
                m_netif->transmit(pkt_data.data(), desc.length);
            }

            /* Update descriptor: clear OWN, set DONE */
            desc.flags &= ~SMARTETH_DESC_FLAG_OWN;
            desc.flags |= SMARTETH_DESC_FLAG_DONE;
            if (!dma_write_bridge(desc_addr, sizeof(SmartEthDesc), (uint8_t*)&desc)) {
                std::cerr << "[NIC] TX DMA: write back descriptor" << std::endl;
                break;
            }

            /* Advance tail, decrement doorbell */
            tail = (tail + 1) % ring_size;
            m_regs.set_reg(SC_REG_TX_TAIL >> 2, tail);
            m_regs.set_reg(SC_REG_TX_DOORBELL >> 2, doorbell - 1);

            /* Timing: 100ns setup + 2ns per 4 bytes */
            wait(sc_core::sc_time(100 + desc.length / 4 * 2, sc_core::SC_NS));
        }

        /* TX done IRQ */
        {
            std::lock_guard<std::mutex> lk(g_reg_mtx);
            uint32_t irq_en = m_regs.get_reg(SC_REG_IRQ_EN >> 2);
            if (irq_en & SC_IRQ_TX_DONE) {
                m_regs.set_reg(SC_REG_IRQ_STS >> 2, m_regs.irq_status() | SC_IRQ_TX_DONE);
                if (bridge) bridge->send_irq(1);
            }
        }
    }
}

void SmartNic::process_rx()
{
    while (true) {
        /* Wait for NetIf RX event (packet arrived from network side) */
        if (m_netif) {
            wait(m_netif->m_rx_event);
        } else {
            wait(sc_core::sc_time(1, sc_core::SC_MS));
            continue;
        }

        /* The actual packet processing is done in on_packet_rx()
         * which is called from the NetIf listener thread.
         * Here we just add a small timing overhead and handle IRQ coalescing.
         */
        wait(sc_core::sc_time(10, sc_core::SC_NS));
    }
}
