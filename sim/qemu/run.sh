#!/bin/bash
# sim/qemu/run.sh — 在 QEMU RISC-V virt 上运行固件
#
# 用法:
#   ./sim/qemu/run.sh firmware/baremetal/hello/hello.elf    # 直接运行
#   DEBUG=1 ./sim/qemu/run.sh firmware/baremetal/hello/hello.elf  # 等待 GDB 连接

set -e

ELF="$1"
if [ -z "$ELF" ]; then
    echo "用法: $0 <firmware.elf>"
    echo "示例: $0 firmware/baremetal/hello/hello.elf"
    exit 1
fi

if [ ! -f "$ELF" ]; then
    echo "错误: 文件不存在: $ELF"
    exit 1
fi

QEMU=${QEMU:-qemu-system-riscv64}
SOCKET_PATH=${SOCKET_PATH:-/tmp/sc_bridge.sock}

# QEMU 参数
ARGS=(
    -M virt                  # RISC-V virt 平台
    -m 256M                  # 256MB 内存
    -nographic               # 无图形界面, 串口输出到终端
    -bios none               # 不使用 OpenSBI, 直接运行裸机程序
    -kernel "$ELF"           # 加载固件
    -serial mon:stdio        # 串口映射到 stdio
    -D /tmp/qemu.log         # QEMU 日志
)

# 设备选择
DEVICE=${DEVICE:-}
if [ "$DEVICE" = "smarteth" ]; then
    ARGS+=(-device smarteth)
elif [ "$DEVICE" = "smarteth-sc" ]; then
    ARGS+=(-device "smarteth-sc,socket-path=$SOCKET_PATH")
fi

# GDB 调试模式
if [ -n "$DEBUG" ]; then
    ARGS+=(-s -S)
    echo "等待 GDB 连接: riscv64-unknown-elf-gdb $ELF -ex 'target remote :1234'"
fi

echo "启动 QEMU RISC-V..."
echo "  固件: $ELF"
echo "  QEMU: $(which $QEMU)"
echo ""
exec "$QEMU" "${ARGS[@]}"
