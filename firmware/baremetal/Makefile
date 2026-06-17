# firmware/baremetal/Makefile
# 编译 RISC-V 裸机示例程序

# 可用选项:
#   make CROSS=riscv64-unknown-elf-   (bare-metal toolchain, newlib)
#   make CROSS=riscv64-linux-gnu-     (Linux cross toolchain, 也可以用)
CROSS ?= riscv64-linux-gnu
CC    = $(CROSS)-gcc
OBJCOPY = $(CROSS)-objcopy
OBJDUMP = $(CROSS)-objdump
SIZE  = $(CROSS)-size

# -mno-relax: 禁止 RISC-V 链接器松弛，避免 GOT 访问问题
CFLAGS  = -march=rv64imafdc -mabi=lp64d -mno-relax -nostdlib -nostartfiles -ffreestanding -O2 -g
LDFLAGS = -mno-relax -nostdlib -nostartfiles -ffreestanding -Wl,-gc-sections -g

.PHONY: all clean hello

all: hello

hello:
	$(CC) $(CFLAGS) $(LDFLAGS) \
		-T hello/link.ld \
		hello/start.S hello/hello.c \
		-o hello/hello.elf
	$(OBJDUMP) -S hello/hello.elf > hello/hello.asm
	$(SIZE)   hello/hello.elf

clean:
	rm -f hello/hello.elf hello/hello.asm
