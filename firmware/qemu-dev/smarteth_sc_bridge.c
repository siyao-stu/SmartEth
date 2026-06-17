/*
 * SmartEth RISC-V Smart NIC — QEMU-SystemC Socket Bridge (QEMU QOM)
 *
 * PCIe endpoint that forwards MMIO transactions to a SystemC NIC model
 * via Unix Domain Socket, and handles DMA/MSI-X requests from SystemC.
 *
 * Architecture:
 *   QEMU (main thread):   MMIO handlers send requests and block on CV
 *                         (releases BQL during wait to avoid deadlock)
 *   QEMU (I/O thread):    Receives all messages from SystemC, dispatches:
 *     - MMIO_RESP: signals CV to wake blocking MMIO handler
 *     - DMA_READ/WRITE: acquires BQL, does pci_dma_{read,write}, releases BQL
 *     - MSI_IRQ: acquires BQL, calls msix_notify
 *
 * Usage:
 *   qemu-system-riscv64 -M virt -m 256M \
 *       -device smarteth-sc,socket-path=/tmp/sc_bridge.sock \
 *       -kernel smartnic_rtos.elf
 *
 * Then start SystemC model (it connects as client):
 *   ./smartnic_sc --socket-path=/tmp/sc_bridge.sock
 *
 * Copyright (c) 2026 SmartEth Project
 * SPDX-License-Identifier: MIT
 */

#include "qemu/osdep.h"
#include "qemu/log.h"
#include "qemu/units.h"
#include "hw/pci/pci.h"
#include "hw/pci/msi.h"
#include "hw/pci/msix.h"
#include "qemu/timer.h"
#include "qom/object.h"
#include "qemu/module.h"
#include "qemu/main-loop.h"
#include "qemu/thread.h"
#include "qemu/error-report.h"
#include "qapi/visitor.h"
#include "hw/core/qdev-properties.h"
#include "sc_protocol.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

/* ------------------------------------------------------------------ */
/*  Type & macro definitions                                          */
/* ------------------------------------------------------------------ */

#define TYPE_SMARTETH_SC_BRIDGE "smarteth-sc"
OBJECT_DECLARE_SIMPLE_TYPE(ScBridgeState, SMARTETH_SC_BRIDGE)

#define REG_COUNT       (SC_REG_COUNT / 4)  /* 256 x 32-bit */
#define DMA_BUF_SIZE    4096

/* ------------------------------------------------------------------ */
/*  Device state                                                      */
/* ------------------------------------------------------------------ */

struct ScBridgeState {
    PCIDevice pdev;
    MemoryRegion mmio;

    /* Socket — QEMU is server */
    char *socket_path;
    int listen_fd;
    int sock_fd;
    bool connected;

    /* I/O thread (reads all incoming messages from SystemC) */
    QemuThread io_thread;
    bool io_thread_running;

    /* Socket I/O mutex (protects sock_fd writes from main thread) */
    QemuMutex sock_mtx;

    /* MMIO response synchronization */
    QemuMutex mmio_mtx;
    QemuCond  mmio_cv;
    bool      mmio_pending;    /* true while waiting for MMIO response */
    uint32_t  mmio_resp_data;
    uint32_t  mmio_resp_status;

    /* Cached register values (for read without blocking) */
    uint32_t regs[REG_COUNT];
};

/* ------------------------------------------------------------------ */
/*  Socket helpers                                                    */
/* ------------------------------------------------------------------ */

static bool sc_bridge_send_all(int fd, const void *data, size_t len)
{
    const uint8_t *p = data;
    while (len > 0) {
        ssize_t n = write(fd, p, len);
        if (n <= 0) return false;
        p += n;
        len -= n;
    }
    return true;
}

static bool sc_bridge_recv_all(int fd, void *data, size_t len)
{
    uint8_t *p = data;
    while (len > 0) {
        ssize_t n = read(fd, p, len);
        if (n <= 0) return false;
        p += n;
        len -= n;
    }
    return true;
}

