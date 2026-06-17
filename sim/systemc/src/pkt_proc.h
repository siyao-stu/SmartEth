#ifndef SMARTETH_SC_PKT_PROC_H
#define SMARTETH_SC_PKT_PROC_H

#include <cstdint>
#include <vector>
#include <functional>

/*
 * Packet processing pipeline — models Ethernet frame parsing,
 * filtering, and checksum offload.
 *
 * Pipeline stages (each adds timing delay):
 *   1. Frame preemble/SFD detection (8 bytes)
 *   2. MAC DA/SA parsing + address filter
 *   3. EtherType / VLAN parsing
 *   4. Payload DMA to host buffer
 *   5. CRC check
 */

struct PacketDescriptor {
    uint8_t* data;           /* raw frame data (incl. CRC) */
    uint32_t length;         /* total length */
    uint32_t payload_offset; /* offset to L3 payload */
    uint16_t ethertype;
    uint8_t  dest_mac[6];
    uint8_t  src_mac[6];
    bool     crc_valid;
};

class PktProc {
public:
    PktProc();

    /* Process an incoming frame. Returns delay in ns. */
    uint64_t receive(const uint8_t *frame, uint32_t length);

    /* Get the parsed descriptor from the last receive */
    const PacketDescriptor& last_pkt() const { return m_pkt; }

    /* Pipeline stage delays (ns) */
    static constexpr uint64_t STAGE_PREAMBLE_NS  = 80;   /* 8 bytes @ 10ns/byte */
    static constexpr uint64_t STAGE_MAC_FILTER_NS = 20;   /* address match */
    static constexpr uint64_t STAGE_ETYPE_PARSE_NS = 10;  /* EtherType decode */
    static constexpr uint64_t STAGE_CRC_CHECK_NS  = 40;   /* CRC-32 */

    /* Total per-packet processing */
    static constexpr uint64_t PKT_PROC_NS =
        STAGE_PREAMBLE_NS + STAGE_MAC_FILTER_NS +
        STAGE_ETYPE_PARSE_NS + STAGE_CRC_CHECK_NS;

private:
    PacketDescriptor m_pkt;
    std::vector<uint8_t> m_buf;

    void parse_mac(const uint8_t *frame);
    uint16_t parse_ethertype(const uint8_t *frame);
    bool check_crc32(const uint8_t *frame, uint32_t length);
};

#endif /* SMARTETH_SC_PKT_PROC_H */
