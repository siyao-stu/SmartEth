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
| 3 — SystemC 精确建模 | QEMU + SystemC co-sim | 精确硬件流水线验证 | ⏳ 进行中 |
| 4 — 主机联调 | QEMU x86 + SystemC NIC | 端到端主机驱动 + 固件验证 | 📋 规划 |

## 目录结构

```
firmware/           # 固件源码
├── bsp/            # 板级支持包 (UART, CLINT, PLIC)
├── lds/            # 链接脚本
├── baremetal/      # 裸机示例 (hello)
├── rtos/           # FreeRTOS 固件 (含 PCI 测试)
└── qemu-dev/       # QEMU 自定义 PCIe 设备模型
sim/                # 仿真环境
└── qemu/run.sh     # QEMU 运行脚本
tools/              # 辅助脚本
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

## GDB 调试

### Phase 1: 调试 RTOS 固件

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

### Phase 2: 调试 PCIe 设备

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

**Q: Quick start for English speakers**
A: Run `make -C firmware/baremetal && ./sim/qemu/run.sh firmware/baremetal/hello/hello.elf` for a quick demo.
