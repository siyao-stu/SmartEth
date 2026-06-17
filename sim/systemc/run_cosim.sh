#!/bin/bash
# sim/systemc/run_cosim.sh — QEMU + SystemC 联合仿真启动脚本
#
# 启动 QEMU RISC-V (smarteth-sc 设备) 和 SystemC NIC 模型，
# 通过 Unix Domain Socket 连接。
#
# 用法:
#   ./sim/systemc/run_cosim.sh                                    # 运行 RTOS 固件
#   ./sim/systemc/run_cosim.sh firmware/baremetal/hello/hello.elf # 运行指定固件
#   DEBUG=1 ./sim/systemc/run_cosim.sh ...                        # GDB 调试
#
# 前置条件:
#   - QEMU 已编译 smarteth-sc 设备 (firmware/qemu-dev/build.sh all)
#   - SystemC 模型已编译 (sim/systemc/build/smartnic_sc)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(realpath "$SCRIPT_DIR/../..")"
QEMU_BUILD_DIR="/home/wangsiyao/code/qemu/build"
SYSTEMC_BIN="$SCRIPT_DIR/build/smartnic_sc"
DEFAULT_ELF="$PROJECT_DIR/firmware/rtos/smartnic_rtos.elf"
SOCKET_PATH="${SOCKET_PATH:-/tmp/sc_bridge.sock}"

# ------- 前置检查 -------
if [ ! -f "$SYSTEMC_BIN" ]; then
    echo "[ERROR] SystemC 模型未编译: $SYSTEMC_BIN"
    echo "  请先执行: cd $SCRIPT_DIR && mkdir -p build && cd build && cmake .. && make -j\$(nproc)"
    exit 1
fi

QEMU_BIN="${QEMU:-$QEMU_BUILD_DIR/qemu-system-riscv64}"
if [ ! -f "$QEMU_BIN" ]; then
    echo "[ERROR] QEMU 未找到: $QEMU_BIN"
    echo "  请先执行: cd $PROJECT_DIR/firmware/qemu-dev && ./build.sh all"
    exit 1
fi

ELF="${1:-$DEFAULT_ELF}"
if [ ! -f "$ELF" ]; then
    echo "[ERROR] 固件未找到: $ELF"
    echo "  请先编译固件: make -C $PROJECT_DIR/firmware/rtos"
    exit 1
fi

# ------- 清理旧 socket 文件 ----
rm -f "$SOCKET_PATH"

# ------- 选项 -------
TIMEOUT_SEC="${TIMEOUT:-30}"   # 默认超时 30 秒

# ------- 启动 -------
echo "=========================================="
echo " SmartEth Co-Simulation 启动"
echo "=========================================="
echo "  QEMU:   $QEMU_BIN"
echo "  SystemC: $SYSTEMC_BIN"
echo "  固件:   $ELF"
echo "  Socket: $SOCKET_PATH"
echo "  超时:   ${TIMEOUT_SEC}s"
echo "=========================================="

# 清理退出时的临时进程
cleanup() {
    echo ""
    echo "[COSIM] 正在停止..."
    # Kill background processes
    [ -n "$QEMU_PID" ] && kill "$QEMU_PID" 2>/dev/null || true
    [ -n "$SC_PID" ] && kill "$SC_PID" 2>/dev/null || true
    wait 2>/dev/null || true
    rm -f "$SOCKET_PATH"
    echo "[COSIM] 已停止"
}
trap cleanup EXIT INT TERM

# 步骤 1: 先启动 QEMU (创建 socket 服务器，等待 SystemC 连接)
echo "[COSIM] 启动 QEMU (socket server)..."
QEMU_ARGS=(
    -M virt
    -m 256M
    -nographic
    -bios none
    -kernel "$ELF"
    -serial mon:stdio
    -D /tmp/qemu-cosim.log
    -device "smarteth-sc,socket-path=$SOCKET_PATH"
)

if [ -n "${DEBUG:-}" ]; then
    QEMU_ARGS+=(-s -S)
    echo "[COSIM] GDB 调试模式: riscv64-unknown-elf-gdb $ELF -ex 'target remote :1234'"
fi

# QEMU 后台启动 (stdout 直接输出到终端)
"$QEMU_BIN" "${QEMU_ARGS[@]}" &
QEMU_PID=$!
echo "[COSIM] QEMU PID: $QEMU_PID"

# 等待 socket 文件创建
for i in $(seq 1 20); do
    if [ -S "$SOCKET_PATH" ]; then
        echo "[COSIM] Socket 就绪"
        break
    fi
    sleep 0.2
done

if [ ! -S "$SOCKET_PATH" ]; then
    echo "[ERROR] Socket 文件未创建"
    exit 1
fi

# 步骤 2: 启动 SystemC 模型 (作为 socket 客户端连接 QEMU)
echo "[COSIM] 启动 SystemC NIC 模型..."
"$SYSTEMC_BIN" --socket-path="$SOCKET_PATH" &
SC_PID=$!
echo "[COSIM] SystemC PID: $SC_PID"

# 步骤 3: 等待仿真结束
echo "[COSIM] 仿真运行中 (超时 ${TIMEOUT_SEC}s)..."
wait "$QEMU_PID"
QEMU_EXIT=$?

if [ $QEMU_EXIT -eq 0 ]; then
    echo "[COSIM] QEMU 正常退出 (exit code: $QEMU_EXIT)"
else
    echo "[COSIM] QEMU 退出 (exit code: $QEMU_EXIT)"
fi

# 等待 SystemC 退出
wait "$SC_PID" 2>/dev/null || true

exit $QEMU_EXIT
