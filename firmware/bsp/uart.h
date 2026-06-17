#ifndef __BSP_UART_H__
#define __BSP_UART_H__

#include <stdint.h>

/* NS16550A UART 寄存器 (偏移地址) */
#define UART_RBR    0   /* 接收缓冲 (R) */
#define UART_THR    0   /* 发送保持 (W) */
#define UART_DLL    0   /* 除数低字节 (R/W, DLAB=1) */
#define UART_IER    1   /* 中断使能 (R/W) */
#define UART_DLM    1   /* 除数高字节 (R/W, DLAB=1) */
#define UART_IIR    2   /* 中断标识 (R) */
#define UART_FCR    2   /* FIFO控制 (W) */
#define UART_LCR    3   /* 线路控制 (R/W) */
#define UART_MCR    4   /* 调制解调器控制 (R/W) */
#define UART_LSR    5   /* 线路状态 (R) */
#define UART_MSR    6   /* 调制解调器状态 (R) */
#define UART_SCR    7   /* 暂存 (R/W) */

/* LSR 状态位 */
#define UART_LSR_DR      0x01  /* 数据就绪 */
#define UART_LSR_THRE    0x20  /* 发送保持寄存器空 */
#define UART_LSR_TEMT    0x40  /* 发送器空 */

/* 中断号 (PLIC) */
#define UART_IRQ         10

void uart_init(void);
void uart_putc(char c);
char uart_getc(void);
int  uart_getc_nonblock(void);
void uart_puts(const char *s);
void uart_puthex(uint64_t val);
void uart_printf(const char *fmt, ...) __attribute__((format(printf, 1, 2)));

#endif /* __BSP_UART_H__ */
