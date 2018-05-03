// Copyright (C) 2017 Philipp Holzinger
// Copyright (C) 2017 Martin Stumpf
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <cp0.h>
#include <op_field.h>

#include "fpga_cmd_processor_exceptions.h"

static volatile unsigned int *reg_stack;

static void reserved_instruction_exception(unsigned int cause) {
    // Reserved instruction exception
    unsigned int instr;
    __asm__("mfc0 %0,$22\n\t"      // asm code
             : "=g"(instr)                     // outputs optional
             :                      // inputs optional
             :                     // clobbered registers optional
           );
    unsigned int op_field = ((instr & 0xFC000000) >> 26);

    switch(op_field) {
        case C_OP_FIELD_LB:
            // load byte
            {
                // get instruction fields
                unsigned int base = (instr & 0x03E00000) >> 21;
                unsigned int rt = (instr & 0x001F0000) >> 16;
                unsigned int offset = instr & 0x0000FFFF;

                // sign extend offset
                if (offset & 0x00008000) {
                    offset |= 0xFFFF0000;
                }

                unsigned int base_address = reg_stack[base];
                unsigned int effective_address = base_address + offset;
                unsigned int byte_offset = effective_address & 0x00000003;

                register unsigned int lw_address = effective_address & 0xFFFFFFFC;
                register unsigned int word;

                __asm__("lw %0,0(%1)\n\t"       // asm code
                        : "=g"(word)                     // outputs optional
                        : "g"(lw_address)         // inputs optional
                        :                 // clobbered registers optional
                       );


                // extract byte
                unsigned int bit_offset = byte_offset * 8;
                unsigned int mask = ((unsigned int) 0x000000FF) << bit_offset;
                unsigned int byte = word & mask;
                byte = byte >> bit_offset;

                // sign extend byte
                if ((byte & 0x00000080) == 0x00000080) {
                    byte |= 0xFFFFFF00;
                }

                // store result in register file copy on the stack
                reg_stack[rt] = byte;

                // no branch delay
                if (! (cause & 0x80000000)) {
                    // increment epc register
                    __asm__("mfc0 $t3,$14\n\t"      // asm code
                            "addi $t3,$t3,4\n\t"
                            "mtc0 $t3,$14\n\t"
                            :                      // outputs optional
                            :                      // inputs optional
                            : "t3"                 // clobbered registers optional
                           );
                }
            }
            break;
        case C_OP_FIELD_LBU:
            // load byte unsigned
            {
                // get instruction fields
                unsigned int base = (instr & 0x03E00000) >> 21;
                unsigned int rt = (instr & 0x001F0000) >> 16;
                unsigned int offset = instr & 0x0000FFFF;

                // sign extend offset
                if (offset & 0x8000) {
                    offset |= 0xFFFF0000;
                }

                unsigned int base_address = reg_stack[base];
                unsigned int effective_address = base_address + offset;
                unsigned int byte_offset = effective_address & 0x3;

                register unsigned int lw_address = effective_address & 0xFFFFFFFC;
                register unsigned int word;

                __asm__("lw %0,0(%1)\n\t"       // asm code
                        : "=g"(word)                     // outputs optional
                        : "g"(lw_address)         // inputs optional
                        :                 // clobbered registers optional
                       );


                // extract byte
                unsigned int byte = (word & (0xFF << (byte_offset * 8)) >> (byte_offset * 8));
                // store result in register file copy on the stack
                reg_stack[rt] = byte;

                // no branch delay
                if (! (cause & 0x80000000)) {
                    // increment epc register
                    __asm__("mfc0 $t3,$14\n\t"      // asm code
                            "addi $t3,$t3,4\n\t"
                            "mtc0 $t3,$14\n\t"
                            :                      // outputs optional
                            :                      // inputs optional
                            : "t3"                 // clobbered registers optional
                           );
                }
            }
            break;
        case C_OP_FIELD_LH:
            // load halfword
            {
                // get instruction fields
                unsigned int base = (instr & 0x03E00000) >> 21;
                unsigned int rt = (instr & 0x001F0000) >> 16;
                unsigned int offset = instr & 0x0000FFFF;

                // sign extend offset
                if (offset & 0x8000) {
                    offset |= 0xFFFF0000;
                }

                unsigned int base_address = reg_stack[base];
                unsigned int effective_address = base_address + offset;
                unsigned int halfword_offset = (effective_address & 0x2) >> 1;

                register unsigned int lw_address = effective_address & 0xFFFFFFFC;
                register unsigned int word;

                __asm__("lw %0,0(%1)\n\t"       // asm code
                        : "=g"(word)                     // outputs optional
                        : "g"(lw_address)         // inputs optional
                        :                 // clobbered registers optional
                       );


                // extract halfword
                unsigned int halfword = (word & (0xFFFF << (halfword_offset * 16)) >> (halfword_offset * 16));

                // sign extend halfword
                if (halfword & 8000) {
                    halfword |= 0xFFFF0000;
                }

                // store result in register file copy on the stack
                reg_stack[rt] = halfword;

                // no branch delay
                if (! (cause & 0x80000000)) {
                    // increment epc register
                    __asm__("mfc0 $t3,$14\n\t"      // asm code
                            "addi $t3,$t3,4\n\t"
                            "mtc0 $t3,$14\n\t"
                            :                      // outputs optional
                            :                      // inputs optional
                            : "t3"                 // clobbered registers optional
                           );
                }
            }
            break;
        case C_OP_FIELD_LHU:
            // load halfword unsigned
            {
                // get instruction fields
                unsigned int base = (instr & 0x03E00000) >> 21;
                unsigned int rt = (instr & 0x001F0000) >> 16;
                unsigned int offset = instr & 0x0000FFFF;

                // sign extend offset
                if (offset & 0x8000) {
                    offset |= 0xFFFF0000;
                }

                unsigned int base_address = reg_stack[base];
                unsigned int effective_address = base_address + offset;
                unsigned int halfword_offset = (effective_address & 0x2) >> 1;

                register unsigned int lw_address = effective_address & 0xFFFFFFFC;
                register unsigned int word;

                __asm__("lw %0,0(%1)\n\t"       // asm code
                        : "=g"(word)                     // outputs optional
                        : "g"(lw_address)         // inputs optional
                        :                 // clobbered registers optional
                       );


                // extract halfword
                unsigned int halfword = (word & (0xFFFF << (halfword_offset * 16)) >> (halfword_offset * 16));

                // store result in register file copy on the stack
                reg_stack[rt] = halfword;

                // no branch delay
                if (! (cause & 0x80000000)) {
                    // increment epc register
                    __asm__("mfc0 $t3,$14\n\t"      // asm code
                            "addi $t3,$t3,4\n\t"
                            "mtc0 $t3,$14\n\t"
                            :                      // outputs optional
                            :                      // inputs optional
                            : "t3"                 // clobbered registers optional
                           );
                }
            }
            break;
        case C_OP_FIELD_SB:
            // store byte
            {
                // get instruction fields
                unsigned int base = (instr & 0x03E00000) >> 21;
                unsigned int rt = (instr & 0x001F0000) >> 16;
                unsigned int offset = instr & 0x0000FFFF;

                unsigned int base_address = reg_stack[base];
                unsigned int effective_address = base_address + offset;
                unsigned int byte_offset = effective_address & 0x3;

                register unsigned int lw_address = effective_address & 0xFFFFFFFC;
                register unsigned int word;

                __asm__("lw %0,0(%1)\n\t"       // asm code
                        : "=g"(word)             // outputs optional
                        : "g"(lw_address)       // inputs optional
                        :                       // clobbered registers optional
                       );


                // load byte from the register file copy and move it to the byte
                // offset
                unsigned int byte = (reg_stack[rt] & 0xFF) << (byte_offset * 8);
                unsigned int mask = !(0xFF << (byte_offset * 8));

                // merge byte into the loaded word
                word &= mask;
                word |= byte;

                // store word in memory
                __asm__("sw %0,0(%1)\n\t"       // asm code
                        :                        // outputs optional
                        : "g"(word), "g"(lw_address)      // inputs optional
                        :                      // clobbered registers optional
                       );

                // no branch delay
                if (! (cause & 0x80000000)) {
                    // increment epc register
                    __asm__("mfc0 $t3,$14\n\t"      // asm code
                            "addi $t3,$t3,4\n\t"
                            "mtc0 $t3,$14\n\t"
                            :                      // outputs optional
                            :                      // inputs optional
                            : "t3"                 // clobbered registers optional
                           );
                }
            }
            break;
        case C_OP_FIELD_SH:
            // store halfword
            {
                // get instruction fields
                unsigned int base = (instr & 0x03E00000) >> 21;
                unsigned int rt = (instr & 0x001F0000) >> 16;
                unsigned int offset = instr & 0x0000FFFF;

                unsigned int base_address = reg_stack[base];
                unsigned int effective_address = base_address + offset;
                unsigned int halfword_offset = (effective_address & 0x2) >> 1;

                register unsigned int lw_address = effective_address & 0xFFFFFFFC;
                register unsigned int word;

                __asm__("lw %0,0(%1)\n\t"       // asm code
                        : "=g"(word)             // outputs optional
                        : "g"(lw_address)       // inputs optional
                        :                       // clobbered registers optional
                       );


                // load halfword from the register file copy and move it to the
                // halfword offset
                unsigned int halfword = (reg_stack[rt] & 0xFFFF) << (halfword_offset * 16);
                unsigned int mask = !(0xFFFF << (halfword_offset * 16));

                // merge byte into the loaded word
                word &= mask;
                word |= halfword;

                // store word in memory
                __asm__("sw %0,0(%1)\n\t"       // asm code
                        :                        // outputs optional
                        : "g"(word), "g"(lw_address)      // inputs optional
                        :                      // clobbered registers optional
                       );

                // no branch delay
                if (! (cause & 0x80000000)) {
                    // increment epc register
                    __asm__("mfc0 $t3,$14\n\t"      // asm code
                            "addi $t3,$t3,4\n\t"
                            "mtc0 $t3,$14\n\t"
                            :                      // outputs optional
                            :                      // inputs optional
                            : "t3"                 // clobbered registers optional
                           );
                }
            }
            break;
        default:
            break;
    }
}

