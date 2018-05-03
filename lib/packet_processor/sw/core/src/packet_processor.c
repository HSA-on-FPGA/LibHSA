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

#include "packet_processor.h"

// global kernel data
struct kernel_info_t pending_packets[DISPATCH_WINDOW_SIZE];
struct core_info_t core_usage[AVAILABLE_CORES];
volatile uint16_t free_slots[DISPATCH_WINDOW_SIZE];
volatile uint32_t remaining_dispatch_slots = DISPATCH_WINDOW_SIZE;
volatile uint32_t current_dma_packet_id = UINT32_MAX;
volatile uint32_t current_cmpl_packet_id = UINT32_MAX;
uint64_t current_packet_number = 0;

// DMA queue (DMA is only requested by main program and not by interrupts to prevend deadlocks)
struct dma_request_t dma_queue[DISPATCH_WINDOW_SIZE];
volatile uint64_t dma_request_read_index = 0;
volatile uint64_t dma_request_write_index = 0;

// Kernel launch queue (also to prevent deadlocks)
struct launch_request_t launch_queue[DISPATCH_WINDOW_SIZE];
volatile uint64_t launch_request_read_index = 0;
volatile uint64_t launch_request_write_index = 0;

// Completion signal decrement queue (also to prevent deadlocks)
struct decrement_request_t dec_queue[DISPATCH_WINDOW_SIZE];
volatile uint64_t dec_request_read_index = 0;
volatile uint64_t dec_request_write_index = 0;

int main(){
	// initialize dispatch window stack
	for(uint16_t i=0; i<DISPATCH_WINDOW_SIZE; ++i){
		free_slots[i] = i;
	}
	while(true){
		process_aql_packets();
		process_dma_queue();
		process_launch_queue();
		process_dec_queue();
	}
}

