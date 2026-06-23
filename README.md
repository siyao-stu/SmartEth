# SmartEth — RISC-V 智能网卡

RISC-V 架构的智能网卡（Smart NIC）固件开发与仿真验证项目。

## 项目目标

- 开发 RISC-V 智能网卡的 RTOS 固件
- 在硬件流片前，通过仿真环境验证固件正确性

## 仿真策略（分阶段）

| 阶段 | 工具 | 目标 | 状态 |
|------|------|------|------|
| 1 — QEMU 快速启动 | QEMU riscv64 system mode | 跑起 RTOS 固件、调试基础 BSP | ✅ 完成 |
| 2 — 自定义设备模型 | QEMU + QOM PCIe device | 验证 PCIe 寄存器、中断、DMA | ✅ 完成 |
| 3 — SystemC 精确建模 | QEMU + SystemC co-sim | 精确硬件流水线验证 | ✅ 完成 |
| 4 — 主机联调 | QEMU x86 + SystemC NIC | 端到端主机驱动 + 固件验证 | ⏳ 进行中 |

## 目录结构

```
firmware/               # 固件源码
├── bsp/                # 板级支持包 (UART, CLINT, PLIC)
├── lds/                # 链接脚本
├── baremetal/          # 裸机示例 (hello)
├── rtos/               # FreeRTOS 固件 (含 PCI 测试)
│   ├── main.c          # 主程序 (heartbeat, echo, pci_test 任务)
│   ├── pci_test.c/h    # PCIe 设备扫描与寄存器测试 (含 Phase 4 描述符环定义)
│   ├── startup.S       # 启动代码
│   └── FreeRTOSConfig.h
├── qemu-dev/           # QEMU 自定义 PCIe 设备模型
│   ├── smarteth_pci.c          # Phase 2: 纯 QEMU 设备
│   ├── smarteth_sc_bridge.c    # Phase 3: QEMU-SystemC 桥接设备
│   ├── sc_protocol.h           # QEMU-SystemC 通信协议 (C 版, 含 Phase 4 描述符环)
│   └── build.sh               # 编译集成脚本 (支持 x86_64 QEMU 构建)
└── host-driver/        # Phase 4: Linux 主机 PCI 驱动
    ├── driver/
    │   └── smarteth_main.c     # Linux PCI 网卡驱动 (~560 行)
    ├── initramfs_source/       # initramfs 集成配置 (TODO)
    └── test/                   # 网络侧测试工具 (TODO)
sim/                    # 仿真环境
├── qemu/run.sh         # QEMU 运行脚本 (Phase 1/2)
└── systemc/            # SystemC 精确模型 (Phase 3/4)
    ├── CMakeLists.txt
    ├── run_cosim.sh    # QEMU + SystemC 联合仿真启动脚本
    └── src/
        ├── protocol.h          # 通信协议 (C++ 版, 含 Phase 4 描述符环)
        ├── pcie_bridge.cpp/h   # PCIe Socket 桥接
        ├── nic.cpp/h           # NIC 顶层模块 (含 Phase 4 TX/RX 描述符环处理)
        ├── reg_block.cpp/h     # 寄存器文件
        ├── dma_engine.cpp/h    # DMA 引擎
        ├── pkt_proc.cpp/h      # 数据包处理流水线
        ├── net_if.cpp/h        # Phase 4: 网络侧 Unix Socket I/O
        └── main.cpp            # SystemC 入口 (sc_main, 含 NetIf CLI 参数)
tools/                  # 辅助脚本
├── debug.gdb           # GDB 调试命令
└── env-check.sh        # 环境检查
docs/
tests/
```

---

## 环境准备

### 安装工具链

```bash
# RISC-V 交叉编译器
sudo apt install gcc-riscv64-linux-gnu

# 多架构 GDB
sudo apt install gdb-multiarch

# QEMU (用于 Phase 1，Phase 2 需要自编译 QEMU)
sudo apt install qemu-system-misc
```

### 验证

