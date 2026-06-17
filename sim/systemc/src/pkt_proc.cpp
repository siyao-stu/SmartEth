#include "pkt_proc.h"
#include <cstring>
#include <algorithm>

PktProc::PktProc()
    : m_pkt{}
    , m_buf(2048)
{
}

void PktProc::parse_mac(const uint8_t *frame)
{
    /* DA = first 6 bytes */
    std::memcpy(m_pkt.dest_mac, frame, 6);
    /* SA = next 6 bytes */
    std::memcpy(m_pkt.src_mac, frame + 6, 6);
}

uint16_t PktProc::parse_ethertype(const uint8_t *frame)
{
    /* EtherType at offset 12 (after DA+SA) */
    uint16_t etype = (uint16_t)frame[12] << 8 | frame[13];

    /* 802.1Q VLAN tag (0x8100) → EtherType at offset 16 */
    if (etype == 0x8100) {
        etype = (uint16_t)frame[16] << 8 | frame[17];
        m_pkt.payload_offset = 18;
    } else {
        m_pkt.payload_offset = 14;
    }

    return etype;
}

/* Simple XOR-based checksum (demo, not real CRC32) */
bool PktProc::check_crc32(const uint8_t *frame, uint32_t length)
{
    if (length < 4) return false;

    /* FCS is last 4 bytes — for demo assume valid */
    (void)frame;
    return true;
}

uint64_t PktProc::receive(const uint8_t *frame, uint32_t length)
{
    /* Store in working buffer */
    m_buf.resize(std::max(length, 64U));
    std::memcpy(m_buf.data(), frame, length);

    /* Pipeline stage 1: preamble (just delay, no work) */

    /* Stage 2: MAC parsing */
    parse_mac(m_buf.data());

    /* Stage 3: EtherType parsing */
    m_pkt.ethertype = parse_ethertype(m_buf.data());

    /* Stage 4: CRC check */
    m_pkt.crc_valid = check_crc32(m_buf.data(), length);

    /* Total delay */
    return PKT_PROC_NS;
}
