#ifndef SMARTETH_SC_NIC_H
#define SMARTETH_SC_NIC_H

#include <systemc.h>
#include "reg_block.h"
#include "dma_engine.h"
#include "pkt_proc.h"
#include "pcie_bridge.h"
#include "net_if.h"

/*
 * SmartEth NIC top-level SystemC module.
 *
 * Wires together: RegBlock, DmaEngine, PktProc, PcieBridge, NetIf.
 * Handles MMIO dispatch, DMA coordination, descriptor ring processing,
 * and interrupt generation.
 */

class SmartNic : public sc_core::sc_module {
public:
    /* Bridge to QEMU (injected, not owned) */
    PcieBridge *bridge;

    SC_HAS_PROCESS(SmartNic);

    SmartNic(sc_core::sc_module_name name);
    ~SmartNic() override = default;

    /* Register a PcieBridge instance */
    void set_bridge(PcieBridge *b) { bridge = b; }

    /* Register a NetIf instance (Phase 4, may be null) */
    void set_netif(NetIf *n) { m_netif = n; }

    /* Register MMIO/reset callbacks with the bridge (before socket start) */
    void register_callbacks();

    /* Start the socket thread (called after register_callbacks) */
    void start_bridge();

    /* Called from NetIf listener thread when a packet arrives */
    void on_packet_rx(const uint8_t *data, uint32_t len);

private:
    RegBlock   m_regs;
    DmaEngine  m_dma;
    PktProc    m_pkt;
    NetIf     *m_netif;  /* may be null (Phase 3 mode) */

    /* SystemC processes */
    void poll_irq();       /* SC_THREAD: poll IRQ state, send to QEMU */
    void process_dma();    /* SC_THREAD: handle DMA after MMIO write */
    void process_tx();     /* SC_THREAD: process TX descriptor ring (Phase 4) */
    void process_rx();     /* SC_THREAD: process RX packet delivery (Phase 4) */

    /* Callbacks registered with PcieBridge */
    uint32_t on_mmio_read(uint64_t addr);
    void     on_mmio_write(uint64_t addr, uint32_t data);
    void     on_reset();

    /* Internal state */
    bool m_dma_pending;
    bool m_tx_pending;
    sc_core::sc_event m_tx_event;  /* triggered by TX doorbell write */

    /* DMA bridge helpers */
    bool dma_read_bridge(uint64_t addr, uint32_t len, uint8_t *buf);
    bool dma_write_bridge(uint64_t addr, uint32_t len, const uint8_t *buf);
};

#endif /* SMARTETH_SC_NIC_H */
