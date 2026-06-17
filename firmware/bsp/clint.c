/**
 * clint.c — CLINT 定时器驱动 (QEMU RISC-V virt)
 *
 * CLINT 提供了:
 *   - mtime: 64-bit 计数器, 以 RTCCLK 频率递增 (QEMU 默认 ~10MHz)
 *   - mtimecmp: 每个 hart 的比较寄存器, 当 mtime >= mtimecmp 时触发定时器中断
 *   - msip: 每个 hart 的软件中断寄存器
 */

#include "bsp.h"
#include "clint.h"

/* CLINT 寄存器指针 (volatile) */
static volatile uint64_t * const clint_mtime =
    (volatile uint64_t *)CLINT_MTIME;
static volatile uint64_t * const clint_mtimecmp_h0 =
    (volatile uint64_t *)CLINT_MTIMECMP(0);

void clint_init(void)
{
    /* 初始设置 mtimecmp 为一个很大的值, 禁止定时器中断 */
    clint_mtimecmp_h0[0] = UINT64_MAX;
}

void clint_set_mtimecmp(uint64_t value)
{
    clint_mtimecmp_h0[0] = value;
}

uint64_t clint_get_time(void)
{
    return *clint_mtime;
}

void clint_set_tick(uint64_t tick_interval)
{
    uint64_t current = clint_get_time();
    clint_set_mtimecmp(current + tick_interval);
}

void clint_clear_timer_int(void)
{
    /* 清除定时器中断 = 设置新的 mtimecmp */
    uint64_t current = clint_get_time();

    /* 先设为 UINT64_MAX 防止在设置期间重复触发 */
    clint_mtimecmp_h0[0] = UINT64_MAX;

    /* 重新设置 */
    clint_mtimecmp_h0[0] = current + CLINT_DEFAULT_TICK_US;
}
