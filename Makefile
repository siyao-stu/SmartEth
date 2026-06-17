# top-level Makefile — SmartEth 项目构建入口

.PHONY: all clean firmware rtos hello debug run env-check

all: firmware

# 编译固件
firmware:
	$(MAKE) -C firmware/baremetal

rtos:
	$(MAKE) -C firmware/rtos

hello:
	$(MAKE) -C firmware/baremetal hello

# 在 QEMU 中运行（裸机）
run:
	./sim/qemu/run.sh firmware/baremetal/hello/hello.elf

# 在 QEMU 中运行 RTOS 固件 + SmartEth 设备
run-rtos: rtos
	DEVICE=smarteth ./sim/qemu/run.sh firmware/rtos/smartnic_rtos.elf

# GDB 调试模式（裸机）
debug:
	DEBUG=1 ./sim/qemu/run.sh firmware/baremetal/hello/hello.elf

# 检查环境
env-check:
	@bash tools/env-check.sh

# 清理
clean:
	$(MAKE) -C firmware/baremetal clean
	$(MAKE) -C firmware/rtos clean

# 显示帮助
help:
	@echo "SmartEth 项目 — 构建命令"
	@echo "  make all        编译所有固件"
	@echo "  make rtos       编译 RTOS 固件 (含 PCI 测试)"
	@echo "  make run        在 QEMU 中运行 (裸机)"
	@echo "  make run-rtos   在 QEMU 中运行 RTOS 固件 + SmartEth 设备"
	@echo "  make debug      启动 QEMU 并等待 GDB 连接 (端口 :1234)"
	@echo "  make clean      清理编译产物"
	@echo ""
	@echo "GDB 调试:"
	@echo "  make debug          → 另一个终端执行:"
	@echo "  riscv64-linux-gnu-gdb firmware/baremetal/hello/hello.elf -x tools/debug.gdb"