void process_aql_packets(){
	// start processing if the packet queue is not empty
	if(*AQL_LEFT && remaining_dispatch_slots > 0){
		// process AQL packet header
		uint32_t packet_index = current_packet_number & (MAX_QUEUE_LENGTH-1);
		void *current_packet_address = (void*)(((char*)BASE_AQL_PKT_ADDR)+(PACKETSIZE*packet_index));
		uint16_t header = *((uint16_t*)current_packet_address);
		int type = (header >> HSA_PACKET_HEADER_TYPE) & ((1 << HSA_PACKET_HEADER_WIDTH_TYPE)-1);
		// if barrier bit is set, block until the current packet index equals the last completed (READ_INDEX)
		int barrier = (header >> HSA_PACKET_HEADER_BARRIER) & ((1 << HSA_PACKET_HEADER_WIDTH_BARRIER)-1);
		while(barrier && current_packet_number!=*READ_INDEX){}

		// process different packet types
		bool valid_packet = true;
		switch(type){
			case HSA_PACKET_TYPE_VENDOR_SPECIFIC: break;
			case HSA_PACKET_TYPE_INVALID: {
				valid_packet = false; 
				break;}
			case HSA_PACKET_TYPE_KERNEL_DISPATCH: {
				// kernargs: src_address (64 bit) | dest_address (64 bit) | colormodel (8 bit) | borderhandling (8 bit) | threshold (16 bit) 
				//           (| optional: normalization (16 bit + 16 bit padding) | filter mask (25x4 byte or 9x4 byte))
				hsa_kernel_dispatch_packet_t *kp = (hsa_kernel_dispatch_packet_t*)current_packet_address;
				// copy the kernel arguments to on board DRAM
				int kernarg_mem_size = 20; // 20 byte default
				if(kp->kernel_object == CUSTOM_FILTER3x3){
					kernarg_mem_size = 60; // default size + 36 byte mask + 4 byte normalization
				} else if(kp->kernel_object == CUSTOM_FILTER5x5){
					kernarg_mem_size = 124; // default size + 100 byte mask + 4 byte normalization
				}
				void *local_kernargs = malloc(kernarg_mem_size);
				uint32_t pasid = BASE_PASID_BUF_ADDR[packet_index];
				// write kernel information
				disable_interrupts();
				--remaining_dispatch_slots;
				uint16_t packet_window_index = free_slots[remaining_dispatch_slots];
				pending_packets[packet_window_index].kp_addr = kp;
				pending_packets[packet_window_index].status = GET_KERNARG;
				pending_packets[packet_window_index].pasid = pasid;
				pending_packets[packet_window_index].local_kernarg_address = (uint64_t)local_kernargs;
				// write DMA request to queue
				uint64_t dma_queue_index = dma_request_write_index & (DISPATCH_WINDOW_SIZE-1);
				dma_queue[dma_queue_index].packet_id      = packet_window_index;
				dma_queue[dma_queue_index].host_address   = (uint64_t)(kp->kernarg_address);
				dma_queue[dma_queue_index].device_address = (uint64_t)local_kernargs;
				dma_queue[dma_queue_index].payload_size   = kernarg_mem_size;
				dma_queue[dma_queue_index].ldst           = LOAD_DATA;
				dma_queue[dma_queue_index].pasid          = pasid;
				++dma_request_write_index;
				enable_interrupts();
                        	break;}
			case HSA_PACKET_TYPE_BARRIER_AND: {
				hsa_barrier_and_packet_t *bpa = (hsa_barrier_and_packet_t*)current_packet_address;
				// wait until all depending signals are set
				int not_ready = 0;
				do{
					not_ready = 0;
					for(unsigned int i=0; i<5; ++i){
						if(bpa->dep_signal[i].handle != 0){
							if(*((int64_t*)(bpa->dep_signal[i].handle)) != 0){
								not_ready = 1;
							}
						}
					}
				}while(not_ready);
				// atomic decrement completion signal if signal is set
				if(bpa->completion_signal.handle != 0){
					disable_interrupts();
					uint64_t dec_queue_index = dec_request_write_index & (DISPATCH_WINDOW_SIZE-1);
					dec_queue[dec_queue_index].packet_id     = packet_index;
					dec_queue[dec_queue_index].signal_handle = bpa->completion_signal.handle;
					dec_queue[dec_queue_index].pasid         = BASE_PASID_BUF_ADDR[packet_index];
					++dec_request_write_index;
					enable_interrupts();
				}else{
					bpa->header = HSA_PACKET_TYPE_INVALID;
					++(*READ_INDEX);
				}
				break;}
			case HSA_PACKET_TYPE_AGENT_DISPATCH: break;
			case HSA_PACKET_TYPE_BARRIER_OR: {
				hsa_barrier_and_packet_t *bpo = (hsa_barrier_and_packet_t*)current_packet_address;
				// wait until one depending signal is set
				int is_set = 1;
				do{
					is_set = 1;
					for(unsigned int i=0; i<5; ++i){
						if(bpo->dep_signal[i].handle != 0){
							if(*((int64_t*)(bpo->dep_signal[i].handle)) == 0){
								is_set = 0;
								break;
							}
						}
					}
				}while(is_set);
				// atomic decrement completion signal if signal is set
				if(bpo->completion_signal.handle != 0){
					disable_interrupts();
					uint64_t dec_queue_index = dec_request_write_index & (DISPATCH_WINDOW_SIZE-1);
					dec_queue[dec_queue_index].packet_id     = packet_index;
					dec_queue[dec_queue_index].signal_handle = bpo->completion_signal.handle;
					dec_queue[dec_queue_index].pasid         = BASE_PASID_BUF_ADDR[packet_index];
					++dec_request_write_index;
					enable_interrupts();
				}else{
					bpo->header = HSA_PACKET_TYPE_INVALID;
					++(*READ_INDEX);
				}
				break;}
			default: break;
		}
		if(valid_packet){
			++current_packet_number;
			// if the queue is empty, set the AQL_LEFT register to 0 (disable the Packet Processor)
			if(current_packet_number == *WRITE_INDEX){
				*AQL_LEFT = 0;
			}
		}
	}
}

void process_dma_queue(){
	disable_interrupts();
	if(dma_request_read_index != dma_request_write_index && current_dma_packet_id == UINT32_MAX){
		// write DMA configuration
		uint64_t dma_queue_index = dma_request_read_index & (DISPATCH_WINDOW_SIZE-1);
		*DMA_HOST_ADDR         = dma_queue[dma_queue_index].host_address;
		*DMA_DEVICE_ADDR       = dma_queue[dma_queue_index].device_address;
		*DMA_PAYLOAD_SIZE_ADDR = dma_queue[dma_queue_index].payload_size;
		*DMA_LDST_ADDR         = dma_queue[dma_queue_index].ldst;
		*DMA_PASID_ADDR        = dma_queue[dma_queue_index].pasid;
               	current_dma_packet_id  = dma_queue[dma_queue_index].packet_id;
		// send interrupt to TPC
		send_dma_interrupt();
		++dma_request_read_index;
	}
	enable_interrupts();
}

