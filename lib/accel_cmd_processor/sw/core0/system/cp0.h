// Copyright (C) 2017 Tobias Lieske
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

// exception codes stored in the cp0_cause register

enum CP0_CAUSE_EXC_CODE {
    C_CP0_CAUSE_EXC_CODE_INT     = 0x00, // Interrupt
    C_CP0_CAUSE_EXC_CODE_ADEL    = 0x04, // Address error exception (load or instruction fetch)
    C_CP0_CAUSE_EXC_CODE_ADES    = 0x05, // Address error exception (store)
    C_CP0_CAUSE_EXC_CODE_IBE     = 0x06, // Bus error exception (instruction fetch)
    C_CP0_CAUSE_EXC_CODE_DBE     = 0x07, // Bus error exception (data reference: load or store)
    C_CP0_CAUSE_EXC_CODE_SYS     = 0x08, // Syscall exception
    C_CP0_CAUSE_EXC_CODE_BP      = 0x09, // Breakpoint exception
    C_CP0_CAUSE_EXC_CODE_RI      = 0x0A, // Reserved instruction exception
    C_CP0_CAUSE_EXC_CODE_CPU     = 0x0B, // Coprocessor Unusable exception
    C_CP0_CAUSE_EXC_CODE_OV      = 0x0C, // Arithmetic Overflow exception
    C_CP0_CAUSE_EXC_CODE_TR      = 0x0D, // Trap exception
    // 0x0E is reserved
    C_CP0_CAUSE_EXC_CODE_FPE     = 0x0F, // Floating point exception
};



void setCoprocessor0StatusReg(unsigned int value);


