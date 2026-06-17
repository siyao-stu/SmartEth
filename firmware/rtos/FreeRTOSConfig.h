#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

/* ========== RISC-V 平台配置 ========== */

/* CLINT/mtime 寄存器地址 (QEMU RISC-V virt) */
#define configMTIME_BASE_ADDRESS     (0x0200BFF8ULL)
#define configMTIMECMP_BASE_ADDRESS  (0x02004000ULL)

/* 使用静态 ISR 栈 (否则需要链接脚本提供 __freertos_irq_stack_top) */
#define configISR_STACK_SIZE_WORDS   512

/* ========== 基础配置 ========== */

#define configUSE_PREEMPTION         1
#define configUSE_IDLE_HOOK          0
#define configUSE_TICK_HOOK          0
#define configCPU_CLOCK_HZ           (10000000UL)     /* QEMU virt RTCCLK ~10MHz */
#define configTICK_RATE_HZ           ((TickType_t)100) /* 100Hz = 10ms tick */
#define configMAX_PRIORITIES         5
#define configMINIMAL_STACK_SIZE     ((unsigned short)128)
#define configTOTAL_HEAP_SIZE        ((size_t)(64 * 1024))  /* 64KB heap */
#define configMAX_TASK_NAME_LEN      16
#define configUSE_16_BIT_TICKS       0
#define configIDLE_SHOULD_YIELD      1
#define configUSE_MUTEXES            1
#define configUSE_RECURSIVE_MUTEXES  0
#define configUSE_COUNTING_SEMAPHORES 1
#define configUSE_TRACE_FACILITY     0
#define configQUEUE_REGISTRY_SIZE    8
#define configUSE_QUEUE_SETS         0
#define configUSE_TIME_SLICING       1
#define configUSE_NEWLIB_REENTRANT   0
#define configENABLE_BACKWARD_COMPATIBILITY 0
#define configNUM_THREAD_LOCAL_STORAGE_POINTERS 0
#define configSTACK_DEPTH_TYPE       uint16_t

/* ========== 内存管理 ========== */

#define configSUPPORT_STATIC_ALLOCATION      0
#define configSUPPORT_DYNAMIC_ALLOCATION     1
#define configAPPLICATION_ALLOCATED_HEAP     0

/* ========== 协程 (不使用) ========== */

#define configUSE_CO_ROUTINES          0
#define configMAX_CO_ROUTINE_PRIORITIES 1

/* ========== 定时器 ========== */

#define configUSE_TIMERS               1
#define configTIMER_TASK_PRIORITY      2
#define configTIMER_QUEUE_LENGTH       10
#define configTIMER_TASK_STACK_DEPTH   (configMINIMAL_STACK_SIZE * 2)

/* ========== 断言 ========== */

#define configASSERT(x)    if ((x) == 0) { taskDISABLE_INTERRUPTS(); for (;;); }

/* ========== 可选功能 ========== */

#define INCLUDE_vTaskPrioritySet            1
#define INCLUDE_uxTaskPriorityGet           1
#define INCLUDE_vTaskDelete                 1
#define INCLUDE_vTaskSuspend                1
#define INCLUDE_xTaskDelayUntil             1
#define INCLUDE_vTaskDelay                  1
#define INCLUDE_uxTaskGetStackHighWaterMark 0
#define INCLUDE_xTaskGetSchedulerState      0
#define INCLUDE_xTimerGetTimerDaemonTaskHandle 0
#define INCLUDE_xTaskGetIdleTaskHandle      0
#define INCLUDE_pcTaskGetTaskName           0
#define INCLUDE_xSemaphoreGetMutexHolder    0

/* ========== 中断优先级 (RISC-V 机器模式) ========== */

/* RISC-V 机器模式没有中断优先级中断嵌套 (所有中断屏蔽在 MIE),
 * 所以 configMAX_SYSCALL_INTERRUPT_PRIORITY 和 configKERNEL_INTERRUPT_PRIORITY
 * 需要对应机器模式下的处理.
 *
 * 在 FreeRTOS RISC-V 机器模式端口中, 只有机器模式定时器中断 (MTI) 和
 * 机器模式外部中断 (MEI) 参与. 任何 MIE 中的中断位都可以被临界区屏蔽.
 */
#define configMAX_SYSCALL_INTERRUPT_PRIORITY  0
#define configKERNEL_INTERRUPT_PRIORITY       0

/* ========== 函数原型 ========== */

void vApplicationTickHook(void);
void vApplicationIdleHook(void);
void vAssertCalled(const char *pcFile, unsigned long ulLine);

#endif /* FREERTOS_CONFIG_H */