void process_launch_queue(){
	disable_interrupts();
	//select next free core (if possible)
	unsigned int next_core = 0;
	for(; next_core<AVAILABLE_CORES; ++next_core){
		if(!core_usage[next_core].running){
			break;
		}
	}
	// launch kernel if there is work and a idle core is available
	if(launch_request_read_index != launch_request_write_index && next_core < AVAILABLE_CORES){
		// write kernel configuration
		uint64_t launch_queue_index = launch_request_read_index & (DISPATCH_WINDOW_SIZE-1);
		volatile char *core_base_addr = BASE_ACCEL_ADDR+next_core*ACCEL_ADDR_SPACE_LEN;
		*((volatile uint16_t*)(core_base_addr+TASK_OFFSET))            = launch_queue[launch_queue_index].kernel;
		*((volatile uint16_t*)(core_base_addr+NORMALIZATION_OFFSET))   = launch_queue[launch_queue_index].normalization;
		*((volatile uint16_t*)(core_base_addr+THRESHOLD_OFFSET))       = launch_queue[launch_queue_index].threshold;
		*((volatile uint8_t* )(core_base_addr+COLOR_MODEL_OFFSET))     = launch_queue[launch_queue_index].colormodel;
		*((volatile uint8_t* )(core_base_addr+BORDER_HANDLING_OFFSET)) = launch_queue[launch_queue_index].borderhandling;
		*((volatile uint32_t*)(core_base_addr+IMG_WIDTH_OFFSET))       = launch_queue[launch_queue_index].sizex;
		*((volatile uint32_t*)(core_base_addr+IMG_HEIGHT_OFFSET))      = launch_queue[launch_queue_index].sizey;
		*((volatile uint64_t*)(core_base_addr+SRC_ADDR_OFFSET))        = launch_queue[launch_queue_index].src_address;
		*((volatile uint64_t*)(core_base_addr+DST_ADDR_OFFSET))        = launch_queue[launch_queue_index].dst_address;
		write_mask_to_core(next_core,launch_queue[launch_queue_index].kernel,launch_queue[launch_queue_index].custom_mask);
		// mark core as busy
		core_usage[next_core].running = true;
		core_usage[next_core].packet_id = launch_queue[launch_queue_index].packet_id;
		// send interrupt to accelerator core
		send_interrupt_to_core(next_core);
		++launch_request_read_index;
	}
	enable_interrupts();
}

void process_dec_queue(){
	disable_interrupts();
	if(dec_request_read_index != dec_request_write_index && current_cmpl_packet_id == UINT32_MAX){
		// write configuration to registers
		uint64_t dec_queue_index = dec_request_read_index & (DISPATCH_WINDOW_SIZE-1);
		*CMPL_SIG_ADDR         = dec_queue[dec_queue_index].signal_handle;
		*CMPL_SIG_PASID_ADDR   = dec_queue[dec_queue_index].pasid;	
		current_cmpl_packet_id = dec_queue[dec_queue_index].packet_id;
		// send interrupt to TPC
		send_completion_interrupt();
		++dec_request_read_index;
	}
	enable_interrupts();
}

