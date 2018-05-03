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

#ifndef PACKET_PROCESSOR_H_
#define PACKET_PROCESSOR_H_

#include <stdbool.h>
#include <stdlib.h>

#include "packet_processor_exceptions.h"
#include "hsa_packets.h"
#include "hsa_fpga.h"
#include "address_conf.h"

#ifndef MAX_QUEUE_LENGTH
#define MAX_QUEUE_LENGTH 128
#endif

#ifndef AVAILABLE_CORES
#define AVAILABLE_CORES 1
#endif

#ifndef DISPATCH_WINDOW_SIZE
#define DISPATCH_WINDOW_SIZE 8
#endif

typedef enum {
	GET_KERNARG = 0x00,
	GET_IMAGE = 0x01,
	PROCESSING = 0x02,
	STORE_IMAGE = 0x03,
	COMPLETION = 0x04,
} kernel_status_t;

struct core_info_t{
	bool running;
	uint32_t packet_id;
};

struct kernel_info_t{
	hsa_kernel_dispatch_packet_t *kp_addr;
	kernel_status_t status;
	uint32_t pasid;
	uint64_t local_kernarg_address;
	uint64_t local_image_address;
};

struct dma_request_t{	
	uint64_t packet_id;
	uint64_t host_address;
	uint64_t device_address;
	uint64_t payload_size;
	uint32_t ldst;
	uint32_t pasid;
};

struct launch_request_t{	
	uint64_t packet_id;
	uint16_t kernel;
	uint16_t normalization;
	uint16_t threshold;
	uint8_t  colormodel;
	uint8_t  borderhandling;
	uint32_t sizex;
	uint32_t sizey;
	uint64_t src_address;
	uint64_t dst_address;
	int32_t *custom_mask;
};

struct decrement_request_t{
	uint64_t packet_id;
	uint64_t signal_handle;
	uint32_t pasid;
};

//main Packet Processor functions
void process_aql_packets();
void process_dma_queue();
void process_launch_queue();
void process_dec_queue();

// custom_mask ignored for fixed functions
void write_mask_to_core(const uint32_t core, const fpga_operation_type_t operation, int32_t *custom_mask);

// helper functions
inline void send_dma_interrupt(){
	*SND_INT = AVAILABLE_CORES+3;	
}

inline void send_completion_interrupt(){
	*SND_INT = AVAILABLE_CORES+2;	
}

inline void send_added_core_interrupt(){
	*SND_INT = AVAILABLE_CORES+1;	
}

inline void send_removed_core_interrupt(){
	*SND_INT = AVAILABLE_CORES;	
}

inline void send_interrupt_to_core(int number){
	*SND_INT = number;
}

inline void enable_interrupts(){
	const unsigned int status_reg_mask = 0x00000FC01;
	__asm__("mtc0 %0,$12\n\t"        // asm code
		 :                       // outputs optional
		 : "r"(status_reg_mask)  // inputs optional
		 :                       // clobbered registers optional
		 );
}

inline void disable_interrupts(){
	const unsigned int status_reg_mask = 0x00000FC00;
	__asm__("mtc0 %0,$12\n\t"        // asm code
		 :                       // outputs optional
		 : "r"(status_reg_mask)  // inputs optional
		 :                       // clobbered registers optional
		 );
}

#endif
