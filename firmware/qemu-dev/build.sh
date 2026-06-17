#!/usr/bin/env bash
# build.sh — 将 SmartEth PCIe 设备编译进 QEMU
#
# 用法:
#   ./build.sh                          # 编译 smarteth 设备 + QEMU
#   ./build.sh smarteth-sc              # 编译 SC bridge 设备 + QEMU
#   ./build.sh all                      # 编译所有设备 + QEMU
#   ./build.sh reconfigure              # 重新配置 meson (首次需要)
#   ./build.sh test                     # 快速测试: 启动固件 + smarteth 设备
#
# 前置条件: QEMU 源码在 $QEMU_SRC 目录 (默认 ../code/qemu)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QEMU_SRC="${QEMU_SRC:-$(realpath "$SCRIPT_DIR/../../../code/qemu" 2>/dev/null || realpath "$SCRIPT_DIR/../../../../qemu" 2>/dev/null || echo "")}"
BUILD_DIR="${BUILD_DIR:-$QEMU_SRC/build}"
FIRMWARE_DIR="$(realpath "$SCRIPT_DIR/..")"

# ------- 颜色 -------
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC} $*" >&2; }

# ------- 设备集成 -------
integrate_device() {
    local dev="$1"
    local src_file config_name config_define

    case "$dev" in
        smarteth)
            src_file="$SCRIPT_DIR/smarteth_pci.c"
            config_name="smarteth_pci"
            config_define="CONFIG_SMARTETH_PCI"
            ;;
        smarteth-sc)
            src_file="$SCRIPT_DIR/smarteth_sc_bridge.c"
            config_name="smarteth_sc_bridge"
            config_define="CONFIG_SMARTETH_SC_BRIDGE"
            cp "$SCRIPT_DIR/sc_protocol.h" "$QEMU_SRC/hw/net/"
            ;;
        *)
            err "Unknown device: $dev"
            exit 1
            ;;
    esac

    info "Integrating $dev into QEMU source..."

    # 1. Copy source to hw/net/
    cp "$src_file" "$QEMU_SRC/hw/net/"

    # 2. Check meson.build
    if ! grep -q "$config_define" "$QEMU_SRC/hw/net/meson.build" 2>/dev/null; then
        sed -i "/CONFIG_E1000E_PCI_EXPRESS/i\\
system_ss.add(when: '$config_define', if_true: files('$config_name.c'))" \
            "$QEMU_SRC/hw/net/meson.build"
        info "  Added to hw/net/meson.build"
    else
        info "  Already in hw/net/meson.build"
    fi

    # 3. Check Kconfig
    if ! grep -q "config ${config_define#CONFIG_}" "$QEMU_SRC/hw/net/Kconfig" 2>/dev/null; then
        cat >> "$QEMU_SRC/hw/net/Kconfig" <<EOF

config ${config_define#CONFIG_}
    bool
    default y if PCI_DEVICES || PCIE_DEVICES
    depends on PCI
EOF
        info "  Added to hw/net/Kconfig"
    else
        info "  Already in hw/net/Kconfig"
    fi

    # 4. Ensure RISC-V config enables the device
    local config_file="$BUILD_DIR/riscv64-softmmu-config-devices.h"
    if [ -f "$config_file" ]; then
        if ! grep -q "$config_define" "$config_file" 2>/dev/null; then
            echo "#define $config_define 1" >> "$config_file"
            info "  Enabled $config_define in RISC-V config"
        else
            info "  Already enabled in RISC-V config"
        fi
    fi
}

# ------- 构建 QEMU -------
build_qemu() {
    local devs="${1:-smarteth}"

    if [ "$devs" = "all" ]; then
        integrate_device smarteth
        integrate_device smarteth-sc
    elif [ "$devs" = "reconfigure" ]; then
        # Just reconfigure, no device integration needed if already done
        info "Reconfiguring meson..."
        cd "$QEMU_SRC"
        ./configure --target-list=riscv64-softmmu --enable-debug
        cd "$BUILD_DIR"
        ninja qemu-system-riscv64 2>&1 | tail -20
        info "QEMU built: $BUILD_DIR/qemu-system-riscv64"
        return 0
    else
        integrate_device "$devs"
    fi

    info "Rebuilding QEMU (riscv64-softmmu)..."
    cd "$BUILD_DIR"
    ninja qemu-system-riscv64 2>&1 | tail -20
    info "QEMU built: $BUILD_DIR/qemu-system-riscv64"
}

# ------- 运行测试 -------
run_test() {
    local qemu="$BUILD_DIR/qemu-system-riscv64"
    if [ ! -f "$qemu" ]; then
        build_qemu smarteth
    fi

    local elf="$FIRMWARE_DIR/rtos/smartnic_rtos.elf"
    if [ ! -f "$elf" ]; then
        info "Building RTOS firmware first..."
        make -C "$FIRMWARE_DIR/rtos" clean
        make -C "$FIRMWARE_DIR/rtos"
    fi

    info "Starting QEMU with SmartEth PCIe device..."
    "$qemu" -M virt -m 256M -nographic \
        -device smarteth \
        -kernel "$elf" \
        "$@"
}

# ------- 主入口 -------
case "${1:-qemu}" in
    qemu)    build_qemu smarteth ;;
    smarteth-sc) build_qemu smarteth-sc ;;
    all)     build_qemu all ;;
    reconfigure) build_qemu reconfigure ;;
    test)    run_test "${@:2}" ;;
    device)  integrate_device "${2:-smarteth}" ;;
    *)
        echo "Usage: $0 {qemu|smarteth-sc|all|reconfigure|test|device}"
        exit 1
        ;;
esac
