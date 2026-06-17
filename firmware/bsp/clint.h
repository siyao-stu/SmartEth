#ifndef __BSP_CLINT_H__
#define __BSP_CLINT_H__

#include <stdint.h>

/* CLINT 控制函数 */
void    clint_init(void);
void    clint_set_mtimecmp(uint64_t value);
uint64_t clint_get_time(void);
void    clint_set_tick(uint64_t tick_interval);
void    clint_clear_timer_int(void);

/* 默认 tick 间隔 (约 10ms @ QEMU 10MHz RTCCLK) */
#define CLINT_DEFAULT_TICK_US   10000  /* 10ms */

#endif /* __BSP_CLINT_H__ */
