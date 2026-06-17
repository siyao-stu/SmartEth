
hello/hello.elf:     file format elf64-littleriscv


Disassembly of section .text.init:

0000000080000000 <_start>:

.section .text.init
.globl _start
_start:
    # 设置栈指针 (指向 RAM 顶部 0x90000000)
    lla sp, _stack_top
    80000000:	10000117          	auipc	sp,0x10000
    80000004:	00010113          	mv	sp,sp

    # 清除 BSS 段
    lla t0, _bss_start
    80000008:	00000297          	auipc	t0,0x0
    8000000c:	48c28293          	addi	t0,t0,1164 # 80000494 <_bss_start>
    lla t1, _bss_end
    80000010:	00000317          	auipc	t1,0x0
    80000014:	5a030313          	addi	t1,t1,1440 # 800005b0 <_bss_end>
    bgeu t0, t1, 1f
    80000018:	0062f763          	bgeu	t0,t1,80000026 <_start+0x26>
0:
    sw zero, 0(t0)
    8000001c:	0002a023          	sw	zero,0(t0)
    addi t0, t0, 4
    80000020:	0291                	addi	t0,t0,4
    bltu t0, t1, 0b
    80000022:	fe62ede3          	bltu	t0,t1,8000001c <_start+0x1c>
1:
    # 跳转到 main
    jal main
    80000026:	0e0000ef          	jal	ra,80000106 <main>

    # main 返回后死循环
2:
    wfi
    8000002a:	10500073          	wfi
    j 2b
    8000002e:	bff5                	j	8000002a <_start+0x2a>

Disassembly of section .text:

0000000080000030 <uart_puts>:
}

/* 输出字符串 */
static void uart_puts(const char *s)
{
    while (*s)
    80000030:	00054683          	lbu	a3,0(a0)
{
    80000034:	85aa                	mv	a1,a0
    while (*s)
    80000036:	c29d                	beqz	a3,8000005c <uart_puts+0x2c>
    while (!(*lsr & UART_LSR_THRE))
    80000038:	10000737          	lui	a4,0x10000
    if (c == '\n')
    8000003c:	4629                	li	a2,10
        uart_putc(*s++);
    8000003e:	0585                	addi	a1,a1,1
    while (!(*lsr & UART_LSR_THRE))
    80000040:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80000044:	0207f793          	andi	a5,a5,32
    80000048:	dfe5                	beqz	a5,80000040 <uart_puts+0x10>
    *thr = (u8)c;
    8000004a:	00d70023          	sb	a3,0(a4)
    if (c == '\n')
    8000004e:	00c69463          	bne	a3,a2,80000056 <uart_puts+0x26>
        uart_putc('\r');
    80000052:	46b5                	li	a3,13
    while (!(*lsr & UART_LSR_THRE))
    80000054:	b7f5                	j	80000040 <uart_puts+0x10>
    while (*s)
    80000056:	0005c683          	lbu	a3,0(a1)
    8000005a:	f2f5                	bnez	a3,8000003e <uart_puts+0xe>
}
    8000005c:	8082                	ret

000000008000005e <uart_puthex_pfx>:
    uart_puts(buf);
}