```bash
riscv64-linux-gnu-gcc --version
gdb-multiarch --version
qemu-system-riscv64 --version
```

### SystemC 库 (Phase 3)

Phase 3 联合仿真需要 SystemC 2.3.4 库:

```bash
# 从 Accellera 官网下载
wget https://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.4.tar.gz
tar xzf systemc-2.3.4.tar.gz && cd systemc-2.3.4
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$PWD/install
make -j$(nproc) && make install

# 设置环境变量 (可加入 ~/.bashrc)
export SYSTEMC_HOME=$PWD/install
```

或设置 `SYSTEMC_HOME` 环境变量指向已安装的 SystemC 路径。编译 SystemC 模型时 CMake 会优先读取此变量。默认路径为 `<project_root>/../tools/systemc/install`。

---

## Phase 1: 裸机 / RTOS 固件

无需自定义 QEMU，直接用系统自带的 `qemu-system-riscv64`。

### 裸机示例

```bash
# 编译
make -C firmware/baremetal

# 运行
./sim/qemu/run.sh firmware/baremetal/hello/hello.elf
```

预期输出 — 心跳计数循环:
```
========================================
  SmartEth RISC-V NIC Firmware
  Phase 1: QEMU RISC-V Baremetal
========================================
BSP Init OK
[HB] count=0x0000000000000000
[HB] count=0x0000000000000001
...
```

### RTOS 固件（无 PCI 设备）

```bash
# 编译
make -C firmware/rtos

# 运行
./sim/qemu/run.sh firmware/rtos/smartnic_rtos.elf
```

预期输出 — 多任务调度:
```
========================================
  SmartEth RISC-V NIC Firmware
  Phase 1: FreeRTOS on QEMU RISC-V
========================================
BSP Init OK
[SYS] Starting FreeRTOS scheduler...
[ECHO] Enter characters (will echo back):
[HB] count=0x0
---[INFO]---
  mhartid: 0x0
  Tick Hz: 100
  Heap:    48704 bytes free
...
[PCI] Scanning for SmartEth device...
[PCI] SmartEth device NOT found!
[PCI] SmartEth device not present (expected without -device)
```

> 未加 `-device smarteth` 时 PCI 扫描找不到设备，属正常现象。

---

## Phase 2: 自定义 PCIe 设备

需要从源码编译 QEMU，加入 SmartEth 设备模型。

### 编译支持 SmartEth 的 QEMU

```bash
# 进入设备模型目录
cd firmware/qemu-dev

# 首次: 配置 meson 编译系统
./build.sh reconfigure

# 编译 QEMU (riscv64-softmmu)
./build.sh qemu
```

编译产物: `<project_root>/../qemu/build/qemu-system-riscv64`

### 编译 RTOS 固件（含 PCI 测试）

```bash
make -C firmware/rtos clean && make -C firmware/rtos
```

### 运行 PCI 测试

```bash
# 方法 1: 使用 build 脚本
cd firmware/qemu-dev
./build.sh test

# 方法 2: 手动运行
qemu-system-riscv64 -M virt -m 256M -nographic -bios none \
  -device smarteth \
  -kernel firmware/rtos/smartnic_rtos.elf

# 方法 3: 使用顶层 Makefile
make run-rtos
```

### 预期测试结果

```
====== PCIe Device Tests ======
[TEST] DEV_ID = 0x52414d53  PASS
[TEST] STATUS = 0x1  PASS (device ready)
[TEST] SCRATCH[0] = 0x0  PASS
[TEST] SCRATCH[1] = 0xffffffff  PASS
[TEST] SCRATCH[2] = 0xaaaaaaaa  PASS
[TEST] SCRATCH[3] = 0x12345678  PASS
[TEST] SCRATCH[4] = 0xdeadbeef  PASS
[TEST] CTRL_RESET: SCRATCH0 after reset = 0x0  PASS
[TEST] MAC = 52:54:0:12:34:56  PASS
[TEST] DMA started (reading 256 bytes from guest memory)...
[TEST] DMA completed  PASS
[TEST] Triggering device interrupt (REG_IRQ_TEST)...
[TEST] IRQ_STS after trigger = 0x2
[TEST] Interrupt status bit set  PASS (device side)
====== Tests PASSED ======
```

