#include "net_if.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cstring>
#include <iostream>

NetIf::NetIf(sc_core::sc_module_name name,
             const char *rx_socket_path,
             const char *tx_socket_path)
    : sc_module(name)
    , m_rx_path(rx_socket_path)
    , m_tx_path(tx_socket_path)
    , m_rx_listen_fd(-1)
    , m_rx_fd(-1)
    , m_tx_fd(-1)
    , m_running(false)
{
}

NetIf::~NetIf()
{
    m_running = false;
    if (m_rx_fd >= 0) ::close(m_rx_fd);
    if (m_rx_listen_fd >= 0) ::close(m_rx_listen_fd);
    if (m_tx_fd >= 0) ::close(m_tx_fd);
    if (m_thread.joinable()) m_thread.join();
    ::unlink(m_rx_path.c_str());
    ::unlink(m_tx_path.c_str());
}

void NetIf::start()
{
    ::unlink(m_rx_path.c_str());
    ::unlink(m_tx_path.c_str());

    /* Create RX listener socket (test tool connects here to inject packets) */
    struct sockaddr_un addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, m_rx_path.c_str(), sizeof(addr.sun_path) - 1);

    m_rx_listen_fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (m_rx_listen_fd < 0) {
        std::cerr << "[NetIf] ERROR: cannot create RX socket" << std::endl;
        return;
    }
    if (::bind(m_rx_listen_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        std::cerr << "[NetIf] ERROR: cannot bind RX socket: " << m_rx_path << std::endl;
        return;
    }
    ::listen(m_rx_listen_fd, 1);

    /* Create TX listener socket (test tool connects here to capture TX packets) */
    struct sockaddr_un tx_addr;
    std::memset(&tx_addr, 0, sizeof(tx_addr));
    tx_addr.sun_family = AF_UNIX;
    std::strncpy(tx_addr.sun_path, m_tx_path.c_str(), sizeof(tx_addr.sun_path) - 1);

    m_tx_fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (m_tx_fd < 0) {
        std::cerr << "[NetIf] ERROR: cannot create TX socket" << std::endl;
        return;
    }
    if (::bind(m_tx_fd, (struct sockaddr*)&tx_addr, sizeof(tx_addr)) < 0) {
        std::cerr << "[NetIf] ERROR: cannot bind TX socket: " << m_tx_path << std::endl;
        return;
    }
    ::listen(m_tx_fd, 1);

    /* Accept exactly one TX capture connection */
    struct sockaddr_un peer;
    socklen_t peer_len = sizeof(peer);
    int tx_conn = ::accept(m_tx_fd, (struct sockaddr*)&peer, &peer_len);
    ::close(m_tx_fd);
    m_tx_fd = tx_conn;

    std::cout << "[NetIf] TX capture connected" << std::endl;

    /* Start RX listener thread */
    m_running = true;
    m_thread = std::thread(&NetIf::listener_thread, this);
}

void NetIf::listener_thread()
{
    /* Accept one RX injection connection */
    struct sockaddr_un peer;
    socklen_t peer_len = sizeof(peer);
    m_rx_fd = ::accept(m_rx_listen_fd, (struct sockaddr*)&peer, &peer_len);
    ::close(m_rx_listen_fd);
    m_rx_listen_fd = -1;

    std::cout << "[NetIf] RX injector connected" << std::endl;

    /* Read packets: each message is [length:4][data:length] */
    while (m_running) {
        uint32_t pkt_len;
        ssize_t n = ::read(m_rx_fd, &pkt_len, sizeof(pkt_len));
        if (n <= 0) break;

        if (pkt_len == 0 || pkt_len > 16384) continue;

        std::vector<uint8_t> buf(pkt_len);
        size_t remain = pkt_len;
        uint8_t *p = buf.data();
        while (remain > 0) {
            ssize_t r = ::read(m_rx_fd, p, remain);
            if (r <= 0) { m_running = false; return; }
            p += r;
            remain -= r;
        }

        /* Deliver to registered callback */
        if (m_rx_cb) {
            m_rx_cb(buf.data(), pkt_len);
        }

        /* Notify SystemC that RX data is available */
        m_rx_event.notify(sc_core::SC_ZERO_TIME);
    }
}

void NetIf::transmit(const uint8_t *data, uint32_t length)
{
    std::lock_guard<std::mutex> lk(m_tx_mtx);
    if (m_tx_fd < 0) return;

    uint32_t net_len = length;
    ::write(m_tx_fd, &net_len, sizeof(net_len));
    ::write(m_tx_fd, data, length);
}
