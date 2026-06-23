#ifndef SMARTETH_SC_NET_IF_H
#define SMARTETH_SC_NET_IF_H

#include <systemc.h>
#include <cstdint>
#include <vector>
#include <mutex>
#include <atomic>
#include <thread>
#include <functional>

/*
 * NetIf — Network-side interface for SmartNic (Phase 4)
 *
 * Provides packet I/O via Unix Domain Socket side-channels.
 *   - NET_RX socket: test tool injects raw Ethernet frames into NIC
 *   - NET_TX socket: NIC sends TX packets out to test tool capture
 *
 * Protocol: [length:4][data:length] — length-prefixed raw Ethernet frames.
 */

class NetIf : public sc_core::sc_module {
public:
    /* Callback when a packet arrives from the network side */
    using RxCallback = std::function<void(const uint8_t* data, uint32_t len)>;

    SC_HAS_PROCESS(NetIf);

    NetIf(sc_core::sc_module_name name,
          const char *rx_socket_path = "/tmp/smarteth_net_rx.sock",
          const char *tx_socket_path = "/tmp/smarteth_net_tx.sock");
    ~NetIf() override;

    /* Called by SmartNic TX path: send packet out to network */
    void transmit(const uint8_t *data, uint32_t length);

    /* Register callback for incoming packets (set up by main.cpp) */
    void register_rx_callback(RxCallback cb) { m_rx_cb = std::move(cb); }

    /* SystemC event: notified when new RX packet arrives */
    sc_core::sc_event m_rx_event;

    /* Start listener threads (call before sc_start) */
    void start();

private:
    /* Listener thread: accepts test tool connection, reads packets */
    void listener_thread();

    std::string m_rx_path;
    std::string m_tx_path;

    int m_rx_listen_fd;
    int m_rx_fd;
    int m_tx_fd;

    std::thread m_thread;
    std::atomic<bool> m_running;

    RxCallback m_rx_cb;

    /* Protects TX writes from multiple SystemC threads */
    std::mutex m_tx_mtx;
};

#endif /* SMARTETH_SC_NET_IF_H */
