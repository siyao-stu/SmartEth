#ifndef SMARTETH_SC_DMA_ENGINE_H
#define SMARTETH_SC_DMA_ENGINE_H

#include <cstdint>
#include <vector>
#include "protocol.h"

/*
 * DMA engine model — transfers data between NIC internal buffer and
 * guest memory (via QEMU bridge).
 *
 * Features:
 *   - Configurable source/destination addresses and length
 *   - Internal buffer (4KB)
 *   - Timing model: 1 cycle per 4 bytes + bus arbitration overhead
 *   - Callback-based DMA read/write initiation
 */

class DmaEngine {
public:
    /* Callback types for bridging to QEMU memory */
    using DmaReadCb  = bool (*)(uint64_t addr, uint32_t len,
                                 uint8_t *buf, void *user);
    using DmaWriteCb = bool (*)(uint64_t addr, uint32_t len,
                                 const uint8_t *buf, void *user);

    DmaEngine();

    /* Configure from register block values */
    void configure(uint64_t src, uint64_t dst, uint32_t len, uint32_t ctrl);

    /* Start DMA transfer (returns delay in ns) */
    uint64_t start(DmaReadCb read_cb, DmaWriteCb write_cb, void *user);

    /* Check if DMA is busy */
    bool busy() const { return m_busy; }

    /* Get internal buffer */
    const uint8_t* buffer() const { return m_buf.data(); }
    uint8_t* buffer() { return m_buf.data(); }

    /* Get DMA status flags */
    uint32_t status() const { return m_busy ? SC_STATUS_DMA_BSY : 0; }

    /* Set direction (read from RAM vs write to RAM) */
    bool is_write_dir() const { return m_dir_write; }

    /* Transfer timing per unit (ns per 4 bytes) */
    static constexpr uint64_t DMA_CYCLE_NS = 2;   /* 2ns per 4 bytes ≈ 2GB/s */
    static constexpr uint64_t DMA_START_NS = 50;  /* 50ns setup overhead */
    static constexpr uint64_t DMA_MAX_BUF  = 4096;

private:
    uint64_t m_src;
    uint64_t m_dst;
    uint32_t m_len;
    uint32_t m_ctrl;
    bool     m_busy;
    bool     m_dir_write;
    bool     m_irq_en;
    std::vector<uint8_t> m_buf;
};

#endif /* SMARTETH_SC_DMA_ENGINE_H */
