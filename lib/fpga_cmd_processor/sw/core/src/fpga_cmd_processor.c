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

#include "fpga_cmd_processor.h"
#include "testimage.h"
#include "code_segments.h"

int main(){
	// invalidate all packet slots
	invalidate_aql_packets();

	// initialize cores
	write_core_code();

	// single producer queue
	uint64_t packet_index = (*WRITE_INDEX)++;
	volatile uint16_t *src_image = (volatile uint16_t*)test_image;
	volatile uint16_t *dst_image = malloc(width*height*sizeof(uint16_t));
		
	hsa_kernel_dispatch_packet_t *packet = (hsa_kernel_dispatch_packet_t*)((char*)BASE_AQL_PKT_ADDR+PACKETSIZE*packet_index);

	volatile uint64_t signal_value = 1;
	uint64_t handle = (uint64_t)(&signal_value);
	hsa_signal_t signal = {handle};

	// kernargs: src_address (64 bit) | dest_address (64 bit) | colormodel (8 bit) | borderhandling (8 bit) | threshold (16 bit) 
	volatile uint8_t *kernargs           = malloc(20);
	*((volatile uint64_t*)kernargs)      = (uint64_t)src_image;
	*((volatile uint64_t*)(kernargs+8))  = (uint64_t)dst_image;
	*(kernargs+16)                       = UINT16_GRAY_SCALE;
	*(kernargs+17)                       = CLAMP_TO_ZERO;
	*((volatile uint16_t*)(kernargs+18)) = 0;

	packet->kernel_object = SOBELXY3x3;
	packet->kernarg_address = (void*)kernargs;
	packet->grid_size_x = width;
	packet->grid_size_y = height;
	packet->completion_signal = signal;
		
	BASE_PASID_BUF_ADDR[packet_index] = 7;
	
	// atomically assign packet to packet processor
	uint32_t hs = (setup(2) << 16) | header(HSA_PACKET_TYPE_KERNEL_DISPATCH,0,HSA_FENCE_SCOPE_SYSTEM,HSA_FENCE_SCOPE_SYSTEM);
	*((volatile uint32_t*)packet) = hs;
	send_aql_interrupt();

	// wait for completion
	while(signal_value == 1){}

	free((uint16_t*)dst_image);
	free((uint8_t*)kernargs);
}

void invalidate_aql_packets(){
	for(unsigned int i=0; i<MAX_QUEUE_LENGTH; ++i){
		hsa_kernel_dispatch_packet_t *packet = (hsa_kernel_dispatch_packet_t*)((char*)BASE_AQL_PKT_ADDR+PACKETSIZE*i);
		packet->header = HSA_PACKET_TYPE_INVALID;
	}
}

void write_core_code(){
	char *segment_base = (char*)BASE_CODE_SPACE_ADDR;
	for(unsigned int i=0; i<AVAILABLE_CORES+1; ++i){
		/*uint64_t *current_address = (uint64_t*)segment_base;
		if(code_vector[i].instructions != NULL){
			// write instruction segment
			for(unsigned int line=0; line<code_vector[i].imem_length; ++line){
				current_address[line] = (code_vector[i].instructions)[line];
			}
			segment_base += CODE_SEGMENT_ADDR_SPACE_LEN;
			current_address = (uint64_t*)segment_base;

			// write code segment
			for(unsigned int line=0; line<code_vector[i].dmem_length; ++line){
				current_address[line] = (code_vector[i].data)[line];
			}
			segment_base += CODE_SEGMENT_ADDR_SPACE_LEN;
		}*/
	
		// notify processor
		if(i!=0){
			change_accelerator_state(i);
		}
	}
	change_packet_processor_state();
}

void interrupt_transfer(){
	const uint64_t length   = *DMA_PAYLOAD_SIZE_ADDR;
	const uint64_t length64 = length >> 3;
	const uint64_t length8  = length - (length64 << 3);
	uint8_t *src = (uint8_t*)(*DMA_DEVICE_ADDR);
	uint8_t *dst = (uint8_t*)(*DMA_HOST_ADDR);
	
	if(*DMA_LDST_ADDR == LOAD_DATA){
		src = (uint8_t*)(*DMA_HOST_ADDR);
		dst = (uint8_t*)(*DMA_DEVICE_ADDR);
	}

	// write as much as possible in doubleword steps	
	for(unsigned int i=0; i<length64; ++i){
		*((uint64_t*)dst) = *((uint64_t*)src);
		src += 8;
		dst += 8;
	}
	
	// write rest in byte steps	
	for(unsigned int i=0; i<length8; ++i){
		*dst = *src;
		++src;
		++dst;
	}
	send_dma_interrupt();
}

void interrupt_completion(){
	--(*((volatile uint64_t*)(*CMPL_SIG_ADDR)));
	send_completion_interrupt();
}

void interrupt_added_core(){
	send_add_core_interrupt();
}

void interrupt_removed_core(){
	send_remove_core_interrupt();
}
