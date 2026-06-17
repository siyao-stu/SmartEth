/* SmartEth 固件链接脚本 (QEMU RISC-V virt + FreeRTOS) */
/* RAM: 0x80000000, 256MB */

ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
    . = ORIGIN(RAM);

    /* 启动代码和异常向量表放在最前面 */
    .text.init : {
        *(.text.init)
    } > RAM

    /* FreeRTOS 陷阱处理函数 */
    .text.freertos_risc_v_trap_handler : {
        *(.text.freertos_risc_v_trap_handler)
    } > RAM

    .text.freertos_risc_v_exception_handler : {
        *(.text.freertos_risc_v_exception_handler)
    } > RAM

    .text.freertos_risc_v_interrupt_handler : {
        *(.text.freertos_risc_v_interrupt_handler)
    } > RAM

    .text.freertos_risc_v_mtimer_interrupt_handler : {
        *(.text.freertos_risc_v_mtimer_interrupt_handler)
    } > RAM

    /* 代码段 */
    .text : {
        *(.text)
        *(.text.*)
    } > RAM

    /* 只读数据 */
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > RAM

    /* 初始化数据 */
    .data : {
        *(.data)
        *(.data.*)
        *(.got)
        *(.got.*)
        *(.sdata)
        *(.sdata.*)
    } > RAM

    /* BSS 段 */
    _bss_start = .;
    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
        *(.sbss)
        *(.sbss.*)
    } > RAM
    _bss_end = .;

    /* 栈顶 (RAM 顶部) */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /* 堆区域 (在 BSS 之后) */
    _heap_start = ALIGN(16);
    _heap_end = ORIGIN(RAM) + LENGTH(RAM) - 0x10000;  /* 留 64KB 给栈 */

    /* 放弃不需要的段 */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.riscv.attributes)
        *(.note)
        *(.note.*)
    }
}