### 测试项说明

| 测试 | 验证内容 |
|------|---------|
| DEV_ID | 设备标识寄存器 (0x52414d53 = "SMAR") |
| STATUS | 设备就绪状态 |
| SCRATCH | 寄存器读写一致性 (5 种 pattern) |
| CTRL_RESET | 软件复位后寄存器清零 |
| MAC | 默认 MAC 地址读回 (52:54:00:12:34:56) |
| DMA | 设备读取 guest 内存 → 轮询完成 |
| Interrupt | 写 IRQ_TEST 触发中断状态位 |

---

## Phase 3: SystemC 精确建模 + QEMU 联合仿真

在 Phase 2 的 QEMU 设备模型基础上，将复杂硬件组件替换为 SystemC/TLM-2.0 精确模型，
通过 Unix Domain Socket 与 QEMU 通信。

### 架构

```
┌─────────────────────┐     Unix Domain Socket     ┌──────────────────────────┐
│  QEMU (riscv64 VM)  │ ◄───────────────────────► │  SystemC NIC Model       │
│  ┌───────────────┐  │      /tmp/sc_bridge.sock   │  ┌────────────────────┐  │
│  │ guest firmware │  │                            │  │ RegBlock           │  │
│  │   (RTOS + PCI  │  │                            │  │ DmaEngine          │  │
│  │     tests)     │  │                            │  │ PktProc            │  │
│  └───────┬───────┘  │                            │  └────────────────────┘  │
│          │          │                            │  ┌────────────────────┐  │
│  ┌───────▼───────┐  │                            │  │ PcieBridge         │  │
│  │ smarteth-sc   │──┼────────────────────────────┼──┤ (socket client)    │  │
│  │ bridge device │  │                            │  └────────────────────┘  │
│  └───────────────┘  │                            └──────────────────────────┘
```

### SystemC 模型编译

```bash
# 前置条件: SystemC 库已安装 (见"环境准备")
export SYSTEMC_HOME=/path/to/systemc/install  # 或使用默认路径

# 编译 SystemC NIC 模型
cd sim/systemc
mkdir -p build && cd build
cmake ..
make -j$(nproc)
```

产物: `build/smartnic_sc`

### 编译 QEMU (含 smarteth-sc 桥接设备)

```bash
cd firmware/qemu-dev
./build.sh smarteth-sc  # 仅编译 smarteth-sc 设备 + QEMU
# 或
./build.sh all          # 编译所有设备 (smarteth + smarteth-sc)
```

### 运行联合仿真

```bash
# 方法 1: 使用启动脚本
cd sim/systemc
./run_cosim.sh

# 方法 2: 指定固件
./run_cosim.sh /path/to/firmware.elf

# 方法 3: 手动启动 (终端 1 — QEMU)
QEMU=/path/to/qemu-system-riscv64 \
./sim/qemu/run.sh firmware/rtos/smartnic_rtos.elf

# 方法 3 (续): 终端 2 — SystemC 模型
cd sim/systemc/build
./smartnic_sc --socket-path=/tmp/sc_bridge.sock
```

### 联合仿真预期测试结果

```
====== PCIe Device Tests ======
[TEST] DEV_ID = 0x52414d53  PASS
[TEST] STATUS = 0x1  PASS (device ready)
[TEST] SCRATCH[0] = 0x0  PASS
[TEST] SCRATCH[1] = 0xffffffff  PASS
[TEST] SCRATCH[2] = 0xaaaaaaaa  PASS
[TEST] SCRATCH[3] = 0x12345678  PASS
[TEST] SCRATCH[4] = 0xdeadbeef  PASS
[TEST] CTRL_RESET: SCRATCH0 after reset = 0x0  PASS
[TEST] MAC = 52:54:0:12:34:56
[TEST] MAC readback  PASS
[TEST] DMA completed  PASS
[TEST] IRQ_STS after trigger = 0x2
[TEST] Interrupt status bit set  PASS (device side)
====== Tests PASSED ======
```