static void exception_handler() {
    // save start address of register file backup on the stack
    register unsigned int reg_stack_addr __asm__("k0");
    reg_stack = (unsigned int *) reg_stack_addr;
    //
    // caller saved registers are saved automatically by the compiler. But for
    // assembler code only, if they are marked as clobbered
    //
    // Please note: Kernel register are not saved in this configuration
    //
    // load status register
    //__asm__("mfc0 $k0,$12");
    //register unsigned int status __asm__("k0");
    // load cause register
    __asm__("mfc0 $k1,$13");
    register unsigned int cause __asm__("k1");
    unsigned int exc_code = (cause & 0x7C) >> 2;

    // high priority
    if (exc_code == C_CP0_CAUSE_EXC_CODE_RI) {
        reserved_instruction_exception(cause);
    }

    switch(exc_code) {
        case C_CP0_CAUSE_EXC_CODE_INT:{
            // Interrupt
            unsigned int interrupt_code = (cause & 0xFC00) >> 10;
            switch(interrupt_code){
                case 32: interrupt_transfer(); break;
                case 16: interrupt_completion(); break;
                case  8: interrupt_added_core(); break;
                case  4: interrupt_removed_core(); break;
		default: break;
            }
            break;}
/*        case C_CP0_CAUSE_EXC_CODE_ADEL:
            // Address error exception (load or instruction fetch)
            break;
        case C_CP0_CAUSE_EXC_CODE_ADES:
            // Address error exception (store)
            break;
        case C_CP0_CAUSE_EXC_CODE_IBE:
            // Bus error exception (instruction fetch)
            break;
        case C_CP0_CAUSE_EXC_CODE_DBE:
            // Bus error exception (data reference: load or store)
            break;
        case C_CP0_CAUSE_EXC_CODE_SYS:
            // Syscall exception
            break;
        case C_CP0_CAUSE_EXC_CODE_BP:
            // Breakpoint exception
            break;
        case C_CP0_CAUSE_EXC_CODE_RI:
            // Reserved instruction exception
            break;
        case C_CP0_CAUSE_EXC_CODE_CPU:
            // Coprocessor Unusable exception
            break;
        case C_CP0_CAUSE_EXC_CODE_OV:
            // Arithmetic Overflow exception
            break;
        case C_CP0_CAUSE_EXC_CODE_TR:
            // Trap exception
            break;
        case C_CP0_CAUSE_EXC_CODE_FPE:
            // Floating point exception
            break;*/
        default:
            __asm__("j _halt");
            break;
    }
}

