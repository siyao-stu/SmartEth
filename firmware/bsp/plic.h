#ifndef __BSP_PLIC_H__
#define __BSP_PLIC_H__

#include <stdint.h>

/* PLIC 中断控制函数 */
void plic_init(void);
void plic_enable_irq(int irq);
void plic_disable_irq(int irq);
void plic_set_priority(int irq, uint32_t priority);
void plic_set_threshold(uint32_t threshold);
int  plic_claim(void);
void plic_complete(int irq);

/* 最大中断源 (QEMU virt PLIC) */
#define PLIC_MAX_IRQ   127

#endif /* __BSP_PLIC_H__ */
