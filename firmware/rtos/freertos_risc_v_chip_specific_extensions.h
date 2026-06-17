/*
 * SmartEth 芯片特定扩展 (QEMU RISC-V virt)
 *    - 支持标准 SiFive CLINT (含 mtime/mtimecmp)
 *    - 无额外寄存器需要保存/恢复
 */

#ifndef __FREERTOS_RISC_V_EXTENSIONS_H__
#define __FREERTOS_RISC_V_EXTENSIONS_H__

#define portasmHAS_SIFIVE_CLINT           1
#define portasmHAS_MTIME                  1
#define portasmADDITIONAL_CONTEXT_SIZE    0

.macro portasmSAVE_ADDITIONAL_REGISTERS
   .endm

   .macro portasmRESTORE_ADDITIONAL_REGISTERS
   .endm

#endif /* __FREERTOS_RISC_V_EXTENSIONS_H__ */
