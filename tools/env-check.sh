#!/bin/bash
# tools/env-check.sh — SmartEth 开发环境检查
# 用法: bash tools/env-check.sh 或 make env-check

PASS=0
WARN=0
FAIL=0

check_cmd() {
    if command -v "$1" &>/dev/null; then
        echo "  [✓] $1 → $(which $1)"
        PASS=$((PASS + 1))
    else
        echo "  [✗] $1 — 未安装 (需要手动安装)"
        FAIL=$((FAIL + 1))
    fi
}

check_opt() {
    if command -v "$1" &>/dev/null; then
        echo "  [~] $1 → $(which $1) (可选)"
        WARN=$((WARN + 1))
    else
        echo "  [ ] $1 — 未安装 (后续阶段需要)"
        WARN=$((WARN + 1))
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo "  [✓] $1"
        PASS=$((PASS + 1))
    else
        echo "  [✗] $1 — 文件缺失"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "=============================="
echo " SmartEth 开发环境检查"
echo "=============================="
echo ""

echo "--- 必需工具 (Phase 1) ---"
check_cmd riscv64-linux-gnu-gcc
check_cmd riscv64-linux-gnu-ld
check_cmd riscv64-linux-gnu-objdump
check_cmd riscv64-linux-gnu-size
check_cmd qemu-system-riscv64
check_cmd make
check_cmd cmake

echo ""
echo "--- 推荐工具 (调试) ---"
check_opt riscv64-linux-gnu-gdb
check_opt riscv64-linux-gnu-objcopy

echo ""
echo "--- 后续阶段需要 (Phase 2-4) ---"
check_opt qemu-system-x86_64
check_opt g++         # SystemC 需要 C++ 编译器
check_opt python3

echo ""
echo "--- 项目文件完整性 ---"
check_file firmware/baremetal/hello/start.S
check_file firmware/baremetal/hello/hello.c
check_file firmware/baremetal/hello/link.ld
check_file firmware/baremetal/Makefile
check_file sim/qemu/run.sh
check_file tools/debug.gdb
check_file Makefile

echo ""
echo "=============================="
echo " 结果: $PASS 通过  $WARN 警告(可选)  $FAIL 失败(必需)"
echo "=============================="

if [ $FAIL -gt 0 ]; then
    echo "请安装缺失的必需工具后再继续。"
    echo "  sudo apt-get install gcc-riscv64-linux-gnu qemu-system-misc"
    echo ""
    exit 1
else
    echo "环境就绪！运行: make run"
    echo ""
fi