### 通信协议

QEMU-SystemC 之间通过 Unix Domain Socket 传输二进制消息，每条消息格式:

```
[MsgHeader: 8 bytes] [Payload: 变长]
  - type:   uint32_t (PcieMsgType)
  - length: uint32_t (payload 长度)
```

| 消息类型 | 方向 | 载荷 | 说明 |
|---------|------|------|------|
| MMIO_READ (0) | QEMU → SC | addr(8) | 寄存器读请求 |
| MMIO_READ_RESP | SC → QEMU | data(4) + status(4) | 寄存器读响应 |
| MMIO_WRITE (1) | QEMU → SC | addr(8) + data(4) | 寄存器写 (fire-and-forget) |
| DMA_READ (2) | SC → QEMU | addr(8) + len(4) | DMA 读 guest 内存 |
| DMA_WRITE (3) | SC → QEMU | addr(8) + len(4) + data(len) | DMA 写 guest 内存 |
| MSI_IRQ (4) | SC → QEMU | vector(4) | 发送 MSI-X 中断 |
| BRIDGE_RESET (5) | QEMU → SC | (none) | 复位通知 |

### Phase 3 测试项说明

| 测试 | Phase 2 (QEMU 设备) | Phase 3 (SystemC 模型) |
|------|---------------------|------------------------|
| 寄存器读写 | QEMU 内存区域模拟 | SystemC RegBlock 精确时序模型 |
| DMA | QEMU 定时器模拟 (1ms) | SystemC DMA 引擎 + 真实 socket 往返 |
| 中断 | QEMU MSI-X 直接投递 | SystemC 轮询 IRQ 状态 → 通过桥接发送 |
| 时序 | 无精确时序 | sc_time 注释 (10ns 寄存器访问) |

---

## Phase 4: 主机联调 (进行中)

在 Phase 3 SystemC 精确模型的基础上，增加描述符环（Descriptor Ring）DMA 传输、
网络侧数据包 I/O（NetIf），并开发 Linux PCI 主机驱动，实现端到端的数据通路验证。

### 架构

```
┌─────────────────────────────────────┐     Unix Domain Socket     ┌──────────────────────────────────────────┐
│  QEMU (x86_64 VM)                   │ ◄───────────────────────► │  SystemC NIC Model                       │
│  ┌─────────────────────────────┐    │      /tmp/sc_bridge.sock   │  ┌────────────────────────────────────┐  │
│  │  Linux Kernel               │    │                            │  │ RegBlock + Descriptor Rings        │  │
│  │  ┌───────────────────────┐  │    │                            │  │ DmaEngine + PktProc                │  │
│  │  │ smarteth.ko (PCI drv) │  │    │                            │  │ process_tx / process_rx SC_THREADs  │  │
│  │  └──────────┬────────────┘  │    │                            │  └────────────────────────────────────┘  │
│  │             │               │    │                            │  ┌────────────────────────────────────┐  │
│  │  ┌──────────▼────────────┐  │    │                            │  │ NetIf (Unix Socket I/O)            │  │
│  │  │ smarteth-sc bridge    │──┼────┼────────────────────────────┼──┤  - RX listener (packet inject)     │  │
│  │  └───────────────────────┘  │    │                            │  │  - TX sender   (packet capture)    │  │
│  └─────────────────────────────┘    │                            │  └────────────────────────────────────┘  │
└─────────────────────────────────────┘                            └─────────────────────────────────────┬────┘
                                                                                                       │
                                                                                         Unix Socket (net side)
                                                                                                       │
                                                                                              ┌────────▼───────┐
                                                                                              │  test tool     │
                                                                                              │  (RX inject /  │
                                                                                              │   TX capture)  │
                                                                                              └────────────────┘
```

### 新增/修改组件

