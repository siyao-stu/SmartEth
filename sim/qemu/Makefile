# sim/qemu/Makefile — 用于后续编译自定义 QEMU 设备和 QEMU 源码
#
# 如果需要从源码编译 QEMU 以添加自定义设备:
#   make qemu-build
#   make qemu-clean

QEMU_SRC ?= ../qemu
QEMU_BUILD ?= $(QEMU_SRC)/build

.PHONY: qemu-build qemu-clean

qemu-build:
	@if [ ! -d "$(QEMU_SRC)" ]; then \
		echo "请先将 QEMU 源码克隆到 $(QEMU_SRC)"; \
		echo "  git clone https://github.com/qemu/qemu.git $(QEMU_SRC)"; \
		exit 1; \
	fi
	mkdir -p $(QEMU_BUILD)
	cd $(QEMU_BUILD) && \
		../configure --target-list=riscv64-softmmu,x86_64-softmmu \
			--enable-debug
	$(MAKE) -C $(QEMU_BUILD) -j$$(nproc)

qemu-clean:
	rm -rf $(QEMU_BUILD)
