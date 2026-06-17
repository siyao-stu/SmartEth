#ifndef SMARTETH_SC_NIC_H
#define SMARTETH_SC_NIC_H

#include <systemc.h>
#include "reg_block.h"
#include "dma_engine.h"
#include "pkt_proc.h"
#include "pcie_bridge.h"

/*
 * SmartEth NIC top-level SystemC module.
 *
 * Wires together: RegBlock, DmaEngine, PktProc, PcieBridge.
 * Handles MMIO dispatch, DMA coordination, and interrupt generation.
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

    /* Register MMIO/reset callbacks with the bridge (before socket start) */
    void register_callbacks();

    /* Start the socket thread (called after register_callbacks) */
    void start_bridge();

private:
    RegBlock   m_regs;
    DmaEngine  m_dma;
    PktProc    m_pkt;

    /* SystemC processes */
    void poll_irq();       /* SC_THREAD: poll IRQ state, send to QEMU */
    void process_dma();    /* SC_THREAD: handle DMA after MMIO write */

    /* Callbacks registered with PcieBridge */
    uint32_t on_mmio_read(uint64_t addr);
    void     on_mmio_write(uint64_t addr, uint32_t data);
    void     on_reset();

    /* Internal state */
    bool m_dma_pending;
};

#endif /* SMARTETH_SC_NIC_H */