/* ------------------------------------------------------------------ */
/*  MMIO handlers (main thread, may block waiting for SystemC)        */
/* ------------------------------------------------------------------ */

static void sc_bridge_send_mmio_read(ScBridgeState *s, uint64_t addr)
{
    ScMmioReadReq req;

    req.hdr.type   = SC_MSG_MMIO_READ;
    req.hdr.length = sizeof(req) - sizeof(ScMsgHeader);
    req.addr       = addr;

    qemu_mutex_lock(&s->sock_mtx);
    if (s->sock_fd >= 0) {
        sc_bridge_send_all(s->sock_fd, &req, sizeof(req));
    }
    qemu_mutex_unlock(&s->sock_mtx);
}

static void sc_bridge_send_mmio_write(ScBridgeState *s, uint64_t addr,
                                       uint32_t val)
{
    ScMmioWriteMsg msg;

    msg.hdr.type   = SC_MSG_MMIO_WRITE;
    msg.hdr.length = sizeof(msg) - sizeof(ScMsgHeader);
    msg.addr       = addr;
    msg.data       = val;

    qemu_mutex_lock(&s->sock_mtx);
    if (s->sock_fd >= 0) {
        sc_bridge_send_all(s->sock_fd, &msg, sizeof(msg));
    }
    qemu_mutex_unlock(&s->sock_mtx);
}

static uint64_t sc_bridge_mmio_read(void *opaque, hwaddr addr,
                                     unsigned size)
{
    ScBridgeState *s = opaque;

    if (addr >= SC_REG_COUNT) {
        return 0;
    }

    if (!s->connected) {
        /* Not connected yet — return safe defaults for known registers */
        switch (addr) {
        case SC_REG_DEV_ID:
            return SC_DEV_ID;
        case SC_REG_STATUS:
            return SC_STATUS_READY;
        default:
            return s->regs[addr >> 2];
        }
    }

    /*
     * Set pending flag BEFORE sending the request.
     * This eliminates a TOCTOU race: without this ordering, the I/O thread
     * could receive and process the SystemC response (setting pending=false,
     * storing data, signalling CV) before the main thread sets pending=true.
     * The signal would be lost (no waiter), then pending=true would
     * overwrite the completion flag and the main thread would wait forever.
     *
     * With the flag set first, any response that arrives before we begin
     * waiting will already have cleared pending and stored the data;
     * the while-loop body is never entered and we read the pre-stored data.
     */
    qemu_mutex_lock(&s->mmio_mtx);
    s->mmio_pending = true;
    qemu_mutex_unlock(&s->mmio_mtx);

    sc_bridge_send_mmio_read(s, addr);

    /*
     * Wait for response from I/O thread.
     * Release BQL during wait to avoid deadlock (I/O thread needs BQL
     * for DMA/MSI operations).
     */
    bql_unlock();
    qemu_mutex_lock(&s->mmio_mtx);
    while (s->mmio_pending) {
        qemu_cond_wait(&s->mmio_cv, &s->mmio_mtx);
    }
    uint32_t result = s->mmio_resp_data;
    uint32_t status = s->mmio_resp_status;
    qemu_mutex_unlock(&s->mmio_mtx);
    bql_lock();

    /* On error, return cached value */
    if (status != SC_STATUS_OK) {
        return s->regs[addr >> 2];
    }

    /* Update local cache */
    s->regs[addr >> 2] = result;

    return result;
}

