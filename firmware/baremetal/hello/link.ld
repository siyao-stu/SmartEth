/* QEMU RISC-V virt 平台链接脚本 */
/* RAM: 0x80000000 ~ 0x80000000 + 256MB（QEMU virt 默认） */

ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
    . = ORIGIN(RAM);

    /* 启动代码放在最前面 */
    .text.init : {
        *(.text.init)
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

    /* 数据段 */
    .data : {
        *(.data)
        *(.data.*)
    } > RAM

    /* BSS 段 */
    _bss_start = .;
    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } > RAM
    _bss_end = .;

    /* 栈顶 */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
