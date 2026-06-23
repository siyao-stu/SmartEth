#include "nic.h"
#include "pcie_bridge.h"
#include "net_if.h"
#include <iostream>
#include <csignal>
#include <cstring>
#include <thread>
#include <chrono>

/*
 * SmartEth SystemC NIC Simulation — Main Entry Point
 *
 * Connects to QEMU via Unix Domain Socket and simulates
 * the Smart NIC hardware model (registers, DMA, packet proc).
 *
 * Phase 4: also connects to NetIf for packet I/O side-channels.
 *
 * Usage:
 *   ./smartnic_sc --socket-path=/tmp/sc_bridge.sock
 *   ./smartnic_sc --socket-path=/tmp/sc_bridge.sock \
 *                 --net-rx-path=/tmp/smarteth_net_rx.sock \
 *                 --net-tx-path=/tmp/smarteth_net_tx.sock
 */

static bool g_running = true;
static void signal_handler(int) { g_running = false; }

int sc_main(int argc, char *argv[])
{
    const char *socket_path = "/tmp/sc_bridge.sock";
    const char *net_rx_path = nullptr;  /* Phase 4: optional */
    const char *net_tx_path = nullptr;

    /* Parse args */
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--socket-path=", 14) == 0) {
            socket_path = argv[i] + 14;
        } else if (strncmp(argv[i], "--net-rx-path=", 14) == 0) {
            net_rx_path = argv[i] + 14;
        } else if (strncmp(argv[i], "--net-tx-path=", 14) == 0) {
            net_tx_path = argv[i] + 14;
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            std::cout << "Usage: " << argv[0] << " [options]\n"
                      << "  --socket-path=PATH   QEMU bridge socket (default: /tmp/sc_bridge.sock)\n"
                      << "  --net-rx-path=PATH   NetIf RX socket (Phase 4, optional)\n"
                      << "  --net-tx-path=PATH   NetIf TX socket (Phase 4, optional)\n";
            return 0;
        }
    }

    std::cout << "[SC NIC] SmartEth SystemC NIC model starting...\n"
              << "  Socket: " << socket_path << "\n";

    /* Create SystemC modules */
    PcieBridge bridge("pcie_bridge", socket_path);
    SmartNic    nic("smart_nic");

    nic.set_bridge(&bridge);
    nic.register_callbacks();

    /* Phase 4: optional NetIf for packet I/O */
    NetIf *netif = nullptr;
    if (net_rx_path && net_tx_path) {
        netif = new NetIf("net_if", net_rx_path, net_tx_path);
        nic.set_netif(netif);

        /* Wire up RX callback: network packet → NIC processing */
        netif->register_rx_callback(
            [&nic](const uint8_t *data, uint32_t len) {
                nic.on_packet_rx(data, len);
            });

        netif->start();
        std::cout << "[SC NIC] NetIf started: RX=" << net_rx_path
                  << " TX=" << net_tx_path << "\n";
    } else {
        std::cout << "[SC NIC] No NetIf configured (Phase 3 compatibility mode)\n";
    }

    /* Register signal handler for clean shutdown */
    std::signal(SIGINT,  signal_handler);
    std::signal(SIGTERM, signal_handler);

    /* Launch socket thread (connects to QEMU) */
    try {
        nic.start_bridge();
    } catch (const std::exception &e) {
        std::cerr << "[SC NIC] Failed to start bridge thread: " << e.what() << "\n";
        delete netif;
        return 1;
    }

    /* Wait for connection to QEMU (retry up to ~10s) */
    std::cout << "[SC NIC] Waiting for connection to QEMU...\n";
    for (int retry = 0; retry < 100; retry++) {
        if (bridge.is_running()) {
            std::cout << "[SC NIC] Connected to QEMU.\n";
            break;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    if (!bridge.is_running()) {
        std::cerr << "[SC NIC] ERROR: Failed to connect to QEMU at "
                  << socket_path << "\n"
                  << "  Ensure QEMU with smarteth-sc device is running.\n";
        delete netif;
        return 1;
    }

    std::cout << "[SC NIC] Starting SystemC simulation...\n";

    /* Main simulation loop */
    while (g_running) {
        sc_core::sc_start(1, sc_core::SC_MS);

        if (sc_core::sc_end_of_simulation_invoked()) {
            g_running = false;
        }
    }

    std::cout << "[SC NIC] Simulation stopped.\n";
    delete netif;
    return 0;
}