void interrupt_transfer(){
	switch(pending_packets[current_dma_packet_id].status){
		case GET_KERNARG:{
			hsa_kernel_dispatch_packet_t *kp = pending_packets[current_dma_packet_id].kp_addr;
			volatile uint64_t *local_kernargs = (volatile uint64_t*)pending_packets[current_dma_packet_id].local_kernarg_address;
			uint64_t src_address = *local_kernargs;
			uint8_t colormodel = *(((volatile uint8_t*)local_kernargs)+16);
			// transfer source image to on board DRAM
			int storage = kp->grid_size_x*kp->grid_size_y*get_pixel_storage(colormodel);
			void *dram_dest = malloc(storage);
			pending_packets[current_dma_packet_id].local_image_address = (uint64_t)dram_dest;
			pending_packets[current_dma_packet_id].status = GET_IMAGE;
			// write DMA request to queue
			uint64_t dma_queue_index = dma_request_write_index & (DISPATCH_WINDOW_SIZE-1);
			dma_queue[dma_queue_index].packet_id      = current_dma_packet_id;
			dma_queue[dma_queue_index].host_address   = src_address;
			dma_queue[dma_queue_index].device_address = (uint64_t)dram_dest;
			dma_queue[dma_queue_index].payload_size   = storage;
			dma_queue[dma_queue_index].ldst           = LOAD_DATA;
			dma_queue[dma_queue_index].pasid          = pending_packets[current_dma_packet_id].pasid;
			++dma_request_write_index;
			break;}
		case GET_IMAGE:{
			// calculate needed addresses and arguments
			hsa_kernel_dispatch_packet_t *kp = pending_packets[current_dma_packet_id].kp_addr;
			uint16_t kernel = kp->kernel_object;
			volatile uint64_t *local_kernargs = (volatile uint64_t*)pending_packets[current_dma_packet_id].local_kernarg_address;
			uint8_t colormodel = *(((volatile uint8_t*)local_kernargs)+16);
			uint8_t borderhandling = *(((volatile uint8_t*)local_kernargs)+17);
			uint16_t threshold = *(((volatile uint16_t*)local_kernargs)+9);
			uint64_t local_src_dst_addr = pending_packets[current_dma_packet_id].local_image_address;//assuming core supports fullbuffering
			int32_t *custom_mask = NULL;
			uint16_t normalization = 0;
			if(kernel == CUSTOM_FILTER3x3 || kernel == CUSTOM_FILTER5x5){
				custom_mask   = ((int32_t*)local_kernargs)+5;
				normalization = *(((volatile uint16_t*)local_kernargs)+10);
			}else if(kernel == GAUSS3x3){
				normalization = gauss_3x3_normalization;
			}else if(kernel == GAUSS5x5){
				normalization = gauss_5x5_normalization;
			}
			pending_packets[current_dma_packet_id].status = PROCESSING;
			// write configuration to launch queue
			uint64_t launch_queue_index = launch_request_write_index & (DISPATCH_WINDOW_SIZE-1);
			launch_queue[launch_queue_index].packet_id      = current_dma_packet_id;
			launch_queue[launch_queue_index].kernel         = kernel;
			launch_queue[launch_queue_index].normalization  = normalization;
			launch_queue[launch_queue_index].threshold      = threshold;
        		launch_queue[launch_queue_index].colormodel     = colormodel;
        		launch_queue[launch_queue_index].borderhandling = borderhandling;
        		launch_queue[launch_queue_index].sizex          = kp->grid_size_x;
        		launch_queue[launch_queue_index].sizey          = kp->grid_size_y;
        		launch_queue[launch_queue_index].src_address    = local_src_dst_addr;
        		launch_queue[launch_queue_index].dst_address    = local_src_dst_addr;
        		launch_queue[launch_queue_index].custom_mask    = custom_mask;
			++launch_request_write_index;
		break;}
		case STORE_IMAGE:{
			hsa_kernel_dispatch_packet_t *kp = pending_packets[current_dma_packet_id].kp_addr;
			// send completion signal if set
			if(kp->completion_signal.handle != 0){
				pending_packets[current_dma_packet_id].status = COMPLETION;
				// write configuration to queue
				uint64_t dec_queue_index = dec_request_write_index & (DISPATCH_WINDOW_SIZE-1);
				dec_queue[dec_queue_index].signal_handle = kp->completion_signal.handle;
				dec_queue[dec_queue_index].pasid         = pending_packets[current_dma_packet_id].pasid;
				dec_queue[dec_queue_index].packet_id     = current_dma_packet_id;
				++dec_request_write_index;
			}else{
				free((void *)(pending_packets[current_dma_packet_id].local_kernarg_address));
				free((void *)(pending_packets[current_dma_packet_id].local_image_address));
				free_slots[remaining_dispatch_slots] = current_dma_packet_id;
				++remaining_dispatch_slots;
				kp->header = HSA_PACKET_TYPE_INVALID;
				++(*READ_INDEX);
			}
		break;}
		default: break;
	}
	// clear DMA engine
	current_dma_packet_id = UINT32_MAX;
}

void interrupt_kernel(){
	// copy the image from on-board DRAM to main memory
	uint64_t packet_id = core_usage[*RCV_INT_ADDR].packet_id;
	hsa_kernel_dispatch_packet_t *kp = pending_packets[packet_id].kp_addr;
	volatile uint64_t *local_kernargs = (volatile uint64_t*)pending_packets[packet_id].local_kernarg_address;
	uint64_t dst_address = *((local_kernargs)+1);
	uint8_t colormodel = *(((volatile uint8_t*)local_kernargs)+16);
	int storage = kp->grid_size_x*kp->grid_size_y*get_pixel_storage(colormodel);
	// write DMA configuration to queue
	uint64_t dma_queue_index = dma_request_write_index & (DISPATCH_WINDOW_SIZE-1);
	dma_queue[dma_queue_index].packet_id      = packet_id;
	dma_queue[dma_queue_index].host_address   = dst_address;
	dma_queue[dma_queue_index].device_address = pending_packets[packet_id].local_image_address;
	dma_queue[dma_queue_index].payload_size   = storage;
	dma_queue[dma_queue_index].ldst           = STORE_DATA;
	dma_queue[dma_queue_index].pasid          = pending_packets[packet_id].pasid;
	++dma_request_write_index;
	// update core bookkeeping information
	pending_packets[packet_id].status = STORE_IMAGE;
	core_usage[*RCV_INT_ADDR].packet_id = UINT32_MAX;
	core_usage[*RCV_INT_ADDR].running = false;
}

