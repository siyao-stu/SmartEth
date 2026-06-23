#ifndef SMARTETH_SC_PROTOCOL_H
#define SMARTETH_SC_PROTOCOL_H

#include <cstdint>
#include <cstring>
#include <vector>

/*
 * SmartEth QEMU-SystemC 通信协议
 *
 * 基于 Unix Domain Socket 的简单二进制协议。
 * 每条消息: [type:4][payload...]
 *
 * 类型定义:
 */
enum class PcieMsgType : uint32_t {
    MMIO_READ      = 0,   /* QEMU→SC: addr(8)           | SC→QEMU: data(4)     */
    MMIO_WRITE     = 1,   /* QEMU→SC: addr(8)+data(4)   | SC→QEMU: status(4)   */
    DMA_READ       = 2,   /* SC→QEMU: addr(8)+len(4)    | QEMU→SC: data(len)   */
    DMA_WRITE      = 3,   /* SC→QEMU: addr(8)+len(4)+d  | QEMU→SC: status(4)   */
    MSI_IRQ        = 4,   /* SC→QEMU: vector(4)          | (one-way)            */
    BRIDGE_RESET   = 5,   /* QEMU→SC: (none)             | SC→QEMU: status(4)  */
};

/* Transaction status codes */
enum class PcieStatus : uint32_t {
    OK        = 0,
    ERR_BUSY  = 1,
    ERR_TIMEOUT = 2,
};

#pragma pack(push, 1)

/* Message header — first 8 bytes of every message */
struct MsgHeader {
    uint32_t type;   /* PcieMsgType */
    uint32_t length; /* payload length following header */
};

/* MMIO read request (QEMU → SystemC) */
struct MmioReadReq {
    MsgHeader hdr;   /* type=MMIO_READ, length=sizeof(MmioReadReq)-sizeof(MsgHeader) */
    uint64_t  addr;  /* register byte offset within BAR0 */
};

/* MMIO read response (SystemC → QEMU) */
struct MmioReadResp {
    MsgHeader hdr;   /* type=MMIO_READ, length=sizeof(MmioReadResp)-sizeof(MsgHeader) */
    uint32_t  data;
    uint32_t  status; /* PcieStatus */
};

/* MMIO write (QEMU → SystemC) */
struct MmioWriteMsg {
    MsgHeader hdr;   /* type=MMIO_WRITE */
    uint64_t  addr;
    uint32_t  data;
};

/* MMIO write response (SystemC → QEMU) */
struct MmioWriteResp {
    MsgHeader hdr;
    uint32_t  status;
};

/* DMA read request (SystemC → QEMU) — SystemC needs data from guest RAM */
struct DmaReadReq {
    MsgHeader hdr;   /* type=DMA_READ */
    uint64_t  addr;  /* guest physical address */
    uint32_t  length;
};

/* DMA read response (QEMU → SystemC) */
struct DmaReadResp {
    MsgHeader hdr;
    uint32_t  status;
    /* followed by `length` bytes of data */
};

/* DMA write request (SystemC → QEMU) — SystemC pushes data to guest RAM */
struct DmaWriteReq {
    MsgHeader hdr;   /* type=DMA_WRITE */
    uint64_t  addr;
    uint32_t  length;
    /* followed by `length` bytes of data */
};

/* DMA write response (QEMU → SystemC) */
struct DmaWriteResp {
    MsgHeader hdr;
    uint32_t  status;
};

/* MSI IRQ (SystemC → QEMU, one-way) */
struct MsiIrqMsg {
    MsgHeader hdr;   /* type=MSI_IRQ */
    uint32_t  vector;
};

#pragma pack(pop)

/* Register offsets (mirrors firmware/qemu-dev/smarteth_pci.c) */
enum ScRegOffset : uint64_t {
    SC_REG_CTRL            = 0x000,
    SC_REG_STATUS          = 0x004,
    SC_REG_IRQ_EN          = 0x008,
    SC_REG_IRQ_STS         = 0x00C,
    SC_REG_MAC_LO          = 0x010,
    SC_REG_MAC_HI          = 0x014,
    SC_REG_SCRATCH0        = 0x020,
    SC_REG_SCRATCH1        = 0x024,
    SC_REG_SCRATCH2        = 0x028,
    SC_REG_SCRATCH3        = 0x02C,
    SC_REG_DMA_SRC         = 0x040,
    SC_REG_DMA_DST         = 0x048,
    SC_REG_DMA_LEN         = 0x050,
    SC_REG_DMA_CTRL        = 0x058,
    SC_REG_DMA_STS         = 0x05C,
    /* Descriptor ring registers (Phase 4) */
    SC_REG_TX_RING_BASE_LO = 0x300,
    SC_REG_TX_RING_BASE_HI = 0x304,
    SC_REG_TX_RING_SIZE    = 0x308,
    SC_REG_TX_DOORBELL     = 0x30C,
    SC_REG_TX_TAIL         = 0x310,
    SC_REG_RX_RING_BASE_LO = 0x320,
    SC_REG_RX_RING_BASE_HI = 0x324,
    SC_REG_RX_RING_SIZE    = 0x328,
    SC_REG_RX_DOORBELL     = 0x32C,
    SC_REG_RX_TAIL         = 0x330,
    SC_REG_DEV_ID          = 0x100,
    SC_REG_IRQ_TEST        = 0x200,
    SC_REG_COUNT           = 0x400,
};

/* Control/status bits */
#define SC_CTRL_RESET      0x00000001
#define SC_STATUS_READY    0x00000001
#define SC_STATUS_DMA_BSY  0x00000002
#define SC_IRQ_DMA_DONE    0x00000001
#define SC_IRQ_TEST        0x00000002
#define SC_IRQ_TX_DONE     0x00000004
#define SC_IRQ_RX          0x00000008
#define SC_DMA_START       0x00000001
#define SC_DMA_DIR_WRITE   0x00000002
#define SC_DMA_IRQ_EN      0x00000004

/* Descriptor flags (Phase 4) */
#define SMARTETH_DESC_FLAG_OWN  0x80000000u
#define SMARTETH_DESC_FLAG_DONE 0x40000000u
#define SMARTETH_DESC_FLAG_ERR  0x20000000u

/* Descriptor ring entry — 16 bytes */
struct SmartEthDesc {
    uint64_t addr;    /* DMA address of packet buffer */
    uint32_t length;  /* buffer length / data length */
    uint32_t flags;   /* SMARTETH_DESC_FLAG_* */
} __attribute__((packed));

/* Device ID */
#define SC_DEV_ID          0x52414D53UL  /* "SMAR" */

/* Default MAC address */
#define SC_MAC_DEFAULT_LO  0x00541234UL  /* 52:54:00:12:34:56 → low 32 bits */
#define SC_MAC_DEFAULT_HI  0x0056UL      /* high 16 bits */

/* Helper: serialize a header + payload into a byte vector */
static inline std::vector<uint8_t> make_msg(PcieMsgType type,
                                             const void *payload,
                                             uint32_t payload_len)
{
    MsgHeader hdr;
    hdr.type   = static_cast<uint32_t>(type);
    hdr.length = payload_len;

    std::vector<uint8_t> buf(sizeof(MsgHeader) + payload_len);
    std::memcpy(buf.data(), &hdr, sizeof(MsgHeader));
    if (payload && payload_len > 0) {
        std::memcpy(buf.data() + sizeof(MsgHeader), payload, payload_len);
    }
    return buf;
}

#endif /* SMARTETH_SC_PROTOCOL_H */