static void sc_bridge_mmio_write(void *opaque, hwaddr addr,
                                  uint64_t val, unsigned size)
{
    ScBridgeState *s = opaque;

    if (addr >= SC_REG_COUNT) {
        return;
    }

    /*
     * Local register handling:
     * Some registers have side effects we must handle locally
     * before (or instead of) forwarding to SystemC.
     */
    switch (addr) {
    case SC_REG_CTRL:
        if (val & SC_CTRL_RESET) {
            memset(s->regs, 0, sizeof(s->regs));
            s->regs[SC_REG_DEV_ID >> 2]  = SC_DEV_ID;
            s->regs[SC_REG_STATUS >> 2]  = SC_STATUS_READY;
            s->regs[SC_REG_MAC_LO >> 2]  = 0x00541234UL;
            s->regs[SC_REG_MAC_HI >> 2]  = 0x0056UL;
            break;  /* Don't forward reset to SystemC (it will be notified separately) */
        }
        s->regs[addr >> 2] = (uint32_t)val;
        break;

    case SC_REG_IRQ_STS:
        /* Write-1-to-clear */
        s->regs[addr >> 2] &= ~(uint32_t)val;
        break;

    case SC_REG_DMA_CTRL:
        s->regs[addr >> 2] = (uint32_t)val;
        if (val & SC_DMA_START) {
            s->regs[SC_REG_DMA_STS >> 2] = SC_STATUS_DMA_BSY;
        }
        break;

    case SC_REG_STATUS:
    case SC_REG_DEV_ID:
        /* Read-only — ignore writes */
        return;

    default:
        s->regs[addr >> 2] = (uint32_t)val;
        break;
    }

    /* Forward write to SystemC (fire-and-forget, no blocking) */
    if (s->connected) {
        sc_bridge_send_mmio_write(s, addr, (uint32_t)val);
    }
}

static const MemoryRegionOps sc_bridge_mmio_ops = {
    .read  = sc_bridge_mmio_read,
    .write = sc_bridge_mmio_write,
    .endianness = DEVICE_NATIVE_ENDIAN,
    .valid = {
        .min_access_size = 4,
        .max_access_size = 8,
    },
    .impl = {
        .min_access_size = 4,
        .max_access_size = 8,
    },
};

/* ------------------------------------------------------------------ */
/*  I/O thread — handles all incoming messages from SystemC           */
/* ------------------------------------------------------------------ */

static void sc_bridge_handle_dma_read(ScBridgeState *s,
                                       const ScDmaReadReq *req)
{
    uint8_t buf[DMA_BUF_SIZE];
    uint32_t len = MIN(req->length, DMA_BUF_SIZE);

    /* Needs BQL for pci_dma_read */
    bql_lock();
    pci_dma_read(&s->pdev, req->addr, buf, len);
    bql_unlock();

    /* Build response: header + status(4) + data(len) */
    size_t resp_size = sizeof(ScDmaReadResp) + len;
    uint8_t *resp = g_malloc(resp_size);
    ScDmaReadResp *hdr = (ScDmaReadResp *)resp;
    hdr->hdr.type   = SC_MSG_DMA_READ;
    hdr->hdr.length = sizeof(ScDmaReadResp) - sizeof(ScMsgHeader) + len;
    hdr->status     = SC_STATUS_OK;
    memcpy(resp + sizeof(ScDmaReadResp), buf, len);

    qemu_mutex_lock(&s->sock_mtx);
    if (s->sock_fd >= 0) {
        sc_bridge_send_all(s->sock_fd, resp, resp_size);
    }
    qemu_mutex_unlock(&s->sock_mtx);

    g_free(resp);
}

