/**
 * plic.c — PLIC 中断控制器驱动 (QEMU RISC-V virt @ 0x0C000000)
 *
 * PLIC 管理所有外部中断 (来自 UART, VIRTIO, PCIe 等设备)
 */

#include "bsp.h"
#include "plic.h"

/* PLIC 寄存器指针 */
#define PLIC_PRIORITY_BASE     ((volatile uint32_t *)PLIC_BASE)
#define PLIC_ENABLE_BASE(hart)((volatile uint32_t *)(PLIC_ENABLE(hart)))
#define PLIC_THRESHOLD_REG(hart) ((volatile uint32_t *)(PLIC_THRESHOLD(hart)))
#define PLIC_CLAIM_REG(hart)  ((volatile uint32_t *)(PLIC_CLAIM(hart)))

#define CURRENT_HART  0  /* 单核, hart 0 */

void plic_init(void)
{
    /* 设置中断阈值, 禁止所有优先级 < threshold 的中断 */
    *PLIC_THRESHOLD_REG(CURRENT_HART) = 0;  /* 允许所有中断 */

    /* 默认所有中断优先级为 0 (最低) */
    /* 在使能具体中断时再设置优先级 */
}

void plic_enable_irq(int irq)
{
    volatile uint32_t *enable = PLIC_ENABLE_BASE(CURRENT_HART);

    if (irq < 0 || irq > PLIC_MAX_IRQ)
        return;

    enable[irq / 32] |= (1UL << (irq % 32));
}

void plic_disable_irq(int irq)
{
    volatile uint32_t *enable = PLIC_ENABLE_BASE(CURRENT_HART);

    if (irq < 0 || irq > PLIC_MAX_IRQ)
        return;

    enable[irq / 32] &= ~(1UL << (irq % 32));
}

void plic_set_priority(int irq, uint32_t priority)
{
    volatile uint32_t *prio = PLIC_PRIORITY_BASE;

    if (irq < 0 || irq > PLIC_MAX_IRQ || priority > 7)
        return;

    prio[irq] = priority;
}

void plic_set_threshold(uint32_t threshold)
{
    *PLIC_THRESHOLD_REG(CURRENT_HART) = threshold;
}

int plic_claim(void)
{
    return (int)*PLIC_CLAIM_REG(CURRENT_HART);
}

void plic_complete(int irq)
{
    *PLIC_CLAIM_REG(CURRENT_HART) = (uint32_t)irq;
}
