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

#ifndef FPGA_CMD_PROCESSOR_H_
#define FPGA_CMD_PROCESSOR_H_

#include <stdbool.h>
#include <stdlib.h>

#include "fpga_cmd_processor_exceptions.h"
#include "hsa_packets.h"
#include "hsa_fpga.h"
#include "address_conf.h"

#ifndef MAX_QUEUE_LENGTH
#define MAX_QUEUE_LENGTH 128
#endif

#ifndef AVAILABLE_CORES
#define AVAILABLE_CORES 1
#endif

// main functions
void write_core_code();
void invalidate_aql_packets();

uint16_t header(hsa_packet_type_t type, uint16_t barrier, hsa_fence_scope_t acquire, hsa_fence_scope_t release){
	uint16_t header = type << HSA_PACKET_HEADER_TYPE;
	header |= (barrier & ((1 << HSA_PACKET_HEADER_WIDTH_BARRIER)-1)) << HSA_PACKET_HEADER_BARRIER;
	header |= acquire << HSA_PACKET_HEADER_SCACQUIRE_FENCE_SCOPE;
	header |= release << HSA_PACKET_HEADER_SCRELEASE_FENCE_SCOPE;
	return header;
}

uint16_t setup(uint16_t dims) {
	return (dims & ((1 << HSA_KERNEL_DISPATCH_PACKET_SETUP_WIDTH_DIMENSIONS)-1)) << HSA_KERNEL_DISPATCH_PACKET_SETUP_DIMENSIONS;
}

// helper functions
static inline void send_aql_interrupt(){
	*SND_INT = 4;
}

static inline void send_dma_interrupt(){
	*SND_INT = 3;	
}

static inline void send_completion_interrupt(){
	*SND_INT = 2;
}

static inline void send_add_core_interrupt(){
	*SND_INT = 1;
}

static inline void send_remove_core_interrupt(){
	*SND_INT = 0;
}

static inline void change_packet_processor_state(){
	*CPU_HALT = 0;
}

static inline void change_accelerator_state(unsigned int number){
	*CPU_HALT = number;
}

static inline void enable_interrupts(){
	const unsigned int status_reg_mask = 0x00000FC01;
	__asm__("mtc0 %0,$12\n\t"        // asm code
		 :                       // outputs optional
		 : "r"(status_reg_mask)  // inputs optional
		 :                       // clobbered registers optional
		 );
}

static inline void disable_interrupts(){
	const unsigned int status_reg_mask = 0x00000FC00;
	__asm__("mtc0 %0,$12\n\t"        // asm code
		 :                       // outputs optional
		 : "r"(status_reg_mask)  // inputs optional
		 :                       // clobbered registers optional
		 );
}

#endif