void interrupt_completion(){
	free((void *)(pending_packets[current_cmpl_packet_id].local_kernarg_address));
	free((void *)(pending_packets[current_cmpl_packet_id].local_image_address));
	free_slots[remaining_dispatch_slots] = current_cmpl_packet_id;
	++remaining_dispatch_slots;
	hsa_kernel_dispatch_packet_t *packet = pending_packets[current_cmpl_packet_id].kp_addr;
	packet->header = HSA_PACKET_TYPE_INVALID;
	current_cmpl_packet_id = UINT32_MAX;
	++(*READ_INDEX);
}

void interrupt_add_core(){
	send_added_core_interrupt();
}

void interrupt_remove_core(){
	send_removed_core_interrupt();
}

void write_mask_to_core(const uint32_t core, const fpga_operation_type_t operation, int32_t *custom_mask){
	const int8_t *mask0 = NULL;
	const int8_t *mask1 = NULL;
	bool needs_write = false;
	bool write_both = false;
	bool write_custom = false;
	uint8_t custom_length = 0;
	switch(operation){
		case SOBELX3x3: {
			mask0 = sobelX_3x3_mask;
			needs_write = true;
		break;}
		case SOBELY3x3: {
			mask0 = sobelY_3x3_mask;
			needs_write = true;
		break;}
		case SOBELXY3x3: {
			mask0 = sobelX_3x3_mask;
			mask1 = sobelY_3x3_mask;
			needs_write = true;
			write_both = true;
		break;}
		case SOBELX5x5: {
			mask0 = sobelX_5x5_mask;
			needs_write = true;
		break;}
		case SOBELY5x5: {
			mask0 = sobelY_5x5_mask;
			needs_write = true;
		break;}
		case SOBELXY5x5: {
			mask0 = sobelX_5x5_mask;
			mask1 = sobelY_5x5_mask;
			needs_write = true;
			write_both = true;
		break;}
		case GAUSS3x3: {
			mask0 = gauss_3x3_mask;
			needs_write = true;
		break;}
		case GAUSS5x5: {
			mask0 = gauss_5x5_mask;
			needs_write = true;
		break;}
		case MIN_FILTER3x3: break;
		case MIN_FILTER5x5: break;
		case MAX_FILTER3x3: break;
		case MAX_FILTER5x5: break;
		case MEDIAN_FILTER3x3: break;
		case MEDIAN_FILTER5x5: break;
		case CUSTOM_FILTER3x3: {
			needs_write = true;
			write_custom = true;
			custom_length = 9;
		break;}
		case CUSTOM_FILTER5x5: {
			needs_write = true;
			write_custom = true;
			custom_length = 25;
		break;}
		default: break;
	}
	if(needs_write){
		if(write_both){
			volatile int32_t *mask0_entry = (volatile int32_t *)(BASE_ACCEL_ADDR+core*ACCEL_ADDR_SPACE_LEN+MASK0_OFFSET);
			volatile int32_t *mask1_entry = (volatile int32_t *)(BASE_ACCEL_ADDR+core*ACCEL_ADDR_SPACE_LEN+MASK1_OFFSET);
			for(int i=0; i<25; ++i){
				*mask0_entry = (int32_t)(mask0[i]);
				*mask1_entry = (int32_t)(mask1[i]);
				++mask0_entry;
				++mask1_entry;
			}
		}else if(write_custom){
			volatile int32_t *mask0_entry = (volatile int32_t *)(BASE_ACCEL_ADDR+core*ACCEL_ADDR_SPACE_LEN+MASK0_OFFSET);
			for(int i=0; i<custom_length; ++i){
				*mask0_entry = custom_mask[i];
				++mask0_entry;
			}
		}else{
			volatile int32_t *mask0_entry = (volatile int32_t *)(BASE_ACCEL_ADDR+core*ACCEL_ADDR_SPACE_LEN+MASK0_OFFSET);
			for(int i=0; i<25; ++i){
				*mask0_entry = (int32_t)(mask0[i]);
				++mask0_entry;
			}
		}
	}
}
