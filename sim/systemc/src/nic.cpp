#include "nic.h"
#include <iostream>
#include <mutex>

static std::mutex g_reg_mtx;  /* protects regs from socket thread vs SC thread */

SmartNic::SmartNic(sc_core::sc_module_name name)
    : sc_module(name)
    , bridge(nullptr)
    , m_dma_pending(false)
{
    SC_THREAD(poll_irq);
    dont_initialize();

    SC_THREAD(process_dma);
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
        /* Start socket thread (callbacks must be registered first) */
        bridge->start();
    }
}

/* ── Callbacks (called from socket thread — use mutex) ── */

uint32_t SmartNic::on_mmio_read(uint64_t addr)
{
    std::lock_guard<std::mutex> lk(g_reg_mtx);

    uint32_t val = m_regs.read(addr);

    /* Special handling for DMA_STS — report DMA engine status */
    if (addr == SC_REG_DMA_STS) {
        val = m_dma.status();
    }

    return val;
}

void SmartNic::on_mmio_write(uint64_t addr, uint32_t data)
{
    std::lock_guard<std::mutex> lk(g_reg_mtx);

    bool irq = m_regs.write(addr, data);

    /* If DMA_CTRL written with START bit, kick off DMA */
    if (addr == SC_REG_DMA_CTRL && (data & SC_DMA_START)) {
        /* Save DMA params from regs into DMA engine */
        uint64_t src = m_regs.get_reg(SC_REG_DMA_SRC >> 2);
        uint64_t dst = m_regs.get_reg(SC_REG_DMA_DST >> 2);
        uint32_t len = m_regs.get_reg(SC_REG_DMA_LEN >> 2);
        m_dma.configure(src, dst, len, data);
        m_regs.set_reg(SC_REG_DMA_STS >> 2, SC_STATUS_DMA_BSY);
        m_dma_pending = true;
    }

    if (irq && bridge) {
        bridge->send_irq(0);  /* Notify QEMU of IRQ state change */
    }
}

void SmartNic::on_reset()
{
    std::lock_guard<std::mutex> lk(g_reg_mtx);
    m_regs.reset();
    m_dma_pending = false;
}

/* ── SystemC processes ── */

void SmartNic::poll_irq()
{
    while (true) {
        wait(sc_core::sc_time(100, sc_core::SC_NS));

        std::lock_guard<std::mutex> lk(g_reg_mtx);
        uint32_t irq = m_regs.irq_status();

        if (irq && bridge) {
            /* Send MSI-X interrupt to QEMU for any raised IRQ */
            int vec = (irq & SC_IRQ_DMA_DONE) ? 0 : 1;
            bridge->send_irq(vec);
        }
    }
}

void SmartNic::process_dma()
{
    while (true) {
        /* Poll for DMA pending flag (thread-safe: set from socket thread under mutex) */
        wait(sc_core::sc_time(10, sc_core::SC_NS));

        if (!m_dma_pending) continue;

        std::lock_guard<std::mutex> lk(g_reg_mtx);

        /* Execute DMA transfer (timing accounted inside DmaEngine) */
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

        /* Clear busy, raise IRQ if enabled */
        m_regs.set_reg(SC_REG_DMA_STS >> 2, 0);
        m_dma_pending = false;

        uint32_t ctrl = m_regs.get_reg(SC_REG_DMA_CTRL >> 2);
        if (ctrl & SC_DMA_IRQ_EN) {
            m_regs.write(SC_REG_IRQ_STS, m_regs.irq_status() | SC_IRQ_DMA_DONE, nullptr);
            if (bridge) {
                bridge->send_irq(0);
            }
        }

        /* Account for DMA timing */
        wait(sc_core::sc_time(dma_delay, sc_core::SC_NS));
    }
}
