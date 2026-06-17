#ifndef SMARTETH_SC_PCIE_BRIDGE_H
#define SMARTETH_SC_PCIE_BRIDGE_H

#include <systemc.h>
#include <thread>
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <vector>
#include "protocol.h"

/*
 * PCIe Transaction Bridge (SystemC side)
 *
 * Connects to QEMU via Unix Domain Socket and translates
 * raw protocol messages into SystemC method calls.
 *
 * Runs a POSIX socket listener thread that pushes received
 * messages into a queue; the SystemC SC_METHOD polls the queue
 * via m_irq_event notification.
 */

class PcieBridge : public sc_core::sc_module {
public:
    /* Callbacks for incoming QEMU messages */
    using MmioReadCb  = std::function<uint32_t(uint64_t addr)>;
    using MmioWriteCb = std::function<void(uint64_t addr, uint32_t data)>;
    using ResetCb     = std::function<void()>;

    SC_HAS_PROCESS(PcieBridge);

    PcieBridge(sc_core::sc_module_name name, const char *socket_path);
    ~PcieBridge() override;

    /* Register callbacks from the NIC model */
    void register_mmio_read(MmioReadCb cb)  { m_mmio_read_cb = cb; }
    void register_mmio_write(MmioWriteCb cb) { m_mmio_write_cb = cb; }
    void register_reset(ResetCb cb)          { m_reset_cb = cb; }

    /* Send DMA read request to QEMU (blocking, called from DMA engine) */
    bool dma_read(uint64_t addr, uint32_t len, uint8_t *buf);

    /* Send DMA write request to QEMU (blocking) */
    bool dma_write(uint64_t addr, uint32_t len, const uint8_t *buf);

    /* Send MSI-X interrupt to QEMU (non-blocking) */
    void send_irq(uint32_t vector);

    /* SystemC event for incoming message notification */
    sc_core::sc_event m_irq_event;

    /* Start the socket thread (connects to QEMU) */
    void start();

    /* Check if socket thread is running */
    bool is_running() const { return m_running.load(); }

    /* Called by SC_METHOD when socket thread receives data */
    void irq_handler();

private:
    /* Socket thread: reads from QEMU, dispatches */
    void socket_thread();

    /* Process one incoming message (called from socket thread) */
    void handle_message(const MsgHeader &hdr,
                         const uint8_t *payload);

    /* Send raw data to QEMU */
    bool send_all(const uint8_t *data, size_t len);

    /* Socket */
    int m_sock_fd;
    std::string m_socket_path;
    std::atomic<bool> m_running;

    /* Thread */
    std::thread m_thread;

    /* Sync for DMA responses */
    std::mutex m_dma_mtx;
    std::condition_variable m_dma_cv;
    std::vector<uint8_t> m_dma_resp;
    bool m_dma_pending = false;

    /* Callbacks */
    MmioReadCb  m_mmio_read_cb;
    MmioWriteCb m_mmio_write_cb;
    ResetCb     m_reset_cb;
};

#endif /* SMARTETH_SC_PCIE_BRIDGE_H */
