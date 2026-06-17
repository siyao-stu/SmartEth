/**
 * hello.c — QEMU RISC-V virt 平台裸机示例
 *
 * 演示:
 *   - UART 输出 (NS16550A @ 0x10000000)
 *   - CSRR 读取 CPU 信息 (mhartid, marchid, mimpid)
 *   - 心跳主循环
 */

#define UART_BASE       0x10000000UL
#define UART_THR        0   /* Transmit Holding Register (W) */
#define UART_LSR        5   /* Line Status Register (R)     */
#define UART_LSR_THRE   0x20/* Transmitter Hold Reg Empty   */

typedef unsigned char  u8;
typedef unsigned long  u64;
typedef unsigned int   u32;

/* 等待 UART 发送 FIFO 为空 */
static void uart_wait_txrdy(void)
{
    volatile u8 *lsr = (volatile u8 *)(UART_BASE + UART_LSR);
    while (!(*lsr & UART_LSR_THRE))
        ;
}

/* 输出一个字符 */
static void uart_putc(char c)
{
    volatile u8 *thr = (volatile u8 *)UART_BASE;
    uart_wait_txrdy();
    *thr = (u8)c;
    if (c == '\n')
        uart_putc('\r');
}

/* 输出字符串 */
static void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

/* 输出十六进制数 (直接数字, 无前缀) */
static void uart_puthex(u64 val)
{
    char hex[] = "0123456789abcdef";
    char buf[17];
    int i;
    for (i = 15; i >= 0; i--) {
        buf[i] = hex[val & 0xf];
        val >>= 4;
    }
    buf[16] = '\0';
    uart_puts(buf);
}

/* 输出带 "0x" 前缀的十六进制 */
static void uart_puthex_pfx(const char *label, u64 val)
{
    uart_puts(label);
    uart_puthex(val);
    uart_putc('\n');
}

/* 忙等待 (简单延时) */
static void delay(u32 count)
{
    while (count--)
        __asm__ volatile ("" ::: "memory");
}

void main(void)
{
    u64 mhartid, marchid, mimpid;

    __asm__ volatile("csrr %0, mhartid" : "=r"(mhartid));
    __asm__ volatile("csrr %0, marchid" : "=r"(marchid));
    __asm__ volatile("csrr %0, mimpid"  : "=r"(mimpid));

    uart_puts("\n========================================\n");
    uart_puts("  SmartEth RISC-V NIC Firmware\n");
    uart_puts("  Phase 1: QEMU RISC-V Baremetal\n");
    uart_puts("========================================\n");
    uart_puts("BSP Init OK\n");
    uart_puts("Platform: QEMU riscv64 virt\n\n");

    uart_puts("--- CPU Info ---\n");
    uart_puthex_pfx("  mhartid: 0x", mhartid);
    uart_puthex_pfx("  marchid: 0x", marchid);
    uart_puthex_pfx("  mimpid:  0x", mimpid);
    uart_puts("---\n\n");

    u32 counter = 0;
    while (1) {
        uart_puts("[HB] count=0x");
        uart_puthex(counter++);
        uart_putc('\n');
        delay(5000000);
    }
}