| 组件 | 文件 | 说明 |
|------|------|------|
| 描述符环寄存器 | `sc_protocol.h`, `protocol.h`, `pci_test.h` | TX/RX ring base、size、doorbell、tail (offset 0x300–0x330) |
| SmartEthDesc | 同上三个头文件 | 16 字节描述符结构体: addr(8) + length(4) + flags(4) |
| TX 处理 | `nic.cpp` `process_tx()` | SC_THREAD: 读取描述符环 → DMA 读包数据 → NetIf 发送 → 写回 DONE |
| RX 处理 | `nic.cpp` `process_rx()` / `on_packet_rx()` | NetIf 回调: MAC 过滤 → DMA 写入 RX buffer → 更新 tail → IRQ |
| NetIf 模块 | `net_if.cpp/h` | Unix Domain Socket 监听线程, 支持 RX 注入 / TX 捕获 |
| CLI 参数 | `main.cpp` | `--net-rx-path=`, `--net-tx-path=` 可选参数 (Phase 3 兼容) |
| Linux 驱动 | `host-driver/driver/smarteth_main.c` | PCI 网卡驱动: MMIO, MSI-X, DMA rings, TX/RX, sysfs 测试接口 |
| x86_64 构建 | `build.sh` | `build_qemu_x86()` 函数, 支持 x86_64-softmmu QEMU 编译 |

### Linux 主机驱动

`firmware/host-driver/driver/smarteth_main.c` — 完整的 Linux PCI 网络设备驱动:

- **PCI**: Vendor=0x1efd, Device=0x0001, DMA mask 32-bit, Bus Master
- **MSI-X**: 1 向量中断处理
- **描述符环**: 64 项 TX/RX 环形队列 (DMA-coherent), 支持 OWN/DONE/ERR 标志
- **测试接口**: sysfs `test` 属性 — `echo regs|dma|tx|intr > /sys/devices/.../test`
- **RX 缓冲**: DMA 映射 + 描述符预填充

### 待办事项 (TODO)

- [ ] **驱动 Makefile** — Kbuild 编译框架 (`Kbuild` / `Makefile`)
- [ ] **驱动编译验证** — 确认 `smarteth.ko` 可编译
- [ ] **NetIf 测试工具** — RX 注入 / TX 捕获命令行工具
- [ ] **x86_64 QEMU 编译与验证** — 确认 `build.sh x86` 成功
- [ ] **端到端集成测试** — QEMU x86_64 + SystemC NIC + 主机驱动 insmod
- [ ] **initramfs 集成** — 配置内核启动时自动加载驱动
- [ ] **FreeRTOS 固件描述符环测试** — 在 RISC-V 侧新增 TX/RX descriptor ring 测试用例

---

## GDB 调试

### Phase 1/2: 调试固件

```bash
# 终端 1: 启动 QEMU，等待 GDB
qemu-system-riscv64 -M virt -m 256M -nographic -bios none \
  -kernel firmware/rtos/smartnic_rtos.elf -s -S

# 终端 2: 连接 GDB
gdb-multiarch -q \
  -ex "set architecture riscv:rv64" \
  -ex "file firmware/rtos/smartnic_rtos.elf" \
  -ex "target remote :1234" \
  -ex "break main" \
  -ex "continue"
```

### Phase 2: 调试 PCIe 设备 (含 SmartEth)

```bash
# 终端 1: 使用自编译 QEMU，含 SmartEth 设备
qemu-system-riscv64 -M virt -m 256M -nographic -bios none \
  -device smarteth \
  -kernel firmware/rtos/smartnic_rtos.elf -s -S

# 终端 2: GDB 连接
gdb-multiarch -q \
  -ex "set architecture riscv:rv64" \
  -ex "file firmware/rtos/smartnic_rtos.elf" \
  -ex "target remote :1234" \
  -ex "break smarteth_run_tests" \
  -ex "continue"
```

### Phase 3: 调试联合仿真 (QEMU + SystemC)

