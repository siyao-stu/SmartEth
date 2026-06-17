/**
 * main.c — SmartEth RTOS 固件入口
 *
 * Phase 1 目标:
 *   - 验证 FreeRTOS 在 QEMU RISC-V virt 上的移植
 *   - 多任务调度 (UART 输出, LED 闪烁模拟, 定时器)
 *   - BSP 驱动验证
 */

#include <stdint.h>
#include "FreeRTOS.h"
#include "task.h"
#include "bsp/bsp.h"
#include "bsp/uart.h"
#include "bsp/clint.h"
#include "bsp/plic.h"
#include "pci_test.h"

/* ========== 任务句柄 ========== */

TaskHandle_t task_hb_handle = NULL;
TaskHandle_t task_info_handle = NULL;
TaskHandle_t task_echo_handle = NULL;
TaskHandle_t task_pci_handle = NULL;

/* ========== 任务函数 ========== */

/**
 * Task 1: 心跳任务 — 定期输出心跳计数
 */
void vTaskHeartbeat(void *pvParameters)
{
    uint32_t count = 0;

    (void)pvParameters;

    while (1) {
        uart_printf("[HB] count=0x%x\n", count++);
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}

/**
 * Task 2: 信息任务 — 输出系统信息
 */
void vTaskInfo(void *pvParameters)
{
    uint64_t mhartid, marchid, mimpid;

    (void)pvParameters;

    __asm__ volatile("csrr %0, mhartid"  : "=r"(mhartid));
    __asm__ volatile("csrr %0, marchid"  : "=r"(marchid));
    __asm__ volatile("csrr %0, mimpid"   : "=r"(mimpid));

    vTaskDelay(pdMS_TO_TICKS(500));  /* 让心跳先跑 */

    while (1) {
        uart_puts("---[INFO]---\n");
        uart_printf("  mhartid: 0x%lx\n", (unsigned long)mhartid);
        uart_printf("  marchid: 0x%lx\n", (unsigned long)marchid);
        uart_printf("  mimpid:  0x%lx\n", (unsigned long)mimpid);
        uart_printf("  Tick Hz: %d\n", (int)configTICK_RATE_HZ);
        uart_printf("  Heap:    %d bytes free\n",
                    (int)xPortGetFreeHeapSize());
        uart_puts("------------\n");
        vTaskDelay(pdMS_TO_TICKS(10000));
    }
}

/**
 * Task 3: 回显任务 — 通过 UART 接收字符并回显
 */
void vTaskEcho(void *pvParameters)
{
    (void)pvParameters;

    uart_puts("[ECHO] Enter characters (will echo back):\n");

    while (1) {
        int c = uart_getc_nonblock();
        if (c >= 0) {
            uart_putc((char)c);
            /* 回显时加换行方便查看 */
            if (c == '\r' || c == '\n')
                uart_puts("> ");
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

/**
 * Task 4: PCI 测试任务 — 扫描并验证 SmartEth PCIe 设备
 */
void vTaskPciTest(void *pvParameters)
{
    (void)pvParameters;

    /* 给其他任务一些时间输出 */
    vTaskDelay(pdMS_TO_TICKS(1000));

    uart_puts("\n");
    uart_puts("========================================\n");
    uart_puts("  PCIe Device Test Phase 2\n");
    uart_puts("========================================\n");

    /* 扫描 PCIe 总线，寻找 SmartEth 设备 */
    uint64_t bar0 = smarteth_pci_scan();

    if (bar0 != 0) {
        /* 设备存在 → 运行完整测试 */
        smarteth_run_tests(bar0);
    } else {
        uart_puts("[PCI] SmartEth device not present (expected without -device)\n");
    }

    uart_puts("[PCI] Test task complete, deleting self.\n");

    /* 任务已完成，自删除 */
    vTaskDelete(NULL);
}

/* ========== FreeRTOS 钩子函数 ========== */

void vApplicationTickHook(void)
{
    /* 定时器钩子, 当前未使用 */
}

void vApplicationIdleHook(void)
{
    /* 空闲任务钩子, 可进入低功耗 */
}

void vApplicationMallocFailedHook(void)
{
    taskDISABLE_INTERRUPTS();
    uart_puts("[FATAL] Malloc failed!\n");
    for (;;)
        ;
}

void vAssertCalled(const char *pcFile, unsigned long ulLine)
{
    taskDISABLE_INTERRUPTS();
    uart_printf("[ASSERT] %s:%lx\n", pcFile, (unsigned long)ulLine);
    for (;;)
        ;
}

/* ========== 外部中断处理 ========== */

void freertos_risc_v_application_interrupt_handler(void)
{
    /* 读取 PLIC claim → 获取中断源 */
    int irq = plic_claim();

    if (irq > 0) {
        switch (irq) {
        case 10:  /* UART 中断 */
            /* UART 中断处理 (当前未使用) */
            break;
        default:
            uart_printf("[IRQ] unhandled irq=%d\n", irq);
            break;
        }

        plic_complete(irq);
    }
}

/* ========== 主函数 ========== */

void main(void)
{
    /* 初始化 BSP */
    uart_init();
    clint_init();
    plic_init();

    uart_puts("\n");
    uart_puts("========================================\n");
    uart_puts("  SmartEth RISC-V NIC Firmware\n");
    uart_puts("  Phase 1: FreeRTOS on QEMU RISC-V\n");
    uart_puts("========================================\n");
    uart_puts("BSP Init OK\n\n");

    /* 创建任务 */
    xTaskCreate(
        vTaskHeartbeat,
        "heartbeat",
        configMINIMAL_STACK_SIZE * 2,
        NULL,
        1,
        &task_hb_handle
    );

    xTaskCreate(
        vTaskInfo,
        "info",
        configMINIMAL_STACK_SIZE * 3,
        NULL,
        1,
        &task_info_handle
    );

    xTaskCreate(
        vTaskEcho,
        "echo",
        configMINIMAL_STACK_SIZE * 3,
        NULL,
        2,
        &task_echo_handle
    );

    xTaskCreate(
        vTaskPciTest,
        "pci_test",
        configMINIMAL_STACK_SIZE * 4,
        NULL,
        1,
        &task_pci_handle
    );

    /* 启动调度器 */
    uart_puts("[SYS] Starting FreeRTOS scheduler...\n\n");
    vTaskStartScheduler();

    /* 不应到达这里 */
    uart_puts("[FATAL] Scheduler returned!\n");
    for (;;)
        ;
}
