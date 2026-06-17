#include "dma_engine.h"
#include <algorithm>
#include <cstring>

DmaEngine::DmaEngine()
    : m_src(0), m_dst(0), m_len(0), m_ctrl(0)
    , m_busy(false), m_dir_write(false), m_irq_en(false)
{
    m_buf.resize(DMA_MAX_BUF, 0);
}

void DmaEngine::configure(uint64_t src, uint64_t dst,
                           uint32_t len, uint32_t ctrl)
{
    m_src       = src;
    m_dst       = dst;
    m_len       = std::min<uint32_t>(len, DMA_MAX_BUF);
    m_ctrl      = ctrl;
    m_dir_write = (ctrl & SC_DMA_DIR_WRITE) != 0;
    m_irq_en    = (ctrl & SC_DMA_IRQ_EN) != 0;
}

uint64_t DmaEngine::start(DmaReadCb read_cb, DmaWriteCb write_cb, void *user)
{
    if (m_busy || m_len == 0) {
        return 0;
    }

    m_busy = true;

    /* Setup overhead */
    uint64_t delay = DMA_START_NS;

    if (m_dir_write) {
        /* Device writes to guest memory: copy from internal buffer */
        if (write_cb) {
            write_cb(m_dst, m_len, m_buf.data(), user);
        }
    } else {
        /* Device reads from guest memory: copy to internal buffer */
        if (read_cb) {
            read_cb(m_src, m_len, m_buf.data(), user);
        }
    }

    /* Transfer time: proportional to length */
    uint64_t cycles = (m_len + 3) / 4;  /* round up to 4-byte words */
    delay += cycles * DMA_CYCLE_NS;

    m_busy = false;
    return delay;
}