```bash
# 终端 1: QEMU (smarteth-sc 桥接设备)
QEMU=/path/to/qemu-system-riscv64 \
  ./sim/qemu/run.sh firmware/rtos/smartnic_rtos.elf

# 终端 2: GDB 连接固件
gdb-multiarch -q \
  -ex "set architecture riscv:rv64" \
  -ex "file firmware/rtos/smartnic_rtos.elf" \
  -ex "target remote :1234" \
  -ex "break smarteth_run_tests" \
  -ex "continue"

# 终端 3: SystemC 模型 (等 QEMU 启动后再运行)
cd sim/systemc/build
./smartnic_sc --socket-path=/tmp/sc_bridge.sock
```

---

## Makefile 命令一览

| 命令 | 用途 |
|------|------|
| `make` / `make all` | 编译裸机固件 |
| `make rtos` | 编译 RTOS 固件 (含 PCI 测试) |
| `make run` | QEMU 运行裸机固件 |
| `make run-rtos` | QEMU + smarteth 设备 + RTOS 固件 |
| `make debug` | QEMU GDB 调试模式 (裸机) |
| `make clean` | 清理固件编译产物 |
| `cd sim/systemc && mkdir -p build && cd build && cmake .. && make` | 编译 SystemC NIC 模型 (Phase 3/4) |
| `cd firmware/qemu-dev && ./build.sh x86` | 编译 x86_64 QEMU + smarteth-sc (Phase 4) |
| `cd firmware/qemu-dev && ./build.sh smarteth-sc` | 编译 riscv64 QEMU + smarteth-sc (Phase 3) |

---

## 编译选项说明

| 选项 | 作用 |
|------|------|
| `-march=rv64imafdc` | RISC-V 64 位，含压缩指令扩展 |
| `-mabi=lp64d` | LP64 ABI，双精度浮点寄存器传参 |
| `-mno-relax` | 禁止链接器松弛 |
| `-fno-pic` | 禁止位置无关代码 |
| `-mcmodel=medany` | 中地址模型，PC 相对寻址 |
| `-no-pie` | 生成绝对地址可执行文件 |
| `-nostdlib -nostartfiles` | 裸机环境，无标准启动文件 |

## 常见问题

**Q: QEMU 编译报错**
A: 确认 QEMU 源码在 `<project_root>/../qemu`。首次需要 `./build.sh reconfigure`。

**Q: QEMU 启动报 ROM 区域重叠**
A: 确认加了 `-bios none` 参数，避免 OpenSBI 与固件加载地址冲突。

**Q: BAR0 读取为 0**
A: 裸机环境无 BIOS，PCI BAR 不会被自动分配。固件通过 ECAM 写入 `0x40000000`（PCI MMIO 窗口基址）并需设置 COMMAND 寄存器的 Memory Space 位。

**Q: DMA 测试超时**
A: 确认 QEMU 设备模型的 DMA 定时器延迟足够短（Phase 2 使用 1ms）。QEMU_CLOCK_VIRTUAL 在默认模式下需要真实时间推进。

**Q: 联合仿真时 SystemC 提示连接失败**
A: 确认已先启动 QEMU 再启动 SystemC 模型。QEMU 是 socket 服务端(SystemC 是客户端)，需等待 QEMU 就绪。

**Q: 联合仿真 SCRATCH 测试不稳定 (值错乱)**
A: 确认 QEMU 已重新编译，包含 `smarteth_sc_bridge.c` 的 MMIO 响应序列化修复。
QEMU 的 I/O 线程在处理 `MMIO_WRITE` 响应时不得提前唤醒 `MMIO_READ` 等待者。

**Q: SystemC 编译报 `systemc.h: No such file or directory`**
A: 设置 `SYSTEMC_HOME` 环境变量指向 SystemC 安装路径，或通过 cmake `-DSYSTEMC_HOME=...` 指定。

**Q: Quick start for English speakers**
A: Run `make -C firmware/baremetal && ./sim/qemu/run.sh firmware/baremetal/hello/hello.elf` for a quick demo.
