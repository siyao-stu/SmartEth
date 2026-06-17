/**
 * startup.S — SmartEth RTOS 启动代码 (QEMU RISC-V virt)
 *
 * 启动流程:
 *   1. 设置栈指针
 *   2. 清除 BSS 段
 *   3. 设置陷阱向量 (mtvec → freertos_risc_v_trap_handler)
 *   4. 使能定时器中断和外部中断 (mie)
 *   5. 跳转到 main()
 *
 * 注: 全局中断 (mstatus.MIE) 由 vTaskStartScheduler 使能。
 */

.section .text.init
.globl _start
_start:
    /* 栈指针 → RAM 顶部 */
    lla sp, _stack_top

    /* 清除 BSS */
    lla t0, _bss_start
    lla t1, _bss_end
    bgeu t0, t1, 1f
0:
    sw zero, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, 0b
1:
    /* 设置陷阱向量 → FreeRTOS 陷阱处理程序 */
    lla t0, freertos_risc_v_trap_handler
    csrw mtvec, t0

    /* 使能机器模式定时器中断 (MTI) + 外部中断 (MEI) */
    li t0, 0x880   /* MIE[7]=MTIE, MIE[11]=MEIE = 0x880 */
    csrw mie, t0

    /* 跳转到 main */
    jal main

    /* main 不应返回 */
2:
    wfi
    j 2b