static void sc_bridge_handle_dma_write(ScBridgeState *s,
                                        const ScDmaWriteReq *req,
                                        const uint8_t *payload)
{
    /*
     * Payload layout after ScDmaWriteReq:
     *   [data: length bytes]
     * The data starts at offset sizeof(ScDmaWriteReq) from the original msg,
     * but in the caller we've already split header+payload, so the payload
     * passed here is the ScDmaWriteReq followed by data.
     *
     * Actually, the protocol sends:
     *   header: type(4) + length(4)
     *   payload: addr(8) + len(4) + data(len)
     *
     * After parsing the header, the payload pointer points to the data
     * starting at addr. So data is at payload + sizeof(ScDmaWriteReq) - sizeof(ScMsgHeader).
     */

    uint32_t len = MIN(req->length, DMA_BUF_SIZE);
    const uint8_t *data = payload + (sizeof(ScDmaWriteReq) - sizeof(ScMsgHeader));

    /* Needs BQL for pci_dma_write */
    bql_lock();
    pci_dma_write(&s->pdev, req->addr, data, len);
    bql_unlock();

    /* Send acknowledgment */
    ScDmaWriteResp resp;
    resp.hdr.type   = SC_MSG_DMA_WRITE;
    resp.hdr.length = sizeof(resp) - sizeof(ScMsgHeader);
    resp.status     = SC_STATUS_OK;

    qemu_mutex_lock(&s->sock_mtx);
    if (s->sock_fd >= 0) {
        sc_bridge_send_all(s->sock_fd, &resp, sizeof(resp));
    }
    qemu_mutex_unlock(&s->sock_mtx);
}

static void sc_bridge_handle_msi(ScBridgeState *s, const ScMsiIrqMsg *msg)
{
    /* Needs BQL for msix_notify */
    bql_lock();
    if (msix_enabled(&s->pdev)) {
        msix_notify(&s->pdev, msg->vector);
    }
    bql_unlock();
}

static void sc_bridge_handle_msg(ScBridgeState *s,
                                  uint32_t msg_type,
                                  const uint8_t *payload,
                                  uint32_t payload_len)
{
    switch (msg_type) {

    case SC_MSG_MMIO_READ: {
        /* SystemC responds to our MMIO read request */
        ScMmioReadResp resp;
        if (payload_len < sizeof(resp) - sizeof(ScMsgHeader)) {
            return;
        }
        memcpy(&resp.data,   payload,     4);
        memcpy(&resp.status, payload + 4, 4);

        qemu_mutex_lock(&s->mmio_mtx);
        s->mmio_resp_data   = resp.data;
        s->mmio_resp_status = resp.status;
        s->mmio_pending     = false;
        qemu_cond_signal(&s->mmio_cv);
        qemu_mutex_unlock(&s->mmio_mtx);
        break;
    }

    case SC_MSG_MMIO_WRITE: {
        /*
         * SystemC acknowledges the write.
         * MMIO writes are fire-and-forget — the main thread never waits on
         * mmio_cv for a write response.  DO NOT touch mmio_pending or
         * mmio_cv here: doing so would wake a concurrently waiting MMIO_READ
         * handler with stale data.
         */
        break;
    }

    case SC_MSG_DMA_READ: {
        ScDmaReadReq req;
        if (payload_len < sizeof(req) - sizeof(ScMsgHeader)) {
            return;
        }
        memcpy(&req.addr,   payload,     8);
        memcpy(&req.length, payload + 8, 4);
        sc_bridge_handle_dma_read(s, &req);
        break;
    }

    case SC_MSG_DMA_WRITE: {
        ScDmaWriteReq req;
        if (payload_len < sizeof(req) - sizeof(ScMsgHeader)) {
            return;
        }
        memcpy(&req.addr,   payload,     8);
        memcpy(&req.length, payload + 8, 4);
        sc_bridge_handle_dma_write(s, &req, payload);
        break;
    }

    case SC_MSG_MSI_IRQ: {
        ScMsiIrqMsg msg;
        if (payload_len < sizeof(msg) - sizeof(ScMsgHeader)) {
            return;
        }
        memcpy(&msg.vector, payload, 4);
        sc_bridge_handle_msi(s, &msg);
        break;
    }

    default:
        qemu_log_mask(LOG_GUEST_ERROR,
                      "[SC BRIDGE] Unknown message type: %u\n", msg_type);
        break;
    }
}

