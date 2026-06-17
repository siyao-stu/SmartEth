# tools/debug.gdb — GDB 初始化脚本
#
# 用法:
#   riscv64-unknown-elf-gdb firmware/baremetal/hello/hello.elf -x tools/debug.gdb

set architecture riscv:rv64
set confirm off

# 连接到 QEMU GDB stub
target remote :1234

# 初始断点: _start (入口) 和 main
break _start
break main

# 显示源码和反汇编
display/5i $pc

echo \n=== 已连接到 QEMU RISC-V ===\n
echo 断点: _start, main\n
echo 输入 continue 开始运行\n
