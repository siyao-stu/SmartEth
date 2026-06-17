# SmartEth RISC-V NIC Firmware

智能网卡 RISC-V 固件，支持裸机示例和 FreeRTOS RTOS 两种运行模式。

## 环境要求

### 工具链

```bash
# RISC-V 交叉编译器 (Linux 靶标，兼容器码)
sudo apt install gcc-riscv64-linux-gnu

# 多架构 GDB (用于调试)
sudo apt install gdb-multiarch

# QEMU (RISC-V 系统模拟)
sudo apt install qemu-system-misc
```

> `riscv64-linux-gnu-gcc` 已验证可用。若使用 `riscv64-unknown-elf-gcc`（裸机工具链）方式类似。

### 验证工具

```bash
riscv64-linux-gnu-gcc --version
qemu-system-riscv64 --version
gdb-multiarch --version
```

---

## 项目结构

```
firmware/
├── bsp/              # 板级支持包 (UART, CLINT, PLIC)
│   ├── bsp.h         # 内存映射、CSR 操作宏
│   ├── uart.c/h      # NS16550A UART 驱动
│   ├── clint.c/h     # CLINT 定时器驱动
│   └── plic.c/h      # PLIC 中断控制器驱动
├── lds/              # 链接脚本
│   └── smartnic.ld   # RTOS 链接脚本 (256MB RAM)
├── baremetal/        # 裸机示例
│   ├── Makefile
│   └── hello/
│       ├── start.S   # 启动代码
│       ├── hello.c   # 主程序
│       └── link.ld   # 链接脚本
├── rtos/             # FreeRTOS 固件
│   ├── Makefile
│   ├── startup.S     # 启动代码
│   ├── main.c        # 主程序 (含 vTaskPciTest)
│   ├── pci_test.c/h  # PCIe 设备扫描与测试
│   ├── libc_supp.c   # libc 补充函数
│   ├── FreeRTOSConfig.h
│   └── FreeRTOS-Kernel/  # FreeRTOS 内核源码
├── qemu-dev/         # QEMU 自定义 PCIe 设备模型
│   ├── smarteth_pci.c # SmartEth PCIe 设备 (QOM)
│   └── build.sh      # 编译集成脚本
└── README.md         # 本文件
```

---

## 裸机示例 (Baremetal Hello)

裸机程序：初始化 UART，循环输出心跳计数。

### 编译

```bash
cd firmware/baremetal
make
```

产物: `hello/hello.elf` (含调试符号), `hello/hello.asm` (反汇编)

### 运行

```bash
cd firmware/baremetal
qemu-system-riscv64 -M virt -m 256M -nographic -bios none -kernel hello/hello.elf
```

按 `Ctrl-A X` 退出 QEMU。

预期输出:

```
========================================
  SmartEth RISC-V NIC Firmware
  Phase 1: QEMU RISC-V Baremetal
========================================
BSP Init OK
Platform: QEMU riscv64 virt

--- CPU Info ---
  mhartid: 0x0000000000000000
  marchid: 0x0000000000000000
  mimpid:  0x0000000000000000
---

[HB] count=0x0000000000000000
[HB] count=0x0000000000000001
[HB] count=0x0000000000000002
...
```

### 清除

```bash
cd firmware/baremetal
make clean
```

---

## RTOS 固件 (FreeRTOS)

RTOS 固件：初始化 BSP → 创建 3 个 FreeRTOS 任务 → 启动调度器。

| 任务 | 功能 | 周期 |
|------|------|------|
| `heartbeat` | 输出心跳计数 | 2 秒 |
| `info` | 输出系统信息 (CSR, 堆, Tick) | 10 秒 |
| `echo` | UART 字符回显 | 轮询 (10ms) |

### 编译

```bash
cd firmware/rtos
make
```

产物: `smartnic_rtos.elf`, `smartnic_rtos.asm` (反汇编)

### 运行

```bash
cd firmware/rtos
qemu-system-riscv64 -M virt -m 256M -nographic -bios none -kernel smartnic_rtos.elf
```

按 `Ctrl-A X` 退出 QEMU。

预期输出:

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
  Heap:    52976 bytes free
------------
[HB] count=0x1
[HB] count=0x2
...
```

### 清除

```bash
cd firmware/rtos
make clean
```

---

## Phase 2: PCIe 设备模型与验证

QEMU 自定义 PCIe 设备模型 (`qemu-dev/smarteth_pci.c`)，实现智能网卡基本功能：

| 功能 | 实现 |
|------|------|
| PCIe 配置空间 | Vendor=0x1efd, Device=0x0001, Class=Ethernet |
| BAR0 (MMIO) | 4KB 寄存器空间 (CTRL, STATUS, IRQ, DMA, SCRATCH) |
| BAR1 (MSI-X) | 专用 BAR，2 个向量 (DMA完成, 测试中断) |
| DMA 引擎 | 基于定时器的传输模拟 (4KB 内部缓冲) |
| 中断 | 支持 INTx, MSI, MSI-X |

### 编译 QEMU (含 SmartEth 设备)

前置条件: QEMU 源码在 `/home/wangsiyao/code/qemu`

```bash
cd firmware/qemu-dev
./build.sh qemu       # 编译设备 + QEMU
```

首次需加 `reconfigure`:
```bash
./build.sh reconfigure
```

### 编译 RTOS 固件 (含 PCI 测试)

```bash
cd firmware/rtos
make clean && make
```

### 运行测试

```bash
cd firmware/qemu-dev
./build.sh test
```

或手动运行:

```bash
qemu-system-riscv64 -M virt -m 256M -nographic -bios none \
  -device smarteth \
  -kernel firmware/rtos/smartnic_rtos.elf