static void *sc_bridge_io_thread(void *opaque)
{
    ScBridgeState *s = opaque;

    /* Accept connection from SystemC */
    struct sockaddr_un peer;
    socklen_t peer_len = sizeof(peer);

    qemu_log("[SC BRIDGE] Waiting for SystemC connection on %s...\n",
             s->socket_path);

    s->sock_fd = accept(s->listen_fd, (struct sockaddr *)&peer, &peer_len);
    if (s->sock_fd < 0) {
        qemu_log("[SC BRIDGE] accept() failed: %s\n", strerror(errno));
        s->connected = false;
        return NULL;
    }

    qemu_log("[SC BRIDGE] SystemC connected.\n");
    s->connected = true;

    /* I/O loop: read messages from SystemC and dispatch */
    while (s->io_thread_running) {
        ScMsgHeader hdr;

        if (!sc_bridge_recv_all(s->sock_fd, &hdr, sizeof(hdr))) {
            if (s->io_thread_running) {
                qemu_log("[SC BRIDGE] Connection lost (read error: %s)\n",
                         strerror(errno));
            }
            break;
        }

        /* Read payload */
        uint8_t *payload = NULL;
        if (hdr.length > 0) {
            payload = g_malloc(hdr.length);
            if (!sc_bridge_recv_all(s->sock_fd, payload, hdr.length)) {
                qemu_log("[SC BRIDGE] Connection lost (payload read error)\n");
                g_free(payload);
                break;
            }
        }

        /* Process message */
        sc_bridge_handle_msg(s, hdr.type, payload, hdr.length);
        g_free(payload);
    }

    /* Cleanup */
    if (s->sock_fd >= 0) {
        close(s->sock_fd);
        s->sock_fd = -1;
    }
    s->connected = false;

    return NULL;
}

/* ------------------------------------------------------------------ */
/*  PCIe device lifecycle                                             */
/* ------------------------------------------------------------------ */

