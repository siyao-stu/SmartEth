/**
 * uart.c — NS16550A UART 驱动 (QEMU RISC-V virt @ 0x10000000)
 */

#include "bsp.h"
#include "uart.h"
#include <stdarg.h>

/* UART 寄存器基址 */
#define UART  ((volatile uint8_t *)UART_BASE)

void uart_init(void)
{
    /* QEMU 默认已经配置好 UART, 这里做基本初始化 */

    /* 设置波特率: 禁用中断 -> 设置 DLAB -> 写除数 -> 清除 DLAB */
    uint8_t lcr = UART[UART_LCR];

    UART[UART_IER] = 0x00;              /* 关中断 */
    UART[UART_LCR] = lcr | 0x80;        /* 置 DLAB */
    UART[UART_DLL] = 1;                 /* 115200 (1.8432MHz / 16 / 1) */
    UART[UART_DLM] = 0;
    UART[UART_LCR] = lcr & ~0x80;       /* 清 DLAB */

    /* 8N1, 使能 FIFO */
    UART[UART_LCR] = 0x03;              /* 8位, 无校验, 1停止位 */
    UART[UART_FCR] = 0x01;              /* 使能 FIFO */
}

void uart_putc(char c)
{
    /* 等待发送 FIFO 空 */
    while (!(UART[UART_LSR] & UART_LSR_THRE))
        ;

    UART[UART_THR] = (uint8_t)c;

    /* LF -> CR+LF */
    if (c == '\n')
        uart_putc('\r');
}

char uart_getc(void)
{
    /* 等待数据就绪 */
    while (!(UART[UART_LSR] & UART_LSR_DR))
        ;

    return (char)UART[UART_RBR];
}

int uart_getc_nonblock(void)
{
    if (UART[UART_LSR] & UART_LSR_DR)
        return (char)UART[UART_RBR];

    return -1;  /* 无可读数据 */
}

void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

void uart_puthex(uint64_t val)
{
    const char hex[] = "0123456789abcdef";
    char buf[17];
    int i;

    for (i = 15; i >= 0; i--) {
        buf[i] = hex[val & 0xf];
        val >>= 4;
    }
    buf[16] = '\0';
    uart_puts(buf);
}

void uart_printf(const char *fmt, ...)
{
    va_list args;
    char buf[256];
    int len;

    va_start(args, fmt);
    /* 简单的格式化: 用 vsnprintf, 但嵌入式没有 stdio.h */
    /* 自己实现一个极简的 */
    len = 0;
    while (*fmt && len < (int)sizeof(buf) - 1) {
        if (*fmt == '%') {
            fmt++;
            switch (*fmt) {
            case 's': {
                const char *s = va_arg(args, const char *);
                while (*s && len < (int)sizeof(buf) - 1)
                    buf[len++] = *s++;
                break;
            }
            case 'x': {
                unsigned int v = va_arg(args, unsigned int);
                int shift;
                int started = 0;
                for (shift = 28; shift >= 0; shift -= 4) {
                    int nibble = (v >> shift) & 0xf;
                    if (nibble || started || shift == 0) {
                        buf[len++] = "0123456789abcdef"[nibble];
                        started = 1;
                    }
                }
                if (!started) buf[len++] = '0';
                break;
            }
            case 'l': {
                /* Handle %lx, %ld etc. */
                fmt++;
                switch (*fmt) {
                case 'x': {
                    unsigned long v = va_arg(args, unsigned long);
                    int shift;
                    int started = 0;
                    for (shift = 60; shift >= 0; shift -= 4) {
                        int nibble = (v >> shift) & 0xf;
                        if (nibble || started || shift == 0) {
                            buf[len++] = "0123456789abcdef"[nibble];
                            started = 1;
                        }
                    }
                    if (!started) buf[len++] = '0';
                    break;
                }
                case 'd':
                case 'i': {
                    long v = va_arg(args, long);
                    unsigned long u;
                    char tmp[24];
                    int tlen = 0, i;
                    if (v < 0) {
                        buf[len++] = '-';
                        u = -(unsigned long)v;
                    } else {
                        u = (unsigned long)v;
                    }
                    if (u == 0) tmp[tlen++] = '0';
                    while (u > 0) {
                        tmp[tlen++] = '0' + (u % 10);
                        u /= 10;
                    }
                    for (i = tlen - 1; i >= 0; i--)
                        buf[len++] = tmp[i];
                    break;
                }
                case 'u': {
                    unsigned long v = va_arg(args, unsigned long);
                    char tmp[24];
                    int tlen = 0, i;
                    if (v == 0) tmp[tlen++] = '0';
                    while (v > 0) {
                        tmp[tlen++] = '0' + (v % 10);
                        v /= 10;
                    }
                    for (i = tlen - 1; i >= 0; i--)
                        buf[len++] = tmp[i];
                    break;
                }
                default:
                    buf[len++] = '%';
                    buf[len++] = 'l';
                    buf[len++] = *fmt;
                    break;
                }
                break;
            }
            case 'd':
            case 'i': {
                long v = va_arg(args, int);
                unsigned long u;
                char tmp[24];
                int tlen = 0, i;
                if (v < 0) {
                    buf[len++] = '-';
                    u = -(unsigned long)v;
                } else {
                    u = (unsigned long)v;
                }
                if (u == 0) tmp[tlen++] = '0';
                while (u > 0) {
                    tmp[tlen++] = '0' + (u % 10);
                    u /= 10;
                }
                for (i = tlen - 1; i >= 0; i--)
                    buf[len++] = tmp[i];
                break;
            }
            case 'u': {
                unsigned long v = va_arg(args, unsigned int);
                char tmp[24];
                int tlen = 0, i;
                if (v == 0) tmp[tlen++] = '0';
                while (v > 0) {
                    tmp[tlen++] = '0' + (v % 10);
                    v /= 10;
                }
                for (i = tlen - 1; i >= 0; i--)
                    buf[len++] = tmp[i];
                break;
            }
            case 'c': {
                char c = (char)va_arg(args, int);
                buf[len++] = c;
                break;
            }
            case '%':
                buf[len++] = '%';
                break;
            default:
                buf[len++] = '%';
                buf[len++] = *fmt;
                break;
            }
        } else {
            buf[len++] = *fmt;
        }
        fmt++;
    }
    buf[len] = '\0';
    va_end(args);

    uart_puts(buf);
}
