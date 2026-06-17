#include "nic.h"
#include "pcie_bridge.h"
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
 * QEMU is the socket server, SystemC is the client.
 *
 * Usage:
 *   ./smartnic_sc --socket-path=/tmp/sc_bridge.sock
 *
 * Then start QEMU with -device smarteth-sc,chardev=bridge0
 */

static bool g_running = true;
static void signal_handler(int) { g_running = false; }

int sc_main(int argc, char *argv[])
{
    const char *socket_path = "/tmp/sc_bridge.sock";

    /* Parse args */
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--socket-path=", 14) == 0) {
            socket_path = argv[i] + 14;
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            std::cout << "Usage: " << argv[0] << " [--socket-path=PATH]\n"
                      << "  Default socket: /tmp/sc_bridge.sock\n";
            return 0;
        }
    }

    std::cout << "[SC NIC] SmartEth SystemC NIC model starting...\n"
              << "  Socket: " << socket_path << "\n";

    /* Create SystemC modules */
    PcieBridge bridge("pcie_bridge", socket_path);
    SmartNic    nic("smart_nic");

    /*
     * Init sequence:
     *   1. set_bridge — stores bridge pointer in nic
     *   2. register_callbacks — registers MMIO/reset handlers with bridge
     *      (MUST happen before socket thread starts, otherwise race)
     *   3. start_bridge — launches socket thread, connects to QEMU
     */
    nic.set_bridge(&bridge);
    nic.register_callbacks();

    /* Register signal handler for clean shutdown */
    std::signal(SIGINT,  signal_handler);
    std::signal(SIGTERM, signal_handler);

    /* Launch socket thread (connects to QEMU) */
    try {
        nic.start_bridge();
    } catch (const std::exception &e) {
        std::cerr << "[SC NIC] Failed to start bridge thread: " << e.what() << "\n";
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
    return 0;
}