static void sc_bridge_realize(PCIDevice *pdev, Error **errp)
{
    ScBridgeState *s = SMARTETH_SC_BRIDGE(pdev);
    uint8_t *pci_conf = pdev->config;
    struct sockaddr_un addr;

    /* PCI config space */
    pci_config_set_interrupt_pin(pci_conf, 1);

    /* MMIO region (BAR0) */
    memory_region_init_io(&s->mmio, OBJECT(s), &sc_bridge_mmio_ops,
                          s, "smarteth-sc-mmio", SC_REG_COUNT);
    pci_register_bar(pdev, 0, PCI_BASE_ADDRESS_SPACE_MEMORY,
                     &s->mmio);

    /* MSI-X: 2 vectors, exclusive BAR (BAR1) */
    if (msix_init_exclusive_bar(pdev, 2, 1, errp)) {
        return;
    }

    /* Initialize mutexes and condition variable */
    qemu_mutex_init(&s->sock_mtx);
    qemu_mutex_init(&s->mmio_mtx);
    qemu_cond_init(&s->mmio_cv);

    /* Initialize cached registers */
    memset(s->regs, 0, sizeof(s->regs));
    s->regs[SC_REG_DEV_ID >> 2] = SC_DEV_ID;
    s->regs[SC_REG_STATUS >> 2] = SC_STATUS_READY;
    /* Default MAC address */
    s->regs[SC_REG_MAC_LO >> 2] = 0x00541234UL;
    s->regs[SC_REG_MAC_HI >> 2] = 0x0056UL;

    /* Create Unix domain socket server */
    if (!s->socket_path) {
        s->socket_path = g_strdup("/tmp/sc_bridge.sock");
    }
    s->listen_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (s->listen_fd < 0) {
        error_setg(errp, "[SC BRIDGE] Failed to create socket: %s",
                   strerror(errno));
        return;
    }

    /* Allow socket reuse */
    int opt = 1;
    setsockopt(s->listen_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, s->socket_path, sizeof(addr.sun_path) - 1);

    /* Remove stale socket file */
    unlink(s->socket_path);

    if (bind(s->listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        error_setg(errp, "[SC BRIDGE] bind(%s) failed: %s",
                   s->socket_path, strerror(errno));
        close(s->listen_fd);
        s->listen_fd = -1;
        return;
    }

    if (listen(s->listen_fd, 1) < 0) {
        error_setg(errp, "[SC BRIDGE] listen() failed: %s",
                   strerror(errno));
        close(s->listen_fd);
        s->listen_fd = -1;
        return;
    }

    /* Start I/O thread (will block on accept() until SystemC connects) */
    s->connected = false;
    s->sock_fd = -1;
    s->io_thread_running = true;
    qemu_thread_create(&s->io_thread, "smarteth-sc-io",
                        sc_bridge_io_thread, s, QEMU_THREAD_DETACHED);

    qemu_log("[SC BRIDGE] Socket server ready at %s\n", s->socket_path);
}

static void sc_bridge_exit(PCIDevice *pdev)
{
    ScBridgeState *s = SMARTETH_SC_BRIDGE(pdev);

    /* Signal I/O thread to stop */
    s->io_thread_running = false;

    /*
     * The I/O thread is detached, so we can't join it.
     * Close the socket to wake up any blocked read/accept.
     */
    if (s->sock_fd >= 0) {
        shutdown(s->sock_fd, SHUT_RDWR);
        close(s->sock_fd);
        s->sock_fd = -1;
    }
    if (s->listen_fd >= 0) {
        close(s->listen_fd);
        s->listen_fd = -1;
    }

    /* Wake any blocked MMIO handler */
    qemu_mutex_lock(&s->mmio_mtx);
    s->mmio_pending = false;
    qemu_cond_signal(&s->mmio_cv);
    qemu_mutex_unlock(&s->mmio_mtx);

    /* Clean up socket file */
    if (s->socket_path) {
        unlink(s->socket_path);
    }

    msix_uninit_exclusive_bar(pdev);

    qemu_mutex_destroy(&s->sock_mtx);
    qemu_mutex_destroy(&s->mmio_mtx);
    qemu_cond_destroy(&s->mmio_cv);
}

static void sc_bridge_instance_init(Object *obj)
{
    ScBridgeState *s = SMARTETH_SC_BRIDGE(obj);

    s->listen_fd = -1;
    s->sock_fd = -1;
    s->connected = false;
    /* socket_path is set from qdev property */
}

static void sc_bridge_instance_finalize(Object *obj)
{
    ScBridgeState *s = SMARTETH_SC_BRIDGE(obj);
    g_free(s->socket_path);
}

static const Property sc_bridge_props[] = {
    DEFINE_PROP_STRING("socket-path", ScBridgeState, socket_path),
};

static void sc_bridge_class_init(ObjectClass *class, const void *data)
{
    DeviceClass *dc = DEVICE_CLASS(class);
    PCIDeviceClass *k = PCI_DEVICE_CLASS(class);

    k->realize   = sc_bridge_realize;
    k->exit      = sc_bridge_exit;
    k->vendor_id = 0x1efd;
    k->device_id = 0x0001;
    k->revision  = 0x01;
    k->class_id  = PCI_CLASS_NETWORK_ETHERNET;
    set_bit(DEVICE_CATEGORY_NETWORK, dc->categories);

    dc->desc = "SmartEth NIC QEMU-SystemC Bridge";
    device_class_set_props(dc, sc_bridge_props);
}

static const TypeInfo sc_bridge_info[] = {
    {
        .name          = TYPE_SMARTETH_SC_BRIDGE,
        .parent        = TYPE_PCI_DEVICE,
        .instance_size = sizeof(ScBridgeState),
        .instance_init = sc_bridge_instance_init,
        .instance_finalize = sc_bridge_instance_finalize,
        .class_init    = sc_bridge_class_init,
        .interfaces = (const InterfaceInfo[]) {
            { INTERFACE_PCIE_DEVICE },
            { },
        },
    }
};

DEFINE_TYPES(sc_bridge_info)
