#include "pcie_bridge.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cstring>
#include <iostream>
#include <thread>
#include <chrono>

PcieBridge::PcieBridge(sc_core::sc_module_name name, const char *socket_path)
    : sc_module(name)
    , m_sock_fd(-1)
    , m_socket_path(socket_path)
    , m_running(false)
{
    SC_METHOD(irq_handler);
    sensitive << m_irq_event;
    dont_initialize();
}

void PcieBridge::start()
{
    m_thread = std::thread(&PcieBridge::socket_thread, this);
}

PcieBridge::~PcieBridge()
{
    m_running = false;
    if (m_sock_fd >= 0) {
        ::shutdown(m_sock_fd, SHUT_RDWR);
        ::close(m_sock_fd);
    }
    if (m_thread.joinable()) {
        m_thread.join();
    }
}

void PcieBridge::irq_handler()
{
    /* SC_METHOD: triggered when socket thread receives a message.
     * The NIC module hooks into this via m_irq_event.
     * The method body is empty — the NIC module uses the event
     * sensitivity to drive its own processing. */
}

bool PcieBridge::send_all(const uint8_t *data, size_t len)
{
    while (len > 0) {
        ssize_t n = ::write(m_sock_fd, data, len);
        if (n <= 0) return false;
        data += n;
        len  -= n;
    }
    return true;
}

void PcieBridge::handle_message(const MsgHeader &hdr,
                                 const uint8_t *payload)
{
    switch (static_cast<PcieMsgType>(hdr.type)) {

    case PcieMsgType::MMIO_READ: {
        uint64_t addr = 0;
        std::memcpy(&addr, payload, sizeof(addr));

        uint32_t val = 0;
        if (m_mmio_read_cb) {
            val = m_mmio_read_cb(addr);
        }

        MmioReadResp resp;
        resp.hdr.type   = static_cast<uint32_t>(PcieMsgType::MMIO_READ);
        resp.hdr.length = sizeof(resp) - sizeof(MsgHeader);
        resp.data   = val;
        resp.status = static_cast<uint32_t>(PcieStatus::OK);

        auto msg = make_msg(PcieMsgType::MMIO_READ,
                            reinterpret_cast<const uint8_t*>(&resp) + sizeof(MsgHeader),
                            resp.hdr.length);
        send_all(msg.data(), msg.size());
        break;
    }

    case PcieMsgType::MMIO_WRITE: {
        uint64_t addr = 0;
        uint32_t data_val = 0;
        std::memcpy(&addr, payload, sizeof(addr));
        std::memcpy(&data_val, payload + sizeof(addr), sizeof(data_val));

        if (m_mmio_write_cb) {
            m_mmio_write_cb(addr, data_val);
        }

        MmioWriteResp resp;
        resp.hdr.type   = static_cast<uint32_t>(PcieMsgType::MMIO_WRITE);
        resp.hdr.length = sizeof(resp) - sizeof(MsgHeader);
        resp.status     = static_cast<uint32_t>(PcieStatus::OK);

        auto msg_out = make_msg(PcieMsgType::MMIO_WRITE,
                                reinterpret_cast<const uint8_t*>(&resp) + sizeof(MsgHeader),
                                resp.hdr.length);
        send_all(msg_out.data(), msg_out.size());
        break;
    }

    case PcieMsgType::BRIDGE_RESET:
        if (m_reset_cb) m_reset_cb();

        {
            MmioWriteResp resp;
            resp.hdr.type   = static_cast<uint32_t>(PcieMsgType::BRIDGE_RESET);
            resp.hdr.length = sizeof(resp) - sizeof(MsgHeader);
            resp.status     = static_cast<uint32_t>(PcieStatus::OK);
            auto msg_out = make_msg(PcieMsgType::BRIDGE_RESET,
                                    reinterpret_cast<const uint8_t*>(&resp) + sizeof(MsgHeader),
                                    resp.hdr.length);
            send_all(msg_out.data(), msg_out.size());
        }
        break;

    case PcieMsgType::DMA_READ: {
        /* QEMU responds with data from guest RAM */
        uint32_t status = 0;
        std::memcpy(&status, payload, sizeof(status));

        {
            std::lock_guard<std::mutex> lk(m_dma_mtx);
            uint32_t data_len = hdr.length - sizeof(uint32_t);
            m_dma_resp.resize(data_len);
            std::memcpy(m_dma_resp.data(), payload + sizeof(uint32_t), data_len);
            m_dma_pending = false;
        }
        m_dma_cv.notify_one();
        break;
    }

    case PcieMsgType::DMA_WRITE: {
        /* QEMU acknowledges DMA write completion */
        {
            std::lock_guard<std::mutex> lk(m_dma_mtx);
            m_dma_pending = false;
        }
        m_dma_cv.notify_one();
        break;
    }

    default:
        break;
    }
}

