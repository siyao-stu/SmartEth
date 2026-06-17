#ifndef SMARTETH_SC_PROTOCOL_H
#define SMARTETH_SC_PROTOCOL_H

/*
 * SmartEth QEMU-SystemC 通信协议 (C-compatible)
 *
 * 基于 Unix Domain Socket 的简单二进制协议。
 * 每条消息: [type:4][length:4][payload...]
 *
 * 与 sim/systemc/src/protocol.h 保持同步。
 */

#include <stdint.h>

/* Message types */
#define SC_MSG_MMIO_READ      0   /* QEMU→SC: addr(8)           | SC→QEMU: data(4)+status(4) */
#define SC_MSG_MMIO_WRITE     1   /* QEMU→SC: addr(8)+data(4)   | SC→QEMU: status(4)        */
#define SC_MSG_DMA_READ       2   /* SC→QEMU: addr(8)+len(4)    | QEMU→SC: data(len)        */
#define SC_MSG_DMA_WRITE      3   /* SC→QEMU: addr(8)+len(4)+d  | QEMU→SC: status(4)        */
#define SC_MSG_MSI_IRQ        4   /* SC→QEMU: vector(4)          | (one-way)                 */
#define SC_MSG_BRIDGE_RESET   5   /* QEMU→SC: (none)             | SC→QEMU: status(4)        */

/* Status codes */
#define SC_STATUS_OK           0
#define SC_STATUS_ERR_BUSY     1
#define SC_STATUS_ERR_TIMEOUT  2

#pragma pack(push, 1)

/* Message header — first 8 bytes of every message */
typedef struct {
    uint32_t type;    /* SC_MSG_* */
    uint32_t length;  /* payload length following header */
} ScMsgHeader;

/* MMIO read request (QEMU → SystemC) */
typedef struct {
    ScMsgHeader hdr;  /* type=SC_MSG_MMIO_READ, length=8 */
    uint64_t  addr;   /* register byte offset within BAR0 */
} ScMmioReadReq;

/* MMIO read response (SystemC → QEMU) */
typedef struct {
    ScMsgHeader hdr;  /* type=SC_MSG_MMIO_READ, length=8 */
    uint32_t  data;
    uint32_t  status;
} ScMmioReadResp;

/* MMIO write (QEMU → SystemC) */
typedef struct {
    ScMsgHeader hdr;  /* type=SC_MSG_MMIO_WRITE, length=12 */
    uint64_t  addr;
    uint32_t  data;
} ScMmioWriteMsg;

/* MMIO write response (SystemC → QEMU) */
typedef struct {
    ScMsgHeader hdr;
    uint32_t  status;
} ScMmioWriteResp;

/* DMA read request (SystemC → QEMU) */
typedef struct {
    ScMsgHeader hdr;  /* type=SC_MSG_DMA_READ, length=12 */
    uint64_t  addr;   /* guest physical address */
    uint32_t  length;
} ScDmaReadReq;

/* DMA read response (QEMU → SystemC) — followed by `length` bytes */
typedef struct {
    ScMsgHeader hdr;
    uint32_t  status;
} ScDmaReadResp;

/* DMA write request (SystemC → QEMU) — followed by `length` bytes of data */
typedef struct {
    ScMsgHeader hdr;  /* type=SC_MSG_DMA_WRITE, length=12+length */
    uint64_t  addr;
    uint32_t  length;
} ScDmaWriteReq;

/* DMA write response (QEMU → SystemC) */
typedef struct {
    ScMsgHeader hdr;
    uint32_t  status;
} ScDmaWriteResp;

/* MSI IRQ (SystemC → QEMU, one-way) */
typedef struct {
    ScMsgHeader hdr;
    uint32_t  vector;
} ScMsiIrqMsg;

#pragma pack(pop)

/* Register offsets (mirrors firmware/qemu-dev/smarteth_pci.c) */
#define SC_REG_CTRL      0x000
#define SC_REG_STATUS    0x004
#define SC_REG_IRQ_EN    0x008
#define SC_REG_IRQ_STS   0x00C
#define SC_REG_MAC_LO    0x010
#define SC_REG_MAC_HI    0x014
#define SC_REG_SCRATCH0  0x020
#define SC_REG_SCRATCH1  0x024
#define SC_REG_SCRATCH2  0x028
#define SC_REG_SCRATCH3  0x02C
#define SC_REG_DMA_SRC   0x040
#define SC_REG_DMA_DST   0x048
#define SC_REG_DMA_LEN   0x050
#define SC_REG_DMA_CTRL  0x058
#define SC_REG_DMA_STS   0x05C
#define SC_REG_DEV_ID    0x100
#define SC_REG_IRQ_TEST  0x200
#define SC_REG_COUNT     0x400

/* Bits */
#define SC_CTRL_RESET     0x00000001
#define SC_STATUS_READY   0x00000001
#define SC_STATUS_DMA_BSY 0x00000002
#define SC_IRQ_DMA_DONE   0x00000001
#define SC_IRQ_TEST       0x00000002
#define SC_DMA_START      0x00000001
#define SC_DMA_IRQ_EN     0x00000004

/* Device ID */
#define SC_DEV_ID         0x52414D53UL  /* "SMAR" */

#endif /* SMARTETH_SC_PROTOCOL_H */
