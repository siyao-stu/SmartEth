# firmware/rtos/Makefile — SmartEth RTOS 固件构建

CROSS ?= riscv64-linux-gnu
CC    = $(CROSS)-gcc
OBJDUMP = $(CROSS)-objdump
SIZE  = $(CROSS)-size

CFLAGS  = -march=rv64imafdc -mabi=lp64d -mno-relax -fno-pic -mcmodel=medany -nostdlib -nostartfiles -ffreestanding -O2 -g
CFLAGS += -Wall -Werror=implicit-function-declaration

# FreeRTOS 内核路径
FREERTOS_DIR = FreeRTOS-Kernel

# 包含路径 (给 C 编译器)
INCLUDES  = -I.                              # FreeRTOSConfig.h
INCLUDES += -I$(FREERTOS_DIR)/include        # FreeRTOS public API
INCLUDES += -I$(FREERTOS_DIR)/portable/GCC/RISC-V  # portmacro.h
INCLUDES += -I..                              # BSP headers (bsp/)

# 汇编器额外包含路径 (找 freertos_risc_v_chip_specific_extensions.h)
ASFLAGS  = -I.
ASFLAGS += -I$(FREERTOS_DIR)/portable/GCC/RISC-V

# FreeRTOS 内核源文件
FREERTOS_SRCS = \
    $(FREERTOS_DIR)/tasks.c \
    $(FREERTOS_DIR)/list.c \
    $(FREERTOS_DIR)/queue.c \
    $(FREERTOS_DIR)/timers.c \
    $(FREERTOS_DIR)/event_groups.c \
    $(FREERTOS_DIR)/stream_buffer.c \
    $(FREERTOS_DIR)/portable/MemMang/heap_4.c

# FreeRTOS RISC-V port (汇编 + C)
FREERTOS_PORT_SRCS = \
    $(FREERTOS_DIR)/portable/GCC/RISC-V/portASM.S \
    $(FREERTOS_DIR)/portable/GCC/RISC-V/port.c

# BSP drivers
BSP_SRCS = \
    ../bsp/uart.c \
    ../bsp/clint.c \
    ../bsp/plic.c

# 应用 + libc 补充
APP_SRCS = \
    startup.S \
    main.c \
    libc_supp.c \
    pci_test.c

ALL_SRCS = $(FREERTOS_SRCS) $(FREERTOS_PORT_SRCS) $(BSP_SRCS) $(APP_SRCS)

OUT = smartnic_rtos.elf

.PHONY: all clean

all: $(OUT)

$(OUT): $(ALL_SRCS)
	$(CC) $(CFLAGS) $(INCLUDES) -no-pie \
		-Wa,-I,. -Wa,-I,$(FREERTOS_DIR)/portable/GCC/RISC-V \
		-T ../lds/smartnic.ld \
		$(ALL_SRCS) \
		-o $(OUT) \
		-Wl,-lgcc
	$(OBJDUMP) -S $(OUT) > $(OUT:.elf=.asm)
	$(SIZE) $(OUT)

clean:
	rm -f $(OUT) $(OUT:.elf=.asm)