/* 输出带 "0x" 前缀的十六进制 */
static void uart_puthex_pfx(const char *label, u64 val)
{
    8000005e:	7139                	addi	sp,sp,-64
    80000060:	f822                	sd	s0,48(sp)
    80000062:	fc06                	sd	ra,56(sp)
    80000064:	842e                	mv	s0,a1
    uart_puts(label);
    80000066:	00000097          	auipc	ra,0x0
    8000006a:	fca080e7          	jalr	-54(ra) # 80000030 <uart_puts>
    char hex[] = "0123456789abcdef";
    8000006e:	00000797          	auipc	a5,0x0
    80000072:	23a78793          	addi	a5,a5,570 # 800002a8 <main+0x1a2>
    80000076:	6394                	ld	a3,0(a5)
    80000078:	6798                	ld	a4,8(a5)
    8000007a:	0107c783          	lbu	a5,16(a5)
    8000007e:	e036                	sd	a3,0(sp)
    80000080:	e43a                	sd	a4,8(sp)
    80000082:	00f10823          	sb	a5,16(sp) # 90000010 <_stack_top+0x10>
    for (i = 15; i >= 0; i--) {
    80000086:	082c                	addi	a1,sp,24
    80000088:	02710793          	addi	a5,sp,39
        buf[i] = hex[val & 0xf];
    8000008c:	00f47713          	andi	a4,s0,15
    80000090:	03070713          	addi	a4,a4,48
    80000094:	970a                	add	a4,a4,sp
    80000096:	fd074683          	lbu	a3,-48(a4)
    8000009a:	873e                	mv	a4,a5
        val >>= 4;
    8000009c:	8011                	srli	s0,s0,0x4
        buf[i] = hex[val & 0xf];
    8000009e:	00d78023          	sb	a3,0(a5)
    for (i = 15; i >= 0; i--) {
    800000a2:	17fd                	addi	a5,a5,-1
    800000a4:	fee594e3          	bne	a1,a4,8000008c <uart_puthex_pfx+0x2e>
    while (*s)
    800000a8:	01814683          	lbu	a3,24(sp)
    buf[16] = '\0';
    800000ac:	02010423          	sb	zero,40(sp)
    while (*s)
    800000b0:	c29d                	beqz	a3,800000d6 <uart_puthex_pfx+0x78>
    while (!(*lsr & UART_LSR_THRE))
    800000b2:	10000737          	lui	a4,0x10000
    if (c == '\n')
    800000b6:	4629                	li	a2,10
        uart_putc(*s++);
    800000b8:	0585                	addi	a1,a1,1
    while (!(*lsr & UART_LSR_THRE))
    800000ba:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    800000be:	0207f793          	andi	a5,a5,32
    800000c2:	dfe5                	beqz	a5,800000ba <uart_puthex_pfx+0x5c>
    *thr = (u8)c;
    800000c4:	00d70023          	sb	a3,0(a4)
    if (c == '\n')
    800000c8:	00c69463          	bne	a3,a2,800000d0 <uart_puthex_pfx+0x72>
        uart_putc('\r');
    800000cc:	46b5                	li	a3,13
    while (!(*lsr & UART_LSR_THRE))
    800000ce:	b7f5                	j	800000ba <uart_puthex_pfx+0x5c>
    while (*s)
    800000d0:	0005c683          	lbu	a3,0(a1)
    800000d4:	f2f5                	bnez	a3,800000b8 <uart_puthex_pfx+0x5a>
    while (!(*lsr & UART_LSR_THRE))
    800000d6:	10000737          	lui	a4,0x10000
    800000da:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    800000de:	0207f793          	andi	a5,a5,32
    800000e2:	dfe5                	beqz	a5,800000da <uart_puthex_pfx+0x7c>
    *thr = (u8)c;
    800000e4:	47a9                	li	a5,10
    800000e6:	00f70023          	sb	a5,0(a4)
    while (!(*lsr & UART_LSR_THRE))
    800000ea:	10000737          	lui	a4,0x10000
    800000ee:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    800000f2:	0207f793          	andi	a5,a5,32
    800000f6:	dfe5                	beqz	a5,800000ee <uart_puthex_pfx+0x90>
    *thr = (u8)c;
    800000f8:	47b5                	li	a5,13
    800000fa:	00f70023          	sb	a5,0(a4)
    uart_puthex(val);
    uart_putc('\n');
}
    800000fe:	70e2                	ld	ra,56(sp)
    80000100:	7442                	ld	s0,48(sp)
    80000102:	6121                	addi	sp,sp,64
    80000104:	8082                	ret

0000000080000106 <main>:
    while (count--)
        __asm__ volatile ("" ::: "memory");
}

void main(void)
{
    80000106:	715d                	addi	sp,sp,-80
    80000108:	e486                	sd	ra,72(sp)
    8000010a:	e0a2                	sd	s0,64(sp)
    8000010c:	fc26                	sd	s1,56(sp)
    8000010e:	f84a                	sd	s2,48(sp)
    u64 mhartid, marchid, mimpid;

    __asm__ volatile("csrr %0, mhartid" : "=r"(mhartid));
    80000110:	f1402973          	csrr	s2,mhartid
    __asm__ volatile("csrr %0, marchid" : "=r"(marchid));
    80000114:	f12024f3          	csrr	s1,marchid
    __asm__ volatile("csrr %0, mimpid"  : "=r"(mimpid));
    80000118:	f1302473          	csrr	s0,mimpid

    uart_puts("\n========================================\n");
    8000011c:	00000517          	auipc	a0,0x0
    80000120:	1b450513          	addi	a0,a0,436 # 800002d0 <_PROCEDURE_LINKAGE_TABLE_+0x20>
    80000124:	00000097          	auipc	ra,0x0
    80000128:	f0c080e7          	jalr	-244(ra) # 80000030 <uart_puts>
    uart_puts("  SmartEth RISC-V NIC Firmware\n");
    8000012c:	00000517          	auipc	a0,0x0
    80000130:	1d450513          	addi	a0,a0,468 # 80000300 <_PROCEDURE_LINKAGE_TABLE_+0x50>
    80000134:	00000097          	auipc	ra,0x0
    80000138:	efc080e7          	jalr	-260(ra) # 80000030 <uart_puts>
    uart_puts("  Phase 1: QEMU RISC-V Baremetal\n");
    8000013c:	00000517          	auipc	a0,0x0
    80000140:	1e450513          	addi	a0,a0,484 # 80000320 <_PROCEDURE_LINKAGE_TABLE_+0x70>
    80000144:	00000097          	auipc	ra,0x0
    80000148:	eec080e7          	jalr	-276(ra) # 80000030 <uart_puts>
    uart_puts("========================================\n");
    8000014c:	00000517          	auipc	a0,0x0
    80000150:	1fc50513          	addi	a0,a0,508 # 80000348 <_PROCEDURE_LINKAGE_TABLE_+0x98>
    80000154:	00000097          	auipc	ra,0x0
    80000158:	edc080e7          	jalr	-292(ra) # 80000030 <uart_puts>
    uart_puts("BSP Init OK\n");
    8000015c:	00000517          	auipc	a0,0x0
    80000160:	21c50513          	addi	a0,a0,540 # 80000378 <_PROCEDURE_LINKAGE_TABLE_+0xc8>
    80000164:	00000097          	auipc	ra,0x0
    80000168:	ecc080e7          	jalr	-308(ra) # 80000030 <uart_puts>
    uart_puts("Platform: QEMU riscv64 virt\n\n");
    8000016c:	00000517          	auipc	a0,0x0
    80000170:	21c50513          	addi	a0,a0,540 # 80000388 <_PROCEDURE_LINKAGE_TABLE_+0xd8>
    80000174:	00000097          	auipc	ra,0x0
    80000178:	ebc080e7          	jalr	-324(ra) # 80000030 <uart_puts>

    uart_puts("--- CPU Info ---\n");
    8000017c:	00000517          	auipc	a0,0x0
    80000180:	22c50513          	addi	a0,a0,556 # 800003a8 <_PROCEDURE_LINKAGE_TABLE_+0xf8>
    80000184:	00000097          	auipc	ra,0x0
    80000188:	eac080e7          	jalr	-340(ra) # 80000030 <uart_puts>
    uart_puthex_pfx("  mhartid: 0x", mhartid);
    8000018c:	85ca                	mv	a1,s2
    8000018e:	00000517          	auipc	a0,0x0
    80000192:	23250513          	addi	a0,a0,562 # 800003c0 <_PROCEDURE_LINKAGE_TABLE_+0x110>
    80000196:	00000097          	auipc	ra,0x0
    8000019a:	ec8080e7          	jalr	-312(ra) # 8000005e <uart_puthex_pfx>
    uart_puthex_pfx("  marchid: 0x", marchid);
    8000019e:	85a6                	mv	a1,s1
    800001a0:	00000517          	auipc	a0,0x0
    800001a4:	23050513          	addi	a0,a0,560 # 800003d0 <_PROCEDURE_LINKAGE_TABLE_+0x120>
    800001a8:	00000097          	auipc	ra,0x0
    800001ac:	eb6080e7          	jalr	-330(ra) # 8000005e <uart_puthex_pfx>
    uart_puthex_pfx("  mimpid:  0x", mimpid);
    800001b0:	85a2                	mv	a1,s0
    800001b2:	00000517          	auipc	a0,0x0
    800001b6:	22e50513          	addi	a0,a0,558 # 800003e0 <_PROCEDURE_LINKAGE_TABLE_+0x130>
    800001ba:	00000097          	auipc	ra,0x0
    800001be:	ea4080e7          	jalr	-348(ra) # 8000005e <uart_puthex_pfx>
    uart_puts("---\n\n");
    800001c2:	00000517          	auipc	a0,0x0
    800001c6:	22e50513          	addi	a0,a0,558 # 800003f0 <_PROCEDURE_LINKAGE_TABLE_+0x140>
    800001ca:	00000097          	auipc	ra,0x0
    800001ce:	e66080e7          	jalr	-410(ra) # 80000030 <uart_puts>
    *thr = (u8)c;
    800001d2:	004c58b7          	lui	a7,0x4c5

    u32 counter = 0;
    800001d6:	4581                	li	a1,0
    800001d8:	00000317          	auipc	t1,0x0
    800001dc:	0d030313          	addi	t1,t1,208 # 800002a8 <main+0x1a2>
    800001e0:	01810813          	addi	a6,sp,24
    800001e4:	02710e93          	addi	t4,sp,39
    while (!(*lsr & UART_LSR_THRE))
    800001e8:	10000737          	lui	a4,0x10000
    if (c == '\n')
    800001ec:	4629                	li	a2,10
        uart_putc('\r');
    800001ee:	4e35                	li	t3,13
    *thr = (u8)c;
    800001f0:	b4088893          	addi	a7,a7,-1216 # 4c4b40 <_start-0x7fb3b4c0>
    while (*s)
    800001f4:	05b00693          	li	a3,91
    800001f8:	00000517          	auipc	a0,0x0
    800001fc:	0c850513          	addi	a0,a0,200 # 800002c0 <_PROCEDURE_LINKAGE_TABLE_+0x10>
        uart_putc(*s++);
    80000200:	0505                	addi	a0,a0,1
    while (!(*lsr & UART_LSR_THRE))
    80000202:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80000206:	0207f793          	andi	a5,a5,32
    8000020a:	dfe5                	beqz	a5,80000202 <main+0xfc>
    *thr = (u8)c;
    8000020c:	00d70023          	sb	a3,0(a4)
    if (c == '\n')
    80000210:	00c69463          	bne	a3,a2,80000218 <main+0x112>
        uart_putc('\r');
    80000214:	46b5                	li	a3,13
    while (!(*lsr & UART_LSR_THRE))
    80000216:	b7f5                	j	80000202 <main+0xfc>
    while (*s)
    80000218:	00054683          	lbu	a3,0(a0)
    8000021c:	f2f5                	bnez	a3,80000200 <main+0xfa>
    char hex[] = "0123456789abcdef";
    8000021e:	01034783          	lbu	a5,16(t1)
    80000222:	00033503          	ld	a0,0(t1)
    80000226:	00833683          	ld	a3,8(t1)
    while (1) {
        uart_puts("[HB] count=0x");
        uart_puthex(counter++);
    8000022a:	00158f1b          	addiw	t5,a1,1
    8000022e:	1582                	slli	a1,a1,0x20
    char hex[] = "0123456789abcdef";
    80000230:	00f10823          	sb	a5,16(sp)
        uart_puthex(counter++);
    80000234:	9181                	srli	a1,a1,0x20
    char hex[] = "0123456789abcdef";
    80000236:	e02a                	sd	a0,0(sp)
    80000238:	e436                	sd	a3,8(sp)
    8000023a:	87f6                	mv	a5,t4
        buf[i] = hex[val & 0xf];
    8000023c:	00f5f693          	andi	a3,a1,15
    80000240:	03068693          	addi	a3,a3,48
    80000244:	968a                	add	a3,a3,sp
    80000246:	fd06c503          	lbu	a0,-48(a3)
    8000024a:	86be                	mv	a3,a5
        val >>= 4;
    8000024c:	8191                	srli	a1,a1,0x4
        buf[i] = hex[val & 0xf];
    8000024e:	00a78023          	sb	a0,0(a5)
    for (i = 15; i >= 0; i--) {
    80000252:	17fd                	addi	a5,a5,-1
    80000254:	fed814e3          	bne	a6,a3,8000023c <main+0x136>
    while (*s)
    80000258:	01814683          	lbu	a3,24(sp)
    buf[16] = '\0';
    8000025c:	02010423          	sb	zero,40(sp)
    while (*s)
    80000260:	c28d                	beqz	a3,80000282 <main+0x17c>
    80000262:	85c2                	mv	a1,a6
        uart_putc(*s++);
    80000264:	0585                	addi	a1,a1,1
    while (!(*lsr & UART_LSR_THRE))
    80000266:	00574783          	lbu	a5,5(a4)
    8000026a:	0207f793          	andi	a5,a5,32
    8000026e:	dfe5                	beqz	a5,80000266 <main+0x160>
    *thr = (u8)c;
    80000270:	00d70023          	sb	a3,0(a4)
    if (c == '\n')
    80000274:	00c69463          	bne	a3,a2,8000027c <main+0x176>
        uart_putc('\r');
    80000278:	46b5                	li	a3,13
    while (!(*lsr & UART_LSR_THRE))
    8000027a:	b7f5                	j	80000266 <main+0x160>
    while (*s)
    8000027c:	0005c683          	lbu	a3,0(a1)
    80000280:	f2f5                	bnez	a3,80000264 <main+0x15e>
    while (!(*lsr & UART_LSR_THRE))
    80000282:	00574783          	lbu	a5,5(a4)
    80000286:	0207f793          	andi	a5,a5,32
    8000028a:	dfe5                	beqz	a5,80000282 <main+0x17c>
    *thr = (u8)c;
    8000028c:	00c70023          	sb	a2,0(a4)
    while (!(*lsr & UART_LSR_THRE))
    80000290:	00574783          	lbu	a5,5(a4)
    80000294:	0207f793          	andi	a5,a5,32
    80000298:	dfe5                	beqz	a5,80000290 <main+0x18a>
    *thr = (u8)c;
    8000029a:	01c70023          	sb	t3,0(a4)
    8000029e:	87c6                	mv	a5,a7
    while (count--)
    800002a0:	37fd                	addiw	a5,a5,-1
    800002a2:	fffd                	bnez	a5,800002a0 <main+0x19a>
        uart_puthex(counter++);
    800002a4:	85fa                	mv	a1,t5
    800002a6:	b7b9                	j	800001f4 <main+0xee>
