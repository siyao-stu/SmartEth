
smartnic_rtos.elf:     file format elf64-littleriscv


Disassembly of section .text.init:

0000000080000000 <_start>:

.section .text.init
.globl _start
_start:
    /* 栈指针 → RAM 顶部 */
    lla sp, _stack_top
    80000000:	10000117          	auipc	sp,0x10000
    80000004:	00010113          	mv	sp,sp

    /* 清除 BSS */
    lla t0, _bss_start
    80000008:	00007297          	auipc	t0,0x7
    8000000c:	86828293          	addi	t0,t0,-1944 # 80006870 <xSuspendedTaskList>
    lla t1, _bss_end
    80000010:	00018317          	auipc	t1,0x18
    80000014:	bd430313          	addi	t1,t1,-1068 # 80017be4 <_bss_end>
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
    /* 设置陷阱向量 → FreeRTOS 陷阱处理程序 */
    lla t0, freertos_risc_v_trap_handler
    80000026:	00000297          	auipc	t0,0x0
    8000002a:	0da28293          	addi	t0,t0,218 # 80000100 <freertos_risc_v_trap_handler>
    csrw mtvec, t0
    8000002e:	30529073          	csrw	mtvec,t0

    /* 使能机器模式定时器中断 (MTI) + 外部中断 (MEI) */
    li t0, 0x880   /* MIE[7]=MTIE, MIE[11]=MEIE = 0x880 */
    80000032:	6285                	lui	t0,0x1
    80000034:	8802829b          	addiw	t0,t0,-1920 # 880 <_start-0x7ffff780>
    csrw mie, t0
    80000038:	30429073          	csrw	mie,t0

    /* 跳转到 main */
    jal main
    8000003c:	557050ef          	jal	ra,80005d92 <main>

    /* main 不应返回 */
2:
    wfi
    80000040:	10500073          	wfi
    j 2b
    80000044:	bff5                	j	80000040 <_start+0x40>

Disassembly of section .text.freertos_risc_v_trap_handler:

0000000080000100 <freertos_risc_v_trap_handler>:
/*-----------------------------------------------------------*/

.section .text.freertos_risc_v_trap_handler
.align 8
freertos_risc_v_trap_handler:
    portcontextSAVE_CONTEXT_INTERNAL
    80000100:	f0810113          	addi	sp,sp,-248 # 8fffff08 <_heap_end+0xff08>
    80000104:	e806                	sd	ra,16(sp)
    80000106:	ec16                	sd	t0,24(sp)
    80000108:	f01a                	sd	t1,32(sp)
    8000010a:	f41e                	sd	t2,40(sp)
    8000010c:	f822                	sd	s0,48(sp)
    8000010e:	fc26                	sd	s1,56(sp)
    80000110:	e0aa                	sd	a0,64(sp)
    80000112:	e4ae                	sd	a1,72(sp)
    80000114:	e8b2                	sd	a2,80(sp)
    80000116:	ecb6                	sd	a3,88(sp)
    80000118:	f0ba                	sd	a4,96(sp)
    8000011a:	f4be                	sd	a5,104(sp)
    8000011c:	f8c2                	sd	a6,112(sp)
    8000011e:	fcc6                	sd	a7,120(sp)
    80000120:	e14a                	sd	s2,128(sp)
    80000122:	e54e                	sd	s3,136(sp)
    80000124:	e952                	sd	s4,144(sp)
    80000126:	ed56                	sd	s5,152(sp)
    80000128:	f15a                	sd	s6,160(sp)
    8000012a:	f55e                	sd	s7,168(sp)
    8000012c:	f962                	sd	s8,176(sp)
    8000012e:	fd66                	sd	s9,184(sp)
    80000130:	e1ea                	sd	s10,192(sp)
    80000132:	e5ee                	sd	s11,200(sp)
    80000134:	e9f2                	sd	t3,208(sp)
    80000136:	edf6                	sd	t4,216(sp)
    80000138:	f1fa                	sd	t5,224(sp)
    8000013a:	f5fe                	sd	t6,232(sp)
    8000013c:	00006297          	auipc	t0,0x6
    80000140:	7242b283          	ld	t0,1828(t0) # 80006860 <xCriticalNesting>
    80000144:	f996                	sd	t0,240(sp)
    80000146:	300022f3          	csrr	t0,mstatus
    8000014a:	e416                	sd	t0,8(sp)
    8000014c:	00018297          	auipc	t0,0x18
    80000150:	a042b283          	ld	t0,-1532(t0) # 80017b50 <pxCurrentTCB>
    80000154:	0022b023          	sd	sp,0(t0)

    csrr a0, mcause
    80000158:	34202573          	csrr	a0,mcause
    csrr a1, mepc
    8000015c:	341025f3          	csrr	a1,mepc

    bge a0, x0, synchronous_exception
    80000160:	00055863          	bgez	a0,80000170 <synchronous_exception>

0000000080000164 <asynchronous_interrupt>:

asynchronous_interrupt:
    store_x a1, 0( sp )                 /* Asynchronous interrupt so save unmodified exception return address. */
    80000164:	e02e                	sd	a1,0(sp)
    load_x sp, xISRStackTop             /* Switch to ISR stack. */
    80000166:	00006117          	auipc	sp,0x6
    8000016a:	6ba13103          	ld	sp,1722(sp) # 80006820 <xISRStackTop>
    j handle_interrupt
    8000016e:	a801                	j	8000017e <handle_interrupt>

0000000080000170 <synchronous_exception>:

synchronous_exception:
    addi a1, a1, 4                      /* Synchronous so update exception return address to the instruction after the instruction that generated the exeption. */
    80000170:	0591                	addi	a1,a1,4
    store_x a1, 0( sp )                 /* Save updated exception return address. */
    80000172:	e02e                	sd	a1,0(sp)
    load_x sp, xISRStackTop             /* Switch to ISR stack. */
    80000174:	00006117          	auipc	sp,0x6
    80000178:	6ac13103          	ld	sp,1708(sp) # 80006820 <xISRStackTop>
    j handle_exception
    8000017c:	a891                	j	800001d0 <handle_exception>

000000008000017e <handle_interrupt>:

handle_interrupt:
#if( portasmHAS_MTIME != 0 )

    test_if_mtimer:                     /* If there is a CLINT then the mtimer is used to generate the tick interrupt. */
        addi t0, x0, 1
    8000017e:	4285                	li	t0,1
        slli t0, t0, __riscv_xlen - 1   /* LSB is already set, shift into MSB.  Shift 31 on 32-bit or 63 on 64-bit cores. */
    80000180:	12fe                	slli	t0,t0,0x3f
        addi t1, t0, 7                  /* 0x8000[]0007 == machine timer interrupt. */
    80000182:	00728313          	addi	t1,t0,7
        bne a0, t1, application_interrupt_handler
    80000186:	04651063          	bne	a0,t1,800001c6 <application_interrupt_handler>

        portUPDATE_MTIMER_COMPARE_REGISTER
    8000018a:	00018517          	auipc	a0,0x18
    8000018e:	a2653503          	ld	a0,-1498(a0) # 80017bb0 <pullMachineTimerCompareRegister>
    80000192:	00006597          	auipc	a1,0x6
    80000196:	6d65b583          	ld	a1,1750(a1) # 80006868 <pullNextTime>
    8000019a:	0005b383          	ld	t2,0(a1)
    8000019e:	00753023          	sd	t2,0(a0)
    800001a2:	00006297          	auipc	t0,0x6
    800001a6:	6762b283          	ld	t0,1654(t0) # 80006818 <uxTimerIncrementsForOneTick>
    800001aa:	00728eb3          	add	t4,t0,t2
    800001ae:	01d5b023          	sd	t4,0(a1)
        call xTaskIncrementTick
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	41e080e7          	jalr	1054(ra) # 800015d0 <xTaskIncrementTick>
        beqz a0, processed_source       /* Don't switch context if incrementing tick didn't unblock a task. */
    800001ba:	c905                	beqz	a0,800001ea <processed_source>
        call vTaskSwitchContext
    800001bc:	00001097          	auipc	ra,0x1
    800001c0:	438080e7          	jalr	1080(ra) # 800015f4 <vTaskSwitchContext>
        j processed_source
    800001c4:	a01d                	j	800001ea <processed_source>

00000000800001c6 <application_interrupt_handler>:

#endif /* portasmHAS_MTIME */

application_interrupt_handler:
    call freertos_risc_v_application_interrupt_handler
    800001c6:	00005097          	auipc	ra,0x5
    800001ca:	592080e7          	jalr	1426(ra) # 80005758 <freertos_risc_v_application_interrupt_handler>
    j processed_source
    800001ce:	a831                	j	800001ea <processed_source>

00000000800001d0 <handle_exception>:

handle_exception:
    /* a0 contains mcause. */
    li t0, 11                                   /* 11 == environment call. */
    800001d0:	42ad                	li	t0,11
    bne a0, t0, application_exception_handler   /* Not an M environment call, so some other exception. */
    800001d2:	00551763          	bne	a0,t0,800001e0 <application_exception_handler>
    call vTaskSwitchContext
    800001d6:	00001097          	auipc	ra,0x1
    800001da:	41e080e7          	jalr	1054(ra) # 800015f4 <vTaskSwitchContext>
    j processed_source
    800001de:	a031                	j	800001ea <processed_source>

00000000800001e0 <application_exception_handler>:

application_exception_handler:
    call freertos_risc_v_application_exception_handler
    800001e0:	00005097          	auipc	ra,0x5
    800001e4:	c96080e7          	jalr	-874(ra) # 80004e76 <freertos_risc_v_application_exception_handler>
    j processed_source                  /* No other exceptions handled yet. */
    800001e8:	a009                	j	800001ea <processed_source>

00000000800001ea <processed_source>:

processed_source:
    portcontextRESTORE_CONTEXT
    800001ea:	00018317          	auipc	t1,0x18
    800001ee:	96633303          	ld	t1,-1690(t1) # 80017b50 <pxCurrentTCB>
    800001f2:	00033103          	ld	sp,0(t1)
    800001f6:	6282                	ld	t0,0(sp)
    800001f8:	34129073          	csrw	mepc,t0
    800001fc:	6e22                	ld	t3,8(sp)
    800001fe:	300e1073          	csrw	mstatus,t3
    80000202:	72ce                	ld	t0,240(sp)
    80000204:	00006317          	auipc	t1,0x6
    80000208:	65433303          	ld	t1,1620(t1) # 80006858 <pxCriticalNesting>
    8000020c:	00533023          	sd	t0,0(t1)
    80000210:	60c2                	ld	ra,16(sp)
    80000212:	62e2                	ld	t0,24(sp)
    80000214:	7302                	ld	t1,32(sp)
    80000216:	73a2                	ld	t2,40(sp)
    80000218:	7442                	ld	s0,48(sp)
    8000021a:	74e2                	ld	s1,56(sp)
    8000021c:	6506                	ld	a0,64(sp)
    8000021e:	65a6                	ld	a1,72(sp)
    80000220:	6646                	ld	a2,80(sp)
    80000222:	66e6                	ld	a3,88(sp)
    80000224:	7706                	ld	a4,96(sp)
    80000226:	77a6                	ld	a5,104(sp)
    80000228:	7846                	ld	a6,112(sp)
    8000022a:	78e6                	ld	a7,120(sp)
    8000022c:	690a                	ld	s2,128(sp)
    8000022e:	69aa                	ld	s3,136(sp)
    80000230:	6a4a                	ld	s4,144(sp)
    80000232:	6aea                	ld	s5,152(sp)
    80000234:	7b0a                	ld	s6,160(sp)
    80000236:	7baa                	ld	s7,168(sp)
    80000238:	7c4a                	ld	s8,176(sp)
    8000023a:	7cea                	ld	s9,184(sp)
    8000023c:	6d0e                	ld	s10,192(sp)
    8000023e:	6dae                	ld	s11,200(sp)
    80000240:	6e4e                	ld	t3,208(sp)
    80000242:	6eee                	ld	t4,216(sp)
    80000244:	7f0e                	ld	t5,224(sp)
    80000246:	7fae                	ld	t6,232(sp)
    80000248:	0f810113          	addi	sp,sp,248
    8000024c:	30200073          	mret
	...

Disassembly of section .text.freertos_risc_v_exception_handler:

0000000080000302 <freertos_risc_v_exception_handler>:
    portcontextSAVE_EXCEPTION_CONTEXT
    80000302:	f0810113          	addi	sp,sp,-248
    80000306:	e806                	sd	ra,16(sp)
    80000308:	ec16                	sd	t0,24(sp)
    8000030a:	f01a                	sd	t1,32(sp)
    8000030c:	f41e                	sd	t2,40(sp)
    8000030e:	f822                	sd	s0,48(sp)
    80000310:	fc26                	sd	s1,56(sp)
    80000312:	e0aa                	sd	a0,64(sp)
    80000314:	e4ae                	sd	a1,72(sp)
    80000316:	e8b2                	sd	a2,80(sp)
    80000318:	ecb6                	sd	a3,88(sp)
    8000031a:	f0ba                	sd	a4,96(sp)
    8000031c:	f4be                	sd	a5,104(sp)
    8000031e:	f8c2                	sd	a6,112(sp)
    80000320:	fcc6                	sd	a7,120(sp)
    80000322:	e14a                	sd	s2,128(sp)
    80000324:	e54e                	sd	s3,136(sp)
    80000326:	e952                	sd	s4,144(sp)
    80000328:	ed56                	sd	s5,152(sp)
    8000032a:	f15a                	sd	s6,160(sp)
    8000032c:	f55e                	sd	s7,168(sp)
    8000032e:	f962                	sd	s8,176(sp)
    80000330:	fd66                	sd	s9,184(sp)
    80000332:	e1ea                	sd	s10,192(sp)
    80000334:	e5ee                	sd	s11,200(sp)
    80000336:	e9f2                	sd	t3,208(sp)
    80000338:	edf6                	sd	t4,216(sp)
    8000033a:	f1fa                	sd	t5,224(sp)
    8000033c:	f5fe                	sd	t6,232(sp)
    8000033e:	00006297          	auipc	t0,0x6
    80000342:	5222b283          	ld	t0,1314(t0) # 80006860 <xCriticalNesting>
    80000346:	f996                	sd	t0,240(sp)
    80000348:	300022f3          	csrr	t0,mstatus
    8000034c:	e416                	sd	t0,8(sp)
    8000034e:	00018297          	auipc	t0,0x18
    80000352:	8022b283          	ld	t0,-2046(t0) # 80017b50 <pxCurrentTCB>
    80000356:	0022b023          	sd	sp,0(t0)
    8000035a:	34202573          	csrr	a0,mcause
    8000035e:	341025f3          	csrr	a1,mepc
    80000362:	0591                	addi	a1,a1,4
    80000364:	e02e                	sd	a1,0(sp)
    80000366:	00006117          	auipc	sp,0x6
    8000036a:	4ba13103          	ld	sp,1210(sp) # 80006820 <xISRStackTop>
    li t0, 11                           /* 11 == environment call. */
    8000036e:	42ad                	li	t0,11
    bne a0, t0, other_exception         /* Not an M environment call, so some other exception. */
    80000370:	06551963          	bne	a0,t0,800003e2 <other_exception>
    call vTaskSwitchContext
    80000374:	00001097          	auipc	ra,0x1
    80000378:	280080e7          	jalr	640(ra) # 800015f4 <vTaskSwitchContext>
    portcontextRESTORE_CONTEXT
    8000037c:	00017317          	auipc	t1,0x17
    80000380:	7d433303          	ld	t1,2004(t1) # 80017b50 <pxCurrentTCB>
    80000384:	00033103          	ld	sp,0(t1)
    80000388:	6282                	ld	t0,0(sp)
    8000038a:	34129073          	csrw	mepc,t0
    8000038e:	6e22                	ld	t3,8(sp)
    80000390:	300e1073          	csrw	mstatus,t3
    80000394:	72ce                	ld	t0,240(sp)
    80000396:	00006317          	auipc	t1,0x6
    8000039a:	4c233303          	ld	t1,1218(t1) # 80006858 <pxCriticalNesting>
    8000039e:	00533023          	sd	t0,0(t1)
    800003a2:	60c2                	ld	ra,16(sp)
    800003a4:	62e2                	ld	t0,24(sp)
    800003a6:	7302                	ld	t1,32(sp)
    800003a8:	73a2                	ld	t2,40(sp)
    800003aa:	7442                	ld	s0,48(sp)
    800003ac:	74e2                	ld	s1,56(sp)
    800003ae:	6506                	ld	a0,64(sp)
    800003b0:	65a6                	ld	a1,72(sp)
    800003b2:	6646                	ld	a2,80(sp)
    800003b4:	66e6                	ld	a3,88(sp)
    800003b6:	7706                	ld	a4,96(sp)
    800003b8:	77a6                	ld	a5,104(sp)
    800003ba:	7846                	ld	a6,112(sp)
    800003bc:	78e6                	ld	a7,120(sp)
    800003be:	690a                	ld	s2,128(sp)
    800003c0:	69aa                	ld	s3,136(sp)
    800003c2:	6a4a                	ld	s4,144(sp)
    800003c4:	6aea                	ld	s5,152(sp)
    800003c6:	7b0a                	ld	s6,160(sp)
    800003c8:	7baa                	ld	s7,168(sp)
    800003ca:	7c4a                	ld	s8,176(sp)
    800003cc:	7cea                	ld	s9,184(sp)
    800003ce:	6d0e                	ld	s10,192(sp)
    800003d0:	6dae                	ld	s11,200(sp)
    800003d2:	6e4e                	ld	t3,208(sp)
    800003d4:	6eee                	ld	t4,216(sp)
    800003d6:	7f0e                	ld	t5,224(sp)
    800003d8:	7fae                	ld	t6,232(sp)
    800003da:	0f810113          	addi	sp,sp,248
    800003de:	30200073          	mret

00000000800003e2 <other_exception>:
    call freertos_risc_v_application_exception_handler
    800003e2:	00005097          	auipc	ra,0x5
    800003e6:	a94080e7          	jalr	-1388(ra) # 80004e76 <freertos_risc_v_application_exception_handler>
    portcontextRESTORE_CONTEXT
    800003ea:	00017317          	auipc	t1,0x17
    800003ee:	76633303          	ld	t1,1894(t1) # 80017b50 <pxCurrentTCB>
    800003f2:	00033103          	ld	sp,0(t1)
    800003f6:	6282                	ld	t0,0(sp)
    800003f8:	34129073          	csrw	mepc,t0
    800003fc:	6e22                	ld	t3,8(sp)
    800003fe:	300e1073          	csrw	mstatus,t3
    80000402:	72ce                	ld	t0,240(sp)
    80000404:	00006317          	auipc	t1,0x6
    80000408:	45433303          	ld	t1,1108(t1) # 80006858 <pxCriticalNesting>
    8000040c:	00533023          	sd	t0,0(t1)
    80000410:	60c2                	ld	ra,16(sp)
    80000412:	62e2                	ld	t0,24(sp)
    80000414:	7302                	ld	t1,32(sp)
    80000416:	73a2                	ld	t2,40(sp)
    80000418:	7442                	ld	s0,48(sp)
    8000041a:	74e2                	ld	s1,56(sp)
    8000041c:	6506                	ld	a0,64(sp)
    8000041e:	65a6                	ld	a1,72(sp)
    80000420:	6646                	ld	a2,80(sp)
    80000422:	66e6                	ld	a3,88(sp)
    80000424:	7706                	ld	a4,96(sp)
    80000426:	77a6                	ld	a5,104(sp)
    80000428:	7846                	ld	a6,112(sp)
    8000042a:	78e6                	ld	a7,120(sp)
    8000042c:	690a                	ld	s2,128(sp)
    8000042e:	69aa                	ld	s3,136(sp)
    80000430:	6a4a                	ld	s4,144(sp)
    80000432:	6aea                	ld	s5,152(sp)
    80000434:	7b0a                	ld	s6,160(sp)
    80000436:	7baa                	ld	s7,168(sp)
    80000438:	7c4a                	ld	s8,176(sp)
    8000043a:	7cea                	ld	s9,184(sp)
    8000043c:	6d0e                	ld	s10,192(sp)
    8000043e:	6dae                	ld	s11,200(sp)
    80000440:	6e4e                	ld	t3,208(sp)
    80000442:	6eee                	ld	t4,216(sp)
    80000444:	7f0e                	ld	t5,224(sp)
    80000446:	7fae                	ld	t6,232(sp)
    80000448:	0f810113          	addi	sp,sp,248
    8000044c:	30200073          	mret

Disassembly of section .text.freertos_risc_v_interrupt_handler:

0000000080000450 <freertos_risc_v_interrupt_handler>:
    portcontextSAVE_INTERRUPT_CONTEXT
    80000450:	f0810113          	addi	sp,sp,-248
    80000454:	e806                	sd	ra,16(sp)
    80000456:	ec16                	sd	t0,24(sp)
    80000458:	f01a                	sd	t1,32(sp)
    8000045a:	f41e                	sd	t2,40(sp)
    8000045c:	f822                	sd	s0,48(sp)
    8000045e:	fc26                	sd	s1,56(sp)
    80000460:	e0aa                	sd	a0,64(sp)
    80000462:	e4ae                	sd	a1,72(sp)
    80000464:	e8b2                	sd	a2,80(sp)
    80000466:	ecb6                	sd	a3,88(sp)
    80000468:	f0ba                	sd	a4,96(sp)
    8000046a:	f4be                	sd	a5,104(sp)
    8000046c:	f8c2                	sd	a6,112(sp)
    8000046e:	fcc6                	sd	a7,120(sp)
    80000470:	e14a                	sd	s2,128(sp)
    80000472:	e54e                	sd	s3,136(sp)
    80000474:	e952                	sd	s4,144(sp)
    80000476:	ed56                	sd	s5,152(sp)
    80000478:	f15a                	sd	s6,160(sp)
    8000047a:	f55e                	sd	s7,168(sp)
    8000047c:	f962                	sd	s8,176(sp)
    8000047e:	fd66                	sd	s9,184(sp)
    80000480:	e1ea                	sd	s10,192(sp)
    80000482:	e5ee                	sd	s11,200(sp)
    80000484:	e9f2                	sd	t3,208(sp)
    80000486:	edf6                	sd	t4,216(sp)
    80000488:	f1fa                	sd	t5,224(sp)
    8000048a:	f5fe                	sd	t6,232(sp)
    8000048c:	00006297          	auipc	t0,0x6
    80000490:	3d42b283          	ld	t0,980(t0) # 80006860 <xCriticalNesting>
    80000494:	f996                	sd	t0,240(sp)
    80000496:	300022f3          	csrr	t0,mstatus
    8000049a:	e416                	sd	t0,8(sp)
    8000049c:	00017297          	auipc	t0,0x17
    800004a0:	6b42b283          	ld	t0,1716(t0) # 80017b50 <pxCurrentTCB>
    800004a4:	0022b023          	sd	sp,0(t0)
    800004a8:	34202573          	csrr	a0,mcause
    800004ac:	341025f3          	csrr	a1,mepc
    800004b0:	e02e                	sd	a1,0(sp)
    800004b2:	00006117          	auipc	sp,0x6
    800004b6:	36e13103          	ld	sp,878(sp) # 80006820 <xISRStackTop>
    call freertos_risc_v_application_interrupt_handler
    800004ba:	00005097          	auipc	ra,0x5
    800004be:	29e080e7          	jalr	670(ra) # 80005758 <freertos_risc_v_application_interrupt_handler>
    portcontextRESTORE_CONTEXT
    800004c2:	00017317          	auipc	t1,0x17
    800004c6:	68e33303          	ld	t1,1678(t1) # 80017b50 <pxCurrentTCB>
    800004ca:	00033103          	ld	sp,0(t1)
    800004ce:	6282                	ld	t0,0(sp)
    800004d0:	34129073          	csrw	mepc,t0
    800004d4:	6e22                	ld	t3,8(sp)
    800004d6:	300e1073          	csrw	mstatus,t3
    800004da:	72ce                	ld	t0,240(sp)
    800004dc:	00006317          	auipc	t1,0x6
    800004e0:	37c33303          	ld	t1,892(t1) # 80006858 <pxCriticalNesting>
    800004e4:	00533023          	sd	t0,0(t1)
    800004e8:	60c2                	ld	ra,16(sp)
    800004ea:	62e2                	ld	t0,24(sp)
    800004ec:	7302                	ld	t1,32(sp)
    800004ee:	73a2                	ld	t2,40(sp)
    800004f0:	7442                	ld	s0,48(sp)
    800004f2:	74e2                	ld	s1,56(sp)
    800004f4:	6506                	ld	a0,64(sp)
    800004f6:	65a6                	ld	a1,72(sp)
    800004f8:	6646                	ld	a2,80(sp)
    800004fa:	66e6                	ld	a3,88(sp)
    800004fc:	7706                	ld	a4,96(sp)
    800004fe:	77a6                	ld	a5,104(sp)
    80000500:	7846                	ld	a6,112(sp)
    80000502:	78e6                	ld	a7,120(sp)
    80000504:	690a                	ld	s2,128(sp)
    80000506:	69aa                	ld	s3,136(sp)
    80000508:	6a4a                	ld	s4,144(sp)
    8000050a:	6aea                	ld	s5,152(sp)
    8000050c:	7b0a                	ld	s6,160(sp)
    8000050e:	7baa                	ld	s7,168(sp)
    80000510:	7c4a                	ld	s8,176(sp)
    80000512:	7cea                	ld	s9,184(sp)
    80000514:	6d0e                	ld	s10,192(sp)
    80000516:	6dae                	ld	s11,200(sp)
    80000518:	6e4e                	ld	t3,208(sp)
    8000051a:	6eee                	ld	t4,216(sp)
    8000051c:	7f0e                	ld	t5,224(sp)
    8000051e:	7fae                	ld	t6,232(sp)
    80000520:	0f810113          	addi	sp,sp,248
    80000524:	30200073          	mret

Disassembly of section .text.freertos_risc_v_mtimer_interrupt_handler:

0000000080000528 <freertos_risc_v_mtimer_interrupt_handler>:
    portcontextSAVE_INTERRUPT_CONTEXT
    80000528:	f0810113          	addi	sp,sp,-248
    8000052c:	e806                	sd	ra,16(sp)
    8000052e:	ec16                	sd	t0,24(sp)
    80000530:	f01a                	sd	t1,32(sp)
    80000532:	f41e                	sd	t2,40(sp)
    80000534:	f822                	sd	s0,48(sp)
    80000536:	fc26                	sd	s1,56(sp)
    80000538:	e0aa                	sd	a0,64(sp)
    8000053a:	e4ae                	sd	a1,72(sp)
    8000053c:	e8b2                	sd	a2,80(sp)
    8000053e:	ecb6                	sd	a3,88(sp)
    80000540:	f0ba                	sd	a4,96(sp)
    80000542:	f4be                	sd	a5,104(sp)
    80000544:	f8c2                	sd	a6,112(sp)
    80000546:	fcc6                	sd	a7,120(sp)
    80000548:	e14a                	sd	s2,128(sp)
    8000054a:	e54e                	sd	s3,136(sp)
    8000054c:	e952                	sd	s4,144(sp)
    8000054e:	ed56                	sd	s5,152(sp)
    80000550:	f15a                	sd	s6,160(sp)
    80000552:	f55e                	sd	s7,168(sp)
    80000554:	f962                	sd	s8,176(sp)
    80000556:	fd66                	sd	s9,184(sp)
    80000558:	e1ea                	sd	s10,192(sp)
    8000055a:	e5ee                	sd	s11,200(sp)
    8000055c:	e9f2                	sd	t3,208(sp)
    8000055e:	edf6                	sd	t4,216(sp)
    80000560:	f1fa                	sd	t5,224(sp)
    80000562:	f5fe                	sd	t6,232(sp)
    80000564:	00006297          	auipc	t0,0x6
    80000568:	2fc2b283          	ld	t0,764(t0) # 80006860 <xCriticalNesting>
    8000056c:	f996                	sd	t0,240(sp)
    8000056e:	300022f3          	csrr	t0,mstatus
    80000572:	e416                	sd	t0,8(sp)
    80000574:	00017297          	auipc	t0,0x17
    80000578:	5dc2b283          	ld	t0,1500(t0) # 80017b50 <pxCurrentTCB>
    8000057c:	0022b023          	sd	sp,0(t0)
    80000580:	34202573          	csrr	a0,mcause
    80000584:	341025f3          	csrr	a1,mepc
    80000588:	e02e                	sd	a1,0(sp)
    8000058a:	00006117          	auipc	sp,0x6
    8000058e:	29613103          	ld	sp,662(sp) # 80006820 <xISRStackTop>
    portUPDATE_MTIMER_COMPARE_REGISTER
    80000592:	00017517          	auipc	a0,0x17
    80000596:	61e53503          	ld	a0,1566(a0) # 80017bb0 <pullMachineTimerCompareRegister>
    8000059a:	00006597          	auipc	a1,0x6
    8000059e:	2ce5b583          	ld	a1,718(a1) # 80006868 <pullNextTime>
    800005a2:	0005b383          	ld	t2,0(a1)
    800005a6:	00753023          	sd	t2,0(a0)
    800005aa:	00006297          	auipc	t0,0x6
    800005ae:	26e2b283          	ld	t0,622(t0) # 80006818 <uxTimerIncrementsForOneTick>
    800005b2:	00728eb3          	add	t4,t0,t2
    800005b6:	01d5b023          	sd	t4,0(a1)
    call xTaskIncrementTick
    800005ba:	00001097          	auipc	ra,0x1
    800005be:	016080e7          	jalr	22(ra) # 800015d0 <xTaskIncrementTick>
    beqz a0, exit_without_context_switch    /* Don't switch context if incrementing tick didn't unblock a task. */
    800005c2:	c509                	beqz	a0,800005cc <exit_without_context_switch>
    call vTaskSwitchContext
    800005c4:	00001097          	auipc	ra,0x1
    800005c8:	030080e7          	jalr	48(ra) # 800015f4 <vTaskSwitchContext>

00000000800005cc <exit_without_context_switch>:
    portcontextRESTORE_CONTEXT
    800005cc:	00017317          	auipc	t1,0x17
    800005d0:	58433303          	ld	t1,1412(t1) # 80017b50 <pxCurrentTCB>
    800005d4:	00033103          	ld	sp,0(t1)
    800005d8:	6282                	ld	t0,0(sp)
    800005da:	34129073          	csrw	mepc,t0
    800005de:	6e22                	ld	t3,8(sp)
    800005e0:	300e1073          	csrw	mstatus,t3
    800005e4:	72ce                	ld	t0,240(sp)
    800005e6:	00006317          	auipc	t1,0x6
    800005ea:	27233303          	ld	t1,626(t1) # 80006858 <pxCriticalNesting>
    800005ee:	00533023          	sd	t0,0(t1)
    800005f2:	60c2                	ld	ra,16(sp)
    800005f4:	62e2                	ld	t0,24(sp)
    800005f6:	7302                	ld	t1,32(sp)
    800005f8:	73a2                	ld	t2,40(sp)
    800005fa:	7442                	ld	s0,48(sp)
    800005fc:	74e2                	ld	s1,56(sp)
    800005fe:	6506                	ld	a0,64(sp)
    80000600:	65a6                	ld	a1,72(sp)
    80000602:	6646                	ld	a2,80(sp)
    80000604:	66e6                	ld	a3,88(sp)
    80000606:	7706                	ld	a4,96(sp)
    80000608:	77a6                	ld	a5,104(sp)
    8000060a:	7846                	ld	a6,112(sp)
    8000060c:	78e6                	ld	a7,120(sp)
    8000060e:	690a                	ld	s2,128(sp)
    80000610:	69aa                	ld	s3,136(sp)
    80000612:	6a4a                	ld	s4,144(sp)
    80000614:	6aea                	ld	s5,152(sp)
    80000616:	7b0a                	ld	s6,160(sp)
    80000618:	7baa                	ld	s7,168(sp)
    8000061a:	7c4a                	ld	s8,176(sp)
    8000061c:	7cea                	ld	s9,184(sp)
    8000061e:	6d0e                	ld	s10,192(sp)
    80000620:	6dae                	ld	s11,200(sp)
    80000622:	6e4e                	ld	t3,208(sp)
    80000624:	6eee                	ld	t4,216(sp)
    80000626:	7f0e                	ld	t5,224(sp)
    80000628:	7fae                	ld	t6,232(sp)
    8000062a:	0f810113          	addi	sp,sp,248
    8000062e:	30200073          	mret

Disassembly of section .text:

0000000080000632 <prvAddCurrentTaskToDelayedList>:
#endif /* if ( ( configGENERATE_RUN_TIME_STATS == 1 ) && ( INCLUDE_xTaskGetIdleTaskHandle == 1 ) ) */
/*-----------------------------------------------------------*/

static void prvAddCurrentTaskToDelayedList( TickType_t xTicksToWait,
                                            const BaseType_t xCanBlockIndefinitely )
{
    80000632:	7139                	addi	sp,sp,-64
    80000634:	f426                	sd	s1,40(sp)
    }
    #endif

    /* Remove the task from the ready list before adding it to the blocked list
     * as the same list item is used for both lists. */
    if( uxListRemove( &( pxCurrentTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    80000636:	00017497          	auipc	s1,0x17
    8000063a:	51a48493          	addi	s1,s1,1306 # 80017b50 <pxCurrentTCB>
{
    8000063e:	f04a                	sd	s2,32(sp)
    80000640:	ec4e                	sd	s3,24(sp)
    const TickType_t xConstTickCount = xTickCount;
    80000642:	00017917          	auipc	s2,0x17
    80000646:	4e693903          	ld	s2,1254(s2) # 80017b28 <xTickCount>
{
    8000064a:	e852                	sd	s4,16(sp)
    List_t * const pxDelayedList = pxDelayedTaskList;
    8000064c:	00017997          	auipc	s3,0x17
    80000650:	4fc9b983          	ld	s3,1276(s3) # 80017b48 <pxDelayedTaskList>
    List_t * const pxOverflowDelayedList = pxOverflowDelayedTaskList;
    80000654:	00017a17          	auipc	s4,0x17
    80000658:	4eca3a03          	ld	s4,1260(s4) # 80017b40 <pxOverflowDelayedTaskList>
    if( uxListRemove( &( pxCurrentTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    8000065c:	609c                	ld	a5,0(s1)
{
    8000065e:	f822                	sd	s0,48(sp)
    80000660:	842a                	mv	s0,a0
    if( uxListRemove( &( pxCurrentTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    80000662:	00878513          	addi	a0,a5,8
{
    80000666:	e456                	sd	s5,8(sp)
    80000668:	fc06                	sd	ra,56(sp)
    8000066a:	8aae                	mv	s5,a1
    if( uxListRemove( &( pxCurrentTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    8000066c:	00002097          	auipc	ra,0x2
    80000670:	fc4080e7          	jalr	-60(ra) # 80002630 <uxListRemove>
    80000674:	ed19                	bnez	a0,80000692 <prvAddCurrentTaskToDelayedList+0x60>
    {
        /* The current task must be in a ready list, so there is no need to
         * check, and the port reset macro can be called directly. */
        portRESET_READY_PRIORITY( pxCurrentTCB->uxPriority, uxTopReadyPriority );
    80000676:	609c                	ld	a5,0(s1)
    80000678:	00017717          	auipc	a4,0x17
    8000067c:	4a870713          	addi	a4,a4,1192 # 80017b20 <uxTopReadyPriority>
    80000680:	6314                	ld	a3,0(a4)
    80000682:	6fb0                	ld	a2,88(a5)
    80000684:	4785                	li	a5,1
    80000686:	00c797b3          	sll	a5,a5,a2
    8000068a:	fff7c793          	not	a5,a5
    8000068e:	8ff5                	and	a5,a5,a3
    80000690:	e31c                	sd	a5,0(a4)
        mtCOVERAGE_TEST_MARKER();
    }

    #if ( INCLUDE_vTaskSuspend == 1 )
    {
        if( ( xTicksToWait == portMAX_DELAY ) && ( xCanBlockIndefinitely != pdFALSE ) )
    80000692:	57fd                	li	a5,-1
    80000694:	04f40d63          	beq	s0,a5,800006ee <prvAddCurrentTaskToDelayedList+0xbc>
             * does not occur.  This may overflow but this doesn't matter, the
             * kernel will manage it correctly. */
            xTimeToWake = xConstTickCount + xTicksToWait;

            /* The list item will be inserted in wake time order. */
            listSET_LIST_ITEM_VALUE( &( pxCurrentTCB->xStateListItem ), xTimeToWake );
    80000698:	609c                	ld	a5,0(s1)
            xTimeToWake = xConstTickCount + xTicksToWait;
    8000069a:	944a                	add	s0,s0,s2
            if( xTimeToWake < xConstTickCount )
            {
                /* Wake time has overflowed.  Place this item in the overflow
                 * list. */
                traceMOVED_TASK_TO_OVERFLOW_DELAYED_LIST();
                vListInsert( pxOverflowDelayedList, &( pxCurrentTCB->xStateListItem ) );
    8000069c:	608c                	ld	a1,0(s1)
            listSET_LIST_ITEM_VALUE( &( pxCurrentTCB->xStateListItem ), xTimeToWake );
    8000069e:	e780                	sd	s0,8(a5)
            if( xTimeToWake < xConstTickCount )
    800006a0:	03246963          	bltu	s0,s2,800006d2 <prvAddCurrentTaskToDelayedList+0xa0>
            else
            {
                /* The wake time has not overflowed, so the current block list
                 * is used. */
                traceMOVED_TASK_TO_DELAYED_LIST();
                vListInsert( pxDelayedList, &( pxCurrentTCB->xStateListItem ) );
    800006a4:	854e                	mv	a0,s3
    800006a6:	05a1                	addi	a1,a1,8
    800006a8:	00002097          	auipc	ra,0x2
    800006ac:	f5a080e7          	jalr	-166(ra) # 80002602 <vListInsert>

                /* If the task entering the blocked state was placed at the
                 * head of the list of blocked tasks then xNextTaskUnblockTime
                 * needs to be updated too. */
                if( xTimeToWake < xNextTaskUnblockTime )
    800006b0:	00017797          	auipc	a5,0x17
    800006b4:	44078793          	addi	a5,a5,1088 # 80017af0 <xNextTaskUnblockTime>
    800006b8:	6398                	ld	a4,0(a5)
    800006ba:	00e47363          	bgeu	s0,a4,800006c0 <prvAddCurrentTaskToDelayedList+0x8e>
                {
                    xNextTaskUnblockTime = xTimeToWake;
    800006be:	e380                	sd	s0,0(a5)

        /* Avoid compiler warning when INCLUDE_vTaskSuspend is not 1. */
        ( void ) xCanBlockIndefinitely;
    }
    #endif /* INCLUDE_vTaskSuspend */
}
    800006c0:	70e2                	ld	ra,56(sp)
    800006c2:	7442                	ld	s0,48(sp)
    800006c4:	74a2                	ld	s1,40(sp)
    800006c6:	7902                	ld	s2,32(sp)
    800006c8:	69e2                	ld	s3,24(sp)
    800006ca:	6a42                	ld	s4,16(sp)
    800006cc:	6aa2                	ld	s5,8(sp)
    800006ce:	6121                	addi	sp,sp,64
    800006d0:	8082                	ret
    800006d2:	7442                	ld	s0,48(sp)
    800006d4:	70e2                	ld	ra,56(sp)
    800006d6:	74a2                	ld	s1,40(sp)
    800006d8:	7902                	ld	s2,32(sp)
    800006da:	69e2                	ld	s3,24(sp)
    800006dc:	6aa2                	ld	s5,8(sp)
                vListInsert( pxOverflowDelayedList, &( pxCurrentTCB->xStateListItem ) );
    800006de:	8552                	mv	a0,s4
}
    800006e0:	6a42                	ld	s4,16(sp)
                vListInsert( pxOverflowDelayedList, &( pxCurrentTCB->xStateListItem ) );
    800006e2:	05a1                	addi	a1,a1,8
}
    800006e4:	6121                	addi	sp,sp,64
                vListInsert( pxOverflowDelayedList, &( pxCurrentTCB->xStateListItem ) );
    800006e6:	00002317          	auipc	t1,0x2
    800006ea:	f1c30067          	jr	-228(t1) # 80002602 <vListInsert>
        if( ( xTicksToWait == portMAX_DELAY ) && ( xCanBlockIndefinitely != pdFALSE ) )
    800006ee:	fa0a85e3          	beqz	s5,80000698 <prvAddCurrentTaskToDelayedList+0x66>
            listINSERT_END( &xSuspendedTaskList, &( pxCurrentTCB->xStateListItem ) );
    800006f2:	00006797          	auipc	a5,0x6
    800006f6:	17e78793          	addi	a5,a5,382 # 80006870 <xSuspendedTaskList>
    800006fa:	6798                	ld	a4,8(a5)
    800006fc:	608c                	ld	a1,0(s1)
    800006fe:	6094                	ld	a3,0(s1)
    80000700:	6b10                	ld	a2,16(a4)
    80000702:	e998                	sd	a4,16(a1)
    80000704:	608c                	ld	a1,0(s1)
    80000706:	ee90                	sd	a2,24(a3)
    80000708:	01073803          	ld	a6,16(a4)
    8000070c:	6090                	ld	a2,0(s1)
    8000070e:	6394                	ld	a3,0(a5)
    80000710:	6088                	ld	a0,0(s1)
    80000712:	05a1                	addi	a1,a1,8
    80000714:	00b83423          	sd	a1,8(a6)
    80000718:	0621                	addi	a2,a2,8
    8000071a:	eb10                	sd	a2,16(a4)
    8000071c:	00168713          	addi	a4,a3,1
    80000720:	f51c                	sd	a5,40(a0)
    80000722:	e398                	sd	a4,0(a5)
    80000724:	bf71                	j	800006c0 <prvAddCurrentTaskToDelayedList+0x8e>

0000000080000726 <prvCheckTasksWaitingTermination>:
{
    80000726:	7179                	addi	sp,sp,-48
    80000728:	e84a                	sd	s2,16(sp)
        while( uxDeletedTasksWaitingCleanUp > ( UBaseType_t ) 0U )
    8000072a:	00017917          	auipc	s2,0x17
    8000072e:	40e90913          	addi	s2,s2,1038 # 80017b38 <uxDeletedTasksWaitingCleanUp>
    80000732:	00093783          	ld	a5,0(s2)
{
    80000736:	f406                	sd	ra,40(sp)
    80000738:	f022                	sd	s0,32(sp)
    8000073a:	ec26                	sd	s1,24(sp)
    8000073c:	e44e                	sd	s3,8(sp)
    8000073e:	e052                	sd	s4,0(sp)
        while( uxDeletedTasksWaitingCleanUp > ( UBaseType_t ) 0U )
    80000740:	cba5                	beqz	a5,800007b0 <prvCheckTasksWaitingTermination+0x8a>
    80000742:	00006417          	auipc	s0,0x6
    80000746:	11e40413          	addi	s0,s0,286 # 80006860 <xCriticalNesting>
    8000074a:	00006a17          	auipc	s4,0x6
    8000074e:	126a0a13          	addi	s4,s4,294 # 80006870 <xSuspendedTaskList>
    80000752:	00017997          	auipc	s3,0x17
    80000756:	3de98993          	addi	s3,s3,990 # 80017b30 <uxCurrentNumberOfTasks>
                taskENTER_CRITICAL();
    8000075a:	30047073          	csrci	mstatus,8
                        pxTCB = listGET_OWNER_OF_HEAD_ENTRY( ( &xTasksWaitingTermination ) );
    8000075e:	040a3703          	ld	a4,64(s4)
                taskENTER_CRITICAL();
    80000762:	601c                	ld	a5,0(s0)
                        pxTCB = listGET_OWNER_OF_HEAD_ENTRY( ( &xTasksWaitingTermination ) );
    80000764:	6f04                	ld	s1,24(a4)
                taskENTER_CRITICAL();
    80000766:	0785                	addi	a5,a5,1
    80000768:	e01c                	sd	a5,0(s0)
                        ( void ) uxListRemove( &( pxTCB->xStateListItem ) );
    8000076a:	00848513          	addi	a0,s1,8
    8000076e:	00002097          	auipc	ra,0x2
    80000772:	ec2080e7          	jalr	-318(ra) # 80002630 <uxListRemove>
                        --uxCurrentNumberOfTasks;
    80000776:	0009b703          	ld	a4,0(s3)
                taskEXIT_CRITICAL();
    8000077a:	601c                	ld	a5,0(s0)
                        --uxCurrentNumberOfTasks;
    8000077c:	177d                	addi	a4,a4,-1
    8000077e:	00e9b023          	sd	a4,0(s3)
                        --uxDeletedTasksWaitingCleanUp;
    80000782:	00093703          	ld	a4,0(s2)
                taskEXIT_CRITICAL();
    80000786:	17fd                	addi	a5,a5,-1
    80000788:	e01c                	sd	a5,0(s0)
                        --uxDeletedTasksWaitingCleanUp;
    8000078a:	177d                	addi	a4,a4,-1
    8000078c:	00e93023          	sd	a4,0(s2)
                taskEXIT_CRITICAL();
    80000790:	e399                	bnez	a5,80000796 <prvCheckTasksWaitingTermination+0x70>
    80000792:	30046073          	csrsi	mstatus,8
            vPortFreeStack( pxTCB->pxStack );
    80000796:	70a8                	ld	a0,96(s1)
    80000798:	00004097          	auipc	ra,0x4
    8000079c:	3e8080e7          	jalr	1000(ra) # 80004b80 <vPortFree>
            vPortFree( pxTCB );
    800007a0:	8526                	mv	a0,s1
    800007a2:	00004097          	auipc	ra,0x4
    800007a6:	3de080e7          	jalr	990(ra) # 80004b80 <vPortFree>
        while( uxDeletedTasksWaitingCleanUp > ( UBaseType_t ) 0U )
    800007aa:	00093783          	ld	a5,0(s2)
    800007ae:	f7d5                	bnez	a5,8000075a <prvCheckTasksWaitingTermination+0x34>
}
    800007b0:	70a2                	ld	ra,40(sp)
    800007b2:	7402                	ld	s0,32(sp)
    800007b4:	64e2                	ld	s1,24(sp)
    800007b6:	6942                	ld	s2,16(sp)
    800007b8:	69a2                	ld	s3,8(sp)
    800007ba:	6a02                	ld	s4,0(sp)
    800007bc:	6145                	addi	sp,sp,48
    800007be:	8082                	ret

00000000800007c0 <prvIdleTask>:
{
    800007c0:	1101                	addi	sp,sp,-32
    800007c2:	e822                	sd	s0,16(sp)
    800007c4:	e426                	sd	s1,8(sp)
    800007c6:	ec06                	sd	ra,24(sp)
    800007c8:	00006497          	auipc	s1,0x6
    800007cc:	0a848493          	addi	s1,s1,168 # 80006870 <xSuspendedTaskList>
            if( listCURRENT_LIST_LENGTH( &( pxReadyTasksLists[ tskIDLE_PRIORITY ] ) ) > ( UBaseType_t ) configNUMBER_OF_CORES )
    800007d0:	4405                	li	s0,1
        prvCheckTasksWaitingTermination();
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	f54080e7          	jalr	-172(ra) # 80000726 <prvCheckTasksWaitingTermination>
            if( listCURRENT_LIST_LENGTH( &( pxReadyTasksLists[ tskIDLE_PRIORITY ] ) ) > ( UBaseType_t ) configNUMBER_OF_CORES )
    800007da:	68bc                	ld	a5,80(s1)
    800007dc:	fef47be3          	bgeu	s0,a5,800007d2 <prvIdleTask+0x12>
                taskYIELD();
    800007e0:	00000073          	ecall
        prvCheckTasksWaitingTermination();
    800007e4:	00000097          	auipc	ra,0x0
    800007e8:	f42080e7          	jalr	-190(ra) # 80000726 <prvCheckTasksWaitingTermination>
            if( listCURRENT_LIST_LENGTH( &( pxReadyTasksLists[ tskIDLE_PRIORITY ] ) ) > ( UBaseType_t ) configNUMBER_OF_CORES )
    800007ec:	68bc                	ld	a5,80(s1)
    800007ee:	fef469e3          	bltu	s0,a5,800007e0 <prvIdleTask+0x20>
    800007f2:	b7c5                	j	800007d2 <prvIdleTask+0x12>

00000000800007f4 <xTaskIncrementTick.part.0>:
        const TickType_t xConstTickCount = xTickCount + ( TickType_t ) 1;
    800007f4:	00017797          	auipc	a5,0x17
    800007f8:	33478793          	addi	a5,a5,820 # 80017b28 <xTickCount>
    800007fc:	0007b303          	ld	t1,0(a5)
BaseType_t xTaskIncrementTick( void )
    80000800:	1101                	addi	sp,sp,-32
    80000802:	ec22                	sd	s0,24(sp)
    80000804:	e826                	sd	s1,16(sp)
    80000806:	e44a                	sd	s2,8(sp)
        const TickType_t xConstTickCount = xTickCount + ( TickType_t ) 1;
    80000808:	0305                	addi	t1,t1,1
        xTickCount = xConstTickCount;
    8000080a:	0067b023          	sd	t1,0(a5)
        if( xConstTickCount == ( TickType_t ) 0U )
    8000080e:	00017417          	auipc	s0,0x17
    80000812:	2e240413          	addi	s0,s0,738 # 80017af0 <xNextTaskUnblockTime>
    80000816:	04031563          	bnez	t1,80000860 <xTaskIncrementTick.part.0+0x6c>
            taskSWITCH_DELAYED_LISTS();
    8000081a:	00017797          	auipc	a5,0x17
    8000081e:	32e78793          	addi	a5,a5,814 # 80017b48 <pxDelayedTaskList>
    80000822:	6398                	ld	a4,0(a5)
    80000824:	6318                	ld	a4,0(a4)
    80000826:	c701                	beqz	a4,8000082e <xTaskIncrementTick.part.0+0x3a>
    80000828:	30047073          	csrci	mstatus,8
    8000082c:	a001                	j	8000082c <xTaskIncrementTick.part.0+0x38>
    8000082e:	00017717          	auipc	a4,0x17
    80000832:	31270713          	addi	a4,a4,786 # 80017b40 <pxOverflowDelayedTaskList>
    80000836:	6390                	ld	a2,0(a5)
    80000838:	630c                	ld	a1,0(a4)
    8000083a:	00017697          	auipc	a3,0x17
    8000083e:	2c668693          	addi	a3,a3,710 # 80017b00 <xNumOfOverflows>
    80000842:	e38c                	sd	a1,0(a5)
    80000844:	e310                	sd	a2,0(a4)
    80000846:	6298                	ld	a4,0(a3)
    80000848:	0705                	addi	a4,a4,1
    8000084a:	e298                	sd	a4,0(a3)
    if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    8000084c:	6398                	ld	a4,0(a5)
    8000084e:	6318                	ld	a4,0(a4)
    80000850:	14071863          	bnez	a4,800009a0 <xTaskIncrementTick.part.0+0x1ac>
        xNextTaskUnblockTime = portMAX_DELAY;
    80000854:	00017417          	auipc	s0,0x17
    80000858:	29c40413          	addi	s0,s0,668 # 80017af0 <xNextTaskUnblockTime>
    8000085c:	57fd                	li	a5,-1
    8000085e:	e01c                	sd	a5,0(s0)
        if( xConstTickCount >= xNextTaskUnblockTime )
    80000860:	601c                	ld	a5,0(s0)
    80000862:	0ef36663          	bltu	t1,a5,8000094e <xTaskIncrementTick.part.0+0x15a>
                if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    80000866:	00017e17          	auipc	t3,0x17
    8000086a:	2e2e0e13          	addi	t3,t3,738 # 80017b48 <pxDelayedTaskList>
    8000086e:	000e3783          	ld	a5,0(t3)
    BaseType_t xSwitchRequired = pdFALSE;
    80000872:	4501                	li	a0,0
    80000874:	00006f17          	auipc	t5,0x6
    80000878:	ffcf0f13          	addi	t5,t5,-4 # 80006870 <xSuspendedTaskList>
                if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    8000087c:	639c                	ld	a5,0(a5)
    8000087e:	00017f97          	auipc	t6,0x17
    80000882:	2d2f8f93          	addi	t6,t6,722 # 80017b50 <pxCurrentTCB>
    80000886:	10078863          	beqz	a5,80000996 <xTaskIncrementTick.part.0+0x1a2>
                    prvAddTaskToReadyList( pxTCB );
    8000088a:	00017e97          	auipc	t4,0x17
    8000088e:	296e8e93          	addi	t4,t4,662 # 80017b20 <uxTopReadyPriority>
    80000892:	4385                	li	t2,1
    80000894:	00006297          	auipc	t0,0x6
    80000898:	02c28293          	addi	t0,t0,44 # 800068c0 <pxReadyTasksLists>
    8000089c:	a059                	j	80000922 <xTaskIncrementTick.part.0+0x12e>
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    8000089e:	6290                	ld	a2,0(a3)
                    if( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) != NULL )
    800008a0:	6bb8                	ld	a4,80(a5)
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    800008a2:	0207b423          	sd	zero,40(a5)
    800008a6:	167d                	addi	a2,a2,-1
    800008a8:	e290                	sd	a2,0(a3)
                    if( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) != NULL )
    800008aa:	cf19                	beqz	a4,800008c8 <xTaskIncrementTick.part.0+0xd4>
                        listREMOVE_ITEM( &( pxTCB->xEventListItem ) );
    800008ac:	63b0                	ld	a2,64(a5)
    800008ae:	7f94                	ld	a3,56(a5)
    800008b0:	00873803          	ld	a6,8(a4)
    800008b4:	ea90                	sd	a2,16(a3)
    800008b6:	63b0                	ld	a2,64(a5)
    800008b8:	e614                	sd	a3,8(a2)
    800008ba:	0d180c63          	beq	a6,a7,80000992 <xTaskIncrementTick.part.0+0x19e>
    800008be:	6314                	ld	a3,0(a4)
    800008c0:	0407b823          	sd	zero,80(a5)
    800008c4:	16fd                	addi	a3,a3,-1
    800008c6:	e314                	sd	a3,0(a4)
                    prvAddTaskToReadyList( pxTCB );
    800008c8:	6fb4                	ld	a3,88(a5)
    800008ca:	000eb483          	ld	s1,0(t4)
    800008ce:	00269713          	slli	a4,a3,0x2
    800008d2:	9736                	add	a4,a4,a3
    800008d4:	070e                	slli	a4,a4,0x3
    800008d6:	00ef0833          	add	a6,t5,a4
    800008da:	05883603          	ld	a2,88(a6)
    800008de:	00d398b3          	sll	a7,t2,a3
    800008e2:	0098e8b3          	or	a7,a7,s1
    800008e6:	01063903          	ld	s2,16(a2)
    800008ea:	011eb023          	sd	a7,0(t4)
    800008ee:	05083883          	ld	a7,80(a6)
    800008f2:	0127bc23          	sd	s2,24(a5)
    800008f6:	01063903          	ld	s2,16(a2)
                            if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    800008fa:	000fb483          	ld	s1,0(t6)
                    prvAddTaskToReadyList( pxTCB );
    800008fe:	eb90                	sd	a2,16(a5)
    80000900:	9716                	add	a4,a4,t0
                            if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    80000902:	6ca4                	ld	s1,88(s1)
                    prvAddTaskToReadyList( pxTCB );
    80000904:	00b93423          	sd	a1,8(s2)
    80000908:	ea0c                	sd	a1,16(a2)
    8000090a:	f798                	sd	a4,40(a5)
    8000090c:	00188793          	addi	a5,a7,1
    80000910:	04f83823          	sd	a5,80(a6)
                            if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    80000914:	00d4f363          	bgeu	s1,a3,8000091a <xTaskIncrementTick.part.0+0x126>
                                xSwitchRequired = pdTRUE;
    80000918:	4505                	li	a0,1
                if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    8000091a:	000e3783          	ld	a5,0(t3)
    8000091e:	639c                	ld	a5,0(a5)
    80000920:	cbbd                	beqz	a5,80000996 <xTaskIncrementTick.part.0+0x1a2>
                    pxTCB = listGET_OWNER_OF_HEAD_ENTRY( pxDelayedTaskList );
    80000922:	000e3783          	ld	a5,0(t3)
    80000926:	6f9c                	ld	a5,24(a5)
    80000928:	6f9c                	ld	a5,24(a5)
                    xItemValue = listGET_LIST_ITEM_VALUE( &( pxTCB->xStateListItem ) );
    8000092a:	6798                	ld	a4,8(a5)
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    8000092c:	00878593          	addi	a1,a5,8
                        listREMOVE_ITEM( &( pxTCB->xEventListItem ) );
    80000930:	03078893          	addi	a7,a5,48
                    if( xConstTickCount < xItemValue )
    80000934:	06e36463          	bltu	t1,a4,8000099c <xTaskIncrementTick.part.0+0x1a8>
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80000938:	7794                	ld	a3,40(a5)
    8000093a:	6b90                	ld	a2,16(a5)
    8000093c:	6f98                	ld	a4,24(a5)
    8000093e:	0086b803          	ld	a6,8(a3)
    80000942:	ea18                	sd	a4,16(a2)
    80000944:	e710                	sd	a2,8(a4)
    80000946:	f4b81ce3          	bne	a6,a1,8000089e <xTaskIncrementTick.part.0+0xaa>
    8000094a:	e698                	sd	a4,8(a3)
    8000094c:	bf89                	j	8000089e <xTaskIncrementTick.part.0+0xaa>
    BaseType_t xSwitchRequired = pdFALSE;
    8000094e:	4501                	li	a0,0
    80000950:	00006f17          	auipc	t5,0x6
    80000954:	f20f0f13          	addi	t5,t5,-224 # 80006870 <xSuspendedTaskList>
    80000958:	00017f97          	auipc	t6,0x17
    8000095c:	1f8f8f93          	addi	t6,t6,504 # 80017b50 <pxCurrentTCB>
                if( listCURRENT_LIST_LENGTH( &( pxReadyTasksLists[ pxCurrentTCB->uxPriority ] ) ) > 1U )
    80000960:	000fb783          	ld	a5,0(t6)
    80000964:	4685                	li	a3,1
    80000966:	6fb8                	ld	a4,88(a5)
    80000968:	00271793          	slli	a5,a4,0x2
    8000096c:	97ba                	add	a5,a5,a4
    8000096e:	078e                	slli	a5,a5,0x3
    80000970:	9f3e                	add	t5,t5,a5
    80000972:	050f3783          	ld	a5,80(t5)
    80000976:	00f6f363          	bgeu	a3,a5,8000097c <xTaskIncrementTick.part.0+0x188>
                    xSwitchRequired = pdTRUE;
    8000097a:	4505                	li	a0,1
                if( xYieldPendings[ 0 ] != pdFALSE )
    8000097c:	00017797          	auipc	a5,0x17
    80000980:	18c7b783          	ld	a5,396(a5) # 80017b08 <xYieldPendings>
    80000984:	c391                	beqz	a5,80000988 <xTaskIncrementTick.part.0+0x194>
                    xSwitchRequired = pdTRUE;
    80000986:	4505                	li	a0,1
}
    80000988:	6462                	ld	s0,24(sp)
    8000098a:	64c2                	ld	s1,16(sp)
    8000098c:	6922                	ld	s2,8(sp)
    8000098e:	6105                	addi	sp,sp,32
    80000990:	8082                	ret
                        listREMOVE_ITEM( &( pxTCB->xEventListItem ) );
    80000992:	e710                	sd	a2,8(a4)
    80000994:	b72d                	j	800008be <xTaskIncrementTick.part.0+0xca>
                    xNextTaskUnblockTime = portMAX_DELAY;
    80000996:	57fd                	li	a5,-1
    80000998:	e01c                	sd	a5,0(s0)
                    break;
    8000099a:	b7d9                	j	80000960 <xTaskIncrementTick.part.0+0x16c>
                        xNextTaskUnblockTime = xItemValue;
    8000099c:	e018                	sd	a4,0(s0)
                        break;
    8000099e:	b7c9                	j	80000960 <xTaskIncrementTick.part.0+0x16c>
        xNextTaskUnblockTime = listGET_ITEM_VALUE_OF_HEAD_ENTRY( pxDelayedTaskList );
    800009a0:	639c                	ld	a5,0(a5)
    800009a2:	00017417          	auipc	s0,0x17
    800009a6:	14e40413          	addi	s0,s0,334 # 80017af0 <xNextTaskUnblockTime>
    800009aa:	6f9c                	ld	a5,24(a5)
    800009ac:	639c                	ld	a5,0(a5)
    800009ae:	e01c                	sd	a5,0(s0)
}
    800009b0:	bd45                	j	80000860 <xTaskIncrementTick.part.0+0x6c>

00000000800009b2 <xTaskResumeAll.part.0>:
BaseType_t xTaskResumeAll( void )
    800009b2:	7179                	addi	sp,sp,-48
    800009b4:	f022                	sd	s0,32(sp)
            uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended - 1U );
    800009b6:	00017417          	auipc	s0,0x17
    800009ba:	12a40413          	addi	s0,s0,298 # 80017ae0 <uxSchedulerSuspended>
    800009be:	601c                	ld	a5,0(s0)
BaseType_t xTaskResumeAll( void )
    800009c0:	f406                	sd	ra,40(sp)
    800009c2:	ec26                	sd	s1,24(sp)
            uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended - 1U );
    800009c4:	17fd                	addi	a5,a5,-1
    800009c6:	e01c                	sd	a5,0(s0)
            if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800009c8:	601c                	ld	a5,0(s0)
BaseType_t xTaskResumeAll( void )
    800009ca:	e84a                	sd	s2,16(sp)
    800009cc:	e44e                	sd	s3,8(sp)
    800009ce:	e052                	sd	s4,0(sp)
            if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800009d0:	ebed                	bnez	a5,80000ac2 <xTaskResumeAll.part.0+0x110>
                if( uxCurrentNumberOfTasks > ( UBaseType_t ) 0U )
    800009d2:	00017797          	auipc	a5,0x17
    800009d6:	15e7b783          	ld	a5,350(a5) # 80017b30 <uxCurrentNumberOfTasks>
    800009da:	c7e5                	beqz	a5,80000ac2 <xTaskResumeAll.part.0+0x110>
                    while( listLIST_IS_EMPTY( &xPendingReadyList ) == pdFALSE )
    800009dc:	00006317          	auipc	t1,0x6
    800009e0:	e9430313          	addi	t1,t1,-364 # 80006870 <xSuspendedTaskList>
    800009e4:	11833783          	ld	a5,280(t1)
    800009e8:	00017497          	auipc	s1,0x17
    800009ec:	12048493          	addi	s1,s1,288 # 80017b08 <xYieldPendings>
    800009f0:	10078c63          	beqz	a5,80000b08 <xTaskResumeAll.part.0+0x156>
    800009f4:	00017e17          	auipc	t3,0x17
    800009f8:	12ce0e13          	addi	t3,t3,300 # 80017b20 <uxTopReadyPriority>
    800009fc:	00006f97          	auipc	t6,0x6
    80000a00:	ec4f8f93          	addi	t6,t6,-316 # 800068c0 <pxReadyTasksLists>
    80000a04:	00017f17          	auipc	t5,0x17
    80000a08:	14cf0f13          	addi	t5,t5,332 # 80017b50 <pxCurrentTCB>
    80000a0c:	00017497          	auipc	s1,0x17
    80000a10:	0fc48493          	addi	s1,s1,252 # 80017b08 <xYieldPendings>
                        prvAddTaskToReadyList( pxTCB );
    80000a14:	4e85                	li	t4,1
    80000a16:	a049                	j	80000a98 <xTaskResumeAll.part.0+0xe6>
                        listREMOVE_ITEM( &( pxTCB->xEventListItem ) );
    80000a18:	6314                	ld	a3,0(a4)
    80000a1a:	0407b823          	sd	zero,80(a5)
    80000a1e:	16fd                	addi	a3,a3,-1
    80000a20:	e314                	sd	a3,0(a4)
                        listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80000a22:	778c                	ld	a1,40(a5)
    80000a24:	6b94                	ld	a3,16(a5)
    80000a26:	6f98                	ld	a4,24(a5)
    80000a28:	6590                	ld	a2,8(a1)
                        prvAddTaskToReadyList( pxTCB );
    80000a2a:	000e3283          	ld	t0,0(t3)
                        listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80000a2e:	ea98                	sd	a4,16(a3)
    80000a30:	00878813          	addi	a6,a5,8
    80000a34:	e714                	sd	a3,8(a4)
    80000a36:	0b060963          	beq	a2,a6,80000ae8 <xTaskResumeAll.part.0+0x136>
                        prvAddTaskToReadyList( pxTCB );
    80000a3a:	6fb4                	ld	a3,88(a5)
                        listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80000a3c:	0005b883          	ld	a7,0(a1)
                        prvAddTaskToReadyList( pxTCB );
    80000a40:	00269713          	slli	a4,a3,0x2
    80000a44:	9736                	add	a4,a4,a3
    80000a46:	070e                	slli	a4,a4,0x3
    80000a48:	00e30533          	add	a0,t1,a4
    80000a4c:	6d30                	ld	a2,88(a0)
                        listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80000a4e:	18fd                	addi	a7,a7,-1
    80000a50:	0115b023          	sd	a7,0(a1)
                        prvAddTaskToReadyList( pxTCB );
    80000a54:	01063883          	ld	a7,16(a2)
    80000a58:	00de95b3          	sll	a1,t4,a3
    80000a5c:	0055e5b3          	or	a1,a1,t0
    80000a60:	0117bc23          	sd	a7,24(a5)
    80000a64:	01063283          	ld	t0,16(a2)
    80000a68:	00be3023          	sd	a1,0(t3)
                            if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    80000a6c:	000f3883          	ld	a7,0(t5)
                        prvAddTaskToReadyList( pxTCB );
    80000a70:	692c                	ld	a1,80(a0)
    80000a72:	eb90                	sd	a2,16(a5)
    80000a74:	0102b423          	sd	a6,8(t0)
    80000a78:	01063823          	sd	a6,16(a2)
    80000a7c:	977e                	add	a4,a4,t6
                            if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    80000a7e:	0588b603          	ld	a2,88(a7)
                        prvAddTaskToReadyList( pxTCB );
    80000a82:	f798                	sd	a4,40(a5)
    80000a84:	00158793          	addi	a5,a1,1
    80000a88:	e93c                	sd	a5,80(a0)
                            if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    80000a8a:	00d67463          	bgeu	a2,a3,80000a92 <xTaskResumeAll.part.0+0xe0>
                                xYieldPendings[ xCoreID ] = pdTRUE;
    80000a8e:	01d4b023          	sd	t4,0(s1)
                    while( listLIST_IS_EMPTY( &xPendingReadyList ) == pdFALSE )
    80000a92:	11833783          	ld	a5,280(t1)
    80000a96:	cbb9                	beqz	a5,80000aec <xTaskResumeAll.part.0+0x13a>
                        pxTCB = listGET_OWNER_OF_HEAD_ENTRY( ( &xPendingReadyList ) );
    80000a98:	13033783          	ld	a5,304(t1)
    80000a9c:	6f9c                	ld	a5,24(a5)
                        listREMOVE_ITEM( &( pxTCB->xEventListItem ) );
    80000a9e:	6bb8                	ld	a4,80(a5)
    80000aa0:	7f90                	ld	a2,56(a5)
    80000aa2:	63b4                	ld	a3,64(a5)
    80000aa4:	6708                	ld	a0,8(a4)
    80000aa6:	03078593          	addi	a1,a5,48
    80000aaa:	ea14                	sd	a3,16(a2)
    80000aac:	e690                	sd	a2,8(a3)
    80000aae:	f6b515e3          	bne	a0,a1,80000a18 <xTaskResumeAll.part.0+0x66>
    80000ab2:	e714                	sd	a3,8(a4)
    80000ab4:	b795                	j	80000a18 <xTaskResumeAll.part.0+0x66>
                            xPendedTicks = 0;
    80000ab6:	00017797          	auipc	a5,0x17
    80000aba:	0407bd23          	sd	zero,90(a5) # 80017b10 <xPendedTicks>
                    if( xYieldPendings[ xCoreID ] != pdFALSE )
    80000abe:	609c                	ld	a5,0(s1)
    80000ac0:	e3c1                	bnez	a5,80000b40 <xTaskResumeAll.part.0+0x18e>
    BaseType_t xAlreadyYielded = pdFALSE;
    80000ac2:	4501                	li	a0,0
        taskEXIT_CRITICAL();
    80000ac4:	00006717          	auipc	a4,0x6
    80000ac8:	d9c70713          	addi	a4,a4,-612 # 80006860 <xCriticalNesting>
    80000acc:	631c                	ld	a5,0(a4)
    80000ace:	17fd                	addi	a5,a5,-1
    80000ad0:	e31c                	sd	a5,0(a4)
    80000ad2:	e399                	bnez	a5,80000ad8 <xTaskResumeAll.part.0+0x126>
    80000ad4:	30046073          	csrsi	mstatus,8
}
    80000ad8:	70a2                	ld	ra,40(sp)
    80000ada:	7402                	ld	s0,32(sp)
    80000adc:	64e2                	ld	s1,24(sp)
    80000ade:	6942                	ld	s2,16(sp)
    80000ae0:	69a2                	ld	s3,8(sp)
    80000ae2:	6a02                	ld	s4,0(sp)
    80000ae4:	6145                	addi	sp,sp,48
    80000ae6:	8082                	ret
                        listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80000ae8:	e598                	sd	a4,8(a1)
    80000aea:	bf81                	j	80000a3a <xTaskResumeAll.part.0+0x88>
    if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    80000aec:	00017797          	auipc	a5,0x17
    80000af0:	05c78793          	addi	a5,a5,92 # 80017b48 <pxDelayedTaskList>
    80000af4:	6398                	ld	a4,0(a5)
    80000af6:	6318                	ld	a4,0(a4)
    80000af8:	cf21                	beqz	a4,80000b50 <xTaskResumeAll.part.0+0x19e>
        xNextTaskUnblockTime = listGET_ITEM_VALUE_OF_HEAD_ENTRY( pxDelayedTaskList );
    80000afa:	639c                	ld	a5,0(a5)
    80000afc:	6f9c                	ld	a5,24(a5)
    80000afe:	639c                	ld	a5,0(a5)
    80000b00:	00017717          	auipc	a4,0x17
    80000b04:	fef73823          	sd	a5,-16(a4) # 80017af0 <xNextTaskUnblockTime>
                        TickType_t xPendedCounts = xPendedTicks; /* Non-volatile copy. */
    80000b08:	00017997          	auipc	s3,0x17
    80000b0c:	00898993          	addi	s3,s3,8 # 80017b10 <xPendedTicks>
    80000b10:	0009b903          	ld	s2,0(s3)
                        if( xPendedCounts > ( TickType_t ) 0U )
    80000b14:	fa0905e3          	beqz	s2,80000abe <xTaskResumeAll.part.0+0x10c>
                                    xYieldPendings[ xCoreID ] = pdTRUE;
    80000b18:	4a05                	li	s4,1
    80000b1a:	a819                	j	80000b30 <xTaskResumeAll.part.0+0x17e>
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	cd8080e7          	jalr	-808(ra) # 800007f4 <xTaskIncrementTick.part.0>
                                if( xTaskIncrementTick() != pdFALSE )
    80000b24:	c119                	beqz	a0,80000b2a <xTaskResumeAll.part.0+0x178>
                                    xYieldPendings[ xCoreID ] = pdTRUE;
    80000b26:	0144b023          	sd	s4,0(s1)
                                --xPendedCounts;
    80000b2a:	197d                	addi	s2,s2,-1
                            } while( xPendedCounts > ( TickType_t ) 0U );
    80000b2c:	f80905e3          	beqz	s2,80000ab6 <xTaskResumeAll.part.0+0x104>
    if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    80000b30:	601c                	ld	a5,0(s0)
    80000b32:	d7ed                	beqz	a5,80000b1c <xTaskResumeAll.part.0+0x16a>
        xPendedTicks += 1U;
    80000b34:	0009b783          	ld	a5,0(s3)
    80000b38:	0785                	addi	a5,a5,1
    80000b3a:	00f9b023          	sd	a5,0(s3)
    return xSwitchRequired;
    80000b3e:	b7f5                	j	80000b2a <xTaskResumeAll.part.0+0x178>
                            taskYIELD_TASK_CORE_IF_USING_PREEMPTION( pxCurrentTCB );
    80000b40:	00017797          	auipc	a5,0x17
    80000b44:	0107b783          	ld	a5,16(a5) # 80017b50 <pxCurrentTCB>
    80000b48:	00000073          	ecall
                            xAlreadyYielded = pdTRUE;
    80000b4c:	4505                	li	a0,1
    80000b4e:	bf9d                	j	80000ac4 <xTaskResumeAll.part.0+0x112>
        xNextTaskUnblockTime = portMAX_DELAY;
    80000b50:	57fd                	li	a5,-1
    80000b52:	00017717          	auipc	a4,0x17
    80000b56:	f8f73f23          	sd	a5,-98(a4) # 80017af0 <xNextTaskUnblockTime>
    80000b5a:	b77d                	j	80000b08 <xTaskResumeAll.part.0+0x156>

0000000080000b5c <xTaskCreate>:
    {
    80000b5c:	711d                	addi	sp,sp,-96
    80000b5e:	e862                	sd	s8,16(sp)
            pxStack = ( StackType_t * ) pvPortMallocStack( ( ( ( size_t ) uxStackDepth ) * sizeof( StackType_t ) ) );
    80000b60:	00361c13          	slli	s8,a2,0x3
    {
    80000b64:	f456                	sd	s5,40(sp)
    80000b66:	8aaa                	mv	s5,a0
            pxStack = ( StackType_t * ) pvPortMallocStack( ( ( ( size_t ) uxStackDepth ) * sizeof( StackType_t ) ) );
    80000b68:	8562                	mv	a0,s8
    {
    80000b6a:	e8a2                	sd	s0,80(sp)
    80000b6c:	fc4e                	sd	s3,56(sp)
    80000b6e:	f852                	sd	s4,48(sp)
    80000b70:	f05a                	sd	s6,32(sp)
    80000b72:	ec5e                	sd	s7,24(sp)
    80000b74:	ec86                	sd	ra,88(sp)
    80000b76:	e4a6                	sd	s1,72(sp)
    80000b78:	e0ca                	sd	s2,64(sp)
    80000b7a:	e466                	sd	s9,8(sp)
    80000b7c:	89b2                	mv	s3,a2
    80000b7e:	842e                	mv	s0,a1
    80000b80:	8b36                	mv	s6,a3
    80000b82:	8a3a                	mv	s4,a4
    80000b84:	8bbe                	mv	s7,a5
            pxStack = ( StackType_t * ) pvPortMallocStack( ( ( ( size_t ) uxStackDepth ) * sizeof( StackType_t ) ) );
    80000b86:	00004097          	auipc	ra,0x4
    80000b8a:	e44080e7          	jalr	-444(ra) # 800049ca <pvPortMalloc>
            if( pxStack != NULL )
    80000b8e:	c939                	beqz	a0,80000be4 <xTaskCreate+0x88>
    80000b90:	892a                	mv	s2,a0
                pxNewTCB = ( TCB_t * ) pvPortMalloc( sizeof( TCB_t ) );
    80000b92:	09000513          	li	a0,144
    80000b96:	00004097          	auipc	ra,0x4
    80000b9a:	e34080e7          	jalr	-460(ra) # 800049ca <pvPortMalloc>
    80000b9e:	84aa                	mv	s1,a0
                if( pxNewTCB != NULL )
    80000ba0:	c125                	beqz	a0,80000c00 <xTaskCreate+0xa4>
   case no work is done at all.  We detect these problems by referring
   non-existing functions.  */
__fortify_function void *
__NTH (memset (void *__dest, int __ch, size_t __len))
{
  return __builtin___memset_chk (__dest, __ch, __len,
    80000ba2:	09000613          	li	a2,144
    80000ba6:	4581                	li	a1,0
    80000ba8:	00005097          	auipc	ra,0x5
    80000bac:	c04080e7          	jalr	-1020(ra) # 800057ac <memset>
                    pxNewTCB->pxStack = pxStack;
    80000bb0:	0724b023          	sd	s2,96(s1)
    if( pcName != NULL )
    80000bb4:	c015                	beqz	s0,80000bd8 <xTaskCreate+0x7c>
    80000bb6:	85a2                	mv	a1,s0
    80000bb8:	06848813          	addi	a6,s1,104
    80000bbc:	01040793          	addi	a5,s0,16
            pxNewTCB->pcTaskName[ x ] = pcName[ x ];
    80000bc0:	0005c883          	lbu	a7,0(a1)
        for( x = ( UBaseType_t ) 0; x < ( UBaseType_t ) configMAX_TASK_NAME_LEN; x++ )
    80000bc4:	0805                	addi	a6,a6,1
    80000bc6:	0585                	addi	a1,a1,1
            pxNewTCB->pcTaskName[ x ] = pcName[ x ];
    80000bc8:	ff180fa3          	sb	a7,-1(a6)
            if( pcName[ x ] == ( char ) 0x00 )
    80000bcc:	00088463          	beqz	a7,80000bd4 <xTaskCreate+0x78>
        for( x = ( UBaseType_t ) 0; x < ( UBaseType_t ) configMAX_TASK_NAME_LEN; x++ )
    80000bd0:	feb798e3          	bne	a5,a1,80000bc0 <xTaskCreate+0x64>
        pxNewTCB->pcTaskName[ configMAX_TASK_NAME_LEN - 1U ] = '\0';
    80000bd4:	06048ba3          	sb	zero,119(s1)
    configASSERT( uxPriority < configMAX_PRIORITIES );
    80000bd8:	4791                	li	a5,4
    80000bda:	0347fa63          	bgeu	a5,s4,80000c0e <xTaskCreate+0xb2>
    80000bde:	30047073          	csrci	mstatus,8
    80000be2:	a001                	j	80000be2 <xTaskCreate+0x86>
            xReturn = errCOULD_NOT_ALLOCATE_REQUIRED_MEMORY;
    80000be4:	557d                	li	a0,-1
    }
    80000be6:	60e6                	ld	ra,88(sp)
    80000be8:	6446                	ld	s0,80(sp)
    80000bea:	64a6                	ld	s1,72(sp)
    80000bec:	6906                	ld	s2,64(sp)
    80000bee:	79e2                	ld	s3,56(sp)
    80000bf0:	7a42                	ld	s4,48(sp)
    80000bf2:	7aa2                	ld	s5,40(sp)
    80000bf4:	7b02                	ld	s6,32(sp)
    80000bf6:	6be2                	ld	s7,24(sp)
    80000bf8:	6c42                	ld	s8,16(sp)
    80000bfa:	6ca2                	ld	s9,8(sp)
    80000bfc:	6125                	addi	sp,sp,96
    80000bfe:	8082                	ret
                    vPortFreeStack( pxStack );
    80000c00:	854a                	mv	a0,s2
    80000c02:	00004097          	auipc	ra,0x4
    80000c06:	f7e080e7          	jalr	-130(ra) # 80004b80 <vPortFree>
            xReturn = errCOULD_NOT_ALLOCATE_REQUIRED_MEMORY;
    80000c0a:	557d                	li	a0,-1
    80000c0c:	bfe9                	j	80000be6 <xTaskCreate+0x8a>
    vListInitialiseItem( &( pxNewTCB->xStateListItem ) );
    80000c0e:	00848c93          	addi	s9,s1,8
    80000c12:	8566                	mv	a0,s9
    pxNewTCB->uxPriority = uxPriority;
    80000c14:	0544bc23          	sd	s4,88(s1)
        pxNewTCB->uxBasePriority = uxPriority;
    80000c18:	0744bc23          	sd	s4,120(s1)
    vListInitialiseItem( &( pxNewTCB->xStateListItem ) );
    80000c1c:	00002097          	auipc	ra,0x2
    80000c20:	9c8080e7          	jalr	-1592(ra) # 800025e4 <vListInitialiseItem>
    vListInitialiseItem( &( pxNewTCB->xEventListItem ) );
    80000c24:	03048513          	addi	a0,s1,48
    80000c28:	00002097          	auipc	ra,0x2
    80000c2c:	9bc080e7          	jalr	-1604(ra) # 800025e4 <vListInitialiseItem>
        pxTopOfStack = &( pxNewTCB->pxStack[ uxStackDepth - ( configSTACK_DEPTH_TYPE ) 1 ] );
    80000c30:	1c61                	addi	s8,s8,-8
    80000c32:	01890433          	add	s0,s2,s8
    listSET_LIST_ITEM_VALUE( &( pxNewTCB->xEventListItem ), ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) uxPriority );
    80000c36:	4795                	li	a5,5
    80000c38:	414787b3          	sub	a5,a5,s4
        pxTopOfStack = ( StackType_t * ) ( ( ( portPOINTER_SIZE_TYPE ) pxTopOfStack ) & ( ~( ( portPOINTER_SIZE_TYPE ) portBYTE_ALIGNMENT_MASK ) ) );
    80000c3c:	9841                	andi	s0,s0,-16
    listSET_LIST_ITEM_VALUE( &( pxNewTCB->xEventListItem ), ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) uxPriority );
    80000c3e:	f89c                	sd	a5,48(s1)
    listSET_LIST_ITEM_OWNER( &( pxNewTCB->xStateListItem ), pxNewTCB );
    80000c40:	f084                	sd	s1,32(s1)
    listSET_LIST_ITEM_OWNER( &( pxNewTCB->xEventListItem ), pxNewTCB );
    80000c42:	e4a4                	sd	s1,72(s1)
            pxNewTCB->pxTopOfStack = pxPortInitialiseStack( pxTopOfStack, pxTaskCode, pvParameters );
    80000c44:	865a                	mv	a2,s6
    80000c46:	85d6                	mv	a1,s5
    80000c48:	8522                	mv	a0,s0
    80000c4a:	00004097          	auipc	ra,0x4
    80000c4e:	184080e7          	jalr	388(ra) # 80004dce <pxPortInitialiseStack>
            configASSERT( ( ( portPOINTER_SIZE_TYPE ) ( pxTopOfStack - pxNewTCB->pxTopOfStack ) ) < ( ( portPOINTER_SIZE_TYPE ) uxStackDepth ) );
    80000c52:	40a407b3          	sub	a5,s0,a0
            pxNewTCB->pxTopOfStack = pxPortInitialiseStack( pxTopOfStack, pxTaskCode, pvParameters );
    80000c56:	e088                	sd	a0,0(s1)
            configASSERT( ( ( portPOINTER_SIZE_TYPE ) ( pxTopOfStack - pxNewTCB->pxTopOfStack ) ) < ( ( portPOINTER_SIZE_TYPE ) uxStackDepth ) );
    80000c58:	878d                	srai	a5,a5,0x3
    80000c5a:	0137e563          	bltu	a5,s3,80000c64 <xTaskCreate+0x108>
    80000c5e:	30047073          	csrci	mstatus,8
    80000c62:	a001                	j	80000c62 <xTaskCreate+0x106>
    if( pxCreatedTask != NULL )
    80000c64:	000b8463          	beqz	s7,80000c6c <xTaskCreate+0x110>
        *pxCreatedTask = ( TaskHandle_t ) pxNewTCB;
    80000c68:	009bb023          	sd	s1,0(s7)
        taskENTER_CRITICAL();
    80000c6c:	30047073          	csrci	mstatus,8
            uxCurrentNumberOfTasks = ( UBaseType_t ) ( uxCurrentNumberOfTasks + 1U );
    80000c70:	00017717          	auipc	a4,0x17
    80000c74:	ec070713          	addi	a4,a4,-320 # 80017b30 <uxCurrentNumberOfTasks>
    80000c78:	631c                	ld	a5,0(a4)
        taskENTER_CRITICAL();
    80000c7a:	00006417          	auipc	s0,0x6
    80000c7e:	be640413          	addi	s0,s0,-1050 # 80006860 <xCriticalNesting>
    80000c82:	6010                	ld	a2,0(s0)
            uxCurrentNumberOfTasks = ( UBaseType_t ) ( uxCurrentNumberOfTasks + 1U );
    80000c84:	0785                	addi	a5,a5,1
    80000c86:	e31c                	sd	a5,0(a4)
            if( pxCurrentTCB == NULL )
    80000c88:	00017997          	auipc	s3,0x17
    80000c8c:	ec898993          	addi	s3,s3,-312 # 80017b50 <pxCurrentTCB>
    80000c90:	0009b783          	ld	a5,0(s3)
        taskENTER_CRITICAL();
    80000c94:	00160693          	addi	a3,a2,1
    80000c98:	e014                	sd	a3,0(s0)
            if( pxCurrentTCB == NULL )
    80000c9a:	c7dd                	beqz	a5,80000d48 <xTaskCreate+0x1ec>
                if( xSchedulerRunning == pdFALSE )
    80000c9c:	00017e17          	auipc	t3,0x17
    80000ca0:	e7ce0e13          	addi	t3,t3,-388 # 80017b18 <xSchedulerRunning>
    80000ca4:	000e3783          	ld	a5,0(t3)
                    if( pxCurrentTCB->uxPriority <= pxNewTCB->uxPriority )
    80000ca8:	6cac                	ld	a1,88(s1)
    80000caa:	00006917          	auipc	s2,0x6
    80000cae:	c1690913          	addi	s2,s2,-1002 # 800068c0 <pxReadyTasksLists>
                if( xSchedulerRunning == pdFALSE )
    80000cb2:	eb81                	bnez	a5,80000cc2 <xTaskCreate+0x166>
                    if( pxCurrentTCB->uxPriority <= pxNewTCB->uxPriority )
    80000cb4:	0009b783          	ld	a5,0(s3)
    80000cb8:	6fbc                	ld	a5,88(a5)
    80000cba:	00f5e463          	bltu	a1,a5,80000cc2 <xTaskCreate+0x166>
                        pxCurrentTCB = pxNewTCB;
    80000cbe:	0099b023          	sd	s1,0(s3)
            prvAddTaskToReadyList( pxNewTCB );
    80000cc2:	00259793          	slli	a5,a1,0x2
    80000cc6:	97ae                	add	a5,a5,a1
    80000cc8:	078e                	slli	a5,a5,0x3
    80000cca:	00006717          	auipc	a4,0x6
    80000cce:	ba670713          	addi	a4,a4,-1114 # 80006870 <xSuspendedTaskList>
    80000cd2:	973e                	add	a4,a4,a5
    80000cd4:	6f34                	ld	a3,88(a4)
            uxTaskNumber++;
    80000cd6:	00017317          	auipc	t1,0x17
    80000cda:	e2230313          	addi	t1,t1,-478 # 80017af8 <uxTaskNumber>
            prvAddTaskToReadyList( pxNewTCB );
    80000cde:	00017897          	auipc	a7,0x17
    80000ce2:	e4288893          	addi	a7,a7,-446 # 80017b20 <uxTopReadyPriority>
    80000ce6:	6a88                	ld	a0,16(a3)
    80000ce8:	e894                	sd	a3,16(s1)
            uxTaskNumber++;
    80000cea:	00033803          	ld	a6,0(t1)
            prvAddTaskToReadyList( pxNewTCB );
    80000cee:	ec88                	sd	a0,24(s1)
    80000cf0:	0106bf03          	ld	t5,16(a3)
    80000cf4:	6b28                	ld	a0,80(a4)
    80000cf6:	0008be83          	ld	t4,0(a7)
    80000cfa:	019f3423          	sd	s9,8(t5)
    80000cfe:	0196b823          	sd	s9,16(a3)
    80000d02:	4685                	li	a3,1
    80000d04:	00b696b3          	sll	a3,a3,a1
    80000d08:	993e                	add	s2,s2,a5
            uxTaskNumber++;
    80000d0a:	00180593          	addi	a1,a6,1
            prvAddTaskToReadyList( pxNewTCB );
    80000d0e:	01d6e7b3          	or	a5,a3,t4
    80000d12:	0324b423          	sd	s2,40(s1)
    80000d16:	00150693          	addi	a3,a0,1
            uxTaskNumber++;
    80000d1a:	00b33023          	sd	a1,0(t1)
            prvAddTaskToReadyList( pxNewTCB );
    80000d1e:	00f8b023          	sd	a5,0(a7)
    80000d22:	eb34                	sd	a3,80(a4)
        taskEXIT_CRITICAL();
    80000d24:	e010                	sd	a2,0(s0)
    80000d26:	e219                	bnez	a2,80000d2c <xTaskCreate+0x1d0>
    80000d28:	30046073          	csrsi	mstatus,8
        if( xSchedulerRunning != pdFALSE )
    80000d2c:	000e3783          	ld	a5,0(t3)
            xReturn = pdPASS;
    80000d30:	4505                	li	a0,1
        if( xSchedulerRunning != pdFALSE )
    80000d32:	ea078ae3          	beqz	a5,80000be6 <xTaskCreate+0x8a>
            taskYIELD_ANY_CORE_IF_USING_PREEMPTION( pxNewTCB );
    80000d36:	0009b703          	ld	a4,0(s3)
    80000d3a:	6cbc                	ld	a5,88(s1)
    80000d3c:	6f38                	ld	a4,88(a4)
    80000d3e:	eaf774e3          	bgeu	a4,a5,80000be6 <xTaskCreate+0x8a>
    80000d42:	00000073          	ecall
    80000d46:	b545                	j	80000be6 <xTaskCreate+0x8a>
                pxCurrentTCB = pxNewTCB;
    80000d48:	0099b023          	sd	s1,0(s3)
                if( uxCurrentNumberOfTasks == ( UBaseType_t ) 1 )
    80000d4c:	6318                	ld	a4,0(a4)
    80000d4e:	4785                	li	a5,1
    80000d50:	00f70c63          	beq	a4,a5,80000d68 <xTaskCreate+0x20c>
                    if( pxCurrentTCB->uxPriority <= pxNewTCB->uxPriority )
    80000d54:	6cac                	ld	a1,88(s1)
    80000d56:	00006917          	auipc	s2,0x6
    80000d5a:	b6a90913          	addi	s2,s2,-1174 # 800068c0 <pxReadyTasksLists>
    80000d5e:	00017e17          	auipc	t3,0x17
    80000d62:	dbae0e13          	addi	t3,t3,-582 # 80017b18 <xSchedulerRunning>
    80000d66:	bfb1                	j	80000cc2 <xTaskCreate+0x166>
    80000d68:	00006917          	auipc	s2,0x6
    80000d6c:	b5890913          	addi	s2,s2,-1192 # 800068c0 <pxReadyTasksLists>
    80000d70:	8a4a                	mv	s4,s2
    80000d72:	00006a97          	auipc	s5,0x6
    80000d76:	c16a8a93          	addi	s5,s5,-1002 # 80006988 <xPendingReadyList>
        vListInitialise( &( pxReadyTasksLists[ uxPriority ] ) );
    80000d7a:	8552                	mv	a0,s4
    for( uxPriority = ( UBaseType_t ) 0U; uxPriority < ( UBaseType_t ) configMAX_PRIORITIES; uxPriority++ )
    80000d7c:	028a0a13          	addi	s4,s4,40
        vListInitialise( &( pxReadyTasksLists[ uxPriority ] ) );
    80000d80:	00002097          	auipc	ra,0x2
    80000d84:	850080e7          	jalr	-1968(ra) # 800025d0 <vListInitialise>
    for( uxPriority = ( UBaseType_t ) 0U; uxPriority < ( UBaseType_t ) configMAX_PRIORITIES; uxPriority++ )
    80000d88:	ff4a99e3          	bne	s5,s4,80000d7a <xTaskCreate+0x21e>
    vListInitialise( &xDelayedTaskList1 );
    80000d8c:	00006a97          	auipc	s5,0x6
    80000d90:	c24a8a93          	addi	s5,s5,-988 # 800069b0 <xDelayedTaskList1>
    80000d94:	8556                	mv	a0,s5
    80000d96:	00002097          	auipc	ra,0x2
    80000d9a:	83a080e7          	jalr	-1990(ra) # 800025d0 <vListInitialise>
    vListInitialise( &xDelayedTaskList2 );
    80000d9e:	00006a17          	auipc	s4,0x6
    80000da2:	c3aa0a13          	addi	s4,s4,-966 # 800069d8 <xDelayedTaskList2>
    80000da6:	8552                	mv	a0,s4
    80000da8:	00002097          	auipc	ra,0x2
    80000dac:	828080e7          	jalr	-2008(ra) # 800025d0 <vListInitialise>
    vListInitialise( &xPendingReadyList );
    80000db0:	00006517          	auipc	a0,0x6
    80000db4:	bd850513          	addi	a0,a0,-1064 # 80006988 <xPendingReadyList>
    80000db8:	00002097          	auipc	ra,0x2
    80000dbc:	818080e7          	jalr	-2024(ra) # 800025d0 <vListInitialise>
        vListInitialise( &xTasksWaitingTermination );
    80000dc0:	00006517          	auipc	a0,0x6
    80000dc4:	ad850513          	addi	a0,a0,-1320 # 80006898 <xTasksWaitingTermination>
    80000dc8:	00002097          	auipc	ra,0x2
    80000dcc:	808080e7          	jalr	-2040(ra) # 800025d0 <vListInitialise>
        vListInitialise( &xSuspendedTaskList );
    80000dd0:	00006517          	auipc	a0,0x6
    80000dd4:	aa050513          	addi	a0,a0,-1376 # 80006870 <xSuspendedTaskList>
    80000dd8:	00001097          	auipc	ra,0x1
    80000ddc:	7f8080e7          	jalr	2040(ra) # 800025d0 <vListInitialise>
        taskEXIT_CRITICAL();
    80000de0:	6010                	ld	a2,0(s0)
    pxDelayedTaskList = &xDelayedTaskList1;
    80000de2:	00017797          	auipc	a5,0x17
    80000de6:	d757b323          	sd	s5,-666(a5) # 80017b48 <pxDelayedTaskList>
            prvAddTaskToReadyList( pxNewTCB );
    80000dea:	6cac                	ld	a1,88(s1)
    pxOverflowDelayedTaskList = &xDelayedTaskList2;
    80000dec:	00017797          	auipc	a5,0x17
    80000df0:	d547ba23          	sd	s4,-684(a5) # 80017b40 <pxOverflowDelayedTaskList>
        taskEXIT_CRITICAL();
    80000df4:	167d                	addi	a2,a2,-1
    80000df6:	00017e17          	auipc	t3,0x17
    80000dfa:	d22e0e13          	addi	t3,t3,-734 # 80017b18 <xSchedulerRunning>
}
    80000dfe:	b5d1                	j	80000cc2 <xTaskCreate+0x166>

0000000080000e00 <vTaskDelete>:
    {
    80000e00:	7179                	addi	sp,sp,-48
    80000e02:	f406                	sd	ra,40(sp)
    80000e04:	f022                	sd	s0,32(sp)
    80000e06:	ec26                	sd	s1,24(sp)
    80000e08:	e84a                	sd	s2,16(sp)
    80000e0a:	e44e                	sd	s3,8(sp)
    80000e0c:	e052                	sd	s4,0(sp)
        taskENTER_CRITICAL();
    80000e0e:	30047073          	csrci	mstatus,8
    80000e12:	00006497          	auipc	s1,0x6
    80000e16:	a4e48493          	addi	s1,s1,-1458 # 80006860 <xCriticalNesting>
    80000e1a:	609c                	ld	a5,0(s1)
    80000e1c:	00017917          	auipc	s2,0x17
    80000e20:	d3490913          	addi	s2,s2,-716 # 80017b50 <pxCurrentTCB>
    80000e24:	842a                	mv	s0,a0
    80000e26:	0785                	addi	a5,a5,1
    80000e28:	e09c                	sd	a5,0(s1)
            pxTCB = prvGetTCBFromHandle( xTaskToDelete );
    80000e2a:	cd61                	beqz	a0,80000f02 <vTaskDelete+0x102>
            if( uxListRemove( &( pxTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    80000e2c:	00840a13          	addi	s4,s0,8
    80000e30:	8552                	mv	a0,s4
    80000e32:	00001097          	auipc	ra,0x1
    80000e36:	7fe080e7          	jalr	2046(ra) # 80002630 <uxListRemove>
    80000e3a:	e90d                	bnez	a0,80000e6c <vTaskDelete+0x6c>
                taskRESET_READY_PRIORITY( pxTCB->uxPriority );
    80000e3c:	6c34                	ld	a3,88(s0)
    80000e3e:	00006717          	auipc	a4,0x6
    80000e42:	a3270713          	addi	a4,a4,-1486 # 80006870 <xSuspendedTaskList>
    80000e46:	00269793          	slli	a5,a3,0x2
    80000e4a:	97b6                	add	a5,a5,a3
    80000e4c:	078e                	slli	a5,a5,0x3
    80000e4e:	97ba                	add	a5,a5,a4
    80000e50:	6bbc                	ld	a5,80(a5)
    80000e52:	ef89                	bnez	a5,80000e6c <vTaskDelete+0x6c>
    80000e54:	00017717          	auipc	a4,0x17
    80000e58:	ccc70713          	addi	a4,a4,-820 # 80017b20 <uxTopReadyPriority>
    80000e5c:	6310                	ld	a2,0(a4)
    80000e5e:	4785                	li	a5,1
    80000e60:	00d797b3          	sll	a5,a5,a3
    80000e64:	fff7c793          	not	a5,a5
    80000e68:	8ff1                	and	a5,a5,a2
    80000e6a:	e31c                	sd	a5,0(a4)
            if( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) != NULL )
    80000e6c:	683c                	ld	a5,80(s0)
    80000e6e:	c799                	beqz	a5,80000e7c <vTaskDelete+0x7c>
                ( void ) uxListRemove( &( pxTCB->xEventListItem ) );
    80000e70:	03040513          	addi	a0,s0,48
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	7bc080e7          	jalr	1980(ra) # 80002630 <uxListRemove>
            uxTaskNumber++;
    80000e7c:	00017717          	auipc	a4,0x17
    80000e80:	c7c70713          	addi	a4,a4,-900 # 80017af8 <uxTaskNumber>
    80000e84:	631c                	ld	a5,0(a4)
            xTaskIsRunningOrYielding = taskTASK_IS_RUNNING_OR_SCHEDULED_TO_YIELD( pxTCB );
    80000e86:	00093683          	ld	a3,0(s2)
            if( ( xSchedulerRunning != pdFALSE ) && ( xTaskIsRunningOrYielding != pdFALSE ) )
    80000e8a:	00017997          	auipc	s3,0x17
    80000e8e:	c8e98993          	addi	s3,s3,-882 # 80017b18 <xSchedulerRunning>
            uxTaskNumber++;
    80000e92:	0785                	addi	a5,a5,1
    80000e94:	e31c                	sd	a5,0(a4)
            if( ( xSchedulerRunning != pdFALSE ) && ( xTaskIsRunningOrYielding != pdFALSE ) )
    80000e96:	0009b783          	ld	a5,0(s3)
            xTaskIsRunningOrYielding = taskTASK_IS_RUNNING_OR_SCHEDULED_TO_YIELD( pxTCB );
    80000e9a:	08868263          	beq	a3,s0,80000f1e <vTaskDelete+0x11e>
                --uxCurrentNumberOfTasks;
    80000e9e:	00017717          	auipc	a4,0x17
    80000ea2:	c9270713          	addi	a4,a4,-878 # 80017b30 <uxCurrentNumberOfTasks>
    80000ea6:	631c                	ld	a5,0(a4)
    if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    80000ea8:	00017697          	auipc	a3,0x17
    80000eac:	ca068693          	addi	a3,a3,-864 # 80017b48 <pxDelayedTaskList>
                --uxCurrentNumberOfTasks;
    80000eb0:	17fd                	addi	a5,a5,-1
    80000eb2:	e31c                	sd	a5,0(a4)
    if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    80000eb4:	629c                	ld	a5,0(a3)
    80000eb6:	639c                	ld	a5,0(a5)
    80000eb8:	ebb9                	bnez	a5,80000f0e <vTaskDelete+0x10e>
        xNextTaskUnblockTime = portMAX_DELAY;
    80000eba:	57fd                	li	a5,-1
    80000ebc:	00017717          	auipc	a4,0x17
    80000ec0:	c2f73a23          	sd	a5,-972(a4) # 80017af0 <xNextTaskUnblockTime>
        taskEXIT_CRITICAL();
    80000ec4:	609c                	ld	a5,0(s1)
    80000ec6:	17fd                	addi	a5,a5,-1
    80000ec8:	e09c                	sd	a5,0(s1)
    80000eca:	e399                	bnez	a5,80000ed0 <vTaskDelete+0xd0>
    80000ecc:	30046073          	csrsi	mstatus,8
            vPortFreeStack( pxTCB->pxStack );
    80000ed0:	7028                	ld	a0,96(s0)
    80000ed2:	00004097          	auipc	ra,0x4
    80000ed6:	cae080e7          	jalr	-850(ra) # 80004b80 <vPortFree>
            vPortFree( pxTCB );
    80000eda:	8522                	mv	a0,s0
    80000edc:	00004097          	auipc	ra,0x4
    80000ee0:	ca4080e7          	jalr	-860(ra) # 80004b80 <vPortFree>
            if( xSchedulerRunning != pdFALSE )
    80000ee4:	0009b783          	ld	a5,0(s3)
    80000ee8:	c789                	beqz	a5,80000ef2 <vTaskDelete+0xf2>
                if( pxTCB == pxCurrentTCB )
    80000eea:	00093783          	ld	a5,0(s2)
    80000eee:	06878063          	beq	a5,s0,80000f4e <vTaskDelete+0x14e>
    }
    80000ef2:	70a2                	ld	ra,40(sp)
    80000ef4:	7402                	ld	s0,32(sp)
    80000ef6:	64e2                	ld	s1,24(sp)
    80000ef8:	6942                	ld	s2,16(sp)
    80000efa:	69a2                	ld	s3,8(sp)
    80000efc:	6a02                	ld	s4,0(sp)
    80000efe:	6145                	addi	sp,sp,48
    80000f00:	8082                	ret
            pxTCB = prvGetTCBFromHandle( xTaskToDelete );
    80000f02:	00093403          	ld	s0,0(s2)
            configASSERT( pxTCB != NULL );
    80000f06:	f01d                	bnez	s0,80000e2c <vTaskDelete+0x2c>
    80000f08:	30047073          	csrci	mstatus,8
    80000f0c:	a001                	j	80000f0c <vTaskDelete+0x10c>
        xNextTaskUnblockTime = listGET_ITEM_VALUE_OF_HEAD_ENTRY( pxDelayedTaskList );
    80000f0e:	629c                	ld	a5,0(a3)
    80000f10:	6f9c                	ld	a5,24(a5)
    80000f12:	639c                	ld	a5,0(a5)
    80000f14:	00017717          	auipc	a4,0x17
    80000f18:	bcf73e23          	sd	a5,-1060(a4) # 80017af0 <xNextTaskUnblockTime>
}
    80000f1c:	b765                	j	80000ec4 <vTaskDelete+0xc4>
            if( ( xSchedulerRunning != pdFALSE ) && ( xTaskIsRunningOrYielding != pdFALSE ) )
    80000f1e:	d3c1                	beqz	a5,80000e9e <vTaskDelete+0x9e>
                vListInsertEnd( &xTasksWaitingTermination, &( pxTCB->xStateListItem ) );
    80000f20:	85d2                	mv	a1,s4
    80000f22:	00006517          	auipc	a0,0x6
    80000f26:	97650513          	addi	a0,a0,-1674 # 80006898 <xTasksWaitingTermination>
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	6c0080e7          	jalr	1728(ra) # 800025ea <vListInsertEnd>
                ++uxDeletedTasksWaitingCleanUp;
    80000f32:	00017697          	auipc	a3,0x17
    80000f36:	c0668693          	addi	a3,a3,-1018 # 80017b38 <uxDeletedTasksWaitingCleanUp>
    80000f3a:	6298                	ld	a4,0(a3)
        taskEXIT_CRITICAL();
    80000f3c:	609c                	ld	a5,0(s1)
                ++uxDeletedTasksWaitingCleanUp;
    80000f3e:	0705                	addi	a4,a4,1
        taskEXIT_CRITICAL();
    80000f40:	17fd                	addi	a5,a5,-1
                ++uxDeletedTasksWaitingCleanUp;
    80000f42:	e298                	sd	a4,0(a3)
        taskEXIT_CRITICAL();
    80000f44:	e09c                	sd	a5,0(s1)
    80000f46:	ffd9                	bnez	a5,80000ee4 <vTaskDelete+0xe4>
    80000f48:	30046073          	csrsi	mstatus,8
        if( xDeleteTCBInIdleTask != pdTRUE )
    80000f4c:	bf61                	j	80000ee4 <vTaskDelete+0xe4>
                    configASSERT( uxSchedulerSuspended == 0 );
    80000f4e:	00017797          	auipc	a5,0x17
    80000f52:	b927b783          	ld	a5,-1134(a5) # 80017ae0 <uxSchedulerSuspended>
    80000f56:	c781                	beqz	a5,80000f5e <vTaskDelete+0x15e>
    80000f58:	30047073          	csrci	mstatus,8
    80000f5c:	a001                	j	80000f5c <vTaskDelete+0x15c>
                    taskYIELD_WITHIN_API();
    80000f5e:	00000073          	ecall
    }
    80000f62:	bf41                	j	80000ef2 <vTaskDelete+0xf2>

0000000080000f64 <xTaskDelayUntil>:
        configASSERT( pxPreviousWakeTime );
    80000f64:	c91d                	beqz	a0,80000f9a <xTaskDelayUntil+0x36>
        configASSERT( ( xTimeIncrement > 0U ) );
    80000f66:	c59d                	beqz	a1,80000f94 <xTaskDelayUntil+0x30>
    {
    80000f68:	1101                	addi	sp,sp,-32
    80000f6a:	e822                	sd	s0,16(sp)
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    80000f6c:	00017417          	auipc	s0,0x17
    80000f70:	b7440413          	addi	s0,s0,-1164 # 80017ae0 <uxSchedulerSuspended>
    80000f74:	601c                	ld	a5,0(s0)
    {
    80000f76:	ec06                	sd	ra,24(sp)
    80000f78:	e426                	sd	s1,8(sp)
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    80000f7a:	0785                	addi	a5,a5,1
    80000f7c:	e01c                	sd	a5,0(s0)
            const TickType_t xConstTickCount = xTickCount;
    80000f7e:	00017697          	auipc	a3,0x17
    80000f82:	baa6b683          	ld	a3,-1110(a3) # 80017b28 <xTickCount>
            configASSERT( uxSchedulerSuspended == 1U );
    80000f86:	6018                	ld	a4,0(s0)
    80000f88:	4785                	li	a5,1
    80000f8a:	00f70b63          	beq	a4,a5,80000fa0 <xTaskDelayUntil+0x3c>
    80000f8e:	30047073          	csrci	mstatus,8
    80000f92:	a001                	j	80000f92 <xTaskDelayUntil+0x2e>
        configASSERT( ( xTimeIncrement > 0U ) );
    80000f94:	30047073          	csrci	mstatus,8
    80000f98:	a001                	j	80000f98 <xTaskDelayUntil+0x34>
        configASSERT( pxPreviousWakeTime );
    80000f9a:	30047073          	csrci	mstatus,8
    80000f9e:	a001                	j	80000f9e <xTaskDelayUntil+0x3a>
            xTimeToWake = *pxPreviousWakeTime + xTimeIncrement;
    80000fa0:	6118                	ld	a4,0(a0)
    80000fa2:	00b707b3          	add	a5,a4,a1
            if( xConstTickCount < *pxPreviousWakeTime )
    80000fa6:	02e6f463          	bgeu	a3,a4,80000fce <xTaskDelayUntil+0x6a>
                if( ( xTimeToWake < *pxPreviousWakeTime ) && ( xTimeToWake > xConstTickCount ) )
    80000faa:	02e7e463          	bltu	a5,a4,80000fd2 <xTaskDelayUntil+0x6e>
            *pxPreviousWakeTime = xTimeToWake;
    80000fae:	e11c                	sd	a5,0(a0)
        BaseType_t xAlreadyYielded, xShouldDelay = pdFALSE;
    80000fb0:	4481                	li	s1,0
        taskENTER_CRITICAL();
    80000fb2:	30047073          	csrci	mstatus,8
    80000fb6:	00006717          	auipc	a4,0x6
    80000fba:	8aa70713          	addi	a4,a4,-1878 # 80006860 <xCriticalNesting>
    80000fbe:	631c                	ld	a5,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    80000fc0:	6014                	ld	a3,0(s0)
        taskENTER_CRITICAL();
    80000fc2:	0785                	addi	a5,a5,1
    80000fc4:	e31c                	sd	a5,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    80000fc6:	e295                	bnez	a3,80000fea <xTaskDelayUntil+0x86>
    80000fc8:	30047073          	csrci	mstatus,8
    80000fcc:	a001                	j	80000fcc <xTaskDelayUntil+0x68>
                if( ( xTimeToWake < *pxPreviousWakeTime ) || ( xTimeToWake > xConstTickCount ) )
    80000fce:	00e7e463          	bltu	a5,a4,80000fd6 <xTaskDelayUntil+0x72>
    80000fd2:	fcf6fee3          	bgeu	a3,a5,80000fae <xTaskDelayUntil+0x4a>
            *pxPreviousWakeTime = xTimeToWake;
    80000fd6:	e11c                	sd	a5,0(a0)
                prvAddCurrentTaskToDelayedList( xTimeToWake - xConstTickCount, pdFALSE );
    80000fd8:	4581                	li	a1,0
    80000fda:	40d78533          	sub	a0,a5,a3
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	654080e7          	jalr	1620(ra) # 80000632 <prvAddCurrentTaskToDelayedList>
    80000fe6:	4485                	li	s1,1
    80000fe8:	b7e9                	j	80000fb2 <xTaskDelayUntil+0x4e>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	9c8080e7          	jalr	-1592(ra) # 800009b2 <xTaskResumeAll.part.0>
        if( xAlreadyYielded == pdFALSE )
    80000ff2:	e119                	bnez	a0,80000ff8 <xTaskDelayUntil+0x94>
            taskYIELD_WITHIN_API();
    80000ff4:	00000073          	ecall
    }
    80000ff8:	60e2                	ld	ra,24(sp)
    80000ffa:	6442                	ld	s0,16(sp)
    80000ffc:	8526                	mv	a0,s1
    80000ffe:	64a2                	ld	s1,8(sp)
    80001000:	6105                	addi	sp,sp,32
    80001002:	8082                	ret

0000000080001004 <vTaskDelay>:
        if( xTicksToDelay > ( TickType_t ) 0U )
    80001004:	e501                	bnez	a0,8000100c <vTaskDelay+0x8>
            taskYIELD_WITHIN_API();
    80001006:	00000073          	ecall
    8000100a:	8082                	ret
    {
    8000100c:	1141                	addi	sp,sp,-16
    8000100e:	e022                	sd	s0,0(sp)
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    80001010:	00017417          	auipc	s0,0x17
    80001014:	ad040413          	addi	s0,s0,-1328 # 80017ae0 <uxSchedulerSuspended>
    80001018:	601c                	ld	a5,0(s0)
    {
    8000101a:	e406                	sd	ra,8(sp)
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    8000101c:	0785                	addi	a5,a5,1
    8000101e:	e01c                	sd	a5,0(s0)
                configASSERT( uxSchedulerSuspended == 1U );
    80001020:	6018                	ld	a4,0(s0)
    80001022:	4785                	li	a5,1
    80001024:	00f70563          	beq	a4,a5,8000102e <vTaskDelay+0x2a>
    80001028:	30047073          	csrci	mstatus,8
    8000102c:	a001                	j	8000102c <vTaskDelay+0x28>
                prvAddCurrentTaskToDelayedList( xTicksToDelay, pdFALSE );
    8000102e:	4581                	li	a1,0
    80001030:	fffff097          	auipc	ra,0xfffff
    80001034:	602080e7          	jalr	1538(ra) # 80000632 <prvAddCurrentTaskToDelayedList>
        taskENTER_CRITICAL();
    80001038:	30047073          	csrci	mstatus,8
    8000103c:	00006717          	auipc	a4,0x6
    80001040:	82470713          	addi	a4,a4,-2012 # 80006860 <xCriticalNesting>
    80001044:	631c                	ld	a5,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    80001046:	6014                	ld	a3,0(s0)
        taskENTER_CRITICAL();
    80001048:	0785                	addi	a5,a5,1
    8000104a:	e31c                	sd	a5,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    8000104c:	e681                	bnez	a3,80001054 <vTaskDelay+0x50>
    8000104e:	30047073          	csrci	mstatus,8
    80001052:	a001                	j	80001052 <vTaskDelay+0x4e>
    80001054:	00000097          	auipc	ra,0x0
    80001058:	95e080e7          	jalr	-1698(ra) # 800009b2 <xTaskResumeAll.part.0>
        if( xAlreadyYielded == pdFALSE )
    8000105c:	e119                	bnez	a0,80001062 <vTaskDelay+0x5e>
            taskYIELD_WITHIN_API();
    8000105e:	00000073          	ecall
    }
    80001062:	60a2                	ld	ra,8(sp)
    80001064:	6402                	ld	s0,0(sp)
    80001066:	0141                	addi	sp,sp,16
    80001068:	8082                	ret

000000008000106a <uxTaskPriorityGet>:
        portBASE_TYPE_ENTER_CRITICAL();
    8000106a:	30047073          	csrci	mstatus,8
    8000106e:	00005797          	auipc	a5,0x5
    80001072:	7f278793          	addi	a5,a5,2034 # 80006860 <xCriticalNesting>
    80001076:	6398                	ld	a4,0(a5)
    80001078:	00170693          	addi	a3,a4,1
    8000107c:	e394                	sd	a3,0(a5)
            pxTCB = prvGetTCBFromHandle( xTask );
    8000107e:	c519                	beqz	a0,8000108c <uxTaskPriorityGet+0x22>
        portBASE_TYPE_EXIT_CRITICAL();
    80001080:	e398                	sd	a4,0(a5)
            uxReturn = pxTCB->uxPriority;
    80001082:	6d28                	ld	a0,88(a0)
        portBASE_TYPE_EXIT_CRITICAL();
    80001084:	e319                	bnez	a4,8000108a <uxTaskPriorityGet+0x20>
    80001086:	30046073          	csrsi	mstatus,8
    }
    8000108a:	8082                	ret
            pxTCB = prvGetTCBFromHandle( xTask );
    8000108c:	00017517          	auipc	a0,0x17
    80001090:	ac453503          	ld	a0,-1340(a0) # 80017b50 <pxCurrentTCB>
            configASSERT( pxTCB != NULL );
    80001094:	f575                	bnez	a0,80001080 <uxTaskPriorityGet+0x16>
    80001096:	30047073          	csrci	mstatus,8
    8000109a:	a001                	j	8000109a <uxTaskPriorityGet+0x30>

000000008000109c <uxTaskPriorityGetFromISR>:
            pxTCB = prvGetTCBFromHandle( xTask );
    8000109c:	c119                	beqz	a0,800010a2 <uxTaskPriorityGetFromISR+0x6>
    }
    8000109e:	6d28                	ld	a0,88(a0)
    800010a0:	8082                	ret
            pxTCB = prvGetTCBFromHandle( xTask );
    800010a2:	00017517          	auipc	a0,0x17
    800010a6:	aae53503          	ld	a0,-1362(a0) # 80017b50 <pxCurrentTCB>
            configASSERT( pxTCB != NULL );
    800010aa:	f975                	bnez	a0,8000109e <uxTaskPriorityGetFromISR+0x2>
    800010ac:	30047073          	csrci	mstatus,8
    800010b0:	a001                	j	800010b0 <uxTaskPriorityGetFromISR+0x14>

00000000800010b2 <uxTaskBasePriorityGet>:
        portBASE_TYPE_ENTER_CRITICAL();
    800010b2:	30047073          	csrci	mstatus,8
    800010b6:	00005797          	auipc	a5,0x5
    800010ba:	7aa78793          	addi	a5,a5,1962 # 80006860 <xCriticalNesting>
    800010be:	6398                	ld	a4,0(a5)
    800010c0:	00170693          	addi	a3,a4,1
    800010c4:	e394                	sd	a3,0(a5)
            pxTCB = prvGetTCBFromHandle( xTask );
    800010c6:	c519                	beqz	a0,800010d4 <uxTaskBasePriorityGet+0x22>
        portBASE_TYPE_EXIT_CRITICAL();
    800010c8:	e398                	sd	a4,0(a5)
            uxReturn = pxTCB->uxBasePriority;
    800010ca:	7d28                	ld	a0,120(a0)
        portBASE_TYPE_EXIT_CRITICAL();
    800010cc:	e319                	bnez	a4,800010d2 <uxTaskBasePriorityGet+0x20>
    800010ce:	30046073          	csrsi	mstatus,8
    }
    800010d2:	8082                	ret
            pxTCB = prvGetTCBFromHandle( xTask );
    800010d4:	00017517          	auipc	a0,0x17
    800010d8:	a7c53503          	ld	a0,-1412(a0) # 80017b50 <pxCurrentTCB>
            configASSERT( pxTCB != NULL );
    800010dc:	f575                	bnez	a0,800010c8 <uxTaskBasePriorityGet+0x16>
    800010de:	30047073          	csrci	mstatus,8
    800010e2:	a001                	j	800010e2 <uxTaskBasePriorityGet+0x30>

00000000800010e4 <uxTaskBasePriorityGetFromISR>:
            pxTCB = prvGetTCBFromHandle( xTask );
    800010e4:	c119                	beqz	a0,800010ea <uxTaskBasePriorityGetFromISR+0x6>
    }
    800010e6:	7d28                	ld	a0,120(a0)
    800010e8:	8082                	ret
            pxTCB = prvGetTCBFromHandle( xTask );
    800010ea:	00017517          	auipc	a0,0x17
    800010ee:	a6653503          	ld	a0,-1434(a0) # 80017b50 <pxCurrentTCB>
            configASSERT( pxTCB != NULL );
    800010f2:	f975                	bnez	a0,800010e6 <uxTaskBasePriorityGetFromISR+0x2>
    800010f4:	30047073          	csrci	mstatus,8
    800010f8:	a001                	j	800010f8 <uxTaskBasePriorityGetFromISR+0x14>

00000000800010fa <vTaskPrioritySet>:
        configASSERT( uxNewPriority < configMAX_PRIORITIES );
    800010fa:	4791                	li	a5,4
    800010fc:	00b7f563          	bgeu	a5,a1,80001106 <vTaskPrioritySet+0xc>
    80001100:	30047073          	csrci	mstatus,8
    80001104:	a001                	j	80001104 <vTaskPrioritySet+0xa>
    {
    80001106:	7139                	addi	sp,sp,-64
    80001108:	f822                	sd	s0,48(sp)
    8000110a:	fc06                	sd	ra,56(sp)
    8000110c:	f426                	sd	s1,40(sp)
    8000110e:	f04a                	sd	s2,32(sp)
    80001110:	ec4e                	sd	s3,24(sp)
    80001112:	e852                	sd	s4,16(sp)
    80001114:	e456                	sd	s5,8(sp)
    80001116:	842a                	mv	s0,a0
        taskENTER_CRITICAL();
    80001118:	30047073          	csrci	mstatus,8
    8000111c:	00005497          	auipc	s1,0x5
    80001120:	74448493          	addi	s1,s1,1860 # 80006860 <xCriticalNesting>
    80001124:	609c                	ld	a5,0(s1)
    80001126:	00178713          	addi	a4,a5,1
    8000112a:	e098                	sd	a4,0(s1)
            pxTCB = prvGetTCBFromHandle( xTask );
    8000112c:	c93d                	beqz	a0,800011a2 <vTaskPrioritySet+0xa8>
                uxCurrentBasePriority = pxTCB->uxBasePriority;
    8000112e:	7c38                	ld	a4,120(s0)
            if( uxCurrentBasePriority != uxNewPriority )
    80001130:	04e58c63          	beq	a1,a4,80001188 <vTaskPrioritySet+0x8e>
                if( uxNewPriority > uxCurrentBasePriority )
    80001134:	06b76f63          	bltu	a4,a1,800011b2 <vTaskPrioritySet+0xb8>
                else if( taskTASK_IS_RUNNING( pxTCB ) == pdTRUE )
    80001138:	00017997          	auipc	s3,0x17
    8000113c:	a189b983          	ld	s3,-1512(s3) # 80017b50 <pxCurrentTCB>
    80001140:	408989b3          	sub	s3,s3,s0
    80001144:	0019b993          	seqz	s3,s3
                uxPriorityUsedOnEntry = pxTCB->uxPriority;
    80001148:	05843903          	ld	s2,88(s0)
                    if( ( pxTCB->uxBasePriority == pxTCB->uxPriority ) || ( uxNewPriority > pxTCB->uxPriority ) )
    8000114c:	09270163          	beq	a4,s2,800011ce <vTaskPrioritySet+0xd4>
    80001150:	06b96f63          	bltu	s2,a1,800011ce <vTaskPrioritySet+0xd4>
                if( ( listGET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ) ) & taskEVENT_LIST_ITEM_VALUE_IN_USE ) == ( ( TickType_t ) 0U ) )
    80001154:	781c                	ld	a5,48(s0)
                    pxTCB->uxBasePriority = uxNewPriority;
    80001156:	fc2c                	sd	a1,120(s0)
                if( ( listGET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ) ) & taskEVENT_LIST_ITEM_VALUE_IN_USE ) == ( ( TickType_t ) 0U ) )
    80001158:	01f7d79b          	srliw	a5,a5,0x1f
    8000115c:	e781                	bnez	a5,80001164 <vTaskPrioritySet+0x6a>
                    listSET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ), ( ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) uxNewPriority ) );
    8000115e:	4795                	li	a5,5
    80001160:	8f8d                	sub	a5,a5,a1
    80001162:	f81c                	sd	a5,48(s0)
                if( listIS_CONTAINED_WITHIN( &( pxReadyTasksLists[ uxPriorityUsedOnEntry ] ), &( pxTCB->xStateListItem ) ) != pdFALSE )
    80001164:	00291793          	slli	a5,s2,0x2
    80001168:	97ca                	add	a5,a5,s2
    8000116a:	7418                	ld	a4,40(s0)
    8000116c:	00005a17          	auipc	s4,0x5
    80001170:	754a0a13          	addi	s4,s4,1876 # 800068c0 <pxReadyTasksLists>
    80001174:	078e                	slli	a5,a5,0x3
    80001176:	97d2                	add	a5,a5,s4
    80001178:	04f70d63          	beq	a4,a5,800011d2 <vTaskPrioritySet+0xd8>
                if( xYieldRequired != pdFALSE )
    8000117c:	00098463          	beqz	s3,80001184 <vTaskPrioritySet+0x8a>
                    taskYIELD_TASK_CORE_IF_USING_PREEMPTION( pxTCB );
    80001180:	00000073          	ecall
        taskEXIT_CRITICAL();
    80001184:	609c                	ld	a5,0(s1)
    80001186:	17fd                	addi	a5,a5,-1
    80001188:	e09c                	sd	a5,0(s1)
    8000118a:	e399                	bnez	a5,80001190 <vTaskPrioritySet+0x96>
    8000118c:	30046073          	csrsi	mstatus,8
    }
    80001190:	70e2                	ld	ra,56(sp)
    80001192:	7442                	ld	s0,48(sp)
    80001194:	74a2                	ld	s1,40(sp)
    80001196:	7902                	ld	s2,32(sp)
    80001198:	69e2                	ld	s3,24(sp)
    8000119a:	6a42                	ld	s4,16(sp)
    8000119c:	6aa2                	ld	s5,8(sp)
    8000119e:	6121                	addi	sp,sp,64
    800011a0:	8082                	ret
            pxTCB = prvGetTCBFromHandle( xTask );
    800011a2:	00017417          	auipc	s0,0x17
    800011a6:	9ae43403          	ld	s0,-1618(s0) # 80017b50 <pxCurrentTCB>
            configASSERT( pxTCB != NULL );
    800011aa:	f051                	bnez	s0,8000112e <vTaskPrioritySet+0x34>
    800011ac:	30047073          	csrci	mstatus,8
    800011b0:	a001                	j	800011b0 <vTaskPrioritySet+0xb6>
                        if( pxTCB != pxCurrentTCB )
    800011b2:	00017797          	auipc	a5,0x17
    800011b6:	99e78793          	addi	a5,a5,-1634 # 80017b50 <pxCurrentTCB>
    800011ba:	6394                	ld	a3,0(a5)
        BaseType_t xYieldRequired = pdFALSE;
    800011bc:	4981                	li	s3,0
                        if( pxTCB != pxCurrentTCB )
    800011be:	f88685e3          	beq	a3,s0,80001148 <vTaskPrioritySet+0x4e>
                            if( uxNewPriority > pxCurrentTCB->uxPriority )
    800011c2:	639c                	ld	a5,0(a5)
    800011c4:	0587b983          	ld	s3,88(a5)
    800011c8:	00b9b9b3          	sltu	s3,s3,a1
    800011cc:	bfb5                	j	80001148 <vTaskPrioritySet+0x4e>
                        pxTCB->uxPriority = uxNewPriority;
    800011ce:	ec2c                	sd	a1,88(s0)
    800011d0:	b751                	j	80001154 <vTaskPrioritySet+0x5a>
                    if( uxListRemove( &( pxTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    800011d2:	00840a93          	addi	s5,s0,8
    800011d6:	8556                	mv	a0,s5
    800011d8:	00001097          	auipc	ra,0x1
    800011dc:	458080e7          	jalr	1112(ra) # 80002630 <uxListRemove>
    800011e0:	00017617          	auipc	a2,0x17
    800011e4:	94060613          	addi	a2,a2,-1728 # 80017b20 <uxTopReadyPriority>
    800011e8:	e909                	bnez	a0,800011fa <vTaskPrioritySet+0x100>
                        portRESET_READY_PRIORITY( uxPriorityUsedOnEntry, uxTopReadyPriority );
    800011ea:	6218                	ld	a4,0(a2)
    800011ec:	4785                	li	a5,1
    800011ee:	012797b3          	sll	a5,a5,s2
    800011f2:	fff7c793          	not	a5,a5
    800011f6:	8ff9                	and	a5,a5,a4
    800011f8:	e21c                	sd	a5,0(a2)
                    prvAddTaskToReadyList( pxTCB );
    800011fa:	05843803          	ld	a6,88(s0)
    800011fe:	00005717          	auipc	a4,0x5
    80001202:	67270713          	addi	a4,a4,1650 # 80006870 <xSuspendedTaskList>
    80001206:	4685                	li	a3,1
    80001208:	00281793          	slli	a5,a6,0x2
    8000120c:	97c2                	add	a5,a5,a6
    8000120e:	078e                	slli	a5,a5,0x3
    80001210:	973e                	add	a4,a4,a5
    80001212:	6f2c                	ld	a1,88(a4)
    80001214:	6b28                	ld	a0,80(a4)
    80001216:	010696b3          	sll	a3,a3,a6
    8000121a:	0105b303          	ld	t1,16(a1)
    8000121e:	00063883          	ld	a7,0(a2)
    80001222:	e80c                	sd	a1,16(s0)
    80001224:	00643c23          	sd	t1,24(s0)
    80001228:	0105b803          	ld	a6,16(a1)
    8000122c:	9a3e                	add	s4,s4,a5
    8000122e:	0116e7b3          	or	a5,a3,a7
    80001232:	01583423          	sd	s5,8(a6)
    80001236:	0155b823          	sd	s5,16(a1)
    8000123a:	03443423          	sd	s4,40(s0)
    8000123e:	00150693          	addi	a3,a0,1
    80001242:	e21c                	sd	a5,0(a2)
    80001244:	eb34                	sd	a3,80(a4)
    80001246:	bf1d                	j	8000117c <vTaskPrioritySet+0x82>

0000000080001248 <vTaskResume>:
        configASSERT( xTaskToResume );
    80001248:	c13d                	beqz	a0,800012ae <vTaskResume+0x66>
    {
    8000124a:	7139                	addi	sp,sp,-64
    8000124c:	f426                	sd	s1,40(sp)
            if( ( pxTCB != pxCurrentTCB ) && ( pxTCB != NULL ) )
    8000124e:	00017497          	auipc	s1,0x17
    80001252:	90248493          	addi	s1,s1,-1790 # 80017b50 <pxCurrentTCB>
    80001256:	609c                	ld	a5,0(s1)
    {
    80001258:	f822                	sd	s0,48(sp)
    8000125a:	fc06                	sd	ra,56(sp)
    8000125c:	f04a                	sd	s2,32(sp)
    8000125e:	ec4e                	sd	s3,24(sp)
    80001260:	e852                	sd	s4,16(sp)
    80001262:	e456                	sd	s5,8(sp)
    80001264:	842a                	mv	s0,a0
            if( ( pxTCB != pxCurrentTCB ) && ( pxTCB != NULL ) )
    80001266:	02a78b63          	beq	a5,a0,8000129c <vTaskResume+0x54>
            taskENTER_CRITICAL();
    8000126a:	30047073          	csrci	mstatus,8
    8000126e:	00005917          	auipc	s2,0x5
    80001272:	5f290913          	addi	s2,s2,1522 # 80006860 <xCriticalNesting>
    80001276:	00093783          	ld	a5,0(s2)
        if( listIS_CONTAINED_WITHIN( &xSuspendedTaskList, &( pxTCB->xStateListItem ) ) != pdFALSE )
    8000127a:	02853983          	ld	s3,40(a0)
    8000127e:	00005717          	auipc	a4,0x5
    80001282:	5f270713          	addi	a4,a4,1522 # 80006870 <xSuspendedTaskList>
            taskENTER_CRITICAL();
    80001286:	00178693          	addi	a3,a5,1
    8000128a:	00d93023          	sd	a3,0(s2)
        if( listIS_CONTAINED_WITHIN( &xSuspendedTaskList, &( pxTCB->xStateListItem ) ) != pdFALSE )
    8000128e:	02e98363          	beq	s3,a4,800012b4 <vTaskResume+0x6c>
            taskEXIT_CRITICAL();
    80001292:	00f93023          	sd	a5,0(s2)
    80001296:	e399                	bnez	a5,8000129c <vTaskResume+0x54>
    80001298:	30046073          	csrsi	mstatus,8
    }
    8000129c:	70e2                	ld	ra,56(sp)
    8000129e:	7442                	ld	s0,48(sp)
    800012a0:	74a2                	ld	s1,40(sp)
    800012a2:	7902                	ld	s2,32(sp)
    800012a4:	69e2                	ld	s3,24(sp)
    800012a6:	6a42                	ld	s4,16(sp)
    800012a8:	6aa2                	ld	s5,8(sp)
    800012aa:	6121                	addi	sp,sp,64
    800012ac:	8082                	ret
        configASSERT( xTaskToResume );
    800012ae:	30047073          	csrci	mstatus,8
    800012b2:	a001                	j	800012b2 <vTaskResume+0x6a>
            if( listIS_CONTAINED_WITHIN( &xPendingReadyList, &( pxTCB->xEventListItem ) ) == pdFALSE )
    800012b4:	6938                	ld	a4,80(a0)
    800012b6:	00005697          	auipc	a3,0x5
    800012ba:	6d268693          	addi	a3,a3,1746 # 80006988 <xPendingReadyList>
    800012be:	fcd70ae3          	beq	a4,a3,80001292 <vTaskResume+0x4a>
                if( listIS_CONTAINED_WITHIN( NULL, &( pxTCB->xEventListItem ) ) != pdFALSE )
    800012c2:	fb61                	bnez	a4,80001292 <vTaskResume+0x4a>
                            if( pxTCB->ucNotifyState[ x ] == taskWAITING_NOTIFICATION )
    800012c4:	08c54703          	lbu	a4,140(a0)
    800012c8:	4a05                	li	s4,1
    800012ca:	fd4704e3          	beq	a4,s4,80001292 <vTaskResume+0x4a>
                    ( void ) uxListRemove( &( pxTCB->xStateListItem ) );
    800012ce:	00850a93          	addi	s5,a0,8
    800012d2:	8556                	mv	a0,s5
    800012d4:	00001097          	auipc	ra,0x1
    800012d8:	35c080e7          	jalr	860(ra) # 80002630 <uxListRemove>
                    prvAddTaskToReadyList( pxTCB );
    800012dc:	6c34                	ld	a3,88(s0)
    800012de:	00017597          	auipc	a1,0x17
    800012e2:	84258593          	addi	a1,a1,-1982 # 80017b20 <uxTopReadyPriority>
    800012e6:	6188                	ld	a0,0(a1)
    800012e8:	00269793          	slli	a5,a3,0x2
    800012ec:	97b6                	add	a5,a5,a3
    800012ee:	078e                	slli	a5,a5,0x3
    800012f0:	99be                	add	s3,s3,a5
    800012f2:	0589b603          	ld	a2,88(s3)
    800012f6:	00da1733          	sll	a4,s4,a3
    800012fa:	8f49                	or	a4,a4,a0
    800012fc:	6a08                	ld	a0,16(a2)
    800012fe:	e198                	sd	a4,0(a1)
                    taskYIELD_ANY_CORE_IF_USING_PREEMPTION( pxTCB );
    80001300:	608c                	ld	a1,0(s1)
                    prvAddTaskToReadyList( pxTCB );
    80001302:	ec08                	sd	a0,24(s0)
    80001304:	6a08                	ld	a0,16(a2)
    80001306:	e810                	sd	a2,16(s0)
    80001308:	0509b703          	ld	a4,80(s3)
    8000130c:	01553423          	sd	s5,8(a0)
    80001310:	01563823          	sd	s5,16(a2)
    80001314:	00005617          	auipc	a2,0x5
    80001318:	5ac60613          	addi	a2,a2,1452 # 800068c0 <pxReadyTasksLists>
    8000131c:	97b2                	add	a5,a5,a2
                    taskYIELD_ANY_CORE_IF_USING_PREEMPTION( pxTCB );
    8000131e:	6db0                	ld	a2,88(a1)
                    prvAddTaskToReadyList( pxTCB );
    80001320:	f41c                	sd	a5,40(s0)
    80001322:	00170793          	addi	a5,a4,1
    80001326:	04f9b823          	sd	a5,80(s3)
                    taskYIELD_ANY_CORE_IF_USING_PREEMPTION( pxTCB );
    8000132a:	00d67463          	bgeu	a2,a3,80001332 <vTaskResume+0xea>
    8000132e:	00000073          	ecall
            taskEXIT_CRITICAL();
    80001332:	00093783          	ld	a5,0(s2)
    80001336:	17fd                	addi	a5,a5,-1
    80001338:	bfa9                	j	80001292 <vTaskResume+0x4a>

000000008000133a <xTaskResumeFromISR>:
        configASSERT( xTaskToResume );
    8000133a:	c905                	beqz	a0,8000136a <xTaskResumeFromISR+0x30>
        if( listIS_CONTAINED_WITHIN( &xSuspendedTaskList, &( pxTCB->xStateListItem ) ) != pdFALSE )
    8000133c:	751c                	ld	a5,40(a0)
    {
    8000133e:	7179                	addi	sp,sp,-48
    80001340:	f022                	sd	s0,32(sp)
    80001342:	ec26                	sd	s1,24(sp)
    80001344:	e84a                	sd	s2,16(sp)
    80001346:	f406                	sd	ra,40(sp)
    80001348:	e44e                	sd	s3,8(sp)
        if( listIS_CONTAINED_WITHIN( &xSuspendedTaskList, &( pxTCB->xStateListItem ) ) != pdFALSE )
    8000134a:	00005497          	auipc	s1,0x5
    8000134e:	52648493          	addi	s1,s1,1318 # 80006870 <xSuspendedTaskList>
    80001352:	842a                	mv	s0,a0
        BaseType_t xYieldRequired = pdFALSE;
    80001354:	4901                	li	s2,0
        if( listIS_CONTAINED_WITHIN( &xSuspendedTaskList, &( pxTCB->xStateListItem ) ) != pdFALSE )
    80001356:	00978d63          	beq	a5,s1,80001370 <xTaskResumeFromISR+0x36>
    }
    8000135a:	70a2                	ld	ra,40(sp)
    8000135c:	7402                	ld	s0,32(sp)
    8000135e:	64e2                	ld	s1,24(sp)
    80001360:	69a2                	ld	s3,8(sp)
    80001362:	854a                	mv	a0,s2
    80001364:	6942                	ld	s2,16(sp)
    80001366:	6145                	addi	sp,sp,48
    80001368:	8082                	ret
        configASSERT( xTaskToResume );
    8000136a:	30047073          	csrci	mstatus,8
    8000136e:	a001                	j	8000136e <xTaskResumeFromISR+0x34>
            if( listIS_CONTAINED_WITHIN( &xPendingReadyList, &( pxTCB->xEventListItem ) ) == pdFALSE )
    80001370:	693c                	ld	a5,80(a0)
    80001372:	00005517          	auipc	a0,0x5
    80001376:	61650513          	addi	a0,a0,1558 # 80006988 <xPendingReadyList>
    8000137a:	fea780e3          	beq	a5,a0,8000135a <xTaskResumeFromISR+0x20>
                if( listIS_CONTAINED_WITHIN( NULL, &( pxTCB->xEventListItem ) ) != pdFALSE )
    8000137e:	fff1                	bnez	a5,8000135a <xTaskResumeFromISR+0x20>
                            if( pxTCB->ucNotifyState[ x ] == taskWAITING_NOTIFICATION )
    80001380:	08c44783          	lbu	a5,140(s0)
    80001384:	4685                	li	a3,1
    80001386:	fcd78ae3          	beq	a5,a3,8000135a <xTaskResumeFromISR+0x20>
                if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    8000138a:	00016797          	auipc	a5,0x16
    8000138e:	7567b783          	ld	a5,1878(a5) # 80017ae0 <uxSchedulerSuspended>
    80001392:	e3d1                	bnez	a5,80001416 <xTaskResumeFromISR+0xdc>
                        if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    80001394:	00016797          	auipc	a5,0x16
    80001398:	7bc7b783          	ld	a5,1980(a5) # 80017b50 <pxCurrentTCB>
    8000139c:	6c38                	ld	a4,88(s0)
    8000139e:	6fbc                	ld	a5,88(a5)
    800013a0:	00e7f763          	bgeu	a5,a4,800013ae <xTaskResumeFromISR+0x74>
                            xYieldPendings[ 0 ] = pdTRUE;
    800013a4:	00016797          	auipc	a5,0x16
    800013a8:	76d7b223          	sd	a3,1892(a5) # 80017b08 <xYieldPendings>
                            xYieldRequired = pdTRUE;
    800013ac:	4905                	li	s2,1
                    ( void ) uxListRemove( &( pxTCB->xStateListItem ) );
    800013ae:	00840993          	addi	s3,s0,8
    800013b2:	854e                	mv	a0,s3
    800013b4:	00001097          	auipc	ra,0x1
    800013b8:	27c080e7          	jalr	636(ra) # 80002630 <uxListRemove>
                    prvAddTaskToReadyList( pxTCB );
    800013bc:	6c2c                	ld	a1,88(s0)
    800013be:	00016517          	auipc	a0,0x16
    800013c2:	76250513          	addi	a0,a0,1890 # 80017b20 <uxTopReadyPriority>
    800013c6:	00053803          	ld	a6,0(a0)
    800013ca:	00259793          	slli	a5,a1,0x2
    800013ce:	97ae                	add	a5,a5,a1
    800013d0:	078e                	slli	a5,a5,0x3
    800013d2:	94be                	add	s1,s1,a5
    800013d4:	6cb4                	ld	a3,88(s1)
    800013d6:	68b0                	ld	a2,80(s1)
    }
    800013d8:	70a2                	ld	ra,40(sp)
                    prvAddTaskToReadyList( pxTCB );
    800013da:	6a98                	ld	a4,16(a3)
    800013dc:	e814                	sd	a3,16(s0)
    800013de:	0605                	addi	a2,a2,1
    800013e0:	ec18                	sd	a4,24(s0)
    800013e2:	0106b883          	ld	a7,16(a3)
    800013e6:	4705                	li	a4,1
    800013e8:	00b71733          	sll	a4,a4,a1
    800013ec:	0138b423          	sd	s3,8(a7)
    800013f0:	00005597          	auipc	a1,0x5
    800013f4:	4d058593          	addi	a1,a1,1232 # 800068c0 <pxReadyTasksLists>
    800013f8:	0136b823          	sd	s3,16(a3)
    800013fc:	95be                	add	a1,a1,a5
    800013fe:	f40c                	sd	a1,40(s0)
    }
    80001400:	7402                	ld	s0,32(sp)
                    prvAddTaskToReadyList( pxTCB );
    80001402:	010767b3          	or	a5,a4,a6
    80001406:	e11c                	sd	a5,0(a0)
    80001408:	e8b0                	sd	a2,80(s1)
    }
    8000140a:	69a2                	ld	s3,8(sp)
    8000140c:	64e2                	ld	s1,24(sp)
    8000140e:	854a                	mv	a0,s2
    80001410:	6942                	ld	s2,16(sp)
    80001412:	6145                	addi	sp,sp,48
    80001414:	8082                	ret
                    vListInsertEnd( &( xPendingReadyList ), &( pxTCB->xEventListItem ) );
    80001416:	03040593          	addi	a1,s0,48
    8000141a:	00001097          	auipc	ra,0x1
    8000141e:	1d0080e7          	jalr	464(ra) # 800025ea <vListInsertEnd>
    80001422:	bf25                	j	8000135a <xTaskResumeFromISR+0x20>

0000000080001424 <vTaskStartScheduler>:
{
    80001424:	1101                	addi	sp,sp,-32
        cIdleName[ xIdleTaskNameIndex ] = configIDLE_TASK_NAME[ xIdleTaskNameIndex ];
    80001426:	04900793          	li	a5,73
    char cIdleName[ configMAX_TASK_NAME_LEN ] = { 0 };
    8000142a:	e002                	sd	zero,0(sp)
        cIdleName[ xIdleTaskNameIndex ] = configIDLE_TASK_NAME[ xIdleTaskNameIndex ];
    8000142c:	00f10023          	sb	a5,0(sp)
{
    80001430:	ec06                	sd	ra,24(sp)
    80001432:	e822                	sd	s0,16(sp)
    char cIdleName[ configMAX_TASK_NAME_LEN ] = { 0 };
    80001434:	e402                	sd	zero,8(sp)
        if( cIdleName[ xIdleTaskNameIndex ] == ( char ) 0x00 )
    80001436:	00005717          	auipc	a4,0x5
    8000143a:	c4b70713          	addi	a4,a4,-949 # 80006081 <__clz_tab+0x101>
    8000143e:	00110793          	addi	a5,sp,1
        cIdleName[ xIdleTaskNameIndex ] = configIDLE_TASK_NAME[ xIdleTaskNameIndex ];
    80001442:	00074683          	lbu	a3,0(a4)
        if( cIdleName[ xIdleTaskNameIndex ] == ( char ) 0x00 )
    80001446:	0785                	addi	a5,a5,1
    80001448:	0705                	addi	a4,a4,1
        cIdleName[ xIdleTaskNameIndex ] = configIDLE_TASK_NAME[ xIdleTaskNameIndex ];
    8000144a:	fed78fa3          	sb	a3,-1(a5)
        if( cIdleName[ xIdleTaskNameIndex ] == ( char ) 0x00 )
    8000144e:	faf5                	bnez	a3,80001442 <vTaskStartScheduler+0x1e>
            xReturn = xTaskCreate( pxIdleTaskFunction,
    80001450:	00016797          	auipc	a5,0x16
    80001454:	69878793          	addi	a5,a5,1688 # 80017ae8 <xIdleTaskHandles>
    80001458:	4701                	li	a4,0
    8000145a:	08000613          	li	a2,128
    8000145e:	858a                	mv	a1,sp
    80001460:	fffff517          	auipc	a0,0xfffff
    80001464:	36050513          	addi	a0,a0,864 # 800007c0 <prvIdleTask>
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	6f4080e7          	jalr	1780(ra) # 80000b5c <xTaskCreate>
        if( xReturn != pdPASS )
    80001470:	4405                	li	s0,1
    80001472:	04851363          	bne	a0,s0,800014b8 <vTaskStartScheduler+0x94>
            xReturn = xTimerCreateTimerTask();
    80001476:	00002097          	auipc	ra,0x2
    8000147a:	514080e7          	jalr	1300(ra) # 8000398a <xTimerCreateTimerTask>
    if( xReturn == pdPASS )
    8000147e:	02851d63          	bne	a0,s0,800014b8 <vTaskStartScheduler+0x94>
        portDISABLE_INTERRUPTS();
    80001482:	30047073          	csrci	mstatus,8
        xNextTaskUnblockTime = portMAX_DELAY;
    80001486:	57fd                	li	a5,-1
    80001488:	00016717          	auipc	a4,0x16
    8000148c:	66f73423          	sd	a5,1640(a4) # 80017af0 <xNextTaskUnblockTime>
        xSchedulerRunning = pdTRUE;
    80001490:	00016797          	auipc	a5,0x16
    80001494:	68a7b423          	sd	a0,1672(a5) # 80017b18 <xSchedulerRunning>
        xTickCount = ( TickType_t ) configINITIAL_TICK_COUNT;
    80001498:	00016797          	auipc	a5,0x16
    8000149c:	6807b823          	sd	zero,1680(a5) # 80017b28 <xTickCount>
        ( void ) xPortStartScheduler();
    800014a0:	00004097          	auipc	ra,0x4
    800014a4:	a56080e7          	jalr	-1450(ra) # 80004ef6 <xPortStartScheduler>
}
    800014a8:	60e2                	ld	ra,24(sp)
    800014aa:	6442                	ld	s0,16(sp)
    ( void ) uxTopUsedPriority;
    800014ac:	00005797          	auipc	a5,0x5
    800014b0:	3a47b783          	ld	a5,932(a5) # 80006850 <uxTopUsedPriority>
}
    800014b4:	6105                	addi	sp,sp,32
    800014b6:	8082                	ret
        configASSERT( xReturn != errCOULD_NOT_ALLOCATE_REQUIRED_MEMORY );
    800014b8:	57fd                	li	a5,-1
    800014ba:	fef517e3          	bne	a0,a5,800014a8 <vTaskStartScheduler+0x84>
    800014be:	30047073          	csrci	mstatus,8
    800014c2:	a001                	j	800014c2 <vTaskStartScheduler+0x9e>

00000000800014c4 <vTaskEndScheduler>:
{
    800014c4:	1141                	addi	sp,sp,-16
    800014c6:	e406                	sd	ra,8(sp)
            vTaskDelete( xTimerGetTimerDaemonTaskHandle() );
    800014c8:	00002097          	auipc	ra,0x2
    800014cc:	634080e7          	jalr	1588(ra) # 80003afc <xTimerGetTimerDaemonTaskHandle>
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	930080e7          	jalr	-1744(ra) # 80000e00 <vTaskDelete>
            vTaskDelete( xIdleTaskHandles[ xCoreID ] );
    800014d8:	00016517          	auipc	a0,0x16
    800014dc:	61053503          	ld	a0,1552(a0) # 80017ae8 <xIdleTaskHandles>
    800014e0:	00000097          	auipc	ra,0x0
    800014e4:	920080e7          	jalr	-1760(ra) # 80000e00 <vTaskDelete>
        prvCheckTasksWaitingTermination();
    800014e8:	fffff097          	auipc	ra,0xfffff
    800014ec:	23e080e7          	jalr	574(ra) # 80000726 <prvCheckTasksWaitingTermination>
    portDISABLE_INTERRUPTS();
    800014f0:	30047073          	csrci	mstatus,8
}
    800014f4:	60a2                	ld	ra,8(sp)
    xSchedulerRunning = pdFALSE;
    800014f6:	00016797          	auipc	a5,0x16
    800014fa:	6207b123          	sd	zero,1570(a5) # 80017b18 <xSchedulerRunning>
}
    800014fe:	0141                	addi	sp,sp,16
    vPortEndScheduler();
    80001500:	00004317          	auipc	t1,0x4
    80001504:	a3230067          	jr	-1486(t1) # 80004f32 <vPortEndScheduler>

0000000080001508 <vTaskSuspendAll>:
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    80001508:	00016717          	auipc	a4,0x16
    8000150c:	5d870713          	addi	a4,a4,1496 # 80017ae0 <uxSchedulerSuspended>
    80001510:	631c                	ld	a5,0(a4)
    80001512:	0785                	addi	a5,a5,1
    80001514:	e31c                	sd	a5,0(a4)
}
    80001516:	8082                	ret

0000000080001518 <xTaskResumeAll>:
        taskENTER_CRITICAL();
    80001518:	30047073          	csrci	mstatus,8
    8000151c:	00005717          	auipc	a4,0x5
    80001520:	34470713          	addi	a4,a4,836 # 80006860 <xCriticalNesting>
    80001524:	631c                	ld	a5,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    80001526:	00016697          	auipc	a3,0x16
    8000152a:	5ba6b683          	ld	a3,1466(a3) # 80017ae0 <uxSchedulerSuspended>
        taskENTER_CRITICAL();
    8000152e:	0785                	addi	a5,a5,1
    80001530:	e31c                	sd	a5,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    80001532:	e681                	bnez	a3,8000153a <xTaskResumeAll+0x22>
    80001534:	30047073          	csrci	mstatus,8
    80001538:	a001                	j	80001538 <xTaskResumeAll+0x20>
    8000153a:	fffff317          	auipc	t1,0xfffff
    8000153e:	47830067          	jr	1144(t1) # 800009b2 <xTaskResumeAll.part.0>

0000000080001542 <xTaskGetTickCount>:
}
    80001542:	00016517          	auipc	a0,0x16
    80001546:	5e653503          	ld	a0,1510(a0) # 80017b28 <xTickCount>
    8000154a:	8082                	ret

000000008000154c <xTaskGetTickCountFromISR>:
    8000154c:	00016517          	auipc	a0,0x16
    80001550:	5dc53503          	ld	a0,1500(a0) # 80017b28 <xTickCount>
    80001554:	8082                	ret

0000000080001556 <uxTaskGetNumberOfTasks>:
}
    80001556:	00016517          	auipc	a0,0x16
    8000155a:	5da53503          	ld	a0,1498(a0) # 80017b30 <uxCurrentNumberOfTasks>
    8000155e:	8082                	ret

0000000080001560 <pcTaskGetName>:
    pxTCB = prvGetTCBFromHandle( xTaskToQuery );
    80001560:	c501                	beqz	a0,80001568 <pcTaskGetName+0x8>
}
    80001562:	06850513          	addi	a0,a0,104
    80001566:	8082                	ret
    pxTCB = prvGetTCBFromHandle( xTaskToQuery );
    80001568:	00016517          	auipc	a0,0x16
    8000156c:	5e853503          	ld	a0,1512(a0) # 80017b50 <pxCurrentTCB>
    configASSERT( pxTCB != NULL );
    80001570:	f96d                	bnez	a0,80001562 <pcTaskGetName+0x2>
    80001572:	30047073          	csrci	mstatus,8
    80001576:	a001                	j	80001576 <pcTaskGetName+0x16>

0000000080001578 <xTaskCatchUpTicks>:
    configASSERT( uxSchedulerSuspended == ( UBaseType_t ) 0U );
    80001578:	00016797          	auipc	a5,0x16
    8000157c:	56878793          	addi	a5,a5,1384 # 80017ae0 <uxSchedulerSuspended>
    80001580:	6398                	ld	a4,0(a5)
    80001582:	c701                	beqz	a4,8000158a <xTaskCatchUpTicks+0x12>
    80001584:	30047073          	csrci	mstatus,8
    80001588:	a001                	j	80001588 <xTaskCatchUpTicks+0x10>
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    8000158a:	6398                	ld	a4,0(a5)
    8000158c:	0705                	addi	a4,a4,1
    8000158e:	e398                	sd	a4,0(a5)
    taskENTER_CRITICAL();
    80001590:	30047073          	csrci	mstatus,8
        xPendedTicks += xTicksToCatchUp;
    80001594:	00016617          	auipc	a2,0x16
    80001598:	57c60613          	addi	a2,a2,1404 # 80017b10 <xPendedTicks>
    8000159c:	6214                	ld	a3,0(a2)
    taskENTER_CRITICAL();
    8000159e:	00005717          	auipc	a4,0x5
    800015a2:	2c270713          	addi	a4,a4,706 # 80006860 <xCriticalNesting>
    800015a6:	630c                	ld	a1,0(a4)
        xPendedTicks += xTicksToCatchUp;
    800015a8:	96aa                	add	a3,a3,a0
    800015aa:	e214                	sd	a3,0(a2)
    taskEXIT_CRITICAL();
    800015ac:	e199                	bnez	a1,800015b2 <xTaskCatchUpTicks+0x3a>
    800015ae:	30046073          	csrsi	mstatus,8
        taskENTER_CRITICAL();
    800015b2:	30047073          	csrci	mstatus,8
    800015b6:	6314                	ld	a3,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    800015b8:	6390                	ld	a2,0(a5)
        taskENTER_CRITICAL();
    800015ba:	00168793          	addi	a5,a3,1
    800015be:	e31c                	sd	a5,0(a4)
            configASSERT( uxSchedulerSuspended != 0U );
    800015c0:	e601                	bnez	a2,800015c8 <xTaskCatchUpTicks+0x50>
    800015c2:	30047073          	csrci	mstatus,8
    800015c6:	a001                	j	800015c6 <xTaskCatchUpTicks+0x4e>
    800015c8:	fffff317          	auipc	t1,0xfffff
    800015cc:	3ea30067          	jr	1002(t1) # 800009b2 <xTaskResumeAll.part.0>

00000000800015d0 <xTaskIncrementTick>:
    if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800015d0:	00016797          	auipc	a5,0x16
    800015d4:	5107b783          	ld	a5,1296(a5) # 80017ae0 <uxSchedulerSuspended>
    800015d8:	e789                	bnez	a5,800015e2 <xTaskIncrementTick+0x12>
    800015da:	fffff317          	auipc	t1,0xfffff
    800015de:	21a30067          	jr	538(t1) # 800007f4 <xTaskIncrementTick.part.0>
        xPendedTicks += 1U;
    800015e2:	00016717          	auipc	a4,0x16
    800015e6:	52e70713          	addi	a4,a4,1326 # 80017b10 <xPendedTicks>
    800015ea:	631c                	ld	a5,0(a4)
}
    800015ec:	4501                	li	a0,0
        xPendedTicks += 1U;
    800015ee:	0785                	addi	a5,a5,1
    800015f0:	e31c                	sd	a5,0(a4)
}
    800015f2:	8082                	ret

00000000800015f4 <vTaskSwitchContext>:
        if( uxSchedulerSuspended != ( UBaseType_t ) 0U )
    800015f4:	00016797          	auipc	a5,0x16
    800015f8:	4ec7b783          	ld	a5,1260(a5) # 80017ae0 <uxSchedulerSuspended>
    800015fc:	c799                	beqz	a5,8000160a <vTaskSwitchContext+0x16>
            xYieldPendings[ 0 ] = pdTRUE;
    800015fe:	4785                	li	a5,1
    80001600:	00016717          	auipc	a4,0x16
    80001604:	50f73423          	sd	a5,1288(a4) # 80017b08 <xYieldPendings>
    80001608:	8082                	ret
            xYieldPendings[ 0 ] = pdFALSE;
    8000160a:	00016797          	auipc	a5,0x16
    8000160e:	4e07bf23          	sd	zero,1278(a5) # 80017b08 <xYieldPendings>
            taskSELECT_HIGHEST_PRIORITY_TASK();
    80001612:	00016517          	auipc	a0,0x16
    80001616:	50e53503          	ld	a0,1294(a0) # 80017b20 <uxTopReadyPriority>
    8000161a:	1502                	slli	a0,a0,0x20
    {
    8000161c:	1141                	addi	sp,sp,-16
            taskSELECT_HIGHEST_PRIORITY_TASK();
    8000161e:	9101                	srli	a0,a0,0x20
    {
    80001620:	e406                	sd	ra,8(sp)
            taskSELECT_HIGHEST_PRIORITY_TASK();
    80001622:	00004097          	auipc	ra,0x4
    80001626:	72a080e7          	jalr	1834(ra) # 80005d4c <__clzdi2>
    8000162a:	3501                	addiw	a0,a0,-32
    8000162c:	477d                	li	a4,31
    8000162e:	8f09                	sub	a4,a4,a0
    80001630:	00271793          	slli	a5,a4,0x2
    80001634:	97ba                	add	a5,a5,a4
    80001636:	078e                	slli	a5,a5,0x3
    80001638:	00005717          	auipc	a4,0x5
    8000163c:	23870713          	addi	a4,a4,568 # 80006870 <xSuspendedTaskList>
    80001640:	973e                	add	a4,a4,a5
    80001642:	6b34                	ld	a3,80(a4)
    80001644:	e681                	bnez	a3,8000164c <vTaskSwitchContext+0x58>
    80001646:	30047073          	csrci	mstatus,8
    8000164a:	a001                	j	8000164a <vTaskSwitchContext+0x56>
    8000164c:	6f34                	ld	a3,88(a4)
    8000164e:	00005617          	auipc	a2,0x5
    80001652:	28260613          	addi	a2,a2,642 # 800068d0 <pxReadyTasksLists+0x10>
    80001656:	97b2                	add	a5,a5,a2
    80001658:	6694                	ld	a3,8(a3)
    8000165a:	ef34                	sd	a3,88(a4)
    8000165c:	00f68c63          	beq	a3,a5,80001674 <vTaskSwitchContext+0x80>
    80001660:	6e98                	ld	a4,24(a3)
    }
    80001662:	60a2                	ld	ra,8(sp)
            taskSELECT_HIGHEST_PRIORITY_TASK();
    80001664:	00016797          	auipc	a5,0x16
    80001668:	4ec78793          	addi	a5,a5,1260 # 80017b50 <pxCurrentTCB>
    8000166c:	e398                	sd	a4,0(a5)
            portTASK_SWITCH_HOOK( pxCurrentTCB );
    8000166e:	639c                	ld	a5,0(a5)
    }
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
            taskSELECT_HIGHEST_PRIORITY_TASK();
    80001674:	7734                	ld	a3,104(a4)
    80001676:	ef34                	sd	a3,88(a4)
    80001678:	b7e5                	j	80001660 <vTaskSwitchContext+0x6c>

000000008000167a <vTaskSuspend>:
    {
    8000167a:	7179                	addi	sp,sp,-48
    8000167c:	f406                	sd	ra,40(sp)
    8000167e:	f022                	sd	s0,32(sp)
    80001680:	ec26                	sd	s1,24(sp)
    80001682:	e84a                	sd	s2,16(sp)
    80001684:	e44e                	sd	s3,8(sp)
        taskENTER_CRITICAL();
    80001686:	30047073          	csrci	mstatus,8
    8000168a:	00005497          	auipc	s1,0x5
    8000168e:	1d648493          	addi	s1,s1,470 # 80006860 <xCriticalNesting>
    80001692:	609c                	ld	a5,0(s1)
    80001694:	00016917          	auipc	s2,0x16
    80001698:	4bc90913          	addi	s2,s2,1212 # 80017b50 <pxCurrentTCB>
    8000169c:	842a                	mv	s0,a0
    8000169e:	0785                	addi	a5,a5,1
    800016a0:	e09c                	sd	a5,0(s1)
            pxTCB = prvGetTCBFromHandle( xTaskToSuspend );
    800016a2:	c145                	beqz	a0,80001742 <vTaskSuspend+0xc8>
            if( uxListRemove( &( pxTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    800016a4:	00840993          	addi	s3,s0,8
    800016a8:	854e                	mv	a0,s3
    800016aa:	00001097          	auipc	ra,0x1
    800016ae:	f86080e7          	jalr	-122(ra) # 80002630 <uxListRemove>
    800016b2:	e90d                	bnez	a0,800016e4 <vTaskSuspend+0x6a>
                taskRESET_READY_PRIORITY( pxTCB->uxPriority );
    800016b4:	6c34                	ld	a3,88(s0)
    800016b6:	00005717          	auipc	a4,0x5
    800016ba:	1ba70713          	addi	a4,a4,442 # 80006870 <xSuspendedTaskList>
    800016be:	00269793          	slli	a5,a3,0x2
    800016c2:	97b6                	add	a5,a5,a3
    800016c4:	078e                	slli	a5,a5,0x3
    800016c6:	97ba                	add	a5,a5,a4
    800016c8:	6bbc                	ld	a5,80(a5)
    800016ca:	ef89                	bnez	a5,800016e4 <vTaskSuspend+0x6a>
    800016cc:	00016717          	auipc	a4,0x16
    800016d0:	45470713          	addi	a4,a4,1108 # 80017b20 <uxTopReadyPriority>
    800016d4:	6310                	ld	a2,0(a4)
    800016d6:	4785                	li	a5,1
    800016d8:	00d797b3          	sll	a5,a5,a3
    800016dc:	fff7c793          	not	a5,a5
    800016e0:	8ff1                	and	a5,a5,a2
    800016e2:	e31c                	sd	a5,0(a4)
            if( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) != NULL )
    800016e4:	683c                	ld	a5,80(s0)
    800016e6:	c799                	beqz	a5,800016f4 <vTaskSuspend+0x7a>
                ( void ) uxListRemove( &( pxTCB->xEventListItem ) );
    800016e8:	03040513          	addi	a0,s0,48
    800016ec:	00001097          	auipc	ra,0x1
    800016f0:	f44080e7          	jalr	-188(ra) # 80002630 <uxListRemove>
            vListInsertEnd( &xSuspendedTaskList, &( pxTCB->xStateListItem ) );
    800016f4:	85ce                	mv	a1,s3
    800016f6:	00005517          	auipc	a0,0x5
    800016fa:	17a50513          	addi	a0,a0,378 # 80006870 <xSuspendedTaskList>
    800016fe:	00001097          	auipc	ra,0x1
    80001702:	eec080e7          	jalr	-276(ra) # 800025ea <vListInsertEnd>
                    if( pxTCB->ucNotifyState[ x ] == taskWAITING_NOTIFICATION )
    80001706:	08c44703          	lbu	a4,140(s0)
    8000170a:	4785                	li	a5,1
    8000170c:	00f71463          	bne	a4,a5,80001714 <vTaskSuspend+0x9a>
                        pxTCB->ucNotifyState[ x ] = taskNOT_WAITING_NOTIFICATION;
    80001710:	08040623          	sb	zero,140(s0)
        taskEXIT_CRITICAL();
    80001714:	609c                	ld	a5,0(s1)
    80001716:	17fd                	addi	a5,a5,-1
    80001718:	e09c                	sd	a5,0(s1)
    8000171a:	e399                	bnez	a5,80001720 <vTaskSuspend+0xa6>
    8000171c:	30046073          	csrsi	mstatus,8
            if( xSchedulerRunning != pdFALSE )
    80001720:	00016797          	auipc	a5,0x16
    80001724:	3f878793          	addi	a5,a5,1016 # 80017b18 <xSchedulerRunning>
    80001728:	6398                	ld	a4,0(a5)
    8000172a:	e315                	bnez	a4,8000174e <vTaskSuspend+0xd4>
            if( pxTCB == pxCurrentTCB )
    8000172c:	00093703          	ld	a4,0(s2)
    80001730:	04870663          	beq	a4,s0,8000177c <vTaskSuspend+0x102>
    }
    80001734:	70a2                	ld	ra,40(sp)
    80001736:	7402                	ld	s0,32(sp)
    80001738:	64e2                	ld	s1,24(sp)
    8000173a:	6942                	ld	s2,16(sp)
    8000173c:	69a2                	ld	s3,8(sp)
    8000173e:	6145                	addi	sp,sp,48
    80001740:	8082                	ret
            pxTCB = prvGetTCBFromHandle( xTaskToSuspend );
    80001742:	00093403          	ld	s0,0(s2)
            configASSERT( pxTCB != NULL );
    80001746:	fc39                	bnez	s0,800016a4 <vTaskSuspend+0x2a>
    80001748:	30047073          	csrci	mstatus,8
    8000174c:	a001                	j	8000174c <vTaskSuspend+0xd2>
                taskENTER_CRITICAL();
    8000174e:	30047073          	csrci	mstatus,8
    if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    80001752:	00016697          	auipc	a3,0x16
    80001756:	3f668693          	addi	a3,a3,1014 # 80017b48 <pxDelayedTaskList>
    8000175a:	6290                	ld	a2,0(a3)
                taskENTER_CRITICAL();
    8000175c:	6098                	ld	a4,0(s1)
    if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    8000175e:	6210                	ld	a2,0(a2)
                taskENTER_CRITICAL();
    80001760:	00170593          	addi	a1,a4,1
    80001764:	e08c                	sd	a1,0(s1)
    if( listLIST_IS_EMPTY( pxDelayedTaskList ) != pdFALSE )
    80001766:	e60d                	bnez	a2,80001790 <vTaskSuspend+0x116>
        xNextTaskUnblockTime = portMAX_DELAY;
    80001768:	56fd                	li	a3,-1
    8000176a:	00016617          	auipc	a2,0x16
    8000176e:	38d63323          	sd	a3,902(a2) # 80017af0 <xNextTaskUnblockTime>
                taskEXIT_CRITICAL();
    80001772:	e098                	sd	a4,0(s1)
    80001774:	ff45                	bnez	a4,8000172c <vTaskSuspend+0xb2>
    80001776:	30046073          	csrsi	mstatus,8
    8000177a:	bf4d                	j	8000172c <vTaskSuspend+0xb2>
                if( xSchedulerRunning != pdFALSE )
    8000177c:	639c                	ld	a5,0(a5)
    8000177e:	c38d                	beqz	a5,800017a0 <vTaskSuspend+0x126>
                    configASSERT( uxSchedulerSuspended == 0 );
    80001780:	00016797          	auipc	a5,0x16
    80001784:	3607b783          	ld	a5,864(a5) # 80017ae0 <uxSchedulerSuspended>
    80001788:	cb9d                	beqz	a5,800017be <vTaskSuspend+0x144>
    8000178a:	30047073          	csrci	mstatus,8
    8000178e:	a001                	j	8000178e <vTaskSuspend+0x114>
        xNextTaskUnblockTime = listGET_ITEM_VALUE_OF_HEAD_ENTRY( pxDelayedTaskList );
    80001790:	6294                	ld	a3,0(a3)
    80001792:	6e94                	ld	a3,24(a3)
    80001794:	6294                	ld	a3,0(a3)
    80001796:	00016617          	auipc	a2,0x16
    8000179a:	34d63d23          	sd	a3,858(a2) # 80017af0 <xNextTaskUnblockTime>
}
    8000179e:	bfd1                	j	80001772 <vTaskSuspend+0xf8>
                    if( uxCurrentListLength == uxCurrentNumberOfTasks )
    800017a0:	00016717          	auipc	a4,0x16
    800017a4:	39073703          	ld	a4,912(a4) # 80017b30 <uxCurrentNumberOfTasks>
    800017a8:	00005797          	auipc	a5,0x5
    800017ac:	0c87b783          	ld	a5,200(a5) # 80006870 <xSuspendedTaskList>
    800017b0:	00f71a63          	bne	a4,a5,800017c4 <vTaskSuspend+0x14a>
                        pxCurrentTCB = NULL;
    800017b4:	00016797          	auipc	a5,0x16
    800017b8:	3807be23          	sd	zero,924(a5) # 80017b50 <pxCurrentTCB>
    800017bc:	bfa5                	j	80001734 <vTaskSuspend+0xba>
                    portYIELD_WITHIN_API();
    800017be:	00000073          	ecall
    800017c2:	bf8d                	j	80001734 <vTaskSuspend+0xba>
    }
    800017c4:	7402                	ld	s0,32(sp)
    800017c6:	70a2                	ld	ra,40(sp)
    800017c8:	64e2                	ld	s1,24(sp)
    800017ca:	6942                	ld	s2,16(sp)
    800017cc:	69a2                	ld	s3,8(sp)
    800017ce:	6145                	addi	sp,sp,48
                        vTaskSwitchContext();
    800017d0:	00000317          	auipc	t1,0x0
    800017d4:	e2430067          	jr	-476(t1) # 800015f4 <vTaskSwitchContext>

00000000800017d8 <vTaskPlaceOnEventList>:
    configASSERT( pxEventList );
    800017d8:	c905                	beqz	a0,80001808 <vTaskPlaceOnEventList+0x30>
{
    800017da:	1141                	addi	sp,sp,-16
    800017dc:	e022                	sd	s0,0(sp)
    800017de:	842e                	mv	s0,a1
    vListInsert( pxEventList, &( pxCurrentTCB->xEventListItem ) );
    800017e0:	00016597          	auipc	a1,0x16
    800017e4:	3705b583          	ld	a1,880(a1) # 80017b50 <pxCurrentTCB>
    800017e8:	03058593          	addi	a1,a1,48
{
    800017ec:	e406                	sd	ra,8(sp)
    vListInsert( pxEventList, &( pxCurrentTCB->xEventListItem ) );
    800017ee:	00001097          	auipc	ra,0x1
    800017f2:	e14080e7          	jalr	-492(ra) # 80002602 <vListInsert>
    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
    800017f6:	8522                	mv	a0,s0
}
    800017f8:	6402                	ld	s0,0(sp)
    800017fa:	60a2                	ld	ra,8(sp)
    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
    800017fc:	4585                	li	a1,1
}
    800017fe:	0141                	addi	sp,sp,16
    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
    80001800:	fffff317          	auipc	t1,0xfffff
    80001804:	e3230067          	jr	-462(t1) # 80000632 <prvAddCurrentTaskToDelayedList>
    configASSERT( pxEventList );
    80001808:	30047073          	csrci	mstatus,8
    8000180c:	a001                	j	8000180c <vTaskPlaceOnEventList+0x34>

000000008000180e <vTaskPlaceOnUnorderedEventList>:
{
    8000180e:	87aa                	mv	a5,a0
    configASSERT( pxEventList );
    80001810:	c92d                	beqz	a0,80001882 <vTaskPlaceOnUnorderedEventList+0x74>
    configASSERT( uxSchedulerSuspended != ( UBaseType_t ) 0U );
    80001812:	00016717          	auipc	a4,0x16
    80001816:	2ce73703          	ld	a4,718(a4) # 80017ae0 <uxSchedulerSuspended>
    8000181a:	e701                	bnez	a4,80001822 <vTaskPlaceOnUnorderedEventList+0x14>
    8000181c:	30047073          	csrci	mstatus,8
    80001820:	a001                	j	80001820 <vTaskPlaceOnUnorderedEventList+0x12>
    listINSERT_END( pxEventList, &( pxCurrentTCB->xEventListItem ) );
    80001822:	6514                	ld	a3,8(a0)
    listSET_LIST_ITEM_VALUE( &( pxCurrentTCB->xEventListItem ), xItemValue | taskEVENT_LIST_ITEM_VALUE_IN_USE );
    80001824:	00016717          	auipc	a4,0x16
    80001828:	32c70713          	addi	a4,a4,812 # 80017b50 <pxCurrentTCB>
    8000182c:	00073e03          	ld	t3,0(a4)
    80001830:	4505                	li	a0,1
    listINSERT_END( pxEventList, &( pxCurrentTCB->xEventListItem ) );
    80001832:	00073303          	ld	t1,0(a4)
    listSET_LIST_ITEM_VALUE( &( pxCurrentTCB->xEventListItem ), xItemValue | taskEVENT_LIST_ITEM_VALUE_IN_USE );
    80001836:	057e                	slli	a0,a0,0x1f
    listINSERT_END( pxEventList, &( pxCurrentTCB->xEventListItem ) );
    80001838:	0106b883          	ld	a7,16(a3)
    8000183c:	00073803          	ld	a6,0(a4)
    listSET_LIST_ITEM_VALUE( &( pxCurrentTCB->xEventListItem ), xItemValue | taskEVENT_LIST_ITEM_VALUE_IN_USE );
    80001840:	8dc9                	or	a1,a1,a0
    80001842:	02be3823          	sd	a1,48(t3)
    listINSERT_END( pxEventList, &( pxCurrentTCB->xEventListItem ) );
    80001846:	02d33c23          	sd	a3,56(t1)
    8000184a:	05183023          	sd	a7,64(a6)
    8000184e:	00073803          	ld	a6,0(a4)
    80001852:	0106b303          	ld	t1,16(a3)
    80001856:	6308                	ld	a0,0(a4)
    80001858:	638c                	ld	a1,0(a5)
    8000185a:	00073883          	ld	a7,0(a4)
    8000185e:	03080713          	addi	a4,a6,48
    80001862:	00e33423          	sd	a4,8(t1)
    80001866:	03050713          	addi	a4,a0,48
    8000186a:	ea98                	sd	a4,16(a3)
    8000186c:	04f8b823          	sd	a5,80(a7)
    80001870:	00158713          	addi	a4,a1,1
    80001874:	e398                	sd	a4,0(a5)
    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
    80001876:	4585                	li	a1,1
    80001878:	8532                	mv	a0,a2
    8000187a:	fffff317          	auipc	t1,0xfffff
    8000187e:	db830067          	jr	-584(t1) # 80000632 <prvAddCurrentTaskToDelayedList>
    configASSERT( pxEventList );
    80001882:	30047073          	csrci	mstatus,8
    80001886:	a001                	j	80001886 <vTaskPlaceOnUnorderedEventList+0x78>

0000000080001888 <vTaskPlaceOnEventListRestricted>:
    {
    80001888:	87aa                	mv	a5,a0
    8000188a:	852e                	mv	a0,a1
    8000188c:	85b2                	mv	a1,a2
        configASSERT( pxEventList );
    8000188e:	cbb1                	beqz	a5,800018e2 <vTaskPlaceOnEventListRestricted+0x5a>
        listINSERT_END( pxEventList, &( pxCurrentTCB->xEventListItem ) );
    80001890:	6794                	ld	a3,8(a5)
    80001892:	00016717          	auipc	a4,0x16
    80001896:	2be70713          	addi	a4,a4,702 # 80017b50 <pxCurrentTCB>
    8000189a:	00073883          	ld	a7,0(a4)
    8000189e:	0106b803          	ld	a6,16(a3)
    800018a2:	6310                	ld	a2,0(a4)
    800018a4:	02d8bc23          	sd	a3,56(a7)
    800018a8:	00073883          	ld	a7,0(a4)
    800018ac:	05063023          	sd	a6,64(a2)
    800018b0:	0106be03          	ld	t3,16(a3)
    800018b4:	00073803          	ld	a6,0(a4)
    800018b8:	6390                	ld	a2,0(a5)
    800018ba:	00073303          	ld	t1,0(a4)
    800018be:	03088713          	addi	a4,a7,48
    800018c2:	00ee3423          	sd	a4,8(t3)
    800018c6:	03080713          	addi	a4,a6,48
    800018ca:	ea98                	sd	a4,16(a3)
    800018cc:	04f33823          	sd	a5,80(t1)
    800018d0:	00160713          	addi	a4,a2,1
    800018d4:	e398                	sd	a4,0(a5)
        if( xWaitIndefinitely != pdFALSE )
    800018d6:	c191                	beqz	a1,800018da <vTaskPlaceOnEventListRestricted+0x52>
            xTicksToWait = portMAX_DELAY;
    800018d8:	557d                	li	a0,-1
        prvAddCurrentTaskToDelayedList( xTicksToWait, xWaitIndefinitely );
    800018da:	fffff317          	auipc	t1,0xfffff
    800018de:	d5830067          	jr	-680(t1) # 80000632 <prvAddCurrentTaskToDelayedList>
        configASSERT( pxEventList );
    800018e2:	30047073          	csrci	mstatus,8
    800018e6:	a001                	j	800018e6 <vTaskPlaceOnEventListRestricted+0x5e>

00000000800018e8 <xTaskRemoveFromEventList>:
    pxUnblockedTCB = listGET_OWNER_OF_HEAD_ENTRY( pxEventList );
    800018e8:	6d1c                	ld	a5,24(a0)
    800018ea:	6f9c                	ld	a5,24(a5)
    configASSERT( pxUnblockedTCB );
    800018ec:	10078b63          	beqz	a5,80001a02 <xTaskRemoveFromEventList+0x11a>
    listREMOVE_ITEM( &( pxUnblockedTCB->xEventListItem ) );
    800018f0:	6bb8                	ld	a4,80(a5)
    800018f2:	7f90                	ld	a2,56(a5)
    800018f4:	63b4                	ld	a3,64(a5)
    800018f6:	6708                	ld	a0,8(a4)
    800018f8:	03078593          	addi	a1,a5,48
    800018fc:	ea14                	sd	a3,16(a2)
    800018fe:	e690                	sd	a2,8(a3)
    80001900:	0eb50463          	beq	a0,a1,800019e8 <xTaskRemoveFromEventList+0x100>
    80001904:	6314                	ld	a3,0(a4)
    80001906:	0407b823          	sd	zero,80(a5)
    if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    8000190a:	00016617          	auipc	a2,0x16
    8000190e:	1d663603          	ld	a2,470(a2) # 80017ae0 <uxSchedulerSuspended>
    listREMOVE_ITEM( &( pxUnblockedTCB->xEventListItem ) );
    80001912:	16fd                	addi	a3,a3,-1
    80001914:	e314                	sd	a3,0(a4)
        prvAddTaskToReadyList( pxUnblockedTCB );
    80001916:	6fb8                	ld	a4,88(a5)
    if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    80001918:	ca31                	beqz	a2,8000196c <xTaskRemoveFromEventList+0x84>
        listINSERT_END( &( xPendingReadyList ), &( pxUnblockedTCB->xEventListItem ) );
    8000191a:	00005617          	auipc	a2,0x5
    8000191e:	f5660613          	addi	a2,a2,-170 # 80006870 <xSuspendedTaskList>
    80001922:	12063683          	ld	a3,288(a2)
    80001926:	11863503          	ld	a0,280(a2)
    8000192a:	0106b803          	ld	a6,16(a3)
    8000192e:	ff94                	sd	a3,56(a5)
    80001930:	0505                	addi	a0,a0,1
    80001932:	0507b023          	sd	a6,64(a5)
    80001936:	0106b803          	ld	a6,16(a3)
    8000193a:	10a63c23          	sd	a0,280(a2)
    8000193e:	00b83423          	sd	a1,8(a6)
    80001942:	ea8c                	sd	a1,16(a3)
    80001944:	00005697          	auipc	a3,0x5
    80001948:	04468693          	addi	a3,a3,68 # 80006988 <xPendingReadyList>
    8000194c:	ebb4                	sd	a3,80(a5)
        if( pxUnblockedTCB->uxPriority > pxCurrentTCB->uxPriority )
    8000194e:	00016797          	auipc	a5,0x16
    80001952:	2027b783          	ld	a5,514(a5) # 80017b50 <pxCurrentTCB>
    80001956:	6fbc                	ld	a5,88(a5)
            xReturn = pdFALSE;
    80001958:	4501                	li	a0,0
        if( pxUnblockedTCB->uxPriority > pxCurrentTCB->uxPriority )
    8000195a:	00e7f863          	bgeu	a5,a4,8000196a <xTaskRemoveFromEventList+0x82>
            xYieldPendings[ 0 ] = pdTRUE;
    8000195e:	4785                	li	a5,1
    80001960:	00016717          	auipc	a4,0x16
    80001964:	1af73423          	sd	a5,424(a4) # 80017b08 <xYieldPendings>
            xReturn = pdTRUE;
    80001968:	4505                	li	a0,1
}
    8000196a:	8082                	ret
        listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    8000196c:	6f90                	ld	a2,24(a5)
    8000196e:	6b94                	ld	a3,16(a5)
    80001970:	7788                	ld	a0,40(a5)
    80001972:	00878813          	addi	a6,a5,8
    80001976:	ea90                	sd	a2,16(a3)
    80001978:	6f90                	ld	a2,24(a5)
    8000197a:	650c                	ld	a1,8(a0)
    8000197c:	e614                	sd	a3,8(a2)
    8000197e:	09058563          	beq	a1,a6,80001a08 <xTaskRemoveFromEventList+0x120>
        prvAddTaskToReadyList( pxUnblockedTCB );
    80001982:	00271693          	slli	a3,a4,0x2
    80001986:	96ba                	add	a3,a3,a4
    80001988:	068e                	slli	a3,a3,0x3
    8000198a:	00005617          	auipc	a2,0x5
    8000198e:	ee660613          	addi	a2,a2,-282 # 80006870 <xSuspendedTaskList>
    80001992:	9636                	add	a2,a2,a3
    80001994:	6e2c                	ld	a1,88(a2)
        listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001996:	00053883          	ld	a7,0(a0)
        prvAddTaskToReadyList( pxUnblockedTCB );
    8000199a:	00016317          	auipc	t1,0x16
    8000199e:	18630313          	addi	t1,t1,390 # 80017b20 <uxTopReadyPriority>
    800019a2:	0105be03          	ld	t3,16(a1)
        listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    800019a6:	18fd                	addi	a7,a7,-1
    800019a8:	01153023          	sd	a7,0(a0)
        prvAddTaskToReadyList( pxUnblockedTCB );
    800019ac:	01c7bc23          	sd	t3,24(a5)
    800019b0:	0105be03          	ld	t3,16(a1)
    800019b4:	eb8c                	sd	a1,16(a5)
    800019b6:	6a28                	ld	a0,80(a2)
    800019b8:	00033883          	ld	a7,0(t1)
    800019bc:	010e3423          	sd	a6,8(t3)
    800019c0:	0105b823          	sd	a6,16(a1)
    800019c4:	4585                	li	a1,1
    800019c6:	00005817          	auipc	a6,0x5
    800019ca:	efa80813          	addi	a6,a6,-262 # 800068c0 <pxReadyTasksLists>
    800019ce:	9836                	add	a6,a6,a3
    800019d0:	00e595b3          	sll	a1,a1,a4
    800019d4:	0307b423          	sd	a6,40(a5)
    800019d8:	0115e6b3          	or	a3,a1,a7
    800019dc:	00150793          	addi	a5,a0,1
    800019e0:	00d33023          	sd	a3,0(t1)
    800019e4:	ea3c                	sd	a5,80(a2)
    800019e6:	b7a5                	j	8000194e <xTaskRemoveFromEventList+0x66>
    listREMOVE_ITEM( &( pxUnblockedTCB->xEventListItem ) );
    800019e8:	e714                	sd	a3,8(a4)
    800019ea:	6314                	ld	a3,0(a4)
    800019ec:	0407b823          	sd	zero,80(a5)
    if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800019f0:	00016617          	auipc	a2,0x16
    800019f4:	0f063603          	ld	a2,240(a2) # 80017ae0 <uxSchedulerSuspended>
    listREMOVE_ITEM( &( pxUnblockedTCB->xEventListItem ) );
    800019f8:	16fd                	addi	a3,a3,-1
    800019fa:	e314                	sd	a3,0(a4)
        prvAddTaskToReadyList( pxUnblockedTCB );
    800019fc:	6fb8                	ld	a4,88(a5)
    if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800019fe:	fe11                	bnez	a2,8000191a <xTaskRemoveFromEventList+0x32>
    80001a00:	b7b5                	j	8000196c <xTaskRemoveFromEventList+0x84>
    configASSERT( pxUnblockedTCB );
    80001a02:	30047073          	csrci	mstatus,8
    80001a06:	a001                	j	80001a06 <xTaskRemoveFromEventList+0x11e>
        listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001a08:	e510                	sd	a2,8(a0)
    80001a0a:	bfa5                	j	80001982 <xTaskRemoveFromEventList+0x9a>

0000000080001a0c <vTaskRemoveFromUnorderedEventList>:
    configASSERT( uxSchedulerSuspended != ( UBaseType_t ) 0U );
    80001a0c:	00016797          	auipc	a5,0x16
    80001a10:	0d47b783          	ld	a5,212(a5) # 80017ae0 <uxSchedulerSuspended>
    80001a14:	e781                	bnez	a5,80001a1c <vTaskRemoveFromUnorderedEventList+0x10>
    80001a16:	30047073          	csrci	mstatus,8
    80001a1a:	a001                	j	80001a1a <vTaskRemoveFromUnorderedEventList+0xe>
    listSET_LIST_ITEM_VALUE( pxEventListItem, xItemValue | taskEVENT_LIST_ITEM_VALUE_IN_USE );
    80001a1c:	4705                	li	a4,1
    80001a1e:	077e                	slli	a4,a4,0x1f
    pxUnblockedTCB = listGET_LIST_ITEM_OWNER( pxEventListItem );
    80001a20:	6d1c                	ld	a5,24(a0)
    listSET_LIST_ITEM_VALUE( pxEventListItem, xItemValue | taskEVENT_LIST_ITEM_VALUE_IN_USE );
    80001a22:	8dd9                	or	a1,a1,a4
    80001a24:	e10c                	sd	a1,0(a0)
    configASSERT( pxUnblockedTCB );
    80001a26:	cbcd                	beqz	a5,80001ad8 <vTaskRemoveFromUnorderedEventList+0xcc>
    listREMOVE_ITEM( pxEventListItem );
    80001a28:	6910                	ld	a2,16(a0)
    80001a2a:	6514                	ld	a3,8(a0)
    80001a2c:	7118                	ld	a4,32(a0)
    80001a2e:	ea90                	sd	a2,16(a3)
    80001a30:	6910                	ld	a2,16(a0)
    80001a32:	670c                	ld	a1,8(a4)
    80001a34:	e614                	sd	a3,8(a2)
    80001a36:	0aa58663          	beq	a1,a0,80001ae2 <vTaskRemoveFromUnorderedEventList+0xd6>
    80001a3a:	6314                	ld	a3,0(a4)
    listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001a3c:	6b90                	ld	a2,16(a5)
    80001a3e:	6f8c                	ld	a1,24(a5)
    listREMOVE_ITEM( pxEventListItem );
    80001a40:	16fd                	addi	a3,a3,-1
    80001a42:	02053023          	sd	zero,32(a0)
    listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001a46:	7788                	ld	a0,40(a5)
    listREMOVE_ITEM( pxEventListItem );
    80001a48:	e314                	sd	a3,0(a4)
    listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001a4a:	ea0c                	sd	a1,16(a2)
    80001a4c:	6f98                	ld	a4,24(a5)
    80001a4e:	6514                	ld	a3,8(a0)
    80001a50:	00878813          	addi	a6,a5,8
    80001a54:	e710                	sd	a2,8(a4)
    80001a56:	09068463          	beq	a3,a6,80001ade <vTaskRemoveFromUnorderedEventList+0xd2>
    prvAddTaskToReadyList( pxUnblockedTCB );
    80001a5a:	6fb0                	ld	a2,88(a5)
    80001a5c:	00005697          	auipc	a3,0x5
    80001a60:	e1468693          	addi	a3,a3,-492 # 80006870 <xSuspendedTaskList>
    listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001a64:	00053883          	ld	a7,0(a0)
    prvAddTaskToReadyList( pxUnblockedTCB );
    80001a68:	00261713          	slli	a4,a2,0x2
    80001a6c:	9732                	add	a4,a4,a2
    80001a6e:	070e                	slli	a4,a4,0x3
    80001a70:	96ba                	add	a3,a3,a4
    80001a72:	6eac                	ld	a1,88(a3)
    listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001a74:	18fd                	addi	a7,a7,-1
    prvAddTaskToReadyList( pxUnblockedTCB );
    80001a76:	00016317          	auipc	t1,0x16
    80001a7a:	0aa30313          	addi	t1,t1,170 # 80017b20 <uxTopReadyPriority>
    80001a7e:	0105be03          	ld	t3,16(a1)
    listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001a82:	01153023          	sd	a7,0(a0)
    prvAddTaskToReadyList( pxUnblockedTCB );
    80001a86:	00033503          	ld	a0,0(t1)
    80001a8a:	01c7bc23          	sd	t3,24(a5)
    80001a8e:	0105be83          	ld	t4,16(a1)
    80001a92:	4e05                	li	t3,1
    80001a94:	00ce18b3          	sll	a7,t3,a2
    80001a98:	eb8c                	sd	a1,16(a5)
    80001a9a:	00a8e8b3          	or	a7,a7,a0
    80001a9e:	01133023          	sd	a7,0(t1)
    80001aa2:	6aa8                	ld	a0,80(a3)
    80001aa4:	010eb423          	sd	a6,8(t4)
    80001aa8:	0105b823          	sd	a6,16(a1)
        if( pxUnblockedTCB->uxPriority > pxCurrentTCB->uxPriority )
    80001aac:	00016897          	auipc	a7,0x16
    80001ab0:	0a48b883          	ld	a7,164(a7) # 80017b50 <pxCurrentTCB>
    prvAddTaskToReadyList( pxUnblockedTCB );
    80001ab4:	00005597          	auipc	a1,0x5
    80001ab8:	e0c58593          	addi	a1,a1,-500 # 800068c0 <pxReadyTasksLists>
    80001abc:	972e                	add	a4,a4,a1
        if( pxUnblockedTCB->uxPriority > pxCurrentTCB->uxPriority )
    80001abe:	0588b583          	ld	a1,88(a7)
    prvAddTaskToReadyList( pxUnblockedTCB );
    80001ac2:	f798                	sd	a4,40(a5)
    80001ac4:	00150793          	addi	a5,a0,1
    80001ac8:	eabc                	sd	a5,80(a3)
        if( pxUnblockedTCB->uxPriority > pxCurrentTCB->uxPriority )
    80001aca:	00c5f663          	bgeu	a1,a2,80001ad6 <vTaskRemoveFromUnorderedEventList+0xca>
            xYieldPendings[ 0 ] = pdTRUE;
    80001ace:	00016797          	auipc	a5,0x16
    80001ad2:	03c7bd23          	sd	t3,58(a5) # 80017b08 <xYieldPendings>
}
    80001ad6:	8082                	ret
    configASSERT( pxUnblockedTCB );
    80001ad8:	30047073          	csrci	mstatus,8
    80001adc:	a001                	j	80001adc <vTaskRemoveFromUnorderedEventList+0xd0>
    listREMOVE_ITEM( &( pxUnblockedTCB->xStateListItem ) );
    80001ade:	e518                	sd	a4,8(a0)
    80001ae0:	bfad                	j	80001a5a <vTaskRemoveFromUnorderedEventList+0x4e>
    listREMOVE_ITEM( pxEventListItem );
    80001ae2:	e710                	sd	a2,8(a4)
    80001ae4:	bf99                	j	80001a3a <vTaskRemoveFromUnorderedEventList+0x2e>

0000000080001ae6 <vTaskSetTimeOutState>:
    configASSERT( pxTimeOut );
    80001ae6:	c51d                	beqz	a0,80001b14 <vTaskSetTimeOutState+0x2e>
    taskENTER_CRITICAL();
    80001ae8:	30047073          	csrci	mstatus,8
    80001aec:	00005717          	auipc	a4,0x5
    80001af0:	d7470713          	addi	a4,a4,-652 # 80006860 <xCriticalNesting>
    80001af4:	631c                	ld	a5,0(a4)
        pxTimeOut->xOverflowCount = xNumOfOverflows;
    80001af6:	00016697          	auipc	a3,0x16
    80001afa:	00a6b683          	ld	a3,10(a3) # 80017b00 <xNumOfOverflows>
    80001afe:	e114                	sd	a3,0(a0)
        pxTimeOut->xTimeOnEntering = xTickCount;
    80001b00:	00016697          	auipc	a3,0x16
    80001b04:	0286b683          	ld	a3,40(a3) # 80017b28 <xTickCount>
    80001b08:	e514                	sd	a3,8(a0)
    taskEXIT_CRITICAL();
    80001b0a:	e31c                	sd	a5,0(a4)
    80001b0c:	e399                	bnez	a5,80001b12 <vTaskSetTimeOutState+0x2c>
    80001b0e:	30046073          	csrsi	mstatus,8
}
    80001b12:	8082                	ret
    configASSERT( pxTimeOut );
    80001b14:	30047073          	csrci	mstatus,8
    80001b18:	a001                	j	80001b18 <vTaskSetTimeOutState+0x32>

0000000080001b1a <vTaskInternalSetTimeOutState>:
    pxTimeOut->xOverflowCount = xNumOfOverflows;
    80001b1a:	00016717          	auipc	a4,0x16
    80001b1e:	fe673703          	ld	a4,-26(a4) # 80017b00 <xNumOfOverflows>
    pxTimeOut->xTimeOnEntering = xTickCount;
    80001b22:	00016797          	auipc	a5,0x16
    80001b26:	0067b783          	ld	a5,6(a5) # 80017b28 <xTickCount>
    pxTimeOut->xOverflowCount = xNumOfOverflows;
    80001b2a:	e118                	sd	a4,0(a0)
    pxTimeOut->xTimeOnEntering = xTickCount;
    80001b2c:	e51c                	sd	a5,8(a0)
}
    80001b2e:	8082                	ret

0000000080001b30 <xTaskCheckForTimeOut>:
{
    80001b30:	87aa                	mv	a5,a0
    configASSERT( pxTimeOut );
    80001b32:	c159                	beqz	a0,80001bb8 <xTaskCheckForTimeOut+0x88>
    configASSERT( pxTicksToWait );
    80001b34:	cda9                	beqz	a1,80001b8e <xTaskCheckForTimeOut+0x5e>
    taskENTER_CRITICAL();
    80001b36:	30047073          	csrci	mstatus,8
    80001b3a:	00005697          	auipc	a3,0x5
    80001b3e:	d2668693          	addi	a3,a3,-730 # 80006860 <xCriticalNesting>
    80001b42:	6298                	ld	a4,0(a3)
        const TickType_t xConstTickCount = xTickCount;
    80001b44:	00016817          	auipc	a6,0x16
    80001b48:	fe480813          	addi	a6,a6,-28 # 80017b28 <xTickCount>
    80001b4c:	00083883          	ld	a7,0(a6)
    taskENTER_CRITICAL();
    80001b50:	00170613          	addi	a2,a4,1
    80001b54:	e290                	sd	a2,0(a3)
            if( *pxTicksToWait == portMAX_DELAY )
    80001b56:	6190                	ld	a2,0(a1)
    80001b58:	537d                	li	t1,-1
                xReturn = pdFALSE;
    80001b5a:	4501                	li	a0,0
            if( *pxTicksToWait == portMAX_DELAY )
    80001b5c:	02660463          	beq	a2,t1,80001b84 <xTaskCheckForTimeOut+0x54>
        if( ( xNumOfOverflows != pxTimeOut->xOverflowCount ) && ( xConstTickCount >= pxTimeOut->xTimeOnEntering ) )
    80001b60:	00016317          	auipc	t1,0x16
    80001b64:	fa030313          	addi	t1,t1,-96 # 80017b00 <xNumOfOverflows>
    80001b68:	00033703          	ld	a4,0(t1)
    80001b6c:	0007be03          	ld	t3,0(a5)
        const TickType_t xElapsedTime = xConstTickCount - pxTimeOut->xTimeOnEntering;
    80001b70:	6788                	ld	a0,8(a5)
        if( ( xNumOfOverflows != pxTimeOut->xOverflowCount ) && ( xConstTickCount >= pxTimeOut->xTimeOnEntering ) )
    80001b72:	02ee0163          	beq	t3,a4,80001b94 <xTaskCheckForTimeOut+0x64>
    80001b76:	00a8ef63          	bltu	a7,a0,80001b94 <xTaskCheckForTimeOut+0x64>
            *pxTicksToWait = ( TickType_t ) 0;
    80001b7a:	0005b023          	sd	zero,0(a1)
    taskEXIT_CRITICAL();
    80001b7e:	6298                	ld	a4,0(a3)
            xReturn = pdTRUE;
    80001b80:	4505                	li	a0,1
    taskEXIT_CRITICAL();
    80001b82:	177d                	addi	a4,a4,-1
    80001b84:	e298                	sd	a4,0(a3)
    80001b86:	e319                	bnez	a4,80001b8c <xTaskCheckForTimeOut+0x5c>
    80001b88:	30046073          	csrsi	mstatus,8
}
    80001b8c:	8082                	ret
    configASSERT( pxTicksToWait );
    80001b8e:	30047073          	csrci	mstatus,8
    80001b92:	a001                	j	80001b92 <xTaskCheckForTimeOut+0x62>
        const TickType_t xElapsedTime = xConstTickCount - pxTimeOut->xTimeOnEntering;
    80001b94:	40a88733          	sub	a4,a7,a0
        else if( xElapsedTime < *pxTicksToWait )
    80001b98:	fec771e3          	bgeu	a4,a2,80001b7a <xTaskCheckForTimeOut+0x4a>
            *pxTicksToWait -= xElapsedTime;
    80001b9c:	41160733          	sub	a4,a2,a7
    80001ba0:	972a                	add	a4,a4,a0
    80001ba2:	e198                	sd	a4,0(a1)
    taskEXIT_CRITICAL();
    80001ba4:	6298                	ld	a4,0(a3)
    pxTimeOut->xOverflowCount = xNumOfOverflows;
    80001ba6:	00033583          	ld	a1,0(t1)
    pxTimeOut->xTimeOnEntering = xTickCount;
    80001baa:	00083603          	ld	a2,0(a6)
    taskEXIT_CRITICAL();
    80001bae:	177d                	addi	a4,a4,-1
    pxTimeOut->xOverflowCount = xNumOfOverflows;
    80001bb0:	e38c                	sd	a1,0(a5)
    pxTimeOut->xTimeOnEntering = xTickCount;
    80001bb2:	e790                	sd	a2,8(a5)
            xReturn = pdFALSE;
    80001bb4:	4501                	li	a0,0
    80001bb6:	b7f9                	j	80001b84 <xTaskCheckForTimeOut+0x54>
    configASSERT( pxTimeOut );
    80001bb8:	30047073          	csrci	mstatus,8
    80001bbc:	a001                	j	80001bbc <xTaskCheckForTimeOut+0x8c>

0000000080001bbe <vTaskMissedYield>:
    xYieldPendings[ portGET_CORE_ID() ] = pdTRUE;
    80001bbe:	4785                	li	a5,1
    80001bc0:	00016717          	auipc	a4,0x16
    80001bc4:	f4f73423          	sd	a5,-184(a4) # 80017b08 <xYieldPendings>
}
    80001bc8:	8082                	ret

0000000080001bca <xTaskGetCurrentTaskHandle>:
        }
    80001bca:	00016517          	auipc	a0,0x16
    80001bce:	f8653503          	ld	a0,-122(a0) # 80017b50 <pxCurrentTCB>
    80001bd2:	8082                	ret

0000000080001bd4 <xTaskGetCurrentTaskHandleForCore>:
        if( taskVALID_CORE_ID( xCoreID ) != pdFALSE )
    80001bd4:	e511                	bnez	a0,80001be0 <xTaskGetCurrentTaskHandleForCore+0xc>
                xReturn = pxCurrentTCB;
    80001bd6:	00016517          	auipc	a0,0x16
    80001bda:	f7a53503          	ld	a0,-134(a0) # 80017b50 <pxCurrentTCB>
    80001bde:	8082                	ret
        TaskHandle_t xReturn = NULL;
    80001be0:	4501                	li	a0,0
    }
    80001be2:	8082                	ret

0000000080001be4 <xTaskGetSchedulerState>:
        if( xSchedulerRunning == pdFALSE )
    80001be4:	00016797          	auipc	a5,0x16
    80001be8:	f347b783          	ld	a5,-204(a5) # 80017b18 <xSchedulerRunning>
            xReturn = taskSCHEDULER_NOT_STARTED;
    80001bec:	4505                	li	a0,1
        if( xSchedulerRunning == pdFALSE )
    80001bee:	cb81                	beqz	a5,80001bfe <xTaskGetSchedulerState+0x1a>
                if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    80001bf0:	00016517          	auipc	a0,0x16
    80001bf4:	ef053503          	ld	a0,-272(a0) # 80017ae0 <uxSchedulerSuspended>
    80001bf8:	00153513          	seqz	a0,a0
    80001bfc:	0506                	slli	a0,a0,0x1
    }
    80001bfe:	8082                	ret

0000000080001c00 <xTaskPriorityInherit>:
        if( pxMutexHolder != NULL )
    80001c00:	c925                	beqz	a0,80001c70 <xTaskPriorityInherit+0x70>
    {
    80001c02:	7179                	addi	sp,sp,-48
    80001c04:	ec26                	sd	s1,24(sp)
            if( pxMutexHolderTCB->uxPriority < pxCurrentTCB->uxPriority )
    80001c06:	00016497          	auipc	s1,0x16
    80001c0a:	f4a48493          	addi	s1,s1,-182 # 80017b50 <pxCurrentTCB>
    80001c0e:	609c                	ld	a5,0(s1)
    80001c10:	6d38                	ld	a4,88(a0)
    {
    80001c12:	f022                	sd	s0,32(sp)
            if( pxMutexHolderTCB->uxPriority < pxCurrentTCB->uxPriority )
    80001c14:	6fbc                	ld	a5,88(a5)
    {
    80001c16:	f406                	sd	ra,40(sp)
    80001c18:	e84a                	sd	s2,16(sp)
    80001c1a:	e44e                	sd	s3,8(sp)
    80001c1c:	842a                	mv	s0,a0
            if( pxMutexHolderTCB->uxPriority < pxCurrentTCB->uxPriority )
    80001c1e:	00f76e63          	bltu	a4,a5,80001c3a <xTaskPriorityInherit+0x3a>
                if( pxMutexHolderTCB->uxBasePriority < pxCurrentTCB->uxPriority )
    80001c22:	609c                	ld	a5,0(s1)
    80001c24:	7d28                	ld	a0,120(a0)
    80001c26:	6fbc                	ld	a5,88(a5)
    80001c28:	00f53533          	sltu	a0,a0,a5
    }
    80001c2c:	70a2                	ld	ra,40(sp)
    80001c2e:	7402                	ld	s0,32(sp)
    80001c30:	64e2                	ld	s1,24(sp)
    80001c32:	6942                	ld	s2,16(sp)
    80001c34:	69a2                	ld	s3,8(sp)
    80001c36:	6145                	addi	sp,sp,48
    80001c38:	8082                	ret
                if( ( listGET_LIST_ITEM_VALUE( &( pxMutexHolderTCB->xEventListItem ) ) & taskEVENT_LIST_ITEM_VALUE_IN_USE ) == ( ( TickType_t ) 0U ) )
    80001c3a:	791c                	ld	a5,48(a0)
    80001c3c:	01f7d79b          	srliw	a5,a5,0x1f
    80001c40:	cb95                	beqz	a5,80001c74 <xTaskPriorityInherit+0x74>
                if( listIS_CONTAINED_WITHIN( &( pxReadyTasksLists[ pxMutexHolderTCB->uxPriority ] ), &( pxMutexHolderTCB->xStateListItem ) ) != pdFALSE )
    80001c42:	00271793          	slli	a5,a4,0x2
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	7418                	ld	a4,40(s0)
    80001c4a:	00005917          	auipc	s2,0x5
    80001c4e:	c7690913          	addi	s2,s2,-906 # 800068c0 <pxReadyTasksLists>
    80001c52:	078e                	slli	a5,a5,0x3
    80001c54:	97ca                	add	a5,a5,s2
    80001c56:	02f70563          	beq	a4,a5,80001c80 <xTaskPriorityInherit+0x80>
                    pxMutexHolderTCB->uxPriority = pxCurrentTCB->uxPriority;
    80001c5a:	609c                	ld	a5,0(s1)
    }
    80001c5c:	70a2                	ld	ra,40(sp)
    80001c5e:	64e2                	ld	s1,24(sp)
                    pxMutexHolderTCB->uxPriority = pxCurrentTCB->uxPriority;
    80001c60:	6fbc                	ld	a5,88(a5)
    }
    80001c62:	6942                	ld	s2,16(sp)
    80001c64:	69a2                	ld	s3,8(sp)
                    pxMutexHolderTCB->uxPriority = pxCurrentTCB->uxPriority;
    80001c66:	ec3c                	sd	a5,88(s0)
    }
    80001c68:	7402                	ld	s0,32(sp)
                xReturn = pdTRUE;
    80001c6a:	4505                	li	a0,1
    }
    80001c6c:	6145                	addi	sp,sp,48
    80001c6e:	8082                	ret
        BaseType_t xReturn = pdFALSE;
    80001c70:	4501                	li	a0,0
    }
    80001c72:	8082                	ret
                    listSET_LIST_ITEM_VALUE( &( pxMutexHolderTCB->xEventListItem ), ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) pxCurrentTCB->uxPriority );
    80001c74:	609c                	ld	a5,0(s1)
    80001c76:	6fb4                	ld	a3,88(a5)
    80001c78:	4795                	li	a5,5
    80001c7a:	8f95                	sub	a5,a5,a3
    80001c7c:	f91c                	sd	a5,48(a0)
    80001c7e:	b7d1                	j	80001c42 <xTaskPriorityInherit+0x42>
                    if( uxListRemove( &( pxMutexHolderTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    80001c80:	00840993          	addi	s3,s0,8
    80001c84:	854e                	mv	a0,s3
    80001c86:	00001097          	auipc	ra,0x1
    80001c8a:	9aa080e7          	jalr	-1622(ra) # 80002630 <uxListRemove>
    80001c8e:	00016897          	auipc	a7,0x16
    80001c92:	e9288893          	addi	a7,a7,-366 # 80017b20 <uxTopReadyPriority>
    80001c96:	ed01                	bnez	a0,80001cae <xTaskPriorityInherit+0xae>
                        portRESET_READY_PRIORITY( pxMutexHolderTCB->uxPriority, uxTopReadyPriority );
    80001c98:	6c34                	ld	a3,88(s0)
    80001c9a:	0008b703          	ld	a4,0(a7)
    80001c9e:	4785                	li	a5,1
    80001ca0:	00d797b3          	sll	a5,a5,a3
    80001ca4:	fff7c793          	not	a5,a5
    80001ca8:	8ff9                	and	a5,a5,a4
    80001caa:	00f8b023          	sd	a5,0(a7)
                    pxMutexHolderTCB->uxPriority = pxCurrentTCB->uxPriority;
    80001cae:	609c                	ld	a5,0(s1)
                    prvAddTaskToReadyList( pxMutexHolderTCB );
    80001cb0:	00005717          	auipc	a4,0x5
    80001cb4:	bc070713          	addi	a4,a4,-1088 # 80006870 <xSuspendedTaskList>
    80001cb8:	4685                	li	a3,1
                    pxMutexHolderTCB->uxPriority = pxCurrentTCB->uxPriority;
    80001cba:	6fac                	ld	a1,88(a5)
                    prvAddTaskToReadyList( pxMutexHolderTCB );
    80001cbc:	0008b303          	ld	t1,0(a7)
                xReturn = pdTRUE;
    80001cc0:	4505                	li	a0,1
                    prvAddTaskToReadyList( pxMutexHolderTCB );
    80001cc2:	00259793          	slli	a5,a1,0x2
    80001cc6:	97ae                	add	a5,a5,a1
    80001cc8:	078e                	slli	a5,a5,0x3
    80001cca:	973e                	add	a4,a4,a5
    80001ccc:	6f30                	ld	a2,88(a4)
    80001cce:	05073803          	ld	a6,80(a4)
                    pxMutexHolderTCB->uxPriority = pxCurrentTCB->uxPriority;
    80001cd2:	ec2c                	sd	a1,88(s0)
                    prvAddTaskToReadyList( pxMutexHolderTCB );
    80001cd4:	01063e03          	ld	t3,16(a2)
    80001cd8:	00b696b3          	sll	a3,a3,a1
    80001cdc:	e810                	sd	a2,16(s0)
    80001cde:	01c43c23          	sd	t3,24(s0)
    80001ce2:	6a0c                	ld	a1,16(a2)
    80001ce4:	993e                	add	s2,s2,a5
    80001ce6:	0066e7b3          	or	a5,a3,t1
    80001cea:	0135b423          	sd	s3,8(a1)
    80001cee:	01363823          	sd	s3,16(a2)
    80001cf2:	03243423          	sd	s2,40(s0)
    80001cf6:	00180693          	addi	a3,a6,1
    80001cfa:	00f8b023          	sd	a5,0(a7)
    80001cfe:	eb34                	sd	a3,80(a4)
    80001d00:	b735                	j	80001c2c <xTaskPriorityInherit+0x2c>

0000000080001d02 <xTaskPriorityDisinherit>:
        if( pxMutexHolder != NULL )
    80001d02:	c129                	beqz	a0,80001d44 <xTaskPriorityDisinherit+0x42>
    {
    80001d04:	1101                	addi	sp,sp,-32
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e426                	sd	s1,8(sp)
            configASSERT( pxTCB == pxCurrentTCB );
    80001d0c:	00016797          	auipc	a5,0x16
    80001d10:	e447b783          	ld	a5,-444(a5) # 80017b50 <pxCurrentTCB>
    80001d14:	842a                	mv	s0,a0
    80001d16:	00a78563          	beq	a5,a0,80001d20 <xTaskPriorityDisinherit+0x1e>
    80001d1a:	30047073          	csrci	mstatus,8
    80001d1e:	a001                	j	80001d1e <xTaskPriorityDisinherit+0x1c>
            configASSERT( pxTCB->uxMutexesHeld );
    80001d20:	63dc                	ld	a5,128(a5)
    80001d22:	cf91                	beqz	a5,80001d3e <xTaskPriorityDisinherit+0x3c>
            if( pxTCB->uxPriority != pxTCB->uxBasePriority )
    80001d24:	6d34                	ld	a3,88(a0)
    80001d26:	7d38                	ld	a4,120(a0)
            ( pxTCB->uxMutexesHeld )--;
    80001d28:	17fd                	addi	a5,a5,-1
    80001d2a:	e15c                	sd	a5,128(a0)
            if( pxTCB->uxPriority != pxTCB->uxBasePriority )
    80001d2c:	00e68363          	beq	a3,a4,80001d32 <xTaskPriorityDisinherit+0x30>
                if( pxTCB->uxMutexesHeld == ( UBaseType_t ) 0 )
    80001d30:	cf81                	beqz	a5,80001d48 <xTaskPriorityDisinherit+0x46>
        BaseType_t xReturn = pdFALSE;
    80001d32:	4501                	li	a0,0
    }
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret
            configASSERT( pxTCB->uxMutexesHeld );
    80001d3e:	30047073          	csrci	mstatus,8
    80001d42:	a001                	j	80001d42 <xTaskPriorityDisinherit+0x40>
        BaseType_t xReturn = pdFALSE;
    80001d44:	4501                	li	a0,0
    }
    80001d46:	8082                	ret
                    if( uxListRemove( &( pxTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    80001d48:	00850493          	addi	s1,a0,8
    80001d4c:	8526                	mv	a0,s1
    80001d4e:	00001097          	auipc	ra,0x1
    80001d52:	8e2080e7          	jalr	-1822(ra) # 80002630 <uxListRemove>
    80001d56:	00016597          	auipc	a1,0x16
    80001d5a:	dca58593          	addi	a1,a1,-566 # 80017b20 <uxTopReadyPriority>
    80001d5e:	e911                	bnez	a0,80001d72 <xTaskPriorityDisinherit+0x70>
                        portRESET_READY_PRIORITY( pxTCB->uxPriority, uxTopReadyPriority );
    80001d60:	6c34                	ld	a3,88(s0)
    80001d62:	6198                	ld	a4,0(a1)
    80001d64:	4785                	li	a5,1
    80001d66:	00d797b3          	sll	a5,a5,a3
    80001d6a:	fff7c793          	not	a5,a5
    80001d6e:	8ff9                	and	a5,a5,a4
    80001d70:	e19c                	sd	a5,0(a1)
                    pxTCB->uxPriority = pxTCB->uxBasePriority;
    80001d72:	7c30                	ld	a2,120(s0)
                    prvAddTaskToReadyList( pxTCB );
    80001d74:	00005717          	auipc	a4,0x5
    80001d78:	afc70713          	addi	a4,a4,-1284 # 80006870 <xSuspendedTaskList>
                    listSET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ), ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) pxTCB->uxPriority );
    80001d7c:	4515                	li	a0,5
                    prvAddTaskToReadyList( pxTCB );
    80001d7e:	00261793          	slli	a5,a2,0x2
    80001d82:	97b2                	add	a5,a5,a2
    80001d84:	078e                	slli	a5,a5,0x3
    80001d86:	973e                	add	a4,a4,a5
    80001d88:	6f34                	ld	a3,88(a4)
                    listSET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ), ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) pxTCB->uxPriority );
    80001d8a:	8d11                	sub	a0,a0,a2
                    pxTCB->uxPriority = pxTCB->uxBasePriority;
    80001d8c:	ec30                	sd	a2,88(s0)
                    prvAddTaskToReadyList( pxTCB );
    80001d8e:	0106b803          	ld	a6,16(a3)
                    listSET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ), ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) pxTCB->uxPriority );
    80001d92:	f808                	sd	a0,48(s0)
                    prvAddTaskToReadyList( pxTCB );
    80001d94:	e814                	sd	a3,16(s0)
    80001d96:	01043c23          	sd	a6,24(s0)
    80001d9a:	0106b883          	ld	a7,16(a3)
    80001d9e:	6b28                	ld	a0,80(a4)
    80001da0:	0005b803          	ld	a6,0(a1)
    80001da4:	0098b423          	sd	s1,8(a7)
    80001da8:	ea84                	sd	s1,16(a3)
    80001daa:	4685                	li	a3,1
    80001dac:	00c696b3          	sll	a3,a3,a2
    80001db0:	00005617          	auipc	a2,0x5
    80001db4:	b1060613          	addi	a2,a2,-1264 # 800068c0 <pxReadyTasksLists>
    80001db8:	963e                	add	a2,a2,a5
    80001dba:	f410                	sd	a2,40(s0)
    80001dbc:	0106e7b3          	or	a5,a3,a6
    80001dc0:	00150693          	addi	a3,a0,1
    80001dc4:	e19c                	sd	a5,0(a1)
    80001dc6:	eb34                	sd	a3,80(a4)
                    xReturn = pdTRUE;
    80001dc8:	4505                	li	a0,1
        return xReturn;
    80001dca:	b7ad                	j	80001d34 <xTaskPriorityDisinherit+0x32>

0000000080001dcc <vTaskPriorityDisinheritAfterTimeout>:
        if( pxMutexHolder != NULL )
    80001dcc:	c565                	beqz	a0,80001eb4 <vTaskPriorityDisinheritAfterTimeout+0xe8>
            configASSERT( pxTCB->uxMutexesHeld );
    80001dce:	615c                	ld	a5,128(a0)
    {
    80001dd0:	7179                	addi	sp,sp,-48
    80001dd2:	f022                	sd	s0,32(sp)
    80001dd4:	f406                	sd	ra,40(sp)
    80001dd6:	ec26                	sd	s1,24(sp)
    80001dd8:	e84a                	sd	s2,16(sp)
    80001dda:	e44e                	sd	s3,8(sp)
    80001ddc:	842a                	mv	s0,a0
            configASSERT( pxTCB->uxMutexesHeld );
    80001dde:	e781                	bnez	a5,80001de6 <vTaskPriorityDisinheritAfterTimeout+0x1a>
    80001de0:	30047073          	csrci	mstatus,8
    80001de4:	a001                	j	80001de4 <vTaskPriorityDisinheritAfterTimeout+0x18>
            if( pxTCB->uxBasePriority < uxHighestPriorityWaitingTask )
    80001de6:	7d38                	ld	a4,120(a0)
    80001de8:	00b76f63          	bltu	a4,a1,80001e06 <vTaskPriorityDisinheritAfterTimeout+0x3a>
            if( pxTCB->uxPriority != uxPriorityToUse )
    80001dec:	6c24                	ld	s1,88(s0)
    80001dee:	00e48563          	beq	s1,a4,80001df8 <vTaskPriorityDisinheritAfterTimeout+0x2c>
                if( pxTCB->uxMutexesHeld == uxOnlyOneMutexHeld )
    80001df2:	4685                	li	a3,1
    80001df4:	00d78b63          	beq	a5,a3,80001e0a <vTaskPriorityDisinheritAfterTimeout+0x3e>
    }
    80001df8:	70a2                	ld	ra,40(sp)
    80001dfa:	7402                	ld	s0,32(sp)
    80001dfc:	64e2                	ld	s1,24(sp)
    80001dfe:	6942                	ld	s2,16(sp)
    80001e00:	69a2                	ld	s3,8(sp)
    80001e02:	6145                	addi	sp,sp,48
    80001e04:	8082                	ret
    80001e06:	872e                	mv	a4,a1
    80001e08:	b7d5                	j	80001dec <vTaskPriorityDisinheritAfterTimeout+0x20>
                    configASSERT( pxTCB != pxCurrentTCB );
    80001e0a:	00016697          	auipc	a3,0x16
    80001e0e:	d466b683          	ld	a3,-698(a3) # 80017b50 <pxCurrentTCB>
    80001e12:	0a868263          	beq	a3,s0,80001eb6 <vTaskPriorityDisinheritAfterTimeout+0xea>
                    if( ( listGET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ) ) & taskEVENT_LIST_ITEM_VALUE_IN_USE ) == ( ( TickType_t ) 0U ) )
    80001e16:	7814                	ld	a3,48(s0)
    80001e18:	07fe                	slli	a5,a5,0x1f
                    pxTCB->uxPriority = uxPriorityToUse;
    80001e1a:	ec38                	sd	a4,88(s0)
                    if( ( listGET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ) ) & taskEVENT_LIST_ITEM_VALUE_IN_USE ) == ( ( TickType_t ) 0U ) )
    80001e1c:	8ff5                	and	a5,a5,a3
    80001e1e:	e781                	bnez	a5,80001e26 <vTaskPriorityDisinheritAfterTimeout+0x5a>
                        listSET_LIST_ITEM_VALUE( &( pxTCB->xEventListItem ), ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) uxPriorityToUse );
    80001e20:	4795                	li	a5,5
    80001e22:	8f99                	sub	a5,a5,a4
    80001e24:	f81c                	sd	a5,48(s0)
                    if( listIS_CONTAINED_WITHIN( &( pxReadyTasksLists[ uxPriorityUsedOnEntry ] ), &( pxTCB->xStateListItem ) ) != pdFALSE )
    80001e26:	00249793          	slli	a5,s1,0x2
    80001e2a:	97a6                	add	a5,a5,s1
    80001e2c:	7418                	ld	a4,40(s0)
    80001e2e:	00005917          	auipc	s2,0x5
    80001e32:	a9290913          	addi	s2,s2,-1390 # 800068c0 <pxReadyTasksLists>
    80001e36:	078e                	slli	a5,a5,0x3
    80001e38:	97ca                	add	a5,a5,s2
    80001e3a:	faf71fe3          	bne	a4,a5,80001df8 <vTaskPriorityDisinheritAfterTimeout+0x2c>
                        if( uxListRemove( &( pxTCB->xStateListItem ) ) == ( UBaseType_t ) 0 )
    80001e3e:	00840993          	addi	s3,s0,8
    80001e42:	854e                	mv	a0,s3
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	7ec080e7          	jalr	2028(ra) # 80002630 <uxListRemove>
    80001e4c:	00016617          	auipc	a2,0x16
    80001e50:	cd460613          	addi	a2,a2,-812 # 80017b20 <uxTopReadyPriority>
    80001e54:	e909                	bnez	a0,80001e66 <vTaskPriorityDisinheritAfterTimeout+0x9a>
                            portRESET_READY_PRIORITY( uxPriorityUsedOnEntry, uxTopReadyPriority );
    80001e56:	6218                	ld	a4,0(a2)
    80001e58:	4785                	li	a5,1
    80001e5a:	009797b3          	sll	a5,a5,s1
    80001e5e:	fff7c793          	not	a5,a5
    80001e62:	8ff9                	and	a5,a5,a4
    80001e64:	e21c                	sd	a5,0(a2)
                        prvAddTaskToReadyList( pxTCB );
    80001e66:	05843803          	ld	a6,88(s0)
    80001e6a:	00005717          	auipc	a4,0x5
    80001e6e:	a0670713          	addi	a4,a4,-1530 # 80006870 <xSuspendedTaskList>
    80001e72:	4685                	li	a3,1
    80001e74:	00281793          	slli	a5,a6,0x2
    80001e78:	97c2                	add	a5,a5,a6
    80001e7a:	078e                	slli	a5,a5,0x3
    80001e7c:	973e                	add	a4,a4,a5
    80001e7e:	6f2c                	ld	a1,88(a4)
    80001e80:	6b28                	ld	a0,80(a4)
    80001e82:	010696b3          	sll	a3,a3,a6
    80001e86:	0105b303          	ld	t1,16(a1)
    80001e8a:	00063883          	ld	a7,0(a2)
    80001e8e:	e80c                	sd	a1,16(s0)
    80001e90:	00643c23          	sd	t1,24(s0)
    80001e94:	0105b803          	ld	a6,16(a1)
    80001e98:	993e                	add	s2,s2,a5
    80001e9a:	0116e7b3          	or	a5,a3,a7
    80001e9e:	01383423          	sd	s3,8(a6)
    80001ea2:	0135b823          	sd	s3,16(a1)
    80001ea6:	03243423          	sd	s2,40(s0)
    80001eaa:	00150693          	addi	a3,a0,1
    80001eae:	e21c                	sd	a5,0(a2)
    80001eb0:	eb34                	sd	a3,80(a4)
    }
    80001eb2:	b799                	j	80001df8 <vTaskPriorityDisinheritAfterTimeout+0x2c>
    80001eb4:	8082                	ret
                    configASSERT( pxTCB != pxCurrentTCB );
    80001eb6:	30047073          	csrci	mstatus,8
    80001eba:	a001                	j	80001eba <vTaskPriorityDisinheritAfterTimeout+0xee>

0000000080001ebc <uxTaskResetEventItemValue>:
    uxReturn = listGET_LIST_ITEM_VALUE( &( pxCurrentTCB->xEventListItem ) );
    80001ebc:	00016797          	auipc	a5,0x16
    80001ec0:	c9478793          	addi	a5,a5,-876 # 80017b50 <pxCurrentTCB>
    80001ec4:	6390                	ld	a2,0(a5)
    listSET_LIST_ITEM_VALUE( &( pxCurrentTCB->xEventListItem ), ( ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) pxCurrentTCB->uxPriority ) );
    80001ec6:	6394                	ld	a3,0(a5)
    80001ec8:	6398                	ld	a4,0(a5)
    80001eca:	4795                	li	a5,5
    80001ecc:	6eb4                	ld	a3,88(a3)
    uxReturn = listGET_LIST_ITEM_VALUE( &( pxCurrentTCB->xEventListItem ) );
    80001ece:	7a08                	ld	a0,48(a2)
    listSET_LIST_ITEM_VALUE( &( pxCurrentTCB->xEventListItem ), ( ( TickType_t ) configMAX_PRIORITIES - ( TickType_t ) pxCurrentTCB->uxPriority ) );
    80001ed0:	8f95                	sub	a5,a5,a3
    80001ed2:	fb1c                	sd	a5,48(a4)
}
    80001ed4:	8082                	ret

0000000080001ed6 <pvTaskIncrementMutexHeldCount>:
        pxTCB = pxCurrentTCB;
    80001ed6:	00016517          	auipc	a0,0x16
    80001eda:	c7a53503          	ld	a0,-902(a0) # 80017b50 <pxCurrentTCB>
        if( pxTCB != NULL )
    80001ede:	c501                	beqz	a0,80001ee6 <pvTaskIncrementMutexHeldCount+0x10>
            ( pxTCB->uxMutexesHeld )++;
    80001ee0:	615c                	ld	a5,128(a0)
    80001ee2:	0785                	addi	a5,a5,1
    80001ee4:	e15c                	sd	a5,128(a0)
    }
    80001ee6:	8082                	ret

0000000080001ee8 <ulTaskGenericNotifyTake>:
        configASSERT( uxIndexToWaitOn < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    80001ee8:	c501                	beqz	a0,80001ef0 <ulTaskGenericNotifyTake+0x8>
    80001eea:	30047073          	csrci	mstatus,8
    80001eee:	a001                	j	80001eee <ulTaskGenericNotifyTake+0x6>
    {
    80001ef0:	7179                	addi	sp,sp,-48
    80001ef2:	ec26                	sd	s1,24(sp)
        if( ( pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] == 0U ) && ( xTicksToWait > ( TickType_t ) 0 ) )
    80001ef4:	00016497          	auipc	s1,0x16
    80001ef8:	c5c48493          	addi	s1,s1,-932 # 80017b50 <pxCurrentTCB>
    80001efc:	609c                	ld	a5,0(s1)
    {
    80001efe:	f022                	sd	s0,32(sp)
    80001f00:	f406                	sd	ra,40(sp)
        if( ( pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] == 0U ) && ( xTicksToWait > ( TickType_t ) 0 ) )
    80001f02:	0887a783          	lw	a5,136(a5)
    {
    80001f06:	e84a                	sd	s2,16(sp)
    80001f08:	e44e                	sd	s3,8(sp)
    80001f0a:	e052                	sd	s4,0(sp)
    80001f0c:	842e                	mv	s0,a1
        if( ( pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] == 0U ) && ( xTicksToWait > ( TickType_t ) 0 ) )
    80001f0e:	c3a9                	beqz	a5,80001f50 <ulTaskGenericNotifyTake+0x68>
    80001f10:	00005917          	auipc	s2,0x5
    80001f14:	95090913          	addi	s2,s2,-1712 # 80006860 <xCriticalNesting>
        taskENTER_CRITICAL();
    80001f18:	30047073          	csrci	mstatus,8
            ulReturn = pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ];
    80001f1c:	609c                	ld	a5,0(s1)
        taskENTER_CRITICAL();
    80001f1e:	00093703          	ld	a4,0(s2)
            ulReturn = pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ];
    80001f22:	0887a783          	lw	a5,136(a5)
    80001f26:	0007851b          	sext.w	a0,a5
            if( ulReturn != 0U )
    80001f2a:	c789                	beqz	a5,80001f34 <ulTaskGenericNotifyTake+0x4c>
                    pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] = ( uint32_t ) 0U;
    80001f2c:	609c                	ld	a5,0(s1)
                if( xClearCountOnExit != pdFALSE )
    80001f2e:	c051                	beqz	s0,80001fb2 <ulTaskGenericNotifyTake+0xca>
                    pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] = ( uint32_t ) 0U;
    80001f30:	0807a423          	sw	zero,136(a5)
            pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] = taskNOT_WAITING_NOTIFICATION;
    80001f34:	609c                	ld	a5,0(s1)
    80001f36:	08078623          	sb	zero,140(a5)
        taskEXIT_CRITICAL();
    80001f3a:	e319                	bnez	a4,80001f40 <ulTaskGenericNotifyTake+0x58>
    80001f3c:	30046073          	csrsi	mstatus,8
    }
    80001f40:	70a2                	ld	ra,40(sp)
    80001f42:	7402                	ld	s0,32(sp)
    80001f44:	64e2                	ld	s1,24(sp)
    80001f46:	6942                	ld	s2,16(sp)
    80001f48:	69a2                	ld	s3,8(sp)
    80001f4a:	6a02                	ld	s4,0(sp)
    80001f4c:	6145                	addi	sp,sp,48
    80001f4e:	8082                	ret
        if( ( pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] == 0U ) && ( xTicksToWait > ( TickType_t ) 0 ) )
    80001f50:	d261                	beqz	a2,80001f10 <ulTaskGenericNotifyTake+0x28>
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    80001f52:	00016997          	auipc	s3,0x16
    80001f56:	b8e98993          	addi	s3,s3,-1138 # 80017ae0 <uxSchedulerSuspended>
    80001f5a:	0009b783          	ld	a5,0(s3)
    80001f5e:	0785                	addi	a5,a5,1
    80001f60:	00f9b023          	sd	a5,0(s3)
                taskENTER_CRITICAL();
    80001f64:	30047073          	csrci	mstatus,8
                    if( pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] == 0U )
    80001f68:	6098                	ld	a4,0(s1)
                taskENTER_CRITICAL();
    80001f6a:	00005917          	auipc	s2,0x5
    80001f6e:	8f690913          	addi	s2,s2,-1802 # 80006860 <xCriticalNesting>
    80001f72:	00093783          	ld	a5,0(s2)
                    if( pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] == 0U )
    80001f76:	08872703          	lw	a4,136(a4)
    80001f7a:	e329                	bnez	a4,80001fbc <ulTaskGenericNotifyTake+0xd4>
                        pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] = taskWAITING_NOTIFICATION;
    80001f7c:	6098                	ld	a4,0(s1)
    80001f7e:	4685                	li	a3,1
    80001f80:	08d70623          	sb	a3,140(a4)
                taskEXIT_CRITICAL();
    80001f84:	e399                	bnez	a5,80001f8a <ulTaskGenericNotifyTake+0xa2>
    80001f86:	30046073          	csrsi	mstatus,8
                    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
    80001f8a:	4585                	li	a1,1
    80001f8c:	8532                	mv	a0,a2
    80001f8e:	ffffe097          	auipc	ra,0xffffe
    80001f92:	6a4080e7          	jalr	1700(ra) # 80000632 <prvAddCurrentTaskToDelayedList>
    80001f96:	4a05                	li	s4,1
        taskENTER_CRITICAL();
    80001f98:	30047073          	csrci	mstatus,8
    80001f9c:	00093783          	ld	a5,0(s2)
            configASSERT( uxSchedulerSuspended != 0U );
    80001fa0:	0009b703          	ld	a4,0(s3)
        taskENTER_CRITICAL();
    80001fa4:	0785                	addi	a5,a5,1
    80001fa6:	00f93023          	sd	a5,0(s2)
            configASSERT( uxSchedulerSuspended != 0U );
    80001faa:	ef19                	bnez	a4,80001fc8 <ulTaskGenericNotifyTake+0xe0>
    80001fac:	30047073          	csrci	mstatus,8
    80001fb0:	a001                	j	80001fb0 <ulTaskGenericNotifyTake+0xc8>
                    pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] = ulReturn - ( uint32_t ) 1;
    80001fb2:	fff5069b          	addiw	a3,a0,-1
    80001fb6:	08d7a423          	sw	a3,136(a5)
    80001fba:	bfad                	j	80001f34 <ulTaskGenericNotifyTake+0x4c>
        BaseType_t xAlreadyYielded, xShouldBlock = pdFALSE;
    80001fbc:	4a01                	li	s4,0
                taskEXIT_CRITICAL();
    80001fbe:	ffe9                	bnez	a5,80001f98 <ulTaskGenericNotifyTake+0xb0>
    80001fc0:	30046073          	csrsi	mstatus,8
        BaseType_t xAlreadyYielded, xShouldBlock = pdFALSE;
    80001fc4:	4a01                	li	s4,0
    80001fc6:	bfc9                	j	80001f98 <ulTaskGenericNotifyTake+0xb0>
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	9ea080e7          	jalr	-1558(ra) # 800009b2 <xTaskResumeAll.part.0>
            if( ( xShouldBlock == pdTRUE ) && ( xAlreadyYielded == pdFALSE ) )
    80001fd0:	f40a04e3          	beqz	s4,80001f18 <ulTaskGenericNotifyTake+0x30>
    80001fd4:	f131                	bnez	a0,80001f18 <ulTaskGenericNotifyTake+0x30>
                taskYIELD_WITHIN_API();
    80001fd6:	00000073          	ecall
    80001fda:	bf3d                	j	80001f18 <ulTaskGenericNotifyTake+0x30>

0000000080001fdc <xTaskGenericNotifyWait>:
        configASSERT( uxIndexToWaitOn < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    80001fdc:	c501                	beqz	a0,80001fe4 <xTaskGenericNotifyWait+0x8>
    80001fde:	30047073          	csrci	mstatus,8
    80001fe2:	a001                	j	80001fe2 <xTaskGenericNotifyWait+0x6>
    {
    80001fe4:	7139                	addi	sp,sp,-64
    80001fe6:	f822                	sd	s0,48(sp)
        if( ( pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] != taskNOTIFICATION_RECEIVED ) && ( xTicksToWait > ( TickType_t ) 0 ) )
    80001fe8:	00016417          	auipc	s0,0x16
    80001fec:	b6840413          	addi	s0,s0,-1176 # 80017b50 <pxCurrentTCB>
    80001ff0:	6008                	ld	a0,0(s0)
    {
    80001ff2:	fc06                	sd	ra,56(sp)
    80001ff4:	f426                	sd	s1,40(sp)
    80001ff6:	f04a                	sd	s2,32(sp)
    80001ff8:	ec4e                	sd	s3,24(sp)
        if( ( pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] != taskNOTIFICATION_RECEIVED ) && ( xTicksToWait > ( TickType_t ) 0 ) )
    80001ffa:	08c54503          	lbu	a0,140(a0)
    80001ffe:	4789                	li	a5,2
    80002000:	00f50363          	beq	a0,a5,80002006 <xTaskGenericNotifyWait+0x2a>
    80002004:	eb39                	bnez	a4,8000205a <xTaskGenericNotifyWait+0x7e>
    80002006:	00005497          	auipc	s1,0x5
    8000200a:	85a48493          	addi	s1,s1,-1958 # 80006860 <xCriticalNesting>
        taskENTER_CRITICAL();
    8000200e:	30047073          	csrci	mstatus,8
    80002012:	609c                	ld	a5,0(s1)
            if( pulNotificationValue != NULL )
    80002014:	c689                	beqz	a3,8000201e <xTaskGenericNotifyWait+0x42>
                *pulNotificationValue = pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ];
    80002016:	6018                	ld	a4,0(s0)
    80002018:	08872703          	lw	a4,136(a4)
    8000201c:	c298                	sw	a4,0(a3)
            if( pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] != taskNOTIFICATION_RECEIVED )
    8000201e:	6014                	ld	a3,0(s0)
    80002020:	4709                	li	a4,2
                xReturn = pdFALSE;
    80002022:	4501                	li	a0,0
            if( pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] != taskNOTIFICATION_RECEIVED )
    80002024:	08c6c683          	lbu	a3,140(a3)
    80002028:	00e69b63          	bne	a3,a4,8000203e <xTaskGenericNotifyWait+0x62>
                pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] &= ~ulBitsToClearOnExit;
    8000202c:	6014                	ld	a3,0(s0)
    8000202e:	fff64613          	not	a2,a2
                xReturn = pdTRUE;
    80002032:	4505                	li	a0,1
                pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] &= ~ulBitsToClearOnExit;
    80002034:	0886a703          	lw	a4,136(a3)
    80002038:	8f71                	and	a4,a4,a2
    8000203a:	08e6a423          	sw	a4,136(a3)
            pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] = taskNOT_WAITING_NOTIFICATION;
    8000203e:	6018                	ld	a4,0(s0)
        taskEXIT_CRITICAL();
    80002040:	e09c                	sd	a5,0(s1)
            pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] = taskNOT_WAITING_NOTIFICATION;
    80002042:	08070623          	sb	zero,140(a4)
        taskEXIT_CRITICAL();
    80002046:	e399                	bnez	a5,8000204c <xTaskGenericNotifyWait+0x70>
    80002048:	30046073          	csrsi	mstatus,8
    }
    8000204c:	70e2                	ld	ra,56(sp)
    8000204e:	7442                	ld	s0,48(sp)
    80002050:	74a2                	ld	s1,40(sp)
    80002052:	7902                	ld	s2,32(sp)
    80002054:	69e2                	ld	s3,24(sp)
    80002056:	6121                	addi	sp,sp,64
    80002058:	8082                	ret
        uxSchedulerSuspended = ( UBaseType_t ) ( uxSchedulerSuspended + 1U );
    8000205a:	00016917          	auipc	s2,0x16
    8000205e:	a8690913          	addi	s2,s2,-1402 # 80017ae0 <uxSchedulerSuspended>
    80002062:	00093503          	ld	a0,0(s2)
    80002066:	0505                	addi	a0,a0,1
    80002068:	00a93023          	sd	a0,0(s2)
                taskENTER_CRITICAL();
    8000206c:	30047073          	csrci	mstatus,8
                    if( pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] != taskNOTIFICATION_RECEIVED )
    80002070:	00043803          	ld	a6,0(s0)
                taskENTER_CRITICAL();
    80002074:	00004497          	auipc	s1,0x4
    80002078:	7ec48493          	addi	s1,s1,2028 # 80006860 <xCriticalNesting>
    8000207c:	6088                	ld	a0,0(s1)
                    if( pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] != taskNOTIFICATION_RECEIVED )
    8000207e:	08c84803          	lbu	a6,140(a6)
    80002082:	06f80663          	beq	a6,a5,800020ee <xTaskGenericNotifyWait+0x112>
                        pxCurrentTCB->ulNotifiedValue[ uxIndexToWaitOn ] &= ~ulBitsToClearOnEntry;
    80002086:	00043803          	ld	a6,0(s0)
    8000208a:	fff5c593          	not	a1,a1
    8000208e:	08882783          	lw	a5,136(a6)
    80002092:	8fed                	and	a5,a5,a1
    80002094:	08f82423          	sw	a5,136(a6)
                        pxCurrentTCB->ucNotifyState[ uxIndexToWaitOn ] = taskWAITING_NOTIFICATION;
    80002098:	601c                	ld	a5,0(s0)
    8000209a:	4585                	li	a1,1
    8000209c:	08b78623          	sb	a1,140(a5)
                taskEXIT_CRITICAL();
    800020a0:	e119                	bnez	a0,800020a6 <xTaskGenericNotifyWait+0xca>
    800020a2:	30046073          	csrsi	mstatus,8
                    prvAddCurrentTaskToDelayedList( xTicksToWait, pdTRUE );
    800020a6:	4585                	li	a1,1
    800020a8:	853a                	mv	a0,a4
    800020aa:	e436                	sd	a3,8(sp)
    800020ac:	e032                	sd	a2,0(sp)
    800020ae:	ffffe097          	auipc	ra,0xffffe
    800020b2:	584080e7          	jalr	1412(ra) # 80000632 <prvAddCurrentTaskToDelayedList>
    800020b6:	66a2                	ld	a3,8(sp)
    800020b8:	6602                	ld	a2,0(sp)
    800020ba:	4985                	li	s3,1
        taskENTER_CRITICAL();
    800020bc:	30047073          	csrci	mstatus,8
    800020c0:	609c                	ld	a5,0(s1)
            configASSERT( uxSchedulerSuspended != 0U );
    800020c2:	00093703          	ld	a4,0(s2)
        taskENTER_CRITICAL();
    800020c6:	0785                	addi	a5,a5,1
    800020c8:	e09c                	sd	a5,0(s1)
            configASSERT( uxSchedulerSuspended != 0U );
    800020ca:	e701                	bnez	a4,800020d2 <xTaskGenericNotifyWait+0xf6>
    800020cc:	30047073          	csrci	mstatus,8
    800020d0:	a001                	j	800020d0 <xTaskGenericNotifyWait+0xf4>
    800020d2:	e436                	sd	a3,8(sp)
    800020d4:	e032                	sd	a2,0(sp)
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	8dc080e7          	jalr	-1828(ra) # 800009b2 <xTaskResumeAll.part.0>
            if( ( xShouldBlock == pdTRUE ) && ( xAlreadyYielded == pdFALSE ) )
    800020de:	6602                	ld	a2,0(sp)
    800020e0:	66a2                	ld	a3,8(sp)
    800020e2:	f20986e3          	beqz	s3,8000200e <xTaskGenericNotifyWait+0x32>
    800020e6:	f505                	bnez	a0,8000200e <xTaskGenericNotifyWait+0x32>
                taskYIELD_WITHIN_API();
    800020e8:	00000073          	ecall
    800020ec:	b70d                	j	8000200e <xTaskGenericNotifyWait+0x32>
                taskEXIT_CRITICAL();
    800020ee:	c119                	beqz	a0,800020f4 <xTaskGenericNotifyWait+0x118>
        BaseType_t xReturn, xAlreadyYielded, xShouldBlock = pdFALSE;
    800020f0:	4981                	li	s3,0
    800020f2:	b7e9                	j	800020bc <xTaskGenericNotifyWait+0xe0>
                taskEXIT_CRITICAL();
    800020f4:	30046073          	csrsi	mstatus,8
        BaseType_t xReturn, xAlreadyYielded, xShouldBlock = pdFALSE;
    800020f8:	4981                	li	s3,0
    800020fa:	b7c9                	j	800020bc <xTaskGenericNotifyWait+0xe0>

00000000800020fc <xTaskGenericNotify>:
    {
    800020fc:	87aa                	mv	a5,a0
        configASSERT( uxIndexToNotify < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    800020fe:	c581                	beqz	a1,80002106 <xTaskGenericNotify+0xa>
    80002100:	30047073          	csrci	mstatus,8
    80002104:	a001                	j	80002104 <xTaskGenericNotify+0x8>
        configASSERT( xTaskToNotify );
    80002106:	c52d                	beqz	a0,80002170 <xTaskGenericNotify+0x74>
        taskENTER_CRITICAL();
    80002108:	30047073          	csrci	mstatus,8
    8000210c:	00004897          	auipc	a7,0x4
    80002110:	75488893          	addi	a7,a7,1876 # 80006860 <xCriticalNesting>
    80002114:	0008b803          	ld	a6,0(a7)
    80002118:	00180593          	addi	a1,a6,1
    8000211c:	00b8b023          	sd	a1,0(a7)
            if( pulPreviousNotificationValue != NULL )
    80002120:	c701                	beqz	a4,80002128 <xTaskGenericNotify+0x2c>
                *pulPreviousNotificationValue = pxTCB->ulNotifiedValue[ uxIndexToNotify ];
    80002122:	08852583          	lw	a1,136(a0)
    80002126:	c30c                	sw	a1,0(a4)
            ucOriginalNotifyState = pxTCB->ucNotifyState[ uxIndexToNotify ];
    80002128:	08c7c583          	lbu	a1,140(a5)
            pxTCB->ucNotifyState[ uxIndexToNotify ] = taskNOTIFICATION_RECEIVED;
    8000212c:	4709                	li	a4,2
    8000212e:	08e78623          	sb	a4,140(a5)
            switch( eAction )
    80002132:	4711                	li	a4,4
            ucOriginalNotifyState = pxTCB->ucNotifyState[ uxIndexToNotify ];
    80002134:	0ff5f593          	zext.b	a1,a1
            switch( eAction )
    80002138:	0cd76e63          	bltu	a4,a3,80002214 <xTaskGenericNotify+0x118>
    8000213c:	00004517          	auipc	a0,0x4
    80002140:	d9c50513          	addi	a0,a0,-612 # 80005ed8 <main+0x146>
    80002144:	068a                	slli	a3,a3,0x2
    80002146:	00a68733          	add	a4,a3,a0
    8000214a:	4318                	lw	a4,0(a4)
    8000214c:	972a                	add	a4,a4,a0
    8000214e:	8702                	jr	a4
                    if( ucOriginalNotifyState != taskNOTIFICATION_RECEIVED )
    80002150:	4709                	li	a4,2
    80002152:	0ce58963          	beq	a1,a4,80002224 <xTaskGenericNotify+0x128>
                        pxTCB->ulNotifiedValue[ uxIndexToNotify ] = ulValue;
    80002156:	08c7a423          	sw	a2,136(a5)
            if( ucOriginalNotifyState == taskWAITING_NOTIFICATION )
    8000215a:	4705                	li	a4,1
    8000215c:	4505                	li	a0,1
    8000215e:	00e58c63          	beq	a1,a4,80002176 <xTaskGenericNotify+0x7a>
        taskEXIT_CRITICAL();
    80002162:	0108b023          	sd	a6,0(a7)
    80002166:	00081463          	bnez	a6,8000216e <xTaskGenericNotify+0x72>
    8000216a:	30046073          	csrsi	mstatus,8
    }
    8000216e:	8082                	ret
        configASSERT( xTaskToNotify );
    80002170:	30047073          	csrci	mstatus,8
    80002174:	a001                	j	80002174 <xTaskGenericNotify+0x78>
                listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80002176:	6f94                	ld	a3,24(a5)
    80002178:	6b98                	ld	a4,16(a5)
    8000217a:	7788                	ld	a0,40(a5)
    8000217c:	00878313          	addi	t1,a5,8
    80002180:	eb14                	sd	a3,16(a4)
    80002182:	6f94                	ld	a3,24(a5)
    80002184:	6510                	ld	a2,8(a0)
    80002186:	e698                	sd	a4,8(a3)
    80002188:	0a660e63          	beq	a2,t1,80002244 <xTaskGenericNotify+0x148>
                prvAddTaskToReadyList( pxTCB );
    8000218c:	6fac                	ld	a1,88(a5)
    8000218e:	00004697          	auipc	a3,0x4
    80002192:	6e268693          	addi	a3,a3,1762 # 80006870 <xSuspendedTaskList>
                listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80002196:	00053e03          	ld	t3,0(a0)
                prvAddTaskToReadyList( pxTCB );
    8000219a:	00259713          	slli	a4,a1,0x2
    8000219e:	972e                	add	a4,a4,a1
    800021a0:	070e                	slli	a4,a4,0x3
    800021a2:	96ba                	add	a3,a3,a4
    800021a4:	6eb0                	ld	a2,88(a3)
                listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    800021a6:	1e7d                	addi	t3,t3,-1
    800021a8:	01c53023          	sd	t3,0(a0)
                prvAddTaskToReadyList( pxTCB );
    800021ac:	6a08                	ld	a0,16(a2)
    800021ae:	00016e17          	auipc	t3,0x16
    800021b2:	972e0e13          	addi	t3,t3,-1678 # 80017b20 <uxTopReadyPriority>
    800021b6:	eb90                	sd	a2,16(a5)
    800021b8:	ef88                	sd	a0,24(a5)
    800021ba:	01063e83          	ld	t4,16(a2)
    800021be:	6aa8                	ld	a0,80(a3)
    800021c0:	000e3f03          	ld	t5,0(t3)
    800021c4:	006eb423          	sd	t1,8(t4)
    800021c8:	00663823          	sd	t1,16(a2)
    800021cc:	4605                	li	a2,1
    800021ce:	00004317          	auipc	t1,0x4
    800021d2:	6f230313          	addi	t1,t1,1778 # 800068c0 <pxReadyTasksLists>
                configASSERT( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) == NULL );
    800021d6:	0507be83          	ld	t4,80(a5)
                prvAddTaskToReadyList( pxTCB );
    800021da:	933a                	add	t1,t1,a4
    800021dc:	00b61633          	sll	a2,a2,a1
    800021e0:	0267b423          	sd	t1,40(a5)
    800021e4:	01e66733          	or	a4,a2,t5
    800021e8:	00150793          	addi	a5,a0,1
    800021ec:	00ee3023          	sd	a4,0(t3)
    800021f0:	eabc                	sd	a5,80(a3)
                configASSERT( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) == NULL );
    800021f2:	020e8b63          	beqz	t4,80002228 <xTaskGenericNotify+0x12c>
    800021f6:	30047073          	csrci	mstatus,8
    800021fa:	a001                	j	800021fa <xTaskGenericNotify+0xfe>
                    ( pxTCB->ulNotifiedValue[ uxIndexToNotify ] )++;
    800021fc:	0887a703          	lw	a4,136(a5)
    80002200:	2705                	addiw	a4,a4,1
    80002202:	08e7a423          	sw	a4,136(a5)
                    break;
    80002206:	bf91                	j	8000215a <xTaskGenericNotify+0x5e>
                    pxTCB->ulNotifiedValue[ uxIndexToNotify ] |= ulValue;
    80002208:	0887a703          	lw	a4,136(a5)
    8000220c:	8f51                	or	a4,a4,a2
    8000220e:	08e7a423          	sw	a4,136(a5)
                    break;
    80002212:	b7a1                	j	8000215a <xTaskGenericNotify+0x5e>
                    configASSERT( xTickCount == ( TickType_t ) 0 );
    80002214:	00016717          	auipc	a4,0x16
    80002218:	91473703          	ld	a4,-1772(a4) # 80017b28 <xTickCount>
    8000221c:	df1d                	beqz	a4,8000215a <xTaskGenericNotify+0x5e>
    8000221e:	30047073          	csrci	mstatus,8
    80002222:	a001                	j	80002222 <xTaskGenericNotify+0x126>
                        xReturn = pdFAIL;
    80002224:	4501                	li	a0,0
    80002226:	bf35                	j	80002162 <xTaskGenericNotify+0x66>
                taskYIELD_ANY_CORE_IF_USING_PREEMPTION( pxTCB );
    80002228:	00016797          	auipc	a5,0x16
    8000222c:	9287b783          	ld	a5,-1752(a5) # 80017b50 <pxCurrentTCB>
    80002230:	6fbc                	ld	a5,88(a5)
    80002232:	4505                	li	a0,1
    80002234:	f2b7f7e3          	bgeu	a5,a1,80002162 <xTaskGenericNotify+0x66>
    80002238:	00000073          	ecall
        taskEXIT_CRITICAL();
    8000223c:	0008b803          	ld	a6,0(a7)
    80002240:	187d                	addi	a6,a6,-1
    80002242:	b705                	j	80002162 <xTaskGenericNotify+0x66>
                listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80002244:	e514                	sd	a3,8(a0)
    80002246:	b799                	j	8000218c <xTaskGenericNotify+0x90>

0000000080002248 <xTaskGenericNotifyFromISR>:
        configASSERT( xTaskToNotify );
    80002248:	c539                	beqz	a0,80002296 <xTaskGenericNotifyFromISR+0x4e>
        configASSERT( uxIndexToNotify < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    8000224a:	e98d                	bnez	a1,8000227c <xTaskGenericNotifyFromISR+0x34>
            if( pulPreviousNotificationValue != NULL )
    8000224c:	c701                	beqz	a4,80002254 <xTaskGenericNotifyFromISR+0xc>
                *pulPreviousNotificationValue = pxTCB->ulNotifiedValue[ uxIndexToNotify ];
    8000224e:	08852583          	lw	a1,136(a0)
    80002252:	c30c                	sw	a1,0(a4)
            ucOriginalNotifyState = pxTCB->ucNotifyState[ uxIndexToNotify ];
    80002254:	08c54583          	lbu	a1,140(a0)
            pxTCB->ucNotifyState[ uxIndexToNotify ] = taskNOTIFICATION_RECEIVED;
    80002258:	4709                	li	a4,2
    8000225a:	08e50623          	sb	a4,140(a0)
            switch( eAction )
    8000225e:	4711                	li	a4,4
            ucOriginalNotifyState = pxTCB->ucNotifyState[ uxIndexToNotify ];
    80002260:	0ff5f593          	zext.b	a1,a1
            switch( eAction )
    80002264:	04d76d63          	bltu	a4,a3,800022be <xTaskGenericNotifyFromISR+0x76>
    80002268:	00004817          	auipc	a6,0x4
    8000226c:	c8480813          	addi	a6,a6,-892 # 80005eec <main+0x15a>
    80002270:	068a                	slli	a3,a3,0x2
    80002272:	01068733          	add	a4,a3,a6
    80002276:	4318                	lw	a4,0(a4)
    80002278:	9742                	add	a4,a4,a6
    8000227a:	8702                	jr	a4
        configASSERT( uxIndexToNotify < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    8000227c:	30047073          	csrci	mstatus,8
    80002280:	a001                	j	80002280 <xTaskGenericNotifyFromISR+0x38>
                    if( ucOriginalNotifyState != taskNOTIFICATION_RECEIVED )
    80002282:	4709                	li	a4,2
    80002284:	04e58563          	beq	a1,a4,800022ce <xTaskGenericNotifyFromISR+0x86>
                        pxTCB->ulNotifiedValue[ uxIndexToNotify ] = ulValue;
    80002288:	08c52423          	sw	a2,136(a0)
            if( ucOriginalNotifyState == taskWAITING_NOTIFICATION )
    8000228c:	4705                	li	a4,1
    8000228e:	00e58763          	beq	a1,a4,8000229c <xTaskGenericNotifyFromISR+0x54>
    80002292:	4505                	li	a0,1
    80002294:	8082                	ret
        configASSERT( xTaskToNotify );
    80002296:	30047073          	csrci	mstatus,8
    8000229a:	a001                	j	8000229a <xTaskGenericNotifyFromISR+0x52>
                configASSERT( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) == NULL );
    8000229c:	6938                	ld	a4,80(a0)
    8000229e:	cb15                	beqz	a4,800022d2 <xTaskGenericNotifyFromISR+0x8a>
    800022a0:	30047073          	csrci	mstatus,8
    800022a4:	a001                	j	800022a4 <xTaskGenericNotifyFromISR+0x5c>
                    ( pxTCB->ulNotifiedValue[ uxIndexToNotify ] )++;
    800022a6:	08852703          	lw	a4,136(a0)
    800022aa:	2705                	addiw	a4,a4,1
    800022ac:	08e52423          	sw	a4,136(a0)
                    break;
    800022b0:	bff1                	j	8000228c <xTaskGenericNotifyFromISR+0x44>
                    pxTCB->ulNotifiedValue[ uxIndexToNotify ] |= ulValue;
    800022b2:	08852703          	lw	a4,136(a0)
    800022b6:	8f51                	or	a4,a4,a2
    800022b8:	08e52423          	sw	a4,136(a0)
                    break;
    800022bc:	bfc1                	j	8000228c <xTaskGenericNotifyFromISR+0x44>
                    configASSERT( xTickCount == ( TickType_t ) 0 );
    800022be:	00016717          	auipc	a4,0x16
    800022c2:	86a73703          	ld	a4,-1942(a4) # 80017b28 <xTickCount>
    800022c6:	d379                	beqz	a4,8000228c <xTaskGenericNotifyFromISR+0x44>
    800022c8:	30047073          	csrci	mstatus,8
    800022cc:	a001                	j	800022cc <xTaskGenericNotifyFromISR+0x84>
                        xReturn = pdFAIL;
    800022ce:	4501                	li	a0,0
    }
    800022d0:	8082                	ret
                if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800022d2:	00016717          	auipc	a4,0x16
    800022d6:	80e73703          	ld	a4,-2034(a4) # 80017ae0 <uxSchedulerSuspended>
                    prvAddTaskToReadyList( pxTCB );
    800022da:	6d2c                	ld	a1,88(a0)
                if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800022dc:	e34d                	bnez	a4,8000237e <xTaskGenericNotifyFromISR+0x136>
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    800022de:	6d18                	ld	a4,24(a0)
    800022e0:	6914                	ld	a3,16(a0)
    800022e2:	02853803          	ld	a6,40(a0)
    800022e6:	00850893          	addi	a7,a0,8
    800022ea:	ea98                	sd	a4,16(a3)
    800022ec:	6d18                	ld	a4,24(a0)
    800022ee:	00883603          	ld	a2,8(a6)
    800022f2:	e714                	sd	a3,8(a4)
    800022f4:	0d160363          	beq	a2,a7,800023ba <xTaskGenericNotifyFromISR+0x172>
                    prvAddTaskToReadyList( pxTCB );
    800022f8:	00259713          	slli	a4,a1,0x2
    800022fc:	972e                	add	a4,a4,a1
    800022fe:	070e                	slli	a4,a4,0x3
    80002300:	00004697          	auipc	a3,0x4
    80002304:	57068693          	addi	a3,a3,1392 # 80006870 <xSuspendedTaskList>
    80002308:	96ba                	add	a3,a3,a4
    8000230a:	6eb0                	ld	a2,88(a3)
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    8000230c:	00083303          	ld	t1,0(a6)
                    prvAddTaskToReadyList( pxTCB );
    80002310:	00016e17          	auipc	t3,0x16
    80002314:	810e0e13          	addi	t3,t3,-2032 # 80017b20 <uxTopReadyPriority>
    80002318:	01063e83          	ld	t4,16(a2)
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    8000231c:	137d                	addi	t1,t1,-1
    8000231e:	00683023          	sd	t1,0(a6)
                    prvAddTaskToReadyList( pxTCB );
    80002322:	01d53c23          	sd	t4,24(a0)
    80002326:	01063e83          	ld	t4,16(a2)
    8000232a:	e910                	sd	a2,16(a0)
    8000232c:	0506b803          	ld	a6,80(a3)
    80002330:	000e3303          	ld	t1,0(t3)
    80002334:	011eb423          	sd	a7,8(t4)
    80002338:	01163823          	sd	a7,16(a2)
    8000233c:	4605                	li	a2,1
    8000233e:	00004897          	auipc	a7,0x4
    80002342:	58288893          	addi	a7,a7,1410 # 800068c0 <pxReadyTasksLists>
    80002346:	00b61633          	sll	a2,a2,a1
    8000234a:	98ba                	add	a7,a7,a4
    8000234c:	03153423          	sd	a7,40(a0)
    80002350:	00666733          	or	a4,a2,t1
    80002354:	00180613          	addi	a2,a6,1
    80002358:	00ee3023          	sd	a4,0(t3)
    8000235c:	eab0                	sd	a2,80(a3)
                    if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    8000235e:	00015717          	auipc	a4,0x15
    80002362:	7f273703          	ld	a4,2034(a4) # 80017b50 <pxCurrentTCB>
    80002366:	6f38                	ld	a4,88(a4)
    80002368:	f2b775e3          	bgeu	a4,a1,80002292 <xTaskGenericNotifyFromISR+0x4a>
                        if( pxHigherPriorityTaskWoken != NULL )
    8000236c:	c399                	beqz	a5,80002372 <xTaskGenericNotifyFromISR+0x12a>
                            *pxHigherPriorityTaskWoken = pdTRUE;
    8000236e:	4705                	li	a4,1
    80002370:	e398                	sd	a4,0(a5)
                        xYieldPendings[ 0 ] = pdTRUE;
    80002372:	4785                	li	a5,1
    80002374:	00015717          	auipc	a4,0x15
    80002378:	78f73a23          	sd	a5,1940(a4) # 80017b08 <xYieldPendings>
    8000237c:	bf19                	j	80002292 <xTaskGenericNotifyFromISR+0x4a>
                    listINSERT_END( &( xPendingReadyList ), &( pxTCB->xEventListItem ) );
    8000237e:	00004697          	auipc	a3,0x4
    80002382:	4f268693          	addi	a3,a3,1266 # 80006870 <xSuspendedTaskList>
    80002386:	1206b703          	ld	a4,288(a3)
    8000238a:	1186b603          	ld	a2,280(a3)
    8000238e:	03050813          	addi	a6,a0,48
    80002392:	01073883          	ld	a7,16(a4)
    80002396:	fd18                	sd	a4,56(a0)
    80002398:	0605                	addi	a2,a2,1
    8000239a:	05153023          	sd	a7,64(a0)
    8000239e:	01073883          	ld	a7,16(a4)
    800023a2:	10c6bc23          	sd	a2,280(a3)
    800023a6:	0108b423          	sd	a6,8(a7)
    800023aa:	01073823          	sd	a6,16(a4)
    800023ae:	00004717          	auipc	a4,0x4
    800023b2:	5da70713          	addi	a4,a4,1498 # 80006988 <xPendingReadyList>
    800023b6:	e938                	sd	a4,80(a0)
    800023b8:	b75d                	j	8000235e <xTaskGenericNotifyFromISR+0x116>
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    800023ba:	00e83423          	sd	a4,8(a6)
    800023be:	bf2d                	j	800022f8 <xTaskGenericNotifyFromISR+0xb0>

00000000800023c0 <vTaskGenericNotifyGiveFromISR>:
        configASSERT( xTaskToNotify );
    800023c0:	c11d                	beqz	a0,800023e6 <vTaskGenericNotifyGiveFromISR+0x26>
        configASSERT( uxIndexToNotify < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    800023c2:	c581                	beqz	a1,800023ca <vTaskGenericNotifyGiveFromISR+0xa>
    800023c4:	30047073          	csrci	mstatus,8
    800023c8:	a001                	j	800023c8 <vTaskGenericNotifyGiveFromISR+0x8>
            pxTCB->ucNotifyState[ uxIndexToNotify ] = taskNOTIFICATION_RECEIVED;
    800023ca:	4789                	li	a5,2
            ucOriginalNotifyState = pxTCB->ucNotifyState[ uxIndexToNotify ];
    800023cc:	08c54683          	lbu	a3,140(a0)
            pxTCB->ucNotifyState[ uxIndexToNotify ] = taskNOTIFICATION_RECEIVED;
    800023d0:	08f50623          	sb	a5,140(a0)
            ( pxTCB->ulNotifiedValue[ uxIndexToNotify ] )++;
    800023d4:	08852783          	lw	a5,136(a0)
            if( ucOriginalNotifyState == taskWAITING_NOTIFICATION )
    800023d8:	4705                	li	a4,1
            ( pxTCB->ulNotifiedValue[ uxIndexToNotify ] )++;
    800023da:	2785                	addiw	a5,a5,1
    800023dc:	08f52423          	sw	a5,136(a0)
            if( ucOriginalNotifyState == taskWAITING_NOTIFICATION )
    800023e0:	00e68663          	beq	a3,a4,800023ec <vTaskGenericNotifyGiveFromISR+0x2c>
    }
    800023e4:	8082                	ret
        configASSERT( xTaskToNotify );
    800023e6:	30047073          	csrci	mstatus,8
    800023ea:	a001                	j	800023ea <vTaskGenericNotifyGiveFromISR+0x2a>
                configASSERT( listLIST_ITEM_CONTAINER( &( pxTCB->xEventListItem ) ) == NULL );
    800023ec:	693c                	ld	a5,80(a0)
    800023ee:	c781                	beqz	a5,800023f6 <vTaskGenericNotifyGiveFromISR+0x36>
    800023f0:	30047073          	csrci	mstatus,8
    800023f4:	a001                	j	800023f4 <vTaskGenericNotifyGiveFromISR+0x34>
                if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    800023f6:	00015797          	auipc	a5,0x15
    800023fa:	6ea7b783          	ld	a5,1770(a5) # 80017ae0 <uxSchedulerSuspended>
                    prvAddTaskToReadyList( pxTCB );
    800023fe:	6d2c                	ld	a1,88(a0)
                if( uxSchedulerSuspended == ( UBaseType_t ) 0U )
    80002400:	e3cd                	bnez	a5,800024a2 <vTaskGenericNotifyGiveFromISR+0xe2>
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80002402:	6d1c                	ld	a5,24(a0)
    80002404:	6918                	ld	a4,16(a0)
    80002406:	02853803          	ld	a6,40(a0)
    8000240a:	00850893          	addi	a7,a0,8
    8000240e:	eb1c                	sd	a5,16(a4)
    80002410:	6d1c                	ld	a5,24(a0)
    80002412:	00883683          	ld	a3,8(a6)
    80002416:	e798                	sd	a4,8(a5)
    80002418:	0d168363          	beq	a3,a7,800024de <vTaskGenericNotifyGiveFromISR+0x11e>
                    prvAddTaskToReadyList( pxTCB );
    8000241c:	00259793          	slli	a5,a1,0x2
    80002420:	97ae                	add	a5,a5,a1
    80002422:	078e                	slli	a5,a5,0x3
    80002424:	00004717          	auipc	a4,0x4
    80002428:	44c70713          	addi	a4,a4,1100 # 80006870 <xSuspendedTaskList>
    8000242c:	973e                	add	a4,a4,a5
    8000242e:	6f34                	ld	a3,88(a4)
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80002430:	00083303          	ld	t1,0(a6)
                    prvAddTaskToReadyList( pxTCB );
    80002434:	00015e17          	auipc	t3,0x15
    80002438:	6ece0e13          	addi	t3,t3,1772 # 80017b20 <uxTopReadyPriority>
    8000243c:	0106be83          	ld	t4,16(a3)
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    80002440:	137d                	addi	t1,t1,-1
    80002442:	00683023          	sd	t1,0(a6)
                    prvAddTaskToReadyList( pxTCB );
    80002446:	01d53c23          	sd	t4,24(a0)
    8000244a:	0106be83          	ld	t4,16(a3)
    8000244e:	e914                	sd	a3,16(a0)
    80002450:	05073803          	ld	a6,80(a4)
    80002454:	000e3303          	ld	t1,0(t3)
    80002458:	011eb423          	sd	a7,8(t4)
    8000245c:	0116b823          	sd	a7,16(a3)
    80002460:	4685                	li	a3,1
    80002462:	00004897          	auipc	a7,0x4
    80002466:	45e88893          	addi	a7,a7,1118 # 800068c0 <pxReadyTasksLists>
    8000246a:	00b696b3          	sll	a3,a3,a1
    8000246e:	98be                	add	a7,a7,a5
    80002470:	03153423          	sd	a7,40(a0)
    80002474:	0066e7b3          	or	a5,a3,t1
    80002478:	00180693          	addi	a3,a6,1
    8000247c:	00fe3023          	sd	a5,0(t3)
    80002480:	eb34                	sd	a3,80(a4)
                    if( pxTCB->uxPriority > pxCurrentTCB->uxPriority )
    80002482:	00015797          	auipc	a5,0x15
    80002486:	6ce7b783          	ld	a5,1742(a5) # 80017b50 <pxCurrentTCB>
    8000248a:	6fbc                	ld	a5,88(a5)
    8000248c:	f4b7fce3          	bgeu	a5,a1,800023e4 <vTaskGenericNotifyGiveFromISR+0x24>
                        if( pxHigherPriorityTaskWoken != NULL )
    80002490:	c219                	beqz	a2,80002496 <vTaskGenericNotifyGiveFromISR+0xd6>
                            *pxHigherPriorityTaskWoken = pdTRUE;
    80002492:	4785                	li	a5,1
    80002494:	e21c                	sd	a5,0(a2)
                        xYieldPendings[ 0 ] = pdTRUE;
    80002496:	4785                	li	a5,1
    80002498:	00015717          	auipc	a4,0x15
    8000249c:	66f73823          	sd	a5,1648(a4) # 80017b08 <xYieldPendings>
    }
    800024a0:	8082                	ret
                    listINSERT_END( &( xPendingReadyList ), &( pxTCB->xEventListItem ) );
    800024a2:	00004717          	auipc	a4,0x4
    800024a6:	3ce70713          	addi	a4,a4,974 # 80006870 <xSuspendedTaskList>
    800024aa:	12073783          	ld	a5,288(a4)
    800024ae:	11873683          	ld	a3,280(a4)
    800024b2:	03050813          	addi	a6,a0,48
    800024b6:	0107b883          	ld	a7,16(a5)
    800024ba:	fd1c                	sd	a5,56(a0)
    800024bc:	0685                	addi	a3,a3,1
    800024be:	05153023          	sd	a7,64(a0)
    800024c2:	0107b883          	ld	a7,16(a5)
    800024c6:	10d73c23          	sd	a3,280(a4)
    800024ca:	0108b423          	sd	a6,8(a7)
    800024ce:	0107b823          	sd	a6,16(a5)
    800024d2:	00004797          	auipc	a5,0x4
    800024d6:	4b678793          	addi	a5,a5,1206 # 80006988 <xPendingReadyList>
    800024da:	e93c                	sd	a5,80(a0)
    800024dc:	b75d                	j	80002482 <vTaskGenericNotifyGiveFromISR+0xc2>
                    listREMOVE_ITEM( &( pxTCB->xStateListItem ) );
    800024de:	00f83423          	sd	a5,8(a6)
    800024e2:	bf2d                	j	8000241c <vTaskGenericNotifyGiveFromISR+0x5c>

00000000800024e4 <xTaskGenericNotifyStateClear>:
    {
    800024e4:	87aa                	mv	a5,a0
        configASSERT( uxIndexToClear < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    800024e6:	c581                	beqz	a1,800024ee <xTaskGenericNotifyStateClear+0xa>
    800024e8:	30047073          	csrci	mstatus,8
    800024ec:	a001                	j	800024ec <xTaskGenericNotifyStateClear+0x8>
        pxTCB = prvGetTCBFromHandle( xTask );
    800024ee:	c10d                	beqz	a0,80002510 <xTaskGenericNotifyStateClear+0x2c>
        taskENTER_CRITICAL();
    800024f0:	30047073          	csrci	mstatus,8
            if( pxTCB->ucNotifyState[ uxIndexToClear ] == taskNOTIFICATION_RECEIVED )
    800024f4:	08c7c603          	lbu	a2,140(a5)
    800024f8:	4689                	li	a3,2
        taskENTER_CRITICAL();
    800024fa:	00004717          	auipc	a4,0x4
    800024fe:	36673703          	ld	a4,870(a4) # 80006860 <xCriticalNesting>
                xReturn = pdFAIL;
    80002502:	4501                	li	a0,0
            if( pxTCB->ucNotifyState[ uxIndexToClear ] == taskNOTIFICATION_RECEIVED )
    80002504:	00d60e63          	beq	a2,a3,80002520 <xTaskGenericNotifyStateClear+0x3c>
        taskEXIT_CRITICAL();
    80002508:	e319                	bnez	a4,8000250e <xTaskGenericNotifyStateClear+0x2a>
    8000250a:	30046073          	csrsi	mstatus,8
    }
    8000250e:	8082                	ret
        pxTCB = prvGetTCBFromHandle( xTask );
    80002510:	00015797          	auipc	a5,0x15
    80002514:	6407b783          	ld	a5,1600(a5) # 80017b50 <pxCurrentTCB>
        configASSERT( pxTCB != NULL );
    80002518:	ffe1                	bnez	a5,800024f0 <xTaskGenericNotifyStateClear+0xc>
    8000251a:	30047073          	csrci	mstatus,8
    8000251e:	a001                	j	8000251e <xTaskGenericNotifyStateClear+0x3a>
                pxTCB->ucNotifyState[ uxIndexToClear ] = taskNOT_WAITING_NOTIFICATION;
    80002520:	08078623          	sb	zero,140(a5)
                xReturn = pdPASS;
    80002524:	4505                	li	a0,1
        taskEXIT_CRITICAL();
    80002526:	f765                	bnez	a4,8000250e <xTaskGenericNotifyStateClear+0x2a>
    80002528:	b7cd                	j	8000250a <xTaskGenericNotifyStateClear+0x26>

000000008000252a <ulTaskGenericNotifyValueClear>:
        configASSERT( uxIndexToClear < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    8000252a:	c581                	beqz	a1,80002532 <ulTaskGenericNotifyValueClear+0x8>
    8000252c:	30047073          	csrci	mstatus,8
    80002530:	a001                	j	80002530 <ulTaskGenericNotifyValueClear+0x6>
        pxTCB = prvGetTCBFromHandle( xTask );
    80002532:	c515                	beqz	a0,8000255e <ulTaskGenericNotifyValueClear+0x34>
        taskENTER_CRITICAL();
    80002534:	30047073          	csrci	mstatus,8
            ulReturn = pxTCB->ulNotifiedValue[ uxIndexToClear ];
    80002538:	08852703          	lw	a4,136(a0)
            pxTCB->ulNotifiedValue[ uxIndexToClear ] &= ~ulBitsToClear;
    8000253c:	08852783          	lw	a5,136(a0)
    80002540:	fff64613          	not	a2,a2
        taskENTER_CRITICAL();
    80002544:	00004697          	auipc	a3,0x4
    80002548:	31c6b683          	ld	a3,796(a3) # 80006860 <xCriticalNesting>
            pxTCB->ulNotifiedValue[ uxIndexToClear ] &= ~ulBitsToClear;
    8000254c:	8ff1                	and	a5,a5,a2
    8000254e:	08f52423          	sw	a5,136(a0)
            ulReturn = pxTCB->ulNotifiedValue[ uxIndexToClear ];
    80002552:	0007051b          	sext.w	a0,a4
        taskEXIT_CRITICAL();
    80002556:	e299                	bnez	a3,8000255c <ulTaskGenericNotifyValueClear+0x32>
    80002558:	30046073          	csrsi	mstatus,8
    }
    8000255c:	8082                	ret
        pxTCB = prvGetTCBFromHandle( xTask );
    8000255e:	00015517          	auipc	a0,0x15
    80002562:	5f253503          	ld	a0,1522(a0) # 80017b50 <pxCurrentTCB>
        configASSERT( pxTCB != NULL );
    80002566:	f579                	bnez	a0,80002534 <ulTaskGenericNotifyValueClear+0xa>
    80002568:	30047073          	csrci	mstatus,8
    8000256c:	a001                	j	8000256c <ulTaskGenericNotifyValueClear+0x42>

000000008000256e <vTaskResetState>:
    BaseType_t xCoreID;

    /* Task control block. */
    #if ( configNUMBER_OF_CORES == 1 )
    {
        pxCurrentTCB = NULL;
    8000256e:	00015797          	auipc	a5,0x15
    80002572:	5e07b123          	sd	zero,1506(a5) # 80017b50 <pxCurrentTCB>
    }
    #endif /* #if ( configNUMBER_OF_CORES == 1 ) */

    #if ( INCLUDE_vTaskDelete == 1 )
    {
        uxDeletedTasksWaitingCleanUp = ( UBaseType_t ) 0U;
    80002576:	00015797          	auipc	a5,0x15
    8000257a:	5c07b123          	sd	zero,1474(a5) # 80017b38 <uxDeletedTasksWaitingCleanUp>
        FreeRTOS_errno = 0;
    }
    #endif /* #if ( configUSE_POSIX_ERRNO == 1 ) */

    /* Other file private variables. */
    uxCurrentNumberOfTasks = ( UBaseType_t ) 0U;
    8000257e:	00015797          	auipc	a5,0x15
    80002582:	5a07b923          	sd	zero,1458(a5) # 80017b30 <uxCurrentNumberOfTasks>
    xTickCount = ( TickType_t ) configINITIAL_TICK_COUNT;
    80002586:	00015797          	auipc	a5,0x15
    8000258a:	5a07b123          	sd	zero,1442(a5) # 80017b28 <xTickCount>
    uxTopReadyPriority = tskIDLE_PRIORITY;
    8000258e:	00015797          	auipc	a5,0x15
    80002592:	5807b923          	sd	zero,1426(a5) # 80017b20 <uxTopReadyPriority>
    xSchedulerRunning = pdFALSE;
    80002596:	00015797          	auipc	a5,0x15
    8000259a:	5807b123          	sd	zero,1410(a5) # 80017b18 <xSchedulerRunning>
    xPendedTicks = ( TickType_t ) 0U;
    8000259e:	00015797          	auipc	a5,0x15
    800025a2:	5607b923          	sd	zero,1394(a5) # 80017b10 <xPendedTicks>

    for( xCoreID = 0; xCoreID < configNUMBER_OF_CORES; xCoreID++ )
    {
        xYieldPendings[ xCoreID ] = pdFALSE;
    800025a6:	00015797          	auipc	a5,0x15
    800025aa:	5607b123          	sd	zero,1378(a5) # 80017b08 <xYieldPendings>
    }

    xNumOfOverflows = ( BaseType_t ) 0;
    800025ae:	00015797          	auipc	a5,0x15
    800025b2:	5407b923          	sd	zero,1362(a5) # 80017b00 <xNumOfOverflows>
    uxTaskNumber = ( UBaseType_t ) 0U;
    xNextTaskUnblockTime = ( TickType_t ) 0U;
    800025b6:	00015797          	auipc	a5,0x15
    800025ba:	5207bd23          	sd	zero,1338(a5) # 80017af0 <xNextTaskUnblockTime>
    uxTaskNumber = ( UBaseType_t ) 0U;
    800025be:	00015797          	auipc	a5,0x15
    800025c2:	5207bd23          	sd	zero,1338(a5) # 80017af8 <uxTaskNumber>

    uxSchedulerSuspended = ( UBaseType_t ) 0U;
    800025c6:	00015797          	auipc	a5,0x15
    800025ca:	5007bd23          	sd	zero,1306(a5) # 80017ae0 <uxSchedulerSuspended>
            ulTaskSwitchedInTime[ xCoreID ] = 0U;
            ulTotalRunTime[ xCoreID ] = 0U;
        }
    }
    #endif /* #if ( configGENERATE_RUN_TIME_STATS == 1 ) */
}
    800025ce:	8082                	ret

00000000800025d0 <vListInitialise>:
    traceENTER_vListInitialise( pxList );

    /* The list structure contains a list item which is used to mark the
     * end of the list.  To initialise the list the list end is inserted
     * as the only list entry. */
    pxList->pxIndex = ( ListItem_t * ) &( pxList->xListEnd );
    800025d0:	01050793          	addi	a5,a0,16

    listSET_FIRST_LIST_ITEM_INTEGRITY_CHECK_VALUE( &( pxList->xListEnd ) );

    /* The list end value is the highest possible value in the list to
     * ensure it remains at the end of the list. */
    pxList->xListEnd.xItemValue = portMAX_DELAY;
    800025d4:	577d                	li	a4,-1
    pxList->pxIndex = ( ListItem_t * ) &( pxList->xListEnd );
    800025d6:	e51c                	sd	a5,8(a0)
    pxList->xListEnd.xItemValue = portMAX_DELAY;
    800025d8:	e918                	sd	a4,16(a0)

    /* The list end next and previous pointers point to itself so we know
     * when the list is empty. */
    pxList->xListEnd.pxNext = ( ListItem_t * ) &( pxList->xListEnd );
    800025da:	ed1c                	sd	a5,24(a0)
    pxList->xListEnd.pxPrevious = ( ListItem_t * ) &( pxList->xListEnd );
    800025dc:	f11c                	sd	a5,32(a0)
        pxList->xListEnd.pxContainer = NULL;
        listSET_SECOND_LIST_ITEM_INTEGRITY_CHECK_VALUE( &( pxList->xListEnd ) );
    }
    #endif

    pxList->uxNumberOfItems = ( UBaseType_t ) 0U;
    800025de:	00053023          	sd	zero,0(a0)
     * configUSE_LIST_DATA_INTEGRITY_CHECK_BYTES is set to 1. */
    listSET_LIST_INTEGRITY_CHECK_1_VALUE( pxList );
    listSET_LIST_INTEGRITY_CHECK_2_VALUE( pxList );

    traceRETURN_vListInitialise();
}
    800025e2:	8082                	ret

00000000800025e4 <vListInitialiseItem>:
void vListInitialiseItem( ListItem_t * const pxItem )
{
    traceENTER_vListInitialiseItem( pxItem );

    /* Make sure the list item is not recorded as being on a list. */
    pxItem->pxContainer = NULL;
    800025e4:	02053023          	sd	zero,32(a0)
     * configUSE_LIST_DATA_INTEGRITY_CHECK_BYTES is set to 1. */
    listSET_FIRST_LIST_ITEM_INTEGRITY_CHECK_VALUE( pxItem );
    listSET_SECOND_LIST_ITEM_INTEGRITY_CHECK_VALUE( pxItem );

    traceRETURN_vListInitialiseItem();
}
    800025e8:	8082                	ret

00000000800025ea <vListInsertEnd>:
/*-----------------------------------------------------------*/

void vListInsertEnd( List_t * const pxList,
                     ListItem_t * const pxNewListItem )
{
    ListItem_t * const pxIndex = pxList->pxIndex;
    800025ea:	651c                	ld	a5,8(a0)
    pxIndex->pxPrevious = pxNewListItem;

    /* Remember which list the item is in. */
    pxNewListItem->pxContainer = pxList;

    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems + 1U );
    800025ec:	6118                	ld	a4,0(a0)
    pxNewListItem->pxPrevious = pxIndex->pxPrevious;
    800025ee:	6b94                	ld	a3,16(a5)
    pxNewListItem->pxNext = pxIndex;
    800025f0:	e59c                	sd	a5,8(a1)
    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems + 1U );
    800025f2:	0705                	addi	a4,a4,1
    pxNewListItem->pxPrevious = pxIndex->pxPrevious;
    800025f4:	e994                	sd	a3,16(a1)
    pxIndex->pxPrevious->pxNext = pxNewListItem;
    800025f6:	6b94                	ld	a3,16(a5)
    800025f8:	e68c                	sd	a1,8(a3)
    pxIndex->pxPrevious = pxNewListItem;
    800025fa:	eb8c                	sd	a1,16(a5)
    pxNewListItem->pxContainer = pxList;
    800025fc:	f188                	sd	a0,32(a1)
    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems + 1U );
    800025fe:	e118                	sd	a4,0(a0)

    traceRETURN_vListInsertEnd();
}
    80002600:	8082                	ret

0000000080002602 <vListInsert>:

void vListInsert( List_t * const pxList,
                  ListItem_t * const pxNewListItem )
{
    ListItem_t * pxIterator;
    const TickType_t xValueOfInsertion = pxNewListItem->xItemValue;
    80002602:	6190                	ld	a2,0(a1)
     * new list item should be placed after it.  This ensures that TCBs which are
     * stored in ready lists (all of which have the same xItemValue value) get a
     * share of the CPU.  However, if the xItemValue is the same as the back marker
     * the iteration loop below will not end.  Therefore the value is checked
     * first, and the algorithm slightly modified if necessary. */
    if( xValueOfInsertion == portMAX_DELAY )
    80002604:	577d                	li	a4,-1
        *   5) If the FreeRTOS port supports interrupt nesting then ensure that
        *      the priority of the tick interrupt is at or below
        *      configMAX_SYSCALL_INTERRUPT_PRIORITY.
        **********************************************************************/

        for( pxIterator = ( ListItem_t * ) &( pxList->xListEnd ); pxIterator->pxNext->xItemValue <= xValueOfInsertion; pxIterator = pxIterator->pxNext )
    80002606:	01050793          	addi	a5,a0,16
    if( xValueOfInsertion == portMAX_DELAY )
    8000260a:	02e60063          	beq	a2,a4,8000262a <vListInsert+0x28>
        for( pxIterator = ( ListItem_t * ) &( pxList->xListEnd ); pxIterator->pxNext->xItemValue <= xValueOfInsertion; pxIterator = pxIterator->pxNext )
    8000260e:	86be                	mv	a3,a5
    80002610:	679c                	ld	a5,8(a5)
    80002612:	6398                	ld	a4,0(a5)
    80002614:	fee67de3          	bgeu	a2,a4,8000260e <vListInsert+0xc>
             * IF YOU FIND YOUR CODE STUCK HERE, SEE THE NOTE JUST ABOVE.
             */
        }
    }

    pxNewListItem->pxNext = pxIterator->pxNext;
    80002618:	e59c                	sd	a5,8(a1)
    pxNewListItem->pxNext->pxPrevious = pxNewListItem;
    8000261a:	eb8c                	sd	a1,16(a5)

    /* Remember which list the item is in.  This allows fast removal of the
     * item later. */
    pxNewListItem->pxContainer = pxList;

    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems + 1U );
    8000261c:	611c                	ld	a5,0(a0)
    pxNewListItem->pxPrevious = pxIterator;
    8000261e:	e994                	sd	a3,16(a1)
    pxIterator->pxNext = pxNewListItem;
    80002620:	e68c                	sd	a1,8(a3)
    pxNewListItem->pxContainer = pxList;
    80002622:	f188                	sd	a0,32(a1)
    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems + 1U );
    80002624:	0785                	addi	a5,a5,1
    80002626:	e11c                	sd	a5,0(a0)

    traceRETURN_vListInsert();
}
    80002628:	8082                	ret
        pxIterator = pxList->xListEnd.pxPrevious;
    8000262a:	7114                	ld	a3,32(a0)
    pxNewListItem->pxNext = pxIterator->pxNext;
    8000262c:	669c                	ld	a5,8(a3)
    8000262e:	b7ed                	j	80002618 <vListInsert+0x16>

0000000080002630 <uxListRemove>:

UBaseType_t uxListRemove( ListItem_t * const pxItemToRemove )
{
    /* The list item knows which list it is in.  Obtain the list from the list
     * item. */
    List_t * const pxList = pxItemToRemove->pxContainer;
    80002630:	7118                	ld	a4,32(a0)

    traceENTER_uxListRemove( pxItemToRemove );

    pxItemToRemove->pxNext->pxPrevious = pxItemToRemove->pxPrevious;
    80002632:	6514                	ld	a3,8(a0)
    80002634:	691c                	ld	a5,16(a0)

    /* Only used during decision coverage testing. */
    mtCOVERAGE_TEST_DELAY();

    /* Make sure the index is left pointing to a valid item. */
    if( pxList->pxIndex == pxItemToRemove )
    80002636:	6710                	ld	a2,8(a4)
    pxItemToRemove->pxNext->pxPrevious = pxItemToRemove->pxPrevious;
    80002638:	ea9c                	sd	a5,16(a3)
    pxItemToRemove->pxPrevious->pxNext = pxItemToRemove->pxNext;
    8000263a:	e794                	sd	a3,8(a5)
    if( pxList->pxIndex == pxItemToRemove )
    8000263c:	00a60963          	beq	a2,a0,8000264e <uxListRemove+0x1e>
    {
        mtCOVERAGE_TEST_MARKER();
    }

    pxItemToRemove->pxContainer = NULL;
    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems - 1U );
    80002640:	631c                	ld	a5,0(a4)
    pxItemToRemove->pxContainer = NULL;
    80002642:	02053023          	sd	zero,32(a0)
    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems - 1U );
    80002646:	fff78513          	addi	a0,a5,-1
    8000264a:	e308                	sd	a0,0(a4)

    traceRETURN_uxListRemove( pxList->uxNumberOfItems );

    return pxList->uxNumberOfItems;
}
    8000264c:	8082                	ret
        pxList->pxIndex = pxItemToRemove->pxPrevious;
    8000264e:	e71c                	sd	a5,8(a4)
    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems - 1U );
    80002650:	631c                	ld	a5,0(a4)
    pxItemToRemove->pxContainer = NULL;
    80002652:	02053023          	sd	zero,32(a0)
    ( pxList->uxNumberOfItems ) = ( UBaseType_t ) ( pxList->uxNumberOfItems - 1U );
    80002656:	fff78513          	addi	a0,a5,-1
    8000265a:	e308                	sd	a0,0(a4)
}
    8000265c:	8082                	ret

000000008000265e <prvCopyDataToQueue>:
/*-----------------------------------------------------------*/

static BaseType_t prvCopyDataToQueue( Queue_t * const pxQueue,
                                      const void * pvItemToQueue,
                                      const BaseType_t xPosition )
{
    8000265e:	1101                	addi	sp,sp,-32

    /* This function is called from a critical section. */

    uxMessagesWaiting = pxQueue->uxMessagesWaiting;

    if( pxQueue->uxItemSize == ( UBaseType_t ) 0 )
    80002660:	615c                	ld	a5,128(a0)
{
    80002662:	e426                	sd	s1,8(sp)
    uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    80002664:	7924                	ld	s1,112(a0)
{
    80002666:	e822                	sd	s0,16(sp)
    80002668:	ec06                	sd	ra,24(sp)
    8000266a:	e04a                	sd	s2,0(sp)
    8000266c:	842a                	mv	s0,a0
    if( pxQueue->uxItemSize == ( UBaseType_t ) 0 )
    8000266e:	ef81                	bnez	a5,80002686 <prvCopyDataToQueue+0x28>
    {
        #if ( configUSE_MUTEXES == 1 )
        {
            if( pxQueue->uxQueueType == queueQUEUE_IS_MUTEX )
    80002670:	611c                	ld	a5,0(a0)
        {
            mtCOVERAGE_TEST_MARKER();
        }
    }

    pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting + ( UBaseType_t ) 1 );
    80002672:	0485                	addi	s1,s1,1
    BaseType_t xReturn = pdFALSE;
    80002674:	4501                	li	a0,0
            if( pxQueue->uxQueueType == queueQUEUE_IS_MUTEX )
    80002676:	c3c1                	beqz	a5,800026f6 <prvCopyDataToQueue+0x98>
    pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting + ( UBaseType_t ) 1 );
    80002678:	f824                	sd	s1,112(s0)

    return xReturn;
}
    8000267a:	60e2                	ld	ra,24(sp)
    8000267c:	6442                	ld	s0,16(sp)
    8000267e:	64a2                	ld	s1,8(sp)
    80002680:	6902                	ld	s2,0(sp)
    80002682:	6105                	addi	sp,sp,32
    80002684:	8082                	ret
    80002686:	8932                	mv	s2,a2
    else if( xPosition == queueSEND_TO_BACK )
    80002688:	ea0d                	bnez	a2,800026ba <prvCopyDataToQueue+0x5c>
  return __builtin___memcpy_chk (__dest, __src, __len,
    8000268a:	6508                	ld	a0,8(a0)
    8000268c:	863e                	mv	a2,a5
    pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting + ( UBaseType_t ) 1 );
    8000268e:	0485                	addi	s1,s1,1
    80002690:	00003097          	auipc	ra,0x3
    80002694:	134080e7          	jalr	308(ra) # 800057c4 <memcpy>
        pxQueue->pcWriteTo += pxQueue->uxItemSize;
    80002698:	641c                	ld	a5,8(s0)
    8000269a:	6054                	ld	a3,128(s0)
        if( pxQueue->pcWriteTo >= pxQueue->u.xQueue.pcTail )
    8000269c:	6818                	ld	a4,16(s0)
    BaseType_t xReturn = pdFALSE;
    8000269e:	4501                	li	a0,0
        pxQueue->pcWriteTo += pxQueue->uxItemSize;
    800026a0:	97b6                	add	a5,a5,a3
    800026a2:	e41c                	sd	a5,8(s0)
        if( pxQueue->pcWriteTo >= pxQueue->u.xQueue.pcTail )
    800026a4:	fce7eae3          	bltu	a5,a4,80002678 <prvCopyDataToQueue+0x1a>
            pxQueue->pcWriteTo = pxQueue->pcHead;
    800026a8:	601c                	ld	a5,0(s0)
    pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting + ( UBaseType_t ) 1 );
    800026aa:	f824                	sd	s1,112(s0)
}
    800026ac:	60e2                	ld	ra,24(sp)
            pxQueue->pcWriteTo = pxQueue->pcHead;
    800026ae:	e41c                	sd	a5,8(s0)
}
    800026b0:	6442                	ld	s0,16(sp)
    800026b2:	64a2                	ld	s1,8(sp)
    800026b4:	6902                	ld	s2,0(sp)
    800026b6:	6105                	addi	sp,sp,32
    800026b8:	8082                	ret
    800026ba:	6d08                	ld	a0,24(a0)
    800026bc:	863e                	mv	a2,a5
    800026be:	00003097          	auipc	ra,0x3
    800026c2:	106080e7          	jalr	262(ra) # 800057c4 <memcpy>
        pxQueue->u.xQueue.pcReadFrom -= pxQueue->uxItemSize;
    800026c6:	6058                	ld	a4,128(s0)
    800026c8:	6c1c                	ld	a5,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom < pxQueue->pcHead )
    800026ca:	6014                	ld	a3,0(s0)
        pxQueue->u.xQueue.pcReadFrom -= pxQueue->uxItemSize;
    800026cc:	40e00633          	neg	a2,a4
    800026d0:	8f99                	sub	a5,a5,a4
    800026d2:	ec1c                	sd	a5,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom < pxQueue->pcHead )
    800026d4:	00d7f563          	bgeu	a5,a3,800026de <prvCopyDataToQueue+0x80>
            pxQueue->u.xQueue.pcReadFrom = ( pxQueue->u.xQueue.pcTail - pxQueue->uxItemSize );
    800026d8:	681c                	ld	a5,16(s0)
    800026da:	97b2                	add	a5,a5,a2
    800026dc:	ec1c                	sd	a5,24(s0)
        if( xPosition == queueOVERWRITE )
    800026de:	4789                	li	a5,2
    800026e0:	02f90363          	beq	s2,a5,80002706 <prvCopyDataToQueue+0xa8>
    pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting + ( UBaseType_t ) 1 );
    800026e4:	0485                	addi	s1,s1,1
    800026e6:	f824                	sd	s1,112(s0)
}
    800026e8:	60e2                	ld	ra,24(sp)
    800026ea:	6442                	ld	s0,16(sp)
    800026ec:	64a2                	ld	s1,8(sp)
    800026ee:	6902                	ld	s2,0(sp)
    BaseType_t xReturn = pdFALSE;
    800026f0:	4501                	li	a0,0
}
    800026f2:	6105                	addi	sp,sp,32
    800026f4:	8082                	ret
                xReturn = xTaskPriorityDisinherit( pxQueue->u.xSemaphore.xMutexHolder );
    800026f6:	6808                	ld	a0,16(s0)
    800026f8:	fffff097          	auipc	ra,0xfffff
    800026fc:	60a080e7          	jalr	1546(ra) # 80001d02 <xTaskPriorityDisinherit>
                pxQueue->u.xSemaphore.xMutexHolder = NULL;
    80002700:	00043823          	sd	zero,16(s0)
    80002704:	bf95                	j	80002678 <prvCopyDataToQueue+0x1a>
            if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    80002706:	c099                	beqz	s1,8000270c <prvCopyDataToQueue+0xae>
    BaseType_t xReturn = pdFALSE;
    80002708:	4501                	li	a0,0
    8000270a:	b7bd                	j	80002678 <prvCopyDataToQueue+0x1a>
    8000270c:	4485                	li	s1,1
    8000270e:	4501                	li	a0,0
    80002710:	b7a5                	j	80002678 <prvCopyDataToQueue+0x1a>

0000000080002712 <prvUnlockQueue>:
    }
}
/*-----------------------------------------------------------*/

static void prvUnlockQueue( Queue_t * const pxQueue )
{
    80002712:	7179                	addi	sp,sp,-48
    80002714:	ec26                	sd	s1,24(sp)
    80002716:	f406                	sd	ra,40(sp)
    80002718:	f022                	sd	s0,32(sp)
    8000271a:	e84a                	sd	s2,16(sp)
    8000271c:	e44e                	sd	s3,8(sp)
    8000271e:	84aa                	mv	s1,a0

    /* The lock counts contains the number of extra data items placed or
     * removed from the queue while the queue was locked.  When a queue is
     * locked items can be added or removed, but the event lists cannot be
     * updated. */
    taskENTER_CRITICAL();
    80002720:	30047073          	csrci	mstatus,8
    80002724:	00004917          	auipc	s2,0x4
    80002728:	13c90913          	addi	s2,s2,316 # 80006860 <xCriticalNesting>
    8000272c:	00093703          	ld	a4,0(s2)
    {
        int8_t cTxLock = pxQueue->cTxLock;
    80002730:	08954783          	lbu	a5,137(a0)
    taskENTER_CRITICAL();
    80002734:	00170693          	addi	a3,a4,1
        int8_t cTxLock = pxQueue->cTxLock;
    80002738:	0187941b          	slliw	s0,a5,0x18
    taskENTER_CRITICAL();
    8000273c:	00d93023          	sd	a3,0(s2)
        int8_t cTxLock = pxQueue->cTxLock;
    80002740:	4184541b          	sraiw	s0,s0,0x18

        /* See if data was added to the queue while it was locked. */
        while( cTxLock > queueLOCKED_UNMODIFIED )
    80002744:	04805663          	blez	s0,80002790 <prvUnlockQueue+0x7e>
            {
                /* Tasks that are removed from the event list will get added to
                 * the pending ready list as the scheduler is still suspended. */
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
                {
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
    80002748:	04850993          	addi	s3,a0,72
    8000274c:	a811                	j	80002760 <prvUnlockQueue+0x4e>
                    break;
                }
            }
            #endif /* configUSE_QUEUE_SETS */

            --cTxLock;
    8000274e:	fff4079b          	addiw	a5,s0,-1
    80002752:	0187941b          	slliw	s0,a5,0x18
    80002756:	0ff7f713          	zext.b	a4,a5
    8000275a:	4184541b          	sraiw	s0,s0,0x18
        while( cTxLock > queueLOCKED_UNMODIFIED )
    8000275e:	c715                	beqz	a4,8000278a <prvUnlockQueue+0x78>
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
    80002760:	64bc                	ld	a5,72(s1)
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
    80002762:	854e                	mv	a0,s3
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
    80002764:	c39d                	beqz	a5,8000278a <prvUnlockQueue+0x78>
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	182080e7          	jalr	386(ra) # 800018e8 <xTaskRemoveFromEventList>
    8000276e:	d165                	beqz	a0,8000274e <prvUnlockQueue+0x3c>
                        vTaskMissedYield();
    80002770:	fffff097          	auipc	ra,0xfffff
    80002774:	44e080e7          	jalr	1102(ra) # 80001bbe <vTaskMissedYield>
            --cTxLock;
    80002778:	fff4079b          	addiw	a5,s0,-1
    8000277c:	0187941b          	slliw	s0,a5,0x18
    80002780:	0ff7f713          	zext.b	a4,a5
    80002784:	4184541b          	sraiw	s0,s0,0x18
        while( cTxLock > queueLOCKED_UNMODIFIED )
    80002788:	ff61                	bnez	a4,80002760 <prvUnlockQueue+0x4e>
        }

        pxQueue->cTxLock = queueUNLOCKED;
    }
    taskEXIT_CRITICAL();
    8000278a:	00093703          	ld	a4,0(s2)
    8000278e:	177d                	addi	a4,a4,-1
        pxQueue->cTxLock = queueUNLOCKED;
    80002790:	57fd                	li	a5,-1
    80002792:	08f484a3          	sb	a5,137(s1)
    taskEXIT_CRITICAL();
    80002796:	00e93023          	sd	a4,0(s2)
    8000279a:	e319                	bnez	a4,800027a0 <prvUnlockQueue+0x8e>
    8000279c:	30046073          	csrsi	mstatus,8

    /* Do the same for the Rx lock. */
    taskENTER_CRITICAL();
    800027a0:	30047073          	csrci	mstatus,8
    800027a4:	00093703          	ld	a4,0(s2)
    {
        int8_t cRxLock = pxQueue->cRxLock;
    800027a8:	0884c783          	lbu	a5,136(s1)
    taskENTER_CRITICAL();
    800027ac:	00170693          	addi	a3,a4,1
        int8_t cRxLock = pxQueue->cRxLock;
    800027b0:	0187941b          	slliw	s0,a5,0x18
    taskENTER_CRITICAL();
    800027b4:	00d93023          	sd	a3,0(s2)
        int8_t cRxLock = pxQueue->cRxLock;
    800027b8:	4184541b          	sraiw	s0,s0,0x18

        while( cRxLock > queueLOCKED_UNMODIFIED )
    800027bc:	04805663          	blez	s0,80002808 <prvUnlockQueue+0xf6>
        {
            if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
            {
                if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
    800027c0:	02048993          	addi	s3,s1,32
    800027c4:	a811                	j	800027d8 <prvUnlockQueue+0xc6>
                else
                {
                    mtCOVERAGE_TEST_MARKER();
                }

                --cRxLock;
    800027c6:	fff4079b          	addiw	a5,s0,-1
    800027ca:	0187941b          	slliw	s0,a5,0x18
    800027ce:	0ff7f713          	zext.b	a4,a5
    800027d2:	4184541b          	sraiw	s0,s0,0x18
        while( cRxLock > queueLOCKED_UNMODIFIED )
    800027d6:	c715                	beqz	a4,80002802 <prvUnlockQueue+0xf0>
            if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
    800027d8:	709c                	ld	a5,32(s1)
                if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
    800027da:	854e                	mv	a0,s3
            if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
    800027dc:	c39d                	beqz	a5,80002802 <prvUnlockQueue+0xf0>
                if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	10a080e7          	jalr	266(ra) # 800018e8 <xTaskRemoveFromEventList>
    800027e6:	d165                	beqz	a0,800027c6 <prvUnlockQueue+0xb4>
                    vTaskMissedYield();
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	3d6080e7          	jalr	982(ra) # 80001bbe <vTaskMissedYield>
                --cRxLock;
    800027f0:	fff4079b          	addiw	a5,s0,-1
    800027f4:	0187941b          	slliw	s0,a5,0x18
    800027f8:	0ff7f713          	zext.b	a4,a5
    800027fc:	4184541b          	sraiw	s0,s0,0x18
        while( cRxLock > queueLOCKED_UNMODIFIED )
    80002800:	ff61                	bnez	a4,800027d8 <prvUnlockQueue+0xc6>
            }
        }

        pxQueue->cRxLock = queueUNLOCKED;
    }
    taskEXIT_CRITICAL();
    80002802:	00093703          	ld	a4,0(s2)
    80002806:	177d                	addi	a4,a4,-1
        pxQueue->cRxLock = queueUNLOCKED;
    80002808:	57fd                	li	a5,-1
    8000280a:	08f48423          	sb	a5,136(s1)
    taskEXIT_CRITICAL();
    8000280e:	00e93023          	sd	a4,0(s2)
    80002812:	e319                	bnez	a4,80002818 <prvUnlockQueue+0x106>
    80002814:	30046073          	csrsi	mstatus,8
}
    80002818:	70a2                	ld	ra,40(sp)
    8000281a:	7402                	ld	s0,32(sp)
    8000281c:	64e2                	ld	s1,24(sp)
    8000281e:	6942                	ld	s2,16(sp)
    80002820:	69a2                	ld	s3,8(sp)
    80002822:	6145                	addi	sp,sp,48
    80002824:	8082                	ret

0000000080002826 <xQueueGenericReset>:
    configASSERT( pxQueue );
    80002826:	cd25                	beqz	a0,8000289e <xQueueGenericReset+0x78>
        ( pxQueue->uxLength >= 1U ) &&
    80002828:	7d3c                	ld	a5,120(a0)
{
    8000282a:	1101                	addi	sp,sp,-32
    8000282c:	e822                	sd	s0,16(sp)
    8000282e:	ec06                	sd	ra,24(sp)
    80002830:	e426                	sd	s1,8(sp)
    80002832:	842a                	mv	s0,a0
    if( ( pxQueue != NULL ) &&
    80002834:	c3b5                	beqz	a5,80002898 <xQueueGenericReset+0x72>
        ( ( SIZE_MAX / pxQueue->uxLength ) >= pxQueue->uxItemSize ) )
    80002836:	6158                	ld	a4,128(a0)
    80002838:	02e7b7b3          	mulhu	a5,a5,a4
    8000283c:	efb1                	bnez	a5,80002898 <xQueueGenericReset+0x72>
        taskENTER_CRITICAL();
    8000283e:	30047073          	csrci	mstatus,8
            pxQueue->u.xQueue.pcTail = pxQueue->pcHead + ( pxQueue->uxLength * pxQueue->uxItemSize );
    80002842:	7d3c                	ld	a5,120(a0)
    80002844:	6148                	ld	a0,128(a0)
        taskENTER_CRITICAL();
    80002846:	00004497          	auipc	s1,0x4
    8000284a:	01a48493          	addi	s1,s1,26 # 80006860 <xCriticalNesting>
            pxQueue->u.xQueue.pcReadFrom = pxQueue->pcHead + ( ( pxQueue->uxLength - 1U ) * pxQueue->uxItemSize );
    8000284e:	fff78613          	addi	a2,a5,-1
            pxQueue->u.xQueue.pcTail = pxQueue->pcHead + ( pxQueue->uxLength * pxQueue->uxItemSize );
    80002852:	02a78733          	mul	a4,a5,a0
    80002856:	6014                	ld	a3,0(s0)
        taskENTER_CRITICAL();
    80002858:	609c                	ld	a5,0(s1)
            pxQueue->uxMessagesWaiting = ( UBaseType_t ) 0U;
    8000285a:	06043823          	sd	zero,112(s0)
            pxQueue->cRxLock = queueUNLOCKED;
    8000285e:	587d                	li	a6,-1
        taskENTER_CRITICAL();
    80002860:	00178893          	addi	a7,a5,1
            pxQueue->cRxLock = queueUNLOCKED;
    80002864:	09040423          	sb	a6,136(s0)
            pxQueue->pcWriteTo = pxQueue->pcHead;
    80002868:	e414                	sd	a3,8(s0)
        taskENTER_CRITICAL();
    8000286a:	0114b023          	sd	a7,0(s1)
            pxQueue->cTxLock = queueUNLOCKED;
    8000286e:	090404a3          	sb	a6,137(s0)
            pxQueue->u.xQueue.pcReadFrom = pxQueue->pcHead + ( ( pxQueue->uxLength - 1U ) * pxQueue->uxItemSize );
    80002872:	02a60633          	mul	a2,a2,a0
            pxQueue->u.xQueue.pcTail = pxQueue->pcHead + ( pxQueue->uxLength * pxQueue->uxItemSize );
    80002876:	9736                	add	a4,a4,a3
    80002878:	e818                	sd	a4,16(s0)
            pxQueue->u.xQueue.pcReadFrom = pxQueue->pcHead + ( ( pxQueue->uxLength - 1U ) * pxQueue->uxItemSize );
    8000287a:	96b2                	add	a3,a3,a2
    8000287c:	ec14                	sd	a3,24(s0)
            if( xNewQueue == pdFALSE )
    8000287e:	e19d                	bnez	a1,800028a4 <xQueueGenericReset+0x7e>
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
    80002880:	7018                	ld	a4,32(s0)
    80002882:	e321                	bnez	a4,800028c2 <xQueueGenericReset+0x9c>
        taskEXIT_CRITICAL();
    80002884:	e09c                	sd	a5,0(s1)
    80002886:	e399                	bnez	a5,8000288c <xQueueGenericReset+0x66>
    80002888:	30046073          	csrsi	mstatus,8
}
    8000288c:	60e2                	ld	ra,24(sp)
    8000288e:	6442                	ld	s0,16(sp)
    80002890:	64a2                	ld	s1,8(sp)
    80002892:	4505                	li	a0,1
    80002894:	6105                	addi	sp,sp,32
    80002896:	8082                	ret
    configASSERT( xReturn != pdFAIL );
    80002898:	30047073          	csrci	mstatus,8
    8000289c:	a001                	j	8000289c <xQueueGenericReset+0x76>
    configASSERT( pxQueue );
    8000289e:	30047073          	csrci	mstatus,8
    800028a2:	a001                	j	800028a2 <xQueueGenericReset+0x7c>
                vListInitialise( &( pxQueue->xTasksWaitingToSend ) );
    800028a4:	02040513          	addi	a0,s0,32
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	d28080e7          	jalr	-728(ra) # 800025d0 <vListInitialise>
                vListInitialise( &( pxQueue->xTasksWaitingToReceive ) );
    800028b0:	04840513          	addi	a0,s0,72
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	d1c080e7          	jalr	-740(ra) # 800025d0 <vListInitialise>
        taskEXIT_CRITICAL();
    800028bc:	609c                	ld	a5,0(s1)
    800028be:	17fd                	addi	a5,a5,-1
    800028c0:	b7d1                	j	80002884 <xQueueGenericReset+0x5e>
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
    800028c2:	02040513          	addi	a0,s0,32
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	022080e7          	jalr	34(ra) # 800018e8 <xTaskRemoveFromEventList>
    800028ce:	d57d                	beqz	a0,800028bc <xQueueGenericReset+0x96>
                        queueYIELD_IF_USING_PREEMPTION();
    800028d0:	00000073          	ecall
        taskEXIT_CRITICAL();
    800028d4:	609c                	ld	a5,0(s1)
    800028d6:	17fd                	addi	a5,a5,-1
    800028d8:	b775                	j	80002884 <xQueueGenericReset+0x5e>

00000000800028da <xQueueGenericCreate>:
        if( ( uxQueueLength > ( UBaseType_t ) 0 ) &&
    800028da:	c115                	beqz	a0,800028fe <xQueueGenericCreate+0x24>
            ( ( SIZE_MAX / uxQueueLength ) >= uxItemSize ) &&
    800028dc:	02a5b7b3          	mulhu	a5,a1,a0
    {
    800028e0:	7179                	addi	sp,sp,-48
    800028e2:	f022                	sd	s0,32(sp)
    800028e4:	f406                	sd	ra,40(sp)
    800028e6:	ec26                	sd	s1,24(sp)
    800028e8:	842a                	mv	s0,a0
            ( ( SIZE_MAX / uxQueueLength ) >= uxItemSize ) &&
    800028ea:	e799                	bnez	a5,800028f8 <xQueueGenericCreate+0x1e>
            ( ( SIZE_MAX - sizeof( Queue_t ) ) >= ( size_t ) ( ( size_t ) uxQueueLength * ( size_t ) uxItemSize ) ) )
    800028ec:	02b50533          	mul	a0,a0,a1
            ( ( SIZE_MAX / uxQueueLength ) >= uxItemSize ) &&
    800028f0:	f6f00793          	li	a5,-145
    800028f4:	00a7f863          	bgeu	a5,a0,80002904 <xQueueGenericCreate+0x2a>
            configASSERT( pxNewQueue );
    800028f8:	30047073          	csrci	mstatus,8
    800028fc:	a001                	j	800028fc <xQueueGenericCreate+0x22>
    800028fe:	30047073          	csrci	mstatus,8
    80002902:	a001                	j	80002902 <xQueueGenericCreate+0x28>
            pxNewQueue = ( Queue_t * ) pvPortMalloc( sizeof( Queue_t ) + xQueueSizeInBytes );
    80002904:	09050513          	addi	a0,a0,144
    80002908:	e42e                	sd	a1,8(sp)
    8000290a:	00002097          	auipc	ra,0x2
    8000290e:	0c0080e7          	jalr	192(ra) # 800049ca <pvPortMalloc>
    80002912:	84aa                	mv	s1,a0
            if( pxNewQueue != NULL )
    80002914:	cd09                	beqz	a0,8000292e <xQueueGenericCreate+0x54>
    if( uxItemSize == ( UBaseType_t ) 0 )
    80002916:	65a2                	ld	a1,8(sp)
    80002918:	87aa                	mv	a5,a0
    8000291a:	e185                	bnez	a1,8000293a <xQueueGenericCreate+0x60>
    pxNewQueue->uxItemSize = uxItemSize;
    8000291c:	e0cc                	sd	a1,128(s1)
    8000291e:	e09c                	sd	a5,0(s1)
    pxNewQueue->uxLength = uxQueueLength;
    80002920:	fca0                	sd	s0,120(s1)
    ( void ) xQueueGenericReset( pxNewQueue, pdTRUE );
    80002922:	4585                	li	a1,1
    80002924:	8526                	mv	a0,s1
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	f00080e7          	jalr	-256(ra) # 80002826 <xQueueGenericReset>
    }
    8000292e:	70a2                	ld	ra,40(sp)
    80002930:	7402                	ld	s0,32(sp)
    80002932:	8526                	mv	a0,s1
    80002934:	64e2                	ld	s1,24(sp)
    80002936:	6145                	addi	sp,sp,48
    80002938:	8082                	ret
                pucQueueStorage += sizeof( Queue_t );
    8000293a:	09050793          	addi	a5,a0,144
        pxNewQueue->pcHead = ( int8_t * ) pucQueueStorage;
    8000293e:	bff9                	j	8000291c <xQueueGenericCreate+0x42>

0000000080002940 <xQueueCreateCountingSemaphore>:
        if( ( uxMaxCount != 0U ) &&
    80002940:	e501                	bnez	a0,80002948 <xQueueCreateCountingSemaphore+0x8>
            configASSERT( xHandle );
    80002942:	30047073          	csrci	mstatus,8
    80002946:	a001                	j	80002946 <xQueueCreateCountingSemaphore+0x6>
    {
    80002948:	1141                	addi	sp,sp,-16
    8000294a:	e022                	sd	s0,0(sp)
    8000294c:	e406                	sd	ra,8(sp)
    8000294e:	842e                	mv	s0,a1
        if( ( uxMaxCount != 0U ) &&
    80002950:	00b57563          	bgeu	a0,a1,8000295a <xQueueCreateCountingSemaphore+0x1a>
            configASSERT( xHandle );
    80002954:	30047073          	csrci	mstatus,8
    80002958:	a001                	j	80002958 <xQueueCreateCountingSemaphore+0x18>
            xHandle = xQueueGenericCreate( uxMaxCount, queueSEMAPHORE_QUEUE_ITEM_LENGTH, queueQUEUE_TYPE_COUNTING_SEMAPHORE );
    8000295a:	4609                	li	a2,2
    8000295c:	4581                	li	a1,0
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	f7c080e7          	jalr	-132(ra) # 800028da <xQueueGenericCreate>
            if( xHandle != NULL )
    80002966:	c111                	beqz	a0,8000296a <xQueueCreateCountingSemaphore+0x2a>
                ( ( Queue_t * ) xHandle )->uxMessagesWaiting = uxInitialCount;
    80002968:	f920                	sd	s0,112(a0)
    }
    8000296a:	60a2                	ld	ra,8(sp)
    8000296c:	6402                	ld	s0,0(sp)
    8000296e:	0141                	addi	sp,sp,16
    80002970:	8082                	ret

0000000080002972 <xQueueGenericSend>:
{
    80002972:	711d                	addi	sp,sp,-96
    80002974:	ec86                	sd	ra,88(sp)
    80002976:	e8a2                	sd	s0,80(sp)
    80002978:	e4a6                	sd	s1,72(sp)
    8000297a:	e0ca                	sd	s2,64(sp)
    8000297c:	fc4e                	sd	s3,56(sp)
    8000297e:	f852                	sd	s4,48(sp)
    80002980:	f456                	sd	s5,40(sp)
    80002982:	e432                	sd	a2,8(sp)
    configASSERT( pxQueue );
    80002984:	14050763          	beqz	a0,80002ad2 <xQueueGenericSend+0x160>
    80002988:	842a                	mv	s0,a0
    8000298a:	8a2e                	mv	s4,a1
    8000298c:	89b6                	mv	s3,a3
    configASSERT( !( ( pvItemToQueue == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    8000298e:	10058363          	beqz	a1,80002a94 <xQueueGenericSend+0x122>
    configASSERT( !( ( xCopyPosition == queueOVERWRITE ) && ( pxQueue->uxLength != 1 ) ) );
    80002992:	4789                	li	a5,2
    80002994:	00f99963          	bne	s3,a5,800029a6 <xQueueGenericSend+0x34>
    80002998:	7c38                	ld	a4,120(s0)
    8000299a:	4785                	li	a5,1
    8000299c:	00f70563          	beq	a4,a5,800029a6 <xQueueGenericSend+0x34>
    800029a0:	30047073          	csrci	mstatus,8
    800029a4:	a001                	j	800029a4 <xQueueGenericSend+0x32>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	23e080e7          	jalr	574(ra) # 80001be4 <xTaskGetSchedulerState>
    800029ae:	12050563          	beqz	a0,80002ad8 <xQueueGenericSend+0x166>
        taskENTER_CRITICAL();
    800029b2:	30047073          	csrci	mstatus,8
    800029b6:	00004497          	auipc	s1,0x4
    800029ba:	eaa48493          	addi	s1,s1,-342 # 80006860 <xCriticalNesting>
    800029be:	609c                	ld	a5,0(s1)
            if( ( pxQueue->uxMessagesWaiting < pxQueue->uxLength ) || ( xCopyPosition == queueOVERWRITE ) )
    800029c0:	7838                	ld	a4,112(s0)
    800029c2:	7c34                	ld	a3,120(s0)
        taskENTER_CRITICAL();
    800029c4:	00178613          	addi	a2,a5,1
    800029c8:	e090                	sd	a2,0(s1)
            if( ( pxQueue->uxMessagesWaiting < pxQueue->uxLength ) || ( xCopyPosition == queueOVERWRITE ) )
    800029ca:	10d76d63          	bltu	a4,a3,80002ae4 <xQueueGenericSend+0x172>
    800029ce:	4709                	li	a4,2
    800029d0:	10e98a63          	beq	s3,a4,80002ae4 <xQueueGenericSend+0x172>
                if( xTicksToWait == ( TickType_t ) 0 )
    800029d4:	6722                	ld	a4,8(sp)
    800029d6:	c34d                	beqz	a4,80002a78 <xQueueGenericSend+0x106>
                    vTaskInternalSetTimeOutState( &xTimeOut );
    800029d8:	0808                	addi	a0,sp,16
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	140080e7          	jalr	320(ra) # 80001b1a <vTaskInternalSetTimeOutState>
        prvLockQueue( pxQueue );
    800029e2:	597d                	li	s2,-1
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToSend ), xTicksToWait );
    800029e4:	02040a93          	addi	s5,s0,32
        taskEXIT_CRITICAL();
    800029e8:	609c                	ld	a5,0(s1)
    800029ea:	17fd                	addi	a5,a5,-1
    800029ec:	e09c                	sd	a5,0(s1)
    800029ee:	e399                	bnez	a5,800029f4 <xQueueGenericSend+0x82>
    800029f0:	30046073          	csrsi	mstatus,8
        vTaskSuspendAll();
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	b14080e7          	jalr	-1260(ra) # 80001508 <vTaskSuspendAll>
        prvLockQueue( pxQueue );
    800029fc:	30047073          	csrci	mstatus,8
    80002a00:	08844783          	lbu	a5,136(s0)
    80002a04:	6098                	ld	a4,0(s1)
    80002a06:	0187979b          	slliw	a5,a5,0x18
    80002a0a:	4187d79b          	sraiw	a5,a5,0x18
    80002a0e:	01279463          	bne	a5,s2,80002a16 <xQueueGenericSend+0xa4>
    80002a12:	08040423          	sb	zero,136(s0)
    80002a16:	08944783          	lbu	a5,137(s0)
    80002a1a:	0187979b          	slliw	a5,a5,0x18
    80002a1e:	4187d79b          	sraiw	a5,a5,0x18
    80002a22:	07278f63          	beq	a5,s2,80002aa0 <xQueueGenericSend+0x12e>
    80002a26:	e319                	bnez	a4,80002a2c <xQueueGenericSend+0xba>
    80002a28:	30046073          	csrsi	mstatus,8
        if( xTaskCheckForTimeOut( &xTimeOut, &xTicksToWait ) == pdFALSE )
    80002a2c:	002c                	addi	a1,sp,8
    80002a2e:	0808                	addi	a0,sp,16
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	100080e7          	jalr	256(ra) # 80001b30 <xTaskCheckForTimeOut>
    80002a38:	e971                	bnez	a0,80002b0c <xQueueGenericSend+0x19a>

static BaseType_t prvIsQueueFull( const Queue_t * pxQueue )
{
    BaseType_t xReturn;

    taskENTER_CRITICAL();
    80002a3a:	30047073          	csrci	mstatus,8
    {
        if( pxQueue->uxMessagesWaiting == pxQueue->uxLength )
    80002a3e:	7834                	ld	a3,112(s0)
    80002a40:	7c38                	ld	a4,120(s0)
    taskENTER_CRITICAL();
    80002a42:	609c                	ld	a5,0(s1)
        if( pxQueue->uxMessagesWaiting == pxQueue->uxLength )
    80002a44:	06e68163          	beq	a3,a4,80002aa6 <xQueueGenericSend+0x134>
        else
        {
            xReturn = pdFALSE;
        }
    }
    taskEXIT_CRITICAL();
    80002a48:	e399                	bnez	a5,80002a4e <xQueueGenericSend+0xdc>
    80002a4a:	30046073          	csrsi	mstatus,8
                prvUnlockQueue( pxQueue );
    80002a4e:	8522                	mv	a0,s0
    80002a50:	00000097          	auipc	ra,0x0
    80002a54:	cc2080e7          	jalr	-830(ra) # 80002712 <prvUnlockQueue>
                ( void ) xTaskResumeAll();
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	ac0080e7          	jalr	-1344(ra) # 80001518 <xTaskResumeAll>
        taskENTER_CRITICAL();
    80002a60:	30047073          	csrci	mstatus,8
    80002a64:	609c                	ld	a5,0(s1)
            if( ( pxQueue->uxMessagesWaiting < pxQueue->uxLength ) || ( xCopyPosition == queueOVERWRITE ) )
    80002a66:	7834                	ld	a3,112(s0)
    80002a68:	7c38                	ld	a4,120(s0)
        taskENTER_CRITICAL();
    80002a6a:	00178613          	addi	a2,a5,1
    80002a6e:	e090                	sd	a2,0(s1)
            if( ( pxQueue->uxMessagesWaiting < pxQueue->uxLength ) || ( xCopyPosition == queueOVERWRITE ) )
    80002a70:	06e6ea63          	bltu	a3,a4,80002ae4 <xQueueGenericSend+0x172>
                if( xTicksToWait == ( TickType_t ) 0 )
    80002a74:	6722                	ld	a4,8(sp)
    80002a76:	fb2d                	bnez	a4,800029e8 <xQueueGenericSend+0x76>
                    taskEXIT_CRITICAL();
    80002a78:	e09c                	sd	a5,0(s1)
                    return errQUEUE_FULL;
    80002a7a:	4501                	li	a0,0
                    taskEXIT_CRITICAL();
    80002a7c:	e399                	bnez	a5,80002a82 <xQueueGenericSend+0x110>
    80002a7e:	30046073          	csrsi	mstatus,8
}
    80002a82:	60e6                	ld	ra,88(sp)
    80002a84:	6446                	ld	s0,80(sp)
    80002a86:	64a6                	ld	s1,72(sp)
    80002a88:	6906                	ld	s2,64(sp)
    80002a8a:	79e2                	ld	s3,56(sp)
    80002a8c:	7a42                	ld	s4,48(sp)
    80002a8e:	7aa2                	ld	s5,40(sp)
    80002a90:	6125                	addi	sp,sp,96
    80002a92:	8082                	ret
    configASSERT( !( ( pvItemToQueue == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    80002a94:	615c                	ld	a5,128(a0)
    80002a96:	ee078ee3          	beqz	a5,80002992 <xQueueGenericSend+0x20>
    80002a9a:	30047073          	csrci	mstatus,8
    80002a9e:	a001                	j	80002a9e <xQueueGenericSend+0x12c>
        prvLockQueue( pxQueue );
    80002aa0:	080404a3          	sb	zero,137(s0)
    80002aa4:	b749                	j	80002a26 <xQueueGenericSend+0xb4>
    taskEXIT_CRITICAL();
    80002aa6:	e399                	bnez	a5,80002aac <xQueueGenericSend+0x13a>
    80002aa8:	30046073          	csrsi	mstatus,8
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToSend ), xTicksToWait );
    80002aac:	65a2                	ld	a1,8(sp)
    80002aae:	8556                	mv	a0,s5
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	d28080e7          	jalr	-728(ra) # 800017d8 <vTaskPlaceOnEventList>
                prvUnlockQueue( pxQueue );
    80002ab8:	8522                	mv	a0,s0
    80002aba:	00000097          	auipc	ra,0x0
    80002abe:	c58080e7          	jalr	-936(ra) # 80002712 <prvUnlockQueue>
                if( xTaskResumeAll() == pdFALSE )
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	a56080e7          	jalr	-1450(ra) # 80001518 <xTaskResumeAll>
    80002aca:	f959                	bnez	a0,80002a60 <xQueueGenericSend+0xee>
                    taskYIELD_WITHIN_API();
    80002acc:	00000073          	ecall
    80002ad0:	bf41                	j	80002a60 <xQueueGenericSend+0xee>
    configASSERT( pxQueue );
    80002ad2:	30047073          	csrci	mstatus,8
    80002ad6:	a001                	j	80002ad6 <xQueueGenericSend+0x164>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80002ad8:	67a2                	ld	a5,8(sp)
    80002ada:	ec078ce3          	beqz	a5,800029b2 <xQueueGenericSend+0x40>
    80002ade:	30047073          	csrci	mstatus,8
    80002ae2:	a001                	j	80002ae2 <xQueueGenericSend+0x170>
                    xYieldRequired = prvCopyDataToQueue( pxQueue, pvItemToQueue, xCopyPosition );
    80002ae4:	864e                	mv	a2,s3
    80002ae6:	85d2                	mv	a1,s4
    80002ae8:	8522                	mv	a0,s0
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	b74080e7          	jalr	-1164(ra) # 8000265e <prvCopyDataToQueue>
                    if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
    80002af2:	643c                	ld	a5,72(s0)
    80002af4:	e79d                	bnez	a5,80002b22 <xQueueGenericSend+0x1b0>
                    else if( xYieldRequired != pdFALSE )
    80002af6:	c119                	beqz	a0,80002afc <xQueueGenericSend+0x18a>
                        queueYIELD_IF_USING_PREEMPTION();
    80002af8:	00000073          	ecall
                taskEXIT_CRITICAL();
    80002afc:	609c                	ld	a5,0(s1)
                return pdPASS;
    80002afe:	4505                	li	a0,1
                taskEXIT_CRITICAL();
    80002b00:	17fd                	addi	a5,a5,-1
    80002b02:	e09c                	sd	a5,0(s1)
    80002b04:	ffbd                	bnez	a5,80002a82 <xQueueGenericSend+0x110>
                    taskEXIT_CRITICAL();
    80002b06:	30046073          	csrsi	mstatus,8
    80002b0a:	bfa5                	j	80002a82 <xQueueGenericSend+0x110>
            prvUnlockQueue( pxQueue );
    80002b0c:	8522                	mv	a0,s0
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	c04080e7          	jalr	-1020(ra) # 80002712 <prvUnlockQueue>
            ( void ) xTaskResumeAll();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	a02080e7          	jalr	-1534(ra) # 80001518 <xTaskResumeAll>
            return errQUEUE_FULL;
    80002b1e:	4501                	li	a0,0
    80002b20:	b78d                	j	80002a82 <xQueueGenericSend+0x110>
                        if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
    80002b22:	04840513          	addi	a0,s0,72
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	dc2080e7          	jalr	-574(ra) # 800018e8 <xTaskRemoveFromEventList>
    80002b2e:	d579                	beqz	a0,80002afc <xQueueGenericSend+0x18a>
                        queueYIELD_IF_USING_PREEMPTION();
    80002b30:	00000073          	ecall
    80002b34:	b7e1                	j	80002afc <xQueueGenericSend+0x18a>

0000000080002b36 <xQueueCreateMutex>:
    {
    80002b36:	1141                	addi	sp,sp,-16
            pxNewQueue = ( Queue_t * ) pvPortMalloc( sizeof( Queue_t ) + xQueueSizeInBytes );
    80002b38:	09000513          	li	a0,144
    {
    80002b3c:	e022                	sd	s0,0(sp)
    80002b3e:	e406                	sd	ra,8(sp)
            pxNewQueue = ( Queue_t * ) pvPortMalloc( sizeof( Queue_t ) + xQueueSizeInBytes );
    80002b40:	00002097          	auipc	ra,0x2
    80002b44:	e8a080e7          	jalr	-374(ra) # 800049ca <pvPortMalloc>
    80002b48:	842a                	mv	s0,a0
            if( pxNewQueue != NULL )
    80002b4a:	c90d                	beqz	a0,80002b7c <xQueueCreateMutex+0x46>
        pxNewQueue->pcHead = ( int8_t * ) pxNewQueue;
    80002b4c:	e008                	sd	a0,0(s0)
    pxNewQueue->uxLength = uxQueueLength;
    80002b4e:	4785                	li	a5,1
    ( void ) xQueueGenericReset( pxNewQueue, pdTRUE );
    80002b50:	4585                	li	a1,1
    pxNewQueue->uxLength = uxQueueLength;
    80002b52:	fd3c                	sd	a5,120(a0)
    pxNewQueue->uxItemSize = uxItemSize;
    80002b54:	08053023          	sd	zero,128(a0)
    ( void ) xQueueGenericReset( pxNewQueue, pdTRUE );
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	cce080e7          	jalr	-818(ra) # 80002826 <xQueueGenericReset>
            ( void ) xQueueGenericSend( pxNewQueue, NULL, ( TickType_t ) 0U, queueSEND_TO_BACK );
    80002b60:	4681                	li	a3,0
            pxNewQueue->u.xSemaphore.xMutexHolder = NULL;
    80002b62:	00043823          	sd	zero,16(s0)
            pxNewQueue->uxQueueType = queueQUEUE_IS_MUTEX;
    80002b66:	00043023          	sd	zero,0(s0)
            pxNewQueue->u.xSemaphore.uxRecursiveCallCount = 0;
    80002b6a:	00043c23          	sd	zero,24(s0)
            ( void ) xQueueGenericSend( pxNewQueue, NULL, ( TickType_t ) 0U, queueSEND_TO_BACK );
    80002b6e:	4601                	li	a2,0
    80002b70:	4581                	li	a1,0
    80002b72:	8522                	mv	a0,s0
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	dfe080e7          	jalr	-514(ra) # 80002972 <xQueueGenericSend>
    }
    80002b7c:	60a2                	ld	ra,8(sp)
    80002b7e:	8522                	mv	a0,s0
    80002b80:	6402                	ld	s0,0(sp)
    80002b82:	0141                	addi	sp,sp,16
    80002b84:	8082                	ret

0000000080002b86 <xQueueGenericSendFromISR>:
    configASSERT( ( pxQueue != NULL ) && !( ( pvItemToQueue == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    80002b86:	c145                	beqz	a0,80002c26 <xQueueGenericSendFromISR+0xa0>
{
    80002b88:	1101                	addi	sp,sp,-32
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	e426                	sd	s1,8(sp)
    80002b8e:	ec06                	sd	ra,24(sp)
    80002b90:	e04a                	sd	s2,0(sp)
    80002b92:	842a                	mv	s0,a0
    80002b94:	84b2                	mv	s1,a2
    configASSERT( ( pxQueue != NULL ) && !( ( pvItemToQueue == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    80002b96:	cd99                	beqz	a1,80002bb4 <xQueueGenericSendFromISR+0x2e>
    configASSERT( ( pxQueue != NULL ) && !( ( xCopyPosition == queueOVERWRITE ) && ( pxQueue->uxLength != 1 ) ) );
    80002b98:	4789                	li	a5,2
    80002b9a:	7c38                	ld	a4,120(s0)
    80002b9c:	02f68163          	beq	a3,a5,80002bbe <xQueueGenericSendFromISR+0x38>
        if( ( pxQueue->uxMessagesWaiting < pxQueue->uxLength ) || ( xCopyPosition == queueOVERWRITE ) )
    80002ba0:	783c                	ld	a5,112(s0)
    80002ba2:	02e7e563          	bltu	a5,a4,80002bcc <xQueueGenericSendFromISR+0x46>
            xReturn = errQUEUE_FULL;
    80002ba6:	4501                	li	a0,0
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6902                	ld	s2,0(sp)
    80002bb0:	6105                	addi	sp,sp,32
    80002bb2:	8082                	ret
    configASSERT( ( pxQueue != NULL ) && !( ( pvItemToQueue == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    80002bb4:	615c                	ld	a5,128(a0)
    80002bb6:	d3ed                	beqz	a5,80002b98 <xQueueGenericSendFromISR+0x12>
    80002bb8:	30047073          	csrci	mstatus,8
    80002bbc:	a001                	j	80002bbc <xQueueGenericSendFromISR+0x36>
    configASSERT( ( pxQueue != NULL ) && !( ( xCopyPosition == queueOVERWRITE ) && ( pxQueue->uxLength != 1 ) ) );
    80002bbe:	4785                	li	a5,1
    80002bc0:	00f70563          	beq	a4,a5,80002bca <xQueueGenericSendFromISR+0x44>
    80002bc4:	30047073          	csrci	mstatus,8
    80002bc8:	a001                	j	80002bc8 <xQueueGenericSendFromISR+0x42>
        if( ( pxQueue->uxMessagesWaiting < pxQueue->uxLength ) || ( xCopyPosition == queueOVERWRITE ) )
    80002bca:	783c                	ld	a5,112(s0)
            const int8_t cTxLock = pxQueue->cTxLock;
    80002bcc:	08944903          	lbu	s2,137(s0)
            const UBaseType_t uxPreviousMessagesWaiting = pxQueue->uxMessagesWaiting;
    80002bd0:	783c                	ld	a5,112(s0)
            ( void ) prvCopyDataToQueue( pxQueue, pvItemToQueue, xCopyPosition );
    80002bd2:	8636                	mv	a2,a3
    80002bd4:	8522                	mv	a0,s0
            const int8_t cTxLock = pxQueue->cTxLock;
    80002bd6:	0189191b          	slliw	s2,s2,0x18
            ( void ) prvCopyDataToQueue( pxQueue, pvItemToQueue, xCopyPosition );
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	a84080e7          	jalr	-1404(ra) # 8000265e <prvCopyDataToQueue>
            const int8_t cTxLock = pxQueue->cTxLock;
    80002be2:	4189591b          	sraiw	s2,s2,0x18
            if( cTxLock == queueUNLOCKED )
    80002be6:	57fd                	li	a5,-1
    80002be8:	00f91b63          	bne	s2,a5,80002bfe <xQueueGenericSendFromISR+0x78>
                    if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
    80002bec:	643c                	ld	a5,72(s0)
    80002bee:	ef9d                	bnez	a5,80002c2c <xQueueGenericSendFromISR+0xa6>
            xReturn = pdPASS;
    80002bf0:	4505                	li	a0,1
}
    80002bf2:	60e2                	ld	ra,24(sp)
    80002bf4:	6442                	ld	s0,16(sp)
    80002bf6:	64a2                	ld	s1,8(sp)
    80002bf8:	6902                	ld	s2,0(sp)
    80002bfa:	6105                	addi	sp,sp,32
    80002bfc:	8082                	ret
                prvIncrementQueueTxLock( pxQueue, cTxLock );
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	958080e7          	jalr	-1704(ra) # 80001556 <uxTaskGetNumberOfTasks>
    80002c06:	fea975e3          	bgeu	s2,a0,80002bf0 <xQueueGenericSendFromISR+0x6a>
    80002c0a:	07f00793          	li	a5,127
    80002c0e:	02f90b63          	beq	s2,a5,80002c44 <xQueueGenericSendFromISR+0xbe>
    80002c12:	0019079b          	addiw	a5,s2,1
    80002c16:	0187979b          	slliw	a5,a5,0x18
    80002c1a:	4187d79b          	sraiw	a5,a5,0x18
    80002c1e:	08f404a3          	sb	a5,137(s0)
            xReturn = pdPASS;
    80002c22:	4505                	li	a0,1
    return xReturn;
    80002c24:	b751                	j	80002ba8 <xQueueGenericSendFromISR+0x22>
    configASSERT( ( pxQueue != NULL ) && !( ( pvItemToQueue == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    80002c26:	30047073          	csrci	mstatus,8
    80002c2a:	a001                	j	80002c2a <xQueueGenericSendFromISR+0xa4>
                        if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
    80002c2c:	04840513          	addi	a0,s0,72
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	cb8080e7          	jalr	-840(ra) # 800018e8 <xTaskRemoveFromEventList>
    80002c38:	dd45                	beqz	a0,80002bf0 <xQueueGenericSendFromISR+0x6a>
                            if( pxHigherPriorityTaskWoken != NULL )
    80002c3a:	d8dd                	beqz	s1,80002bf0 <xQueueGenericSendFromISR+0x6a>
                                *pxHigherPriorityTaskWoken = pdTRUE;
    80002c3c:	4785                	li	a5,1
    80002c3e:	e09c                	sd	a5,0(s1)
            xReturn = pdPASS;
    80002c40:	4505                	li	a0,1
    80002c42:	bf45                	j	80002bf2 <xQueueGenericSendFromISR+0x6c>
                prvIncrementQueueTxLock( pxQueue, cTxLock );
    80002c44:	30047073          	csrci	mstatus,8
    80002c48:	a001                	j	80002c48 <xQueueGenericSendFromISR+0xc2>

0000000080002c4a <xQueueGiveFromISR>:
    configASSERT( ( pxQueue != NULL ) && ( pxQueue->uxItemSize == 0 ) );
    80002c4a:	c931                	beqz	a0,80002c9e <xQueueGiveFromISR+0x54>
    80002c4c:	615c                	ld	a5,128(a0)
{
    80002c4e:	7179                	addi	sp,sp,-48
    80002c50:	f022                	sd	s0,32(sp)
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	ec26                	sd	s1,24(sp)
    80002c56:	842a                	mv	s0,a0
    configASSERT( ( pxQueue != NULL ) && ( pxQueue->uxItemSize == 0 ) );
    80002c58:	eb95                	bnez	a5,80002c8c <xQueueGiveFromISR+0x42>
    configASSERT( ( pxQueue != NULL ) && !( ( pxQueue->uxQueueType == queueQUEUE_IS_MUTEX ) && ( pxQueue->u.xSemaphore.xMutexHolder != NULL ) ) );
    80002c5a:	611c                	ld	a5,0(a0)
    80002c5c:	c7a1                	beqz	a5,80002ca4 <xQueueGiveFromISR+0x5a>
        const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    80002c5e:	783c                	ld	a5,112(s0)
        if( uxMessagesWaiting < pxQueue->uxLength )
    80002c60:	7c38                	ld	a4,120(s0)
    80002c62:	02e7f863          	bgeu	a5,a4,80002c92 <xQueueGiveFromISR+0x48>
            const int8_t cTxLock = pxQueue->cTxLock;
    80002c66:	08944483          	lbu	s1,137(s0)
            pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting + ( UBaseType_t ) 1 );
    80002c6a:	0785                	addi	a5,a5,1
    80002c6c:	f83c                	sd	a5,112(s0)
            const int8_t cTxLock = pxQueue->cTxLock;
    80002c6e:	0184949b          	slliw	s1,s1,0x18
    80002c72:	4184d49b          	sraiw	s1,s1,0x18
            if( cTxLock == queueUNLOCKED )
    80002c76:	57fd                	li	a5,-1
    80002c78:	02f49b63          	bne	s1,a5,80002cae <xQueueGiveFromISR+0x64>
                    if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
    80002c7c:	643c                	ld	a5,72(s0)
    80002c7e:	efa1                	bnez	a5,80002cd6 <xQueueGiveFromISR+0x8c>
            xReturn = pdPASS;
    80002c80:	4505                	li	a0,1
}
    80002c82:	70a2                	ld	ra,40(sp)
    80002c84:	7402                	ld	s0,32(sp)
    80002c86:	64e2                	ld	s1,24(sp)
    80002c88:	6145                	addi	sp,sp,48
    80002c8a:	8082                	ret
    configASSERT( ( pxQueue != NULL ) && ( pxQueue->uxItemSize == 0 ) );
    80002c8c:	30047073          	csrci	mstatus,8
    80002c90:	a001                	j	80002c90 <xQueueGiveFromISR+0x46>
            xReturn = errQUEUE_FULL;
    80002c92:	4501                	li	a0,0
}
    80002c94:	70a2                	ld	ra,40(sp)
    80002c96:	7402                	ld	s0,32(sp)
    80002c98:	64e2                	ld	s1,24(sp)
    80002c9a:	6145                	addi	sp,sp,48
    80002c9c:	8082                	ret
    configASSERT( ( pxQueue != NULL ) && ( pxQueue->uxItemSize == 0 ) );
    80002c9e:	30047073          	csrci	mstatus,8
    80002ca2:	a001                	j	80002ca2 <xQueueGiveFromISR+0x58>
    configASSERT( ( pxQueue != NULL ) && !( ( pxQueue->uxQueueType == queueQUEUE_IS_MUTEX ) && ( pxQueue->u.xSemaphore.xMutexHolder != NULL ) ) );
    80002ca4:	691c                	ld	a5,16(a0)
    80002ca6:	dfc5                	beqz	a5,80002c5e <xQueueGiveFromISR+0x14>
    80002ca8:	30047073          	csrci	mstatus,8
    80002cac:	a001                	j	80002cac <xQueueGiveFromISR+0x62>
                prvIncrementQueueTxLock( pxQueue, cTxLock );
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	8a8080e7          	jalr	-1880(ra) # 80001556 <uxTaskGetNumberOfTasks>
    80002cb6:	fca4f5e3          	bgeu	s1,a0,80002c80 <xQueueGiveFromISR+0x36>
    80002cba:	07f00793          	li	a5,127
    80002cbe:	02f48a63          	beq	s1,a5,80002cf2 <xQueueGiveFromISR+0xa8>
    80002cc2:	0014879b          	addiw	a5,s1,1
    80002cc6:	0187979b          	slliw	a5,a5,0x18
    80002cca:	4187d79b          	sraiw	a5,a5,0x18
    80002cce:	08f404a3          	sb	a5,137(s0)
            xReturn = pdPASS;
    80002cd2:	4505                	li	a0,1
    80002cd4:	b7c1                	j	80002c94 <xQueueGiveFromISR+0x4a>
                        if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
    80002cd6:	04840513          	addi	a0,s0,72
    80002cda:	e42e                	sd	a1,8(sp)
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	c0c080e7          	jalr	-1012(ra) # 800018e8 <xTaskRemoveFromEventList>
    80002ce4:	dd51                	beqz	a0,80002c80 <xQueueGiveFromISR+0x36>
                            if( pxHigherPriorityTaskWoken != NULL )
    80002ce6:	65a2                	ld	a1,8(sp)
    80002ce8:	ddc1                	beqz	a1,80002c80 <xQueueGiveFromISR+0x36>
                                *pxHigherPriorityTaskWoken = pdTRUE;
    80002cea:	4785                	li	a5,1
    80002cec:	e19c                	sd	a5,0(a1)
            xReturn = pdPASS;
    80002cee:	4505                	li	a0,1
    80002cf0:	bf49                	j	80002c82 <xQueueGiveFromISR+0x38>
                prvIncrementQueueTxLock( pxQueue, cTxLock );
    80002cf2:	30047073          	csrci	mstatus,8
    80002cf6:	a001                	j	80002cf6 <xQueueGiveFromISR+0xac>

0000000080002cf8 <xQueueReceive>:
{
    80002cf8:	711d                	addi	sp,sp,-96
    80002cfa:	ec86                	sd	ra,88(sp)
    80002cfc:	e8a2                	sd	s0,80(sp)
    80002cfe:	e4a6                	sd	s1,72(sp)
    80002d00:	e0ca                	sd	s2,64(sp)
    80002d02:	fc4e                	sd	s3,56(sp)
    80002d04:	f852                	sd	s4,48(sp)
    80002d06:	f456                	sd	s5,40(sp)
    80002d08:	e432                	sd	a2,8(sp)
    configASSERT( ( pxQueue ) );
    80002d0a:	1a050063          	beqz	a0,80002eaa <xQueueReceive+0x1b2>
    80002d0e:	842a                	mv	s0,a0
    80002d10:	8a2e                	mv	s4,a1
    configASSERT( !( ( ( pvBuffer ) == NULL ) && ( ( pxQueue )->uxItemSize != ( UBaseType_t ) 0U ) ) );
    80002d12:	c9ed                	beqz	a1,80002e04 <xQueueReceive+0x10c>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	ed0080e7          	jalr	-304(ra) # 80001be4 <xTaskGetSchedulerState>
    80002d1c:	cd65                	beqz	a0,80002e14 <xQueueReceive+0x11c>
        taskENTER_CRITICAL();
    80002d1e:	30047073          	csrci	mstatus,8
    80002d22:	00004497          	auipc	s1,0x4
    80002d26:	b3e48493          	addi	s1,s1,-1218 # 80006860 <xCriticalNesting>
    80002d2a:	609c                	ld	a5,0(s1)
            const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    80002d2c:	07043983          	ld	s3,112(s0)
        taskENTER_CRITICAL();
    80002d30:	00178713          	addi	a4,a5,1
    80002d34:	e098                	sd	a4,0(s1)
            if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    80002d36:	10099a63          	bnez	s3,80002e4a <xQueueReceive+0x152>
                if( xTicksToWait == ( TickType_t ) 0 )
    80002d3a:	6722                	ld	a4,8(sp)
    80002d3c:	cb45                	beqz	a4,80002dec <xQueueReceive+0xf4>
                    vTaskInternalSetTimeOutState( &xTimeOut );
    80002d3e:	0808                	addi	a0,sp,16
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	dda080e7          	jalr	-550(ra) # 80001b1a <vTaskInternalSetTimeOutState>
        prvLockQueue( pxQueue );
    80002d48:	597d                	li	s2,-1
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait );
    80002d4a:	04840a93          	addi	s5,s0,72
        taskEXIT_CRITICAL();
    80002d4e:	609c                	ld	a5,0(s1)
    80002d50:	17fd                	addi	a5,a5,-1
    80002d52:	e09c                	sd	a5,0(s1)
    80002d54:	e399                	bnez	a5,80002d5a <xQueueReceive+0x62>
    80002d56:	30046073          	csrsi	mstatus,8
        vTaskSuspendAll();
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	7ae080e7          	jalr	1966(ra) # 80001508 <vTaskSuspendAll>
        prvLockQueue( pxQueue );
    80002d62:	30047073          	csrci	mstatus,8
    80002d66:	08844783          	lbu	a5,136(s0)
    80002d6a:	6098                	ld	a4,0(s1)
    80002d6c:	0187979b          	slliw	a5,a5,0x18
    80002d70:	4187d79b          	sraiw	a5,a5,0x18
    80002d74:	01279463          	bne	a5,s2,80002d7c <xQueueReceive+0x84>
    80002d78:	08040423          	sb	zero,136(s0)
    80002d7c:	08944783          	lbu	a5,137(s0)
    80002d80:	0187979b          	slliw	a5,a5,0x18
    80002d84:	4187d79b          	sraiw	a5,a5,0x18
    80002d88:	09278363          	beq	a5,s2,80002e0e <xQueueReceive+0x116>
    80002d8c:	e319                	bnez	a4,80002d92 <xQueueReceive+0x9a>
    80002d8e:	30046073          	csrsi	mstatus,8
        if( xTaskCheckForTimeOut( &xTimeOut, &xTicksToWait ) == pdFALSE )
    80002d92:	002c                	addi	a1,sp,8
    80002d94:	0808                	addi	a0,sp,16
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	d9a080e7          	jalr	-614(ra) # 80001b30 <xTaskCheckForTimeOut>
    80002d9e:	e165                	bnez	a0,80002e7e <xQueueReceive+0x186>
    taskENTER_CRITICAL();
    80002da0:	30047073          	csrci	mstatus,8
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80002da4:	783c                	ld	a5,112(s0)
    taskENTER_CRITICAL();
    80002da6:	6098                	ld	a4,0(s1)
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80002da8:	ebbd                	bnez	a5,80002e1e <xQueueReceive+0x126>
    taskEXIT_CRITICAL();
    80002daa:	e319                	bnez	a4,80002db0 <xQueueReceive+0xb8>
    80002dac:	30046073          	csrsi	mstatus,8
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait );
    80002db0:	65a2                	ld	a1,8(sp)
    80002db2:	8556                	mv	a0,s5
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	a24080e7          	jalr	-1500(ra) # 800017d8 <vTaskPlaceOnEventList>
                prvUnlockQueue( pxQueue );
    80002dbc:	8522                	mv	a0,s0
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	954080e7          	jalr	-1708(ra) # 80002712 <prvUnlockQueue>
                if( xTaskResumeAll() == pdFALSE )
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	752080e7          	jalr	1874(ra) # 80001518 <xTaskResumeAll>
    80002dce:	e119                	bnez	a0,80002dd4 <xQueueReceive+0xdc>
                    taskYIELD_WITHIN_API();
    80002dd0:	00000073          	ecall
        taskENTER_CRITICAL();
    80002dd4:	30047073          	csrci	mstatus,8
    80002dd8:	609c                	ld	a5,0(s1)
            const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    80002dda:	07043983          	ld	s3,112(s0)
        taskENTER_CRITICAL();
    80002dde:	00178713          	addi	a4,a5,1
    80002de2:	e098                	sd	a4,0(s1)
            if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    80002de4:	06099363          	bnez	s3,80002e4a <xQueueReceive+0x152>
                if( xTicksToWait == ( TickType_t ) 0 )
    80002de8:	6722                	ld	a4,8(sp)
    80002dea:	f335                	bnez	a4,80002d4e <xQueueReceive+0x56>
                    taskEXIT_CRITICAL();
    80002dec:	e09c                	sd	a5,0(s1)
    80002dee:	c7dd                	beqz	a5,80002e9c <xQueueReceive+0x1a4>
                return errQUEUE_EMPTY;
    80002df0:	4501                	li	a0,0
}
    80002df2:	60e6                	ld	ra,88(sp)
    80002df4:	6446                	ld	s0,80(sp)
    80002df6:	64a6                	ld	s1,72(sp)
    80002df8:	6906                	ld	s2,64(sp)
    80002dfa:	79e2                	ld	s3,56(sp)
    80002dfc:	7a42                	ld	s4,48(sp)
    80002dfe:	7aa2                	ld	s5,40(sp)
    80002e00:	6125                	addi	sp,sp,96
    80002e02:	8082                	ret
    configASSERT( !( ( ( pvBuffer ) == NULL ) && ( ( pxQueue )->uxItemSize != ( UBaseType_t ) 0U ) ) );
    80002e04:	615c                	ld	a5,128(a0)
    80002e06:	d799                	beqz	a5,80002d14 <xQueueReceive+0x1c>
    80002e08:	30047073          	csrci	mstatus,8
    80002e0c:	a001                	j	80002e0c <xQueueReceive+0x114>
        prvLockQueue( pxQueue );
    80002e0e:	080404a3          	sb	zero,137(s0)
    80002e12:	bfad                	j	80002d8c <xQueueReceive+0x94>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80002e14:	67a2                	ld	a5,8(sp)
    80002e16:	d781                	beqz	a5,80002d1e <xQueueReceive+0x26>
    80002e18:	30047073          	csrci	mstatus,8
    80002e1c:	a001                	j	80002e1c <xQueueReceive+0x124>
    taskEXIT_CRITICAL();
    80002e1e:	e319                	bnez	a4,80002e24 <xQueueReceive+0x12c>
    80002e20:	30046073          	csrsi	mstatus,8
                prvUnlockQueue( pxQueue );
    80002e24:	8522                	mv	a0,s0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	8ec080e7          	jalr	-1812(ra) # 80002712 <prvUnlockQueue>
                ( void ) xTaskResumeAll();
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	6ea080e7          	jalr	1770(ra) # 80001518 <xTaskResumeAll>
        taskENTER_CRITICAL();
    80002e36:	30047073          	csrci	mstatus,8
    80002e3a:	609c                	ld	a5,0(s1)
            const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    80002e3c:	07043983          	ld	s3,112(s0)
        taskENTER_CRITICAL();
    80002e40:	00178713          	addi	a4,a5,1
    80002e44:	e098                	sd	a4,0(s1)
            if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    80002e46:	fa0981e3          	beqz	s3,80002de8 <xQueueReceive+0xf0>
    if( pxQueue->uxItemSize != ( UBaseType_t ) 0 )
    80002e4a:	6050                	ld	a2,128(s0)
    80002e4c:	ce01                	beqz	a2,80002e64 <xQueueReceive+0x16c>
        pxQueue->u.xQueue.pcReadFrom += pxQueue->uxItemSize;
    80002e4e:	6c0c                	ld	a1,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    80002e50:	681c                	ld	a5,16(s0)
        pxQueue->u.xQueue.pcReadFrom += pxQueue->uxItemSize;
    80002e52:	95b2                	add	a1,a1,a2
    80002e54:	ec0c                	sd	a1,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    80002e56:	06f5f763          	bgeu	a1,a5,80002ec4 <xQueueReceive+0x1cc>
    80002e5a:	8552                	mv	a0,s4
    80002e5c:	00003097          	auipc	ra,0x3
    80002e60:	968080e7          	jalr	-1688(ra) # 800057c4 <memcpy>
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
    80002e64:	701c                	ld	a5,32(s0)
                pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting - ( UBaseType_t ) 1 );
    80002e66:	19fd                	addi	s3,s3,-1
    80002e68:	07343823          	sd	s3,112(s0)
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
    80002e6c:	e3b1                	bnez	a5,80002eb0 <xQueueReceive+0x1b8>
                taskEXIT_CRITICAL();
    80002e6e:	609c                	ld	a5,0(s1)
                return pdPASS;
    80002e70:	4505                	li	a0,1
                taskEXIT_CRITICAL();
    80002e72:	17fd                	addi	a5,a5,-1
    80002e74:	e09c                	sd	a5,0(s1)
    80002e76:	ffb5                	bnez	a5,80002df2 <xQueueReceive+0xfa>
    80002e78:	30046073          	csrsi	mstatus,8
    80002e7c:	bf9d                	j	80002df2 <xQueueReceive+0xfa>
            prvUnlockQueue( pxQueue );
    80002e7e:	8522                	mv	a0,s0
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	892080e7          	jalr	-1902(ra) # 80002712 <prvUnlockQueue>
            ( void ) xTaskResumeAll();
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	690080e7          	jalr	1680(ra) # 80001518 <xTaskResumeAll>
    taskENTER_CRITICAL();
    80002e90:	30047073          	csrci	mstatus,8
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80002e94:	783c                	ld	a5,112(s0)
    taskENTER_CRITICAL();
    80002e96:	6098                	ld	a4,0(s1)
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80002e98:	e789                	bnez	a5,80002ea2 <xQueueReceive+0x1aa>
    taskEXIT_CRITICAL();
    80002e9a:	fb39                	bnez	a4,80002df0 <xQueueReceive+0xf8>
    80002e9c:	30046073          	csrsi	mstatus,8
    80002ea0:	bf81                	j	80002df0 <xQueueReceive+0xf8>
    80002ea2:	fb0d                	bnez	a4,80002dd4 <xQueueReceive+0xdc>
    80002ea4:	30046073          	csrsi	mstatus,8
    return xReturn;
    80002ea8:	b735                	j	80002dd4 <xQueueReceive+0xdc>
    configASSERT( ( pxQueue ) );
    80002eaa:	30047073          	csrci	mstatus,8
    80002eae:	a001                	j	80002eae <xQueueReceive+0x1b6>
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
    80002eb0:	02040513          	addi	a0,s0,32
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	a34080e7          	jalr	-1484(ra) # 800018e8 <xTaskRemoveFromEventList>
    80002ebc:	d94d                	beqz	a0,80002e6e <xQueueReceive+0x176>
                        queueYIELD_IF_USING_PREEMPTION();
    80002ebe:	00000073          	ecall
    80002ec2:	b775                	j	80002e6e <xQueueReceive+0x176>
            pxQueue->u.xQueue.pcReadFrom = pxQueue->pcHead;
    80002ec4:	600c                	ld	a1,0(s0)
    80002ec6:	ec0c                	sd	a1,24(s0)
    80002ec8:	bf49                	j	80002e5a <xQueueReceive+0x162>

0000000080002eca <xQueueSemaphoreTake>:
{
    80002eca:	715d                	addi	sp,sp,-80
    80002ecc:	e486                	sd	ra,72(sp)
    80002ece:	e0a2                	sd	s0,64(sp)
    80002ed0:	fc26                	sd	s1,56(sp)
    80002ed2:	f84a                	sd	s2,48(sp)
    80002ed4:	f44e                	sd	s3,40(sp)
    80002ed6:	f052                	sd	s4,32(sp)
    80002ed8:	e42e                	sd	a1,8(sp)
    configASSERT( ( pxQueue ) );
    80002eda:	10050963          	beqz	a0,80002fec <xQueueSemaphoreTake+0x122>
    configASSERT( pxQueue->uxItemSize == 0 );
    80002ede:	615c                	ld	a5,128(a0)
    80002ee0:	842a                	mv	s0,a0
    80002ee2:	c781                	beqz	a5,80002eea <xQueueSemaphoreTake+0x20>
    80002ee4:	30047073          	csrci	mstatus,8
    80002ee8:	a001                	j	80002ee8 <xQueueSemaphoreTake+0x1e>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	cfa080e7          	jalr	-774(ra) # 80001be4 <xTaskGetSchedulerState>
    80002ef2:	10050363          	beqz	a0,80002ff8 <xQueueSemaphoreTake+0x12e>
        taskENTER_CRITICAL();
    80002ef6:	30047073          	csrci	mstatus,8
    80002efa:	00004497          	auipc	s1,0x4
    80002efe:	96648493          	addi	s1,s1,-1690 # 80006860 <xCriticalNesting>
    80002f02:	6098                	ld	a4,0(s1)
            const UBaseType_t uxSemaphoreCount = pxQueue->uxMessagesWaiting;
    80002f04:	783c                	ld	a5,112(s0)
        taskENTER_CRITICAL();
    80002f06:	00170693          	addi	a3,a4,1
    80002f0a:	e094                	sd	a3,0(s1)
            if( uxSemaphoreCount > ( UBaseType_t ) 0 )
    80002f0c:	ebd5                	bnez	a5,80002fc0 <xQueueSemaphoreTake+0xf6>
    80002f0e:	4a01                	li	s4,0
    80002f10:	4681                	li	a3,0
        prvLockQueue( pxQueue );
    80002f12:	597d                	li	s2,-1
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait );
    80002f14:	04840993          	addi	s3,s0,72
                if( xTicksToWait == ( TickType_t ) 0 )
    80002f18:	67a2                	ld	a5,8(sp)
    80002f1a:	18078a63          	beqz	a5,800030ae <xQueueSemaphoreTake+0x1e4>
                else if( xEntryTimeSet == pdFALSE )
    80002f1e:	14068b63          	beqz	a3,80003074 <xQueueSemaphoreTake+0x1aa>
        taskEXIT_CRITICAL();
    80002f22:	609c                	ld	a5,0(s1)
    80002f24:	17fd                	addi	a5,a5,-1
    80002f26:	e09c                	sd	a5,0(s1)
    80002f28:	e399                	bnez	a5,80002f2e <xQueueSemaphoreTake+0x64>
    80002f2a:	30046073          	csrsi	mstatus,8
        vTaskSuspendAll();
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	5da080e7          	jalr	1498(ra) # 80001508 <vTaskSuspendAll>
        prvLockQueue( pxQueue );
    80002f36:	30047073          	csrci	mstatus,8
    80002f3a:	08844783          	lbu	a5,136(s0)
    80002f3e:	6098                	ld	a4,0(s1)
    80002f40:	0187979b          	slliw	a5,a5,0x18
    80002f44:	4187d79b          	sraiw	a5,a5,0x18
    80002f48:	01279463          	bne	a5,s2,80002f50 <xQueueSemaphoreTake+0x86>
    80002f4c:	08040423          	sb	zero,136(s0)
    80002f50:	08944783          	lbu	a5,137(s0)
    80002f54:	0187979b          	slliw	a5,a5,0x18
    80002f58:	4187d79b          	sraiw	a5,a5,0x18
    80002f5c:	09278b63          	beq	a5,s2,80002ff2 <xQueueSemaphoreTake+0x128>
    80002f60:	e319                	bnez	a4,80002f66 <xQueueSemaphoreTake+0x9c>
    80002f62:	30046073          	csrsi	mstatus,8
        if( xTaskCheckForTimeOut( &xTimeOut, &xTicksToWait ) == pdFALSE )
    80002f66:	002c                	addi	a1,sp,8
    80002f68:	0808                	addi	a0,sp,16
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	bc6080e7          	jalr	-1082(ra) # 80001b30 <xTaskCheckForTimeOut>
    80002f72:	e555                	bnez	a0,8000301e <xQueueSemaphoreTake+0x154>
    taskENTER_CRITICAL();
    80002f74:	30047073          	csrci	mstatus,8
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80002f78:	783c                	ld	a5,112(s0)
    taskENTER_CRITICAL();
    80002f7a:	6098                	ld	a4,0(s1)
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80002f7c:	e7c1                	bnez	a5,80003004 <xQueueSemaphoreTake+0x13a>
    taskEXIT_CRITICAL();
    80002f7e:	e319                	bnez	a4,80002f84 <xQueueSemaphoreTake+0xba>
    80002f80:	30046073          	csrsi	mstatus,8
                    if( pxQueue->uxQueueType == queueQUEUE_IS_MUTEX )
    80002f84:	601c                	ld	a5,0(s0)
    80002f86:	10078163          	beqz	a5,80003088 <xQueueSemaphoreTake+0x1be>
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait );
    80002f8a:	65a2                	ld	a1,8(sp)
    80002f8c:	854e                	mv	a0,s3
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	84a080e7          	jalr	-1974(ra) # 800017d8 <vTaskPlaceOnEventList>
                prvUnlockQueue( pxQueue );
    80002f96:	8522                	mv	a0,s0
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	77a080e7          	jalr	1914(ra) # 80002712 <prvUnlockQueue>
                if( xTaskResumeAll() == pdFALSE )
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	578080e7          	jalr	1400(ra) # 80001518 <xTaskResumeAll>
    80002fa8:	e119                	bnez	a0,80002fae <xQueueSemaphoreTake+0xe4>
                    taskYIELD_WITHIN_API();
    80002faa:	00000073          	ecall
        taskENTER_CRITICAL();
    80002fae:	30047073          	csrci	mstatus,8
    80002fb2:	6098                	ld	a4,0(s1)
            const UBaseType_t uxSemaphoreCount = pxQueue->uxMessagesWaiting;
    80002fb4:	783c                	ld	a5,112(s0)
    80002fb6:	4685                	li	a3,1
        taskENTER_CRITICAL();
    80002fb8:	00170613          	addi	a2,a4,1
    80002fbc:	e090                	sd	a2,0(s1)
            if( uxSemaphoreCount > ( UBaseType_t ) 0 )
    80002fbe:	dfa9                	beqz	a5,80002f18 <xQueueSemaphoreTake+0x4e>
                    if( pxQueue->uxQueueType == queueQUEUE_IS_MUTEX )
    80002fc0:	6018                	ld	a4,0(s0)
                pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxSemaphoreCount - ( UBaseType_t ) 1 );
    80002fc2:	17fd                	addi	a5,a5,-1
    80002fc4:	f83c                	sd	a5,112(s0)
                    if( pxQueue->uxQueueType == queueQUEUE_IS_MUTEX )
    80002fc6:	10070363          	beqz	a4,800030cc <xQueueSemaphoreTake+0x202>
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
    80002fca:	701c                	ld	a5,32(s0)
    80002fcc:	e7f5                	bnez	a5,800030b8 <xQueueSemaphoreTake+0x1ee>
                taskEXIT_CRITICAL();
    80002fce:	609c                	ld	a5,0(s1)
                return pdPASS;
    80002fd0:	4505                	li	a0,1
                taskEXIT_CRITICAL();
    80002fd2:	17fd                	addi	a5,a5,-1
    80002fd4:	e09c                	sd	a5,0(s1)
    80002fd6:	e399                	bnez	a5,80002fdc <xQueueSemaphoreTake+0x112>
    80002fd8:	30046073          	csrsi	mstatus,8
}
    80002fdc:	60a6                	ld	ra,72(sp)
    80002fde:	6406                	ld	s0,64(sp)
    80002fe0:	74e2                	ld	s1,56(sp)
    80002fe2:	7942                	ld	s2,48(sp)
    80002fe4:	79a2                	ld	s3,40(sp)
    80002fe6:	7a02                	ld	s4,32(sp)
    80002fe8:	6161                	addi	sp,sp,80
    80002fea:	8082                	ret
    configASSERT( ( pxQueue ) );
    80002fec:	30047073          	csrci	mstatus,8
    80002ff0:	a001                	j	80002ff0 <xQueueSemaphoreTake+0x126>
        prvLockQueue( pxQueue );
    80002ff2:	080404a3          	sb	zero,137(s0)
    80002ff6:	b7ad                	j	80002f60 <xQueueSemaphoreTake+0x96>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80002ff8:	67a2                	ld	a5,8(sp)
    80002ffa:	ee078ee3          	beqz	a5,80002ef6 <xQueueSemaphoreTake+0x2c>
    80002ffe:	30047073          	csrci	mstatus,8
    80003002:	a001                	j	80003002 <xQueueSemaphoreTake+0x138>
    taskEXIT_CRITICAL();
    80003004:	e319                	bnez	a4,8000300a <xQueueSemaphoreTake+0x140>
    80003006:	30046073          	csrsi	mstatus,8
                prvUnlockQueue( pxQueue );
    8000300a:	8522                	mv	a0,s0
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	706080e7          	jalr	1798(ra) # 80002712 <prvUnlockQueue>
                ( void ) xTaskResumeAll();
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	504080e7          	jalr	1284(ra) # 80001518 <xTaskResumeAll>
    8000301c:	bf49                	j	80002fae <xQueueSemaphoreTake+0xe4>
            prvUnlockQueue( pxQueue );
    8000301e:	8522                	mv	a0,s0
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	6f2080e7          	jalr	1778(ra) # 80002712 <prvUnlockQueue>
            ( void ) xTaskResumeAll();
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	4f0080e7          	jalr	1264(ra) # 80001518 <xTaskResumeAll>
    taskENTER_CRITICAL();
    80003030:	30047073          	csrci	mstatus,8
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80003034:	783c                	ld	a5,112(s0)
    taskENTER_CRITICAL();
    80003036:	6098                	ld	a4,0(s1)
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80003038:	e7a1                	bnez	a5,80003080 <xQueueSemaphoreTake+0x1b6>
    taskEXIT_CRITICAL();
    8000303a:	e319                	bnez	a4,80003040 <xQueueSemaphoreTake+0x176>
    8000303c:	30046073          	csrsi	mstatus,8
                    if( xInheritanceOccurred != pdFALSE )
    80003040:	020a0863          	beqz	s4,80003070 <xQueueSemaphoreTake+0x1a6>
                        taskENTER_CRITICAL();
    80003044:	30047073          	csrci	mstatus,8
    80003048:	609c                	ld	a5,0(s1)
        if( listCURRENT_LIST_LENGTH( &( pxQueue->xTasksWaitingToReceive ) ) > 0U )
    8000304a:	642c                	ld	a1,72(s0)
                        taskENTER_CRITICAL();
    8000304c:	0785                	addi	a5,a5,1
    8000304e:	e09c                	sd	a5,0(s1)
        if( listCURRENT_LIST_LENGTH( &( pxQueue->xTasksWaitingToReceive ) ) > 0U )
    80003050:	c589                	beqz	a1,8000305a <xQueueSemaphoreTake+0x190>
            uxHighestPriorityOfWaitingTasks = ( UBaseType_t ) ( ( UBaseType_t ) configMAX_PRIORITIES - ( UBaseType_t ) listGET_ITEM_VALUE_OF_HEAD_ENTRY( &( pxQueue->xTasksWaitingToReceive ) ) );
    80003052:	703c                	ld	a5,96(s0)
    80003054:	4595                	li	a1,5
    80003056:	639c                	ld	a5,0(a5)
    80003058:	8d9d                	sub	a1,a1,a5
                            vTaskPriorityDisinheritAfterTimeout( pxQueue->u.xSemaphore.xMutexHolder, uxHighestWaitingPriority );
    8000305a:	6808                	ld	a0,16(s0)
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	d70080e7          	jalr	-656(ra) # 80001dcc <vTaskPriorityDisinheritAfterTimeout>
                        taskEXIT_CRITICAL();
    80003064:	609c                	ld	a5,0(s1)
    80003066:	17fd                	addi	a5,a5,-1
    80003068:	e09c                	sd	a5,0(s1)
    8000306a:	e399                	bnez	a5,80003070 <xQueueSemaphoreTake+0x1a6>
    8000306c:	30046073          	csrsi	mstatus,8
                return errQUEUE_EMPTY;
    80003070:	4501                	li	a0,0
    80003072:	b7ad                	j	80002fdc <xQueueSemaphoreTake+0x112>
                    vTaskInternalSetTimeOutState( &xTimeOut );
    80003074:	0808                	addi	a0,sp,16
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	aa4080e7          	jalr	-1372(ra) # 80001b1a <vTaskInternalSetTimeOutState>
                    xEntryTimeSet = pdTRUE;
    8000307e:	b555                	j	80002f22 <xQueueSemaphoreTake+0x58>
    taskEXIT_CRITICAL();
    80003080:	f71d                	bnez	a4,80002fae <xQueueSemaphoreTake+0xe4>
    80003082:	30046073          	csrsi	mstatus,8
    return xReturn;
    80003086:	b725                	j	80002fae <xQueueSemaphoreTake+0xe4>
                        taskENTER_CRITICAL();
    80003088:	30047073          	csrci	mstatus,8
    8000308c:	609c                	ld	a5,0(s1)
                            xInheritanceOccurred = xTaskPriorityInherit( pxQueue->u.xSemaphore.xMutexHolder );
    8000308e:	6808                	ld	a0,16(s0)
                        taskENTER_CRITICAL();
    80003090:	0785                	addi	a5,a5,1
    80003092:	e09c                	sd	a5,0(s1)
                            xInheritanceOccurred = xTaskPriorityInherit( pxQueue->u.xSemaphore.xMutexHolder );
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	b6c080e7          	jalr	-1172(ra) # 80001c00 <xTaskPriorityInherit>
                        taskEXIT_CRITICAL();
    8000309c:	609c                	ld	a5,0(s1)
                            xInheritanceOccurred = xTaskPriorityInherit( pxQueue->u.xSemaphore.xMutexHolder );
    8000309e:	8a2a                	mv	s4,a0
                        taskEXIT_CRITICAL();
    800030a0:	17fd                	addi	a5,a5,-1
    800030a2:	e09c                	sd	a5,0(s1)
    800030a4:	ee0793e3          	bnez	a5,80002f8a <xQueueSemaphoreTake+0xc0>
    800030a8:	30046073          	csrsi	mstatus,8
    800030ac:	bdf9                	j	80002f8a <xQueueSemaphoreTake+0xc0>
                    taskEXIT_CRITICAL();
    800030ae:	e098                	sd	a4,0(s1)
    800030b0:	f361                	bnez	a4,80003070 <xQueueSemaphoreTake+0x1a6>
                        taskEXIT_CRITICAL();
    800030b2:	30046073          	csrsi	mstatus,8
    800030b6:	bf6d                	j	80003070 <xQueueSemaphoreTake+0x1a6>
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
    800030b8:	02040513          	addi	a0,s0,32
    800030bc:	fffff097          	auipc	ra,0xfffff
    800030c0:	82c080e7          	jalr	-2004(ra) # 800018e8 <xTaskRemoveFromEventList>
    800030c4:	d509                	beqz	a0,80002fce <xQueueSemaphoreTake+0x104>
                        queueYIELD_IF_USING_PREEMPTION();
    800030c6:	00000073          	ecall
    800030ca:	b711                	j	80002fce <xQueueSemaphoreTake+0x104>
                        pxQueue->u.xSemaphore.xMutexHolder = pvTaskIncrementMutexHeldCount();
    800030cc:	fffff097          	auipc	ra,0xfffff
    800030d0:	e0a080e7          	jalr	-502(ra) # 80001ed6 <pvTaskIncrementMutexHeldCount>
    800030d4:	e808                	sd	a0,16(s0)
    800030d6:	bdd5                	j	80002fca <xQueueSemaphoreTake+0x100>

00000000800030d8 <xQueuePeek>:
{
    800030d8:	715d                	addi	sp,sp,-80
    800030da:	e486                	sd	ra,72(sp)
    800030dc:	e0a2                	sd	s0,64(sp)
    800030de:	fc26                	sd	s1,56(sp)
    800030e0:	f84a                	sd	s2,48(sp)
    800030e2:	f44e                	sd	s3,40(sp)
    800030e4:	f052                	sd	s4,32(sp)
    800030e6:	e432                	sd	a2,8(sp)
    configASSERT( ( pxQueue != NULL ) && !( ( ( pvBuffer ) == NULL ) && ( ( pxQueue )->uxItemSize != ( UBaseType_t ) 0U ) ) );
    800030e8:	c975                	beqz	a0,800031dc <xQueuePeek+0x104>
    800030ea:	842a                	mv	s0,a0
    800030ec:	89ae                	mv	s3,a1
    800030ee:	c5ed                	beqz	a1,800031d8 <xQueuePeek+0x100>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	af4080e7          	jalr	-1292(ra) # 80001be4 <xTaskGetSchedulerState>
    800030f8:	c965                	beqz	a0,800031e8 <xQueuePeek+0x110>
        taskENTER_CRITICAL();
    800030fa:	30047073          	csrci	mstatus,8
    800030fe:	00003497          	auipc	s1,0x3
    80003102:	76248493          	addi	s1,s1,1890 # 80006860 <xCriticalNesting>
    80003106:	609c                	ld	a5,0(s1)
            const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    80003108:	7838                	ld	a4,112(s0)
        taskENTER_CRITICAL();
    8000310a:	00178693          	addi	a3,a5,1
    8000310e:	e094                	sd	a3,0(s1)
            if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    80003110:	10071563          	bnez	a4,8000321a <xQueuePeek+0x142>
                if( xTicksToWait == ( TickType_t ) 0 )
    80003114:	6722                	ld	a4,8(sp)
    80003116:	c755                	beqz	a4,800031c2 <xQueuePeek+0xea>
                    vTaskInternalSetTimeOutState( &xTimeOut );
    80003118:	0808                	addi	a0,sp,16
    8000311a:	fffff097          	auipc	ra,0xfffff
    8000311e:	a00080e7          	jalr	-1536(ra) # 80001b1a <vTaskInternalSetTimeOutState>
        prvLockQueue( pxQueue );
    80003122:	597d                	li	s2,-1
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait );
    80003124:	04840a13          	addi	s4,s0,72
        taskEXIT_CRITICAL();
    80003128:	609c                	ld	a5,0(s1)
    8000312a:	17fd                	addi	a5,a5,-1
    8000312c:	e09c                	sd	a5,0(s1)
    8000312e:	e399                	bnez	a5,80003134 <xQueuePeek+0x5c>
    80003130:	30046073          	csrsi	mstatus,8
        vTaskSuspendAll();
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	3d4080e7          	jalr	980(ra) # 80001508 <vTaskSuspendAll>
        prvLockQueue( pxQueue );
    8000313c:	30047073          	csrci	mstatus,8
    80003140:	08844783          	lbu	a5,136(s0)
    80003144:	6098                	ld	a4,0(s1)
    80003146:	0187979b          	slliw	a5,a5,0x18
    8000314a:	4187d79b          	sraiw	a5,a5,0x18
    8000314e:	01279463          	bne	a5,s2,80003156 <xQueuePeek+0x7e>
    80003152:	08040423          	sb	zero,136(s0)
    80003156:	08944783          	lbu	a5,137(s0)
    8000315a:	0187979b          	slliw	a5,a5,0x18
    8000315e:	4187d79b          	sraiw	a5,a5,0x18
    80003162:	09278063          	beq	a5,s2,800031e2 <xQueuePeek+0x10a>
    80003166:	e319                	bnez	a4,8000316c <xQueuePeek+0x94>
    80003168:	30046073          	csrsi	mstatus,8
        if( xTaskCheckForTimeOut( &xTimeOut, &xTicksToWait ) == pdFALSE )
    8000316c:	002c                	addi	a1,sp,8
    8000316e:	0808                	addi	a0,sp,16
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	9c0080e7          	jalr	-1600(ra) # 80001b30 <xTaskCheckForTimeOut>
    80003178:	ed61                	bnez	a0,80003250 <xQueuePeek+0x178>
    taskENTER_CRITICAL();
    8000317a:	30047073          	csrci	mstatus,8
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    8000317e:	7838                	ld	a4,112(s0)
    taskENTER_CRITICAL();
    80003180:	609c                	ld	a5,0(s1)
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80003182:	eb25                	bnez	a4,800031f2 <xQueuePeek+0x11a>
    taskEXIT_CRITICAL();
    80003184:	e399                	bnez	a5,8000318a <xQueuePeek+0xb2>
    80003186:	30046073          	csrsi	mstatus,8
                vTaskPlaceOnEventList( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait );
    8000318a:	65a2                	ld	a1,8(sp)
    8000318c:	8552                	mv	a0,s4
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	64a080e7          	jalr	1610(ra) # 800017d8 <vTaskPlaceOnEventList>
                prvUnlockQueue( pxQueue );
    80003196:	8522                	mv	a0,s0
    80003198:	fffff097          	auipc	ra,0xfffff
    8000319c:	57a080e7          	jalr	1402(ra) # 80002712 <prvUnlockQueue>
                if( xTaskResumeAll() == pdFALSE )
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	378080e7          	jalr	888(ra) # 80001518 <xTaskResumeAll>
    800031a8:	e119                	bnez	a0,800031ae <xQueuePeek+0xd6>
                    taskYIELD_WITHIN_API();
    800031aa:	00000073          	ecall
        taskENTER_CRITICAL();
    800031ae:	30047073          	csrci	mstatus,8
    800031b2:	609c                	ld	a5,0(s1)
            const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    800031b4:	7838                	ld	a4,112(s0)
        taskENTER_CRITICAL();
    800031b6:	00178693          	addi	a3,a5,1
    800031ba:	e094                	sd	a3,0(s1)
            if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    800031bc:	ef39                	bnez	a4,8000321a <xQueuePeek+0x142>
                if( xTicksToWait == ( TickType_t ) 0 )
    800031be:	6722                	ld	a4,8(sp)
    800031c0:	f725                	bnez	a4,80003128 <xQueuePeek+0x50>
                    taskEXIT_CRITICAL();
    800031c2:	e09c                	sd	a5,0(s1)
    800031c4:	c7cd                	beqz	a5,8000326e <xQueuePeek+0x196>
                return errQUEUE_EMPTY;
    800031c6:	4501                	li	a0,0
}
    800031c8:	60a6                	ld	ra,72(sp)
    800031ca:	6406                	ld	s0,64(sp)
    800031cc:	74e2                	ld	s1,56(sp)
    800031ce:	7942                	ld	s2,48(sp)
    800031d0:	79a2                	ld	s3,40(sp)
    800031d2:	7a02                	ld	s4,32(sp)
    800031d4:	6161                	addi	sp,sp,80
    800031d6:	8082                	ret
    configASSERT( ( pxQueue != NULL ) && !( ( ( pvBuffer ) == NULL ) && ( ( pxQueue )->uxItemSize != ( UBaseType_t ) 0U ) ) );
    800031d8:	615c                	ld	a5,128(a0)
    800031da:	db99                	beqz	a5,800030f0 <xQueuePeek+0x18>
    800031dc:	30047073          	csrci	mstatus,8
    800031e0:	a001                	j	800031e0 <xQueuePeek+0x108>
        prvLockQueue( pxQueue );
    800031e2:	080404a3          	sb	zero,137(s0)
    800031e6:	b741                	j	80003166 <xQueuePeek+0x8e>
        configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    800031e8:	67a2                	ld	a5,8(sp)
    800031ea:	db81                	beqz	a5,800030fa <xQueuePeek+0x22>
    800031ec:	30047073          	csrci	mstatus,8
    800031f0:	a001                	j	800031f0 <xQueuePeek+0x118>
    taskEXIT_CRITICAL();
    800031f2:	e399                	bnez	a5,800031f8 <xQueuePeek+0x120>
    800031f4:	30046073          	csrsi	mstatus,8
                prvUnlockQueue( pxQueue );
    800031f8:	8522                	mv	a0,s0
    800031fa:	fffff097          	auipc	ra,0xfffff
    800031fe:	518080e7          	jalr	1304(ra) # 80002712 <prvUnlockQueue>
                ( void ) xTaskResumeAll();
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	316080e7          	jalr	790(ra) # 80001518 <xTaskResumeAll>
        taskENTER_CRITICAL();
    8000320a:	30047073          	csrci	mstatus,8
    8000320e:	609c                	ld	a5,0(s1)
            const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    80003210:	7838                	ld	a4,112(s0)
        taskENTER_CRITICAL();
    80003212:	00178693          	addi	a3,a5,1
    80003216:	e094                	sd	a3,0(s1)
            if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    80003218:	d35d                	beqz	a4,800031be <xQueuePeek+0xe6>
    if( pxQueue->uxItemSize != ( UBaseType_t ) 0 )
    8000321a:	6050                	ld	a2,128(s0)
                pcOriginalReadPosition = pxQueue->u.xQueue.pcReadFrom;
    8000321c:	01843903          	ld	s2,24(s0)
    if( pxQueue->uxItemSize != ( UBaseType_t ) 0 )
    80003220:	ce01                	beqz	a2,80003238 <xQueuePeek+0x160>
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    80003222:	681c                	ld	a5,16(s0)
        pxQueue->u.xQueue.pcReadFrom += pxQueue->uxItemSize;
    80003224:	00c905b3          	add	a1,s2,a2
    80003228:	ec0c                	sd	a1,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    8000322a:	06f5f363          	bgeu	a1,a5,80003290 <xQueuePeek+0x1b8>
    8000322e:	854e                	mv	a0,s3
    80003230:	00002097          	auipc	ra,0x2
    80003234:	594080e7          	jalr	1428(ra) # 800057c4 <memcpy>
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
    80003238:	643c                	ld	a5,72(s0)
                pxQueue->u.xQueue.pcReadFrom = pcOriginalReadPosition;
    8000323a:	01243c23          	sd	s2,24(s0)
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToReceive ) ) == pdFALSE )
    8000323e:	ef9d                	bnez	a5,8000327c <xQueuePeek+0x1a4>
                taskEXIT_CRITICAL();
    80003240:	609c                	ld	a5,0(s1)
                return pdPASS;
    80003242:	4505                	li	a0,1
                taskEXIT_CRITICAL();
    80003244:	17fd                	addi	a5,a5,-1
    80003246:	e09c                	sd	a5,0(s1)
    80003248:	f3c1                	bnez	a5,800031c8 <xQueuePeek+0xf0>
    8000324a:	30046073          	csrsi	mstatus,8
    8000324e:	bfad                	j	800031c8 <xQueuePeek+0xf0>
            prvUnlockQueue( pxQueue );
    80003250:	8522                	mv	a0,s0
    80003252:	fffff097          	auipc	ra,0xfffff
    80003256:	4c0080e7          	jalr	1216(ra) # 80002712 <prvUnlockQueue>
            ( void ) xTaskResumeAll();
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	2be080e7          	jalr	702(ra) # 80001518 <xTaskResumeAll>
    taskENTER_CRITICAL();
    80003262:	30047073          	csrci	mstatus,8
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80003266:	783c                	ld	a5,112(s0)
    taskENTER_CRITICAL();
    80003268:	6098                	ld	a4,0(s1)
        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    8000326a:	e789                	bnez	a5,80003274 <xQueuePeek+0x19c>
    taskEXIT_CRITICAL();
    8000326c:	ff29                	bnez	a4,800031c6 <xQueuePeek+0xee>
    8000326e:	30046073          	csrsi	mstatus,8
    80003272:	bf91                	j	800031c6 <xQueuePeek+0xee>
    80003274:	ff0d                	bnez	a4,800031ae <xQueuePeek+0xd6>
    80003276:	30046073          	csrsi	mstatus,8
    return xReturn;
    8000327a:	bf15                	j	800031ae <xQueuePeek+0xd6>
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToReceive ) ) != pdFALSE )
    8000327c:	04840513          	addi	a0,s0,72
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	668080e7          	jalr	1640(ra) # 800018e8 <xTaskRemoveFromEventList>
    80003288:	dd45                	beqz	a0,80003240 <xQueuePeek+0x168>
                        queueYIELD_IF_USING_PREEMPTION();
    8000328a:	00000073          	ecall
    8000328e:	bf4d                	j	80003240 <xQueuePeek+0x168>
            pxQueue->u.xQueue.pcReadFrom = pxQueue->pcHead;
    80003290:	600c                	ld	a1,0(s0)
    80003292:	ec0c                	sd	a1,24(s0)
    80003294:	bf69                	j	8000322e <xQueuePeek+0x156>

0000000080003296 <xQueueReceiveFromISR>:
    configASSERT( pxQueue );
    80003296:	cd1d                	beqz	a0,800032d4 <xQueueReceiveFromISR+0x3e>
{
    80003298:	7179                	addi	sp,sp,-48
    8000329a:	f022                	sd	s0,32(sp)
    8000329c:	ec26                	sd	s1,24(sp)
    8000329e:	f406                	sd	ra,40(sp)
    800032a0:	e84a                	sd	s2,16(sp)
    800032a2:	e44e                	sd	s3,8(sp)
    800032a4:	842a                	mv	s0,a0
    800032a6:	87ae                	mv	a5,a1
    800032a8:	84b2                	mv	s1,a2
    configASSERT( !( ( pvBuffer == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    800032aa:	cd89                	beqz	a1,800032c4 <xQueueReceiveFromISR+0x2e>
        const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    800032ac:	07053903          	ld	s2,112(a0)
            xReturn = pdFAIL;
    800032b0:	4501                	li	a0,0
        if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    800032b2:	02091763          	bnez	s2,800032e0 <xQueueReceiveFromISR+0x4a>
}
    800032b6:	70a2                	ld	ra,40(sp)
    800032b8:	7402                	ld	s0,32(sp)
    800032ba:	64e2                	ld	s1,24(sp)
    800032bc:	6942                	ld	s2,16(sp)
    800032be:	69a2                	ld	s3,8(sp)
    800032c0:	6145                	addi	sp,sp,48
    800032c2:	8082                	ret
    configASSERT( !( ( pvBuffer == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    800032c4:	615c                	ld	a5,128(a0)
    800032c6:	eb91                	bnez	a5,800032da <xQueueReceiveFromISR+0x44>
        const UBaseType_t uxMessagesWaiting = pxQueue->uxMessagesWaiting;
    800032c8:	07053903          	ld	s2,112(a0)
        if( uxMessagesWaiting > ( UBaseType_t ) 0 )
    800032cc:	0a091063          	bnez	s2,8000336c <xQueueReceiveFromISR+0xd6>
            xReturn = pdFAIL;
    800032d0:	4501                	li	a0,0
    800032d2:	b7d5                	j	800032b6 <xQueueReceiveFromISR+0x20>
    configASSERT( pxQueue );
    800032d4:	30047073          	csrci	mstatus,8
    800032d8:	a001                	j	800032d8 <xQueueReceiveFromISR+0x42>
    configASSERT( !( ( pvBuffer == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    800032da:	30047073          	csrci	mstatus,8
    800032de:	a001                	j	800032de <xQueueReceiveFromISR+0x48>
            const int8_t cRxLock = pxQueue->cRxLock;
    800032e0:	08844983          	lbu	s3,136(s0)
    if( pxQueue->uxItemSize != ( UBaseType_t ) 0 )
    800032e4:	6050                	ld	a2,128(s0)
            const int8_t cRxLock = pxQueue->cRxLock;
    800032e6:	0189999b          	slliw	s3,s3,0x18
    800032ea:	4189d99b          	sraiw	s3,s3,0x18
    if( pxQueue->uxItemSize != ( UBaseType_t ) 0 )
    800032ee:	ce01                	beqz	a2,80003306 <xQueueReceiveFromISR+0x70>
        pxQueue->u.xQueue.pcReadFrom += pxQueue->uxItemSize;
    800032f0:	6c0c                	ld	a1,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    800032f2:	6818                	ld	a4,16(s0)
        pxQueue->u.xQueue.pcReadFrom += pxQueue->uxItemSize;
    800032f4:	95b2                	add	a1,a1,a2
    800032f6:	ec0c                	sd	a1,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    800032f8:	04e5fb63          	bgeu	a1,a4,8000334e <xQueueReceiveFromISR+0xb8>
    800032fc:	853e                	mv	a0,a5
    800032fe:	00002097          	auipc	ra,0x2
    80003302:	4c6080e7          	jalr	1222(ra) # 800057c4 <memcpy>
            pxQueue->uxMessagesWaiting = ( UBaseType_t ) ( uxMessagesWaiting - ( UBaseType_t ) 1 );
    80003306:	197d                	addi	s2,s2,-1
    80003308:	07243823          	sd	s2,112(s0)
            if( cRxLock == queueUNLOCKED )
    8000330c:	57fd                	li	a5,-1
    8000330e:	00f99c63          	bne	s3,a5,80003326 <xQueueReceiveFromISR+0x90>
                if( listLIST_IS_EMPTY( &( pxQueue->xTasksWaitingToSend ) ) == pdFALSE )
    80003312:	701c                	ld	a5,32(s0)
    80003314:	e3a1                	bnez	a5,80003354 <xQueueReceiveFromISR+0xbe>
            xReturn = pdPASS;
    80003316:	4505                	li	a0,1
}
    80003318:	70a2                	ld	ra,40(sp)
    8000331a:	7402                	ld	s0,32(sp)
    8000331c:	64e2                	ld	s1,24(sp)
    8000331e:	6942                	ld	s2,16(sp)
    80003320:	69a2                	ld	s3,8(sp)
    80003322:	6145                	addi	sp,sp,48
    80003324:	8082                	ret
                prvIncrementQueueRxLock( pxQueue, cRxLock );
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	230080e7          	jalr	560(ra) # 80001556 <uxTaskGetNumberOfTasks>
    8000332e:	fea9f4e3          	bgeu	s3,a0,80003316 <xQueueReceiveFromISR+0x80>
    80003332:	07f00793          	li	a5,127
    80003336:	04f98263          	beq	s3,a5,8000337a <xQueueReceiveFromISR+0xe4>
    8000333a:	0019879b          	addiw	a5,s3,1
    8000333e:	0187979b          	slliw	a5,a5,0x18
    80003342:	4187d79b          	sraiw	a5,a5,0x18
    80003346:	08f40423          	sb	a5,136(s0)
            xReturn = pdPASS;
    8000334a:	4505                	li	a0,1
    8000334c:	b7ad                	j	800032b6 <xQueueReceiveFromISR+0x20>
            pxQueue->u.xQueue.pcReadFrom = pxQueue->pcHead;
    8000334e:	600c                	ld	a1,0(s0)
    80003350:	ec0c                	sd	a1,24(s0)
    80003352:	b76d                	j	800032fc <xQueueReceiveFromISR+0x66>
                    if( xTaskRemoveFromEventList( &( pxQueue->xTasksWaitingToSend ) ) != pdFALSE )
    80003354:	02040513          	addi	a0,s0,32
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	590080e7          	jalr	1424(ra) # 800018e8 <xTaskRemoveFromEventList>
    80003360:	d95d                	beqz	a0,80003316 <xQueueReceiveFromISR+0x80>
                        if( pxHigherPriorityTaskWoken != NULL )
    80003362:	d8d5                	beqz	s1,80003316 <xQueueReceiveFromISR+0x80>
                            *pxHigherPriorityTaskWoken = pdTRUE;
    80003364:	4785                	li	a5,1
    80003366:	e09c                	sd	a5,0(s1)
            xReturn = pdPASS;
    80003368:	4505                	li	a0,1
    8000336a:	b77d                	j	80003318 <xQueueReceiveFromISR+0x82>
            const int8_t cRxLock = pxQueue->cRxLock;
    8000336c:	08844983          	lbu	s3,136(s0)
    80003370:	0189999b          	slliw	s3,s3,0x18
    80003374:	4189d99b          	sraiw	s3,s3,0x18
    if( pxQueue->uxItemSize != ( UBaseType_t ) 0 )
    80003378:	b779                	j	80003306 <xQueueReceiveFromISR+0x70>
                prvIncrementQueueRxLock( pxQueue, cRxLock );
    8000337a:	30047073          	csrci	mstatus,8
    8000337e:	a001                	j	8000337e <xQueueReceiveFromISR+0xe8>

0000000080003380 <xQueuePeekFromISR>:
{
    80003380:	1101                	addi	sp,sp,-32
    80003382:	e822                	sd	s0,16(sp)
    80003384:	ec06                	sd	ra,24(sp)
    80003386:	e426                	sd	s1,8(sp)
    80003388:	842a                	mv	s0,a0
    configASSERT( ( pxQueue != NULL ) && !( ( pvBuffer == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    8000338a:	c10d                	beqz	a0,800033ac <xQueuePeekFromISR+0x2c>
    8000338c:	6050                	ld	a2,128(s0)
    8000338e:	852e                	mv	a0,a1
    80003390:	c991                	beqz	a1,800033a4 <xQueuePeekFromISR+0x24>
    configASSERT( ( pxQueue != NULL ) && ( pxQueue->uxItemSize != 0 ) ); /* Can't peek a semaphore. */
    80003392:	ca11                	beqz	a2,800033a6 <xQueuePeekFromISR+0x26>
        if( pxQueue->uxMessagesWaiting > ( UBaseType_t ) 0 )
    80003394:	783c                	ld	a5,112(s0)
    80003396:	ef91                	bnez	a5,800033b2 <xQueuePeekFromISR+0x32>
            xReturn = pdFAIL;
    80003398:	4501                	li	a0,0
}
    8000339a:	60e2                	ld	ra,24(sp)
    8000339c:	6442                	ld	s0,16(sp)
    8000339e:	64a2                	ld	s1,8(sp)
    800033a0:	6105                	addi	sp,sp,32
    800033a2:	8082                	ret
    configASSERT( ( pxQueue != NULL ) && !( ( pvBuffer == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    800033a4:	e601                	bnez	a2,800033ac <xQueuePeekFromISR+0x2c>
    configASSERT( ( pxQueue != NULL ) && ( pxQueue->uxItemSize != 0 ) ); /* Can't peek a semaphore. */
    800033a6:	30047073          	csrci	mstatus,8
    800033aa:	a001                	j	800033aa <xQueuePeekFromISR+0x2a>
    configASSERT( ( pxQueue != NULL ) && !( ( pvBuffer == NULL ) && ( pxQueue->uxItemSize != ( UBaseType_t ) 0U ) ) );
    800033ac:	30047073          	csrci	mstatus,8
    800033b0:	a001                	j	800033b0 <xQueuePeekFromISR+0x30>
            pcOriginalReadPosition = pxQueue->u.xQueue.pcReadFrom;
    800033b2:	6c04                	ld	s1,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    800033b4:	681c                	ld	a5,16(s0)
        pxQueue->u.xQueue.pcReadFrom += pxQueue->uxItemSize;
    800033b6:	00c485b3          	add	a1,s1,a2
    800033ba:	ec0c                	sd	a1,24(s0)
        if( pxQueue->u.xQueue.pcReadFrom >= pxQueue->u.xQueue.pcTail )
    800033bc:	00f5e463          	bltu	a1,a5,800033c4 <xQueuePeekFromISR+0x44>
            pxQueue->u.xQueue.pcReadFrom = pxQueue->pcHead;
    800033c0:	600c                	ld	a1,0(s0)
    800033c2:	ec0c                	sd	a1,24(s0)
    800033c4:	00002097          	auipc	ra,0x2
    800033c8:	400080e7          	jalr	1024(ra) # 800057c4 <memcpy>
            xReturn = pdPASS;
    800033cc:	4505                	li	a0,1
            pxQueue->u.xQueue.pcReadFrom = pcOriginalReadPosition;
    800033ce:	ec04                	sd	s1,24(s0)
    return xReturn;
    800033d0:	b7e9                	j	8000339a <xQueuePeekFromISR+0x1a>

00000000800033d2 <uxQueueMessagesWaiting>:
    configASSERT( xQueue );
    800033d2:	cd01                	beqz	a0,800033ea <uxQueueMessagesWaiting+0x18>
    portBASE_TYPE_ENTER_CRITICAL();
    800033d4:	30047073          	csrci	mstatus,8
        uxReturn = ( ( Queue_t * ) xQueue )->uxMessagesWaiting;
    800033d8:	7928                	ld	a0,112(a0)
    portBASE_TYPE_EXIT_CRITICAL();
    800033da:	00003797          	auipc	a5,0x3
    800033de:	4867b783          	ld	a5,1158(a5) # 80006860 <xCriticalNesting>
    800033e2:	e399                	bnez	a5,800033e8 <uxQueueMessagesWaiting+0x16>
    800033e4:	30046073          	csrsi	mstatus,8
}
    800033e8:	8082                	ret
    configASSERT( xQueue );
    800033ea:	30047073          	csrci	mstatus,8
    800033ee:	a001                	j	800033ee <uxQueueMessagesWaiting+0x1c>

00000000800033f0 <uxQueueSpacesAvailable>:
    configASSERT( pxQueue );
    800033f0:	cd11                	beqz	a0,8000340c <uxQueueSpacesAvailable+0x1c>
    portBASE_TYPE_ENTER_CRITICAL();
    800033f2:	30047073          	csrci	mstatus,8
        uxReturn = ( UBaseType_t ) ( pxQueue->uxLength - pxQueue->uxMessagesWaiting );
    800033f6:	7938                	ld	a4,112(a0)
    800033f8:	7d28                	ld	a0,120(a0)
    portBASE_TYPE_EXIT_CRITICAL();
    800033fa:	00003797          	auipc	a5,0x3
    800033fe:	4667b783          	ld	a5,1126(a5) # 80006860 <xCriticalNesting>
        uxReturn = ( UBaseType_t ) ( pxQueue->uxLength - pxQueue->uxMessagesWaiting );
    80003402:	8d19                	sub	a0,a0,a4
    portBASE_TYPE_EXIT_CRITICAL();
    80003404:	e399                	bnez	a5,8000340a <uxQueueSpacesAvailable+0x1a>
    80003406:	30046073          	csrsi	mstatus,8
}
    8000340a:	8082                	ret
    configASSERT( pxQueue );
    8000340c:	30047073          	csrci	mstatus,8
    80003410:	a001                	j	80003410 <uxQueueSpacesAvailable+0x20>

0000000080003412 <uxQueueMessagesWaitingFromISR>:
    configASSERT( pxQueue );
    80003412:	c119                	beqz	a0,80003418 <uxQueueMessagesWaitingFromISR+0x6>
    uxReturn = pxQueue->uxMessagesWaiting;
    80003414:	7928                	ld	a0,112(a0)
}
    80003416:	8082                	ret
    configASSERT( pxQueue );
    80003418:	30047073          	csrci	mstatus,8
    8000341c:	a001                	j	8000341c <uxQueueMessagesWaitingFromISR+0xa>

000000008000341e <vQueueDelete>:
    configASSERT( pxQueue );
    8000341e:	c11d                	beqz	a0,80003444 <vQueueDelete+0x26>
    80003420:	00003597          	auipc	a1,0x3
    80003424:	5e058593          	addi	a1,a1,1504 # 80006a00 <xQueueRegistry>
    80003428:	87ae                	mv	a5,a1

        configASSERT( xQueue );

        /* See if the handle of the queue being unregistered in actually in the
         * registry. */
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    8000342a:	4701                	li	a4,0
    8000342c:	4621                	li	a2,8
        {
            if( xQueueRegistry[ ux ].xHandle == xQueue )
    8000342e:	6794                	ld	a3,8(a5)
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    80003430:	07c1                	addi	a5,a5,16
            if( xQueueRegistry[ ux ].xHandle == xQueue )
    80003432:	00d50c63          	beq	a0,a3,8000344a <vQueueDelete+0x2c>
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    80003436:	0705                	addi	a4,a4,1
    80003438:	fec71be3          	bne	a4,a2,8000342e <vQueueDelete+0x10>
        vPortFree( pxQueue );
    8000343c:	00001317          	auipc	t1,0x1
    80003440:	74430067          	jr	1860(t1) # 80004b80 <vPortFree>
    configASSERT( pxQueue );
    80003444:	30047073          	csrci	mstatus,8
    80003448:	a001                	j	80003448 <vQueueDelete+0x2a>
            {
                /* Set the name to NULL to show that this slot if free again. */
                xQueueRegistry[ ux ].pcQueueName = NULL;
    8000344a:	0712                	slli	a4,a4,0x4
    8000344c:	95ba                	add	a1,a1,a4
    8000344e:	0005b023          	sd	zero,0(a1)

                /* Set the handle to NULL to ensure the same queue handle cannot
                 * appear in the registry twice if it is added, removed, then
                 * added again. */
                xQueueRegistry[ ux ].xHandle = ( QueueHandle_t ) 0;
    80003452:	0005b423          	sd	zero,8(a1)
        vPortFree( pxQueue );
    80003456:	00001317          	auipc	t1,0x1
    8000345a:	72a30067          	jr	1834(t1) # 80004b80 <vPortFree>

000000008000345e <uxQueueGetQueueItemSize>:
}
    8000345e:	6148                	ld	a0,128(a0)
    80003460:	8082                	ret

0000000080003462 <uxQueueGetQueueLength>:
}
    80003462:	7d28                	ld	a0,120(a0)
    80003464:	8082                	ret

0000000080003466 <xQueueIsQueueEmptyFromISR>:
    configASSERT( pxQueue );
    80003466:	c509                	beqz	a0,80003470 <xQueueIsQueueEmptyFromISR+0xa>
    if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0 )
    80003468:	7928                	ld	a0,112(a0)
}
    8000346a:	00153513          	seqz	a0,a0
    8000346e:	8082                	ret
    configASSERT( pxQueue );
    80003470:	30047073          	csrci	mstatus,8
    80003474:	a001                	j	80003474 <xQueueIsQueueEmptyFromISR+0xe>

0000000080003476 <xQueueIsQueueFullFromISR>:
    configASSERT( pxQueue );
    80003476:	c519                	beqz	a0,80003484 <xQueueIsQueueFullFromISR+0xe>
    if( pxQueue->uxMessagesWaiting == pxQueue->uxLength )
    80003478:	793c                	ld	a5,112(a0)
    8000347a:	7d28                	ld	a0,120(a0)
    8000347c:	8d1d                	sub	a0,a0,a5
}
    8000347e:	00153513          	seqz	a0,a0
    80003482:	8082                	ret
    configASSERT( pxQueue );
    80003484:	30047073          	csrci	mstatus,8
    80003488:	a001                	j	80003488 <xQueueIsQueueFullFromISR+0x12>

000000008000348a <vQueueAddToRegistry>:
        configASSERT( xQueue );
    8000348a:	cd21                	beqz	a0,800034e2 <vQueueAddToRegistry+0x58>
        if( pcQueueName != NULL )
    8000348c:	c985                	beqz	a1,800034bc <vQueueAddToRegistry+0x32>
        QueueRegistryItem_t * pxEntryToWrite = NULL;
    8000348e:	4801                	li	a6,0
            for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    80003490:	4781                	li	a5,0
    80003492:	00003897          	auipc	a7,0x3
    80003496:	56e88893          	addi	a7,a7,1390 # 80006a00 <xQueueRegistry>
    8000349a:	4321                	li	t1,8
                if( xQueue == xQueueRegistry[ ux ].xHandle )
    8000349c:	00479693          	slli	a3,a5,0x4
    800034a0:	00d88733          	add	a4,a7,a3
    800034a4:	6710                	ld	a2,8(a4)
    800034a6:	02a60763          	beq	a2,a0,800034d4 <vQueueAddToRegistry+0x4a>
                else if( ( pxEntryToWrite == NULL ) && ( xQueueRegistry[ ux ].pcQueueName == NULL ) )
    800034aa:	00080a63          	beqz	a6,800034be <vQueueAddToRegistry+0x34>
            for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    800034ae:	0785                	addi	a5,a5,1
    800034b0:	fe6796e3          	bne	a5,t1,8000349c <vQueueAddToRegistry+0x12>
            pxEntryToWrite->pcQueueName = pcQueueName;
    800034b4:	00b83023          	sd	a1,0(a6)
            pxEntryToWrite->xHandle = xQueue;
    800034b8:	00a83423          	sd	a0,8(a6)
    }
    800034bc:	8082                	ret
                else if( ( pxEntryToWrite == NULL ) && ( xQueueRegistry[ ux ].pcQueueName == NULL ) )
    800034be:	6314                	ld	a3,0(a4)
                if( xQueue == xQueueRegistry[ ux ].xHandle )
    800034c0:	0741                	addi	a4,a4,16
                else if( ( pxEntryToWrite == NULL ) && ( xQueueRegistry[ ux ].pcQueueName == NULL ) )
    800034c2:	c29d                	beqz	a3,800034e8 <vQueueAddToRegistry+0x5e>
            for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    800034c4:	0785                	addi	a5,a5,1
    800034c6:	fe678be3          	beq	a5,t1,800034bc <vQueueAddToRegistry+0x32>
                if( xQueue == xQueueRegistry[ ux ].xHandle )
    800034ca:	6714                	ld	a3,8(a4)
    800034cc:	fed519e3          	bne	a0,a3,800034be <vQueueAddToRegistry+0x34>
    800034d0:	00479693          	slli	a3,a5,0x4
                    pxEntryToWrite = &( xQueueRegistry[ ux ] );
    800034d4:	00d88833          	add	a6,a7,a3
            pxEntryToWrite->pcQueueName = pcQueueName;
    800034d8:	00b83023          	sd	a1,0(a6)
            pxEntryToWrite->xHandle = xQueue;
    800034dc:	00a83423          	sd	a0,8(a6)
        traceRETURN_vQueueAddToRegistry();
    800034e0:	bff1                	j	800034bc <vQueueAddToRegistry+0x32>
        configASSERT( xQueue );
    800034e2:	30047073          	csrci	mstatus,8
    800034e6:	a001                	j	800034e6 <vQueueAddToRegistry+0x5c>
                    pxEntryToWrite = &( xQueueRegistry[ ux ] );
    800034e8:	00479813          	slli	a6,a5,0x4
    800034ec:	9846                	add	a6,a6,a7
    800034ee:	b7c1                	j	800034ae <vQueueAddToRegistry+0x24>

00000000800034f0 <pcQueueGetName>:
        configASSERT( xQueue );
    800034f0:	c10d                	beqz	a0,80003512 <pcQueueGetName+0x22>
    800034f2:	00003597          	auipc	a1,0x3
    800034f6:	50e58593          	addi	a1,a1,1294 # 80006a00 <xQueueRegistry>
    800034fa:	872e                	mv	a4,a1
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    800034fc:	4781                	li	a5,0
    800034fe:	4621                	li	a2,8
            if( xQueueRegistry[ ux ].xHandle == xQueue )
    80003500:	6714                	ld	a3,8(a4)
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    80003502:	0741                	addi	a4,a4,16
            if( xQueueRegistry[ ux ].xHandle == xQueue )
    80003504:	00a68a63          	beq	a3,a0,80003518 <pcQueueGetName+0x28>
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    80003508:	0785                	addi	a5,a5,1
    8000350a:	fec79be3          	bne	a5,a2,80003500 <pcQueueGetName+0x10>
        const char * pcReturn = NULL;
    8000350e:	4501                	li	a0,0
    }
    80003510:	8082                	ret
        configASSERT( xQueue );
    80003512:	30047073          	csrci	mstatus,8
    80003516:	a001                	j	80003516 <pcQueueGetName+0x26>
                pcReturn = xQueueRegistry[ ux ].pcQueueName;
    80003518:	0792                	slli	a5,a5,0x4
    8000351a:	95be                	add	a1,a1,a5
    8000351c:	6188                	ld	a0,0(a1)
                break;
    8000351e:	8082                	ret

0000000080003520 <vQueueUnregisterQueue>:
        configASSERT( xQueue );
    80003520:	c105                	beqz	a0,80003540 <vQueueUnregisterQueue+0x20>
    80003522:	00003597          	auipc	a1,0x3
    80003526:	4de58593          	addi	a1,a1,1246 # 80006a00 <xQueueRegistry>
    8000352a:	872e                	mv	a4,a1
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    8000352c:	4781                	li	a5,0
    8000352e:	4621                	li	a2,8
            if( xQueueRegistry[ ux ].xHandle == xQueue )
    80003530:	6714                	ld	a3,8(a4)
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    80003532:	0741                	addi	a4,a4,16
            if( xQueueRegistry[ ux ].xHandle == xQueue )
    80003534:	00d50963          	beq	a0,a3,80003546 <vQueueUnregisterQueue+0x26>
        for( ux = ( UBaseType_t ) 0U; ux < ( UBaseType_t ) configQUEUE_REGISTRY_SIZE; ux++ )
    80003538:	0785                	addi	a5,a5,1
    8000353a:	fec79be3          	bne	a5,a2,80003530 <vQueueUnregisterQueue+0x10>
                mtCOVERAGE_TEST_MARKER();
            }
        }

        traceRETURN_vQueueUnregisterQueue();
    }
    8000353e:	8082                	ret
        configASSERT( xQueue );
    80003540:	30047073          	csrci	mstatus,8
    80003544:	a001                	j	80003544 <vQueueUnregisterQueue+0x24>
                xQueueRegistry[ ux ].pcQueueName = NULL;
    80003546:	0792                	slli	a5,a5,0x4
    80003548:	95be                	add	a1,a1,a5
    8000354a:	0005b023          	sd	zero,0(a1)
                xQueueRegistry[ ux ].xHandle = ( QueueHandle_t ) 0;
    8000354e:	0005b423          	sd	zero,8(a1)
                break;
    80003552:	8082                	ret

0000000080003554 <vQueueWaitForMessageRestricted>:
#if ( configUSE_TIMERS == 1 )

    void vQueueWaitForMessageRestricted( QueueHandle_t xQueue,
                                         TickType_t xTicksToWait,
                                         const BaseType_t xWaitIndefinitely )
    {
    80003554:	1141                	addi	sp,sp,-16
    80003556:	e022                	sd	s0,0(sp)
    80003558:	e406                	sd	ra,8(sp)
    8000355a:	842a                	mv	s0,a0
         *  will not actually cause the task to block, just place it on a blocked
         *  list.  It will not block until the scheduler is unlocked - at which
         *  time a yield will be performed.  If an item is added to the queue while
         *  the queue is locked, and the calling task blocks on the queue, then the
         *  calling task will be immediately unblocked when the queue is unlocked. */
        prvLockQueue( pxQueue );
    8000355c:	30047073          	csrci	mstatus,8
    80003560:	08854783          	lbu	a5,136(a0)
    80003564:	56fd                	li	a3,-1
    80003566:	00003717          	auipc	a4,0x3
    8000356a:	2fa73703          	ld	a4,762(a4) # 80006860 <xCriticalNesting>
    8000356e:	0187979b          	slliw	a5,a5,0x18
    80003572:	4187d79b          	sraiw	a5,a5,0x18
    80003576:	00d79463          	bne	a5,a3,8000357e <vQueueWaitForMessageRestricted+0x2a>
    8000357a:	08050423          	sb	zero,136(a0)
    8000357e:	08944783          	lbu	a5,137(s0)
    80003582:	56fd                	li	a3,-1
    80003584:	0187979b          	slliw	a5,a5,0x18
    80003588:	4187d79b          	sraiw	a5,a5,0x18
    8000358c:	00d78f63          	beq	a5,a3,800035aa <vQueueWaitForMessageRestricted+0x56>
    80003590:	e319                	bnez	a4,80003596 <vQueueWaitForMessageRestricted+0x42>
    80003592:	30046073          	csrsi	mstatus,8

        if( pxQueue->uxMessagesWaiting == ( UBaseType_t ) 0U )
    80003596:	783c                	ld	a5,112(s0)
    80003598:	cf81                	beqz	a5,800035b0 <vQueueWaitForMessageRestricted+0x5c>
        else
        {
            mtCOVERAGE_TEST_MARKER();
        }

        prvUnlockQueue( pxQueue );
    8000359a:	8522                	mv	a0,s0

        traceRETURN_vQueueWaitForMessageRestricted();
    }
    8000359c:	6402                	ld	s0,0(sp)
    8000359e:	60a2                	ld	ra,8(sp)
    800035a0:	0141                	addi	sp,sp,16
        prvUnlockQueue( pxQueue );
    800035a2:	fffff317          	auipc	t1,0xfffff
    800035a6:	17030067          	jr	368(t1) # 80002712 <prvUnlockQueue>
        prvLockQueue( pxQueue );
    800035aa:	080404a3          	sb	zero,137(s0)
    800035ae:	b7cd                	j	80003590 <vQueueWaitForMessageRestricted+0x3c>
            vTaskPlaceOnEventListRestricted( &( pxQueue->xTasksWaitingToReceive ), xTicksToWait, xWaitIndefinitely );
    800035b0:	04840513          	addi	a0,s0,72
    800035b4:	ffffe097          	auipc	ra,0xffffe
    800035b8:	2d4080e7          	jalr	724(ra) # 80001888 <vTaskPlaceOnEventListRestricted>
        prvUnlockQueue( pxQueue );
    800035bc:	8522                	mv	a0,s0
    }
    800035be:	6402                	ld	s0,0(sp)
    800035c0:	60a2                	ld	ra,8(sp)
    800035c2:	0141                	addi	sp,sp,16
        prvUnlockQueue( pxQueue );
    800035c4:	fffff317          	auipc	t1,0xfffff
    800035c8:	14e30067          	jr	334(t1) # 80002712 <prvUnlockQueue>

00000000800035cc <prvCheckForValidListAndQueue>:
        pxOverflowTimerList = pxTemp;
    }
/*-----------------------------------------------------------*/

    static void prvCheckForValidListAndQueue( void )
    {
    800035cc:	7179                	addi	sp,sp,-48
    800035ce:	f406                	sd	ra,40(sp)
    800035d0:	f022                	sd	s0,32(sp)
    800035d2:	ec26                	sd	s1,24(sp)
    800035d4:	e84a                	sd	s2,16(sp)
    800035d6:	e44e                	sd	s3,8(sp)
        /* Check that the list from which active timers are referenced, and the
         * queue used to communicate with the timer service, have been
         * initialised. */
        taskENTER_CRITICAL();
    800035d8:	30047073          	csrci	mstatus,8
    800035dc:	00003417          	auipc	s0,0x3
    800035e0:	28440413          	addi	s0,s0,644 # 80006860 <xCriticalNesting>
    800035e4:	601c                	ld	a5,0(s0)
        {
            if( xTimerQueue == NULL )
    800035e6:	00014497          	auipc	s1,0x14
    800035ea:	58248493          	addi	s1,s1,1410 # 80017b68 <xTimerQueue>
    800035ee:	6098                	ld	a4,0(s1)
        taskENTER_CRITICAL();
    800035f0:	00178693          	addi	a3,a5,1
    800035f4:	e014                	sd	a3,0(s0)
            if( xTimerQueue == NULL )
    800035f6:	cf01                	beqz	a4,8000360e <prvCheckForValidListAndQueue+0x42>
            else
            {
                mtCOVERAGE_TEST_MARKER();
            }
        }
        taskEXIT_CRITICAL();
    800035f8:	e01c                	sd	a5,0(s0)
    800035fa:	e399                	bnez	a5,80003600 <prvCheckForValidListAndQueue+0x34>
    800035fc:	30046073          	csrsi	mstatus,8
    }
    80003600:	70a2                	ld	ra,40(sp)
    80003602:	7402                	ld	s0,32(sp)
    80003604:	64e2                	ld	s1,24(sp)
    80003606:	6942                	ld	s2,16(sp)
    80003608:	69a2                	ld	s3,8(sp)
    8000360a:	6145                	addi	sp,sp,48
    8000360c:	8082                	ret
                vListInitialise( &xActiveTimerList1 );
    8000360e:	00003997          	auipc	s3,0x3
    80003612:	47298993          	addi	s3,s3,1138 # 80006a80 <xActiveTimerList1>
    80003616:	854e                	mv	a0,s3
    80003618:	fffff097          	auipc	ra,0xfffff
    8000361c:	fb8080e7          	jalr	-72(ra) # 800025d0 <vListInitialise>
                vListInitialise( &xActiveTimerList2 );
    80003620:	00003917          	auipc	s2,0x3
    80003624:	48890913          	addi	s2,s2,1160 # 80006aa8 <xActiveTimerList2>
    80003628:	854a                	mv	a0,s2
    8000362a:	fffff097          	auipc	ra,0xfffff
    8000362e:	fa6080e7          	jalr	-90(ra) # 800025d0 <vListInitialise>
                    xTimerQueue = xQueueCreate( ( UBaseType_t ) configTIMER_QUEUE_LENGTH, ( UBaseType_t ) sizeof( DaemonTaskMessage_t ) );
    80003632:	4601                	li	a2,0
    80003634:	45e1                	li	a1,24
    80003636:	4529                	li	a0,10
                pxCurrentTimerList = &xActiveTimerList1;
    80003638:	00014797          	auipc	a5,0x14
    8000363c:	5537b023          	sd	s3,1344(a5) # 80017b78 <pxCurrentTimerList>
                pxOverflowTimerList = &xActiveTimerList2;
    80003640:	00014797          	auipc	a5,0x14
    80003644:	5327b823          	sd	s2,1328(a5) # 80017b70 <pxOverflowTimerList>
                    xTimerQueue = xQueueCreate( ( UBaseType_t ) configTIMER_QUEUE_LENGTH, ( UBaseType_t ) sizeof( DaemonTaskMessage_t ) );
    80003648:	fffff097          	auipc	ra,0xfffff
    8000364c:	292080e7          	jalr	658(ra) # 800028da <xQueueGenericCreate>
    80003650:	e088                	sd	a0,0(s1)
                    if( xTimerQueue != NULL )
    80003652:	c909                	beqz	a0,80003664 <prvCheckForValidListAndQueue+0x98>
                        vQueueAddToRegistry( xTimerQueue, "TmrQ" );
    80003654:	00003597          	auipc	a1,0x3
    80003658:	a3458593          	addi	a1,a1,-1484 # 80006088 <__clz_tab+0x108>
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	e2e080e7          	jalr	-466(ra) # 8000348a <vQueueAddToRegistry>
        taskEXIT_CRITICAL();
    80003664:	601c                	ld	a5,0(s0)
    80003666:	17fd                	addi	a5,a5,-1
    80003668:	bf41                	j	800035f8 <prvCheckForValidListAndQueue+0x2c>

000000008000366a <prvReloadTimer>:
    {
    8000366a:	1101                	addi	sp,sp,-32
    8000366c:	e822                	sd	s0,16(sp)
    8000366e:	e04a                	sd	s2,0(sp)
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e426                	sd	s1,8(sp)
    80003674:	842a                	mv	s0,a0
    80003676:	8932                	mv	s2,a2
        while( prvInsertTimerInActiveList( pxTimer, ( xExpiredTime + pxTimer->xTimerPeriodInTicks ), xTimeNow, xExpiredTime ) != pdFALSE )
    80003678:	a031                	j	80003684 <prvReloadTimer+0x1a>
            if( ( ( TickType_t ) ( xTimeNow - xCommandTime ) ) >= pxTimer->xTimerPeriodInTicks )
    8000367a:	04f76263          	bltu	a4,a5,800036be <prvReloadTimer+0x54>
            pxTimer->pxCallbackFunction( ( TimerHandle_t ) pxTimer );
    8000367e:	603c                	ld	a5,64(s0)
    80003680:	9782                	jalr	a5
        while( prvInsertTimerInActiveList( pxTimer, ( xExpiredTime + pxTimer->xTimerPeriodInTicks ), xTimeNow, xExpiredTime ) != pdFALSE )
    80003682:	85a6                	mv	a1,s1
    80003684:	781c                	ld	a5,48(s0)
        listSET_LIST_ITEM_OWNER( &( pxTimer->xTimerListItem ), pxTimer );
    80003686:	f000                	sd	s0,32(s0)
            pxTimer->pxCallbackFunction( ( TimerHandle_t ) pxTimer );
    80003688:	8522                	mv	a0,s0
        while( prvInsertTimerInActiveList( pxTimer, ( xExpiredTime + pxTimer->xTimerPeriodInTicks ), xTimeNow, xExpiredTime ) != pdFALSE )
    8000368a:	00b784b3          	add	s1,a5,a1
        listSET_LIST_ITEM_VALUE( &( pxTimer->xTimerListItem ), xNextExpiryTime );
    8000368e:	e404                	sd	s1,8(s0)
            if( ( ( TickType_t ) ( xTimeNow - xCommandTime ) ) >= pxTimer->xTimerPeriodInTicks )
    80003690:	40b90733          	sub	a4,s2,a1
        if( xNextExpiryTime <= xTimeNow )
    80003694:	fe9973e3          	bgeu	s2,s1,8000367a <prvReloadTimer+0x10>
            if( ( xTimeNow < xCommandTime ) && ( xNextExpiryTime >= xCommandTime ) )
    80003698:	00b97463          	bgeu	s2,a1,800036a0 <prvReloadTimer+0x36>
    8000369c:	feb4f1e3          	bgeu	s1,a1,8000367e <prvReloadTimer+0x14>
                vListInsert( pxCurrentTimerList, &( pxTimer->xTimerListItem ) );
    800036a0:	00840593          	addi	a1,s0,8
    }
    800036a4:	6442                	ld	s0,16(sp)
    800036a6:	60e2                	ld	ra,24(sp)
    800036a8:	64a2                	ld	s1,8(sp)
    800036aa:	6902                	ld	s2,0(sp)
                vListInsert( pxCurrentTimerList, &( pxTimer->xTimerListItem ) );
    800036ac:	00014517          	auipc	a0,0x14
    800036b0:	4cc53503          	ld	a0,1228(a0) # 80017b78 <pxCurrentTimerList>
    }
    800036b4:	6105                	addi	sp,sp,32
                vListInsert( pxCurrentTimerList, &( pxTimer->xTimerListItem ) );
    800036b6:	fffff317          	auipc	t1,0xfffff
    800036ba:	f4c30067          	jr	-180(t1) # 80002602 <vListInsert>
                vListInsert( pxOverflowTimerList, &( pxTimer->xTimerListItem ) );
    800036be:	00840593          	addi	a1,s0,8
    }
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	64a2                	ld	s1,8(sp)
    800036c8:	6902                	ld	s2,0(sp)
                vListInsert( pxOverflowTimerList, &( pxTimer->xTimerListItem ) );
    800036ca:	00014517          	auipc	a0,0x14
    800036ce:	4a653503          	ld	a0,1190(a0) # 80017b70 <pxOverflowTimerList>
    }
    800036d2:	6105                	addi	sp,sp,32
                vListInsert( pxCurrentTimerList, &( pxTimer->xTimerListItem ) );
    800036d4:	fffff317          	auipc	t1,0xfffff
    800036d8:	f2e30067          	jr	-210(t1) # 80002602 <vListInsert>

00000000800036dc <prvProcessExpiredTimer>:
        Timer_t * const pxTimer = ( Timer_t * ) listGET_OWNER_OF_HEAD_ENTRY( pxCurrentTimerList );
    800036dc:	00014797          	auipc	a5,0x14
    800036e0:	49c7b783          	ld	a5,1180(a5) # 80017b78 <pxCurrentTimerList>
    800036e4:	6f9c                	ld	a5,24(a5)
    {
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	e822                	sd	s0,16(sp)
        Timer_t * const pxTimer = ( Timer_t * ) listGET_OWNER_OF_HEAD_ENTRY( pxCurrentTimerList );
    800036ea:	6f80                	ld	s0,24(a5)
    {
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	84aa                	mv	s1,a0
        ( void ) uxListRemove( &( pxTimer->xTimerListItem ) );
    800036f0:	00840513          	addi	a0,s0,8
    {
    800036f4:	e04a                	sd	s2,0(sp)
    800036f6:	ec06                	sd	ra,24(sp)
    800036f8:	892e                	mv	s2,a1
        ( void ) uxListRemove( &( pxTimer->xTimerListItem ) );
    800036fa:	fffff097          	auipc	ra,0xfffff
    800036fe:	f36080e7          	jalr	-202(ra) # 80002630 <uxListRemove>
        if( ( pxTimer->ucStatus & tmrSTATUS_IS_AUTORELOAD ) != 0U )
    80003702:	04844783          	lbu	a5,72(s0)
    80003706:	0047f713          	andi	a4,a5,4
    8000370a:	ef01                	bnez	a4,80003722 <prvProcessExpiredTimer+0x46>
            pxTimer->ucStatus &= ( ( uint8_t ) ~tmrSTATUS_IS_ACTIVE );
    8000370c:	9bf9                	andi	a5,a5,-2
    8000370e:	04f40423          	sb	a5,72(s0)
        pxTimer->pxCallbackFunction( ( TimerHandle_t ) pxTimer );
    80003712:	603c                	ld	a5,64(s0)
    80003714:	8522                	mv	a0,s0
    }
    80003716:	6442                	ld	s0,16(sp)
    80003718:	60e2                	ld	ra,24(sp)
    8000371a:	64a2                	ld	s1,8(sp)
    8000371c:	6902                	ld	s2,0(sp)
    8000371e:	6105                	addi	sp,sp,32
        pxTimer->pxCallbackFunction( ( TimerHandle_t ) pxTimer );
    80003720:	8782                	jr	a5
            prvReloadTimer( pxTimer, xNextExpireTime, xTimeNow );
    80003722:	864a                	mv	a2,s2
    80003724:	85a6                	mv	a1,s1
    80003726:	8522                	mv	a0,s0
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	f42080e7          	jalr	-190(ra) # 8000366a <prvReloadTimer>
    80003730:	b7cd                	j	80003712 <prvProcessExpiredTimer+0x36>

0000000080003732 <prvTimerTask>:
    {
    80003732:	7159                	addi	sp,sp,-112
    80003734:	e8ca                	sd	s2,80(sp)
    80003736:	e4ce                	sd	s3,72(sp)
    80003738:	e0d2                	sd	s4,64(sp)
    8000373a:	fc56                	sd	s5,56(sp)
    8000373c:	f85a                	sd	s6,48(sp)
    8000373e:	f45e                	sd	s7,40(sp)
    80003740:	f486                	sd	ra,104(sp)
    80003742:	f0a2                	sd	s0,96(sp)
    80003744:	eca6                	sd	s1,88(sp)
    80003746:	00014917          	auipc	s2,0x14
    8000374a:	43290913          	addi	s2,s2,1074 # 80017b78 <pxCurrentTimerList>
    8000374e:	00014a17          	auipc	s4,0x14
    80003752:	40aa0a13          	addi	s4,s4,1034 # 80017b58 <xLastTime.0>
    80003756:	00014b97          	auipc	s7,0x14
    8000375a:	41ab8b93          	addi	s7,s7,1050 # 80017b70 <pxOverflowTimerList>
    8000375e:	00014997          	auipc	s3,0x14
    80003762:	40a98993          	addi	s3,s3,1034 # 80017b68 <xTimerQueue>
    80003766:	00002a97          	auipc	s5,0x2
    8000376a:	79aa8a93          	addi	s5,s5,1946 # 80005f00 <main+0x16e>
                    switch( xMessage.xMessageID )
    8000376e:	4b25                	li	s6,9
        *pxListWasEmpty = listLIST_IS_EMPTY( pxCurrentTimerList );
    80003770:	00093783          	ld	a5,0(s2)
    80003774:	6384                	ld	s1,0(a5)
    80003776:	1a048163          	beqz	s1,80003918 <prvTimerTask+0x1e6>
            xNextExpireTime = listGET_ITEM_VALUE_OF_HEAD_ENTRY( pxCurrentTimerList );
    8000377a:	6f9c                	ld	a5,24(a5)
    8000377c:	6384                	ld	s1,0(a5)
        vTaskSuspendAll();
    8000377e:	ffffe097          	auipc	ra,0xffffe
    80003782:	d8a080e7          	jalr	-630(ra) # 80001508 <vTaskSuspendAll>
        xTimeNow = xTaskGetTickCount();
    80003786:	ffffe097          	auipc	ra,0xffffe
    8000378a:	dbc080e7          	jalr	-580(ra) # 80001542 <xTaskGetTickCount>
        if( xTimeNow < xLastTime )
    8000378e:	000a3783          	ld	a5,0(s4)
        xTimeNow = xTaskGetTickCount();
    80003792:	842a                	mv	s0,a0
        if( xTimeNow < xLastTime )
    80003794:	0ef56763          	bltu	a0,a5,80003882 <prvTimerTask+0x150>
        xLastTime = xTimeNow;
    80003798:	00aa3023          	sd	a0,0(s4)
                if( ( xListWasEmpty == pdFALSE ) && ( xNextExpireTime <= xTimeNow ) )
    8000379c:	4601                	li	a2,0
    8000379e:	1c957863          	bgeu	a0,s1,8000396e <prvTimerTask+0x23c>
                    vQueueWaitForMessageRestricted( xTimerQueue, ( xNextExpireTime - xTimeNow ), xListWasEmpty );
    800037a2:	0009b503          	ld	a0,0(s3)
    800037a6:	408485b3          	sub	a1,s1,s0
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	daa080e7          	jalr	-598(ra) # 80003554 <vQueueWaitForMessageRestricted>
                    if( xTaskResumeAll() == pdFALSE )
    800037b2:	ffffe097          	auipc	ra,0xffffe
    800037b6:	d66080e7          	jalr	-666(ra) # 80001518 <xTaskResumeAll>
    800037ba:	e119                	bnez	a0,800037c0 <prvTimerTask+0x8e>
                        taskYIELD_WITHIN_API();
    800037bc:	00000073          	ecall
        DaemonTaskMessage_t xMessage = { 0 };
    800037c0:	e402                	sd	zero,8(sp)
    800037c2:	e802                	sd	zero,16(sp)
    800037c4:	ec02                	sd	zero,24(sp)
        while( xQueueReceive( xTimerQueue, &xMessage, tmrNO_DELAY ) != pdFAIL )
    800037c6:	0009b503          	ld	a0,0(s3)
    800037ca:	4601                	li	a2,0
    800037cc:	002c                	addi	a1,sp,8
    800037ce:	fffff097          	auipc	ra,0xfffff
    800037d2:	52a080e7          	jalr	1322(ra) # 80002cf8 <xQueueReceive>
    800037d6:	dd49                	beqz	a0,80003770 <prvTimerTask+0x3e>
            if( xMessage.xMessageID >= ( BaseType_t ) 0 )
    800037d8:	67a2                	ld	a5,8(sp)
    800037da:	fe07c6e3          	bltz	a5,800037c6 <prvTimerTask+0x94>
                pxTimer = xMessage.u.xTimerParameters.pxTimer;
    800037de:	6462                	ld	s0,24(sp)
                if( pxTimer != NULL )
    800037e0:	d07d                	beqz	s0,800037c6 <prvTimerTask+0x94>
                    if( listIS_CONTAINED_WITHIN( NULL, &( pxTimer->xTimerListItem ) ) == pdFALSE )
    800037e2:	741c                	ld	a5,40(s0)
    800037e4:	c799                	beqz	a5,800037f2 <prvTimerTask+0xc0>
                        ( void ) uxListRemove( &( pxTimer->xTimerListItem ) );
    800037e6:	00840513          	addi	a0,s0,8
    800037ea:	fffff097          	auipc	ra,0xfffff
    800037ee:	e46080e7          	jalr	-442(ra) # 80002630 <uxListRemove>
        xTimeNow = xTaskGetTickCount();
    800037f2:	ffffe097          	auipc	ra,0xffffe
    800037f6:	d50080e7          	jalr	-688(ra) # 80001542 <xTaskGetTickCount>
        if( xTimeNow < xLastTime )
    800037fa:	000a3783          	ld	a5,0(s4)
        xTimeNow = xTaskGetTickCount();
    800037fe:	84aa                	mv	s1,a0
        if( xTimeNow < xLastTime )
    80003800:	02f56363          	bltu	a0,a5,80003826 <prvTimerTask+0xf4>
                    switch( xMessage.xMessageID )
    80003804:	67a2                	ld	a5,8(sp)
        xLastTime = xTimeNow;
    80003806:	009a3023          	sd	s1,0(s4)
                    switch( xMessage.xMessageID )
    8000380a:	fafb6ee3          	bltu	s6,a5,800037c6 <prvTimerTask+0x94>
    8000380e:	078a                	slli	a5,a5,0x2
    80003810:	97d6                	add	a5,a5,s5
    80003812:	439c                	lw	a5,0(a5)
    80003814:	97d6                	add	a5,a5,s5
    80003816:	8782                	jr	a5
            xNextExpireTime = listGET_ITEM_VALUE_OF_HEAD_ENTRY( pxCurrentTimerList );
    80003818:	6f9c                	ld	a5,24(a5)
            prvProcessExpiredTimer( xNextExpireTime, tmrMAX_TIME_BEFORE_OVERFLOW );
    8000381a:	55fd                	li	a1,-1
    8000381c:	6388                	ld	a0,0(a5)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	ebe080e7          	jalr	-322(ra) # 800036dc <prvProcessExpiredTimer>
        while( listLIST_IS_EMPTY( pxCurrentTimerList ) == pdFALSE )
    80003826:	00093783          	ld	a5,0(s2)
    8000382a:	6398                	ld	a4,0(a5)
    8000382c:	f775                	bnez	a4,80003818 <prvTimerTask+0xe6>
        pxCurrentTimerList = pxOverflowTimerList;
    8000382e:	000bb703          	ld	a4,0(s7)
        pxOverflowTimerList = pxTemp;
    80003832:	00fbb023          	sd	a5,0(s7)
        pxCurrentTimerList = pxOverflowTimerList;
    80003836:	00e93023          	sd	a4,0(s2)
            *pxTimerListsWereSwitched = pdTRUE;
    8000383a:	b7e9                	j	80003804 <prvTimerTask+0xd2>
                            pxTimer->ucStatus |= ( uint8_t ) tmrSTATUS_IS_ACTIVE;
    8000383c:	04844703          	lbu	a4,72(s0)
                            if( prvInsertTimerInActiveList( pxTimer, xMessage.u.xTimerParameters.xMessageValue + pxTimer->xTimerPeriodInTicks, xTimeNow, xMessage.u.xTimerParameters.xMessageValue ) != pdFALSE )
    80003840:	67c2                	ld	a5,16(sp)
    80003842:	7814                	ld	a3,48(s0)
                            pxTimer->ucStatus |= ( uint8_t ) tmrSTATUS_IS_ACTIVE;
    80003844:	00176613          	ori	a2,a4,1
    80003848:	04c40423          	sb	a2,72(s0)
                            if( prvInsertTimerInActiveList( pxTimer, xMessage.u.xTimerParameters.xMessageValue + pxTimer->xTimerPeriodInTicks, xTimeNow, xMessage.u.xTimerParameters.xMessageValue ) != pdFALSE )
    8000384c:	00d785b3          	add	a1,a5,a3
        listSET_LIST_ITEM_VALUE( &( pxTimer->xTimerListItem ), xNextExpiryTime );
    80003850:	e40c                	sd	a1,8(s0)
        listSET_LIST_ITEM_OWNER( &( pxTimer->xTimerListItem ), pxTimer );
    80003852:	f000                	sd	s0,32(s0)
        if( xNextExpiryTime <= xTimeNow )
    80003854:	08b4ee63          	bltu	s1,a1,800038f0 <prvTimerTask+0x1be>
            if( ( ( TickType_t ) ( xTimeNow - xCommandTime ) ) >= pxTimer->xTimerPeriodInTicks )
    80003858:	40f487b3          	sub	a5,s1,a5
    8000385c:	10d7e063          	bltu	a5,a3,8000395c <prvTimerTask+0x22a>
                                if( ( pxTimer->ucStatus & tmrSTATUS_IS_AUTORELOAD ) != 0U )
    80003860:	00477793          	andi	a5,a4,4
    80003864:	e7ed                	bnez	a5,8000394e <prvTimerTask+0x21c>
                                    pxTimer->ucStatus &= ( ( uint8_t ) ~tmrSTATUS_IS_ACTIVE );
    80003866:	9b79                	andi	a4,a4,-2
    80003868:	04e40423          	sb	a4,72(s0)
                                pxTimer->pxCallbackFunction( ( TimerHandle_t ) pxTimer );
    8000386c:	603c                	ld	a5,64(s0)
    8000386e:	8522                	mv	a0,s0
    80003870:	9782                	jalr	a5
    80003872:	bf91                	j	800037c6 <prvTimerTask+0x94>
            xNextExpireTime = listGET_ITEM_VALUE_OF_HEAD_ENTRY( pxCurrentTimerList );
    80003874:	6f9c                	ld	a5,24(a5)
            prvProcessExpiredTimer( xNextExpireTime, tmrMAX_TIME_BEFORE_OVERFLOW );
    80003876:	55fd                	li	a1,-1
    80003878:	6388                	ld	a0,0(a5)
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	e62080e7          	jalr	-414(ra) # 800036dc <prvProcessExpiredTimer>
        while( listLIST_IS_EMPTY( pxCurrentTimerList ) == pdFALSE )
    80003882:	00093783          	ld	a5,0(s2)
    80003886:	6398                	ld	a4,0(a5)
    80003888:	f775                	bnez	a4,80003874 <prvTimerTask+0x142>
        pxCurrentTimerList = pxOverflowTimerList;
    8000388a:	000bb703          	ld	a4,0(s7)
        xLastTime = xTimeNow;
    8000388e:	008a3023          	sd	s0,0(s4)
        pxOverflowTimerList = pxTemp;
    80003892:	00fbb023          	sd	a5,0(s7)
        pxCurrentTimerList = pxOverflowTimerList;
    80003896:	00e93023          	sd	a4,0(s2)
                ( void ) xTaskResumeAll();
    8000389a:	ffffe097          	auipc	ra,0xffffe
    8000389e:	c7e080e7          	jalr	-898(ra) # 80001518 <xTaskResumeAll>
    800038a2:	bf39                	j	800037c0 <prvTimerTask+0x8e>
                            pxTimer->ucStatus |= ( uint8_t ) tmrSTATUS_IS_ACTIVE;
    800038a4:	04844703          	lbu	a4,72(s0)
                            pxTimer->xTimerPeriodInTicks = xMessage.u.xTimerParameters.xMessageValue;
    800038a8:	67c2                	ld	a5,16(sp)
                            pxTimer->ucStatus |= ( uint8_t ) tmrSTATUS_IS_ACTIVE;
    800038aa:	00176713          	ori	a4,a4,1
    800038ae:	04e40423          	sb	a4,72(s0)
                            pxTimer->xTimerPeriodInTicks = xMessage.u.xTimerParameters.xMessageValue;
    800038b2:	f81c                	sd	a5,48(s0)
                            configASSERT( ( pxTimer->xTimerPeriodInTicks > 0 ) );
    800038b4:	cbe1                	beqz	a5,80003984 <prvTimerTask+0x252>
                            ( void ) prvInsertTimerInActiveList( pxTimer, ( xTimeNow + pxTimer->xTimerPeriodInTicks ), xTimeNow, xTimeNow );
    800038b6:	97a6                	add	a5,a5,s1
        listSET_LIST_ITEM_VALUE( &( pxTimer->xTimerListItem ), xNextExpiryTime );
    800038b8:	e41c                	sd	a5,8(s0)
        listSET_LIST_ITEM_OWNER( &( pxTimer->xTimerListItem ), pxTimer );
    800038ba:	f000                	sd	s0,32(s0)
                        ( void ) uxListRemove( &( pxTimer->xTimerListItem ) );
    800038bc:	00840593          	addi	a1,s0,8
        if( xNextExpiryTime <= xTimeNow )
    800038c0:	04f4e563          	bltu	s1,a5,8000390a <prvTimerTask+0x1d8>
                vListInsert( pxOverflowTimerList, &( pxTimer->xTimerListItem ) );
    800038c4:	000bb503          	ld	a0,0(s7)
    800038c8:	fffff097          	auipc	ra,0xfffff
    800038cc:	d3a080e7          	jalr	-710(ra) # 80002602 <vListInsert>
        return xProcessTimerNow;
    800038d0:	bddd                	j	800037c6 <prvTimerTask+0x94>
                            pxTimer->ucStatus &= ( ( uint8_t ) ~tmrSTATUS_IS_ACTIVE );
    800038d2:	04844783          	lbu	a5,72(s0)
    800038d6:	9bf9                	andi	a5,a5,-2
    800038d8:	04f40423          	sb	a5,72(s0)
                            break;
    800038dc:	b5ed                	j	800037c6 <prvTimerTask+0x94>
                                if( ( pxTimer->ucStatus & tmrSTATUS_IS_STATICALLY_ALLOCATED ) == ( uint8_t ) 0 )
    800038de:	04844783          	lbu	a5,72(s0)
    800038e2:	0027f713          	andi	a4,a5,2
    800038e6:	cf31                	beqz	a4,80003942 <prvTimerTask+0x210>
                                    pxTimer->ucStatus &= ( ( uint8_t ) ~tmrSTATUS_IS_ACTIVE );
    800038e8:	9bf9                	andi	a5,a5,-2
    800038ea:	04f40423          	sb	a5,72(s0)
    800038ee:	bde1                	j	800037c6 <prvTimerTask+0x94>
            if( ( xTimeNow < xCommandTime ) && ( xNextExpiryTime >= xCommandTime ) )
    800038f0:	00f4f463          	bgeu	s1,a5,800038f8 <prvTimerTask+0x1c6>
    800038f4:	f6f5f6e3          	bgeu	a1,a5,80003860 <prvTimerTask+0x12e>
                vListInsert( pxCurrentTimerList, &( pxTimer->xTimerListItem ) );
    800038f8:	00093503          	ld	a0,0(s2)
    800038fc:	00840593          	addi	a1,s0,8
    80003900:	fffff097          	auipc	ra,0xfffff
    80003904:	d02080e7          	jalr	-766(ra) # 80002602 <vListInsert>
        return xProcessTimerNow;
    80003908:	bd7d                	j	800037c6 <prvTimerTask+0x94>
                vListInsert( pxCurrentTimerList, &( pxTimer->xTimerListItem ) );
    8000390a:	00093503          	ld	a0,0(s2)
    8000390e:	fffff097          	auipc	ra,0xfffff
    80003912:	cf4080e7          	jalr	-780(ra) # 80002602 <vListInsert>
    80003916:	bd45                	j	800037c6 <prvTimerTask+0x94>
        vTaskSuspendAll();
    80003918:	ffffe097          	auipc	ra,0xffffe
    8000391c:	bf0080e7          	jalr	-1040(ra) # 80001508 <vTaskSuspendAll>
        xTimeNow = xTaskGetTickCount();
    80003920:	ffffe097          	auipc	ra,0xffffe
    80003924:	c22080e7          	jalr	-990(ra) # 80001542 <xTaskGetTickCount>
        if( xTimeNow < xLastTime )
    80003928:	000a3783          	ld	a5,0(s4)
        xTimeNow = xTaskGetTickCount();
    8000392c:	842a                	mv	s0,a0
        if( xTimeNow < xLastTime )
    8000392e:	f4f56ae3          	bltu	a0,a5,80003882 <prvTimerTask+0x150>
                        xListWasEmpty = listLIST_IS_EMPTY( pxOverflowTimerList );
    80003932:	000bb783          	ld	a5,0(s7)
        xLastTime = xTimeNow;
    80003936:	008a3023          	sd	s0,0(s4)
                        xListWasEmpty = listLIST_IS_EMPTY( pxOverflowTimerList );
    8000393a:	6390                	ld	a2,0(a5)
    8000393c:	00163613          	seqz	a2,a2
    80003940:	b58d                	j	800037a2 <prvTimerTask+0x70>
                                    vPortFree( pxTimer );
    80003942:	8522                	mv	a0,s0
    80003944:	00001097          	auipc	ra,0x1
    80003948:	23c080e7          	jalr	572(ra) # 80004b80 <vPortFree>
    8000394c:	bdad                	j	800037c6 <prvTimerTask+0x94>
                                    prvReloadTimer( pxTimer, xMessage.u.xTimerParameters.xMessageValue + pxTimer->xTimerPeriodInTicks, xTimeNow );
    8000394e:	8626                	mv	a2,s1
    80003950:	8522                	mv	a0,s0
    80003952:	00000097          	auipc	ra,0x0
    80003956:	d18080e7          	jalr	-744(ra) # 8000366a <prvReloadTimer>
    8000395a:	bf09                	j	8000386c <prvTimerTask+0x13a>
                vListInsert( pxOverflowTimerList, &( pxTimer->xTimerListItem ) );
    8000395c:	000bb503          	ld	a0,0(s7)
    80003960:	00840593          	addi	a1,s0,8
    80003964:	fffff097          	auipc	ra,0xfffff
    80003968:	c9e080e7          	jalr	-866(ra) # 80002602 <vListInsert>
        return xProcessTimerNow;
    8000396c:	bda9                	j	800037c6 <prvTimerTask+0x94>
                    ( void ) xTaskResumeAll();
    8000396e:	ffffe097          	auipc	ra,0xffffe
    80003972:	baa080e7          	jalr	-1110(ra) # 80001518 <xTaskResumeAll>
                    prvProcessExpiredTimer( xNextExpireTime, xTimeNow );
    80003976:	85a2                	mv	a1,s0
    80003978:	8526                	mv	a0,s1
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	d62080e7          	jalr	-670(ra) # 800036dc <prvProcessExpiredTimer>
    80003982:	bd3d                	j	800037c0 <prvTimerTask+0x8e>
                            configASSERT( ( pxTimer->xTimerPeriodInTicks > 0 ) );
    80003984:	30047073          	csrci	mstatus,8
    80003988:	a001                	j	80003988 <prvTimerTask+0x256>

000000008000398a <xTimerCreateTimerTask>:
    {
    8000398a:	1141                	addi	sp,sp,-16
    8000398c:	e406                	sd	ra,8(sp)
        prvCheckForValidListAndQueue();
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	c3e080e7          	jalr	-962(ra) # 800035cc <prvCheckForValidListAndQueue>
        if( xTimerQueue != NULL )
    80003996:	00014797          	auipc	a5,0x14
    8000399a:	1d27b783          	ld	a5,466(a5) # 80017b68 <xTimerQueue>
    8000399e:	c795                	beqz	a5,800039ca <xTimerCreateTimerTask+0x40>
                    xReturn = xTaskCreate( &prvTimerTask,
    800039a0:	00014797          	auipc	a5,0x14
    800039a4:	1c078793          	addi	a5,a5,448 # 80017b60 <xTimerTaskHandle>
    800039a8:	4709                	li	a4,2
    800039aa:	4681                	li	a3,0
    800039ac:	10000613          	li	a2,256
    800039b0:	00002597          	auipc	a1,0x2
    800039b4:	6e058593          	addi	a1,a1,1760 # 80006090 <__clz_tab+0x110>
    800039b8:	00000517          	auipc	a0,0x0
    800039bc:	d7a50513          	addi	a0,a0,-646 # 80003732 <prvTimerTask>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	19c080e7          	jalr	412(ra) # 80000b5c <xTaskCreate>
        configASSERT( xReturn );
    800039c8:	e501                	bnez	a0,800039d0 <xTimerCreateTimerTask+0x46>
    800039ca:	30047073          	csrci	mstatus,8
    800039ce:	a001                	j	800039ce <xTimerCreateTimerTask+0x44>
    }
    800039d0:	60a2                	ld	ra,8(sp)
    800039d2:	0141                	addi	sp,sp,16
    800039d4:	8082                	ret

00000000800039d6 <xTimerCreate>:
        {
    800039d6:	7139                	addi	sp,sp,-64
    800039d8:	e456                	sd	s5,8(sp)
    800039da:	8aaa                	mv	s5,a0
            pxNewTimer = ( Timer_t * ) pvPortMalloc( sizeof( Timer_t ) );
    800039dc:	05000513          	li	a0,80
        {
    800039e0:	f822                	sd	s0,48(sp)
    800039e2:	f426                	sd	s1,40(sp)
    800039e4:	f04a                	sd	s2,32(sp)
    800039e6:	ec4e                	sd	s3,24(sp)
    800039e8:	e852                	sd	s4,16(sp)
    800039ea:	fc06                	sd	ra,56(sp)
    800039ec:	84ae                	mv	s1,a1
    800039ee:	8932                	mv	s2,a2
    800039f0:	8a36                	mv	s4,a3
    800039f2:	89ba                	mv	s3,a4
            pxNewTimer = ( Timer_t * ) pvPortMalloc( sizeof( Timer_t ) );
    800039f4:	00001097          	auipc	ra,0x1
    800039f8:	fd6080e7          	jalr	-42(ra) # 800049ca <pvPortMalloc>
    800039fc:	842a                	mv	s0,a0
            if( pxNewTimer != NULL )
    800039fe:	c121                	beqz	a0,80003a3e <xTimerCreate+0x68>
                pxNewTimer->ucStatus = 0x00;
    80003a00:	04050423          	sb	zero,72(a0)
        configASSERT( ( xTimerPeriodInTicks > 0 ) );
    80003a04:	e481                	bnez	s1,80003a0c <xTimerCreate+0x36>
    80003a06:	30047073          	csrci	mstatus,8
    80003a0a:	a001                	j	80003a0a <xTimerCreate+0x34>
        prvCheckForValidListAndQueue();
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	bc0080e7          	jalr	-1088(ra) # 800035cc <prvCheckForValidListAndQueue>
        vListInitialiseItem( &( pxNewTimer->xTimerListItem ) );
    80003a14:	00840513          	addi	a0,s0,8
        pxNewTimer->pcTimerName = pcTimerName;
    80003a18:	01543023          	sd	s5,0(s0)
        pxNewTimer->xTimerPeriodInTicks = xTimerPeriodInTicks;
    80003a1c:	f804                	sd	s1,48(s0)
        pxNewTimer->pvTimerID = pvTimerID;
    80003a1e:	03443c23          	sd	s4,56(s0)
        pxNewTimer->pxCallbackFunction = pxCallbackFunction;
    80003a22:	05343023          	sd	s3,64(s0)
        vListInitialiseItem( &( pxNewTimer->xTimerListItem ) );
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	bbe080e7          	jalr	-1090(ra) # 800025e4 <vListInitialiseItem>
        if( xAutoReload != pdFALSE )
    80003a2e:	00090863          	beqz	s2,80003a3e <xTimerCreate+0x68>
            pxNewTimer->ucStatus |= ( uint8_t ) tmrSTATUS_IS_AUTORELOAD;
    80003a32:	04844783          	lbu	a5,72(s0)
    80003a36:	0047e793          	ori	a5,a5,4
    80003a3a:	04f40423          	sb	a5,72(s0)
        }
    80003a3e:	70e2                	ld	ra,56(sp)
    80003a40:	8522                	mv	a0,s0
    80003a42:	7442                	ld	s0,48(sp)
    80003a44:	74a2                	ld	s1,40(sp)
    80003a46:	7902                	ld	s2,32(sp)
    80003a48:	69e2                	ld	s3,24(sp)
    80003a4a:	6a42                	ld	s4,16(sp)
    80003a4c:	6aa2                	ld	s5,8(sp)
    80003a4e:	6121                	addi	sp,sp,64
    80003a50:	8082                	ret

0000000080003a52 <xTimerGenericCommandFromTask>:
    {
    80003a52:	7139                	addi	sp,sp,-64
    80003a54:	f822                	sd	s0,48(sp)
        if( ( xTimerQueue != NULL ) && ( xTimer != NULL ) )
    80003a56:	00014417          	auipc	s0,0x14
    80003a5a:	11240413          	addi	s0,s0,274 # 80017b68 <xTimerQueue>
    80003a5e:	601c                	ld	a5,0(s0)
    {
    80003a60:	fc06                	sd	ra,56(sp)
        if( ( xTimerQueue != NULL ) && ( xTimer != NULL ) )
    80003a62:	cb99                	beqz	a5,80003a78 <xTimerGenericCommandFromTask+0x26>
    80003a64:	c911                	beqz	a0,80003a78 <xTimerGenericCommandFromTask+0x26>
            xMessage.xMessageID = xCommandID;
    80003a66:	ec2e                	sd	a1,24(sp)
            xMessage.u.xTimerParameters.xMessageValue = xOptionalValue;
    80003a68:	f032                	sd	a2,32(sp)
            xMessage.u.xTimerParameters.pxTimer = xTimer;
    80003a6a:	f42a                	sd	a0,40(sp)
            configASSERT( xCommandID < tmrFIRST_FROM_ISR_COMMAND );
    80003a6c:	4795                	li	a5,5
    80003a6e:	00b7da63          	bge	a5,a1,80003a82 <xTimerGenericCommandFromTask+0x30>
    80003a72:	30047073          	csrci	mstatus,8
    80003a76:	a001                	j	80003a76 <xTimerGenericCommandFromTask+0x24>
        BaseType_t xReturn = pdFAIL;
    80003a78:	4501                	li	a0,0
    }
    80003a7a:	70e2                	ld	ra,56(sp)
    80003a7c:	7442                	ld	s0,48(sp)
    80003a7e:	6121                	addi	sp,sp,64
    80003a80:	8082                	ret
                if( xTaskGetSchedulerState() == taskSCHEDULER_RUNNING )
    80003a82:	e43a                	sd	a4,8(sp)
    80003a84:	ffffe097          	auipc	ra,0xffffe
    80003a88:	160080e7          	jalr	352(ra) # 80001be4 <xTaskGetSchedulerState>
    80003a8c:	4789                	li	a5,2
    80003a8e:	6722                	ld	a4,8(sp)
    80003a90:	00f50e63          	beq	a0,a5,80003aac <xTimerGenericCommandFromTask+0x5a>
                    xReturn = xQueueSendToBack( xTimerQueue, &xMessage, tmrNO_DELAY );
    80003a94:	6008                	ld	a0,0(s0)
    80003a96:	082c                	addi	a1,sp,24
    80003a98:	4681                	li	a3,0
    80003a9a:	4601                	li	a2,0
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	ed6080e7          	jalr	-298(ra) # 80002972 <xQueueGenericSend>
    }
    80003aa4:	70e2                	ld	ra,56(sp)
    80003aa6:	7442                	ld	s0,48(sp)
    80003aa8:	6121                	addi	sp,sp,64
    80003aaa:	8082                	ret
                    xReturn = xQueueSendToBack( xTimerQueue, &xMessage, xTicksToWait );
    80003aac:	6008                	ld	a0,0(s0)
    80003aae:	4681                	li	a3,0
    80003ab0:	863a                	mv	a2,a4
    80003ab2:	082c                	addi	a1,sp,24
    80003ab4:	fffff097          	auipc	ra,0xfffff
    80003ab8:	ebe080e7          	jalr	-322(ra) # 80002972 <xQueueGenericSend>
    80003abc:	bf7d                	j	80003a7a <xTimerGenericCommandFromTask+0x28>

0000000080003abe <xTimerGenericCommandFromISR>:
        if( ( xTimerQueue != NULL ) && ( xTimer != NULL ) )
    80003abe:	00014717          	auipc	a4,0x14
    80003ac2:	0aa73703          	ld	a4,170(a4) # 80017b68 <xTimerQueue>
    80003ac6:	cf11                	beqz	a4,80003ae2 <xTimerGenericCommandFromISR+0x24>
    80003ac8:	cd09                	beqz	a0,80003ae2 <xTimerGenericCommandFromISR+0x24>
    {
    80003aca:	7179                	addi	sp,sp,-48
    80003acc:	87b6                	mv	a5,a3
    80003ace:	f406                	sd	ra,40(sp)
            xMessage.xMessageID = xCommandID;
    80003ad0:	e42e                	sd	a1,8(sp)
            xMessage.u.xTimerParameters.xMessageValue = xOptionalValue;
    80003ad2:	e832                	sd	a2,16(sp)
            xMessage.u.xTimerParameters.pxTimer = xTimer;
    80003ad4:	ec2a                	sd	a0,24(sp)
            configASSERT( xCommandID >= tmrFIRST_FROM_ISR_COMMAND );
    80003ad6:	4695                	li	a3,5
    80003ad8:	00b6c763          	blt	a3,a1,80003ae6 <xTimerGenericCommandFromISR+0x28>
    80003adc:	30047073          	csrci	mstatus,8
    80003ae0:	a001                	j	80003ae0 <xTimerGenericCommandFromISR+0x22>
        BaseType_t xReturn = pdFAIL;
    80003ae2:	4501                	li	a0,0
    }
    80003ae4:	8082                	ret
                xReturn = xQueueSendToBackFromISR( xTimerQueue, &xMessage, pxHigherPriorityTaskWoken );
    80003ae6:	002c                	addi	a1,sp,8
    80003ae8:	4681                	li	a3,0
    80003aea:	863e                	mv	a2,a5
    80003aec:	853a                	mv	a0,a4
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	098080e7          	jalr	152(ra) # 80002b86 <xQueueGenericSendFromISR>
    }
    80003af6:	70a2                	ld	ra,40(sp)
    80003af8:	6145                	addi	sp,sp,48
    80003afa:	8082                	ret

0000000080003afc <xTimerGetTimerDaemonTaskHandle>:
        configASSERT( ( xTimerTaskHandle != NULL ) );
    80003afc:	00014517          	auipc	a0,0x14
    80003b00:	06453503          	ld	a0,100(a0) # 80017b60 <xTimerTaskHandle>
    80003b04:	c111                	beqz	a0,80003b08 <xTimerGetTimerDaemonTaskHandle+0xc>
    }
    80003b06:	8082                	ret
        configASSERT( ( xTimerTaskHandle != NULL ) );
    80003b08:	30047073          	csrci	mstatus,8
    80003b0c:	a001                	j	80003b0c <xTimerGetTimerDaemonTaskHandle+0x10>

0000000080003b0e <xTimerGetPeriod>:
        configASSERT( xTimer );
    80003b0e:	c119                	beqz	a0,80003b14 <xTimerGetPeriod+0x6>
    }
    80003b10:	7908                	ld	a0,48(a0)
    80003b12:	8082                	ret
        configASSERT( xTimer );
    80003b14:	30047073          	csrci	mstatus,8
    80003b18:	a001                	j	80003b18 <xTimerGetPeriod+0xa>

0000000080003b1a <vTimerSetReloadMode>:
        configASSERT( xTimer );
    80003b1a:	c50d                	beqz	a0,80003b44 <vTimerSetReloadMode+0x2a>
        taskENTER_CRITICAL();
    80003b1c:	30047073          	csrci	mstatus,8
    80003b20:	00003717          	auipc	a4,0x3
    80003b24:	d4073703          	ld	a4,-704(a4) # 80006860 <xCriticalNesting>
                pxTimer->ucStatus |= ( uint8_t ) tmrSTATUS_IS_AUTORELOAD;
    80003b28:	04854783          	lbu	a5,72(a0)
            if( xAutoReload != pdFALSE )
    80003b2c:	e989                	bnez	a1,80003b3e <vTimerSetReloadMode+0x24>
                pxTimer->ucStatus &= ( ( uint8_t ) ~tmrSTATUS_IS_AUTORELOAD );
    80003b2e:	0fb7f793          	andi	a5,a5,251
    80003b32:	04f50423          	sb	a5,72(a0)
        taskEXIT_CRITICAL();
    80003b36:	e319                	bnez	a4,80003b3c <vTimerSetReloadMode+0x22>
    80003b38:	30046073          	csrsi	mstatus,8
    }
    80003b3c:	8082                	ret
                pxTimer->ucStatus |= ( uint8_t ) tmrSTATUS_IS_AUTORELOAD;
    80003b3e:	0047e793          	ori	a5,a5,4
    80003b42:	bfc5                	j	80003b32 <vTimerSetReloadMode+0x18>
        configASSERT( xTimer );
    80003b44:	30047073          	csrci	mstatus,8
    80003b48:	a001                	j	80003b48 <vTimerSetReloadMode+0x2e>

0000000080003b4a <xTimerGetReloadMode>:
        configASSERT( xTimer );
    80003b4a:	cd19                	beqz	a0,80003b68 <xTimerGetReloadMode+0x1e>
        portBASE_TYPE_ENTER_CRITICAL();
    80003b4c:	30047073          	csrci	mstatus,8
            if( ( pxTimer->ucStatus & tmrSTATUS_IS_AUTORELOAD ) == 0U )
    80003b50:	04854503          	lbu	a0,72(a0)
        portBASE_TYPE_EXIT_CRITICAL();
    80003b54:	00003797          	auipc	a5,0x3
    80003b58:	d0c7b783          	ld	a5,-756(a5) # 80006860 <xCriticalNesting>
            if( ( pxTimer->ucStatus & tmrSTATUS_IS_AUTORELOAD ) == 0U )
    80003b5c:	8109                	srli	a0,a0,0x2
    80003b5e:	8905                	andi	a0,a0,1
        portBASE_TYPE_EXIT_CRITICAL();
    80003b60:	e399                	bnez	a5,80003b66 <xTimerGetReloadMode+0x1c>
    80003b62:	30046073          	csrsi	mstatus,8
    }
    80003b66:	8082                	ret
        configASSERT( xTimer );
    80003b68:	30047073          	csrci	mstatus,8
    80003b6c:	a001                	j	80003b6c <xTimerGetReloadMode+0x22>

0000000080003b6e <uxTimerGetReloadMode>:
    80003b6e:	c105                	beqz	a0,80003b8e <uxTimerGetReloadMode+0x20>
        portBASE_TYPE_ENTER_CRITICAL();
    80003b70:	30047073          	csrci	mstatus,8
            if( ( pxTimer->ucStatus & tmrSTATUS_IS_AUTORELOAD ) == 0U )
    80003b74:	04854503          	lbu	a0,72(a0)
        portBASE_TYPE_EXIT_CRITICAL();
    80003b78:	00003797          	auipc	a5,0x3
    80003b7c:	ce87b783          	ld	a5,-792(a5) # 80006860 <xCriticalNesting>
            if( ( pxTimer->ucStatus & tmrSTATUS_IS_AUTORELOAD ) == 0U )
    80003b80:	0025551b          	srliw	a0,a0,0x2
    80003b84:	8905                	andi	a0,a0,1
        portBASE_TYPE_EXIT_CRITICAL();
    80003b86:	e399                	bnez	a5,80003b8c <uxTimerGetReloadMode+0x1e>
    80003b88:	30046073          	csrsi	mstatus,8
    }
    80003b8c:	8082                	ret
        configASSERT( xTimer );
    80003b8e:	30047073          	csrci	mstatus,8
    80003b92:	a001                	j	80003b92 <uxTimerGetReloadMode+0x24>

0000000080003b94 <xTimerGetExpiryTime>:
        configASSERT( xTimer );
    80003b94:	c119                	beqz	a0,80003b9a <xTimerGetExpiryTime+0x6>
    }
    80003b96:	6508                	ld	a0,8(a0)
    80003b98:	8082                	ret
        configASSERT( xTimer );
    80003b9a:	30047073          	csrci	mstatus,8
    80003b9e:	a001                	j	80003b9e <xTimerGetExpiryTime+0xa>

0000000080003ba0 <pcTimerGetName>:
        configASSERT( xTimer );
    80003ba0:	c119                	beqz	a0,80003ba6 <pcTimerGetName+0x6>
    }
    80003ba2:	6108                	ld	a0,0(a0)
    80003ba4:	8082                	ret
        configASSERT( xTimer );
    80003ba6:	30047073          	csrci	mstatus,8
    80003baa:	a001                	j	80003baa <pcTimerGetName+0xa>

0000000080003bac <xTimerIsTimerActive>:
        BaseType_t xReturn;
        Timer_t * pxTimer = xTimer;

        traceENTER_xTimerIsTimerActive( xTimer );

        configASSERT( xTimer );
    80003bac:	cd11                	beqz	a0,80003bc8 <xTimerIsTimerActive+0x1c>

        /* Is the timer in the list of active timers? */
        portBASE_TYPE_ENTER_CRITICAL();
    80003bae:	30047073          	csrci	mstatus,8
        {
            if( ( pxTimer->ucStatus & tmrSTATUS_IS_ACTIVE ) == 0U )
    80003bb2:	04854503          	lbu	a0,72(a0)
            else
            {
                xReturn = pdTRUE;
            }
        }
        portBASE_TYPE_EXIT_CRITICAL();
    80003bb6:	00003797          	auipc	a5,0x3
    80003bba:	caa7b783          	ld	a5,-854(a5) # 80006860 <xCriticalNesting>
            if( ( pxTimer->ucStatus & tmrSTATUS_IS_ACTIVE ) == 0U )
    80003bbe:	8905                	andi	a0,a0,1
        portBASE_TYPE_EXIT_CRITICAL();
    80003bc0:	e399                	bnez	a5,80003bc6 <xTimerIsTimerActive+0x1a>
    80003bc2:	30046073          	csrsi	mstatus,8

        traceRETURN_xTimerIsTimerActive( xReturn );

        return xReturn;
    }
    80003bc6:	8082                	ret
        configASSERT( xTimer );
    80003bc8:	30047073          	csrci	mstatus,8
    80003bcc:	a001                	j	80003bcc <xTimerIsTimerActive+0x20>

0000000080003bce <pvTimerGetTimerID>:
        Timer_t * const pxTimer = xTimer;
        void * pvReturn;

        traceENTER_pvTimerGetTimerID( xTimer );

        configASSERT( xTimer );
    80003bce:	cd01                	beqz	a0,80003be6 <pvTimerGetTimerID+0x18>

        taskENTER_CRITICAL();
    80003bd0:	30047073          	csrci	mstatus,8
        {
            pvReturn = pxTimer->pvTimerID;
        }
        taskEXIT_CRITICAL();
    80003bd4:	00003797          	auipc	a5,0x3
    80003bd8:	c8c7b783          	ld	a5,-884(a5) # 80006860 <xCriticalNesting>
            pvReturn = pxTimer->pvTimerID;
    80003bdc:	7d08                	ld	a0,56(a0)
        taskEXIT_CRITICAL();
    80003bde:	e399                	bnez	a5,80003be4 <pvTimerGetTimerID+0x16>
    80003be0:	30046073          	csrsi	mstatus,8

        traceRETURN_pvTimerGetTimerID( pvReturn );

        return pvReturn;
    }
    80003be4:	8082                	ret
        configASSERT( xTimer );
    80003be6:	30047073          	csrci	mstatus,8
    80003bea:	a001                	j	80003bea <pvTimerGetTimerID+0x1c>

0000000080003bec <vTimerSetTimerID>:
    {
        Timer_t * const pxTimer = xTimer;

        traceENTER_vTimerSetTimerID( xTimer, pvNewID );

        configASSERT( xTimer );
    80003bec:	cd01                	beqz	a0,80003c04 <vTimerSetTimerID+0x18>

        taskENTER_CRITICAL();
    80003bee:	30047073          	csrci	mstatus,8
    80003bf2:	00003797          	auipc	a5,0x3
    80003bf6:	c6e7b783          	ld	a5,-914(a5) # 80006860 <xCriticalNesting>
        {
            pxTimer->pvTimerID = pvNewID;
    80003bfa:	fd0c                	sd	a1,56(a0)
        }
        taskEXIT_CRITICAL();
    80003bfc:	e399                	bnez	a5,80003c02 <vTimerSetTimerID+0x16>
    80003bfe:	30046073          	csrsi	mstatus,8

        traceRETURN_vTimerSetTimerID();
    }
    80003c02:	8082                	ret
        configASSERT( xTimer );
    80003c04:	30047073          	csrci	mstatus,8
    80003c08:	a001                	j	80003c08 <vTimerSetTimerID+0x1c>

0000000080003c0a <vTimerResetState>:
 * This function must be called by the application before restarting the
 * scheduler.
 */
    void vTimerResetState( void )
    {
        xTimerQueue = NULL;
    80003c0a:	00014797          	auipc	a5,0x14
    80003c0e:	f407bf23          	sd	zero,-162(a5) # 80017b68 <xTimerQueue>
        xTimerTaskHandle = NULL;
    80003c12:	00014797          	auipc	a5,0x14
    80003c16:	f407b723          	sd	zero,-178(a5) # 80017b60 <xTimerTaskHandle>
    }
    80003c1a:	8082                	ret

0000000080003c1c <xEventGroupSetBits.part.0>:

        return uxReturn;
    }
/*-----------------------------------------------------------*/

    EventBits_t xEventGroupSetBits( EventGroupHandle_t xEventGroup,
    80003c1c:	715d                	addi	sp,sp,-80
    80003c1e:	e0a2                	sd	s0,64(sp)
    80003c20:	fc26                	sd	s1,56(sp)
    80003c22:	f84a                	sd	s2,48(sp)
    80003c24:	f44e                	sd	s3,40(sp)
    80003c26:	892a                	mv	s2,a0
    80003c28:	84ae                	mv	s1,a1
    80003c2a:	e486                	sd	ra,72(sp)
    80003c2c:	f052                	sd	s4,32(sp)
    80003c2e:	ec56                	sd	s5,24(sp)
    80003c30:	e85a                	sd	s6,16(sp)
    80003c32:	e45e                	sd	s7,8(sp)
    80003c34:	e062                	sd	s8,0(sp)
        configASSERT( xEventGroup );
        configASSERT( ( uxBitsToSet & eventEVENT_BITS_CONTROL_BYTES ) == 0 );

        pxList = &( pxEventBits->xTasksWaitingForBits );
        pxListEnd = listGET_END_MARKER( pxList );
        vTaskSuspendAll();
    80003c36:	ffffe097          	auipc	ra,0xffffe
    80003c3a:	8d2080e7          	jalr	-1838(ra) # 80001508 <vTaskSuspendAll>
            traceEVENT_GROUP_SET_BITS( xEventGroup, uxBitsToSet );

            pxListItem = listGET_HEAD_ENTRY( pxList );

            /* Set the bits. */
            pxEventBits->uxEventBits |= uxBitsToSet;
    80003c3e:	00093783          	ld	a5,0(s2)
            pxListItem = listGET_HEAD_ENTRY( pxList );
    80003c42:	02093403          	ld	s0,32(s2)
        pxListEnd = listGET_END_MARKER( pxList );
    80003c46:	01890993          	addi	s3,s2,24
            pxEventBits->uxEventBits |= uxBitsToSet;
    80003c4a:	8cdd                	or	s1,s1,a5
    80003c4c:	00993023          	sd	s1,0(s2)

            /* See if the new bit value should unblock any tasks. */
            while( pxListItem != pxListEnd )
    80003c50:	04898963          	beq	s3,s0,80003ca2 <xEventGroupSetBits.part.0+0x86>
                uxBitsWaitedFor = listGET_LIST_ITEM_VALUE( pxListItem );
                xMatchFound = pdFALSE;

                /* Split the bits waited for from the control bits. */
                uxControlBits = uxBitsWaitedFor & eventEVENT_BITS_CONTROL_BYTES;
                uxBitsWaitedFor &= ~eventEVENT_BITS_CONTROL_BYTES;
    80003c54:	01000a37          	lui	s4,0x1000
        EventBits_t uxBitsToClear = 0, uxBitsWaitedFor, uxControlBits, uxReturnBits;
    80003c58:	4a81                	li	s5,0
                uxBitsWaitedFor &= ~eventEVENT_BITS_CONTROL_BYTES;
    80003c5a:	fffa0c13          	addi	s8,s4,-1 # ffffff <_start-0x7f000001>

                if( ( uxControlBits & eventWAIT_FOR_ALL_BITS ) == ( EventBits_t ) 0 )
    80003c5e:	04000bb7          	lui	s7,0x4000
                    /* Store the actual event flag value in the task's event list
                     * item before removing the task from the event list.  The
                     * eventUNBLOCKED_DUE_TO_BIT_SET bit is set so the task knows
                     * that is was unblocked due to its required bits matching, rather
                     * than because it timed out. */
                    vTaskRemoveFromUnorderedEventList( pxListItem, pxEventBits->uxEventBits | eventUNBLOCKED_DUE_TO_BIT_SET );
    80003c62:	02000b37          	lui	s6,0x2000
                uxBitsWaitedFor = listGET_LIST_ITEM_VALUE( pxListItem );
    80003c66:	601c                	ld	a5,0(s0)
    80003c68:	8522                	mv	a0,s0
                    vTaskRemoveFromUnorderedEventList( pxListItem, pxEventBits->uxEventBits | eventUNBLOCKED_DUE_TO_BIT_SET );
    80003c6a:	0164e5b3          	or	a1,s1,s6
                uxBitsWaitedFor &= ~eventEVENT_BITS_CONTROL_BYTES;
    80003c6e:	0187f733          	and	a4,a5,s8
                if( ( uxControlBits & eventWAIT_FOR_ALL_BITS ) == ( EventBits_t ) 0 )
    80003c72:	0177f633          	and	a2,a5,s7
                pxNext = listGET_NEXT( pxListItem );
    80003c76:	6400                	ld	s0,8(s0)
                    if( ( uxControlBits & eventCLEAR_EVENTS_ON_EXIT_BIT ) != ( EventBits_t ) 0 )
    80003c78:	0147f7b3          	and	a5,a5,s4
                    if( ( uxBitsWaitedFor & pxEventBits->uxEventBits ) != ( EventBits_t ) 0 )
    80003c7c:	009776b3          	and	a3,a4,s1
                if( ( uxControlBits & eventWAIT_FOR_ALL_BITS ) == ( EventBits_t ) 0 )
    80003c80:	e621                	bnez	a2,80003cc8 <xEventGroupSetBits.part.0+0xac>
                    if( ( uxBitsWaitedFor & pxEventBits->uxEventBits ) != ( EventBits_t ) 0 )
    80003c82:	ca91                	beqz	a3,80003c96 <xEventGroupSetBits.part.0+0x7a>
                    if( ( uxControlBits & eventCLEAR_EVENTS_ON_EXIT_BIT ) != ( EventBits_t ) 0 )
    80003c84:	c399                	beqz	a5,80003c8a <xEventGroupSetBits.part.0+0x6e>
                        uxBitsToClear |= uxBitsWaitedFor;
    80003c86:	00eaeab3          	or	s5,s5,a4
                    vTaskRemoveFromUnorderedEventList( pxListItem, pxEventBits->uxEventBits | eventUNBLOCKED_DUE_TO_BIT_SET );
    80003c8a:	ffffe097          	auipc	ra,0xffffe
    80003c8e:	d82080e7          	jalr	-638(ra) # 80001a0c <vTaskRemoveFromUnorderedEventList>
                pxListItem = pxNext;
            }

            /* Clear any bits that matched when the eventCLEAR_EVENTS_ON_EXIT_BIT
             * bit was set in the control word. */
            pxEventBits->uxEventBits &= ~uxBitsToClear;
    80003c92:	00093483          	ld	s1,0(s2)
            while( pxListItem != pxListEnd )
    80003c96:	fc8998e3          	bne	s3,s0,80003c66 <xEventGroupSetBits.part.0+0x4a>
            pxEventBits->uxEventBits &= ~uxBitsToClear;
    80003c9a:	fffaca93          	not	s5,s5
    80003c9e:	0154f4b3          	and	s1,s1,s5
    80003ca2:	00993023          	sd	s1,0(s2)

            /* Snapshot resulting bits. */
            uxReturnBits = pxEventBits->uxEventBits;
        }
        ( void ) xTaskResumeAll();
    80003ca6:	ffffe097          	auipc	ra,0xffffe
    80003caa:	872080e7          	jalr	-1934(ra) # 80001518 <xTaskResumeAll>

        traceRETURN_xEventGroupSetBits( uxReturnBits );

        return uxReturnBits;
    }
    80003cae:	60a6                	ld	ra,72(sp)
    80003cb0:	6406                	ld	s0,64(sp)
    80003cb2:	7942                	ld	s2,48(sp)
    80003cb4:	79a2                	ld	s3,40(sp)
    80003cb6:	7a02                	ld	s4,32(sp)
    80003cb8:	6ae2                	ld	s5,24(sp)
    80003cba:	6b42                	ld	s6,16(sp)
    80003cbc:	6ba2                	ld	s7,8(sp)
    80003cbe:	6c02                	ld	s8,0(sp)
    80003cc0:	8526                	mv	a0,s1
    80003cc2:	74e2                	ld	s1,56(sp)
    80003cc4:	6161                	addi	sp,sp,80
    80003cc6:	8082                	ret
                else if( ( uxBitsWaitedFor & pxEventBits->uxEventBits ) == uxBitsWaitedFor )
    80003cc8:	fad70ee3          	beq	a4,a3,80003c84 <xEventGroupSetBits.part.0+0x68>
            while( pxListItem != pxListEnd )
    80003ccc:	f8899de3          	bne	s3,s0,80003c66 <xEventGroupSetBits.part.0+0x4a>
    80003cd0:	b7e9                	j	80003c9a <xEventGroupSetBits.part.0+0x7e>

0000000080003cd2 <xEventGroupCreate>:
        {
    80003cd2:	1141                	addi	sp,sp,-16
            pxEventBits = ( EventGroup_t * ) pvPortMalloc( sizeof( EventGroup_t ) );
    80003cd4:	03000513          	li	a0,48
        {
    80003cd8:	e022                	sd	s0,0(sp)
    80003cda:	e406                	sd	ra,8(sp)
            pxEventBits = ( EventGroup_t * ) pvPortMalloc( sizeof( EventGroup_t ) );
    80003cdc:	00001097          	auipc	ra,0x1
    80003ce0:	cee080e7          	jalr	-786(ra) # 800049ca <pvPortMalloc>
    80003ce4:	842a                	mv	s0,a0
            if( pxEventBits != NULL )
    80003ce6:	c901                	beqz	a0,80003cf6 <xEventGroupCreate+0x24>
                pxEventBits->uxEventBits = 0;
    80003ce8:	00053023          	sd	zero,0(a0)
                vListInitialise( &( pxEventBits->xTasksWaitingForBits ) );
    80003cec:	0521                	addi	a0,a0,8
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	8e2080e7          	jalr	-1822(ra) # 800025d0 <vListInitialise>
        }
    80003cf6:	60a2                	ld	ra,8(sp)
    80003cf8:	8522                	mv	a0,s0
    80003cfa:	6402                	ld	s0,0(sp)
    80003cfc:	0141                	addi	sp,sp,16
    80003cfe:	8082                	ret

0000000080003d00 <xEventGroupSync>:
        configASSERT( ( uxBitsToWaitFor & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003d00:	0ff00793          	li	a5,255
    80003d04:	07e2                	slli	a5,a5,0x18
    80003d06:	8ff1                	and	a5,a5,a2
    80003d08:	c781                	beqz	a5,80003d10 <xEventGroupSync+0x10>
    80003d0a:	30047073          	csrci	mstatus,8
    80003d0e:	a001                	j	80003d0e <xEventGroupSync+0xe>
    {
    80003d10:	7139                	addi	sp,sp,-64
    80003d12:	f822                	sd	s0,48(sp)
    80003d14:	fc06                	sd	ra,56(sp)
    80003d16:	f426                	sd	s1,40(sp)
    80003d18:	f04a                	sd	s2,32(sp)
    80003d1a:	ec4e                	sd	s3,24(sp)
    80003d1c:	8432                	mv	s0,a2
        configASSERT( uxBitsToWaitFor != 0 );
    80003d1e:	e601                	bnez	a2,80003d26 <xEventGroupSync+0x26>
    80003d20:	30047073          	csrci	mstatus,8
    80003d24:	a001                	j	80003d24 <xEventGroupSync+0x24>
            configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80003d26:	e42e                	sd	a1,8(sp)
    80003d28:	84aa                	mv	s1,a0
    80003d2a:	89b6                	mv	s3,a3
    80003d2c:	ffffe097          	auipc	ra,0xffffe
    80003d30:	eb8080e7          	jalr	-328(ra) # 80001be4 <xTaskGetSchedulerState>
    80003d34:	65a2                	ld	a1,8(sp)
    80003d36:	e511                	bnez	a0,80003d42 <xEventGroupSync+0x42>
    80003d38:	00098563          	beqz	s3,80003d42 <xEventGroupSync+0x42>
    80003d3c:	30047073          	csrci	mstatus,8
    80003d40:	a001                	j	80003d40 <xEventGroupSync+0x40>
    80003d42:	e42e                	sd	a1,8(sp)
        vTaskSuspendAll();
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	7c4080e7          	jalr	1988(ra) # 80001508 <vTaskSuspendAll>
        configASSERT( ( uxBitsToSet & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003d4c:	65a2                	ld	a1,8(sp)
    80003d4e:	0ff00793          	li	a5,255
    80003d52:	07e2                	slli	a5,a5,0x18
    80003d54:	8fed                	and	a5,a5,a1
            uxOriginalBitValue = pxEventBits->uxEventBits;
    80003d56:	0004b903          	ld	s2,0(s1)
        configASSERT( ( uxBitsToSet & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003d5a:	c781                	beqz	a5,80003d62 <xEventGroupSync+0x62>
    80003d5c:	30047073          	csrci	mstatus,8
    80003d60:	a001                	j	80003d60 <xEventGroupSync+0x60>
    80003d62:	8526                	mv	a0,s1
            if( ( ( uxOriginalBitValue | uxBitsToSet ) & uxBitsToWaitFor ) == uxBitsToWaitFor )
    80003d64:	0125e933          	or	s2,a1,s2
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	eb4080e7          	jalr	-332(ra) # 80003c1c <xEventGroupSetBits.part.0>
    80003d70:	008977b3          	and	a5,s2,s0
    80003d74:	08878463          	beq	a5,s0,80003dfc <xEventGroupSync+0xfc>
                if( xTicksToWait != ( TickType_t ) 0 )
    80003d78:	02099063          	bnez	s3,80003d98 <xEventGroupSync+0x98>
                    uxReturn = pxEventBits->uxEventBits;
    80003d7c:	0004b903          	ld	s2,0(s1)
        xAlreadyYielded = xTaskResumeAll();
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	798080e7          	jalr	1944(ra) # 80001518 <xTaskResumeAll>
    }
    80003d88:	70e2                	ld	ra,56(sp)
    80003d8a:	7442                	ld	s0,48(sp)
    80003d8c:	74a2                	ld	s1,40(sp)
    80003d8e:	69e2                	ld	s3,24(sp)
    80003d90:	854a                	mv	a0,s2
    80003d92:	7902                	ld	s2,32(sp)
    80003d94:	6121                	addi	sp,sp,64
    80003d96:	8082                	ret
                    vTaskPlaceOnUnorderedEventList( &( pxEventBits->xTasksWaitingForBits ), ( uxBitsToWaitFor | eventCLEAR_EVENTS_ON_EXIT_BIT | eventWAIT_FOR_ALL_BITS ), xTicksToWait );
    80003d98:	050005b7          	lui	a1,0x5000
    80003d9c:	864e                	mv	a2,s3
    80003d9e:	8dc1                	or	a1,a1,s0
    80003da0:	00848513          	addi	a0,s1,8
    80003da4:	ffffe097          	auipc	ra,0xffffe
    80003da8:	a6a080e7          	jalr	-1430(ra) # 8000180e <vTaskPlaceOnUnorderedEventList>
        xAlreadyYielded = xTaskResumeAll();
    80003dac:	ffffd097          	auipc	ra,0xffffd
    80003db0:	76c080e7          	jalr	1900(ra) # 80001518 <xTaskResumeAll>
            if( xAlreadyYielded == pdFALSE )
    80003db4:	e119                	bnez	a0,80003dba <xEventGroupSync+0xba>
                taskYIELD_WITHIN_API();
    80003db6:	00000073          	ecall
            uxReturn = uxTaskResetEventItemValue();
    80003dba:	ffffe097          	auipc	ra,0xffffe
    80003dbe:	102080e7          	jalr	258(ra) # 80001ebc <uxTaskResetEventItemValue>
            if( ( uxReturn & eventUNBLOCKED_DUE_TO_BIT_SET ) == ( EventBits_t ) 0 )
    80003dc2:	02000737          	lui	a4,0x2000
    80003dc6:	8f69                	and	a4,a4,a0
            uxReturn = uxTaskResetEventItemValue();
    80003dc8:	87aa                	mv	a5,a0
            if( ( uxReturn & eventUNBLOCKED_DUE_TO_BIT_SET ) == ( EventBits_t ) 0 )
    80003dca:	e70d                	bnez	a4,80003df4 <xEventGroupSync+0xf4>
                taskENTER_CRITICAL();
    80003dcc:	30047073          	csrci	mstatus,8
                    uxReturn = pxEventBits->uxEventBits;
    80003dd0:	609c                	ld	a5,0(s1)
                taskENTER_CRITICAL();
    80003dd2:	00003617          	auipc	a2,0x3
    80003dd6:	a8e60613          	addi	a2,a2,-1394 # 80006860 <xCriticalNesting>
    80003dda:	6214                	ld	a3,0(a2)
                    if( ( uxReturn & uxBitsToWaitFor ) == uxBitsToWaitFor )
    80003ddc:	00f47733          	and	a4,s0,a5
    80003de0:	00871663          	bne	a4,s0,80003dec <xEventGroupSync+0xec>
                        pxEventBits->uxEventBits &= ~uxBitsToWaitFor;
    80003de4:	fff44713          	not	a4,s0
    80003de8:	8f7d                	and	a4,a4,a5
    80003dea:	e098                	sd	a4,0(s1)
                taskEXIT_CRITICAL();
    80003dec:	e214                	sd	a3,0(a2)
    80003dee:	e299                	bnez	a3,80003df4 <xEventGroupSync+0xf4>
    80003df0:	30046073          	csrsi	mstatus,8
            uxReturn &= ~eventEVENT_BITS_CONTROL_BYTES;
    80003df4:	17a2                	slli	a5,a5,0x28
    80003df6:	0287d913          	srli	s2,a5,0x28
        return uxReturn;
    80003dfa:	b779                	j	80003d88 <xEventGroupSync+0x88>
                pxEventBits->uxEventBits &= ~uxBitsToWaitFor;
    80003dfc:	609c                	ld	a5,0(s1)
    80003dfe:	fff44413          	not	s0,s0
    80003e02:	8fe1                	and	a5,a5,s0
    80003e04:	e09c                	sd	a5,0(s1)
        xAlreadyYielded = xTaskResumeAll();
    80003e06:	ffffd097          	auipc	ra,0xffffd
    80003e0a:	712080e7          	jalr	1810(ra) # 80001518 <xTaskResumeAll>
        if( xTicksToWait != ( TickType_t ) 0 )
    80003e0e:	bfad                	j	80003d88 <xEventGroupSync+0x88>

0000000080003e10 <xEventGroupWaitBits>:
        configASSERT( xEventGroup );
    80003e10:	c505                	beqz	a0,80003e38 <xEventGroupWaitBits+0x28>
        configASSERT( ( uxBitsToWaitFor & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003e12:	0ff00793          	li	a5,255
    {
    80003e16:	7139                	addi	sp,sp,-64
        configASSERT( ( uxBitsToWaitFor & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003e18:	07e2                	slli	a5,a5,0x18
    {
    80003e1a:	f822                	sd	s0,48(sp)
    80003e1c:	fc06                	sd	ra,56(sp)
    80003e1e:	f426                	sd	s1,40(sp)
    80003e20:	f04a                	sd	s2,32(sp)
    80003e22:	ec4e                	sd	s3,24(sp)
        configASSERT( ( uxBitsToWaitFor & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003e24:	8fed                	and	a5,a5,a1
    80003e26:	842e                	mv	s0,a1
    80003e28:	e789                	bnez	a5,80003e32 <xEventGroupWaitBits+0x22>
        configASSERT( uxBitsToWaitFor != 0 );
    80003e2a:	e991                	bnez	a1,80003e3e <xEventGroupWaitBits+0x2e>
    80003e2c:	30047073          	csrci	mstatus,8
    80003e30:	a001                	j	80003e30 <xEventGroupWaitBits+0x20>
        configASSERT( ( uxBitsToWaitFor & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003e32:	30047073          	csrci	mstatus,8
    80003e36:	a001                	j	80003e36 <xEventGroupWaitBits+0x26>
        configASSERT( xEventGroup );
    80003e38:	30047073          	csrci	mstatus,8
    80003e3c:	a001                	j	80003e3c <xEventGroupWaitBits+0x2c>
            configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80003e3e:	e43a                	sd	a4,8(sp)
    80003e40:	e032                	sd	a2,0(sp)
    80003e42:	892a                	mv	s2,a0
    80003e44:	89b6                	mv	s3,a3
    80003e46:	ffffe097          	auipc	ra,0xffffe
    80003e4a:	d9e080e7          	jalr	-610(ra) # 80001be4 <xTaskGetSchedulerState>
    80003e4e:	6602                	ld	a2,0(sp)
    80003e50:	6722                	ld	a4,8(sp)
    80003e52:	e111                	bnez	a0,80003e56 <xEventGroupWaitBits+0x46>
    80003e54:	e355                	bnez	a4,80003ef8 <xEventGroupWaitBits+0xe8>
    80003e56:	e43a                	sd	a4,8(sp)
    80003e58:	e032                	sd	a2,0(sp)
        vTaskSuspendAll();
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	6ae080e7          	jalr	1710(ra) # 80001508 <vTaskSuspendAll>
            const EventBits_t uxCurrentEventBits = pxEventBits->uxEventBits;
    80003e62:	00093483          	ld	s1,0(s2)
                                            const EventBits_t uxBitsToWaitFor,
                                            const BaseType_t xWaitForAllBits )
    {
        BaseType_t xWaitConditionMet = pdFALSE;

        if( xWaitForAllBits == pdFALSE )
    80003e66:	6602                	ld	a2,0(sp)
    80003e68:	6722                	ld	a4,8(sp)
        {
            /* Task only has to wait for one bit within uxBitsToWaitFor to be
             * set.  Is one already set? */
            if( ( uxCurrentEventBits & uxBitsToWaitFor ) != ( EventBits_t ) 0 )
    80003e6a:	009477b3          	and	a5,s0,s1
        if( xWaitForAllBits == pdFALSE )
    80003e6e:	06099663          	bnez	s3,80003eda <xEventGroupWaitBits+0xca>
            if( ( uxCurrentEventBits & uxBitsToWaitFor ) != ( EventBits_t ) 0 )
    80003e72:	efd9                	bnez	a5,80003f10 <xEventGroupWaitBits+0x100>
            else if( xTicksToWait == ( TickType_t ) 0 )
    80003e74:	c735                	beqz	a4,80003ee0 <xEventGroupWaitBits+0xd0>
                if( xClearOnExit != pdFALSE )
    80003e76:	00c034b3          	snez	s1,a2
    80003e7a:	01849593          	slli	a1,s1,0x18
                vTaskPlaceOnUnorderedEventList( &( pxEventBits->xTasksWaitingForBits ), ( uxBitsToWaitFor | uxControlBits ), xTicksToWait );
    80003e7e:	863a                	mv	a2,a4
    80003e80:	8dc1                	or	a1,a1,s0
    80003e82:	00890513          	addi	a0,s2,8
    80003e86:	ffffe097          	auipc	ra,0xffffe
    80003e8a:	988080e7          	jalr	-1656(ra) # 8000180e <vTaskPlaceOnUnorderedEventList>
        xAlreadyYielded = xTaskResumeAll();
    80003e8e:	ffffd097          	auipc	ra,0xffffd
    80003e92:	68a080e7          	jalr	1674(ra) # 80001518 <xTaskResumeAll>
            if( xAlreadyYielded == pdFALSE )
    80003e96:	e119                	bnez	a0,80003e9c <xEventGroupWaitBits+0x8c>
                taskYIELD_WITHIN_API();
    80003e98:	00000073          	ecall
            uxReturn = uxTaskResetEventItemValue();
    80003e9c:	ffffe097          	auipc	ra,0xffffe
    80003ea0:	020080e7          	jalr	32(ra) # 80001ebc <uxTaskResetEventItemValue>
            if( ( uxReturn & eventUNBLOCKED_DUE_TO_BIT_SET ) == ( EventBits_t ) 0 )
    80003ea4:	02000737          	lui	a4,0x2000
    80003ea8:	8f69                	and	a4,a4,a0
            uxReturn = uxTaskResetEventItemValue();
    80003eaa:	87aa                	mv	a5,a0
            if( ( uxReturn & eventUNBLOCKED_DUE_TO_BIT_SET ) == ( EventBits_t ) 0 )
    80003eac:	e31d                	bnez	a4,80003ed2 <xEventGroupWaitBits+0xc2>
                taskENTER_CRITICAL();
    80003eae:	30047073          	csrci	mstatus,8
                    uxReturn = pxEventBits->uxEventBits;
    80003eb2:	00093783          	ld	a5,0(s2)
                taskENTER_CRITICAL();
    80003eb6:	00003597          	auipc	a1,0x3
    80003eba:	9aa58593          	addi	a1,a1,-1622 # 80006860 <xCriticalNesting>
    80003ebe:	6190                	ld	a2,0(a1)
            if( ( uxCurrentEventBits & uxBitsToWaitFor ) != ( EventBits_t ) 0 )
    80003ec0:	00f47733          	and	a4,s0,a5
        if( xWaitForAllBits == pdFALSE )
    80003ec4:	02099d63          	bnez	s3,80003efe <xEventGroupWaitBits+0xee>
            if( ( uxCurrentEventBits & uxBitsToWaitFor ) != ( EventBits_t ) 0 )
    80003ec8:	ef0d                	bnez	a4,80003f02 <xEventGroupWaitBits+0xf2>
                taskEXIT_CRITICAL();
    80003eca:	e190                	sd	a2,0(a1)
    80003ecc:	e219                	bnez	a2,80003ed2 <xEventGroupWaitBits+0xc2>
    80003ece:	30046073          	csrsi	mstatus,8
            uxReturn &= ~eventEVENT_BITS_CONTROL_BYTES;
    80003ed2:	17a2                	slli	a5,a5,0x28
    80003ed4:	0287d493          	srli	s1,a5,0x28
        return uxReturn;
    80003ed8:	a801                	j	80003ee8 <xEventGroupWaitBits+0xd8>
        }
        else
        {
            /* Task has to wait for all the bits in uxBitsToWaitFor to be set.
             * Are they set already? */
            if( ( uxCurrentEventBits & uxBitsToWaitFor ) == uxBitsToWaitFor )
    80003eda:	02f40b63          	beq	s0,a5,80003f10 <xEventGroupWaitBits+0x100>
            else if( xTicksToWait == ( TickType_t ) 0 )
    80003ede:	e721                	bnez	a4,80003f26 <xEventGroupWaitBits+0x116>
        xAlreadyYielded = xTaskResumeAll();
    80003ee0:	ffffd097          	auipc	ra,0xffffd
    80003ee4:	638080e7          	jalr	1592(ra) # 80001518 <xTaskResumeAll>
    }
    80003ee8:	70e2                	ld	ra,56(sp)
    80003eea:	7442                	ld	s0,48(sp)
    80003eec:	7902                	ld	s2,32(sp)
    80003eee:	69e2                	ld	s3,24(sp)
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	74a2                	ld	s1,40(sp)
    80003ef4:	6121                	addi	sp,sp,64
    80003ef6:	8082                	ret
            configASSERT( !( ( xTaskGetSchedulerState() == taskSCHEDULER_SUSPENDED ) && ( xTicksToWait != 0 ) ) );
    80003ef8:	30047073          	csrci	mstatus,8
    80003efc:	a001                	j	80003efc <xEventGroupWaitBits+0xec>
            if( ( uxCurrentEventBits & uxBitsToWaitFor ) == uxBitsToWaitFor )
    80003efe:	fce416e3          	bne	s0,a4,80003eca <xEventGroupWaitBits+0xba>
                        if( xClearOnExit != pdFALSE )
    80003f02:	d4e1                	beqz	s1,80003eca <xEventGroupWaitBits+0xba>
                            pxEventBits->uxEventBits &= ~uxBitsToWaitFor;
    80003f04:	fff44713          	not	a4,s0
    80003f08:	8f7d                	and	a4,a4,a5
    80003f0a:	00e93023          	sd	a4,0(s2)
    80003f0e:	bf75                	j	80003eca <xEventGroupWaitBits+0xba>
                if( xClearOnExit != pdFALSE )
    80003f10:	da61                	beqz	a2,80003ee0 <xEventGroupWaitBits+0xd0>
                    pxEventBits->uxEventBits &= ~uxBitsToWaitFor;
    80003f12:	fff44793          	not	a5,s0
    80003f16:	8fe5                	and	a5,a5,s1
    80003f18:	00f93023          	sd	a5,0(s2)
        xAlreadyYielded = xTaskResumeAll();
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	5fc080e7          	jalr	1532(ra) # 80001518 <xTaskResumeAll>
        if( xTicksToWait != ( TickType_t ) 0 )
    80003f24:	b7d1                	j	80003ee8 <xEventGroupWaitBits+0xd8>
                if( xClearOnExit != pdFALSE )
    80003f26:	00c034b3          	snez	s1,a2
    80003f2a:	01849593          	slli	a1,s1,0x18
                    uxControlBits |= eventWAIT_FOR_ALL_BITS;
    80003f2e:	040007b7          	lui	a5,0x4000
    80003f32:	8ddd                	or	a1,a1,a5
    80003f34:	b7a9                	j	80003e7e <xEventGroupWaitBits+0x6e>

0000000080003f36 <xEventGroupClearBits>:
    {
    80003f36:	872a                	mv	a4,a0
        configASSERT( xEventGroup );
    80003f38:	c91d                	beqz	a0,80003f6e <xEventGroupClearBits+0x38>
        configASSERT( ( uxBitsToClear & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003f3a:	0ff00793          	li	a5,255
    80003f3e:	07e2                	slli	a5,a5,0x18
    80003f40:	8fed                	and	a5,a5,a1
    80003f42:	c781                	beqz	a5,80003f4a <xEventGroupClearBits+0x14>
    80003f44:	30047073          	csrci	mstatus,8
    80003f48:	a001                	j	80003f48 <xEventGroupClearBits+0x12>
        taskENTER_CRITICAL();
    80003f4a:	30047073          	csrci	mstatus,8
            uxReturn = pxEventBits->uxEventBits;
    80003f4e:	6108                	ld	a0,0(a0)
        taskENTER_CRITICAL();
    80003f50:	00003617          	auipc	a2,0x3
    80003f54:	91060613          	addi	a2,a2,-1776 # 80006860 <xCriticalNesting>
    80003f58:	6214                	ld	a3,0(a2)
            pxEventBits->uxEventBits &= ~uxBitsToClear;
    80003f5a:	fff5c593          	not	a1,a1
    80003f5e:	00a5f7b3          	and	a5,a1,a0
    80003f62:	e31c                	sd	a5,0(a4)
        taskEXIT_CRITICAL();
    80003f64:	e214                	sd	a3,0(a2)
    80003f66:	e299                	bnez	a3,80003f6c <xEventGroupClearBits+0x36>
    80003f68:	30046073          	csrsi	mstatus,8
    }
    80003f6c:	8082                	ret
        configASSERT( xEventGroup );
    80003f6e:	30047073          	csrci	mstatus,8
    80003f72:	a001                	j	80003f72 <xEventGroupClearBits+0x3c>

0000000080003f74 <xEventGroupGetBitsFromISR>:
    }
    80003f74:	6108                	ld	a0,0(a0)
    80003f76:	8082                	ret

0000000080003f78 <xEventGroupSetBits>:
        configASSERT( xEventGroup );
    80003f78:	cd11                	beqz	a0,80003f94 <xEventGroupSetBits+0x1c>
        configASSERT( ( uxBitsToSet & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003f7a:	0ff00713          	li	a4,255
    80003f7e:	0762                	slli	a4,a4,0x18
    80003f80:	00e5f7b3          	and	a5,a1,a4
    80003f84:	c781                	beqz	a5,80003f8c <xEventGroupSetBits+0x14>
    80003f86:	30047073          	csrci	mstatus,8
    80003f8a:	a001                	j	80003f8a <xEventGroupSetBits+0x12>
    80003f8c:	00000317          	auipc	t1,0x0
    80003f90:	c9030067          	jr	-880(t1) # 80003c1c <xEventGroupSetBits.part.0>
        configASSERT( xEventGroup );
    80003f94:	30047073          	csrci	mstatus,8
    80003f98:	a001                	j	80003f98 <xEventGroupSetBits+0x20>

0000000080003f9a <vEventGroupDelete>:
        configASSERT( pxEventBits );
    80003f9a:	cd0d                	beqz	a0,80003fd4 <vEventGroupDelete+0x3a>
    {
    80003f9c:	1101                	addi	sp,sp,-32
    80003f9e:	e822                	sd	s0,16(sp)
    80003fa0:	e426                	sd	s1,8(sp)
    80003fa2:	842a                	mv	s0,a0
    80003fa4:	ec06                	sd	ra,24(sp)
        vTaskSuspendAll();
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	562080e7          	jalr	1378(ra) # 80001508 <vTaskSuspendAll>
            while( listCURRENT_LIST_LENGTH( pxTasksWaitingForBits ) > ( UBaseType_t ) 0 )
    80003fae:	641c                	ld	a5,8(s0)
                configASSERT( pxTasksWaitingForBits->xListEnd.pxNext != ( const ListItem_t * ) &( pxTasksWaitingForBits->xListEnd ) );
    80003fb0:	01840493          	addi	s1,s0,24
            while( listCURRENT_LIST_LENGTH( pxTasksWaitingForBits ) > ( UBaseType_t ) 0 )
    80003fb4:	eb81                	bnez	a5,80003fc4 <vEventGroupDelete+0x2a>
    80003fb6:	a015                	j	80003fda <vEventGroupDelete+0x40>
                vTaskRemoveFromUnorderedEventList( pxTasksWaitingForBits->xListEnd.pxNext, eventUNBLOCKED_DUE_TO_BIT_SET );
    80003fb8:	ffffe097          	auipc	ra,0xffffe
    80003fbc:	a54080e7          	jalr	-1452(ra) # 80001a0c <vTaskRemoveFromUnorderedEventList>
            while( listCURRENT_LIST_LENGTH( pxTasksWaitingForBits ) > ( UBaseType_t ) 0 )
    80003fc0:	641c                	ld	a5,8(s0)
    80003fc2:	cf81                	beqz	a5,80003fda <vEventGroupDelete+0x40>
                configASSERT( pxTasksWaitingForBits->xListEnd.pxNext != ( const ListItem_t * ) &( pxTasksWaitingForBits->xListEnd ) );
    80003fc4:	7008                	ld	a0,32(s0)
                vTaskRemoveFromUnorderedEventList( pxTasksWaitingForBits->xListEnd.pxNext, eventUNBLOCKED_DUE_TO_BIT_SET );
    80003fc6:	020005b7          	lui	a1,0x2000
                configASSERT( pxTasksWaitingForBits->xListEnd.pxNext != ( const ListItem_t * ) &( pxTasksWaitingForBits->xListEnd ) );
    80003fca:	fe9517e3          	bne	a0,s1,80003fb8 <vEventGroupDelete+0x1e>
    80003fce:	30047073          	csrci	mstatus,8
    80003fd2:	a001                	j	80003fd2 <vEventGroupDelete+0x38>
        configASSERT( pxEventBits );
    80003fd4:	30047073          	csrci	mstatus,8
    80003fd8:	a001                	j	80003fd8 <vEventGroupDelete+0x3e>
        ( void ) xTaskResumeAll();
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	53e080e7          	jalr	1342(ra) # 80001518 <xTaskResumeAll>
            vPortFree( pxEventBits );
    80003fe2:	8522                	mv	a0,s0
    }
    80003fe4:	6442                	ld	s0,16(sp)
    80003fe6:	60e2                	ld	ra,24(sp)
    80003fe8:	64a2                	ld	s1,8(sp)
    80003fea:	6105                	addi	sp,sp,32
            vPortFree( pxEventBits );
    80003fec:	00001317          	auipc	t1,0x1
    80003ff0:	b9430067          	jr	-1132(t1) # 80004b80 <vPortFree>

0000000080003ff4 <vEventGroupSetBitsCallback>:
        configASSERT( xEventGroup );
    80003ff4:	cd11                	beqz	a0,80004010 <vEventGroupSetBitsCallback+0x1c>
        configASSERT( ( uxBitsToSet & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80003ff6:	ff0007b7          	lui	a5,0xff000
    80003ffa:	8fed                	and	a5,a5,a1
    80003ffc:	c781                	beqz	a5,80004004 <vEventGroupSetBitsCallback+0x10>
    80003ffe:	30047073          	csrci	mstatus,8
    80004002:	a001                	j	80004002 <vEventGroupSetBitsCallback+0xe>
    80004004:	1582                	slli	a1,a1,0x20
    80004006:	9181                	srli	a1,a1,0x20
    80004008:	00000317          	auipc	t1,0x0
    8000400c:	c1430067          	jr	-1004(t1) # 80003c1c <xEventGroupSetBits.part.0>
        configASSERT( xEventGroup );
    80004010:	30047073          	csrci	mstatus,8
    80004014:	a001                	j	80004014 <vEventGroupSetBitsCallback+0x20>

0000000080004016 <vEventGroupClearBitsCallback>:
        configASSERT( xEventGroup );
    80004016:	c91d                	beqz	a0,8000404c <vEventGroupClearBitsCallback+0x36>
        configASSERT( ( uxBitsToClear & eventEVENT_BITS_CONTROL_BYTES ) == 0 );
    80004018:	ff0007b7          	lui	a5,0xff000
    8000401c:	8fed                	and	a5,a5,a1
    8000401e:	c781                	beqz	a5,80004026 <vEventGroupClearBitsCallback+0x10>
    80004020:	30047073          	csrci	mstatus,8
    80004024:	a001                	j	80004024 <vEventGroupClearBitsCallback+0xe>
        taskENTER_CRITICAL();
    80004026:	30047073          	csrci	mstatus,8
            pxEventBits->uxEventBits &= ~uxBitsToClear;
    8000402a:	6118                	ld	a4,0(a0)
        ( void ) xEventGroupClearBits( pvEventGroup, ( EventBits_t ) ulBitsToClear );
    8000402c:	1582                	slli	a1,a1,0x20
        taskENTER_CRITICAL();
    8000402e:	00003617          	auipc	a2,0x3
    80004032:	83260613          	addi	a2,a2,-1998 # 80006860 <xCriticalNesting>
        ( void ) xEventGroupClearBits( pvEventGroup, ( EventBits_t ) ulBitsToClear );
    80004036:	9181                	srli	a1,a1,0x20
        taskENTER_CRITICAL();
    80004038:	6214                	ld	a3,0(a2)
            pxEventBits->uxEventBits &= ~uxBitsToClear;
    8000403a:	fff5c793          	not	a5,a1
    8000403e:	8ff9                	and	a5,a5,a4
    80004040:	e11c                	sd	a5,0(a0)
        taskEXIT_CRITICAL();
    80004042:	e214                	sd	a3,0(a2)
    80004044:	e299                	bnez	a3,8000404a <vEventGroupClearBitsCallback+0x34>
    80004046:	30046073          	csrsi	mstatus,8
    }
    8000404a:	8082                	ret
        configASSERT( xEventGroup );
    8000404c:	30047073          	csrci	mstatus,8
    80004050:	a001                	j	80004050 <vEventGroupClearBitsCallback+0x3a>

0000000080004052 <prvWriteBytesToBuffer.part.0>:
    configASSERT( xCount > ( size_t ) 0 );

    /* Calculate the number of bytes that can be added in the first write -
     * which may be less than the total number of bytes that need to be added if
     * the buffer will wrap back to the beginning. */
    xFirstLength = configMIN( pxStreamBuffer->xLength - xHead, xCount );
    80004052:	691c                	ld	a5,16(a0)
static size_t prvWriteBytesToBuffer( StreamBuffer_t * const pxStreamBuffer,
    80004054:	7179                	addi	sp,sp,-48
    80004056:	f022                	sd	s0,32(sp)
    80004058:	ec26                	sd	s1,24(sp)
    8000405a:	e84a                	sd	s2,16(sp)
    8000405c:	e44e                	sd	s3,8(sp)
    8000405e:	e052                	sd	s4,0(sp)
    80004060:	f406                	sd	ra,40(sp)
    xFirstLength = configMIN( pxStreamBuffer->xLength - xHead, xCount );
    80004062:	40d789b3          	sub	s3,a5,a3
static size_t prvWriteBytesToBuffer( StreamBuffer_t * const pxStreamBuffer,
    80004066:	892a                	mv	s2,a0
    80004068:	8436                	mv	s0,a3
    8000406a:	84b2                	mv	s1,a2
    8000406c:	8a2e                	mv	s4,a1
    xFirstLength = configMIN( pxStreamBuffer->xLength - xHead, xCount );
    8000406e:	01367363          	bgeu	a2,s3,80004074 <prvWriteBytesToBuffer.part.0+0x22>
    80004072:	89b2                	mv	s3,a2

    /* Write as many bytes as can be written in the first write. */
    configASSERT( ( xHead + xFirstLength ) <= pxStreamBuffer->xLength );
    80004074:	01340733          	add	a4,s0,s3
    80004078:	00e7f563          	bgeu	a5,a4,80004082 <prvWriteBytesToBuffer.part.0+0x30>
    8000407c:	30047073          	csrci	mstatus,8
    80004080:	a001                	j	80004080 <prvWriteBytesToBuffer.part.0+0x2e>
    ( void ) memcpy( ( void * ) ( &( pxStreamBuffer->pucBuffer[ xHead ] ) ), ( const void * ) pucData, xFirstLength );
    80004082:	03093503          	ld	a0,48(s2)
    80004086:	864e                	mv	a2,s3
    80004088:	85d2                	mv	a1,s4
    8000408a:	9522                	add	a0,a0,s0
    8000408c:	00001097          	auipc	ra,0x1
    80004090:	738080e7          	jalr	1848(ra) # 800057c4 <memcpy>

    /* If the number of bytes written was less than the number that could be
     * written in the first write... */
    if( xCount > xFirstLength )
    80004094:	0299f363          	bgeu	s3,s1,800040ba <prvWriteBytesToBuffer.part.0+0x68>
    {
        /* ...then write the remaining bytes to the start of the buffer. */
        configASSERT( ( xCount - xFirstLength ) <= pxStreamBuffer->xLength );
    80004098:	01093783          	ld	a5,16(s2)
    8000409c:	41348633          	sub	a2,s1,s3
    800040a0:	00c7f563          	bgeu	a5,a2,800040aa <prvWriteBytesToBuffer.part.0+0x58>
    800040a4:	30047073          	csrci	mstatus,8
    800040a8:	a001                	j	800040a8 <prvWriteBytesToBuffer.part.0+0x56>
    800040aa:	03093503          	ld	a0,48(s2)
    800040ae:	013a05b3          	add	a1,s4,s3
    800040b2:	00001097          	auipc	ra,0x1
    800040b6:	712080e7          	jalr	1810(ra) # 800057c4 <memcpy>
        mtCOVERAGE_TEST_MARKER();
    }

    xHead += xCount;

    if( xHead >= pxStreamBuffer->xLength )
    800040ba:	01093783          	ld	a5,16(s2)
    xHead += xCount;
    800040be:	00940533          	add	a0,s0,s1
    if( xHead >= pxStreamBuffer->xLength )
    800040c2:	00f56363          	bltu	a0,a5,800040c8 <prvWriteBytesToBuffer.part.0+0x76>
    {
        xHead -= pxStreamBuffer->xLength;
    800040c6:	8d1d                	sub	a0,a0,a5
    {
        mtCOVERAGE_TEST_MARKER();
    }

    return xHead;
}
    800040c8:	70a2                	ld	ra,40(sp)
    800040ca:	7402                	ld	s0,32(sp)
    800040cc:	64e2                	ld	s1,24(sp)
    800040ce:	6942                	ld	s2,16(sp)
    800040d0:	69a2                	ld	s3,8(sp)
    800040d2:	6a02                	ld	s4,0(sp)
    800040d4:	6145                	addi	sp,sp,48
    800040d6:	8082                	ret

00000000800040d8 <prvWriteMessageToBuffer>:
{
    800040d8:	7139                	addi	sp,sp,-64
    800040da:	f822                	sd	s0,48(sp)
    800040dc:	f426                	sd	s1,40(sp)
    800040de:	ec4e                	sd	s3,24(sp)
    800040e0:	fc06                	sd	ra,56(sp)
    800040e2:	f04a                	sd	s2,32(sp)
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800040e4:	03854783          	lbu	a5,56(a0)
    size_t xNextHead = pxStreamBuffer->xHead;
    800040e8:	00853803          	ld	a6,8(a0)
{
    800040ec:	842a                	mv	s0,a0
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800040ee:	8b85                	andi	a5,a5,1
{
    800040f0:	89ae                	mv	s3,a1
    800040f2:	84b2                	mv	s1,a2
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800040f4:	cf89                	beqz	a5,8000410e <prvWriteMessageToBuffer+0x36>
        xMessageLength = ( configMESSAGE_BUFFER_LENGTH_TYPE ) xDataLengthBytes;
    800040f6:	e432                	sd	a2,8(sp)
            xDataLengthBytes = 0;
    800040f8:	4901                	li	s2,0
        if( xSpace >= xRequiredSpace )
    800040fa:	04e6f163          	bgeu	a3,a4,8000413c <prvWriteMessageToBuffer+0x64>
}
    800040fe:	70e2                	ld	ra,56(sp)
    80004100:	7442                	ld	s0,48(sp)
    80004102:	74a2                	ld	s1,40(sp)
    80004104:	69e2                	ld	s3,24(sp)
    80004106:	854a                	mv	a0,s2
    80004108:	7902                	ld	s2,32(sp)
    8000410a:	6121                	addi	sp,sp,64
    8000410c:	8082                	ret
        xDataLengthBytes = configMIN( xDataLengthBytes, xSpace );
    8000410e:	8936                	mv	s2,a3
    80004110:	00d67363          	bgeu	a2,a3,80004116 <prvWriteMessageToBuffer+0x3e>
    80004114:	8932                	mv	s2,a2
    if( xDataLengthBytes != ( size_t ) 0 )
    80004116:	fe0904e3          	beqz	s2,800040fe <prvWriteMessageToBuffer+0x26>
    configASSERT( xCount > ( size_t ) 0 );
    8000411a:	864a                	mv	a2,s2
    8000411c:	85ce                	mv	a1,s3
    8000411e:	8522                	mv	a0,s0
    80004120:	86c2                	mv	a3,a6
    80004122:	00000097          	auipc	ra,0x0
    80004126:	f30080e7          	jalr	-208(ra) # 80004052 <prvWriteBytesToBuffer.part.0>
        pxStreamBuffer->xHead = prvWriteBytesToBuffer( pxStreamBuffer, ( const uint8_t * ) pvTxData, xDataLengthBytes, xNextHead );
    8000412a:	e408                	sd	a0,8(s0)
}
    8000412c:	70e2                	ld	ra,56(sp)
    8000412e:	7442                	ld	s0,48(sp)
    80004130:	74a2                	ld	s1,40(sp)
    80004132:	69e2                	ld	s3,24(sp)
    80004134:	854a                	mv	a0,s2
    80004136:	7902                	ld	s2,32(sp)
    80004138:	6121                	addi	sp,sp,64
    8000413a:	8082                	ret
    configASSERT( xCount > ( size_t ) 0 );
    8000413c:	86c2                	mv	a3,a6
    8000413e:	4621                	li	a2,8
    80004140:	002c                	addi	a1,sp,8
    80004142:	00000097          	auipc	ra,0x0
    80004146:	f10080e7          	jalr	-240(ra) # 80004052 <prvWriteBytesToBuffer.part.0>
    8000414a:	882a                	mv	a6,a0
    return xHead;
    8000414c:	8926                	mv	s2,s1
    8000414e:	b7e1                	j	80004116 <prvWriteMessageToBuffer+0x3e>

0000000080004150 <prvReadBytesFromBuffer.part.0>:
    configASSERT( xCount != ( size_t ) 0 );

    /* Calculate the number of bytes that can be read - which may be
     * less than the number wanted if the data wraps around to the start of
     * the buffer. */
    xFirstLength = configMIN( pxStreamBuffer->xLength - xTail, xCount );
    80004150:	6918                	ld	a4,16(a0)
static size_t prvReadBytesFromBuffer( StreamBuffer_t * pxStreamBuffer,
    80004152:	7179                	addi	sp,sp,-48
    80004154:	f022                	sd	s0,32(sp)
    80004156:	ec26                	sd	s1,24(sp)
    80004158:	e84a                	sd	s2,16(sp)
    8000415a:	e44e                	sd	s3,8(sp)
    8000415c:	f406                	sd	ra,40(sp)
    xFirstLength = configMIN( pxStreamBuffer->xLength - xTail, xCount );
    8000415e:	40d709b3          	sub	s3,a4,a3
static size_t prvReadBytesFromBuffer( StreamBuffer_t * pxStreamBuffer,
    80004162:	892a                	mv	s2,a0
    80004164:	8436                	mv	s0,a3
    80004166:	84b2                	mv	s1,a2
    80004168:	87ae                	mv	a5,a1
    xFirstLength = configMIN( pxStreamBuffer->xLength - xTail, xCount );
    8000416a:	01367363          	bgeu	a2,s3,80004170 <prvReadBytesFromBuffer.part.0+0x20>
    8000416e:	89b2                	mv	s3,a2

    /* Obtain the number of bytes it is possible to obtain in the first
     * read.  Asserts check bounds of read and write. */
    configASSERT( xFirstLength <= xCount );
    configASSERT( ( xTail + xFirstLength ) <= pxStreamBuffer->xLength );
    80004170:	013406b3          	add	a3,s0,s3
    80004174:	00d77563          	bgeu	a4,a3,8000417e <prvReadBytesFromBuffer.part.0+0x2e>
    80004178:	30047073          	csrci	mstatus,8
    8000417c:	a001                	j	8000417c <prvReadBytesFromBuffer.part.0+0x2c>
    ( void ) memcpy( ( void * ) pucData, ( const void * ) &( pxStreamBuffer->pucBuffer[ xTail ] ), xFirstLength );
    8000417e:	03093583          	ld	a1,48(s2)
    80004182:	864e                	mv	a2,s3
    80004184:	853e                	mv	a0,a5
    80004186:	95a2                	add	a1,a1,s0
    80004188:	00001097          	auipc	ra,0x1
    8000418c:	63c080e7          	jalr	1596(ra) # 800057c4 <memcpy>

    /* If the total number of wanted bytes is greater than the number
     * that could be read in the first read... */
    if( xCount > xFirstLength )
    80004190:	0299e063          	bltu	s3,s1,800041b0 <prvReadBytesFromBuffer.part.0+0x60>
    }

    /* Move the tail pointer to effectively remove the data read from the buffer. */
    xTail += xCount;

    if( xTail >= pxStreamBuffer->xLength )
    80004194:	01093783          	ld	a5,16(s2)
    xTail += xCount;
    80004198:	00940533          	add	a0,s0,s1
    if( xTail >= pxStreamBuffer->xLength )
    8000419c:	00f56363          	bltu	a0,a5,800041a2 <prvReadBytesFromBuffer.part.0+0x52>
    {
        xTail -= pxStreamBuffer->xLength;
    800041a0:	8d1d                	sub	a0,a0,a5
    }

    return xTail;
}
    800041a2:	70a2                	ld	ra,40(sp)
    800041a4:	7402                	ld	s0,32(sp)
    800041a6:	64e2                	ld	s1,24(sp)
    800041a8:	6942                	ld	s2,16(sp)
    800041aa:	69a2                	ld	s3,8(sp)
    800041ac:	6145                	addi	sp,sp,48
    800041ae:	8082                	ret
    800041b0:	03093583          	ld	a1,48(s2)
    800041b4:	41348633          	sub	a2,s1,s3
    800041b8:	954e                	add	a0,a0,s3
    800041ba:	00001097          	auipc	ra,0x1
    800041be:	60a080e7          	jalr	1546(ra) # 800057c4 <memcpy>
    800041c2:	bfc9                	j	80004194 <prvReadBytesFromBuffer.part.0+0x44>

00000000800041c4 <prvReadMessageFromBuffer>:
{
    800041c4:	7139                	addi	sp,sp,-64
    800041c6:	f822                	sd	s0,48(sp)
    800041c8:	f426                	sd	s1,40(sp)
    800041ca:	ec4e                	sd	s3,24(sp)
    800041cc:	e852                	sd	s4,16(sp)
    800041ce:	fc06                	sd	ra,56(sp)
    800041d0:	f04a                	sd	s2,32(sp)
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800041d2:	03854783          	lbu	a5,56(a0)
    size_t xNextTail = pxStreamBuffer->xTail;
    800041d6:	6118                	ld	a4,0(a0)
{
    800041d8:	842a                	mv	s0,a0
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800041da:	8b85                	andi	a5,a5,1
{
    800041dc:	8a2e                	mv	s4,a1
    800041de:	84b2                	mv	s1,a2
    800041e0:	89b6                	mv	s3,a3
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800041e2:	eb95                	bnez	a5,80004216 <prvReadMessageFromBuffer+0x52>
    xCount = configMIN( xNextMessageLength, xBytesAvailable );
    800041e4:	894e                	mv	s2,s3
    800041e6:	0334e663          	bltu	s1,s3,80004212 <prvReadMessageFromBuffer+0x4e>
    if( xCount != ( size_t ) 0 )
    800041ea:	00090b63          	beqz	s2,80004200 <prvReadMessageFromBuffer+0x3c>
    configASSERT( xCount != ( size_t ) 0 );
    800041ee:	86ba                	mv	a3,a4
    800041f0:	864a                	mv	a2,s2
    800041f2:	85d2                	mv	a1,s4
    800041f4:	8522                	mv	a0,s0
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	f5a080e7          	jalr	-166(ra) # 80004150 <prvReadBytesFromBuffer.part.0>
        pxStreamBuffer->xTail = prvReadBytesFromBuffer( pxStreamBuffer, ( uint8_t * ) pvRxData, xCount, xNextTail );
    800041fe:	e008                	sd	a0,0(s0)
}
    80004200:	70e2                	ld	ra,56(sp)
    80004202:	7442                	ld	s0,48(sp)
    80004204:	74a2                	ld	s1,40(sp)
    80004206:	69e2                	ld	s3,24(sp)
    80004208:	6a42                	ld	s4,16(sp)
    8000420a:	854a                	mv	a0,s2
    8000420c:	7902                	ld	s2,32(sp)
    8000420e:	6121                	addi	sp,sp,64
    80004210:	8082                	ret
    xCount = configMIN( xNextMessageLength, xBytesAvailable );
    80004212:	8926                	mv	s2,s1
    80004214:	bfd9                	j	800041ea <prvReadMessageFromBuffer+0x26>
    configASSERT( xCount != ( size_t ) 0 );
    80004216:	86ba                	mv	a3,a4
    80004218:	4621                	li	a2,8
    8000421a:	002c                	addi	a1,sp,8
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	f34080e7          	jalr	-204(ra) # 80004150 <prvReadBytesFromBuffer.part.0>
        xNextMessageLength = ( size_t ) xTempNextMessageLength;
    80004224:	67a2                	ld	a5,8(sp)
    80004226:	872a                	mv	a4,a0
    xCount = configMIN( xNextMessageLength, xBytesAvailable );
    80004228:	4901                	li	s2,0
        if( xNextMessageLength > xBufferLengthBytes )
    8000422a:	fcf4ebe3          	bltu	s1,a5,80004200 <prvReadMessageFromBuffer+0x3c>
        xBytesAvailable -= sbBYTES_TO_STORE_MESSAGE_LENGTH;
    8000422e:	19e1                	addi	s3,s3,-8
    80004230:	84be                	mv	s1,a5
    80004232:	bf4d                	j	800041e4 <prvReadMessageFromBuffer+0x20>

0000000080004234 <xStreamBufferGenericCreate>:
    {
    80004234:	7179                	addi	sp,sp,-48
    80004236:	f022                	sd	s0,32(sp)
    80004238:	ec26                	sd	s1,24(sp)
    8000423a:	f406                	sd	ra,40(sp)
    8000423c:	e84a                	sd	s2,16(sp)
    8000423e:	e44e                	sd	s3,8(sp)
    80004240:	e052                	sd	s4,0(sp)
        if( xStreamBufferType == sbTYPE_MESSAGE_BUFFER )
    80004242:	4785                	li	a5,1
    {
    80004244:	842a                	mv	s0,a0
    80004246:	84ae                	mv	s1,a1
        if( xStreamBufferType == sbTYPE_MESSAGE_BUFFER )
    80004248:	00f60d63          	beq	a2,a5,80004262 <xStreamBufferGenericCreate+0x2e>
        else if( xStreamBufferType == sbTYPE_STREAM_BATCHING_BUFFER )
    8000424c:	4789                	li	a5,2
    8000424e:	00f60663          	beq	a2,a5,8000425a <xStreamBufferGenericCreate+0x26>
            configASSERT( xBufferSizeBytes > 0 );
    80004252:	ed11                	bnez	a0,8000426e <xStreamBufferGenericCreate+0x3a>
    80004254:	30047073          	csrci	mstatus,8
    80004258:	a001                	j	80004258 <xStreamBufferGenericCreate+0x24>
            configASSERT( xBufferSizeBytes > 0 );
    8000425a:	e925                	bnez	a0,800042ca <xStreamBufferGenericCreate+0x96>
    8000425c:	30047073          	csrci	mstatus,8
    80004260:	a001                	j	80004260 <xStreamBufferGenericCreate+0x2c>
            configASSERT( xBufferSizeBytes > sbBYTES_TO_STORE_MESSAGE_LENGTH );
    80004262:	47a1                	li	a5,8
    80004264:	04a7e763          	bltu	a5,a0,800042b2 <xStreamBufferGenericCreate+0x7e>
    80004268:	30047073          	csrci	mstatus,8
    8000426c:	a001                	j	8000426c <xStreamBufferGenericCreate+0x38>
            ucFlags = 0;
    8000426e:	4981                	li	s3,0
        configASSERT( xTriggerLevelBytes <= xBufferSizeBytes );
    80004270:	00947563          	bgeu	s0,s1,8000427a <xStreamBufferGenericCreate+0x46>
    80004274:	30047073          	csrci	mstatus,8
    80004278:	a001                	j	80004278 <xStreamBufferGenericCreate+0x44>
        if( xBufferSizeBytes < ( xBufferSizeBytes + 1U + sizeof( StreamBuffer_t ) ) )
    8000427a:	fb600793          	li	a5,-74
    8000427e:	0287ec63          	bltu	a5,s0,800042b6 <xStreamBufferGenericCreate+0x82>
            pvAllocatedMemory = pvPortMalloc( xBufferSizeBytes + sizeof( StreamBuffer_t ) );
    80004282:	04940513          	addi	a0,s0,73
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	744080e7          	jalr	1860(ra) # 800049ca <pvPortMalloc>
    8000428e:	892a                	mv	s2,a0
        if( pvAllocatedMemory != NULL )
    80004290:	c11d                	beqz	a0,800042b6 <xStreamBufferGenericCreate+0x82>
            prvInitialiseNewStreamBuffer( ( StreamBuffer_t * ) pvAllocatedMemory,                         /* Structure at the start of the allocated memory. */
    80004292:	04850a13          	addi	s4,a0,72
            xBufferSizeBytes++;
    80004296:	0405                	addi	s0,s0,1
  return __builtin___memset_chk (__dest, __ch, __len,
    80004298:	8622                	mv	a2,s0
    8000429a:	05500593          	li	a1,85
    8000429e:	8552                	mv	a0,s4
    800042a0:	00001097          	auipc	ra,0x1
    800042a4:	50c080e7          	jalr	1292(ra) # 800057ac <memset>
    {
        /* The value written just has to be identifiable when looking at the
         * memory.  Don't use 0xA5 as that is the stack fill value and could
         * result in confusion as to what is actually being observed. */
        #define STREAM_BUFFER_BUFFER_WRITE_VALUE    ( 0x55 )
        configASSERT( memset( pucBuffer, ( int ) STREAM_BUFFER_BUFFER_WRITE_VALUE, xBufferSizeBytes ) == pucBuffer );
    800042a8:	02aa0363          	beq	s4,a0,800042ce <xStreamBufferGenericCreate+0x9a>
    800042ac:	30047073          	csrci	mstatus,8
    800042b0:	a001                	j	800042b0 <xStreamBufferGenericCreate+0x7c>
            ucFlags = sbFLAGS_IS_MESSAGE_BUFFER;
    800042b2:	4985                	li	s3,1
    800042b4:	bf75                	j	80004270 <xStreamBufferGenericCreate+0x3c>
            pvAllocatedMemory = NULL;
    800042b6:	4901                	li	s2,0
    }
    800042b8:	70a2                	ld	ra,40(sp)
    800042ba:	7402                	ld	s0,32(sp)
    800042bc:	64e2                	ld	s1,24(sp)
    800042be:	69a2                	ld	s3,8(sp)
    800042c0:	6a02                	ld	s4,0(sp)
    800042c2:	854a                	mv	a0,s2
    800042c4:	6942                	ld	s2,16(sp)
    800042c6:	6145                	addi	sp,sp,48
    800042c8:	8082                	ret
            ucFlags = sbFLAGS_IS_BATCHING_BUFFER;
    800042ca:	4991                	li	s3,4
    800042cc:	b755                	j	80004270 <xStreamBufferGenericCreate+0x3c>
    800042ce:	4581                	li	a1,0
    800042d0:	04800613          	li	a2,72
    800042d4:	854a                	mv	a0,s2
    800042d6:	00001097          	auipc	ra,0x1
    800042da:	4d6080e7          	jalr	1238(ra) # 800057ac <memset>
    }
    #endif

    ( void ) memset( ( void * ) pxStreamBuffer, 0x00, sizeof( StreamBuffer_t ) );
    pxStreamBuffer->pucBuffer = pucBuffer;
    800042de:	03493823          	sd	s4,48(s2)
    pxStreamBuffer->xLength = xBufferSizeBytes;
    800042e2:	00893823          	sd	s0,16(s2)
    pxStreamBuffer->xTriggerLevelBytes = xTriggerLevelBytes;
    800042e6:	85a6                	mv	a1,s1
    800042e8:	e091                	bnez	s1,800042ec <xStreamBufferGenericCreate+0xb8>
    800042ea:	4585                	li	a1,1
    800042ec:	00b93c23          	sd	a1,24(s2)
    pxStreamBuffer->ucFlags = ucFlags;
    800042f0:	03390c23          	sb	s3,56(s2)
        return ( StreamBufferHandle_t ) pvAllocatedMemory;
    800042f4:	b7d1                	j	800042b8 <xStreamBufferGenericCreate+0x84>

00000000800042f6 <vStreamBufferDelete>:
    configASSERT( pxStreamBuffer );
    800042f6:	c105                	beqz	a0,80004316 <vStreamBufferDelete+0x20>
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_STATICALLY_ALLOCATED ) == ( uint8_t ) pdFALSE )
    800042f8:	03854783          	lbu	a5,56(a0)
    800042fc:	8b89                	andi	a5,a5,2
    800042fe:	e789                	bnez	a5,80004308 <vStreamBufferDelete+0x12>
            vPortFree( ( void * ) pxStreamBuffer );
    80004300:	00001317          	auipc	t1,0x1
    80004304:	88030067          	jr	-1920(t1) # 80004b80 <vPortFree>
    80004308:	04800613          	li	a2,72
    8000430c:	4581                	li	a1,0
    8000430e:	00001317          	auipc	t1,0x1
    80004312:	49e30067          	jr	1182(t1) # 800057ac <memset>
    configASSERT( pxStreamBuffer );
    80004316:	30047073          	csrci	mstatus,8
    8000431a:	a001                	j	8000431a <vStreamBufferDelete+0x24>

000000008000431c <xStreamBufferReset>:
    configASSERT( pxStreamBuffer );
    8000431c:	c93d                	beqz	a0,80004392 <xStreamBufferReset+0x76>
{
    8000431e:	7139                	addi	sp,sp,-64
    80004320:	f822                	sd	s0,48(sp)
    80004322:	fc06                	sd	ra,56(sp)
    80004324:	f426                	sd	s1,40(sp)
    80004326:	f04a                	sd	s2,32(sp)
    80004328:	ec4e                	sd	s3,24(sp)
    8000432a:	e852                	sd	s4,16(sp)
    8000432c:	e456                	sd	s5,8(sp)
    8000432e:	842a                	mv	s0,a0
    taskENTER_CRITICAL();
    80004330:	30047073          	csrci	mstatus,8
    80004334:	00002497          	auipc	s1,0x2
    80004338:	52c48493          	addi	s1,s1,1324 # 80006860 <xCriticalNesting>
    8000433c:	609c                	ld	a5,0(s1)
        if( ( pxStreamBuffer->xTaskWaitingToReceive == NULL ) && ( pxStreamBuffer->xTaskWaitingToSend == NULL ) )
    8000433e:	7118                	ld	a4,32(a0)
    BaseType_t xReturn = pdFAIL;
    80004340:	4501                	li	a0,0
    taskENTER_CRITICAL();
    80004342:	00178693          	addi	a3,a5,1 # ffffffffff000001 <_stack_top+0xffffffff6f000001>
    80004346:	e094                	sd	a3,0(s1)
        if( ( pxStreamBuffer->xTaskWaitingToReceive == NULL ) && ( pxStreamBuffer->xTaskWaitingToSend == NULL ) )
    80004348:	cf11                	beqz	a4,80004364 <xStreamBufferReset+0x48>
    taskEXIT_CRITICAL();
    8000434a:	e09c                	sd	a5,0(s1)
    8000434c:	e399                	bnez	a5,80004352 <xStreamBufferReset+0x36>
    8000434e:	30046073          	csrsi	mstatus,8
}
    80004352:	70e2                	ld	ra,56(sp)
    80004354:	7442                	ld	s0,48(sp)
    80004356:	74a2                	ld	s1,40(sp)
    80004358:	7902                	ld	s2,32(sp)
    8000435a:	69e2                	ld	s3,24(sp)
    8000435c:	6a42                	ld	s4,16(sp)
    8000435e:	6aa2                	ld	s5,8(sp)
    80004360:	6121                	addi	sp,sp,64
    80004362:	8082                	ret
        if( ( pxStreamBuffer->xTaskWaitingToReceive == NULL ) && ( pxStreamBuffer->xTaskWaitingToSend == NULL ) )
    80004364:	7418                	ld	a4,40(s0)
    80004366:	f375                	bnez	a4,8000434a <xStreamBufferReset+0x2e>
            prvInitialiseNewStreamBuffer( pxStreamBuffer,
    80004368:	03043903          	ld	s2,48(s0)
    8000436c:	01043983          	ld	s3,16(s0)
    80004370:	05500593          	li	a1,85
    80004374:	854a                	mv	a0,s2
    80004376:	864e                	mv	a2,s3
    80004378:	01843a83          	ld	s5,24(s0)
    8000437c:	03844a03          	lbu	s4,56(s0)
    80004380:	00001097          	auipc	ra,0x1
    80004384:	42c080e7          	jalr	1068(ra) # 800057ac <memset>
        configASSERT( memset( pucBuffer, ( int ) STREAM_BUFFER_BUFFER_WRITE_VALUE, xBufferSizeBytes ) == pucBuffer );
    80004388:	00a90863          	beq	s2,a0,80004398 <xStreamBufferReset+0x7c>
    8000438c:	30047073          	csrci	mstatus,8
    80004390:	a001                	j	80004390 <xStreamBufferReset+0x74>
    configASSERT( pxStreamBuffer );
    80004392:	30047073          	csrci	mstatus,8
    80004396:	a001                	j	80004396 <xStreamBufferReset+0x7a>
    80004398:	04800613          	li	a2,72
    8000439c:	4581                	li	a1,0
    8000439e:	8522                	mv	a0,s0
    800043a0:	00001097          	auipc	ra,0x1
    800043a4:	40c080e7          	jalr	1036(ra) # 800057ac <memset>
    taskEXIT_CRITICAL();
    800043a8:	609c                	ld	a5,0(s1)
    pxStreamBuffer->pucBuffer = pucBuffer;
    800043aa:	03243823          	sd	s2,48(s0)
    pxStreamBuffer->xLength = xBufferSizeBytes;
    800043ae:	01343823          	sd	s3,16(s0)
    pxStreamBuffer->xTriggerLevelBytes = xTriggerLevelBytes;
    800043b2:	01543c23          	sd	s5,24(s0)
    pxStreamBuffer->ucFlags = ucFlags;
    800043b6:	03440c23          	sb	s4,56(s0)
    taskEXIT_CRITICAL();
    800043ba:	17fd                	addi	a5,a5,-1
            xReturn = pdPASS;
    800043bc:	4505                	li	a0,1
        /* More details at: https://github.com/FreeRTOS/FreeRTOS-Kernel/blob/main/MISRA.md#rule-111 */
        /* coverity[misra_c_2012_rule_11_1_violation] */
        ( void ) pxReceiveCompletedCallback;
    }
    #endif /* if ( configUSE_SB_COMPLETED_CALLBACK == 1 ) */
}
    800043be:	b771                	j	8000434a <xStreamBufferReset+0x2e>

00000000800043c0 <xStreamBufferResetFromISR>:
    configASSERT( pxStreamBuffer );
    800043c0:	c931                	beqz	a0,80004414 <xStreamBufferResetFromISR+0x54>
        if( ( pxStreamBuffer->xTaskWaitingToReceive == NULL ) && ( pxStreamBuffer->xTaskWaitingToSend == NULL ) )
    800043c2:	711c                	ld	a5,32(a0)
{
    800043c4:	7179                	addi	sp,sp,-48
    800043c6:	f022                	sd	s0,32(sp)
    800043c8:	f406                	sd	ra,40(sp)
    800043ca:	ec26                	sd	s1,24(sp)
    800043cc:	e84a                	sd	s2,16(sp)
    800043ce:	e44e                	sd	s3,8(sp)
    800043d0:	e052                	sd	s4,0(sp)
    800043d2:	842a                	mv	s0,a0
    BaseType_t xReturn = pdFAIL;
    800043d4:	4501                	li	a0,0
        if( ( pxStreamBuffer->xTaskWaitingToReceive == NULL ) && ( pxStreamBuffer->xTaskWaitingToSend == NULL ) )
    800043d6:	cb89                	beqz	a5,800043e8 <xStreamBufferResetFromISR+0x28>
}
    800043d8:	70a2                	ld	ra,40(sp)
    800043da:	7402                	ld	s0,32(sp)
    800043dc:	64e2                	ld	s1,24(sp)
    800043de:	6942                	ld	s2,16(sp)
    800043e0:	69a2                	ld	s3,8(sp)
    800043e2:	6a02                	ld	s4,0(sp)
    800043e4:	6145                	addi	sp,sp,48
    800043e6:	8082                	ret
        if( ( pxStreamBuffer->xTaskWaitingToReceive == NULL ) && ( pxStreamBuffer->xTaskWaitingToSend == NULL ) )
    800043e8:	741c                	ld	a5,40(s0)
    800043ea:	f7fd                	bnez	a5,800043d8 <xStreamBufferResetFromISR+0x18>
            prvInitialiseNewStreamBuffer( pxStreamBuffer,
    800043ec:	7804                	ld	s1,48(s0)
    800043ee:	01043903          	ld	s2,16(s0)
    800043f2:	05500593          	li	a1,85
    800043f6:	8526                	mv	a0,s1
    800043f8:	864a                	mv	a2,s2
    800043fa:	01843a03          	ld	s4,24(s0)
    800043fe:	03844983          	lbu	s3,56(s0)
    80004402:	00001097          	auipc	ra,0x1
    80004406:	3aa080e7          	jalr	938(ra) # 800057ac <memset>
        configASSERT( memset( pucBuffer, ( int ) STREAM_BUFFER_BUFFER_WRITE_VALUE, xBufferSizeBytes ) == pucBuffer );
    8000440a:	00a48863          	beq	s1,a0,8000441a <xStreamBufferResetFromISR+0x5a>
    8000440e:	30047073          	csrci	mstatus,8
    80004412:	a001                	j	80004412 <xStreamBufferResetFromISR+0x52>
    configASSERT( pxStreamBuffer );
    80004414:	30047073          	csrci	mstatus,8
    80004418:	a001                	j	80004418 <xStreamBufferResetFromISR+0x58>
    8000441a:	04800613          	li	a2,72
    8000441e:	4581                	li	a1,0
    80004420:	8522                	mv	a0,s0
    80004422:	00001097          	auipc	ra,0x1
    80004426:	38a080e7          	jalr	906(ra) # 800057ac <memset>
            xReturn = pdPASS;
    8000442a:	4505                	li	a0,1
    pxStreamBuffer->pucBuffer = pucBuffer;
    8000442c:	f804                	sd	s1,48(s0)
    pxStreamBuffer->xLength = xBufferSizeBytes;
    8000442e:	01243823          	sd	s2,16(s0)
    pxStreamBuffer->xTriggerLevelBytes = xTriggerLevelBytes;
    80004432:	01443c23          	sd	s4,24(s0)
    pxStreamBuffer->ucFlags = ucFlags;
    80004436:	03340c23          	sb	s3,56(s0)
}
    8000443a:	bf79                	j	800043d8 <xStreamBufferResetFromISR+0x18>

000000008000443c <xStreamBufferSetTriggerLevel>:
{
    8000443c:	87aa                	mv	a5,a0
    configASSERT( pxStreamBuffer );
    8000443e:	cd19                	beqz	a0,8000445c <xStreamBufferSetTriggerLevel+0x20>
    if( xTriggerLevel == ( size_t ) 0 )
    80004440:	c981                	beqz	a1,80004450 <xStreamBufferSetTriggerLevel+0x14>
    if( xTriggerLevel < pxStreamBuffer->xLength )
    80004442:	6b98                	ld	a4,16(a5)
        xReturn = pdFALSE;
    80004444:	4501                	li	a0,0
    if( xTriggerLevel < pxStreamBuffer->xLength )
    80004446:	00e5f463          	bgeu	a1,a4,8000444e <xStreamBufferSetTriggerLevel+0x12>
        pxStreamBuffer->xTriggerLevelBytes = xTriggerLevel;
    8000444a:	ef8c                	sd	a1,24(a5)
        xReturn = pdPASS;
    8000444c:	4505                	li	a0,1
}
    8000444e:	8082                	ret
    if( xTriggerLevel < pxStreamBuffer->xLength )
    80004450:	6b98                	ld	a4,16(a5)
    80004452:	4585                	li	a1,1
        xReturn = pdFALSE;
    80004454:	4501                	li	a0,0
    if( xTriggerLevel < pxStreamBuffer->xLength )
    80004456:	fee5fce3          	bgeu	a1,a4,8000444e <xStreamBufferSetTriggerLevel+0x12>
    8000445a:	bfc5                	j	8000444a <xStreamBufferSetTriggerLevel+0xe>
    configASSERT( pxStreamBuffer );
    8000445c:	30047073          	csrci	mstatus,8
    80004460:	a001                	j	80004460 <xStreamBufferSetTriggerLevel+0x24>

0000000080004462 <xStreamBufferSpacesAvailable>:
    configASSERT( pxStreamBuffer );
    80004462:	c105                	beqz	a0,80004482 <xStreamBufferSpacesAvailable+0x20>
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004464:	690c                	ld	a1,16(a0)
        xOriginalTail = pxStreamBuffer->xTail;
    80004466:	6118                	ld	a4,0(a0)
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004468:	6114                	ld	a3,0(a0)
        xSpace -= pxStreamBuffer->xHead;
    8000446a:	6510                	ld	a2,8(a0)
    } while( xOriginalTail != pxStreamBuffer->xTail );
    8000446c:	611c                	ld	a5,0(a0)
    8000446e:	fef71ce3          	bne	a4,a5,80004466 <xStreamBufferSpacesAvailable+0x4>
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004472:	00d58533          	add	a0,a1,a3
    80004476:	157d                	addi	a0,a0,-1
    xSpace -= ( size_t ) 1;
    80004478:	8d11                	sub	a0,a0,a2
    if( xSpace >= pxStreamBuffer->xLength )
    8000447a:	00b56363          	bltu	a0,a1,80004480 <xStreamBufferSpacesAvailable+0x1e>
        xSpace -= pxStreamBuffer->xLength;
    8000447e:	8d0d                	sub	a0,a0,a1
}
    80004480:	8082                	ret
    configASSERT( pxStreamBuffer );
    80004482:	30047073          	csrci	mstatus,8
    80004486:	a001                	j	80004486 <xStreamBufferSpacesAvailable+0x24>

0000000080004488 <xStreamBufferBytesAvailable>:
    configASSERT( pxStreamBuffer );
    80004488:	c919                	beqz	a0,8000449e <xStreamBufferBytesAvailable+0x16>
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    8000448a:	651c                	ld	a5,8(a0)
    8000448c:	6918                	ld	a4,16(a0)
    xCount -= pxStreamBuffer->xTail;
    8000448e:	6114                	ld	a3,0(a0)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004490:	00f70533          	add	a0,a4,a5
    xCount -= pxStreamBuffer->xTail;
    80004494:	8d15                	sub	a0,a0,a3
    if( xCount >= pxStreamBuffer->xLength )
    80004496:	00e56363          	bltu	a0,a4,8000449c <xStreamBufferBytesAvailable+0x14>
        xCount -= pxStreamBuffer->xLength;
    8000449a:	8d19                	sub	a0,a0,a4
}
    8000449c:	8082                	ret
    configASSERT( pxStreamBuffer );
    8000449e:	30047073          	csrci	mstatus,8
    800044a2:	a001                	j	800044a2 <xStreamBufferBytesAvailable+0x1a>

00000000800044a4 <xStreamBufferSend>:
{
    800044a4:	711d                	addi	sp,sp,-96
    800044a6:	ec86                	sd	ra,88(sp)
    800044a8:	e8a2                	sd	s0,80(sp)
    800044aa:	e4a6                	sd	s1,72(sp)
    800044ac:	e0ca                	sd	s2,64(sp)
    800044ae:	fc4e                	sd	s3,56(sp)
    800044b0:	f852                	sd	s4,48(sp)
    800044b2:	f456                	sd	s5,40(sp)
    800044b4:	e436                	sd	a3,8(sp)
    configASSERT( pvTxData );
    800044b6:	c9cd                	beqz	a1,80004568 <xStreamBufferSend+0xc4>
    800044b8:	842a                	mv	s0,a0
    configASSERT( pxStreamBuffer );
    800044ba:	c545                	beqz	a0,80004562 <xStreamBufferSend+0xbe>
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800044bc:	03854783          	lbu	a5,56(a0)
    800044c0:	89ae                	mv	s3,a1
    xMaxReportedSpace = pxStreamBuffer->xLength - ( size_t ) 1;
    800044c2:	690c                	ld	a1,16(a0)
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800044c4:	8b85                	andi	a5,a5,1
    800044c6:	8a32                	mv	s4,a2
    xMaxReportedSpace = pxStreamBuffer->xLength - ( size_t ) 1;
    800044c8:	fff58713          	addi	a4,a1,-1 # 1ffffff <_start-0x7e000001>
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800044cc:	c3cd                	beqz	a5,8000456e <xStreamBufferSend+0xca>
        xRequiredSpace += sbBYTES_TO_STORE_MESSAGE_LENGTH;
    800044ce:	00860a93          	addi	s5,a2,8
        configASSERT( xRequiredSpace > xDataLengthBytes );
    800044d2:	15567363          	bgeu	a2,s5,80004618 <xStreamBufferSend+0x174>
        if( xRequiredSpace > xMaxReportedSpace )
    800044d6:	09577f63          	bgeu	a4,s5,80004574 <xStreamBufferSend+0xd0>
            xTicksToWait = ( TickType_t ) 0;
    800044da:	e402                	sd	zero,8(sp)
        xOriginalTail = pxStreamBuffer->xTail;
    800044dc:	6018                	ld	a4,0(s0)
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    800044de:	6014                	ld	a3,0(s0)
        xSpace -= pxStreamBuffer->xHead;
    800044e0:	6410                	ld	a2,8(s0)
    } while( xOriginalTail != pxStreamBuffer->xTail );
    800044e2:	601c                	ld	a5,0(s0)
    800044e4:	fef71ce3          	bne	a4,a5,800044dc <xStreamBufferSend+0x38>
    xSpace -= ( size_t ) 1;
    800044e8:	fff68793          	addi	a5,a3,-1
    800044ec:	8f91                	sub	a5,a5,a2
    800044ee:	00f584b3          	add	s1,a1,a5
    if( xSpace >= pxStreamBuffer->xLength )
    800044f2:	00b4e363          	bltu	s1,a1,800044f8 <xStreamBufferSend+0x54>
        xSpace -= pxStreamBuffer->xLength;
    800044f6:	84be                	mv	s1,a5
    xReturn = prvWriteMessageToBuffer( pxStreamBuffer, pvTxData, xDataLengthBytes, xSpace, xRequiredSpace );
    800044f8:	86a6                	mv	a3,s1
    800044fa:	8756                	mv	a4,s5
    800044fc:	8652                	mv	a2,s4
    800044fe:	85ce                	mv	a1,s3
    80004500:	8522                	mv	a0,s0
    80004502:	00000097          	auipc	ra,0x0
    80004506:	bd6080e7          	jalr	-1066(ra) # 800040d8 <prvWriteMessageToBuffer>
    8000450a:	84aa                	mv	s1,a0
    if( xReturn > ( size_t ) 0 )
    8000450c:	c129                	beqz	a0,8000454e <xStreamBufferSend+0xaa>
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    8000450e:	641c                	ld	a5,8(s0)
    80004510:	6818                	ld	a4,16(s0)
    xCount -= pxStreamBuffer->xTail;
    80004512:	6014                	ld	a3,0(s0)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004514:	97ba                	add	a5,a5,a4
    xCount -= pxStreamBuffer->xTail;
    80004516:	8f95                	sub	a5,a5,a3
    if( xCount >= pxStreamBuffer->xLength )
    80004518:	00e7e363          	bltu	a5,a4,8000451e <xStreamBufferSend+0x7a>
        xCount -= pxStreamBuffer->xLength;
    8000451c:	8f99                	sub	a5,a5,a4
        if( prvBytesInBuffer( pxStreamBuffer ) >= pxStreamBuffer->xTriggerLevelBytes )
    8000451e:	6c18                	ld	a4,24(s0)
    80004520:	02e7e763          	bltu	a5,a4,8000454e <xStreamBufferSend+0xaa>
            prvSEND_COMPLETED( pxStreamBuffer );
    80004524:	ffffd097          	auipc	ra,0xffffd
    80004528:	fe4080e7          	jalr	-28(ra) # 80001508 <vTaskSuspendAll>
    8000452c:	701c                	ld	a5,32(s0)
    8000452e:	cf81                	beqz	a5,80004546 <xStreamBufferSend+0xa2>
    80004530:	7008                	ld	a0,32(s0)
    80004532:	602c                	ld	a1,64(s0)
    80004534:	4701                	li	a4,0
    80004536:	4681                	li	a3,0
    80004538:	4601                	li	a2,0
    8000453a:	ffffe097          	auipc	ra,0xffffe
    8000453e:	bc2080e7          	jalr	-1086(ra) # 800020fc <xTaskGenericNotify>
    80004542:	02043023          	sd	zero,32(s0)
    80004546:	ffffd097          	auipc	ra,0xffffd
    8000454a:	fd2080e7          	jalr	-46(ra) # 80001518 <xTaskResumeAll>
}
    8000454e:	60e6                	ld	ra,88(sp)
    80004550:	6446                	ld	s0,80(sp)
    80004552:	6906                	ld	s2,64(sp)
    80004554:	79e2                	ld	s3,56(sp)
    80004556:	7a42                	ld	s4,48(sp)
    80004558:	7aa2                	ld	s5,40(sp)
    8000455a:	8526                	mv	a0,s1
    8000455c:	64a6                	ld	s1,72(sp)
    8000455e:	6125                	addi	sp,sp,96
    80004560:	8082                	ret
    configASSERT( pxStreamBuffer );
    80004562:	30047073          	csrci	mstatus,8
    80004566:	a001                	j	80004566 <xStreamBufferSend+0xc2>
    configASSERT( pvTxData );
    80004568:	30047073          	csrci	mstatus,8
    8000456c:	a001                	j	8000456c <xStreamBufferSend+0xc8>
        if( xRequiredSpace > xMaxReportedSpace )
    8000456e:	8ab2                	mv	s5,a2
    80004570:	0ac76063          	bltu	a4,a2,80004610 <xStreamBufferSend+0x16c>
    if( xTicksToWait != ( TickType_t ) 0 )
    80004574:	67a2                	ld	a5,8(sp)
    80004576:	d3bd                	beqz	a5,800044dc <xStreamBufferSend+0x38>
        vTaskSetTimeOutState( &xTimeOut );
    80004578:	0808                	addi	a0,sp,16
    8000457a:	ffffd097          	auipc	ra,0xffffd
    8000457e:	56c080e7          	jalr	1388(ra) # 80001ae6 <vTaskSetTimeOutState>
    80004582:	00002917          	auipc	s2,0x2
    80004586:	2de90913          	addi	s2,s2,734 # 80006860 <xCriticalNesting>
            taskENTER_CRITICAL();
    8000458a:	30047073          	csrci	mstatus,8
    8000458e:	00093583          	ld	a1,0(s2)
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004592:	6810                	ld	a2,16(s0)
            taskENTER_CRITICAL();
    80004594:	00158793          	addi	a5,a1,1
    80004598:	00f93023          	sd	a5,0(s2)
        xOriginalTail = pxStreamBuffer->xTail;
    8000459c:	6018                	ld	a4,0(s0)
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    8000459e:	6014                	ld	a3,0(s0)
        xSpace -= pxStreamBuffer->xHead;
    800045a0:	6408                	ld	a0,8(s0)
    } while( xOriginalTail != pxStreamBuffer->xTail );
    800045a2:	601c                	ld	a5,0(s0)
    800045a4:	fef71ce3          	bne	a4,a5,8000459c <xStreamBufferSend+0xf8>
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    800045a8:	00d604b3          	add	s1,a2,a3
    800045ac:	14fd                	addi	s1,s1,-1
    xSpace -= ( size_t ) 1;
    800045ae:	8c89                	sub	s1,s1,a0
    if( xSpace >= pxStreamBuffer->xLength )
    800045b0:	00c4e363          	bltu	s1,a2,800045b6 <xStreamBufferSend+0x112>
        xSpace -= pxStreamBuffer->xLength;
    800045b4:	8c91                	sub	s1,s1,a2
                if( xSpace < xRequiredSpace )
    800045b6:	0754f463          	bgeu	s1,s5,8000461e <xStreamBufferSend+0x17a>
                    ( void ) xTaskNotifyStateClearIndexed( NULL, pxStreamBuffer->uxNotificationIndex );
    800045ba:	602c                	ld	a1,64(s0)
    800045bc:	4501                	li	a0,0
    800045be:	ffffe097          	auipc	ra,0xffffe
    800045c2:	f26080e7          	jalr	-218(ra) # 800024e4 <xTaskGenericNotifyStateClear>
                    configASSERT( pxStreamBuffer->xTaskWaitingToSend == NULL );
    800045c6:	741c                	ld	a5,40(s0)
    800045c8:	e3ad                	bnez	a5,8000462a <xStreamBufferSend+0x186>
                    pxStreamBuffer->xTaskWaitingToSend = xTaskGetCurrentTaskHandle();
    800045ca:	ffffd097          	auipc	ra,0xffffd
    800045ce:	600080e7          	jalr	1536(ra) # 80001bca <xTaskGetCurrentTaskHandle>
            taskEXIT_CRITICAL();
    800045d2:	00093783          	ld	a5,0(s2)
                    pxStreamBuffer->xTaskWaitingToSend = xTaskGetCurrentTaskHandle();
    800045d6:	f408                	sd	a0,40(s0)
            taskEXIT_CRITICAL();
    800045d8:	17fd                	addi	a5,a5,-1
    800045da:	00f93023          	sd	a5,0(s2)
    800045de:	e399                	bnez	a5,800045e4 <xStreamBufferSend+0x140>
    800045e0:	30046073          	csrsi	mstatus,8
            ( void ) xTaskNotifyWaitIndexed( pxStreamBuffer->uxNotificationIndex, ( uint32_t ) 0, ( uint32_t ) 0, NULL, xTicksToWait );
    800045e4:	6722                	ld	a4,8(sp)
    800045e6:	6028                	ld	a0,64(s0)
    800045e8:	4581                	li	a1,0
    800045ea:	4681                	li	a3,0
    800045ec:	4601                	li	a2,0
    800045ee:	ffffe097          	auipc	ra,0xffffe
    800045f2:	9ee080e7          	jalr	-1554(ra) # 80001fdc <xTaskGenericNotifyWait>
        } while( xTaskCheckForTimeOut( &xTimeOut, &xTicksToWait ) == pdFALSE );
    800045f6:	002c                	addi	a1,sp,8
            pxStreamBuffer->xTaskWaitingToSend = NULL;
    800045f8:	02043423          	sd	zero,40(s0)
        } while( xTaskCheckForTimeOut( &xTimeOut, &xTicksToWait ) == pdFALSE );
    800045fc:	0808                	addi	a0,sp,16
    800045fe:	ffffd097          	auipc	ra,0xffffd
    80004602:	532080e7          	jalr	1330(ra) # 80001b30 <xTaskCheckForTimeOut>
    80004606:	d151                	beqz	a0,8000458a <xStreamBufferSend+0xe6>
    if( xSpace == ( size_t ) 0 )
    80004608:	ee0498e3          	bnez	s1,800044f8 <xStreamBufferSend+0x54>
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    8000460c:	680c                	ld	a1,16(s0)
    configASSERT( pxStreamBuffer );
    8000460e:	b5f9                	j	800044dc <xStreamBufferSend+0x38>
    if( xTicksToWait != ( TickType_t ) 0 )
    80004610:	67a2                	ld	a5,8(sp)
    80004612:	8aba                	mv	s5,a4
    80004614:	f3b5                	bnez	a5,80004578 <xStreamBufferSend+0xd4>
    80004616:	b5d9                	j	800044dc <xStreamBufferSend+0x38>
        configASSERT( xRequiredSpace > xDataLengthBytes );
    80004618:	30047073          	csrci	mstatus,8
    8000461c:	a001                	j	8000461c <xStreamBufferSend+0x178>
                    taskEXIT_CRITICAL();
    8000461e:	00b93023          	sd	a1,0(s2)
    80004622:	f1fd                	bnez	a1,80004608 <xStreamBufferSend+0x164>
    80004624:	30046073          	csrsi	mstatus,8
    80004628:	b7c5                	j	80004608 <xStreamBufferSend+0x164>
                    configASSERT( pxStreamBuffer->xTaskWaitingToSend == NULL );
    8000462a:	30047073          	csrci	mstatus,8
    8000462e:	a001                	j	8000462e <xStreamBufferSend+0x18a>

0000000080004630 <xStreamBufferSendFromISR>:
    configASSERT( pvTxData );
    80004630:	cdc9                	beqz	a1,800046ca <xStreamBufferSendFromISR+0x9a>
{
    80004632:	1101                	addi	sp,sp,-32
    80004634:	e822                	sd	s0,16(sp)
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e426                	sd	s1,8(sp)
    8000463a:	e04a                	sd	s2,0(sp)
    8000463c:	842a                	mv	s0,a0
    configASSERT( pxStreamBuffer );
    8000463e:	c159                	beqz	a0,800046c4 <xStreamBufferSendFromISR+0x94>
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    80004640:	03854783          	lbu	a5,56(a0)
    80004644:	84b6                	mv	s1,a3
    80004646:	8b85                	andi	a5,a5,1
    80004648:	c7d9                	beqz	a5,800046d6 <xStreamBufferSendFromISR+0xa6>
        xRequiredSpace += sbBYTES_TO_STORE_MESSAGE_LENGTH;
    8000464a:	00860713          	addi	a4,a2,8
        configASSERT( xRequiredSpace > xDataLengthBytes );
    8000464e:	08e67163          	bgeu	a2,a4,800046d0 <xStreamBufferSendFromISR+0xa0>
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004652:	681c                	ld	a5,16(s0)
        xOriginalTail = pxStreamBuffer->xTail;
    80004654:	00043803          	ld	a6,0(s0)
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004658:	00043883          	ld	a7,0(s0)
        xSpace -= pxStreamBuffer->xHead;
    8000465c:	00843303          	ld	t1,8(s0)
    } while( xOriginalTail != pxStreamBuffer->xTail );
    80004660:	6008                	ld	a0,0(s0)
    80004662:	fea819e3          	bne	a6,a0,80004654 <xStreamBufferSendFromISR+0x24>
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004666:	01178533          	add	a0,a5,a7
    8000466a:	157d                	addi	a0,a0,-1
    xSpace -= ( size_t ) 1;
    8000466c:	406506b3          	sub	a3,a0,t1
    if( xSpace >= pxStreamBuffer->xLength )
    80004670:	00f6e363          	bltu	a3,a5,80004676 <xStreamBufferSendFromISR+0x46>
        xSpace -= pxStreamBuffer->xLength;
    80004674:	8e9d                	sub	a3,a3,a5
    xReturn = prvWriteMessageToBuffer( pxStreamBuffer, pvTxData, xDataLengthBytes, xSpace, xRequiredSpace );
    80004676:	8522                	mv	a0,s0
    80004678:	00000097          	auipc	ra,0x0
    8000467c:	a60080e7          	jalr	-1440(ra) # 800040d8 <prvWriteMessageToBuffer>
    80004680:	892a                	mv	s2,a0
    if( xReturn > ( size_t ) 0 )
    80004682:	c915                	beqz	a0,800046b6 <xStreamBufferSendFromISR+0x86>
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004684:	641c                	ld	a5,8(s0)
    80004686:	6818                	ld	a4,16(s0)
    xCount -= pxStreamBuffer->xTail;
    80004688:	6014                	ld	a3,0(s0)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    8000468a:	97ba                	add	a5,a5,a4
    xCount -= pxStreamBuffer->xTail;
    8000468c:	8f95                	sub	a5,a5,a3
    if( xCount >= pxStreamBuffer->xLength )
    8000468e:	00e7e363          	bltu	a5,a4,80004694 <xStreamBufferSendFromISR+0x64>
        xCount -= pxStreamBuffer->xLength;
    80004692:	8f99                	sub	a5,a5,a4
        if( prvBytesInBuffer( pxStreamBuffer ) >= pxStreamBuffer->xTriggerLevelBytes )
    80004694:	6c18                	ld	a4,24(s0)
    80004696:	02e7e063          	bltu	a5,a4,800046b6 <xStreamBufferSendFromISR+0x86>
            prvSEND_COMPLETE_FROM_ISR( pxStreamBuffer, pxHigherPriorityTaskWoken );
    8000469a:	701c                	ld	a5,32(s0)
    8000469c:	cf89                	beqz	a5,800046b6 <xStreamBufferSendFromISR+0x86>
    8000469e:	7008                	ld	a0,32(s0)
    800046a0:	602c                	ld	a1,64(s0)
    800046a2:	87a6                	mv	a5,s1
    800046a4:	4701                	li	a4,0
    800046a6:	4681                	li	a3,0
    800046a8:	4601                	li	a2,0
    800046aa:	ffffe097          	auipc	ra,0xffffe
    800046ae:	b9e080e7          	jalr	-1122(ra) # 80002248 <xTaskGenericNotifyFromISR>
    800046b2:	02043023          	sd	zero,32(s0)
}
    800046b6:	60e2                	ld	ra,24(sp)
    800046b8:	6442                	ld	s0,16(sp)
    800046ba:	64a2                	ld	s1,8(sp)
    800046bc:	854a                	mv	a0,s2
    800046be:	6902                	ld	s2,0(sp)
    800046c0:	6105                	addi	sp,sp,32
    800046c2:	8082                	ret
    configASSERT( pxStreamBuffer );
    800046c4:	30047073          	csrci	mstatus,8
    800046c8:	a001                	j	800046c8 <xStreamBufferSendFromISR+0x98>
    configASSERT( pvTxData );
    800046ca:	30047073          	csrci	mstatus,8
    800046ce:	a001                	j	800046ce <xStreamBufferSendFromISR+0x9e>
        configASSERT( xRequiredSpace > xDataLengthBytes );
    800046d0:	30047073          	csrci	mstatus,8
    800046d4:	a001                	j	800046d4 <xStreamBufferSendFromISR+0xa4>
    800046d6:	8732                	mv	a4,a2
    800046d8:	bfad                	j	80004652 <xStreamBufferSendFromISR+0x22>

00000000800046da <xStreamBufferReceive>:
    configASSERT( pvRxData );
    800046da:	c5dd                	beqz	a1,80004788 <xStreamBufferReceive+0xae>
{
    800046dc:	715d                	addi	sp,sp,-80
    800046de:	e0a2                	sd	s0,64(sp)
    800046e0:	e486                	sd	ra,72(sp)
    800046e2:	fc26                	sd	s1,56(sp)
    800046e4:	f84a                	sd	s2,48(sp)
    800046e6:	f44e                	sd	s3,40(sp)
    800046e8:	f052                	sd	s4,32(sp)
    800046ea:	ec56                	sd	s5,24(sp)
    800046ec:	842a                	mv	s0,a0
    configASSERT( pxStreamBuffer );
    800046ee:	c951                	beqz	a0,80004782 <xStreamBufferReceive+0xa8>
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800046f0:	03854783          	lbu	a5,56(a0)
    800046f4:	892e                	mv	s2,a1
    800046f6:	89b2                	mv	s3,a2
    800046f8:	0017f713          	andi	a4,a5,1
        xBytesToStoreMessageLength = sbBYTES_TO_STORE_MESSAGE_LENGTH;
    800046fc:	4a21                	li	s4,8
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800046fe:	e701                	bnez	a4,80004706 <xStreamBufferReceive+0x2c>
    else if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_BATCHING_BUFFER ) != ( uint8_t ) 0 )
    80004700:	8b91                	andi	a5,a5,4
        xBytesToStoreMessageLength = 0;
    80004702:	4a01                	li	s4,0
    else if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_BATCHING_BUFFER ) != ( uint8_t ) 0 )
    80004704:	e7c9                	bnez	a5,8000478e <xStreamBufferReceive+0xb4>
    if( xTicksToWait != ( TickType_t ) 0 )
    80004706:	caa9                	beqz	a3,80004758 <xStreamBufferReceive+0x7e>
        taskENTER_CRITICAL();
    80004708:	30047073          	csrci	mstatus,8
    8000470c:	00002a97          	auipc	s5,0x2
    80004710:	154a8a93          	addi	s5,s5,340 # 80006860 <xCriticalNesting>
    80004714:	000ab703          	ld	a4,0(s5)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004718:	6404                	ld	s1,8(s0)
    8000471a:	681c                	ld	a5,16(s0)
    xCount -= pxStreamBuffer->xTail;
    8000471c:	6010                	ld	a2,0(s0)
        taskENTER_CRITICAL();
    8000471e:	00170593          	addi	a1,a4,1 # 2000001 <_start-0x7dffffff>
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004722:	94be                	add	s1,s1,a5
        taskENTER_CRITICAL();
    80004724:	00bab023          	sd	a1,0(s5)
    xCount -= pxStreamBuffer->xTail;
    80004728:	8c91                	sub	s1,s1,a2
    if( xCount >= pxStreamBuffer->xLength )
    8000472a:	00f4e363          	bltu	s1,a5,80004730 <xStreamBufferReceive+0x56>
        xCount -= pxStreamBuffer->xLength;
    8000472e:	8c9d                	sub	s1,s1,a5
            if( xBytesAvailable <= xBytesToStoreMessageLength )
    80004730:	069a7263          	bgeu	s4,s1,80004794 <xStreamBufferReceive+0xba>
        taskEXIT_CRITICAL();
    80004734:	00eab023          	sd	a4,0(s5)
    80004738:	eb3d                	bnez	a4,800047ae <xStreamBufferReceive+0xd4>
    8000473a:	30046073          	csrsi	mstatus,8
        if( xBytesAvailable <= xBytesToStoreMessageLength )
    8000473e:	069a6863          	bltu	s4,s1,800047ae <xStreamBufferReceive+0xd4>
            ( void ) xTaskNotifyWaitIndexed( pxStreamBuffer->uxNotificationIndex, ( uint32_t ) 0, ( uint32_t ) 0, NULL, xTicksToWait );
    80004742:	6028                	ld	a0,64(s0)
    80004744:	8736                	mv	a4,a3
    80004746:	4601                	li	a2,0
    80004748:	4681                	li	a3,0
    8000474a:	4581                	li	a1,0
    8000474c:	ffffe097          	auipc	ra,0xffffe
    80004750:	890080e7          	jalr	-1904(ra) # 80001fdc <xTaskGenericNotifyWait>
            pxStreamBuffer->xTaskWaitingToReceive = NULL;
    80004754:	02043023          	sd	zero,32(s0)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004758:	6404                	ld	s1,8(s0)
    8000475a:	681c                	ld	a5,16(s0)
    xCount -= pxStreamBuffer->xTail;
    8000475c:	6018                	ld	a4,0(s0)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    8000475e:	94be                	add	s1,s1,a5
    xCount -= pxStreamBuffer->xTail;
    80004760:	8c99                	sub	s1,s1,a4
    if( xCount >= pxStreamBuffer->xLength )
    80004762:	00f4e363          	bltu	s1,a5,80004768 <xStreamBufferReceive+0x8e>
        xCount -= pxStreamBuffer->xLength;
    80004766:	8c9d                	sub	s1,s1,a5
    if( xBytesAvailable > xBytesToStoreMessageLength )
    80004768:	049a6363          	bltu	s4,s1,800047ae <xStreamBufferReceive+0xd4>
    size_t xReceivedLength = 0, xBytesAvailable, xBytesToStoreMessageLength;
    8000476c:	4481                	li	s1,0
}
    8000476e:	60a6                	ld	ra,72(sp)
    80004770:	6406                	ld	s0,64(sp)
    80004772:	7942                	ld	s2,48(sp)
    80004774:	79a2                	ld	s3,40(sp)
    80004776:	7a02                	ld	s4,32(sp)
    80004778:	6ae2                	ld	s5,24(sp)
    8000477a:	8526                	mv	a0,s1
    8000477c:	74e2                	ld	s1,56(sp)
    8000477e:	6161                	addi	sp,sp,80
    80004780:	8082                	ret
    configASSERT( pxStreamBuffer );
    80004782:	30047073          	csrci	mstatus,8
    80004786:	a001                	j	80004786 <xStreamBufferReceive+0xac>
    configASSERT( pvRxData );
    80004788:	30047073          	csrci	mstatus,8
    8000478c:	a001                	j	8000478c <xStreamBufferReceive+0xb2>
        xBytesToStoreMessageLength = pxStreamBuffer->xTriggerLevelBytes;
    8000478e:	01853a03          	ld	s4,24(a0)
    80004792:	bf95                	j	80004706 <xStreamBufferReceive+0x2c>
                ( void ) xTaskNotifyStateClearIndexed( NULL, pxStreamBuffer->uxNotificationIndex );
    80004794:	602c                	ld	a1,64(s0)
    80004796:	4501                	li	a0,0
    80004798:	e436                	sd	a3,8(sp)
    8000479a:	ffffe097          	auipc	ra,0xffffe
    8000479e:	d4a080e7          	jalr	-694(ra) # 800024e4 <xTaskGenericNotifyStateClear>
                configASSERT( pxStreamBuffer->xTaskWaitingToReceive == NULL );
    800047a2:	701c                	ld	a5,32(s0)
    800047a4:	66a2                	ld	a3,8(sp)
    800047a6:	c7a1                	beqz	a5,800047ee <xStreamBufferReceive+0x114>
    800047a8:	30047073          	csrci	mstatus,8
    800047ac:	a001                	j	800047ac <xStreamBufferReceive+0xd2>
        xReceivedLength = prvReadMessageFromBuffer( pxStreamBuffer, pvRxData, xBufferLengthBytes, xBytesAvailable );
    800047ae:	86a6                	mv	a3,s1
    800047b0:	864e                	mv	a2,s3
    800047b2:	85ca                	mv	a1,s2
    800047b4:	8522                	mv	a0,s0
    800047b6:	00000097          	auipc	ra,0x0
    800047ba:	a0e080e7          	jalr	-1522(ra) # 800041c4 <prvReadMessageFromBuffer>
    800047be:	84aa                	mv	s1,a0
        if( xReceivedLength != ( size_t ) 0 )
    800047c0:	d555                	beqz	a0,8000476c <xStreamBufferReceive+0x92>
            prvRECEIVE_COMPLETED( xStreamBuffer );
    800047c2:	ffffd097          	auipc	ra,0xffffd
    800047c6:	d46080e7          	jalr	-698(ra) # 80001508 <vTaskSuspendAll>
    800047ca:	741c                	ld	a5,40(s0)
    800047cc:	cf81                	beqz	a5,800047e4 <xStreamBufferReceive+0x10a>
    800047ce:	7408                	ld	a0,40(s0)
    800047d0:	602c                	ld	a1,64(s0)
    800047d2:	4701                	li	a4,0
    800047d4:	4681                	li	a3,0
    800047d6:	4601                	li	a2,0
    800047d8:	ffffe097          	auipc	ra,0xffffe
    800047dc:	924080e7          	jalr	-1756(ra) # 800020fc <xTaskGenericNotify>
    800047e0:	02043423          	sd	zero,40(s0)
    800047e4:	ffffd097          	auipc	ra,0xffffd
    800047e8:	d34080e7          	jalr	-716(ra) # 80001518 <xTaskResumeAll>
    return xReceivedLength;
    800047ec:	b749                	j	8000476e <xStreamBufferReceive+0x94>
    800047ee:	e436                	sd	a3,8(sp)
                pxStreamBuffer->xTaskWaitingToReceive = xTaskGetCurrentTaskHandle();
    800047f0:	ffffd097          	auipc	ra,0xffffd
    800047f4:	3da080e7          	jalr	986(ra) # 80001bca <xTaskGetCurrentTaskHandle>
        taskEXIT_CRITICAL();
    800047f8:	000ab783          	ld	a5,0(s5)
                pxStreamBuffer->xTaskWaitingToReceive = xTaskGetCurrentTaskHandle();
    800047fc:	f008                	sd	a0,32(s0)
        taskEXIT_CRITICAL();
    800047fe:	66a2                	ld	a3,8(sp)
    80004800:	17fd                	addi	a5,a5,-1
    80004802:	00fab023          	sd	a5,0(s5)
    80004806:	db95                	beqz	a5,8000473a <xStreamBufferReceive+0x60>
    80004808:	bf2d                	j	80004742 <xStreamBufferReceive+0x68>

000000008000480a <xStreamBufferNextMessageLengthBytes>:
    configASSERT( pxStreamBuffer );
    8000480a:	c51d                	beqz	a0,80004838 <xStreamBufferNextMessageLengthBytes+0x2e>
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    8000480c:	03854703          	lbu	a4,56(a0)
    80004810:	87aa                	mv	a5,a0
    80004812:	8b05                	andi	a4,a4,1
    80004814:	cf19                	beqz	a4,80004832 <xStreamBufferNextMessageLengthBytes+0x28>
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004816:	6508                	ld	a0,8(a0)
    80004818:	6b98                	ld	a4,16(a5)
    xCount -= pxStreamBuffer->xTail;
    8000481a:	6394                	ld	a3,0(a5)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    8000481c:	953a                	add	a0,a0,a4
    xCount -= pxStreamBuffer->xTail;
    8000481e:	8d15                	sub	a0,a0,a3
    if( xCount >= pxStreamBuffer->xLength )
    80004820:	00e57f63          	bgeu	a0,a4,8000483e <xStreamBufferNextMessageLengthBytes+0x34>
        if( xBytesAvailable > sbBYTES_TO_STORE_MESSAGE_LENGTH )
    80004824:	4721                	li	a4,8
    80004826:	02a76063          	bltu	a4,a0,80004846 <xStreamBufferNextMessageLengthBytes+0x3c>
            configASSERT( xBytesAvailable == 0 );
    8000482a:	c511                	beqz	a0,80004836 <xStreamBufferNextMessageLengthBytes+0x2c>
    8000482c:	30047073          	csrci	mstatus,8
    80004830:	a001                	j	80004830 <xStreamBufferNextMessageLengthBytes+0x26>
        xReturn = 0;
    80004832:	4501                	li	a0,0
    return xReturn;
    80004834:	8082                	ret
}
    80004836:	8082                	ret
    configASSERT( pxStreamBuffer );
    80004838:	30047073          	csrci	mstatus,8
    8000483c:	a001                	j	8000483c <xStreamBufferNextMessageLengthBytes+0x32>
        xCount -= pxStreamBuffer->xLength;
    8000483e:	8d19                	sub	a0,a0,a4
        if( xBytesAvailable > sbBYTES_TO_STORE_MESSAGE_LENGTH )
    80004840:	4721                	li	a4,8
    80004842:	fea774e3          	bgeu	a4,a0,8000482a <xStreamBufferNextMessageLengthBytes+0x20>
            ( void ) prvReadBytesFromBuffer( pxStreamBuffer, ( uint8_t * ) &xTempReturn, sbBYTES_TO_STORE_MESSAGE_LENGTH, pxStreamBuffer->xTail );
    80004846:	6394                	ld	a3,0(a5)
{
    80004848:	1101                	addi	sp,sp,-32
    configASSERT( xCount != ( size_t ) 0 );
    8000484a:	002c                	addi	a1,sp,8
    8000484c:	4621                	li	a2,8
    8000484e:	853e                	mv	a0,a5
{
    80004850:	ec06                	sd	ra,24(sp)
    80004852:	00000097          	auipc	ra,0x0
    80004856:	8fe080e7          	jalr	-1794(ra) # 80004150 <prvReadBytesFromBuffer.part.0>
}
    8000485a:	60e2                	ld	ra,24(sp)
            xReturn = ( size_t ) xTempReturn;
    8000485c:	6522                	ld	a0,8(sp)
}
    8000485e:	6105                	addi	sp,sp,32
    80004860:	8082                	ret

0000000080004862 <xStreamBufferReceiveFromISR>:
    configASSERT( pvRxData );
    80004862:	c1b9                	beqz	a1,800048a8 <xStreamBufferReceiveFromISR+0x46>
{
    80004864:	1101                	addi	sp,sp,-32
    80004866:	e822                	sd	s0,16(sp)
    80004868:	ec06                	sd	ra,24(sp)
    8000486a:	e426                	sd	s1,8(sp)
    8000486c:	e04a                	sd	s2,0(sp)
    8000486e:	842a                	mv	s0,a0
    configASSERT( pxStreamBuffer );
    80004870:	c90d                	beqz	a0,800048a2 <xStreamBufferReceiveFromISR+0x40>
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    80004872:	6518                	ld	a4,8(a0)
    80004874:	6908                	ld	a0,16(a0)
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    80004876:	03844783          	lbu	a5,56(s0)
    8000487a:	84b6                	mv	s1,a3
    xCount -= pxStreamBuffer->xTail;
    8000487c:	6014                	ld	a3,0(s0)
    xCount = pxStreamBuffer->xLength + pxStreamBuffer->xHead;
    8000487e:	972a                	add	a4,a4,a0
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    80004880:	8b85                	andi	a5,a5,1
    xCount -= pxStreamBuffer->xTail;
    80004882:	40d706b3          	sub	a3,a4,a3
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    80004886:	078e                	slli	a5,a5,0x3
    if( xCount >= pxStreamBuffer->xLength )
    80004888:	00a6e363          	bltu	a3,a0,8000488e <xStreamBufferReceiveFromISR+0x2c>
        xCount -= pxStreamBuffer->xLength;
    8000488c:	8e89                	sub	a3,a3,a0
    if( xBytesAvailable > xBytesToStoreMessageLength )
    8000488e:	02d7e063          	bltu	a5,a3,800048ae <xStreamBufferReceiveFromISR+0x4c>
    size_t xReceivedLength = 0, xBytesAvailable, xBytesToStoreMessageLength;
    80004892:	4901                	li	s2,0
}
    80004894:	60e2                	ld	ra,24(sp)
    80004896:	6442                	ld	s0,16(sp)
    80004898:	64a2                	ld	s1,8(sp)
    8000489a:	854a                	mv	a0,s2
    8000489c:	6902                	ld	s2,0(sp)
    8000489e:	6105                	addi	sp,sp,32
    800048a0:	8082                	ret
    configASSERT( pxStreamBuffer );
    800048a2:	30047073          	csrci	mstatus,8
    800048a6:	a001                	j	800048a6 <xStreamBufferReceiveFromISR+0x44>
    configASSERT( pvRxData );
    800048a8:	30047073          	csrci	mstatus,8
    800048ac:	a001                	j	800048ac <xStreamBufferReceiveFromISR+0x4a>
        xReceivedLength = prvReadMessageFromBuffer( pxStreamBuffer, pvRxData, xBufferLengthBytes, xBytesAvailable );
    800048ae:	8522                	mv	a0,s0
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	914080e7          	jalr	-1772(ra) # 800041c4 <prvReadMessageFromBuffer>
    800048b8:	892a                	mv	s2,a0
        if( xReceivedLength != ( size_t ) 0 )
    800048ba:	dd61                	beqz	a0,80004892 <xStreamBufferReceiveFromISR+0x30>
            prvRECEIVE_COMPLETED_FROM_ISR( pxStreamBuffer, pxHigherPriorityTaskWoken );
    800048bc:	741c                	ld	a5,40(s0)
    800048be:	dbf9                	beqz	a5,80004894 <xStreamBufferReceiveFromISR+0x32>
    800048c0:	7408                	ld	a0,40(s0)
    800048c2:	602c                	ld	a1,64(s0)
    800048c4:	87a6                	mv	a5,s1
    800048c6:	4701                	li	a4,0
    800048c8:	4681                	li	a3,0
    800048ca:	4601                	li	a2,0
    800048cc:	ffffe097          	auipc	ra,0xffffe
    800048d0:	97c080e7          	jalr	-1668(ra) # 80002248 <xTaskGenericNotifyFromISR>
    800048d4:	02043423          	sd	zero,40(s0)
    return xReceivedLength;
    800048d8:	bf75                	j	80004894 <xStreamBufferReceiveFromISR+0x32>

00000000800048da <xStreamBufferIsEmpty>:
    configASSERT( pxStreamBuffer );
    800048da:	c519                	beqz	a0,800048e8 <xStreamBufferIsEmpty+0xe>
    xTail = pxStreamBuffer->xTail;
    800048dc:	611c                	ld	a5,0(a0)
    if( pxStreamBuffer->xHead == xTail )
    800048de:	6508                	ld	a0,8(a0)
    800048e0:	8d1d                	sub	a0,a0,a5
}
    800048e2:	00153513          	seqz	a0,a0
    800048e6:	8082                	ret
    configASSERT( pxStreamBuffer );
    800048e8:	30047073          	csrci	mstatus,8
    800048ec:	a001                	j	800048ec <xStreamBufferIsEmpty+0x12>

00000000800048ee <xStreamBufferIsFull>:
    configASSERT( pxStreamBuffer );
    800048ee:	c91d                	beqz	a0,80004924 <xStreamBufferIsFull+0x36>
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800048f0:	03854583          	lbu	a1,56(a0)
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    800048f4:	01053803          	ld	a6,16(a0)
    if( ( pxStreamBuffer->ucFlags & sbFLAGS_IS_MESSAGE_BUFFER ) != ( uint8_t ) 0 )
    800048f8:	8985                	andi	a1,a1,1
    800048fa:	058e                	slli	a1,a1,0x3
        xOriginalTail = pxStreamBuffer->xTail;
    800048fc:	6118                	ld	a4,0(a0)
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    800048fe:	6114                	ld	a3,0(a0)
        xSpace -= pxStreamBuffer->xHead;
    80004900:	6510                	ld	a2,8(a0)
    } while( xOriginalTail != pxStreamBuffer->xTail );
    80004902:	611c                	ld	a5,0(a0)
    80004904:	fef71ce3          	bne	a4,a5,800048fc <xStreamBufferIsFull+0xe>
        xSpace = pxStreamBuffer->xLength + pxStreamBuffer->xTail;
    80004908:	00d807b3          	add	a5,a6,a3
    8000490c:	17fd                	addi	a5,a5,-1
    xSpace -= ( size_t ) 1;
    8000490e:	8f91                	sub	a5,a5,a2
    if( xSpace >= pxStreamBuffer->xLength )
    80004910:	0107e463          	bltu	a5,a6,80004918 <xStreamBufferIsFull+0x2a>
        xSpace -= pxStreamBuffer->xLength;
    80004914:	410787b3          	sub	a5,a5,a6
    if( xStreamBufferSpacesAvailable( xStreamBuffer ) <= xBytesToStoreMessageLength )
    80004918:	00f5b533          	sltu	a0,a1,a5
    8000491c:	00154513          	xori	a0,a0,1
}
    80004920:	8905                	andi	a0,a0,1
    80004922:	8082                	ret
    configASSERT( pxStreamBuffer );
    80004924:	30047073          	csrci	mstatus,8
    80004928:	a001                	j	80004928 <xStreamBufferIsFull+0x3a>

000000008000492a <xStreamBufferSendCompletedFromISR>:
    configASSERT( pxStreamBuffer );
    8000492a:	c90d                	beqz	a0,8000495c <xStreamBufferSendCompletedFromISR+0x32>
        if( ( pxStreamBuffer )->xTaskWaitingToReceive != NULL )
    8000492c:	7118                	ld	a4,32(a0)
{
    8000492e:	1141                	addi	sp,sp,-16
    80004930:	e022                	sd	s0,0(sp)
    80004932:	e406                	sd	ra,8(sp)
    80004934:	842a                	mv	s0,a0
            xReturn = pdFALSE;
    80004936:	4501                	li	a0,0
        if( ( pxStreamBuffer )->xTaskWaitingToReceive != NULL )
    80004938:	cf11                	beqz	a4,80004954 <xStreamBufferSendCompletedFromISR+0x2a>
            ( void ) xTaskNotifyIndexedFromISR( ( pxStreamBuffer )->xTaskWaitingToReceive,
    8000493a:	87ae                	mv	a5,a1
    8000493c:	7008                	ld	a0,32(s0)
    8000493e:	602c                	ld	a1,64(s0)
    80004940:	4701                	li	a4,0
    80004942:	4681                	li	a3,0
    80004944:	4601                	li	a2,0
    80004946:	ffffe097          	auipc	ra,0xffffe
    8000494a:	902080e7          	jalr	-1790(ra) # 80002248 <xTaskGenericNotifyFromISR>
            xReturn = pdTRUE;
    8000494e:	4505                	li	a0,1
            ( pxStreamBuffer )->xTaskWaitingToReceive = NULL;
    80004950:	02043023          	sd	zero,32(s0)
}
    80004954:	60a2                	ld	ra,8(sp)
    80004956:	6402                	ld	s0,0(sp)
    80004958:	0141                	addi	sp,sp,16
    8000495a:	8082                	ret
    configASSERT( pxStreamBuffer );
    8000495c:	30047073          	csrci	mstatus,8
    80004960:	a001                	j	80004960 <xStreamBufferSendCompletedFromISR+0x36>

0000000080004962 <xStreamBufferReceiveCompletedFromISR>:
    configASSERT( pxStreamBuffer );
    80004962:	c90d                	beqz	a0,80004994 <xStreamBufferReceiveCompletedFromISR+0x32>
        if( ( pxStreamBuffer )->xTaskWaitingToSend != NULL )
    80004964:	7518                	ld	a4,40(a0)
{
    80004966:	1141                	addi	sp,sp,-16
    80004968:	e022                	sd	s0,0(sp)
    8000496a:	e406                	sd	ra,8(sp)
    8000496c:	842a                	mv	s0,a0
            xReturn = pdFALSE;
    8000496e:	4501                	li	a0,0
        if( ( pxStreamBuffer )->xTaskWaitingToSend != NULL )
    80004970:	cf11                	beqz	a4,8000498c <xStreamBufferReceiveCompletedFromISR+0x2a>
            ( void ) xTaskNotifyIndexedFromISR( ( pxStreamBuffer )->xTaskWaitingToSend,
    80004972:	87ae                	mv	a5,a1
    80004974:	7408                	ld	a0,40(s0)
    80004976:	602c                	ld	a1,64(s0)
    80004978:	4701                	li	a4,0
    8000497a:	4681                	li	a3,0
    8000497c:	4601                	li	a2,0
    8000497e:	ffffe097          	auipc	ra,0xffffe
    80004982:	8ca080e7          	jalr	-1846(ra) # 80002248 <xTaskGenericNotifyFromISR>
            xReturn = pdTRUE;
    80004986:	4505                	li	a0,1
            ( pxStreamBuffer )->xTaskWaitingToSend = NULL;
    80004988:	02043423          	sd	zero,40(s0)
}
    8000498c:	60a2                	ld	ra,8(sp)
    8000498e:	6402                	ld	s0,0(sp)
    80004990:	0141                	addi	sp,sp,16
    80004992:	8082                	ret
    configASSERT( pxStreamBuffer );
    80004994:	30047073          	csrci	mstatus,8
    80004998:	a001                	j	80004998 <xStreamBufferReceiveCompletedFromISR+0x36>

000000008000499a <uxStreamBufferGetStreamBufferNotificationIndex>:
{
    StreamBuffer_t * const pxStreamBuffer = xStreamBuffer;

    traceENTER_uxStreamBufferGetStreamBufferNotificationIndex( xStreamBuffer );

    configASSERT( pxStreamBuffer );
    8000499a:	c119                	beqz	a0,800049a0 <uxStreamBufferGetStreamBufferNotificationIndex+0x6>

    traceRETURN_uxStreamBufferGetStreamBufferNotificationIndex( pxStreamBuffer->uxNotificationIndex );

    return pxStreamBuffer->uxNotificationIndex;
}
    8000499c:	6128                	ld	a0,64(a0)
    8000499e:	8082                	ret
    configASSERT( pxStreamBuffer );
    800049a0:	30047073          	csrci	mstatus,8
    800049a4:	a001                	j	800049a4 <uxStreamBufferGetStreamBufferNotificationIndex+0xa>

00000000800049a6 <vStreamBufferSetStreamBufferNotificationIndex>:
    StreamBuffer_t * const pxStreamBuffer = xStreamBuffer;

    traceENTER_vStreamBufferSetStreamBufferNotificationIndex( xStreamBuffer, uxNotificationIndex );

    /* There should be no task waiting otherwise we'd never resume them. */
    configASSERT( ( pxStreamBuffer != NULL ) && ( pxStreamBuffer->xTaskWaitingToReceive == NULL ) );
    800049a6:	c119                	beqz	a0,800049ac <vStreamBufferSetStreamBufferNotificationIndex+0x6>
    800049a8:	711c                	ld	a5,32(a0)
    800049aa:	c781                	beqz	a5,800049b2 <vStreamBufferSetStreamBufferNotificationIndex+0xc>
    800049ac:	30047073          	csrci	mstatus,8
    800049b0:	a001                	j	800049b0 <vStreamBufferSetStreamBufferNotificationIndex+0xa>
    configASSERT( ( pxStreamBuffer != NULL ) && ( pxStreamBuffer->xTaskWaitingToSend == NULL ) );
    800049b2:	751c                	ld	a5,40(a0)
    800049b4:	c781                	beqz	a5,800049bc <vStreamBufferSetStreamBufferNotificationIndex+0x16>
    800049b6:	30047073          	csrci	mstatus,8
    800049ba:	a001                	j	800049ba <vStreamBufferSetStreamBufferNotificationIndex+0x14>

    /* Check that the task notification index is valid. */
    configASSERT( uxNotificationIndex < configTASK_NOTIFICATION_ARRAY_ENTRIES );
    800049bc:	c581                	beqz	a1,800049c4 <vStreamBufferSetStreamBufferNotificationIndex+0x1e>
    800049be:	30047073          	csrci	mstatus,8
    800049c2:	a001                	j	800049c2 <vStreamBufferSetStreamBufferNotificationIndex+0x1c>

    pxStreamBuffer->uxNotificationIndex = uxNotificationIndex;
    800049c4:	04053023          	sd	zero,64(a0)

    traceRETURN_vStreamBufferSetStreamBufferNotificationIndex();
}
    800049c8:	8082                	ret

00000000800049ca <pvPortMalloc>:
PRIVILEGED_DATA static size_t xNumberOfSuccessfulFrees = ( size_t ) 0U;

/*-----------------------------------------------------------*/

void * pvPortMalloc( size_t xWantedSize )
{
    800049ca:	1101                	addi	sp,sp,-32
    800049cc:	ec06                	sd	ra,24(sp)
    800049ce:	e822                	sd	s0,16(sp)
    800049d0:	e426                	sd	s1,8(sp)
    BlockLink_t * pxNewBlockLink;
    void * pvReturn = NULL;
    size_t xAdditionalRequiredSize;
    size_t xAllocatedBlockSize = 0;

    if( xWantedSize > 0 )
    800049d2:	fff50713          	addi	a4,a0,-1
    800049d6:	57b9                	li	a5,-18
    800049d8:	06e7e863          	bltu	a5,a4,80004a48 <pvPortMalloc+0x7e>
        {
            xWantedSize += xHeapStructSize;

            /* Ensure that blocks are always aligned to the required number
             * of bytes. */
            if( ( xWantedSize & portBYTE_ALIGNMENT_MASK ) != 0x00 )
    800049dc:	00f57793          	andi	a5,a0,15
            xWantedSize += xHeapStructSize;
    800049e0:	01050413          	addi	s0,a0,16
            if( ( xWantedSize & portBYTE_ALIGNMENT_MASK ) != 0x00 )
    800049e4:	cb89                	beqz	a5,800049f6 <pvPortMalloc+0x2c>
            {
                /* Byte alignment required. */
                xAdditionalRequiredSize = portBYTE_ALIGNMENT - ( xWantedSize & portBYTE_ALIGNMENT_MASK );

                if( heapADD_WILL_OVERFLOW( xWantedSize, xAdditionalRequiredSize ) == 0 )
    800049e6:	fef78713          	addi	a4,a5,-17
    800049ea:	04876f63          	bltu	a4,s0,80004a48 <pvPortMalloc+0x7e>
                {
                    xWantedSize += xAdditionalRequiredSize;
    800049ee:	02050513          	addi	a0,a0,32
    800049f2:	40f50433          	sub	s0,a0,a5
    else
    {
        mtCOVERAGE_TEST_MARKER();
    }

    vTaskSuspendAll();
    800049f6:	ffffd097          	auipc	ra,0xffffd
    800049fa:	b12080e7          	jalr	-1262(ra) # 80001508 <vTaskSuspendAll>
    {
        /* If this is the first call to malloc then the heap will require
         * initialisation to setup the list of free blocks. */
        if( pxEnd == NULL )
    800049fe:	00013597          	auipc	a1,0x13
    80004a02:	1a258593          	addi	a1,a1,418 # 80017ba0 <pxEnd>
    80004a06:	619c                	ld	a5,0(a1)
         * top bit is set.  The top bit of the block size member of the BlockLink_t
         * structure is used to determine who owns the block - the application or
         * the kernel, so it must be free. */
        if( heapBLOCK_SIZE_IS_VALID( xWantedSize ) != 0 )
        {
            if( ( xWantedSize > 0 ) && ( xWantedSize <= xFreeBytesRemaining ) )
    80004a08:	8522                	mv	a0,s0
        if( pxEnd == NULL )
    80004a0a:	c3cd                	beqz	a5,80004aac <pvPortMalloc+0xe2>
            if( ( xWantedSize > 0 ) && ( xWantedSize <= xFreeBytesRemaining ) )
    80004a0c:	04a05863          	blez	a0,80004a5c <pvPortMalloc+0x92>
    80004a10:	00013317          	auipc	t1,0x13
    80004a14:	18830313          	addi	t1,t1,392 # 80017b98 <xFreeBytesRemaining>
    80004a18:	00033803          	ld	a6,0(t1)
    80004a1c:	04886063          	bltu	a6,s0,80004a5c <pvPortMalloc+0x92>
            {
                /* Traverse the list from the start (lowest address) block until
                 * one of adequate size is found. */
                pxPreviousBlock = &xStart;
                pxBlock = heapPROTECT_BLOCK_POINTER( xStart.pxNextFreeBlock );
    80004a20:	00002517          	auipc	a0,0x2
    80004a24:	0b050513          	addi	a0,a0,176 # 80006ad0 <xStart>
    80004a28:	611c                	ld	a5,0(a0)
                heapVALIDATE_BLOCK_POINTER( pxBlock );
    80004a2a:	00002697          	auipc	a3,0x2
    80004a2e:	0b668693          	addi	a3,a3,182 # 80006ae0 <ucHeap>
    80004a32:	00d7e863          	bltu	a5,a3,80004a42 <pvPortMalloc+0x78>
    80004a36:	00012897          	auipc	a7,0x12
    80004a3a:	0a988893          	addi	a7,a7,169 # 80016adf <ucHeap+0xffff>
    80004a3e:	04f8f263          	bgeu	a7,a5,80004a82 <pvPortMalloc+0xb8>
    80004a42:	30047073          	csrci	mstatus,8
    80004a46:	a001                	j	80004a46 <pvPortMalloc+0x7c>
    vTaskSuspendAll();
    80004a48:	ffffd097          	auipc	ra,0xffffd
    80004a4c:	ac0080e7          	jalr	-1344(ra) # 80001508 <vTaskSuspendAll>
        if( pxEnd == NULL )
    80004a50:	00013597          	auipc	a1,0x13
    80004a54:	15058593          	addi	a1,a1,336 # 80017ba0 <pxEnd>
    80004a58:	619c                	ld	a5,0(a1)
    80004a5a:	c7b9                	beqz	a5,80004aa8 <pvPortMalloc+0xde>
        traceMALLOC( pvReturn, xAllocatedBlockSize );

        /* Prevent compiler warnings when trace macros are not used. */
        ( void ) xAllocatedBlockSize;
    }
    ( void ) xTaskResumeAll();
    80004a5c:	ffffd097          	auipc	ra,0xffffd
    80004a60:	abc080e7          	jalr	-1348(ra) # 80001518 <xTaskResumeAll>
    80004a64:	4481                	li	s1,0
    }
    #endif /* if ( configUSE_MALLOC_FAILED_HOOK == 1 ) */

    configASSERT( ( ( ( size_t ) pvReturn ) & ( size_t ) portBYTE_ALIGNMENT_MASK ) == 0 );
    return pvReturn;
}
    80004a66:	60e2                	ld	ra,24(sp)
    80004a68:	6442                	ld	s0,16(sp)
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	64a2                	ld	s1,8(sp)
    80004a6e:	6105                	addi	sp,sp,32
    80004a70:	8082                	ret
                while( ( pxBlock->xBlockSize < xWantedSize ) && ( pxBlock->pxNextFreeBlock != heapPROTECT_BLOCK_POINTER( NULL ) ) )
    80004a72:	6398                	ld	a4,0(a5)
    80004a74:	cb11                	beqz	a4,80004a88 <pvPortMalloc+0xbe>
                    heapVALIDATE_BLOCK_POINTER( pxBlock );
    80004a76:	08d76863          	bltu	a4,a3,80004b06 <pvPortMalloc+0x13c>
    80004a7a:	853e                	mv	a0,a5
    80004a7c:	08e8e563          	bltu	a7,a4,80004b06 <pvPortMalloc+0x13c>
    80004a80:	87ba                	mv	a5,a4
                while( ( pxBlock->xBlockSize < xWantedSize ) && ( pxBlock->pxNextFreeBlock != heapPROTECT_BLOCK_POINTER( NULL ) ) )
    80004a82:	6790                	ld	a2,8(a5)
    80004a84:	fe8667e3          	bltu	a2,s0,80004a72 <pvPortMalloc+0xa8>
                if( pxBlock != pxEnd )
    80004a88:	6198                	ld	a4,0(a1)
    80004a8a:	fcf709e3          	beq	a4,a5,80004a5c <pvPortMalloc+0x92>
                    pvReturn = ( void * ) ( ( ( uint8_t * ) heapPROTECT_BLOCK_POINTER( pxPreviousBlock->pxNextFreeBlock ) ) + xHeapStructSize );
    80004a8e:	6104                	ld	s1,0(a0)
    80004a90:	04c1                	addi	s1,s1,16
                    heapVALIDATE_BLOCK_POINTER( pvReturn );
    80004a92:	06d4ed63          	bltu	s1,a3,80004b0c <pvPortMalloc+0x142>
    80004a96:	0698eb63          	bltu	a7,s1,80004b0c <pvPortMalloc+0x142>
                    pxPreviousBlock->pxNextFreeBlock = pxBlock->pxNextFreeBlock;
    80004a9a:	6394                	ld	a3,0(a5)
    80004a9c:	e114                	sd	a3,0(a0)
                    configASSERT( heapSUBTRACT_WILL_UNDERFLOW( pxBlock->xBlockSize, xWantedSize ) == 0 );
    80004a9e:	06867a63          	bgeu	a2,s0,80004b12 <pvPortMalloc+0x148>
    80004aa2:	30047073          	csrci	mstatus,8
    80004aa6:	a001                	j	80004aa6 <pvPortMalloc+0xdc>
        if( pxEnd == NULL )
    80004aa8:	4501                	li	a0,0
    80004aaa:	4401                	li	s0,0
    BlockLink_t * pxFirstFreeBlock;
    portPOINTER_SIZE_TYPE uxStartAddress, uxEndAddress;
    size_t xTotalHeapSize = configTOTAL_HEAP_SIZE;

    /* Ensure the heap starts on a correctly aligned boundary. */
    uxStartAddress = ( portPOINTER_SIZE_TYPE ) ucHeap;
    80004aac:	00002697          	auipc	a3,0x2
    80004ab0:	03468693          	addi	a3,a3,52 # 80006ae0 <ucHeap>

    if( ( uxStartAddress & portBYTE_ALIGNMENT_MASK ) != 0 )
    80004ab4:	00f6f793          	andi	a5,a3,15
    80004ab8:	8636                	mv	a2,a3
    80004aba:	c799                	beqz	a5,80004ac8 <pvPortMalloc+0xfe>
    {
        uxStartAddress += ( portBYTE_ALIGNMENT - 1 );
    80004abc:	00002697          	auipc	a3,0x2
    80004ac0:	03368693          	addi	a3,a3,51 # 80006aef <ucHeap+0xf>
        uxStartAddress &= ~( ( portPOINTER_SIZE_TYPE ) portBYTE_ALIGNMENT_MASK );
    80004ac4:	9ac1                	andi	a3,a3,-16
    }
    #endif

    /* xStart is used to hold a pointer to the first item in the list of free
     * blocks.  The void cast is used to prevent compiler warnings. */
    xStart.pxNextFreeBlock = ( void * ) heapPROTECT_BLOCK_POINTER( uxStartAddress );
    80004ac6:	8636                	mv	a2,a3
    xStart.xBlockSize = ( size_t ) 0;

    /* pxEnd is used to mark the end of the list of free blocks and is inserted
     * at the end of the heap space. */
    uxEndAddress = uxStartAddress + ( portPOINTER_SIZE_TYPE ) xTotalHeapSize;
    uxEndAddress -= ( portPOINTER_SIZE_TYPE ) xHeapStructSize;
    80004ac8:	00012717          	auipc	a4,0x12
    80004acc:	00870713          	addi	a4,a4,8 # 80016ad0 <ucHeap+0xfff0>
    uxEndAddress &= ~( ( portPOINTER_SIZE_TYPE ) portBYTE_ALIGNMENT_MASK );
    80004ad0:	9b41                	andi	a4,a4,-16
    xStart.xBlockSize = ( size_t ) 0;
    80004ad2:	00002797          	auipc	a5,0x2
    80004ad6:	0007b323          	sd	zero,6(a5) # 80006ad8 <xStart+0x8>
    xStart.pxNextFreeBlock = ( void * ) heapPROTECT_BLOCK_POINTER( uxStartAddress );
    80004ada:	00002797          	auipc	a5,0x2
    80004ade:	fec7bb23          	sd	a2,-10(a5) # 80006ad0 <xStart>
    pxEnd = ( BlockLink_t * ) uxEndAddress;
    pxEnd->xBlockSize = 0;
    80004ae2:	00073423          	sd	zero,8(a4)
    pxEnd->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( NULL );
    80004ae6:	00073023          	sd	zero,0(a4)

    /* To start with there is a single free block that is sized to take up the
     * entire heap space, minus the space taken by pxEnd. */
    pxFirstFreeBlock = ( BlockLink_t * ) uxStartAddress;
    pxFirstFreeBlock->xBlockSize = ( size_t ) ( uxEndAddress - ( portPOINTER_SIZE_TYPE ) pxFirstFreeBlock );
    80004aea:	40d707b3          	sub	a5,a4,a3
    pxEnd = ( BlockLink_t * ) uxEndAddress;
    80004aee:	e198                	sd	a4,0(a1)
    pxFirstFreeBlock->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( pxEnd );
    80004af0:	e218                	sd	a4,0(a2)
    pxFirstFreeBlock->xBlockSize = ( size_t ) ( uxEndAddress - ( portPOINTER_SIZE_TYPE ) pxFirstFreeBlock );
    80004af2:	e61c                	sd	a5,8(a2)

    /* Only one block exists - and it covers the entire usable heap space. */
    xMinimumEverFreeBytesRemaining = pxFirstFreeBlock->xBlockSize;
    80004af4:	00013717          	auipc	a4,0x13
    80004af8:	08f73e23          	sd	a5,156(a4) # 80017b90 <xMinimumEverFreeBytesRemaining>
    xFreeBytesRemaining = pxFirstFreeBlock->xBlockSize;
    80004afc:	00013717          	auipc	a4,0x13
    80004b00:	08f73e23          	sd	a5,156(a4) # 80017b98 <xFreeBytesRemaining>
}
    80004b04:	b721                	j	80004a0c <pvPortMalloc+0x42>
                    heapVALIDATE_BLOCK_POINTER( pxBlock );
    80004b06:	30047073          	csrci	mstatus,8
    80004b0a:	a001                	j	80004b0a <pvPortMalloc+0x140>
                    heapVALIDATE_BLOCK_POINTER( pvReturn );
    80004b0c:	30047073          	csrci	mstatus,8
    80004b10:	a001                	j	80004b10 <pvPortMalloc+0x146>
                    if( ( pxBlock->xBlockSize - xWantedSize ) > heapMINIMUM_BLOCK_SIZE )
    80004b12:	408605b3          	sub	a1,a2,s0
    80004b16:	02000713          	li	a4,32
    80004b1a:	00b77e63          	bgeu	a4,a1,80004b36 <pvPortMalloc+0x16c>
                        pxNewBlockLink = ( void * ) ( ( ( uint8_t * ) pxBlock ) + xWantedSize );
    80004b1e:	00878733          	add	a4,a5,s0
                        configASSERT( ( ( ( size_t ) pxNewBlockLink ) & portBYTE_ALIGNMENT_MASK ) == 0 );
    80004b22:	00f77613          	andi	a2,a4,15
    80004b26:	c601                	beqz	a2,80004b2e <pvPortMalloc+0x164>
    80004b28:	30047073          	csrci	mstatus,8
    80004b2c:	a001                	j	80004b2c <pvPortMalloc+0x162>
                        pxNewBlockLink->xBlockSize = pxBlock->xBlockSize - xWantedSize;
    80004b2e:	e70c                	sd	a1,8(a4)
                        pxNewBlockLink->pxNextFreeBlock = pxPreviousBlock->pxNextFreeBlock;
    80004b30:	e314                	sd	a3,0(a4)
                        pxPreviousBlock->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( pxNewBlockLink );
    80004b32:	e118                	sd	a4,0(a0)
    80004b34:	8622                	mv	a2,s0
                    if( xFreeBytesRemaining < xMinimumEverFreeBytesRemaining )
    80004b36:	00013717          	auipc	a4,0x13
    80004b3a:	05a70713          	addi	a4,a4,90 # 80017b90 <xMinimumEverFreeBytesRemaining>
    80004b3e:	6314                	ld	a3,0(a4)
                    xFreeBytesRemaining -= pxBlock->xBlockSize;
    80004b40:	40c80833          	sub	a6,a6,a2
    80004b44:	01033023          	sd	a6,0(t1)
                    if( xFreeBytesRemaining < xMinimumEverFreeBytesRemaining )
    80004b48:	00d87463          	bgeu	a6,a3,80004b50 <pvPortMalloc+0x186>
                        xMinimumEverFreeBytesRemaining = xFreeBytesRemaining;
    80004b4c:	01073023          	sd	a6,0(a4)
                    xNumberOfSuccessfulAllocations++;
    80004b50:	00013597          	auipc	a1,0x13
    80004b54:	03858593          	addi	a1,a1,56 # 80017b88 <xNumberOfSuccessfulAllocations>
    80004b58:	6198                	ld	a4,0(a1)
                    heapALLOCATE_BLOCK( pxBlock );
    80004b5a:	56fd                	li	a3,-1
    80004b5c:	16fe                	slli	a3,a3,0x3f
    80004b5e:	8e55                	or	a2,a2,a3
                    xNumberOfSuccessfulAllocations++;
    80004b60:	0705                	addi	a4,a4,1
                    heapALLOCATE_BLOCK( pxBlock );
    80004b62:	e790                	sd	a2,8(a5)
                    pxBlock->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( NULL );
    80004b64:	0007b023          	sd	zero,0(a5)
                    xNumberOfSuccessfulAllocations++;
    80004b68:	e198                	sd	a4,0(a1)
    ( void ) xTaskResumeAll();
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	9ae080e7          	jalr	-1618(ra) # 80001518 <xTaskResumeAll>
    configASSERT( ( ( ( size_t ) pvReturn ) & ( size_t ) portBYTE_ALIGNMENT_MASK ) == 0 );
    80004b72:	00f4f793          	andi	a5,s1,15
    80004b76:	ee0788e3          	beqz	a5,80004a66 <pvPortMalloc+0x9c>
    80004b7a:	30047073          	csrci	mstatus,8
    80004b7e:	a001                	j	80004b7e <pvPortMalloc+0x1b4>

0000000080004b80 <vPortFree>:
    if( pv != NULL )
    80004b80:	cd1d                	beqz	a0,80004bbe <vPortFree+0x3e>
{
    80004b82:	7179                	addi	sp,sp,-48
    80004b84:	f022                	sd	s0,32(sp)
    80004b86:	ec26                	sd	s1,24(sp)
    80004b88:	f406                	sd	ra,40(sp)
    80004b8a:	e84a                	sd	s2,16(sp)
        puc -= xHeapStructSize;
    80004b8c:	ff050413          	addi	s0,a0,-16
        heapVALIDATE_BLOCK_POINTER( pxLink );
    80004b90:	00002497          	auipc	s1,0x2
    80004b94:	f5048493          	addi	s1,s1,-176 # 80006ae0 <ucHeap>
    80004b98:	02946063          	bltu	s0,s1,80004bb8 <vPortFree+0x38>
    80004b9c:	00012917          	auipc	s2,0x12
    80004ba0:	f4390913          	addi	s2,s2,-189 # 80016adf <ucHeap+0xffff>
    80004ba4:	00896a63          	bltu	s2,s0,80004bb8 <vPortFree+0x38>
        configASSERT( heapBLOCK_IS_ALLOCATED( pxLink ) != 0 );
    80004ba8:	ff853783          	ld	a5,-8(a0)
    80004bac:	43f7d713          	srai	a4,a5,0x3f
    80004bb0:	eb01                	bnez	a4,80004bc0 <vPortFree+0x40>
    80004bb2:	30047073          	csrci	mstatus,8
    80004bb6:	a001                	j	80004bb6 <vPortFree+0x36>
        heapVALIDATE_BLOCK_POINTER( pxLink );
    80004bb8:	30047073          	csrci	mstatus,8
    80004bbc:	a001                	j	80004bbc <vPortFree+0x3c>
    80004bbe:	8082                	ret
        configASSERT( pxLink->pxNextFreeBlock == heapPROTECT_BLOCK_POINTER( NULL ) );
    80004bc0:	ff053683          	ld	a3,-16(a0)
    80004bc4:	c681                	beqz	a3,80004bcc <vPortFree+0x4c>
    80004bc6:	30047073          	csrci	mstatus,8
    80004bca:	a001                	j	80004bca <vPortFree+0x4a>
                heapFREE_BLOCK( pxLink );
    80004bcc:	8305                	srli	a4,a4,0x1
    80004bce:	8ff9                	and	a5,a5,a4
    80004bd0:	fef53c23          	sd	a5,-8(a0)
    80004bd4:	e42a                	sd	a0,8(sp)
                vTaskSuspendAll();
    80004bd6:	ffffd097          	auipc	ra,0xffffd
    80004bda:	932080e7          	jalr	-1742(ra) # 80001508 <vTaskSuspendAll>
                    xFreeBytesRemaining += pxLink->xBlockSize;
    80004bde:	6522                	ld	a0,8(sp)
    80004be0:	00013597          	auipc	a1,0x13
    80004be4:	fb858593          	addi	a1,a1,-72 # 80017b98 <xFreeBytesRemaining>
    80004be8:	619c                	ld	a5,0(a1)
    80004bea:	ff853683          	ld	a3,-8(a0)
    BlockLink_t * pxIterator;
    uint8_t * puc;

    /* Iterate through the list until a block is found that has a higher address
     * than the block being inserted. */
    for( pxIterator = &xStart; heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) < pxBlockToInsert; pxIterator = heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) )
    80004bee:	00002617          	auipc	a2,0x2
    80004bf2:	ee260613          	addi	a2,a2,-286 # 80006ad0 <xStart>
    80004bf6:	8732                	mv	a4,a2
                    xFreeBytesRemaining += pxLink->xBlockSize;
    80004bf8:	97b6                	add	a5,a5,a3
    80004bfa:	e19c                	sd	a5,0(a1)
    for( pxIterator = &xStart; heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) < pxBlockToInsert; pxIterator = heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) )
    80004bfc:	87ba                	mv	a5,a4
    80004bfe:	6318                	ld	a4,0(a4)
    80004c00:	fe876ee3          	bltu	a4,s0,80004bfc <vPortFree+0x7c>
    {
        /* Nothing to do here, just iterate to the right position. */
    }

    if( pxIterator != &xStart )
    80004c04:	00c78663          	beq	a5,a2,80004c10 <vPortFree+0x90>
    {
        heapVALIDATE_BLOCK_POINTER( pxIterator );
    80004c08:	0497e263          	bltu	a5,s1,80004c4c <vPortFree+0xcc>
    80004c0c:	04f96063          	bltu	s2,a5,80004c4c <vPortFree+0xcc>

    /* Do the block being inserted, and the block it is being inserted after
     * make a contiguous block of memory? */
    puc = ( uint8_t * ) pxIterator;

    if( ( puc + pxIterator->xBlockSize ) == ( uint8_t * ) pxBlockToInsert )
    80004c10:	6790                	ld	a2,8(a5)
    80004c12:	00c785b3          	add	a1,a5,a2
    80004c16:	04b40b63          	beq	s0,a1,80004c6c <vPortFree+0xec>

    /* Do the block being inserted, and the block it is being inserted before
     * make a contiguous block of memory? */
    puc = ( uint8_t * ) pxBlockToInsert;

    if( ( puc + pxBlockToInsert->xBlockSize ) == ( uint8_t * ) heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) )
    80004c1a:	00d405b3          	add	a1,s0,a3
    80004c1e:	863a                	mv	a2,a4
    80004c20:	02b70a63          	beq	a4,a1,80004c54 <vPortFree+0xd4>
    {
        if( heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) != pxEnd )
        {
            /* Form one big block from the two blocks. */
            pxBlockToInsert->xBlockSize += heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock )->xBlockSize;
            pxBlockToInsert->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock )->pxNextFreeBlock;
    80004c24:	e010                	sd	a2,0(s0)

    /* If the block being inserted plugged a gap, so was merged with the block
     * before and the block after, then it's pxNextFreeBlock pointer will have
     * already been set, and should not be set here as that would make it point
     * to itself. */
    if( pxIterator != pxBlockToInsert )
    80004c26:	00878363          	beq	a5,s0,80004c2c <vPortFree+0xac>
    {
        pxIterator->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( pxBlockToInsert );
    80004c2a:	e380                	sd	s0,0(a5)
                    xNumberOfSuccessfulFrees++;
    80004c2c:	00013717          	auipc	a4,0x13
    80004c30:	f5470713          	addi	a4,a4,-172 # 80017b80 <xNumberOfSuccessfulFrees>
    80004c34:	631c                	ld	a5,0(a4)
}
    80004c36:	7402                	ld	s0,32(sp)
    80004c38:	70a2                	ld	ra,40(sp)
    80004c3a:	64e2                	ld	s1,24(sp)
    80004c3c:	6942                	ld	s2,16(sp)
                    xNumberOfSuccessfulFrees++;
    80004c3e:	0785                	addi	a5,a5,1
    80004c40:	e31c                	sd	a5,0(a4)
}
    80004c42:	6145                	addi	sp,sp,48
                ( void ) xTaskResumeAll();
    80004c44:	ffffd317          	auipc	t1,0xffffd
    80004c48:	8d430067          	jr	-1836(t1) # 80001518 <xTaskResumeAll>
        heapVALIDATE_BLOCK_POINTER( pxIterator );
    80004c4c:	30047073          	csrci	mstatus,8
    80004c50:	a001                	j	80004c50 <vPortFree+0xd0>
    if( ( puc + pxBlockToInsert->xBlockSize ) == ( uint8_t * ) heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) )
    80004c52:	843e                	mv	s0,a5
        if( heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) != pxEnd )
    80004c54:	00013617          	auipc	a2,0x13
    80004c58:	f4c63603          	ld	a2,-180(a2) # 80017ba0 <pxEnd>
    80004c5c:	fcc704e3          	beq	a4,a2,80004c24 <vPortFree+0xa4>
            pxBlockToInsert->xBlockSize += heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock )->xBlockSize;
    80004c60:	670c                	ld	a1,8(a4)
            pxBlockToInsert->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock )->pxNextFreeBlock;
    80004c62:	6310                	ld	a2,0(a4)
            pxBlockToInsert->xBlockSize += heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock )->xBlockSize;
    80004c64:	00d58733          	add	a4,a1,a3
    80004c68:	e418                	sd	a4,8(s0)
            pxBlockToInsert->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock )->pxNextFreeBlock;
    80004c6a:	bf6d                	j	80004c24 <vPortFree+0xa4>
        pxIterator->xBlockSize += pxBlockToInsert->xBlockSize;
    80004c6c:	96b2                	add	a3,a3,a2
    80004c6e:	e794                	sd	a3,8(a5)
    if( ( puc + pxBlockToInsert->xBlockSize ) == ( uint8_t * ) heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock ) )
    80004c70:	00d78633          	add	a2,a5,a3
    80004c74:	fcc70fe3          	beq	a4,a2,80004c52 <vPortFree+0xd2>
            pxBlockToInsert->pxNextFreeBlock = heapPROTECT_BLOCK_POINTER( pxIterator->pxNextFreeBlock )->pxNextFreeBlock;
    80004c78:	e398                	sd	a4,0(a5)
    if( pxIterator != pxBlockToInsert )
    80004c7a:	bf4d                	j	80004c2c <vPortFree+0xac>

0000000080004c7c <xPortGetFreeHeapSize>:
}
    80004c7c:	00013517          	auipc	a0,0x13
    80004c80:	f1c53503          	ld	a0,-228(a0) # 80017b98 <xFreeBytesRemaining>
    80004c84:	8082                	ret

0000000080004c86 <xPortGetMinimumEverFreeHeapSize>:
}
    80004c86:	00013517          	auipc	a0,0x13
    80004c8a:	f0a53503          	ld	a0,-246(a0) # 80017b90 <xMinimumEverFreeBytesRemaining>
    80004c8e:	8082                	ret

0000000080004c90 <xPortResetHeapMinimumEverFreeHeapSize>:
    xMinimumEverFreeBytesRemaining = xFreeBytesRemaining;
    80004c90:	00013797          	auipc	a5,0x13
    80004c94:	f087b783          	ld	a5,-248(a5) # 80017b98 <xFreeBytesRemaining>
    80004c98:	00013717          	auipc	a4,0x13
    80004c9c:	eef73c23          	sd	a5,-264(a4) # 80017b90 <xMinimumEverFreeBytesRemaining>
}
    80004ca0:	8082                	ret

0000000080004ca2 <vPortInitialiseBlocks>:
}
    80004ca2:	8082                	ret

0000000080004ca4 <pvPortCalloc>:
{
    80004ca4:	1101                	addi	sp,sp,-32
    80004ca6:	ec06                	sd	ra,24(sp)
    80004ca8:	e822                	sd	s0,16(sp)
    80004caa:	e426                	sd	s1,8(sp)
    if( heapMULTIPLY_WILL_OVERFLOW( xNum, xSize ) == 0 )
    80004cac:	c501                	beqz	a0,80004cb4 <pvPortCalloc+0x10>
    80004cae:	02a5b7b3          	mulhu	a5,a1,a0
    80004cb2:	e795                	bnez	a5,80004cde <pvPortCalloc+0x3a>
        pv = pvPortMalloc( xNum * xSize );
    80004cb4:	02b50433          	mul	s0,a0,a1
    80004cb8:	8522                	mv	a0,s0
    80004cba:	00000097          	auipc	ra,0x0
    80004cbe:	d10080e7          	jalr	-752(ra) # 800049ca <pvPortMalloc>
    80004cc2:	84aa                	mv	s1,a0
        if( pv != NULL )
    80004cc4:	c519                	beqz	a0,80004cd2 <pvPortCalloc+0x2e>
    80004cc6:	8622                	mv	a2,s0
    80004cc8:	4581                	li	a1,0
    80004cca:	00001097          	auipc	ra,0x1
    80004cce:	ae2080e7          	jalr	-1310(ra) # 800057ac <memset>
}
    80004cd2:	60e2                	ld	ra,24(sp)
    80004cd4:	6442                	ld	s0,16(sp)
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	64a2                	ld	s1,8(sp)
    80004cda:	6105                	addi	sp,sp,32
    80004cdc:	8082                	ret
    80004cde:	60e2                	ld	ra,24(sp)
    80004ce0:	6442                	ld	s0,16(sp)
    void * pv = NULL;
    80004ce2:	4481                	li	s1,0
}
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	64a2                	ld	s1,8(sp)
    80004ce8:	6105                	addi	sp,sp,32
    80004cea:	8082                	ret

0000000080004cec <vPortGetHeapStats>:
    }
}
/*-----------------------------------------------------------*/

void vPortGetHeapStats( HeapStats_t * pxHeapStats )
{
    80004cec:	7179                	addi	sp,sp,-48
    80004cee:	e44e                	sd	s3,8(sp)
    80004cf0:	f406                	sd	ra,40(sp)
    80004cf2:	f022                	sd	s0,32(sp)
    80004cf4:	ec26                	sd	s1,24(sp)
    80004cf6:	e84a                	sd	s2,16(sp)
    80004cf8:	89aa                	mv	s3,a0
    BlockLink_t * pxBlock;
    size_t xBlocks = 0, xMaxSize = 0, xMinSize = SIZE_MAX;

    vTaskSuspendAll();
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	80e080e7          	jalr	-2034(ra) # 80001508 <vTaskSuspendAll>
    {
        pxBlock = heapPROTECT_BLOCK_POINTER( xStart.pxNextFreeBlock );
    80004d02:	00002797          	auipc	a5,0x2
    80004d06:	dce7b783          	ld	a5,-562(a5) # 80006ad0 <xStart>

        /* pxBlock will be NULL if the heap has not been initialised.  The heap
         * is initialised automatically when the first allocation is made. */
        if( pxBlock != NULL )
    80004d0a:	cbc9                	beqz	a5,80004d9c <vPortGetHeapStats+0xb0>
        {
            while( pxBlock != pxEnd )
    80004d0c:	00013697          	auipc	a3,0x13
    80004d10:	e946b683          	ld	a3,-364(a3) # 80017ba0 <pxEnd>
    size_t xBlocks = 0, xMaxSize = 0, xMinSize = SIZE_MAX;
    80004d14:	54fd                	li	s1,-1
    80004d16:	4901                	li	s2,0
    80004d18:	4401                	li	s0,0
            while( pxBlock != pxEnd )
    80004d1a:	00d78d63          	beq	a5,a3,80004d34 <vPortGetHeapStats+0x48>
            {
                /* Increment the number of blocks and record the largest block seen
                 * so far. */
                xBlocks++;

                if( pxBlock->xBlockSize > xMaxSize )
    80004d1e:	6798                	ld	a4,8(a5)
                xBlocks++;
    80004d20:	0405                	addi	s0,s0,1
                if( pxBlock->xBlockSize > xMaxSize )
    80004d22:	00e97363          	bgeu	s2,a4,80004d28 <vPortGetHeapStats+0x3c>
    80004d26:	893a                	mv	s2,a4
                {
                    xMaxSize = pxBlock->xBlockSize;
                }

                if( pxBlock->xBlockSize < xMinSize )
    80004d28:	00977363          	bgeu	a4,s1,80004d2e <vPortGetHeapStats+0x42>
    80004d2c:	84ba                	mv	s1,a4
                    xMinSize = pxBlock->xBlockSize;
                }

                /* Move to the next block in the chain until the last block is
                 * reached. */
                pxBlock = heapPROTECT_BLOCK_POINTER( pxBlock->pxNextFreeBlock );
    80004d2e:	639c                	ld	a5,0(a5)
            while( pxBlock != pxEnd )
    80004d30:	fed797e3          	bne	a5,a3,80004d1e <vPortGetHeapStats+0x32>
            }
        }
    }
    ( void ) xTaskResumeAll();
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	7e4080e7          	jalr	2020(ra) # 80001518 <xTaskResumeAll>

    pxHeapStats->xSizeOfLargestFreeBlockInBytes = xMaxSize;
    80004d3c:	0129b423          	sd	s2,8(s3)
    pxHeapStats->xSizeOfSmallestFreeBlockInBytes = xMinSize;
    80004d40:	0099b823          	sd	s1,16(s3)
    pxHeapStats->xNumberOfFreeBlocks = xBlocks;
    80004d44:	0089bc23          	sd	s0,24(s3)

    taskENTER_CRITICAL();
    80004d48:	30047073          	csrci	mstatus,8
    80004d4c:	00002717          	auipc	a4,0x2
    80004d50:	b1470713          	addi	a4,a4,-1260 # 80006860 <xCriticalNesting>
    {
        pxHeapStats->xAvailableHeapSpaceInBytes = xFreeBytesRemaining;
    80004d54:	00013697          	auipc	a3,0x13
    80004d58:	e446b683          	ld	a3,-444(a3) # 80017b98 <xFreeBytesRemaining>
    taskENTER_CRITICAL();
    80004d5c:	631c                	ld	a5,0(a4)
        pxHeapStats->xAvailableHeapSpaceInBytes = xFreeBytesRemaining;
    80004d5e:	00d9b023          	sd	a3,0(s3)
        pxHeapStats->xNumberOfSuccessfulAllocations = xNumberOfSuccessfulAllocations;
    80004d62:	00013697          	auipc	a3,0x13
    80004d66:	e266b683          	ld	a3,-474(a3) # 80017b88 <xNumberOfSuccessfulAllocations>
    80004d6a:	02d9b423          	sd	a3,40(s3)
        pxHeapStats->xNumberOfSuccessfulFrees = xNumberOfSuccessfulFrees;
    80004d6e:	00013697          	auipc	a3,0x13
    80004d72:	e126b683          	ld	a3,-494(a3) # 80017b80 <xNumberOfSuccessfulFrees>
    80004d76:	02d9b823          	sd	a3,48(s3)
        pxHeapStats->xMinimumEverFreeBytesRemaining = xMinimumEverFreeBytesRemaining;
    80004d7a:	00013697          	auipc	a3,0x13
    80004d7e:	e166b683          	ld	a3,-490(a3) # 80017b90 <xMinimumEverFreeBytesRemaining>
    80004d82:	02d9b023          	sd	a3,32(s3)
    }
    taskEXIT_CRITICAL();
    80004d86:	e31c                	sd	a5,0(a4)
    80004d88:	e399                	bnez	a5,80004d8e <vPortGetHeapStats+0xa2>
    80004d8a:	30046073          	csrsi	mstatus,8
}
    80004d8e:	70a2                	ld	ra,40(sp)
    80004d90:	7402                	ld	s0,32(sp)
    80004d92:	64e2                	ld	s1,24(sp)
    80004d94:	6942                	ld	s2,16(sp)
    80004d96:	69a2                	ld	s3,8(sp)
    80004d98:	6145                	addi	sp,sp,48
    80004d9a:	8082                	ret
    size_t xBlocks = 0, xMaxSize = 0, xMinSize = SIZE_MAX;
    80004d9c:	54fd                	li	s1,-1
    80004d9e:	4901                	li	s2,0
    80004da0:	4401                	li	s0,0
    80004da2:	bf49                	j	80004d34 <vPortGetHeapStats+0x48>

0000000080004da4 <vPortHeapResetState>:
 * This function must be called by the application before restarting the
 * scheduler.
 */
void vPortHeapResetState( void )
{
    pxEnd = NULL;
    80004da4:	00013797          	auipc	a5,0x13
    80004da8:	de07be23          	sd	zero,-516(a5) # 80017ba0 <pxEnd>

    xFreeBytesRemaining = ( size_t ) 0U;
    80004dac:	00013797          	auipc	a5,0x13
    80004db0:	de07b623          	sd	zero,-532(a5) # 80017b98 <xFreeBytesRemaining>
    xMinimumEverFreeBytesRemaining = ( size_t ) 0U;
    80004db4:	00013797          	auipc	a5,0x13
    80004db8:	dc07be23          	sd	zero,-548(a5) # 80017b90 <xMinimumEverFreeBytesRemaining>
    xNumberOfSuccessfulAllocations = ( size_t ) 0U;
    80004dbc:	00013797          	auipc	a5,0x13
    80004dc0:	dc07b623          	sd	zero,-564(a5) # 80017b88 <xNumberOfSuccessfulAllocations>
    xNumberOfSuccessfulFrees = ( size_t ) 0U;
    80004dc4:	00013797          	auipc	a5,0x13
    80004dc8:	da07be23          	sd	zero,-580(a5) # 80017b80 <xNumberOfSuccessfulFrees>
}
    80004dcc:	8082                	ret

0000000080004dce <pxPortInitialiseStack>:
    addi a0, a0, -portWORD_SIZE         /* Space for critical nesting count. */
    80004dce:	1561                	addi	a0,a0,-8
    store_x x0, 0(a0)                   /* Critical nesting count starts at 0 for every task. */
    80004dd0:	00053023          	sd	zero,0(a0)
    addi a0, a0, -(22 * portWORD_SIZE)  /* Space for registers x10-x31. */
    80004dd4:	f5050513          	addi	a0,a0,-176
    store_x a2, 0(a0)                   /* Task parameters (pvParameters parameter) goes into register x10/a0 on the stack. */
    80004dd8:	e110                	sd	a2,0(a0)
    addi a0, a0, -(6 * portWORD_SIZE)   /* Space for registers x5-x9 + taskReturnAddress (register x1). */
    80004dda:	fd050513          	addi	a0,a0,-48
    load_x t0, xTaskReturnAddress
    80004dde:	00013297          	auipc	t0,0x13
    80004de2:	dca2b283          	ld	t0,-566(t0) # 80017ba8 <xTaskReturnAddress>
    store_x t0, 0(a0)                   /* Return address onto the stack. */
    80004de6:	00553023          	sd	t0,0(a0)
    csrr t0, mstatus                    /* Obtain current mstatus value. */
    80004dea:	300022f3          	csrr	t0,mstatus
    andi t0, t0, ~0x8                   /* Ensure interrupts are disabled when the stack is restored within an ISR.  Required when a task is created after the scheduler has been started, otherwise interrupts would be disabled anyway. */
    80004dee:	ff72f293          	andi	t0,t0,-9
    addi t1, x0, 0x188                  /* Generate the value 0x1880, which are the MPIE=1 and MPP=M_Mode in mstatus. */
    80004df2:	18800313          	li	t1,392
    slli t1, t1, 4
    80004df6:	0312                	slli	t1,t1,0x4
    or t0, t0, t1                       /* Set MPIE and MPP bits in mstatus value. */
    80004df8:	0062e2b3          	or	t0,t0,t1
    addi a0, a0, -portWORD_SIZE
    80004dfc:	1561                	addi	a0,a0,-8
    store_x t0, 0(a0)                   /* mstatus onto the stack. */
    80004dfe:	00553023          	sd	t0,0(a0)
    addi t0, x0, portasmADDITIONAL_CONTEXT_SIZE /* The number of chip specific additional registers. */
    80004e02:	4281                	li	t0,0

0000000080004e04 <chip_specific_stack_frame>:
    beq t0, x0, 1f                      /* No more chip specific registers to save. */
    80004e04:	00028763          	beqz	t0,80004e12 <chip_specific_stack_frame+0xe>
    addi a0, a0, -portWORD_SIZE         /* Make space for chip specific register. */
    80004e08:	1561                	addi	a0,a0,-8
    store_x x0, 0(a0)                   /* Give the chip specific register an initial value of zero. */
    80004e0a:	00053023          	sd	zero,0(a0)
    addi t0, t0, -1                     /* Decrement the count of chip specific registers remaining. */
    80004e0e:	12fd                	addi	t0,t0,-1
    j chip_specific_stack_frame         /* Until no more chip specific registers. */
    80004e10:	bfd5                	j	80004e04 <chip_specific_stack_frame>
    addi a0, a0, -portWORD_SIZE
    80004e12:	1561                	addi	a0,a0,-8
    store_x a1, 0(a0)                   /* mret value (pxCode parameter) onto the stack. */
    80004e14:	e10c                	sd	a1,0(a0)
    ret
    80004e16:	8082                	ret

0000000080004e18 <xPortStartFirstTask>:
    load_x  sp, pxCurrentTCB            /* Load pxCurrentTCB. */
    80004e18:	00013117          	auipc	sp,0x13
    80004e1c:	d3813103          	ld	sp,-712(sp) # 80017b50 <pxCurrentTCB>
    load_x  sp, 0( sp )                 /* Read sp from first TCB member. */
    80004e20:	6102                	ld	sp,0(sp)
    load_x  x1, 0( sp ) /* Note for starting the scheduler the exception return address is used as the function return address. */
    80004e22:	6082                	ld	ra,0(sp)
    load_x  x5, 1 * portWORD_SIZE( sp ) /* Initial mstatus into x5 (t0). */
    80004e24:	62a2                	ld	t0,8(sp)
    addi    x5, x5, 0x08                /* Set MIE bit so the first task starts with interrupts enabled - required as returns with ret not eret. */
    80004e26:	02a1                	addi	t0,t0,8
    csrw    mstatus, x5                 /* Interrupts enabled from here! */
    80004e28:	30029073          	csrw	mstatus,t0
    load_x  x7,  5  * portWORD_SIZE( sp )   /* t2 */
    80004e2c:	73a2                	ld	t2,40(sp)
    load_x  x8,  6  * portWORD_SIZE( sp )   /* s0/fp */
    80004e2e:	7442                	ld	s0,48(sp)
    load_x  x9,  7  * portWORD_SIZE( sp )   /* s1 */
    80004e30:	74e2                	ld	s1,56(sp)
    load_x  x10, 8  * portWORD_SIZE( sp )   /* a0 */
    80004e32:	6506                	ld	a0,64(sp)
    load_x  x11, 9  * portWORD_SIZE( sp )   /* a1 */
    80004e34:	65a6                	ld	a1,72(sp)
    load_x  x12, 10 * portWORD_SIZE( sp )   /* a2 */
    80004e36:	6646                	ld	a2,80(sp)
    load_x  x13, 11 * portWORD_SIZE( sp )   /* a3 */
    80004e38:	66e6                	ld	a3,88(sp)
    load_x  x14, 12 * portWORD_SIZE( sp )   /* a4 */
    80004e3a:	7706                	ld	a4,96(sp)
    load_x  x15, 13 * portWORD_SIZE( sp )   /* a5 */
    80004e3c:	77a6                	ld	a5,104(sp)
    load_x  x16, 14 * portWORD_SIZE( sp )   /* a6 */
    80004e3e:	7846                	ld	a6,112(sp)
    load_x  x17, 15 * portWORD_SIZE( sp )   /* a7 */
    80004e40:	78e6                	ld	a7,120(sp)
    load_x  x18, 16 * portWORD_SIZE( sp )   /* s2 */
    80004e42:	690a                	ld	s2,128(sp)
    load_x  x19, 17 * portWORD_SIZE( sp )   /* s3 */
    80004e44:	69aa                	ld	s3,136(sp)
    load_x  x20, 18 * portWORD_SIZE( sp )   /* s4 */
    80004e46:	6a4a                	ld	s4,144(sp)
    load_x  x21, 19 * portWORD_SIZE( sp )   /* s5 */
    80004e48:	6aea                	ld	s5,152(sp)
    load_x  x22, 20 * portWORD_SIZE( sp )   /* s6 */
    80004e4a:	7b0a                	ld	s6,160(sp)
    load_x  x23, 21 * portWORD_SIZE( sp )   /* s7 */
    80004e4c:	7baa                	ld	s7,168(sp)
    load_x  x24, 22 * portWORD_SIZE( sp )   /* s8 */
    80004e4e:	7c4a                	ld	s8,176(sp)
    load_x  x25, 23 * portWORD_SIZE( sp )   /* s9 */
    80004e50:	7cea                	ld	s9,184(sp)
    load_x  x26, 24 * portWORD_SIZE( sp )   /* s10 */
    80004e52:	6d0e                	ld	s10,192(sp)
    load_x  x27, 25 * portWORD_SIZE( sp )   /* s11 */
    80004e54:	6dae                	ld	s11,200(sp)
    load_x  x28, 26 * portWORD_SIZE( sp )   /* t3 */
    80004e56:	6e4e                	ld	t3,208(sp)
    load_x  x29, 27 * portWORD_SIZE( sp )   /* t4 */
    80004e58:	6eee                	ld	t4,216(sp)
    load_x  x30, 28 * portWORD_SIZE( sp )   /* t5 */
    80004e5a:	7f0e                	ld	t5,224(sp)
    load_x  x31, 29 * portWORD_SIZE( sp )   /* t6 */
    80004e5c:	7fae                	ld	t6,232(sp)
    load_x  x5, portCRITICAL_NESTING_OFFSET * portWORD_SIZE( sp )    /* Obtain xCriticalNesting value for this task from task's stack. */
    80004e5e:	72ce                	ld	t0,240(sp)
    load_x  x6, pxCriticalNesting           /* Load the address of xCriticalNesting into x6. */
    80004e60:	00002317          	auipc	t1,0x2
    80004e64:	9f833303          	ld	t1,-1544(t1) # 80006858 <pxCriticalNesting>
    store_x x5, 0( x6 )                     /* Restore the critical nesting value for this task. */
    80004e68:	00533023          	sd	t0,0(t1)
    load_x  x5, 3 * portWORD_SIZE( sp )     /* Initial x5 (t0) value. */
    80004e6c:	62e2                	ld	t0,24(sp)
    load_x  x6, 4 * portWORD_SIZE( sp )     /* Initial x6 (t1) value. */
    80004e6e:	7302                	ld	t1,32(sp)
    addi    sp, sp, portCONTEXT_SIZE
    80004e70:	0f810113          	addi	sp,sp,248
    ret
    80004e74:	8082                	ret

0000000080004e76 <freertos_risc_v_application_exception_handler>:
    csrr t0, mcause     /* For viewing in the debugger only. */
    80004e76:	342022f3          	csrr	t0,mcause
    csrr t1, mepc       /* For viewing in the debugger only */
    80004e7a:	34102373          	csrr	t1,mepc
    csrr t2, mstatus    /* For viewing in the debugger only */
    80004e7e:	300023f3          	csrr	t2,mstatus
    j .
    80004e82:	a001                	j	80004e82 <freertos_risc_v_application_exception_handler+0xc>
    csrr t0, mcause     /* For viewing in the debugger only. */
    80004e84:	342022f3          	csrr	t0,mcause
    csrr t1, mepc       /* For viewing in the debugger only */
    80004e88:	34102373          	csrr	t1,mepc
    csrr t2, mstatus    /* For viewing in the debugger only */
    80004e8c:	300023f3          	csrr	t2,mstatus
    j .
    80004e90:	a001                	j	80004e90 <freertos_risc_v_application_exception_handler+0x1a>

0000000080004e92 <vPortSetupTimerInterrupt>:
/*-----------------------------------------------------------*/

#if ( configMTIME_BASE_ADDRESS != 0 ) && ( configMTIMECMP_BASE_ADDRESS != 0 )

    void vPortSetupTimerInterrupt( void )
    {
    80004e92:	1141                	addi	sp,sp,-16
        uint32_t ulCurrentTimeHigh, ulCurrentTimeLow;
        volatile uint32_t * const pulTimeHigh = ( volatile uint32_t * const ) ( ( configMTIME_BASE_ADDRESS ) + 4UL ); /* 8-byte type so high 32-bit word is 4 bytes up. */
        volatile uint32_t * const pulTimeLow = ( volatile uint32_t * const ) ( configMTIME_BASE_ADDRESS );
        volatile uint32_t ulHartId;

        __asm volatile ( "csrr %0, mhartid" : "=r" ( ulHartId ) );
    80004e94:	f14027f3          	csrr	a5,mhartid
    80004e98:	c63e                	sw	a5,12(sp)

        pullMachineTimerCompareRegister = ( volatile uint64_t * ) ( configMTIMECMP_BASE_ADDRESS + ( ulHartId * sizeof( uint64_t ) ) );
    80004e9a:	4532                	lw	a0,12(sp)
    80004e9c:	004017b7          	lui	a5,0x401
    80004ea0:	80078793          	addi	a5,a5,-2048 # 400800 <_start-0x7fbff800>
    80004ea4:	1502                	slli	a0,a0,0x20
    80004ea6:	9101                	srli	a0,a0,0x20
    80004ea8:	953e                	add	a0,a0,a5
    80004eaa:	050e                	slli	a0,a0,0x3
    80004eac:	00013797          	auipc	a5,0x13
    80004eb0:	d0a7b223          	sd	a0,-764(a5) # 80017bb0 <pullMachineTimerCompareRegister>

        do
        {
            ulCurrentTimeHigh = *pulTimeHigh;
    80004eb4:	0200c737          	lui	a4,0x200c
    80004eb8:	ffc72603          	lw	a2,-4(a4) # 200bffc <_start-0x7dff4004>
            ulCurrentTimeLow = *pulTimeLow;
    80004ebc:	ff872783          	lw	a5,-8(a4)
        } while( ulCurrentTimeHigh != *pulTimeHigh );
    80004ec0:	ffc72683          	lw	a3,-4(a4)
            ulCurrentTimeLow = *pulTimeLow;
    80004ec4:	2781                	sext.w	a5,a5
        } while( ulCurrentTimeHigh != *pulTimeHigh );
    80004ec6:	0006859b          	sext.w	a1,a3
    80004eca:	fec697e3          	bne	a3,a2,80004eb8 <vPortSetupTimerInterrupt+0x26>

        ullNextTime = ( uint64_t ) ulCurrentTimeHigh;
        ullNextTime <<= 32ULL; /* High 4-byte word is 32-bits up. */
        ullNextTime |= ( uint64_t ) ulCurrentTimeLow;
    80004ece:	1782                	slli	a5,a5,0x20
    80004ed0:	9381                	srli	a5,a5,0x20
        ullNextTime <<= 32ULL; /* High 4-byte word is 32-bits up. */
    80004ed2:	1582                	slli	a1,a1,0x20
        ullNextTime |= ( uint64_t ) ulCurrentTimeLow;
    80004ed4:	8ddd                	or	a1,a1,a5
        ullNextTime += ( uint64_t ) uxTimerIncrementsForOneTick;
    80004ed6:	67e1                	lui	a5,0x18
    80004ed8:	6a078793          	addi	a5,a5,1696 # 186a0 <_start-0x7ffe7960>
    80004edc:	97ae                	add	a5,a5,a1
        *pullMachineTimerCompareRegister = ullNextTime;
    80004ede:	e11c                	sd	a5,0(a0)

        /* Prepare the time to use after the next tick interrupt. */
        ullNextTime += ( uint64_t ) uxTimerIncrementsForOneTick;
    80004ee0:	000317b7          	lui	a5,0x31
    80004ee4:	d4078793          	addi	a5,a5,-704 # 30d40 <_start-0x7ffcf2c0>
    80004ee8:	95be                	add	a1,a1,a5
    80004eea:	00013797          	auipc	a5,0x13
    80004eee:	ccb7b723          	sd	a1,-818(a5) # 80017bb8 <ullNextTime>
    }
    80004ef2:	0141                	addi	sp,sp,16
    80004ef4:	8082                	ret

0000000080004ef6 <xPortStartScheduler>:

#endif /* ( configMTIME_BASE_ADDRESS != 0 ) && ( configMTIMECMP_BASE_ADDRESS != 0 ) */
/*-----------------------------------------------------------*/

BaseType_t xPortStartScheduler( void )
{
    80004ef6:	1141                	addi	sp,sp,-16
    80004ef8:	6605                	lui	a2,0x1
    80004efa:	0ee00593          	li	a1,238
    80004efe:	00012517          	auipc	a0,0x12
    80004f02:	be250513          	addi	a0,a0,-1054 # 80016ae0 <xISRStack>
    80004f06:	e406                	sd	ra,8(sp)
    80004f08:	00001097          	auipc	ra,0x1
    80004f0c:	8a4080e7          	jalr	-1884(ra) # 800057ac <memset>
    #endif /* configASSERT_DEFINED */

    /* If there is a CLINT then it is ok to use the default implementation
     * in this file, otherwise vPortSetupTimerInterrupt() must be implemented to
     * configure whichever clock is to be used to generate the tick interrupt. */
    vPortSetupTimerInterrupt();
    80004f10:	00000097          	auipc	ra,0x0
    80004f14:	f82080e7          	jalr	-126(ra) # 80004e92 <vPortSetupTimerInterrupt>
    #if ( ( configMTIME_BASE_ADDRESS != 0 ) && ( configMTIMECMP_BASE_ADDRESS != 0 ) )
    {
        /* Enable mtime and external interrupts.  1<<7 for timer interrupt,
         * 1<<11 for external interrupt.  _RB_ What happens here when mtime is
         * not present as with pulpino? */
        __asm volatile ( "csrs mie, %0" ::"r" ( 0x880 ) );
    80004f18:	6785                	lui	a5,0x1
    80004f1a:	8807879b          	addiw	a5,a5,-1920 # 880 <_start-0x7ffff780>
    80004f1e:	3047a073          	csrs	mie,a5
    }
    #endif /* ( configMTIME_BASE_ADDRESS != 0 ) && ( configMTIMECMP_BASE_ADDRESS != 0 ) */

    xPortStartFirstTask();
    80004f22:	00000097          	auipc	ra,0x0
    80004f26:	ef6080e7          	jalr	-266(ra) # 80004e18 <xPortStartFirstTask>

    /* Should not get here as after calling xPortStartFirstTask() only tasks
     * should be executing. */
    return pdFAIL;
}
    80004f2a:	60a2                	ld	ra,8(sp)
    80004f2c:	4501                	li	a0,0
    80004f2e:	0141                	addi	sp,sp,16
    80004f30:	8082                	ret

0000000080004f32 <vPortEndScheduler>:
/*-----------------------------------------------------------*/

void vPortEndScheduler( void )
{
    /* Not implemented. */
    for( ; ; )
    80004f32:	a001                	j	80004f32 <vPortEndScheduler>

0000000080004f34 <uart_init>:
void uart_init(void)
{
    /* QEMU 默认已经配置好 UART, 这里做基本初始化 */

    /* 设置波特率: 禁用中断 -> 设置 DLAB -> 写除数 -> 清除 DLAB */
    uint8_t lcr = UART[UART_LCR];
    80004f34:	100007b7          	lui	a5,0x10000
    80004f38:	0037c703          	lbu	a4,3(a5) # 10000003 <_start-0x6ffffffd>

    UART[UART_IER] = 0x00;              /* 关中断 */
    80004f3c:	000780a3          	sb	zero,1(a5)
    UART[UART_LCR] = lcr | 0x80;        /* 置 DLAB */
    UART[UART_DLL] = 1;                 /* 115200 (1.8432MHz / 16 / 1) */
    80004f40:	4685                	li	a3,1
    UART[UART_LCR] = lcr | 0x80;        /* 置 DLAB */
    80004f42:	08076613          	ori	a2,a4,128
    80004f46:	00c781a3          	sb	a2,3(a5)
    UART[UART_DLL] = 1;                 /* 115200 (1.8432MHz / 16 / 1) */
    80004f4a:	00d78023          	sb	a3,0(a5)
    UART[UART_DLM] = 0;
    80004f4e:	000780a3          	sb	zero,1(a5)
    UART[UART_LCR] = lcr & ~0x80;       /* 清 DLAB */
    80004f52:	07f77713          	andi	a4,a4,127
    80004f56:	00e781a3          	sb	a4,3(a5)

    /* 8N1, 使能 FIFO */
    UART[UART_LCR] = 0x03;              /* 8位, 无校验, 1停止位 */
    80004f5a:	470d                	li	a4,3
    80004f5c:	00e781a3          	sb	a4,3(a5)
    UART[UART_FCR] = 0x01;              /* 使能 FIFO */
    80004f60:	00d78123          	sb	a3,2(a5)
}
    80004f64:	8082                	ret

0000000080004f66 <uart_putc>:

void uart_putc(char c)
{
    /* 等待发送 FIFO 空 */
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80004f66:	10000737          	lui	a4,0x10000
        ;

    UART[UART_THR] = (uint8_t)c;

    /* LF -> CR+LF */
    if (c == '\n')
    80004f6a:	46a9                	li	a3,10
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80004f6c:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80004f70:	0207f793          	andi	a5,a5,32
    80004f74:	dfe5                	beqz	a5,80004f6c <uart_putc+0x6>
    UART[UART_THR] = (uint8_t)c;
    80004f76:	00a70023          	sb	a0,0(a4)
    if (c == '\n')
    80004f7a:	00d51463          	bne	a0,a3,80004f82 <uart_putc+0x1c>
        uart_putc('\r');
    80004f7e:	4535                	li	a0,13
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80004f80:	b7f5                	j	80004f6c <uart_putc+0x6>
}
    80004f82:	8082                	ret

0000000080004f84 <uart_getc>:

char uart_getc(void)
{
    /* 等待数据就绪 */
    while (!(UART[UART_LSR] & UART_LSR_DR))
    80004f84:	10000737          	lui	a4,0x10000
    80004f88:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80004f8c:	8b85                	andi	a5,a5,1
    80004f8e:	dfed                	beqz	a5,80004f88 <uart_getc+0x4>
        ;

    return (char)UART[UART_RBR];
    80004f90:	00074503          	lbu	a0,0(a4)
}
    80004f94:	8082                	ret

0000000080004f96 <uart_getc_nonblock>:

int uart_getc_nonblock(void)
{
    if (UART[UART_LSR] & UART_LSR_DR)
    80004f96:	10000737          	lui	a4,0x10000
    80004f9a:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80004f9e:	8b85                	andi	a5,a5,1
    80004fa0:	c781                	beqz	a5,80004fa8 <uart_getc_nonblock+0x12>
        return (char)UART[UART_RBR];
    80004fa2:	00074503          	lbu	a0,0(a4)
    80004fa6:	8082                	ret

    return -1;  /* 无可读数据 */
    80004fa8:	557d                	li	a0,-1
}
    80004faa:	8082                	ret

0000000080004fac <uart_puts>:

void uart_puts(const char *s)
{
    while (*s)
    80004fac:	00054683          	lbu	a3,0(a0)
{
    80004fb0:	85aa                	mv	a1,a0
    while (*s)
    80004fb2:	c29d                	beqz	a3,80004fd8 <uart_puts+0x2c>
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80004fb4:	10000737          	lui	a4,0x10000
    if (c == '\n')
    80004fb8:	4629                	li	a2,10
        uart_putc(*s++);
    80004fba:	0585                	addi	a1,a1,1
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80004fbc:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80004fc0:	0207f793          	andi	a5,a5,32
    80004fc4:	dfe5                	beqz	a5,80004fbc <uart_puts+0x10>
    UART[UART_THR] = (uint8_t)c;
    80004fc6:	00d70023          	sb	a3,0(a4)
    if (c == '\n')
    80004fca:	00c69463          	bne	a3,a2,80004fd2 <uart_puts+0x26>
        uart_putc('\r');
    80004fce:	46b5                	li	a3,13
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80004fd0:	b7f5                	j	80004fbc <uart_puts+0x10>
    while (*s)
    80004fd2:	0005c683          	lbu	a3,0(a1)
    80004fd6:	f2f5                	bnez	a3,80004fba <uart_puts+0xe>
}
    80004fd8:	8082                	ret

0000000080004fda <uart_puthex>:

void uart_puthex(uint64_t val)
{
    const char hex[] = "0123456789abcdef";
    80004fda:	00001797          	auipc	a5,0x1
    80004fde:	0be78793          	addi	a5,a5,190 # 80006098 <__clz_tab+0x118>
    80004fe2:	6390                	ld	a2,0(a5)
    80004fe4:	6798                	ld	a4,8(a5)
    80004fe6:	0107c783          	lbu	a5,16(a5)
{
    80004fea:	7179                	addi	sp,sp,-48
    80004fec:	86aa                	mv	a3,a0
    const char hex[] = "0123456789abcdef";
    80004fee:	00f10823          	sb	a5,16(sp)
    80004ff2:	e032                	sd	a2,0(sp)
    80004ff4:	e43a                	sd	a4,8(sp)
    80004ff6:	082c                	addi	a1,sp,24
    80004ff8:	02710793          	addi	a5,sp,39
    char buf[17];
    int i;

    for (i = 15; i >= 0; i--) {
        buf[i] = hex[val & 0xf];
    80004ffc:	00f6f713          	andi	a4,a3,15
    80005000:	03070713          	addi	a4,a4,48
    80005004:	970a                	add	a4,a4,sp
    80005006:	fd074603          	lbu	a2,-48(a4)
    8000500a:	873e                	mv	a4,a5
        val >>= 4;
    8000500c:	8291                	srli	a3,a3,0x4
        buf[i] = hex[val & 0xf];
    8000500e:	00c78023          	sb	a2,0(a5)
    for (i = 15; i >= 0; i--) {
    80005012:	17fd                	addi	a5,a5,-1
    80005014:	fee594e3          	bne	a1,a4,80004ffc <uart_puthex+0x22>
    while (*s)
    80005018:	01814683          	lbu	a3,24(sp)
    }
    buf[16] = '\0';
    8000501c:	02010423          	sb	zero,40(sp)
    while (*s)
    80005020:	c29d                	beqz	a3,80005046 <uart_puthex+0x6c>
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80005022:	10000737          	lui	a4,0x10000
    if (c == '\n')
    80005026:	4629                	li	a2,10
        uart_putc(*s++);
    80005028:	0585                	addi	a1,a1,1
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    8000502a:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    8000502e:	0207f793          	andi	a5,a5,32
    80005032:	dfe5                	beqz	a5,8000502a <uart_puthex+0x50>
    UART[UART_THR] = (uint8_t)c;
    80005034:	00d70023          	sb	a3,0(a4)
    if (c == '\n')
    80005038:	00c69463          	bne	a3,a2,80005040 <uart_puthex+0x66>
        uart_putc('\r');
    8000503c:	46b5                	li	a3,13
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    8000503e:	b7f5                	j	8000502a <uart_puthex+0x50>
    while (*s)
    80005040:	0005c683          	lbu	a3,0(a1)
    80005044:	f2f5                	bnez	a3,80005028 <uart_puthex+0x4e>
    uart_puts(buf);
}
    80005046:	6145                	addi	sp,sp,48
    80005048:	8082                	ret

000000008000504a <uart_printf>:

void uart_printf(const char *fmt, ...)
{
    8000504a:	7125                	addi	sp,sp,-416
    8000504c:	e73e                	sd	a5,392(sp)
    8000504e:	eea2                	sd	s0,344(sp)
    80005050:	eaa6                	sd	s1,336(sp)
    80005052:	e6ca                	sd	s2,328(sp)
    80005054:	e2ce                	sd	s3,320(sp)
    80005056:	fe52                	sd	s4,312(sp)
    80005058:	fa56                	sd	s5,304(sp)
    8000505a:	f65a                	sd	s6,296(sp)
    8000505c:	f25e                	sd	s7,288(sp)
    8000505e:	f6ae                	sd	a1,360(sp)
    80005060:	fab2                	sd	a2,368(sp)
    80005062:	feb6                	sd	a3,376(sp)
    80005064:	e33a                	sd	a4,384(sp)
    80005066:	eb42                	sd	a6,400(sp)
    80005068:	ef46                	sd	a7,408(sp)

    va_start(args, fmt);
    /* 简单的格式化: 用 vsnprintf, 但嵌入式没有 stdio.h */
    /* 自己实现一个极简的 */
    len = 0;
    while (*fmt && len < (int)sizeof(buf) - 1) {
    8000506a:	00054703          	lbu	a4,0(a0)
    va_start(args, fmt);
    8000506e:	12bc                	addi	a5,sp,360
    80005070:	e03e                	sd	a5,0(sp)
    len = 0;
    80005072:	4781                	li	a5,0
    while (*fmt && len < (int)sizeof(buf) - 1) {
    80005074:	cb5d                	beqz	a4,8000512a <uart_printf+0xe0>
        if (*fmt == '%') {
    80005076:	02500593          	li	a1,37
            fmt++;
            switch (*fmt) {
    8000507a:	4f55                	li	t5,21
    8000507c:	00001897          	auipc	a7,0x1
    80005080:	eac88893          	addi	a7,a7,-340 # 80005f28 <main+0x196>
                unsigned long v = va_arg(args, unsigned int);
                char tmp[24];
                int tlen = 0, i;
                if (v == 0) tmp[tlen++] = '0';
                while (v > 0) {
                    tmp[tlen++] = '0' + (v % 10);
    80005084:	4629                	li	a2,10
                while (v > 0) {
    80005086:	4825                	li	a6,9
                if (v == 0) tmp[tlen++] = '0';
    80005088:	03000e13          	li	t3,48
                    buf[len++] = '-';
    8000508c:	02d00393          	li	t2,45
    80005090:	07500293          	li	t0,117
                    buf[len++] = 'l';
    80005094:	06c00993          	li	s3,108
    80005098:	07800913          	li	s2,120
                            buf[len++] = "0123456789abcdef"[nibble];
    8000509c:	00001f97          	auipc	t6,0x1
    800050a0:	ffcf8f93          	addi	t6,t6,-4 # 80006098 <__clz_tab+0x118>
                    for (shift = 60; shift >= 0; shift -= 4) {
    800050a4:	5371                	li	t1,-4
    800050a6:	06400493          	li	s1,100
    800050aa:	06900413          	li	s0,105
                while (*s && len < (int)sizeof(buf) - 1)
    800050ae:	0ff00e93          	li	t4,255
    800050b2:	a00d                	j	800050d4 <uart_printf+0x8a>
                buf[len++] = '%';
                buf[len++] = *fmt;
                break;
            }
        } else {
            buf[len++] = *fmt;
    800050b4:	12078693          	addi	a3,a5,288
    800050b8:	968a                	add	a3,a3,sp
    800050ba:	f0e68023          	sb	a4,-256(a3)
    800050be:	2785                	addiw	a5,a5,1
    800050c0:	86aa                	mv	a3,a0
    while (*fmt && len < (int)sizeof(buf) - 1) {
    800050c2:	0016c703          	lbu	a4,1(a3)
        }
        fmt++;
    800050c6:	00168513          	addi	a0,a3,1
    while (*fmt && len < (int)sizeof(buf) - 1) {
    800050ca:	c325                	beqz	a4,8000512a <uart_printf+0xe0>
    800050cc:	0fe00693          	li	a3,254
    800050d0:	04f6cd63          	blt	a3,a5,8000512a <uart_printf+0xe0>
            switch (*fmt) {
    800050d4:	00154a03          	lbu	s4,1(a0)
            fmt++;
    800050d8:	00150693          	addi	a3,a0,1
        if (*fmt == '%') {
    800050dc:	fcb71ce3          	bne	a4,a1,800050b4 <uart_printf+0x6a>
            switch (*fmt) {
    800050e0:	22ba0b63          	beq	s4,a1,80005316 <uart_printf+0x2cc>
    800050e4:	f9da071b          	addiw	a4,s4,-99
    800050e8:	0ff77713          	zext.b	a4,a4
    800050ec:	08ef6463          	bltu	t5,a4,80005174 <uart_printf+0x12a>
    800050f0:	070a                	slli	a4,a4,0x2
    800050f2:	9746                	add	a4,a4,a7
    800050f4:	4318                	lw	a4,0(a4)
    800050f6:	9746                	add	a4,a4,a7
    800050f8:	8702                	jr	a4
                const char *s = va_arg(args, const char *);
    800050fa:	6702                	ld	a4,0(sp)
    800050fc:	6308                	ld	a0,0(a4)
    800050fe:	0721                	addi	a4,a4,8
    80005100:	e03a                	sd	a4,0(sp)
                while (*s && len < (int)sizeof(buf) - 1)
    80005102:	00054703          	lbu	a4,0(a0)
    80005106:	df55                	beqz	a4,800050c2 <uart_printf+0x78>
    80005108:	01d78f63          	beq	a5,t4,80005126 <uart_printf+0xdc>
    8000510c:	02010a13          	addi	s4,sp,32
    80005110:	9a3e                	add	s4,s4,a5
                    buf[len++] = *s++;
    80005112:	0505                	addi	a0,a0,1
    80005114:	00ea0023          	sb	a4,0(s4)
                while (*s && len < (int)sizeof(buf) - 1)
    80005118:	00054703          	lbu	a4,0(a0)
                    buf[len++] = *s++;
    8000511c:	2785                	addiw	a5,a5,1
                while (*s && len < (int)sizeof(buf) - 1)
    8000511e:	d355                	beqz	a4,800050c2 <uart_printf+0x78>
    80005120:	0a05                	addi	s4,s4,1
    80005122:	ffd798e3          	bne	a5,t4,80005112 <uart_printf+0xc8>
    len = 0;
    80005126:	0ff00793          	li	a5,255
    }
    buf[len] = '\0';
    8000512a:	12078793          	addi	a5,a5,288
    8000512e:	978a                	add	a5,a5,sp
    80005130:	f0078023          	sb	zero,-256(a5)
    while (*s)
    80005134:	02014683          	lbu	a3,32(sp)
    80005138:	100c                	addi	a1,sp,32
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    8000513a:	10000737          	lui	a4,0x10000
    if (c == '\n')
    8000513e:	4629                	li	a2,10
    while (*s)
    80005140:	c285                	beqz	a3,80005160 <uart_printf+0x116>
        uart_putc(*s++);
    80005142:	0585                	addi	a1,a1,1
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80005144:	00574783          	lbu	a5,5(a4) # 10000005 <_start-0x6ffffffb>
    80005148:	0207f793          	andi	a5,a5,32
    8000514c:	dfe5                	beqz	a5,80005144 <uart_printf+0xfa>
    UART[UART_THR] = (uint8_t)c;
    8000514e:	00d70023          	sb	a3,0(a4)
    if (c == '\n')
    80005152:	00c69463          	bne	a3,a2,8000515a <uart_printf+0x110>
        uart_putc('\r');
    80005156:	46b5                	li	a3,13
    while (!(UART[UART_LSR] & UART_LSR_THRE))
    80005158:	b7f5                	j	80005144 <uart_printf+0xfa>
    while (*s)
    8000515a:	0005c683          	lbu	a3,0(a1)
    8000515e:	f2f5                	bnez	a3,80005142 <uart_printf+0xf8>
    va_end(args);

    uart_puts(buf);
}
    80005160:	6476                	ld	s0,344(sp)
    80005162:	64d6                	ld	s1,336(sp)
    80005164:	6936                	ld	s2,328(sp)
    80005166:	6996                	ld	s3,320(sp)
    80005168:	7a72                	ld	s4,312(sp)
    8000516a:	7ad2                	ld	s5,304(sp)
    8000516c:	7b32                	ld	s6,296(sp)
    8000516e:	7b92                	ld	s7,288(sp)
    80005170:	611d                	addi	sp,sp,416
    80005172:	8082                	ret
                buf[len++] = '%';
    80005174:	0017871b          	addiw	a4,a5,1
    80005178:	12078513          	addi	a0,a5,288
    8000517c:	950a                	add	a0,a0,sp
                buf[len++] = *fmt;
    8000517e:	12070713          	addi	a4,a4,288
                buf[len++] = '%';
    80005182:	f0b50023          	sb	a1,-256(a0)
                buf[len++] = *fmt;
    80005186:	970a                	add	a4,a4,sp
    80005188:	2789                	addiw	a5,a5,2
    8000518a:	f1470023          	sb	s4,-256(a4)
                break;
    8000518e:	bf15                	j	800050c2 <uart_printf+0x78>
                long v = va_arg(args, int);
    80005190:	6702                	ld	a4,0(sp)
    80005192:	00072b03          	lw	s6,0(a4)
    80005196:	0721                	addi	a4,a4,8
    80005198:	e03a                	sd	a4,0(sp)
                if (v < 0) {
    8000519a:	1a0b4763          	bltz	s6,80005348 <uart_printf+0x2fe>
                    u = (unsigned long)v;
    8000519e:	855a                	mv	a0,s6
                if (u == 0) tmp[tlen++] = '0';
    800051a0:	1a0b1c63          	bnez	s6,80005358 <uart_printf+0x30e>
    800051a4:	01c10423          	sb	t3,8(sp)
    800051a8:	03000713          	li	a4,48
                for (i = tlen - 1; i >= 0; i--)
    800051ac:	1008                	addi	a0,sp,32
    800051ae:	953e                	add	a0,a0,a5
    800051b0:	00810a13          	addi	s4,sp,8
    800051b4:	9a5a                	add	s4,s4,s6
    800051b6:	01650ab3          	add	s5,a0,s6
    800051ba:	a021                	j	800051c2 <uart_printf+0x178>
                    buf[len++] = tmp[i];
    800051bc:	000a4703          	lbu	a4,0(s4)
    800051c0:	0505                	addi	a0,a0,1
    800051c2:	00e50023          	sb	a4,0(a0)
                for (i = tlen - 1; i >= 0; i--)
    800051c6:	1a7d                	addi	s4,s4,-1
    800051c8:	feaa9ae3          	bne	s5,a0,800051bc <uart_printf+0x172>
    800051cc:	2785                	addiw	a5,a5,1
                    buf[len++] = tmp[i];
    800051ce:	016787bb          	addw	a5,a5,s6
                break;
    800051d2:	bdc5                	j	800050c2 <uart_printf+0x78>
                unsigned int v = va_arg(args, unsigned int);
    800051d4:	6702                	ld	a4,0(sp)
                int started = 0;
    800051d6:	4a01                	li	s4,0
                for (shift = 28; shift >= 0; shift -= 4) {
    800051d8:	4571                	li	a0,28
                unsigned int v = va_arg(args, unsigned int);
    800051da:	00072a83          	lw	s5,0(a4)
    800051de:	0721                	addi	a4,a4,8
    800051e0:	e03a                	sd	a4,0(sp)
    800051e2:	a029                	j	800051ec <uart_printf+0x1a2>
                    if (nibble || started || shift == 0) {
    800051e4:	c919                	beqz	a0,800051fa <uart_printf+0x1b0>
                for (shift = 28; shift >= 0; shift -= 4) {
    800051e6:	3571                	addiw	a0,a0,-4
    800051e8:	02650663          	beq	a0,t1,80005214 <uart_printf+0x1ca>
                    int nibble = (v >> shift) & 0xf;
    800051ec:	00aad73b          	srlw	a4,s5,a0
    800051f0:	8b3d                	andi	a4,a4,15
                    if (nibble || started || shift == 0) {
    800051f2:	01476a33          	or	s4,a4,s4
    800051f6:	fe0a07e3          	beqz	s4,800051e4 <uart_printf+0x19a>
                        buf[len++] = "0123456789abcdef"[nibble];
    800051fa:	977e                	add	a4,a4,t6
    800051fc:	00074b03          	lbu	s6,0(a4)
    80005200:	12078713          	addi	a4,a5,288
    80005204:	970a                	add	a4,a4,sp
    80005206:	f1670023          	sb	s6,-256(a4)
                for (shift = 28; shift >= 0; shift -= 4) {
    8000520a:	3571                	addiw	a0,a0,-4
                        started = 1;
    8000520c:	4a05                	li	s4,1
                        buf[len++] = "0123456789abcdef"[nibble];
    8000520e:	2785                	addiw	a5,a5,1
                for (shift = 28; shift >= 0; shift -= 4) {
    80005210:	fc651ee3          	bne	a0,t1,800051ec <uart_printf+0x1a2>
                    if (!started) buf[len++] = '0';
    80005214:	ea0a17e3          	bnez	s4,800050c2 <uart_printf+0x78>
    80005218:	12078713          	addi	a4,a5,288
    8000521c:	970a                	add	a4,a4,sp
    8000521e:	f1c70023          	sb	t3,-256(a4)
    80005222:	2785                	addiw	a5,a5,1
    80005224:	bd79                	j	800050c2 <uart_printf+0x78>
                unsigned long v = va_arg(args, unsigned int);
    80005226:	6702                	ld	a4,0(sp)
    80005228:	00076503          	lwu	a0,0(a4)
    8000522c:	0721                	addi	a4,a4,8
    8000522e:	e03a                	sd	a4,0(sp)
                if (v == 0) tmp[tlen++] = '0';
    80005230:	e975                	bnez	a0,80005324 <uart_printf+0x2da>
    80005232:	01c10423          	sb	t3,8(sp)
    80005236:	03000713          	li	a4,48
    8000523a:	4b01                	li	s6,0
                for (i = tlen - 1; i >= 0; i--)
    8000523c:	1008                	addi	a0,sp,32
    8000523e:	953e                	add	a0,a0,a5
    80005240:	00810a13          	addi	s4,sp,8
    80005244:	9a5a                	add	s4,s4,s6
    80005246:	01650ab3          	add	s5,a0,s6
    8000524a:	a021                	j	80005252 <uart_printf+0x208>
                    buf[len++] = tmp[i];
    8000524c:	000a4703          	lbu	a4,0(s4)
    80005250:	0505                	addi	a0,a0,1
    80005252:	00e50023          	sb	a4,0(a0)
                for (i = tlen - 1; i >= 0; i--)
    80005256:	1a7d                	addi	s4,s4,-1
    80005258:	ff551ae3          	bne	a0,s5,8000524c <uart_printf+0x202>
    8000525c:	2785                	addiw	a5,a5,1
                    buf[len++] = tmp[i];
    8000525e:	016787bb          	addw	a5,a5,s6
                break;
    80005262:	b585                	j	800050c2 <uart_printf+0x78>
                char c = (char)va_arg(args, int);
    80005264:	6702                	ld	a4,0(sp)
    80005266:	4308                	lw	a0,0(a4)
    80005268:	0721                	addi	a4,a4,8
    8000526a:	e03a                	sd	a4,0(sp)
    8000526c:	12078713          	addi	a4,a5,288
    80005270:	970a                	add	a4,a4,sp
    80005272:	f0a70023          	sb	a0,-256(a4)
    80005276:	2785                	addiw	a5,a5,1
                break;
    80005278:	b5a9                	j	800050c2 <uart_printf+0x78>
                switch (*fmt) {
    8000527a:	00254703          	lbu	a4,2(a0)
                fmt++;
    8000527e:	00250693          	addi	a3,a0,2
                switch (*fmt) {
    80005282:	12570263          	beq	a4,t0,800053a6 <uart_printf+0x35c>
    80005286:	04e2e763          	bltu	t0,a4,800052d4 <uart_printf+0x28a>
    8000528a:	00970463          	beq	a4,s1,80005292 <uart_printf+0x248>
    8000528e:	0e871763          	bne	a4,s0,8000537c <uart_printf+0x332>
                    long v = va_arg(args, long);
    80005292:	6502                	ld	a0,0(sp)
    80005294:	6118                	ld	a4,0(a0)
    80005296:	0521                	addi	a0,a0,8
    80005298:	e02a                	sd	a0,0(sp)
                    if (v < 0) {
    8000529a:	16074363          	bltz	a4,80005400 <uart_printf+0x3b6>
                    if (u == 0) tmp[tlen++] = '0';
    8000529e:	16071963          	bnez	a4,80005410 <uart_printf+0x3c6>
    800052a2:	01c10423          	sb	t3,8(sp)
    800052a6:	03000513          	li	a0,48
    800052aa:	4a01                	li	s4,0
                    for (i = tlen - 1; i >= 0; i--)
    800052ac:	1018                	addi	a4,sp,32
    800052ae:	973e                	add	a4,a4,a5
    800052b0:	00810a93          	addi	s5,sp,8
    800052b4:	9ad2                	add	s5,s5,s4
    800052b6:	01470b33          	add	s6,a4,s4
    800052ba:	a021                	j	800052c2 <uart_printf+0x278>
                        buf[len++] = tmp[i];
    800052bc:	000ac503          	lbu	a0,0(s5)
    800052c0:	0705                	addi	a4,a4,1
    800052c2:	00a70023          	sb	a0,0(a4)
                    for (i = tlen - 1; i >= 0; i--)
    800052c6:	1afd                	addi	s5,s5,-1
    800052c8:	ff671ae3          	bne	a4,s6,800052bc <uart_printf+0x272>
    800052cc:	2785                	addiw	a5,a5,1
                        buf[len++] = tmp[i];
    800052ce:	014787bb          	addw	a5,a5,s4
                    break;
    800052d2:	bbc5                	j	800050c2 <uart_printf+0x78>
    800052d4:	0b271463          	bne	a4,s2,8000537c <uart_printf+0x332>
                    unsigned long v = va_arg(args, unsigned long);
    800052d8:	6702                	ld	a4,0(sp)
                    int started = 0;
    800052da:	4a01                	li	s4,0
                    for (shift = 60; shift >= 0; shift -= 4) {
    800052dc:	03c00513          	li	a0,60
                    unsigned long v = va_arg(args, unsigned long);
    800052e0:	00073a83          	ld	s5,0(a4)
    800052e4:	0721                	addi	a4,a4,8
    800052e6:	e03a                	sd	a4,0(sp)
    800052e8:	a029                	j	800052f2 <uart_printf+0x2a8>
                        if (nibble || started || shift == 0) {
    800052ea:	c919                	beqz	a0,80005300 <uart_printf+0x2b6>
                    for (shift = 60; shift >= 0; shift -= 4) {
    800052ec:	3571                	addiw	a0,a0,-4
    800052ee:	f26503e3          	beq	a0,t1,80005214 <uart_printf+0x1ca>
                        int nibble = (v >> shift) & 0xf;
    800052f2:	00aad733          	srl	a4,s5,a0
    800052f6:	8b3d                	andi	a4,a4,15
                        if (nibble || started || shift == 0) {
    800052f8:	01476a33          	or	s4,a4,s4
    800052fc:	fe0a07e3          	beqz	s4,800052ea <uart_printf+0x2a0>
                            buf[len++] = "0123456789abcdef"[nibble];
    80005300:	977e                	add	a4,a4,t6
    80005302:	00074b03          	lbu	s6,0(a4)
    80005306:	12078713          	addi	a4,a5,288
    8000530a:	970a                	add	a4,a4,sp
                            started = 1;
    8000530c:	4a05                	li	s4,1
                            buf[len++] = "0123456789abcdef"[nibble];
    8000530e:	f1670023          	sb	s6,-256(a4)
    80005312:	2785                	addiw	a5,a5,1
    80005314:	bfe1                	j	800052ec <uart_printf+0x2a2>
                buf[len++] = '%';
    80005316:	12078713          	addi	a4,a5,288
    8000531a:	970a                	add	a4,a4,sp
    8000531c:	f0b70023          	sb	a1,-256(a4)
    80005320:	2785                	addiw	a5,a5,1
                break;
    80005322:	b345                	j	800050c2 <uart_printf+0x78>
    80005324:	00810a93          	addi	s5,sp,8
                int tlen = 0, i;
    80005328:	4a01                	li	s4,0
                    tmp[tlen++] = '0' + (v % 10);
    8000532a:	02c57733          	remu	a4,a0,a2
                while (v > 0) {
    8000532e:	0a85                	addi	s5,s5,1
    80005330:	8baa                	mv	s7,a0
    80005332:	8b52                	mv	s6,s4
                    tmp[tlen++] = '0' + (v % 10);
    80005334:	2a05                	addiw	s4,s4,1
    80005336:	03070713          	addi	a4,a4,48
    8000533a:	feea8fa3          	sb	a4,-1(s5)
                    v /= 10;
    8000533e:	02c55533          	divu	a0,a0,a2
                while (v > 0) {
    80005342:	ff7864e3          	bltu	a6,s7,8000532a <uart_printf+0x2e0>
    80005346:	bddd                	j	8000523c <uart_printf+0x1f2>
                    buf[len++] = '-';
    80005348:	12078713          	addi	a4,a5,288
    8000534c:	970a                	add	a4,a4,sp
    8000534e:	f0770023          	sb	t2,-256(a4)
                    u = -(unsigned long)v;
    80005352:	41600533          	neg	a0,s6
                    buf[len++] = '-';
    80005356:	2785                	addiw	a5,a5,1
                while (u > 0) {
    80005358:	00810a93          	addi	s5,sp,8
                    if (v == 0) tmp[tlen++] = '0';
    8000535c:	4a01                	li	s4,0
                    tmp[tlen++] = '0' + (u % 10);
    8000535e:	02c57733          	remu	a4,a0,a2
                while (u > 0) {
    80005362:	0a85                	addi	s5,s5,1
    80005364:	8baa                	mv	s7,a0
    80005366:	8b52                	mv	s6,s4
                    tmp[tlen++] = '0' + (u % 10);
    80005368:	2a05                	addiw	s4,s4,1
    8000536a:	03070713          	addi	a4,a4,48
    8000536e:	feea8fa3          	sb	a4,-1(s5)
                    u /= 10;
    80005372:	02c55533          	divu	a0,a0,a2
                while (u > 0) {
    80005376:	ff7864e3          	bltu	a6,s7,8000535e <uart_printf+0x314>
    8000537a:	bd0d                	j	800051ac <uart_printf+0x162>
                    buf[len++] = '%';
    8000537c:	12078513          	addi	a0,a5,288
    80005380:	950a                	add	a0,a0,sp
                    buf[len++] = 'l';
    80005382:	00178a1b          	addiw	s4,a5,1
                    buf[len++] = '%';
    80005386:	f0b50023          	sb	a1,-256(a0)
                    buf[len++] = 'l';
    8000538a:	120a0a13          	addi	s4,s4,288
    8000538e:	0027851b          	addiw	a0,a5,2
    80005392:	9a0a                	add	s4,s4,sp
                    buf[len++] = *fmt;
    80005394:	12050513          	addi	a0,a0,288
                    buf[len++] = 'l';
    80005398:	f13a0023          	sb	s3,-256(s4)
                    buf[len++] = *fmt;
    8000539c:	950a                	add	a0,a0,sp
    8000539e:	278d                	addiw	a5,a5,3
    800053a0:	f0e50023          	sb	a4,-256(a0)
                    break;
    800053a4:	bb39                	j	800050c2 <uart_printf+0x78>
                    unsigned long v = va_arg(args, unsigned long);
    800053a6:	6702                	ld	a4,0(sp)
    800053a8:	6308                	ld	a0,0(a4)
    800053aa:	0721                	addi	a4,a4,8
    800053ac:	e03a                	sd	a4,0(sp)
                    if (v == 0) tmp[tlen++] = '0';
    800053ae:	c139                	beqz	a0,800053f4 <uart_printf+0x3aa>
    800053b0:	00810b13          	addi	s6,sp,8
                    int tlen = 0, i;
    800053b4:	4a81                	li	s5,0
                        tmp[tlen++] = '0' + (v % 10);
    800053b6:	02c57733          	remu	a4,a0,a2
                    while (v > 0) {
    800053ba:	0b05                	addi	s6,s6,1 # 2000001 <_start-0x7dffffff>
    800053bc:	8baa                	mv	s7,a0
    800053be:	8a56                	mv	s4,s5
                        tmp[tlen++] = '0' + (v % 10);
    800053c0:	2a85                	addiw	s5,s5,1
    800053c2:	03070713          	addi	a4,a4,48
    800053c6:	feeb0fa3          	sb	a4,-1(s6)
                        v /= 10;
    800053ca:	02c55533          	divu	a0,a0,a2
                    while (v > 0) {
    800053ce:	ff7864e3          	bltu	a6,s7,800053b6 <uart_printf+0x36c>
                    for (i = tlen - 1; i >= 0; i--)
    800053d2:	1008                	addi	a0,sp,32
    800053d4:	953e                	add	a0,a0,a5
    800053d6:	00810a93          	addi	s5,sp,8
    800053da:	9ad2                	add	s5,s5,s4
    800053dc:	01450b33          	add	s6,a0,s4
    800053e0:	a021                	j	800053e8 <uart_printf+0x39e>
                        buf[len++] = tmp[i];
    800053e2:	000ac703          	lbu	a4,0(s5)
    800053e6:	0505                	addi	a0,a0,1
    800053e8:	00e50023          	sb	a4,0(a0)
                    for (i = tlen - 1; i >= 0; i--)
    800053ec:	1afd                	addi	s5,s5,-1
    800053ee:	ff651ae3          	bne	a0,s6,800053e2 <uart_printf+0x398>
    800053f2:	bde9                	j	800052cc <uart_printf+0x282>
                    if (v == 0) tmp[tlen++] = '0';
    800053f4:	01c10423          	sb	t3,8(sp)
    800053f8:	03000713          	li	a4,48
    800053fc:	4a01                	li	s4,0
    800053fe:	bfd1                	j	800053d2 <uart_printf+0x388>
                        buf[len++] = '-';
    80005400:	12078513          	addi	a0,a5,288
    80005404:	950a                	add	a0,a0,sp
    80005406:	f0750023          	sb	t2,-256(a0)
                        u = -(unsigned long)v;
    8000540a:	40e00733          	neg	a4,a4
                        buf[len++] = '-';
    8000540e:	2785                	addiw	a5,a5,1
                    while (u > 0) {
    80005410:	00810b13          	addi	s6,sp,8
                            started = 1;
    80005414:	4a81                	li	s5,0
                        tmp[tlen++] = '0' + (u % 10);
    80005416:	02c77533          	remu	a0,a4,a2
                    while (u > 0) {
    8000541a:	0b05                	addi	s6,s6,1
    8000541c:	8bba                	mv	s7,a4
    8000541e:	8a56                	mv	s4,s5
                        tmp[tlen++] = '0' + (u % 10);
    80005420:	2a85                	addiw	s5,s5,1
    80005422:	03050513          	addi	a0,a0,48
    80005426:	feab0fa3          	sb	a0,-1(s6)
                        u /= 10;
    8000542a:	02c75733          	divu	a4,a4,a2
                    while (u > 0) {
    8000542e:	ff7864e3          	bltu	a6,s7,80005416 <uart_printf+0x3cc>
    80005432:	bdad                	j	800052ac <uart_printf+0x262>

0000000080005434 <clint_init>:
    (volatile uint64_t *)CLINT_MTIMECMP(0);

void clint_init(void)
{
    /* 初始设置 mtimecmp 为一个很大的值, 禁止定时器中断 */
    clint_mtimecmp_h0[0] = UINT64_MAX;
    80005434:	020047b7          	lui	a5,0x2004
    80005438:	577d                	li	a4,-1
    8000543a:	e398                	sd	a4,0(a5)
}
    8000543c:	8082                	ret

000000008000543e <clint_set_mtimecmp>:

void clint_set_mtimecmp(uint64_t value)
{
    clint_mtimecmp_h0[0] = value;
    8000543e:	020047b7          	lui	a5,0x2004
    80005442:	e388                	sd	a0,0(a5)
}
    80005444:	8082                	ret

0000000080005446 <clint_get_time>:

uint64_t clint_get_time(void)
{
    return *clint_mtime;
    80005446:	0200c7b7          	lui	a5,0x200c
    8000544a:	ff87b503          	ld	a0,-8(a5) # 200bff8 <_start-0x7dff4008>
}
    8000544e:	8082                	ret

0000000080005450 <clint_set_tick>:
    return *clint_mtime;
    80005450:	0200c7b7          	lui	a5,0x200c
    80005454:	ff87b783          	ld	a5,-8(a5) # 200bff8 <_start-0x7dff4008>

void clint_set_tick(uint64_t tick_interval)
{
    uint64_t current = clint_get_time();
    clint_set_mtimecmp(current + tick_interval);
    80005458:	953e                	add	a0,a0,a5
    clint_mtimecmp_h0[0] = value;
    8000545a:	020047b7          	lui	a5,0x2004
    8000545e:	e388                	sd	a0,0(a5)
}
    80005460:	8082                	ret

0000000080005462 <clint_clear_timer_int>:
    return *clint_mtime;
    80005462:	0200c7b7          	lui	a5,0x200c
    80005466:	ff87b783          	ld	a5,-8(a5) # 200bff8 <_start-0x7dff4008>
{
    /* 清除定时器中断 = 设置新的 mtimecmp */
    uint64_t current = clint_get_time();

    /* 先设为 UINT64_MAX 防止在设置期间重复触发 */
    clint_mtimecmp_h0[0] = UINT64_MAX;
    8000546a:	020046b7          	lui	a3,0x2004
    8000546e:	577d                	li	a4,-1
    80005470:	e298                	sd	a4,0(a3)

    /* 重新设置 */
    clint_mtimecmp_h0[0] = current + CLINT_DEFAULT_TICK_US;
    80005472:	6709                	lui	a4,0x2
    80005474:	71070713          	addi	a4,a4,1808 # 2710 <_start-0x7fffd8f0>
    80005478:	97ba                	add	a5,a5,a4
    8000547a:	e29c                	sd	a5,0(a3)
}
    8000547c:	8082                	ret

000000008000547e <plic_init>:
#define CURRENT_HART  0  /* 单核, hart 0 */

void plic_init(void)
{
    /* 设置中断阈值, 禁止所有优先级 < threshold 的中断 */
    *PLIC_THRESHOLD_REG(CURRENT_HART) = 0;  /* 允许所有中断 */
    8000547e:	0c2007b7          	lui	a5,0xc200
    80005482:	0007a023          	sw	zero,0(a5) # c200000 <_start-0x73e00000>

    /* 默认所有中断优先级为 0 (最低) */
    /* 在使能具体中断时再设置优先级 */
}
    80005486:	8082                	ret

0000000080005488 <plic_enable_irq>:

void plic_enable_irq(int irq)
{
    volatile uint32_t *enable = PLIC_ENABLE_BASE(CURRENT_HART);

    if (irq < 0 || irq > PLIC_MAX_IRQ)
    80005488:	07f00793          	li	a5,127
    8000548c:	02a7e063          	bltu	a5,a0,800054ac <plic_enable_irq+0x24>
        return;

    enable[irq / 32] |= (1UL << (irq % 32));
    80005490:	40555793          	srai	a5,a0,0x5
    80005494:	078a                	slli	a5,a5,0x2
    80005496:	0c002737          	lui	a4,0xc002
    8000549a:	973e                	add	a4,a4,a5
    8000549c:	4314                	lw	a3,0(a4)
    8000549e:	897d                	andi	a0,a0,31
    800054a0:	4785                	li	a5,1
    800054a2:	00a797b3          	sll	a5,a5,a0
    800054a6:	8fd5                	or	a5,a5,a3
    800054a8:	2781                	sext.w	a5,a5
    800054aa:	c31c                	sw	a5,0(a4)
}
    800054ac:	8082                	ret

00000000800054ae <plic_disable_irq>:

void plic_disable_irq(int irq)
{
    volatile uint32_t *enable = PLIC_ENABLE_BASE(CURRENT_HART);

    if (irq < 0 || irq > PLIC_MAX_IRQ)
    800054ae:	07f00793          	li	a5,127
    800054b2:	02a7e263          	bltu	a5,a0,800054d6 <plic_disable_irq+0x28>
        return;

    enable[irq / 32] &= ~(1UL << (irq % 32));
    800054b6:	40555793          	srai	a5,a0,0x5
    800054ba:	078a                	slli	a5,a5,0x2
    800054bc:	0c002737          	lui	a4,0xc002
    800054c0:	973e                	add	a4,a4,a5
    800054c2:	4314                	lw	a3,0(a4)
    800054c4:	897d                	andi	a0,a0,31
    800054c6:	4785                	li	a5,1
    800054c8:	00a797b3          	sll	a5,a5,a0
    800054cc:	fff7c793          	not	a5,a5
    800054d0:	8ff5                	and	a5,a5,a3
    800054d2:	2781                	sext.w	a5,a5
    800054d4:	c31c                	sw	a5,0(a4)
}
    800054d6:	8082                	ret

00000000800054d8 <plic_set_priority>:

void plic_set_priority(int irq, uint32_t priority)
{
    volatile uint32_t *prio = PLIC_PRIORITY_BASE;

    if (irq < 0 || irq > PLIC_MAX_IRQ || priority > 7)
    800054d8:	07f00793          	li	a5,127
    800054dc:	00a7ea63          	bltu	a5,a0,800054f0 <plic_set_priority+0x18>
    800054e0:	479d                	li	a5,7
    800054e2:	00b7e763          	bltu	a5,a1,800054f0 <plic_set_priority+0x18>
        return;

    prio[irq] = priority;
    800054e6:	050a                	slli	a0,a0,0x2
    800054e8:	0c0007b7          	lui	a5,0xc000
    800054ec:	97aa                	add	a5,a5,a0
    800054ee:	c38c                	sw	a1,0(a5)
}
    800054f0:	8082                	ret

00000000800054f2 <plic_set_threshold>:

void plic_set_threshold(uint32_t threshold)
{
    *PLIC_THRESHOLD_REG(CURRENT_HART) = threshold;
    800054f2:	0c2007b7          	lui	a5,0xc200
    800054f6:	c388                	sw	a0,0(a5)
}
    800054f8:	8082                	ret

00000000800054fa <plic_claim>:

int plic_claim(void)
{
    return (int)*PLIC_CLAIM_REG(CURRENT_HART);
    800054fa:	0c2007b7          	lui	a5,0xc200
    800054fe:	43c8                	lw	a0,4(a5)
}
    80005500:	8082                	ret

0000000080005502 <plic_complete>:

void plic_complete(int irq)
{
    *PLIC_CLAIM_REG(CURRENT_HART) = (uint32_t)irq;
    80005502:	0c2007b7          	lui	a5,0xc200
    80005506:	c3c8                	sw	a0,4(a5)
}
    80005508:	8082                	ret

000000008000550a <vTaskHeartbeat>:

/**
 * Task 1: 心跳任务 — 定期输出心跳计数
 */
void vTaskHeartbeat(void *pvParameters)
{
    8000550a:	1101                	addi	sp,sp,-32
    8000550c:	e822                	sd	s0,16(sp)
    8000550e:	e426                	sd	s1,8(sp)
    80005510:	ec06                	sd	ra,24(sp)
    uint32_t count = 0;
    80005512:	4401                	li	s0,0

    (void)pvParameters;

    while (1) {
        uart_printf("[HB] count=0x%x\n", count++);
    80005514:	00001497          	auipc	s1,0x1
    80005518:	b9c48493          	addi	s1,s1,-1124 # 800060b0 <__clz_tab+0x130>
    8000551c:	85a2                	mv	a1,s0
    8000551e:	8526                	mv	a0,s1
    80005520:	00000097          	auipc	ra,0x0
    80005524:	b2a080e7          	jalr	-1238(ra) # 8000504a <uart_printf>
        vTaskDelay(pdMS_TO_TICKS(2000));
    80005528:	0c800513          	li	a0,200
        uart_printf("[HB] count=0x%x\n", count++);
    8000552c:	2405                	addiw	s0,s0,1
        vTaskDelay(pdMS_TO_TICKS(2000));
    8000552e:	ffffc097          	auipc	ra,0xffffc
    80005532:	ad6080e7          	jalr	-1322(ra) # 80001004 <vTaskDelay>
    while (1) {
    80005536:	b7dd                	j	8000551c <vTaskHeartbeat+0x12>

0000000080005538 <vTaskInfo>:

/**
 * Task 2: 信息任务 — 输出系统信息
 */
void vTaskInfo(void *pvParameters)
{
    80005538:	711d                	addi	sp,sp,-96
    8000553a:	ec86                	sd	ra,88(sp)
    8000553c:	e8a2                	sd	s0,80(sp)
    8000553e:	e4a6                	sd	s1,72(sp)
    80005540:	e0ca                	sd	s2,64(sp)
    80005542:	fc4e                	sd	s3,56(sp)
    80005544:	f852                	sd	s4,48(sp)
    80005546:	f456                	sd	s5,40(sp)
    80005548:	f05a                	sd	s6,32(sp)
    8000554a:	ec5e                	sd	s7,24(sp)
    8000554c:	e862                	sd	s8,16(sp)
    8000554e:	e466                	sd	s9,8(sp)
    uint64_t mhartid, marchid, mimpid;

    (void)pvParameters;

    __asm__ volatile("csrr %0, mhartid"  : "=r"(mhartid));
    80005550:	f1402cf3          	csrr	s9,mhartid
    __asm__ volatile("csrr %0, marchid"  : "=r"(marchid));
    80005554:	f1202c73          	csrr	s8,marchid
    __asm__ volatile("csrr %0, mimpid"   : "=r"(mimpid));
    80005558:	f1302bf3          	csrr	s7,mimpid

    vTaskDelay(pdMS_TO_TICKS(500));  /* 让心跳先跑 */
    8000555c:	03200513          	li	a0,50
    80005560:	ffffc097          	auipc	ra,0xffffc
    80005564:	aa4080e7          	jalr	-1372(ra) # 80001004 <vTaskDelay>

    while (1) {
        uart_puts("---[INFO]---\n");
    80005568:	00001b17          	auipc	s6,0x1
    8000556c:	b60b0b13          	addi	s6,s6,-1184 # 800060c8 <__clz_tab+0x148>
        uart_printf("  mhartid: 0x%lx\n", (unsigned long)mhartid);
    80005570:	00001a97          	auipc	s5,0x1
    80005574:	b68a8a93          	addi	s5,s5,-1176 # 800060d8 <__clz_tab+0x158>
        uart_printf("  marchid: 0x%lx\n", (unsigned long)marchid);
    80005578:	00001a17          	auipc	s4,0x1
    8000557c:	b78a0a13          	addi	s4,s4,-1160 # 800060f0 <__clz_tab+0x170>
        uart_printf("  mimpid:  0x%lx\n", (unsigned long)mimpid);
    80005580:	00001997          	auipc	s3,0x1
    80005584:	b8898993          	addi	s3,s3,-1144 # 80006108 <__clz_tab+0x188>
        uart_printf("  Tick Hz: %d\n", (int)configTICK_RATE_HZ);
    80005588:	00001917          	auipc	s2,0x1
    8000558c:	b9890913          	addi	s2,s2,-1128 # 80006120 <__clz_tab+0x1a0>
        uart_printf("  Heap:    %d bytes free\n",
    80005590:	00001497          	auipc	s1,0x1
    80005594:	ba048493          	addi	s1,s1,-1120 # 80006130 <__clz_tab+0x1b0>
                    (int)xPortGetFreeHeapSize());
        uart_puts("------------\n");
    80005598:	00001417          	auipc	s0,0x1
    8000559c:	bb840413          	addi	s0,s0,-1096 # 80006150 <__clz_tab+0x1d0>
        uart_puts("---[INFO]---\n");
    800055a0:	855a                	mv	a0,s6
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	a0a080e7          	jalr	-1526(ra) # 80004fac <uart_puts>
        uart_printf("  mhartid: 0x%lx\n", (unsigned long)mhartid);
    800055aa:	85e6                	mv	a1,s9
    800055ac:	8556                	mv	a0,s5
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	a9c080e7          	jalr	-1380(ra) # 8000504a <uart_printf>
        uart_printf("  marchid: 0x%lx\n", (unsigned long)marchid);
    800055b6:	85e2                	mv	a1,s8
    800055b8:	8552                	mv	a0,s4
    800055ba:	00000097          	auipc	ra,0x0
    800055be:	a90080e7          	jalr	-1392(ra) # 8000504a <uart_printf>
        uart_printf("  mimpid:  0x%lx\n", (unsigned long)mimpid);
    800055c2:	85de                	mv	a1,s7
    800055c4:	854e                	mv	a0,s3
    800055c6:	00000097          	auipc	ra,0x0
    800055ca:	a84080e7          	jalr	-1404(ra) # 8000504a <uart_printf>
        uart_printf("  Tick Hz: %d\n", (int)configTICK_RATE_HZ);
    800055ce:	06400593          	li	a1,100
    800055d2:	854a                	mv	a0,s2
    800055d4:	00000097          	auipc	ra,0x0
    800055d8:	a76080e7          	jalr	-1418(ra) # 8000504a <uart_printf>
                    (int)xPortGetFreeHeapSize());
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	6a0080e7          	jalr	1696(ra) # 80004c7c <xPortGetFreeHeapSize>
        uart_printf("  Heap:    %d bytes free\n",
    800055e4:	0005059b          	sext.w	a1,a0
    800055e8:	8526                	mv	a0,s1
    800055ea:	00000097          	auipc	ra,0x0
    800055ee:	a60080e7          	jalr	-1440(ra) # 8000504a <uart_printf>
        uart_puts("------------\n");
    800055f2:	8522                	mv	a0,s0
    800055f4:	00000097          	auipc	ra,0x0
    800055f8:	9b8080e7          	jalr	-1608(ra) # 80004fac <uart_puts>
        vTaskDelay(pdMS_TO_TICKS(10000));
    800055fc:	3e800513          	li	a0,1000
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	a04080e7          	jalr	-1532(ra) # 80001004 <vTaskDelay>
    while (1) {
    80005608:	bf61                	j	800055a0 <vTaskInfo+0x68>

000000008000560a <vTaskEcho>:

/**
 * Task 3: 回显任务 — 通过 UART 接收字符并回显
 */
void vTaskEcho(void *pvParameters)
{
    8000560a:	7179                	addi	sp,sp,-48
    (void)pvParameters;

    uart_puts("[ECHO] Enter characters (will echo back):\n");
    8000560c:	00001517          	auipc	a0,0x1
    80005610:	b5450513          	addi	a0,a0,-1196 # 80006160 <__clz_tab+0x1e0>
{
    80005614:	ec26                	sd	s1,24(sp)
    80005616:	e84a                	sd	s2,16(sp)
    80005618:	e44e                	sd	s3,8(sp)
    8000561a:	f406                	sd	ra,40(sp)
    8000561c:	f022                	sd	s0,32(sp)
    while (1) {
        int c = uart_getc_nonblock();
        if (c >= 0) {
            uart_putc((char)c);
            /* 回显时加换行方便查看 */
            if (c == '\r' || c == '\n')
    8000561e:	4935                	li	s2,13
    uart_puts("[ECHO] Enter characters (will echo back):\n");
    80005620:	00000097          	auipc	ra,0x0
    80005624:	98c080e7          	jalr	-1652(ra) # 80004fac <uart_puts>
                uart_puts("> ");
    80005628:	00001497          	auipc	s1,0x1
    8000562c:	b6848493          	addi	s1,s1,-1176 # 80006190 <__clz_tab+0x210>
            if (c == '\r' || c == '\n')
    80005630:	49a9                	li	s3,10
    80005632:	a801                	j	80005642 <vTaskEcho+0x38>
    80005634:	03340763          	beq	s0,s3,80005662 <vTaskEcho+0x58>
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    80005638:	4505                	li	a0,1
    8000563a:	ffffc097          	auipc	ra,0xffffc
    8000563e:	9ca080e7          	jalr	-1590(ra) # 80001004 <vTaskDelay>
        int c = uart_getc_nonblock();
    80005642:	00000097          	auipc	ra,0x0
    80005646:	954080e7          	jalr	-1708(ra) # 80004f96 <uart_getc_nonblock>
    8000564a:	842a                	mv	s0,a0
            uart_putc((char)c);
    8000564c:	0ff57513          	zext.b	a0,a0
        if (c >= 0) {
    80005650:	fe0444e3          	bltz	s0,80005638 <vTaskEcho+0x2e>
            uart_putc((char)c);
    80005654:	00000097          	auipc	ra,0x0
    80005658:	912080e7          	jalr	-1774(ra) # 80004f66 <uart_putc>
                uart_puts("> ");
    8000565c:	8526                	mv	a0,s1
            if (c == '\r' || c == '\n')
    8000565e:	fd241be3          	bne	s0,s2,80005634 <vTaskEcho+0x2a>
                uart_puts("> ");
    80005662:	00000097          	auipc	ra,0x0
    80005666:	94a080e7          	jalr	-1718(ra) # 80004fac <uart_puts>
    8000566a:	b7f9                	j	80005638 <vTaskEcho+0x2e>

000000008000566c <vTaskPciTest>:

/**
 * Task 4: PCI 测试任务 — 扫描并验证 SmartEth PCIe 设备
 */
void vTaskPciTest(void *pvParameters)
{
    8000566c:	1141                	addi	sp,sp,-16
    (void)pvParameters;

    /* 给其他任务一些时间输出 */
    vTaskDelay(pdMS_TO_TICKS(1000));
    8000566e:	06400513          	li	a0,100
{
    80005672:	e406                	sd	ra,8(sp)
    vTaskDelay(pdMS_TO_TICKS(1000));
    80005674:	ffffc097          	auipc	ra,0xffffc
    80005678:	990080e7          	jalr	-1648(ra) # 80001004 <vTaskDelay>

    uart_puts("\n");
    8000567c:	00001517          	auipc	a0,0x1
    80005680:	19450513          	addi	a0,a0,404 # 80006810 <__clz_tab+0x890>
    80005684:	00000097          	auipc	ra,0x0
    80005688:	928080e7          	jalr	-1752(ra) # 80004fac <uart_puts>
    uart_puts("========================================\n");
    8000568c:	00001517          	auipc	a0,0x1
    80005690:	b0c50513          	addi	a0,a0,-1268 # 80006198 <__clz_tab+0x218>
    80005694:	00000097          	auipc	ra,0x0
    80005698:	918080e7          	jalr	-1768(ra) # 80004fac <uart_puts>
    uart_puts("  PCIe Device Test Phase 2\n");
    8000569c:	00001517          	auipc	a0,0x1
    800056a0:	b2c50513          	addi	a0,a0,-1236 # 800061c8 <__clz_tab+0x248>
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	908080e7          	jalr	-1784(ra) # 80004fac <uart_puts>
    uart_puts("========================================\n");
    800056ac:	00001517          	auipc	a0,0x1
    800056b0:	aec50513          	addi	a0,a0,-1300 # 80006198 <__clz_tab+0x218>
    800056b4:	00000097          	auipc	ra,0x0
    800056b8:	8f8080e7          	jalr	-1800(ra) # 80004fac <uart_puts>

    /* 扫描 PCIe 总线，寻找 SmartEth 设备 */
    uint64_t bar0 = smarteth_pci_scan();
    800056bc:	00000097          	auipc	ra,0x0
    800056c0:	144080e7          	jalr	324(ra) # 80005800 <smarteth_pci_scan>

    if (bar0 != 0) {
    800056c4:	c505                	beqz	a0,800056ec <vTaskPciTest+0x80>
        /* 设备存在 → 运行完整测试 */
        smarteth_run_tests(bar0);
    800056c6:	00000097          	auipc	ra,0x0
    800056ca:	31c080e7          	jalr	796(ra) # 800059e2 <smarteth_run_tests>
    } else {
        uart_puts("[PCI] SmartEth device not present (expected without -device)\n");
    }

    uart_puts("[PCI] Test task complete, deleting self.\n");
    800056ce:	00001517          	auipc	a0,0x1
    800056d2:	b5a50513          	addi	a0,a0,-1190 # 80006228 <__clz_tab+0x2a8>
    800056d6:	00000097          	auipc	ra,0x0
    800056da:	8d6080e7          	jalr	-1834(ra) # 80004fac <uart_puts>

    /* 任务已完成，自删除 */
    vTaskDelete(NULL);
}
    800056de:	60a2                	ld	ra,8(sp)
    vTaskDelete(NULL);
    800056e0:	4501                	li	a0,0
}
    800056e2:	0141                	addi	sp,sp,16
    vTaskDelete(NULL);
    800056e4:	ffffb317          	auipc	t1,0xffffb
    800056e8:	71c30067          	jr	1820(t1) # 80000e00 <vTaskDelete>
        uart_puts("[PCI] SmartEth device not present (expected without -device)\n");
    800056ec:	00001517          	auipc	a0,0x1
    800056f0:	afc50513          	addi	a0,a0,-1284 # 800061e8 <__clz_tab+0x268>
    800056f4:	00000097          	auipc	ra,0x0
    800056f8:	8b8080e7          	jalr	-1864(ra) # 80004fac <uart_puts>
    uart_puts("[PCI] Test task complete, deleting self.\n");
    800056fc:	00001517          	auipc	a0,0x1
    80005700:	b2c50513          	addi	a0,a0,-1236 # 80006228 <__clz_tab+0x2a8>
    80005704:	00000097          	auipc	ra,0x0
    80005708:	8a8080e7          	jalr	-1880(ra) # 80004fac <uart_puts>
}
    8000570c:	60a2                	ld	ra,8(sp)
    vTaskDelete(NULL);
    8000570e:	4501                	li	a0,0
}
    80005710:	0141                	addi	sp,sp,16
    vTaskDelete(NULL);
    80005712:	ffffb317          	auipc	t1,0xffffb
    80005716:	6ee30067          	jr	1774(t1) # 80000e00 <vTaskDelete>

000000008000571a <vApplicationTickHook>:
/* ========== FreeRTOS 钩子函数 ========== */

void vApplicationTickHook(void)
{
    /* 定时器钩子, 当前未使用 */
}
    8000571a:	8082                	ret

000000008000571c <vApplicationIdleHook>:
    8000571c:	8082                	ret

000000008000571e <vApplicationMallocFailedHook>:
{
    /* 空闲任务钩子, 可进入低功耗 */
}

void vApplicationMallocFailedHook(void)
{
    8000571e:	1141                	addi	sp,sp,-16
    80005720:	e406                	sd	ra,8(sp)
    taskDISABLE_INTERRUPTS();
    80005722:	30047073          	csrci	mstatus,8
    uart_puts("[FATAL] Malloc failed!\n");
    80005726:	00001517          	auipc	a0,0x1
    8000572a:	b3250513          	addi	a0,a0,-1230 # 80006258 <__clz_tab+0x2d8>
    8000572e:	00000097          	auipc	ra,0x0
    80005732:	87e080e7          	jalr	-1922(ra) # 80004fac <uart_puts>
    for (;;)
    80005736:	a001                	j	80005736 <vApplicationMallocFailedHook+0x18>

0000000080005738 <vAssertCalled>:
        ;
}

void vAssertCalled(const char *pcFile, unsigned long ulLine)
{
    80005738:	1141                	addi	sp,sp,-16
    8000573a:	e406                	sd	ra,8(sp)
    8000573c:	87aa                	mv	a5,a0
    8000573e:	862e                	mv	a2,a1
    taskDISABLE_INTERRUPTS();
    80005740:	30047073          	csrci	mstatus,8
    uart_printf("[ASSERT] %s:%lx\n", pcFile, (unsigned long)ulLine);
    80005744:	00001517          	auipc	a0,0x1
    80005748:	b2c50513          	addi	a0,a0,-1236 # 80006270 <__clz_tab+0x2f0>
    8000574c:	85be                	mv	a1,a5
    8000574e:	00000097          	auipc	ra,0x0
    80005752:	8fc080e7          	jalr	-1796(ra) # 8000504a <uart_printf>
    for (;;)
    80005756:	a001                	j	80005756 <vAssertCalled+0x1e>

0000000080005758 <freertos_risc_v_application_interrupt_handler>:
}

/* ========== 外部中断处理 ========== */

void freertos_risc_v_application_interrupt_handler(void)
{
    80005758:	1141                	addi	sp,sp,-16
    8000575a:	e406                	sd	ra,8(sp)
    8000575c:	e022                	sd	s0,0(sp)
    /* 读取 PLIC claim → 获取中断源 */
    int irq = plic_claim();
    8000575e:	00000097          	auipc	ra,0x0
    80005762:	d9c080e7          	jalr	-612(ra) # 800054fa <plic_claim>

    if (irq > 0) {
    80005766:	02a05f63          	blez	a0,800057a4 <freertos_risc_v_application_interrupt_handler+0x4c>
        switch (irq) {
    8000576a:	47a9                	li	a5,10
    8000576c:	842a                	mv	s0,a0
    8000576e:	00f51a63          	bne	a0,a5,80005782 <freertos_risc_v_application_interrupt_handler+0x2a>
        default:
            uart_printf("[IRQ] unhandled irq=%d\n", irq);
            break;
        }

        plic_complete(irq);
    80005772:	8522                	mv	a0,s0
    }
}
    80005774:	6402                	ld	s0,0(sp)
    80005776:	60a2                	ld	ra,8(sp)
    80005778:	0141                	addi	sp,sp,16
        plic_complete(irq);
    8000577a:	00000317          	auipc	t1,0x0
    8000577e:	d8830067          	jr	-632(t1) # 80005502 <plic_complete>
            uart_printf("[IRQ] unhandled irq=%d\n", irq);
    80005782:	85aa                	mv	a1,a0
    80005784:	00001517          	auipc	a0,0x1
    80005788:	b0450513          	addi	a0,a0,-1276 # 80006288 <__clz_tab+0x308>
    8000578c:	00000097          	auipc	ra,0x0
    80005790:	8be080e7          	jalr	-1858(ra) # 8000504a <uart_printf>
        plic_complete(irq);
    80005794:	8522                	mv	a0,s0
}
    80005796:	6402                	ld	s0,0(sp)
    80005798:	60a2                	ld	ra,8(sp)
    8000579a:	0141                	addi	sp,sp,16
        plic_complete(irq);
    8000579c:	00000317          	auipc	t1,0x0
    800057a0:	d6630067          	jr	-666(t1) # 80005502 <plic_complete>
}
    800057a4:	60a2                	ld	ra,8(sp)
    800057a6:	6402                	ld	s0,0(sp)
    800057a8:	0141                	addi	sp,sp,16
    800057aa:	8082                	ret

00000000800057ac <memset>:

void *memset(void *s, int c, size_t n)
{
    unsigned char *p = (unsigned char *)s;
    while (n--)
        *p++ = (unsigned char)c;
    800057ac:	0ff5f593          	zext.b	a1,a1
    800057b0:	00c50733          	add	a4,a0,a2
    unsigned char *p = (unsigned char *)s;
    800057b4:	87aa                	mv	a5,a0
    while (n--)
    800057b6:	c611                	beqz	a2,800057c2 <memset+0x16>
        *p++ = (unsigned char)c;
    800057b8:	0785                	addi	a5,a5,1 # c200001 <_start-0x73dfffff>
    800057ba:	feb78fa3          	sb	a1,-1(a5)
    while (n--)
    800057be:	fee79de3          	bne	a5,a4,800057b8 <memset+0xc>
    return s;
}
    800057c2:	8082                	ret

00000000800057c4 <memcpy>:

void *memcpy(void *dest, const void *src, size_t n)
{
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;
    while (n--)
    800057c4:	ca19                	beqz	a2,800057da <memcpy+0x16>
    800057c6:	962a                	add	a2,a2,a0
    unsigned char *d = (unsigned char *)dest;
    800057c8:	87aa                	mv	a5,a0
        *d++ = *s++;
    800057ca:	0005c703          	lbu	a4,0(a1)
    800057ce:	0785                	addi	a5,a5,1
    800057d0:	0585                	addi	a1,a1,1
    800057d2:	fee78fa3          	sb	a4,-1(a5)
    while (n--)
    800057d6:	fec79ae3          	bne	a5,a2,800057ca <memcpy+0x6>
    return dest;
}
    800057da:	8082                	ret

00000000800057dc <memcmp>:

int memcmp(const void *s1, const void *s2, size_t n)
{
    const unsigned char *p1 = (const unsigned char *)s1;
    const unsigned char *p2 = (const unsigned char *)s2;
    while (n--) {
    800057dc:	c205                	beqz	a2,800057fc <memcmp+0x20>
    800057de:	962e                	add	a2,a2,a1
    800057e0:	a019                	j	800057e6 <memcmp+0xa>
    800057e2:	00c58d63          	beq	a1,a2,800057fc <memcmp+0x20>
        if (*p1 != *p2)
    800057e6:	00054783          	lbu	a5,0(a0)
    800057ea:	0005c703          	lbu	a4,0(a1)
            return *p1 - *p2;
        p1++;
    800057ee:	0505                	addi	a0,a0,1
        p2++;
    800057f0:	0585                	addi	a1,a1,1
        if (*p1 != *p2)
    800057f2:	fee788e3          	beq	a5,a4,800057e2 <memcmp+0x6>
            return *p1 - *p2;
    800057f6:	40e7853b          	subw	a0,a5,a4
    800057fa:	8082                	ret
    }
    return 0;
    800057fc:	4501                	li	a0,0
}
    800057fe:	8082                	ret

0000000080005800 <smarteth_pci_scan>:
}

/* ========== Device scan ========== */

uint64_t smarteth_pci_scan(void)
{
    80005800:	711d                	addi	sp,sp,-96
    80005802:	e4a6                	sd	s1,72(sp)
    80005804:	e862                	sd	s8,16(sp)
    uart_puts("[PCI] Scanning for SmartEth device...\n");
    80005806:	00001517          	auipc	a0,0x1
    8000580a:	b6a50513          	addi	a0,a0,-1174 # 80006370 <__clz_tab+0x3f0>

    for (int dev = 0; dev < 32; dev++) {
        uint16_t vendor = pci_config_read16(0, dev, 0, PCI_VENDOR_ID);

        if (vendor == 0xFFFF || vendor == 0x0000)
    8000580e:	6c41                	lui	s8,0x10
        uint8_t hdr_type = pci_config_read8(0, dev, 0, 0x0E);

        uart_printf("  Dev %d: vendor=0x%x device=0x%x hdr=0x%x\n",
                    dev, vendor, device, hdr_type);

        if (vendor == SMARTETH_VENDOR_ID && device == SMARTETH_DEVICE_ID) {
    80005810:	6489                	lui	s1,0x2
{
    80005812:	e0ca                	sd	s2,64(sp)
    80005814:	fc4e                	sd	s3,56(sp)
    80005816:	ec5e                	sd	s7,24(sp)
    80005818:	e466                	sd	s9,8(sp)
    8000581a:	e06a                	sd	s10,0(sp)
    8000581c:	ec86                	sd	ra,88(sp)
    8000581e:	e8a2                	sd	s0,80(sp)
    80005820:	f852                	sd	s4,48(sp)
    80005822:	f456                	sd	s5,40(sp)
    80005824:	f05a                	sd	s6,32(sp)
        if (vendor == 0xFFFF || vendor == 0x0000)
    80005826:	ffdc0d13          	addi	s10,s8,-3 # fffd <_start-0x7fff0003>
    uart_puts("[PCI] Scanning for SmartEth device...\n");
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	782080e7          	jalr	1922(ra) # 80004fac <uart_puts>
    for (int dev = 0; dev < 32; dev++) {
    80005832:	4981                	li	s3,0
    return ecam[addr >> 2];
    80005834:	30000bb7          	lui	s7,0x30000
        uart_printf("  Dev %d: vendor=0x%x device=0x%x hdr=0x%x\n",
    80005838:	1c7d                	addi	s8,s8,-1
    8000583a:	00001c97          	auipc	s9,0x1
    8000583e:	b5ec8c93          	addi	s9,s9,-1186 # 80006398 <__clz_tab+0x418>
        if (vendor == SMARTETH_VENDOR_ID && device == SMARTETH_DEVICE_ID) {
    80005842:	efd48493          	addi	s1,s1,-259 # 1efd <_start-0x7fffe103>
    80005846:	4905                	li	s2,1
    80005848:	a031                	j	80005854 <smarteth_pci_scan+0x54>
    for (int dev = 0; dev < 32; dev++) {
    8000584a:	2985                	addiw	s3,s3,1
    8000584c:	02000793          	li	a5,32
    80005850:	10f98263          	beq	s3,a5,80005954 <smarteth_pci_scan+0x154>
    return ecam[addr >> 2];
    80005854:	00f9941b          	slliw	s0,s3,0xf
    80005858:	0024541b          	srliw	s0,s0,0x2
    8000585c:	02041713          	slli	a4,s0,0x20
    80005860:	9301                	srli	a4,a4,0x20
    80005862:	070a                	slli	a4,a4,0x2
    80005864:	975e                	add	a4,a4,s7
    80005866:	4310                	lw	a2,0(a4)
    80005868:	00346793          	ori	a5,s0,3
    8000586c:	1782                	slli	a5,a5,0x20
    return (uint16_t)(val & 0xFFFF);
    8000586e:	03061a93          	slli	s5,a2,0x30
    80005872:	030ada93          	srli	s5,s5,0x30
        if (vendor == 0xFFFF || vendor == 0x0000)
    80005876:	fffa869b          	addiw	a3,s5,-1
    return ecam[addr >> 2];
    8000587a:	9381                	srli	a5,a5,0x20
        if (vendor == 0xFFFF || vendor == 0x0000)
    8000587c:	16c2                	slli	a3,a3,0x30
    return ecam[addr >> 2];
    8000587e:	078a                	slli	a5,a5,0x2
    80005880:	2601                	sext.w	a2,a2
        if (vendor == 0xFFFF || vendor == 0x0000)
    80005882:	92c1                	srli	a3,a3,0x30
    return ecam[addr >> 2];
    80005884:	97de                	add	a5,a5,s7
        uart_printf("  Dev %d: vendor=0x%x device=0x%x hdr=0x%x\n",
    80005886:	85ce                	mv	a1,s3
    80005888:	8566                	mv	a0,s9
    8000588a:	01867633          	and	a2,a2,s8
    return ecam[addr >> 2];
    8000588e:	00040a1b          	sext.w	s4,s0
        if (vendor == 0xFFFF || vendor == 0x0000)
    80005892:	fadd6ce3          	bltu	s10,a3,8000584a <smarteth_pci_scan+0x4a>
    return ecam[addr >> 2];
    80005896:	00072b03          	lw	s6,0(a4) # c002000 <_start-0x73ffe000>
    8000589a:	4398                	lw	a4,0(a5)
        return (uint16_t)(val >> 16);
    8000589c:	010b5b1b          	srliw	s6,s6,0x10
    return (uint8_t)((val >> ((offset & 3) * 8)) & 0xFF);
    800058a0:	0107571b          	srliw	a4,a4,0x10
        uart_printf("  Dev %d: vendor=0x%x device=0x%x hdr=0x%x\n",
    800058a4:	0ff77713          	zext.b	a4,a4
    800058a8:	86da                	mv	a3,s6
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	7a0080e7          	jalr	1952(ra) # 8000504a <uart_printf>
        if (vendor == SMARTETH_VENDOR_ID && device == SMARTETH_DEVICE_ID) {
    800058b2:	f89a9ce3          	bne	s5,s1,8000584a <smarteth_pci_scan+0x4a>
    800058b6:	f92b1ae3          	bne	s6,s2,8000584a <smarteth_pci_scan+0x4a>
    return ecam[addr >> 2];
    800058ba:	00446413          	ori	s0,s0,4
    800058be:	1402                	slli	s0,s0,0x20
    800058c0:	8079                	srli	s0,s0,0x1e
            /* Found SmartEth device — program BAR0 and enable MMIO */

            uart_printf("[PCI] Found SmartEth at Dev %d\n", dev);
    800058c2:	85ce                	mv	a1,s3
    800058c4:	00001517          	auipc	a0,0x1
    800058c8:	b0450513          	addi	a0,a0,-1276 # 800063c8 <__clz_tab+0x448>
    return ecam[addr >> 2];
    800058cc:	945e                	add	s0,s0,s7
            uart_printf("[PCI] Found SmartEth at Dev %d\n", dev);
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	77c080e7          	jalr	1916(ra) # 8000504a <uart_printf>
    return ecam[addr >> 2];
    800058d6:	4004                	lw	s1,0(s0)
             */
            uint32_t pci_mmio_base = 0x40000000;

            /* Read BAR0 to check if GPEX already assigned it */
            uint32_t bar0_lo = pci_config_read32(0, dev, 0, PCI_BAR0);
            uart_printf("      RAW BAR0 before = 0x%x\n", (unsigned int)bar0_lo);
    800058d8:	00001517          	auipc	a0,0x1
    800058dc:	b1050513          	addi	a0,a0,-1264 # 800063e8 <__clz_tab+0x468>
    return ecam[addr >> 2];
    800058e0:	2481                	sext.w	s1,s1
            uart_printf("      RAW BAR0 before = 0x%x\n", (unsigned int)bar0_lo);
    800058e2:	85a6                	mv	a1,s1

            if ((bar0_lo & ~0xF) == 0) {
    800058e4:	98c1                	andi	s1,s1,-16
            uart_printf("      RAW BAR0 before = 0x%x\n", (unsigned int)bar0_lo);
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	764080e7          	jalr	1892(ra) # 8000504a <uart_printf>
            if ((bar0_lo & ~0xF) == 0) {
    800058ee:	c4cd                	beqz	s1,80005998 <smarteth_pci_scan+0x198>
    return ecam[addr >> 2];
    800058f0:	001a6793          	ori	a5,s4,1
    800058f4:	078a                	slli	a5,a5,0x2
    800058f6:	30000737          	lui	a4,0x30000
    800058fa:	973e                	add	a4,a4,a5
    800058fc:	430c                	lw	a1,0(a4)
    800058fe:	431c                	lw	a5,0(a4)
    uint32_t new_val = (old & ~(0xFFFF << shift)) | ((uint32_t)val << shift);
    80005900:	76c1                	lui	a3,0xffff0
                pci_config_write32(0, dev, 0, PCI_BAR0, pci_mmio_base);
            }

            /* Enable MMIO space (bit 1) + bus master (bit 2) in command reg */
            uint16_t cmd = pci_config_read16(0, dev, 0, PCI_COMMAND);
            cmd |= 0x0006;  /* Memory Space + Bus Master */
    80005902:	0065e593          	ori	a1,a1,6
    uint32_t new_val = (old & ~(0xFFFF << shift)) | ((uint32_t)val << shift);
    80005906:	0105959b          	slliw	a1,a1,0x10
    8000590a:	0105d59b          	srliw	a1,a1,0x10
    8000590e:	8ff5                	and	a5,a5,a3
    80005910:	8fcd                	or	a5,a5,a1
    80005912:	2781                	sext.w	a5,a5
            pci_config_write16(0, dev, 0, PCI_COMMAND, cmd);
            uart_printf("      COMMAND reg = 0x%x\n", (unsigned int)cmd);
    80005914:	00001517          	auipc	a0,0x1
    80005918:	b1450513          	addi	a0,a0,-1260 # 80006428 <__clz_tab+0x4a8>
    ecam[addr >> 2] = val;
    8000591c:	c31c                	sw	a5,0(a4)
            uart_printf("      COMMAND reg = 0x%x\n", (unsigned int)cmd);
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	72c080e7          	jalr	1836(ra) # 8000504a <uart_printf>
    return ecam[addr >> 2];
    80005926:	4000                	lw	s0,0(s0)

            /* Read back BAR0 */
            bar0_lo = pci_config_read32(0, dev, 0, PCI_BAR0);
            uint64_t bar0 = bar0_lo & ~0xF;
            uart_printf("      BAR0 after prog = 0x%x\n", (unsigned int)bar0);
    80005928:	00001517          	auipc	a0,0x1
    8000592c:	b2050513          	addi	a0,a0,-1248 # 80006448 <__clz_tab+0x4c8>
    80005930:	9841                	andi	s0,s0,-16
    80005932:	85a2                	mv	a1,s0
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	716080e7          	jalr	1814(ra) # 8000504a <uart_printf>

            if ((bar0 & ~0xF) != 0) {
    8000593c:	c421                	beqz	s0,80005984 <smarteth_pci_scan+0x184>
                uart_puts("[PCI] BAR0 programmed successfully\n");
    8000593e:	00001517          	auipc	a0,0x1
    80005942:	b2a50513          	addi	a0,a0,-1238 # 80006468 <__clz_tab+0x4e8>
            uint64_t bar0 = bar0_lo & ~0xF;
    80005946:	1402                	slli	s0,s0,0x20
    80005948:	9001                	srli	s0,s0,0x20
                uart_puts("[PCI] BAR0 programmed successfully\n");
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	662080e7          	jalr	1634(ra) # 80004fac <uart_puts>
                return bar0;
    80005952:	a811                	j	80005966 <smarteth_pci_scan+0x166>
                return 0;
            }
        }
    }

    uart_puts("[PCI] SmartEth device NOT found!\n");
    80005954:	00001517          	auipc	a0,0x1
    80005958:	b6c50513          	addi	a0,a0,-1172 # 800064c0 <__clz_tab+0x540>
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	650080e7          	jalr	1616(ra) # 80004fac <uart_puts>
    return 0;
    80005964:	4401                	li	s0,0
}
    80005966:	60e6                	ld	ra,88(sp)
    80005968:	8522                	mv	a0,s0
    8000596a:	6446                	ld	s0,80(sp)
    8000596c:	64a6                	ld	s1,72(sp)
    8000596e:	6906                	ld	s2,64(sp)
    80005970:	79e2                	ld	s3,56(sp)
    80005972:	7a42                	ld	s4,48(sp)
    80005974:	7aa2                	ld	s5,40(sp)
    80005976:	7b02                	ld	s6,32(sp)
    80005978:	6be2                	ld	s7,24(sp)
    8000597a:	6c42                	ld	s8,16(sp)
    8000597c:	6ca2                	ld	s9,8(sp)
    8000597e:	6d02                	ld	s10,0(sp)
    80005980:	6125                	addi	sp,sp,96
    80005982:	8082                	ret
                uart_puts("[PCI] BAR0 still zero after programming!\n");
    80005984:	00001517          	auipc	a0,0x1
    80005988:	b0c50513          	addi	a0,a0,-1268 # 80006490 <__clz_tab+0x510>
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	620080e7          	jalr	1568(ra) # 80004fac <uart_puts>
                return 0;
    80005994:	4401                	li	s0,0
    80005996:	bfc1                	j	80005966 <smarteth_pci_scan+0x166>
                uart_puts("      Programming BAR0...\n");
    80005998:	00001517          	auipc	a0,0x1
    8000599c:	a7050513          	addi	a0,a0,-1424 # 80006408 <__clz_tab+0x488>
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	60c080e7          	jalr	1548(ra) # 80004fac <uart_puts>
    ecam[addr >> 2] = val;
    800059a8:	400007b7          	lui	a5,0x40000
    800059ac:	c01c                	sw	a5,0(s0)
}
    800059ae:	b789                	j	800058f0 <smarteth_pci_scan+0xf0>

00000000800059b0 <smarteth_reg_read>:
/* ========== MMIO register access ========== */

uint32_t smarteth_reg_read(uint64_t bar0, uint32_t offset)
{
    volatile uint32_t *reg = (volatile uint32_t *)bar0;
    return reg[offset >> 2];
    800059b0:	0025d59b          	srliw	a1,a1,0x2
    800059b4:	058a                	slli	a1,a1,0x2
    800059b6:	952e                	add	a0,a0,a1
    800059b8:	4108                	lw	a0,0(a0)
}
    800059ba:	8082                	ret

00000000800059bc <smarteth_reg_write>:

void smarteth_reg_write(uint64_t bar0, uint32_t offset, uint32_t val)
{
    volatile uint32_t *reg = (volatile uint32_t *)bar0;
    reg[offset >> 2] = val;
    800059bc:	0025d59b          	srliw	a1,a1,0x2
    800059c0:	058a                	slli	a1,a1,0x2
    800059c2:	952e                	add	a0,a0,a1
    800059c4:	c110                	sw	a2,0(a0)
}
    800059c6:	8082                	ret

00000000800059c8 <smarteth_test_isr>:
static volatile int g_irq_received = 0;

/* Called from trap handler when MSI-X interrupt fires */
void smarteth_test_isr(void)
{
    g_irq_received = 1;
    800059c8:	4785                	li	a5,1
    uart_puts("[IRQ] Test interrupt received!\n");
    800059ca:	00001517          	auipc	a0,0x1
    800059ce:	b1e50513          	addi	a0,a0,-1250 # 800064e8 <__clz_tab+0x568>
    g_irq_received = 1;
    800059d2:	00012717          	auipc	a4,0x12
    800059d6:	20f72723          	sw	a5,526(a4) # 80017be0 <g_irq_received>
    uart_puts("[IRQ] Test interrupt received!\n");
    800059da:	fffff317          	auipc	t1,0xfffff
    800059de:	5d230067          	jr	1490(t1) # 80004fac <uart_puts>

00000000800059e2 <smarteth_run_tests>:
}

/* ========== Main test runner ========== */

int smarteth_run_tests(uint64_t bar0)
{
    800059e2:	7159                	addi	sp,sp,-112
    800059e4:	eca6                	sd	s1,88(sp)
    800059e6:	84aa                	mv	s1,a0
    int all_pass = PCI_TEST_PASS;

    uart_puts("\n====== PCIe Device Tests ======\n");
    800059e8:	00001517          	auipc	a0,0x1
    800059ec:	b3050513          	addi	a0,a0,-1232 # 80006518 <__clz_tab+0x598>
{
    800059f0:	f486                	sd	ra,104(sp)
    800059f2:	f0a2                	sd	s0,96(sp)
    800059f4:	e8ca                	sd	s2,80(sp)
    800059f6:	e4ce                	sd	s3,72(sp)
    800059f8:	e0d2                	sd	s4,64(sp)
    800059fa:	fc56                	sd	s5,56(sp)
    800059fc:	f85a                	sd	s6,48(sp)
    800059fe:	f45e                	sd	s7,40(sp)
    uart_puts("\n====== PCIe Device Tests ======\n");
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	5ac080e7          	jalr	1452(ra) # 80004fac <uart_puts>
    return reg[offset >> 2];
    80005a08:	1004a403          	lw	s0,256(s1)
    uart_printf("[TEST] DEV_ID = 0x%x", dev_id);
    80005a0c:	00001517          	auipc	a0,0x1
    80005a10:	b3450513          	addi	a0,a0,-1228 # 80006540 <__clz_tab+0x5c0>
    return reg[offset >> 2];
    80005a14:	2401                	sext.w	s0,s0
    uart_printf("[TEST] DEV_ID = 0x%x", dev_id);
    80005a16:	85a2                	mv	a1,s0
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	632080e7          	jalr	1586(ra) # 8000504a <uart_printf>
    if (dev_id == 0x52414D53) {  /* "SMAR" */
    80005a20:	524157b7          	lui	a5,0x52415
    80005a24:	d5378793          	addi	a5,a5,-685 # 52414d53 <_start-0x2dbeb2ad>
    80005a28:	2af41e63          	bne	s0,a5,80005ce4 <smarteth_run_tests+0x302>
        uart_puts("  PASS\n");
    80005a2c:	00001517          	auipc	a0,0x1
    80005a30:	b2c50513          	addi	a0,a0,-1236 # 80006558 <__clz_tab+0x5d8>
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	578080e7          	jalr	1400(ra) # 80004fac <uart_puts>
        return PCI_TEST_PASS;
    80005a3c:	4a81                	li	s5,0
    return reg[offset >> 2];
    80005a3e:	40c0                	lw	s0,4(s1)
    uart_printf("[TEST] STATUS = 0x%x", status);
    80005a40:	00001517          	auipc	a0,0x1
    80005a44:	b4050513          	addi	a0,a0,-1216 # 80006580 <__clz_tab+0x600>
    return reg[offset >> 2];
    80005a48:	2401                	sext.w	s0,s0
    uart_printf("[TEST] STATUS = 0x%x", status);
    80005a4a:	85a2                	mv	a1,s0
    if (status & STATUS_READY) {
    80005a4c:	8805                	andi	s0,s0,1
    uart_printf("[TEST] STATUS = 0x%x", status);
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	5fc080e7          	jalr	1532(ra) # 8000504a <uart_printf>
    if (status & STATUS_READY) {
    80005a56:	2e040163          	beqz	s0,80005d38 <smarteth_run_tests+0x356>
        uart_puts("  PASS (device ready)\n");
    80005a5a:	00001517          	auipc	a0,0x1
    80005a5e:	b3e50513          	addi	a0,a0,-1218 # 80006598 <__clz_tab+0x618>
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	54a080e7          	jalr	1354(ra) # 80004fac <uart_puts>
    uint32_t patterns[] = {
    80005a6a:	57fd                	li	a5,-1
    80005a6c:	c63e                	sw	a5,12(sp)
    80005a6e:	00001797          	auipc	a5,0x1
    80005a72:	dba7b783          	ld	a5,-582(a5) # 80006828 <xISRStackTop+0x8>
    80005a76:	e83e                	sd	a5,16(sp)
    80005a78:	deadc7b7          	lui	a5,0xdeadc
    80005a7c:	eef78793          	addi	a5,a5,-273 # ffffffffdeadbeef <_stack_top+0xffffffff4eadbeef>
    80005a80:	cc3e                	sw	a5,24(sp)
    for (int i = 0; i < n; i++) {
    80005a82:	00c10b13          	addi	s6,sp,12
    uint32_t patterns[] = {
    80005a86:	4681                	li	a3,0
    int pass = PCI_TEST_PASS;
    80005a88:	4b81                	li	s7,0
    for (int i = 0; i < n; i++) {
    80005a8a:	4401                	li	s0,0
            uart_printf("[TEST] SCRATCH[%d] = 0x%x (expected 0x%x)  FAIL\n",
    80005a8c:	00001997          	auipc	s3,0x1
    80005a90:	b6498993          	addi	s3,s3,-1180 # 800065f0 <__clz_tab+0x670>
            uart_printf("[TEST] SCRATCH[%d] = 0x%x  PASS\n", i, val);
    80005a94:	00001a17          	auipc	s4,0x1
    80005a98:	b34a0a13          	addi	s4,s4,-1228 # 800065c8 <__clz_tab+0x648>
    for (int i = 0; i < n; i++) {
    80005a9c:	4915                	li	s2,5
        smarteth_reg_write(bar0, REG_SCRATCH0 + (i % 4) * 4, patterns[i]);
    80005a9e:	00347793          	andi	a5,s0,3
    reg[offset >> 2] = val;
    80005aa2:	07a1                	addi	a5,a5,8
    80005aa4:	078a                	slli	a5,a5,0x2
    80005aa6:	97a6                	add	a5,a5,s1
    80005aa8:	c394                	sw	a3,0(a5)
    return reg[offset >> 2];
    80005aaa:	439c                	lw	a5,0(a5)
            uart_printf("[TEST] SCRATCH[%d] = 0x%x (expected 0x%x)  FAIL\n",
    80005aac:	85a2                	mv	a1,s0
    80005aae:	854e                	mv	a0,s3
    return reg[offset >> 2];
    80005ab0:	0007861b          	sext.w	a2,a5
        if (val == patterns[i]) {
    80005ab4:	00d78e63          	beq	a5,a3,80005ad0 <smarteth_run_tests+0xee>
    for (int i = 0; i < n; i++) {
    80005ab8:	2405                	addiw	s0,s0,1
            uart_printf("[TEST] SCRATCH[%d] = 0x%x (expected 0x%x)  FAIL\n",
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	590080e7          	jalr	1424(ra) # 8000504a <uart_printf>
            pass = PCI_TEST_FAIL;
    80005ac2:	5bfd                	li	s7,-1
    for (int i = 0; i < n; i++) {
    80005ac4:	01240f63          	beq	s0,s2,80005ae2 <smarteth_run_tests+0x100>
        smarteth_reg_write(bar0, REG_SCRATCH0 + (i % 4) * 4, patterns[i]);
    80005ac8:	000b2683          	lw	a3,0(s6)
    80005acc:	0b11                	addi	s6,s6,4
    80005ace:	bfc1                	j	80005a9e <smarteth_run_tests+0xbc>
            uart_printf("[TEST] SCRATCH[%d] = 0x%x  PASS\n", i, val);
    80005ad0:	8636                	mv	a2,a3
    80005ad2:	8552                	mv	a0,s4
    for (int i = 0; i < n; i++) {
    80005ad4:	2405                	addiw	s0,s0,1
            uart_printf("[TEST] SCRATCH[%d] = 0x%x  PASS\n", i, val);
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	574080e7          	jalr	1396(ra) # 8000504a <uart_printf>
    for (int i = 0; i < n; i++) {
    80005ade:	ff2415e3          	bne	s0,s2,80005ac8 <smarteth_run_tests+0xe6>
    reg[offset >> 2] = val;
    80005ae2:	67b9                	lui	a5,0xe
    80005ae4:	ead78793          	addi	a5,a5,-339 # dead <_start-0x7fff2153>
    80005ae8:	d09c                	sw	a5,32(s1)
    80005aea:	4785                	li	a5,1
    80005aec:	c09c                	sw	a5,0(s1)
    return reg[offset >> 2];
    80005aee:	5080                	lw	s0,32(s1)
    uart_printf("[TEST] CTRL_RESET: SCRATCH0 after reset = 0x%x", val);
    80005af0:	00001517          	auipc	a0,0x1
    80005af4:	b3850513          	addi	a0,a0,-1224 # 80006628 <__clz_tab+0x6a8>

    all_pass |= test_device_id(bar0);
    all_pass |= test_status(bar0);
    all_pass |= test_scratch_regs(bar0);
    80005af8:	017aeab3          	or	s5,s5,s7
    return reg[offset >> 2];
    80005afc:	2401                	sext.w	s0,s0
    uart_printf("[TEST] CTRL_RESET: SCRATCH0 after reset = 0x%x", val);
    80005afe:	85a2                	mv	a1,s0
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	54a080e7          	jalr	1354(ra) # 8000504a <uart_printf>
    if (val == 0) {
    80005b08:	20041e63          	bnez	s0,80005d24 <smarteth_run_tests+0x342>
        uart_puts("  PASS\n");
    80005b0c:	00001517          	auipc	a0,0x1
    80005b10:	a4c50513          	addi	a0,a0,-1460 # 80006558 <__clz_tab+0x5d8>
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	498080e7          	jalr	1176(ra) # 80004fac <uart_puts>
    return reg[offset >> 2];
    80005b1c:	488c                	lw	a1,16(s1)
    80005b1e:	48dc                	lw	a5,20(s1)
    uart_printf("[TEST] MAC = %x:%x:%x:%x:%x:%x\n",
    80005b20:	00001517          	auipc	a0,0x1
    80005b24:	b5050513          	addi	a0,a0,-1200 # 80006670 <__clz_tab+0x6f0>
                (unsigned)((mac_lo >> 16) & 0xFF),
    80005b28:	0105d69b          	srliw	a3,a1,0x10
                (unsigned)((mac_hi >> 8) & 0xFF));
    80005b2c:	0087d81b          	srliw	a6,a5,0x8
                (unsigned)((mac_lo >> 8) & 0xFF),
    80005b30:	0085d61b          	srliw	a2,a1,0x8
    uart_printf("[TEST] MAC = %x:%x:%x:%x:%x:%x\n",
    80005b34:	0185d71b          	srliw	a4,a1,0x18
    80005b38:	0ff7f793          	zext.b	a5,a5
    80005b3c:	0ff6f693          	zext.b	a3,a3
    80005b40:	0ff87813          	zext.b	a6,a6
    80005b44:	0ff67613          	zext.b	a2,a2
    80005b48:	0ff5f593          	zext.b	a1,a1
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	4fe080e7          	jalr	1278(ra) # 8000504a <uart_printf>
    uart_puts("[TEST] MAC readback  PASS\n");
    80005b54:	00001517          	auipc	a0,0x1
    80005b58:	b3c50513          	addi	a0,a0,-1220 # 80006690 <__clz_tab+0x710>
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	450080e7          	jalr	1104(ra) # 80004fac <uart_puts>
    80005b64:	08f00793          	li	a5,143
    80005b68:	07e2                	slli	a5,a5,0x18
    80005b6a:	aabb0737          	lui	a4,0xaabb0
    for (int i = 0; i < 64; i++) {
    80005b6e:	10078693          	addi	a3,a5,256
        dma_buf[i] = 0xAABB0000 + i;
    80005b72:	c398                	sw	a4,0(a5)
    for (int i = 0; i < 64; i++) {
    80005b74:	0791                	addi	a5,a5,4
    80005b76:	2705                	addiw	a4,a4,1 # ffffffffaabb0001 <_stack_top+0xffffffff1abb0001>
    80005b78:	fed79de3          	bne	a5,a3,80005b72 <smarteth_run_tests+0x190>
    reg[offset >> 2] = val;
    80005b7c:	8f0007b7          	lui	a5,0x8f000
    80005b80:	c0bc                	sw	a5,64(s1)
    80005b82:	0404a423          	sw	zero,72(s1)
    80005b86:	10000793          	li	a5,256
    80005b8a:	c8bc                	sw	a5,80(s1)
    80005b8c:	4785                	li	a5,1
    80005b8e:	ccbc                	sw	a5,88(s1)
    uart_puts("[TEST] DMA started (reading 256 bytes from guest memory)...\n");
    80005b90:	00001517          	auipc	a0,0x1
    80005b94:	b2050513          	addi	a0,a0,-1248 # 800066b0 <__clz_tab+0x730>
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	414080e7          	jalr	1044(ra) # 80004fac <uart_puts>
    while (timeout--) {
    80005ba0:	1f300413          	li	s0,499
    80005ba4:	597d                	li	s2,-1
    80005ba6:	a801                	j	80005bb6 <smarteth_run_tests+0x1d4>
    80005ba8:	347d                	addiw	s0,s0,-1
        vTaskDelay(pdMS_TO_TICKS(1));
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	45a080e7          	jalr	1114(ra) # 80001004 <vTaskDelay>
    while (timeout--) {
    80005bb2:	0b240e63          	beq	s0,s2,80005c6e <smarteth_run_tests+0x28c>
    return reg[offset >> 2];
    80005bb6:	4cfc                	lw	a5,92(s1)
        vTaskDelay(pdMS_TO_TICKS(1));
    80005bb8:	4501                	li	a0,0
        if (!(dma_sts & STATUS_DMA_BSY)) {  /* not busy anymore */
    80005bba:	8b89                	andi	a5,a5,2
    80005bbc:	f7f5                	bnez	a5,80005ba8 <smarteth_run_tests+0x1c6>
    if (timeout <= 0) {
    80005bbe:	c845                	beqz	s0,80005c6e <smarteth_run_tests+0x28c>
    uart_puts("[TEST] DMA completed  PASS\n");
    80005bc0:	00001517          	auipc	a0,0x1
    80005bc4:	bb050513          	addi	a0,a0,-1104 # 80006770 <__clz_tab+0x7f0>
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	3e4080e7          	jalr	996(ra) # 80004fac <uart_puts>
    uart_puts("[TEST] Triggering device interrupt (REG_IRQ_TEST)...\n");
    80005bd0:	00001517          	auipc	a0,0x1
    80005bd4:	b4050513          	addi	a0,a0,-1216 # 80006710 <__clz_tab+0x790>
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	3d4080e7          	jalr	980(ra) # 80004fac <uart_puts>
    reg[offset >> 2] = val;
    80005be0:	4909                	li	s2,2
    80005be2:	0124a623          	sw	s2,12(s1)
    80005be6:	4785                	li	a5,1
    80005be8:	20f4a023          	sw	a5,512(s1)
    return reg[offset >> 2];
    80005bec:	44c0                	lw	s0,12(s1)
    uart_printf("[TEST] IRQ_STS after trigger = 0x%x\n", irq_sts);
    80005bee:	00001517          	auipc	a0,0x1
    80005bf2:	b5a50513          	addi	a0,a0,-1190 # 80006748 <__clz_tab+0x7c8>
    return reg[offset >> 2];
    80005bf6:	2401                	sext.w	s0,s0
    uart_printf("[TEST] IRQ_STS after trigger = 0x%x\n", irq_sts);
    80005bf8:	85a2                	mv	a1,s0
    if (irq_sts & IRQ_TEST) {
    80005bfa:	8809                	andi	s0,s0,2
    uart_printf("[TEST] IRQ_STS after trigger = 0x%x\n", irq_sts);
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	44e080e7          	jalr	1102(ra) # 8000504a <uart_printf>
    if (irq_sts & IRQ_TEST) {
    80005c04:	c875                	beqz	s0,80005cf8 <smarteth_run_tests+0x316>
        uart_puts("[TEST] Interrupt status bit set  PASS (device side)\n");
    80005c06:	00001517          	auipc	a0,0x1
    80005c0a:	b8a50513          	addi	a0,a0,-1142 # 80006790 <__clz_tab+0x810>
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	39e080e7          	jalr	926(ra) # 80004fac <uart_puts>
    all_pass |= test_ctrl_reset(bar0);
    all_pass |= test_mac_addr(bar0);
    all_pass |= test_dma(bar0);
    all_pass |= test_interrupt(bar0);

    uart_puts("====== Tests ");
    80005c16:	00001517          	auipc	a0,0x1
    80005c1a:	bb250513          	addi	a0,a0,-1102 # 800067c8 <__clz_tab+0x848>
    reg[offset >> 2] = val;
    80005c1e:	0124a623          	sw	s2,12(s1)
    uart_puts("====== Tests ");
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	38a080e7          	jalr	906(ra) # 80004fac <uart_puts>
    uart_puts(all_pass == PCI_TEST_PASS ? "PASSED" : "FAILED");
    80005c2a:	00001517          	auipc	a0,0x1
    80005c2e:	8e650513          	addi	a0,a0,-1818 # 80006510 <__clz_tab+0x590>
    80005c32:	000a9663          	bnez	s5,80005c3e <smarteth_run_tests+0x25c>
    80005c36:	00001517          	auipc	a0,0x1
    80005c3a:	8d250513          	addi	a0,a0,-1838 # 80006508 <__clz_tab+0x588>
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	36e080e7          	jalr	878(ra) # 80004fac <uart_puts>
    uart_puts(" ======\n\n");
    80005c46:	00001517          	auipc	a0,0x1
    80005c4a:	bc250513          	addi	a0,a0,-1086 # 80006808 <__clz_tab+0x888>
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	35e080e7          	jalr	862(ra) # 80004fac <uart_puts>

    return all_pass;
}
    80005c56:	70a6                	ld	ra,104(sp)
    80005c58:	7406                	ld	s0,96(sp)
    80005c5a:	64e6                	ld	s1,88(sp)
    80005c5c:	6946                	ld	s2,80(sp)
    80005c5e:	69a6                	ld	s3,72(sp)
    80005c60:	6a06                	ld	s4,64(sp)
    80005c62:	7b42                	ld	s6,48(sp)
    80005c64:	7ba2                	ld	s7,40(sp)
    80005c66:	8556                	mv	a0,s5
    80005c68:	7ae2                	ld	s5,56(sp)
    80005c6a:	6165                	addi	sp,sp,112
    80005c6c:	8082                	ret
        uart_puts("[TEST] DMA  TIMEOUT  FAIL\n");
    80005c6e:	00001517          	auipc	a0,0x1
    80005c72:	a8250513          	addi	a0,a0,-1406 # 800066f0 <__clz_tab+0x770>
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	336080e7          	jalr	822(ra) # 80004fac <uart_puts>
    uart_puts("[TEST] Triggering device interrupt (REG_IRQ_TEST)...\n");
    80005c7e:	00001517          	auipc	a0,0x1
    80005c82:	a9250513          	addi	a0,a0,-1390 # 80006710 <__clz_tab+0x790>
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	326080e7          	jalr	806(ra) # 80004fac <uart_puts>
    reg[offset >> 2] = val;
    80005c8e:	4909                	li	s2,2
    80005c90:	0124a623          	sw	s2,12(s1)
    80005c94:	4785                	li	a5,1
    80005c96:	20f4a023          	sw	a5,512(s1)
    return reg[offset >> 2];
    80005c9a:	44c0                	lw	s0,12(s1)
    uart_printf("[TEST] IRQ_STS after trigger = 0x%x\n", irq_sts);
    80005c9c:	00001517          	auipc	a0,0x1
    80005ca0:	aac50513          	addi	a0,a0,-1364 # 80006748 <__clz_tab+0x7c8>
    return reg[offset >> 2];
    80005ca4:	2401                	sext.w	s0,s0
    uart_printf("[TEST] IRQ_STS after trigger = 0x%x\n", irq_sts);
    80005ca6:	85a2                	mv	a1,s0
    if (irq_sts & IRQ_TEST) {
    80005ca8:	8809                	andi	s0,s0,2
    uart_printf("[TEST] IRQ_STS after trigger = 0x%x\n", irq_sts);
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	3a0080e7          	jalr	928(ra) # 8000504a <uart_printf>
    if (irq_sts & IRQ_TEST) {
    80005cb2:	c039                	beqz	s0,80005cf8 <smarteth_run_tests+0x316>
        uart_puts("[TEST] Interrupt status bit set  PASS (device side)\n");
    80005cb4:	00001517          	auipc	a0,0x1
    80005cb8:	adc50513          	addi	a0,a0,-1316 # 80006790 <__clz_tab+0x810>
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	2f0080e7          	jalr	752(ra) # 80004fac <uart_puts>
    uart_puts("====== Tests ");
    80005cc4:	00001517          	auipc	a0,0x1
    80005cc8:	b0450513          	addi	a0,a0,-1276 # 800067c8 <__clz_tab+0x848>
    reg[offset >> 2] = val;
    80005ccc:	0124a623          	sw	s2,12(s1)
    uart_puts("====== Tests ");
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	2dc080e7          	jalr	732(ra) # 80004fac <uart_puts>
    all_pass |= test_dma(bar0);
    80005cd8:	5afd                	li	s5,-1
    uart_puts(all_pass == PCI_TEST_PASS ? "PASSED" : "FAILED");
    80005cda:	00001517          	auipc	a0,0x1
    80005cde:	83650513          	addi	a0,a0,-1994 # 80006510 <__clz_tab+0x590>
    80005ce2:	bfb1                	j	80005c3e <smarteth_run_tests+0x25c>
    uart_puts("  FAIL (unexpected value)\n");
    80005ce4:	00001517          	auipc	a0,0x1
    80005ce8:	87c50513          	addi	a0,a0,-1924 # 80006560 <__clz_tab+0x5e0>
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	2c0080e7          	jalr	704(ra) # 80004fac <uart_puts>
    return PCI_TEST_FAIL;
    80005cf4:	5afd                	li	s5,-1
    80005cf6:	b3a1                	j	80005a3e <smarteth_run_tests+0x5c>
    uart_puts("[TEST] Interrupt status bit NOT set  FAIL\n");
    80005cf8:	00001517          	auipc	a0,0x1
    80005cfc:	ae050513          	addi	a0,a0,-1312 # 800067d8 <__clz_tab+0x858>
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	2ac080e7          	jalr	684(ra) # 80004fac <uart_puts>
    uart_puts("====== Tests ");
    80005d08:	00001517          	auipc	a0,0x1
    80005d0c:	ac050513          	addi	a0,a0,-1344 # 800067c8 <__clz_tab+0x848>
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	29c080e7          	jalr	668(ra) # 80004fac <uart_puts>
    all_pass |= test_interrupt(bar0);
    80005d18:	5afd                	li	s5,-1
    uart_puts(all_pass == PCI_TEST_PASS ? "PASSED" : "FAILED");
    80005d1a:	00000517          	auipc	a0,0x0
    80005d1e:	7f650513          	addi	a0,a0,2038 # 80006510 <__clz_tab+0x590>
    80005d22:	bf31                	j	80005c3e <smarteth_run_tests+0x25c>
    uart_puts("  FAIL (not cleared)\n");
    80005d24:	00001517          	auipc	a0,0x1
    80005d28:	93450513          	addi	a0,a0,-1740 # 80006658 <__clz_tab+0x6d8>
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	280080e7          	jalr	640(ra) # 80004fac <uart_puts>
    return PCI_TEST_FAIL;
    80005d34:	5afd                	li	s5,-1
    80005d36:	b3dd                	j	80005b1c <smarteth_run_tests+0x13a>
    uart_puts("  FAIL (not ready)\n");
    80005d38:	00001517          	auipc	a0,0x1
    80005d3c:	87850513          	addi	a0,a0,-1928 # 800065b0 <__clz_tab+0x630>
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	26c080e7          	jalr	620(ra) # 80004fac <uart_puts>
    return PCI_TEST_FAIL;
    80005d48:	5afd                	li	s5,-1
    80005d4a:	b305                	j	80005a6a <smarteth_run_tests+0x88>

0000000080005d4c <__clzdi2>:
    80005d4c:	03800793          	li	a5,56
    80005d50:	00f55733          	srl	a4,a0,a5
    80005d54:	0ff77693          	zext.b	a3,a4
    80005d58:	ee99                	bnez	a3,80005d76 <__clzdi2+0x2a>
    80005d5a:	17e1                	addi	a5,a5,-8 # ffffffff8efffff8 <_stack_top+0xfffffffefefffff8>
    80005d5c:	fbf5                	bnez	a5,80005d50 <__clzdi2+0x4>
    80005d5e:	00001797          	auipc	a5,0x1
    80005d62:	ada7b783          	ld	a5,-1318(a5) # 80006838 <_GLOBAL_OFFSET_TABLE_+0x8>
    80005d66:	97aa                	add	a5,a5,a0
    80005d68:	0007c503          	lbu	a0,0(a5)
    80005d6c:	04000693          	li	a3,64
    80005d70:	40a6853b          	subw	a0,a3,a0
    80005d74:	8082                	ret
    80005d76:	04000693          	li	a3,64
    80005d7a:	8e9d                	sub	a3,a3,a5
    80005d7c:	853a                	mv	a0,a4
    80005d7e:	00001797          	auipc	a5,0x1
    80005d82:	aba7b783          	ld	a5,-1350(a5) # 80006838 <_GLOBAL_OFFSET_TABLE_+0x8>
    80005d86:	97aa                	add	a5,a5,a0
    80005d88:	0007c503          	lbu	a0,0(a5)
    80005d8c:	40a6853b          	subw	a0,a3,a0
    80005d90:	8082                	ret

0000000080005d92 <main>:

/* ========== 主函数 ========== */

void main(void)
{
    80005d92:	1141                	addi	sp,sp,-16
    80005d94:	e406                	sd	ra,8(sp)
    /* 初始化 BSP */
    uart_init();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	19e080e7          	jalr	414(ra) # 80004f34 <uart_init>
    clint_init();
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	696080e7          	jalr	1686(ra) # 80005434 <clint_init>
    plic_init();
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	6d8080e7          	jalr	1752(ra) # 8000547e <plic_init>

    uart_puts("\n");
    80005dae:	00001517          	auipc	a0,0x1
    80005db2:	a6250513          	addi	a0,a0,-1438 # 80006810 <__clz_tab+0x890>
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	1f6080e7          	jalr	502(ra) # 80004fac <uart_puts>
    uart_puts("========================================\n");
    80005dbe:	00000517          	auipc	a0,0x0
    80005dc2:	3da50513          	addi	a0,a0,986 # 80006198 <__clz_tab+0x218>
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	1e6080e7          	jalr	486(ra) # 80004fac <uart_puts>
    uart_puts("  SmartEth RISC-V NIC Firmware\n");
    80005dce:	00000517          	auipc	a0,0x0
    80005dd2:	4d250513          	addi	a0,a0,1234 # 800062a0 <__clz_tab+0x320>
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	1d6080e7          	jalr	470(ra) # 80004fac <uart_puts>
    uart_puts("  Phase 1: FreeRTOS on QEMU RISC-V\n");
    80005dde:	00000517          	auipc	a0,0x0
    80005de2:	4e250513          	addi	a0,a0,1250 # 800062c0 <__clz_tab+0x340>
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	1c6080e7          	jalr	454(ra) # 80004fac <uart_puts>
    uart_puts("========================================\n");
    80005dee:	00000517          	auipc	a0,0x0
    80005df2:	3aa50513          	addi	a0,a0,938 # 80006198 <__clz_tab+0x218>
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	1b6080e7          	jalr	438(ra) # 80004fac <uart_puts>
    uart_puts("BSP Init OK\n\n");
    80005dfe:	00000517          	auipc	a0,0x0
    80005e02:	4ea50513          	addi	a0,a0,1258 # 800062e8 <__clz_tab+0x368>
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	1a6080e7          	jalr	422(ra) # 80004fac <uart_puts>

    /* 创建任务 */
    xTaskCreate(
    80005e0e:	00012797          	auipc	a5,0x12
    80005e12:	dca78793          	addi	a5,a5,-566 # 80017bd8 <task_hb_handle>
    80005e16:	4705                	li	a4,1
    80005e18:	4681                	li	a3,0
    80005e1a:	10000613          	li	a2,256
    80005e1e:	00000597          	auipc	a1,0x0
    80005e22:	4da58593          	addi	a1,a1,1242 # 800062f8 <__clz_tab+0x378>
    80005e26:	fffff517          	auipc	a0,0xfffff
    80005e2a:	6e450513          	addi	a0,a0,1764 # 8000550a <vTaskHeartbeat>
    80005e2e:	ffffb097          	auipc	ra,0xffffb
    80005e32:	d2e080e7          	jalr	-722(ra) # 80000b5c <xTaskCreate>
        NULL,
        1,
        &task_hb_handle
    );

    xTaskCreate(
    80005e36:	00012797          	auipc	a5,0x12
    80005e3a:	d9a78793          	addi	a5,a5,-614 # 80017bd0 <task_info_handle>
    80005e3e:	4705                	li	a4,1
    80005e40:	4681                	li	a3,0
    80005e42:	18000613          	li	a2,384
    80005e46:	00000597          	auipc	a1,0x0
    80005e4a:	4c258593          	addi	a1,a1,1218 # 80006308 <__clz_tab+0x388>
    80005e4e:	fffff517          	auipc	a0,0xfffff
    80005e52:	6ea50513          	addi	a0,a0,1770 # 80005538 <vTaskInfo>
    80005e56:	ffffb097          	auipc	ra,0xffffb
    80005e5a:	d06080e7          	jalr	-762(ra) # 80000b5c <xTaskCreate>
        NULL,
        1,
        &task_info_handle
    );

    xTaskCreate(
    80005e5e:	00012797          	auipc	a5,0x12
    80005e62:	d6a78793          	addi	a5,a5,-662 # 80017bc8 <task_echo_handle>
    80005e66:	4709                	li	a4,2
    80005e68:	4681                	li	a3,0
    80005e6a:	18000613          	li	a2,384
    80005e6e:	00000597          	auipc	a1,0x0
    80005e72:	4a258593          	addi	a1,a1,1186 # 80006310 <__clz_tab+0x390>
    80005e76:	fffff517          	auipc	a0,0xfffff
    80005e7a:	79450513          	addi	a0,a0,1940 # 8000560a <vTaskEcho>
    80005e7e:	ffffb097          	auipc	ra,0xffffb
    80005e82:	cde080e7          	jalr	-802(ra) # 80000b5c <xTaskCreate>
        NULL,
        2,
        &task_echo_handle
    );

    xTaskCreate(
    80005e86:	00012797          	auipc	a5,0x12
    80005e8a:	d3a78793          	addi	a5,a5,-710 # 80017bc0 <task_pci_handle>
    80005e8e:	4705                	li	a4,1
    80005e90:	4681                	li	a3,0
    80005e92:	20000613          	li	a2,512
    80005e96:	00000597          	auipc	a1,0x0
    80005e9a:	48258593          	addi	a1,a1,1154 # 80006318 <__clz_tab+0x398>
    80005e9e:	fffff517          	auipc	a0,0xfffff
    80005ea2:	7ce50513          	addi	a0,a0,1998 # 8000566c <vTaskPciTest>
    80005ea6:	ffffb097          	auipc	ra,0xffffb
    80005eaa:	cb6080e7          	jalr	-842(ra) # 80000b5c <xTaskCreate>
        1,
        &task_pci_handle
    );

    /* 启动调度器 */
    uart_puts("[SYS] Starting FreeRTOS scheduler...\n\n");
    80005eae:	00000517          	auipc	a0,0x0
    80005eb2:	47a50513          	addi	a0,a0,1146 # 80006328 <__clz_tab+0x3a8>
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	0f6080e7          	jalr	246(ra) # 80004fac <uart_puts>
    vTaskStartScheduler();
    80005ebe:	ffffb097          	auipc	ra,0xffffb
    80005ec2:	566080e7          	jalr	1382(ra) # 80001424 <vTaskStartScheduler>

    /* 不应到达这里 */
    uart_puts("[FATAL] Scheduler returned!\n");
    80005ec6:	00000517          	auipc	a0,0x0
    80005eca:	48a50513          	addi	a0,a0,1162 # 80006350 <__clz_tab+0x3d0>
    80005ece:	fffff097          	auipc	ra,0xfffff
    80005ed2:	0de080e7          	jalr	222(ra) # 80004fac <uart_puts>
    for (;;)
    80005ed6:	a001                	j	80005ed6 <main+0x144>