void PcieBridge::socket_thread()
{
    /* Create UNIX domain socket (client) */
    m_sock_fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (m_sock_fd < 0) {
        std::cerr << "[SC BRIDGE] Failed to create socket\n";
        return;
    }

    struct sockaddr_un addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, m_socket_path.c_str(),
                 sizeof(addr.sun_path) - 1);

    /* Retry connecting to QEMU server (up to ~10s) */
    int retries = 0;
    while (true) {
        if (::connect(m_sock_fd, (struct sockaddr*)&addr, sizeof(addr)) == 0) {
            break;
        }
        if (++retries >= 100) {
            std::cerr << "[SC BRIDGE] Failed to connect to " << m_socket_path
                      << " after 100 retries (is QEMU running?)\n";
            ::close(m_sock_fd);
            m_sock_fd = -1;
            return;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    std::cout << "[SC BRIDGE] Connected to QEMU at " << m_socket_path
              << std::endl;

    m_running = true;

    /* Message receive loop */
    while (m_running) {
        MsgHeader hdr;
        ssize_t n = ::read(m_sock_fd, &hdr, sizeof(hdr));
        if (n <= 0) {
            break;  /* connection closed or error */
        }

        if (hdr.length > 0) {
            std::vector<uint8_t> payload(hdr.length);
            size_t remaining = hdr.length;
            uint8_t *p = payload.data();
            while (remaining > 0) {
                ssize_t r = ::read(m_sock_fd, p, remaining);
                if (r <= 0) {
                    m_running = false;
                    return;
                }
                p += r;
                remaining -= r;
            }
            handle_message(hdr, payload.data());
        } else {
            handle_message(hdr, nullptr);
        }

        /* Notify SystemC */
        m_irq_event.notify(sc_core::SC_ZERO_TIME);
    }

    ::close(m_sock_fd);
    m_sock_fd = -1;
}

bool PcieBridge::dma_read(uint64_t addr, uint32_t len, uint8_t *buf)
{
    if (m_sock_fd < 0) return false;

    DmaReadReq req;
    req.hdr.type   = static_cast<uint32_t>(PcieMsgType::DMA_READ);
    req.hdr.length = sizeof(req) - sizeof(MsgHeader);
    req.addr   = addr;
    req.length = len;

    DmaReadResp resp;
    resp.hdr.type   = static_cast<uint32_t>(PcieMsgType::DMA_READ);
    resp.hdr.length = sizeof(resp) - sizeof(MsgHeader) + len;
    resp.status     = static_cast<uint32_t>(PcieStatus::OK);

    /* Build message: header + addr(8) + len(4) */
    std::vector<uint8_t> msg(sizeof(MsgHeader) + sizeof(uint64_t) + sizeof(uint32_t));
    std::memcpy(msg.data(), &req, sizeof(MsgHeader) + sizeof(uint64_t) + sizeof(uint32_t));

    {
        std::lock_guard<std::mutex> lk(m_dma_mtx);
        m_dma_pending = true;
        m_dma_resp.clear();
    }

    if (!send_all(msg.data(), msg.size())) {
        m_dma_pending = false;
        return false;
    }

    /* Wait for response: header + data */
    {
        std::unique_lock<std::mutex> lk(m_dma_mtx);
        if (m_dma_cv.wait_for(lk, std::chrono::seconds(5),
                              [this]{ return !m_dma_pending; })) {
            /* Copy response data */
            if (!m_dma_resp.empty()) {
                uint32_t copy_len = std::min((uint32_t)m_dma_resp.size(), len);
                std::memcpy(buf, m_dma_resp.data(), copy_len);
            }
            return true;
        }
    }

    return false;  /* timeout */
}

bool PcieBridge::dma_write(uint64_t addr, uint32_t len, const uint8_t *buf)
{
    if (m_sock_fd < 0) return false;

    /* Build: header + addr(8) + len(4) + data(len) */
    std::vector<uint8_t> msg(sizeof(MsgHeader) + sizeof(uint64_t) + sizeof(uint32_t) + len);
    MsgHeader hdr;
    hdr.type   = static_cast<uint32_t>(PcieMsgType::DMA_WRITE);
    hdr.length = sizeof(uint64_t) + sizeof(uint32_t) + len;

    std::memcpy(msg.data(), &hdr, sizeof(MsgHeader));
    std::memcpy(msg.data() + sizeof(MsgHeader), &addr, sizeof(addr));
    std::memcpy(msg.data() + sizeof(MsgHeader) + sizeof(addr), &len, sizeof(len));
    std::memcpy(msg.data() + sizeof(MsgHeader) + sizeof(addr) + sizeof(len), buf, len);

    return send_all(msg.data(), msg.size());
}

void PcieBridge::send_irq(uint32_t vector)
{
    if (m_sock_fd < 0) return;

    MsiIrqMsg msg;
    msg.hdr.type   = static_cast<uint32_t>(PcieMsgType::MSI_IRQ);
    msg.hdr.length = sizeof(msg) - sizeof(MsgHeader);
    msg.vector = vector;

    auto buf = make_msg(PcieMsgType::MSI_IRQ,
                        reinterpret_cast<const uint8_t*>(&msg) + sizeof(MsgHeader),
                        msg.hdr.length);
    send_all(buf.data(), buf.size());
}