void _exception_handler() {
    // save all relevant registers to the stack
    __asm(".set noat\n\t"
          "daddiu   $sp, $sp,-208\n\t"
          "move     $k0, $sp\n\t"
          "sd       $t9, 200($sp)\n\t"
          "sd       $t8, 192($sp)\n\t"
          "sd       $s7, 184($sp)\n\t"
          "sd       $s6, 176($sp)\n\t"
          "sd       $s5, 168($sp)\n\t"
          "sd       $s4, 160($sp)\n\t"
          "sd       $s3, 152($sp)\n\t"
          "sd       $s2, 144($sp)\n\t"
          "sd       $s1, 136($sp)\n\t"
          "sd       $s0, 128($sp)\n\t"
          "sd       $t3, 120($sp)\n\t"
          "sd       $t2, 112($sp)\n\t"
          "sd       $t1, 104($sp)\n\t"
          "sd       $t0, 96($sp)\n\t"
          "sd       $a7, 88($sp)\n\t"
          "sd       $a6, 80($sp)\n\t"
          "sd       $a5, 72($sp)\n\t"
          "sd       $a4, 64($sp)\n\t"
          "sd       $a3, 56($sp)\n\t"
          "sd       $a2, 48($sp)\n\t"
          "sd       $a1, 40($sp)\n\t"
          "sd       $a0, 32($sp)\n\t"
          "sd       $v1, 24($sp)\n\t"
          "sd       $v0, 16($sp)\n\t"
          "sd       $at,  8($sp)\n\t"
          "sd       $zero, 0($sp)\n\t"
         );
    exception_handler();
    // restore registers
    __asm(".set noat\n\t"
          "ld       $t9, 200($sp)\n\t"
          "ld       $t8, 192($sp)\n\t"
          "ld       $s7, 184($sp)\n\t"
          "ld       $s6, 176($sp)\n\t"
          "ld       $s5, 168($sp)\n\t"
          "ld       $s4, 160($sp)\n\t"
          "ld       $s3, 152($sp)\n\t"
          "ld       $s2, 144($sp)\n\t"
          "ld       $s1, 136($sp)\n\t"
          "ld       $s0, 128($sp)\n\t"
          "ld       $t3, 120($sp)\n\t"
          "ld       $t2, 112($sp)\n\t"
          "ld       $t1, 104($sp)\n\t"
          "ld       $t0, 96($sp)\n\t"
          "ld       $a7, 88($sp)\n\t"
          "ld       $a6, 80($sp)\n\t"
          "ld       $a5, 72($sp)\n\t"
          "ld       $a4, 64($sp)\n\t"
          "ld       $a3, 56($sp)\n\t"
          "ld       $a2, 48($sp)\n\t"
          "ld       $a1, 40($sp)\n\t"
          "ld       $a0, 32($sp)\n\t"
          "ld       $v1, 24($sp)\n\t"
          "ld       $v0, 16($sp)\n\t"
          "ld       $at, 8($sp)\n\t"
          "daddiu   $sp, $sp,208\n\t"
         );
}
