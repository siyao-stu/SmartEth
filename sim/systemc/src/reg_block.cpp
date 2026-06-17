#include "reg_block.h"
#include <cstring>

RegBlock::RegBlock()
    : m_regs{}
    , m_last_delay_ns(REG_ACCESS_NS)
{
    uint8_t def_mac[6] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x56};
    set_mac(def_mac);
}

void RegBlock::set_mac(const uint8_t mac[6])
{
    std::memcpy(m_mac, mac, 6);
    m_regs[SC_REG_MAC_LO >> 2] = (uint32_t)mac[0]
        | ((uint32_t)mac[1] << 8)
        | ((uint32_t)mac[2] << 16)
        | ((uint32_t)mac[3] << 24);
    m_regs[SC_REG_MAC_HI >> 2] = (uint32_t)mac[4]
        | ((uint32_t)mac[5] << 8);
}

void RegBlock::get_mac(uint8_t mac[6]) const
{
    uint32_t lo = m_regs[SC_REG_MAC_LO >> 2];
    uint32_t hi = m_regs[SC_REG_MAC_HI >> 2];
    mac[0] = (uint8_t)(lo & 0xFF);
    mac[1] = (uint8_t)((lo >> 8) & 0xFF);
    mac[2] = (uint8_t)((lo >> 16) & 0xFF);
    mac[3] = (uint8_t)((lo >> 24) & 0xFF);
    mac[4] = (uint8_t)(hi & 0xFF);
    mac[5] = (uint8_t)((hi >> 8) & 0xFF);
}

uint32_t RegBlock::read(uint64_t addr)
{
    m_last_delay_ns = REG_ACCESS_NS;

    if (addr >= SC_REG_COUNT) {
        return 0;
    }

    switch (addr) {
    case SC_REG_DEV_ID:
        return SC_DEV_ID;
    case SC_REG_STATUS:
        return SC_STATUS_READY;
    default:
        return m_regs[addr >> 2];
    }
}

bool RegBlock::write(uint64_t addr, uint32_t val, uint64_t *delay_ns)
{
    m_last_delay_ns = REG_ACCESS_NS;
    bool irq_changed = false;

    if (addr >= SC_REG_COUNT) {
        if (delay_ns) *delay_ns = m_last_delay_ns;
        return false;
    }

    switch (addr) {
    case SC_REG_CTRL:
        if (val & SC_CTRL_RESET) {
            reset();
            /* Re-store MAC after reset */
            set_mac(m_mac);
            /* Clear IRQ on reset */
            m_regs[SC_REG_IRQ_STS >> 2] = 0;
        } else {
            m_regs[SC_REG_CTRL >> 2] = val;
        }
        break;

    case SC_REG_IRQ_STS:
        /* Write-1-to-clear */
        m_regs[SC_REG_IRQ_STS >> 2] &= ~val;
        irq_changed = true;
        break;

    case SC_REG_DMA_CTRL:
        m_regs[SC_REG_DMA_CTRL >> 2] = val;
        break;

    case SC_REG_IRQ_TEST:
        if (val) {
            m_regs[SC_REG_IRQ_STS >> 2] |= SC_IRQ_TEST;
            irq_changed = true;
        }
        break;

    case SC_REG_STATUS:
    case SC_REG_DEV_ID:
        /* Read-only */
        break;

    default:
        m_regs[addr >> 2] = val;
        break;
    }

    if (delay_ns) *delay_ns = m_last_delay_ns;
    return irq_changed;
}

void RegBlock::reset()
{
    std::memset(m_regs, 0, sizeof(m_regs));
    m_regs[SC_REG_DMA_STS >> 2] = 0;
}
