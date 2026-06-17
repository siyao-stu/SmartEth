#ifndef SMARTETH_SC_REG_BLOCK_H
#define SMARTETH_SC_REG_BLOCK_H

#include <cstdint>
#include "protocol.h"

/*
 * Register block — SmartEth NIC register file.
 *
 * Mirrors the register layout from the QEMU device model (smarteth_pci.c)
 * with timing annotations for precise simulation.
 * Timing is expressed in nanoseconds (ns) — caller converts to sc_time.
 */

class RegBlock {
public:
    RegBlock();

    /* Read a 32-bit register at byte offset `addr`, returns value */
    uint32_t read(uint64_t addr);

    /*
     * Write a 32-bit register at byte offset `addr`.
     * Returns: bit 0 set if IRQ state changed.
     * Out param `delay_ns`: emulation delay for this access.
     */
    bool write(uint64_t addr, uint32_t val, uint64_t *delay_ns = nullptr);

    /* Reset all registers to default state */
    void reset();

    /* Get/set MAC address */
    void set_mac(const uint8_t mac[6]);
    void get_mac(uint8_t mac[6]) const;

    /* Direct register access (for DMA engine integration) */
    uint32_t get_reg(unsigned idx) const { return m_regs[idx]; }
    void     set_reg(unsigned idx, uint32_t val) { m_regs[idx] = val; }

    /* IRQ state */
    uint32_t irq_status() const { return m_regs[SC_REG_IRQ_STS >> 2]; }
    void irq_clear(uint32_t bits) {
        m_regs[SC_REG_IRQ_STS >> 2] &= ~bits;
    }

    /* Last operation delay in ns */
    uint64_t last_delay_ns() const { return m_last_delay_ns; }

    /* Register access delay estimate for timing model */
    static constexpr uint64_t REG_ACCESS_NS = 10;  /* 10ns ≈ 100MHz register bus */

private:
    uint32_t m_regs[SC_REG_COUNT / 4];
    uint64_t m_last_delay_ns;
    uint8_t  m_mac[6];
};

#endif /* SMARTETH_SC_REG_BLOCK_H */
