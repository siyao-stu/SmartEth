#  QEMU RISC-V virt 平台启动代码
#  设置栈指针 -> 清除 BSS -> 跳转到 main
#
#  使用 lla (Local Load Address) 而非 la:
#  - la 可能生成 GOT 访问 (auipc + ld) → 需要 GOT 初始化，静态链接时不工作
#  - lla 始终生成 PC-relative (auipc + addi) → 链接器直接解析地址，不依赖 GOT

.section .text.init
.globl _start
_start:
    # 设置栈指针 (指向 RAM 顶部 0x90000000)
    lla sp, _stack_top

    # 清除 BSS 段
    lla t0, _bss_start
    lla t1, _bss_end
    bgeu t0, t1, 1f
0:
    sw zero, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, 0b
1:
    # 跳转到 main
    jal main

    # main 返回后死循环
2:
    wfi
    j 2b