```

### 预期测试结果

```
====== PCIe Device Tests ======
[TEST] DEV_ID = 0x52414d53  PASS
[TEST] STATUS = 0x1  PASS (device ready)
[TEST] SCRATCH[0] = 0x0  PASS
[TEST] SCRATCH[3] = 0x12345678  PASS
[TEST] CTRL_RESET: SCRATCH0 after reset = 0x0  PASS
[TEST] MAC = 52:54:0:12:34:56  PASS
[TEST] DMA started (reading 256 bytes from guest memory)...
[TEST] DMA completed  PASS
[TEST] Interrupt status bit set  PASS (device side)
====== Tests PASSED ======
```

### 测试用例说明

| 测试 | 验证内容 |
|------|---------|
| DEV_ID | 读取设备标识寄存器 (0x52414d53 = "SMAR") |
| STATUS | 设备就绪状态 (bit 0) |
| SCRATCH | 5 种 pattern 的寄存读写回一致性 |
| CTRL_RESET | 写 CTRL_RESET 后 SCRATCH 是否清零 |
| MAC | 默认 MAC 地址读回 (52:54:00:12:34:56) |
| DMA | 配置源地址 → 启动传输 → 轮询完成 (1ms 模拟) |
| Interrupt | 写 IRQ_TEST 寄存器 → 中断状态位置起 |

**注意**: 裸机环境无 BIOS/OpenSBI，PCI BAR 需要固件手动配置。
MMIO 窗口在 RISC-V virt 机器中位于 `0x40000000` (32位)。

---

## GDB 调试

两种调试方式：

### 方法 1: QEMU 等待 GDB 连接

终端 1 — 启动 QEMU (停在第一条指令):

```bash
cd firmware/rtos
qemu-system-riscv64 -M virt -m 256M -nographic -bios none -kernel smartnic_rtos.elf -s -S
```

参数说明:
- `-s` :  shorthand for `-gdb tcp::1234`
- `-S` :  启动时暂停 CPU，等待 GDB 连接

终端 2 — 连接 GDB:

```bash
gdb-multiarch -q \
  -ex "set architecture riscv:rv64" \
  -ex "file firmware/rtos/smartnic_rtos.elf" \
  -ex "target remote :1234" \
  -ex "break main" \
  -ex "continue"
```

### 方法 2: 直接运行 + 动态连接

```bash
# 终端 1: 直接运行
qemu-system-riscv64 -M virt -m 256M -nographic -bios none -kernel smartnic_rtos.elf -gdb tcp::1234

# 终端 2: 随时连接 GDB
gdb-multiarch
(gdb) set architecture riscv:rv64
(gdb) file firmware/rtos/smartnic_rtos.elf
(gdb) target remote :1234
(gdb) break vTaskHeartbeat
(gdb) continue
```

裸机程序同理:

```bash
qemu-system-riscv64 -M virt -m 256M -nographic -bios none -kernel hello/hello.elf -s -S
gdb-multiarch -ex "set architecture riscv:rv64" \
  -ex "file baremetal/hello/hello.elf" \
  -ex "target remote :1234" \
  -ex "break main" \
  -ex "continue"
```

---

## 编译选项说明

| 选项 | 作用 |
|------|------|
| `-march=rv64imafdc` | RISC-V 64位，整数/乘除/原子/单精度/双精度/压缩指令 |
| `-mabi=lp64d` | LP64 ABI，双精度浮点寄存器传参 |
| `-mno-relax` | 禁止链接器松弛，避免 GOT 访问问题 |
| `-fno-pic` | 禁止位置无关代码，全局变量直接寻址 |
| `-mcmodel=medany` | 中地址模型，PC 相对寻址 (±2GiB) |
| `-no-pie` | 生成绝对地址可执行文件 (非 PIE) |
| `-nostdlib -nostartfiles -ffreestanding` | 裸机环境，无 libc/启动文件 |

### 关于 `riscv64-linux-gnu` vs `riscv64-unknown-elf`

两种工具链都可以。`riscv64-linux-gnu` 默认启用 PIC/PIE，需要通过 `-fno-pic -no-pie` 关闭。
`riscv64-unknown-elf` 默认就是裸机模式，但需要自行编译或从 Bootlin 下载预编译版。

---

## 常见问题

**Q: 编译报错 `relocation R_RISCV_HI20 can not be used when making a shared object`**
A: 链接命令中缺少 `-no-pie` 或 CFLAGS 中没有 `-fno-pic`。

**Q: QEMU 无任何输出**
A: 确认已添加 `-nographic` 参数。检查 ELF 入口点是否正确 (`readelf -h smartnic_rtos.elf`)。

**Q: 固件卡死或在 `xTaskCreate` 处无响应**
A: 旧版本存在 GOT 访问问题。确认已使用 `-fno-pic -mcmodel=medany -no-pie` 重新编译。
