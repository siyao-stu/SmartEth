#ifndef __BSP_H__
#define __BSP_H__

#include <stdint.h>

/* ========== 内存映射 (QEMU RISC-V virt) ========== */

/* CLINT (Core Local Interruptor) */
#define CLINT_BASE          0x02000000UL
#define CLINT_MSIP(hart)    (CLINT_BASE + 0x0000 + (hart) * 4)
#define CLINT_MTIMECMP(hart)(CLINT_BASE + 0x4000 + (hart) * 8)
#define CLINT_MTIME         (CLINT_BASE + 0xBFF8)

/* PLIC (Platform Level Interrupt Controller) */
#define PLIC_BASE           0x0C000000UL
#define PLIC_PRIORITY(idx)  (PLIC_BASE + (idx) * 4)
#define PLIC_PENDING         (PLIC_BASE + 0x1000)
#define PLIC_ENABLE(hart)   (PLIC_BASE + 0x2000 + (hart) * 0x80)
#define PLIC_THRESHOLD(hart)(PLIC_BASE + 0x200000 + (hart) * 0x1000)
#define PLIC_CLAIM(hart)    (PLIC_BASE + 0x200004 + (hart) * 0x1000)

/* UART (NS16550A) */
#define UART_BASE           0x10000000UL

/* ========== CSR 操作 ========== */

static inline uint64_t read_csr(uint64_t addr)
{
    uint64_t val;
    __asm__ volatile("csrr %0, %1" : "=r"(val) : "i"(addr));
    return val;
}

static inline void write_csr(uint64_t addr, uint64_t val)
{
    __asm__ volatile("csrw %0, %1" : : "i"(addr), "r"(val));
}

static inline void set_csr_bits(uint64_t addr, uint64_t val)
{
    __asm__ volatile("csrs %0, %1" : : "i"(addr), "r"(val));
}

static inline void clear_csr_bits(uint64_t addr, uint64_t val)
{
    __asm__ volatile("csrc %0, %1" : : "i"(addr), "r"(val));
}

/* ========== CSR 地址常量 ========== */
#define CSR_MTVEC           0x305
#define CSR_MSTATUS         0x300
#define CSR_MIE             0x304
#define CSR_MSCRATCH        0x340
#define CSR_MEPC            0x341
#define CSR_MCAUSE          0x342
#define CSR_MTVAL           0x343
#define CSR_MIP             0x344

/* MIE/MIP 中断位 */
#define MIP_MSIE            (1UL << 3)  /* Software Interrupt */
#define MIP_MTIE            (1UL << 7)  /* Timer Interrupt */
#define MIP_MEIE            (1UL << 11) /* External Interrupt */

/* MSTATUS 位 */
#define MSTATUS_MIE         (1UL << 3)  /* Machine Interrupt Enable */
#define MSTATUS_MPP         (3UL << 11) /* Machine Previous Privilege */

/* MCAUSE 异常码 */
#define MCAUSE_MTI          0x80000007UL /* Machine Timer Interrupt */
#define MCAUSE_MEI          0x8000000BUL /* Machine External Interrupt */
#define MCAUSE_MSI          0x80000003UL /* Machine Software Interrupt */

/* ========== BSP 初始化 ========== */

void bsp_init(void);
void bsp_trap_handler(void);

/* ========== 外部中断处理注册 ========== */

typedef void (*irq_handler_t)(int irq);
void bsp_register_ext_irq(irq_handler_t handler);

#endif /* __BSP_H__ */
