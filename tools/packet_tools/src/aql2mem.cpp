// Copyright (C) 2017 Philipp Holzinger
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

#include <iostream>
#include <cstdint>
#include <string>
#include <fstream>

#include "hsa_packets.h"

#ifndef MAX_QUEUE_LENGTH
#define MAX_QUEUE_LENGTH 128
#endif

int get_ptype_int_representation(std::string s){
	if(s.compare("AGENT_DISPATCH")==0){
		return HSA_PACKET_TYPE_AGENT_DISPATCH;
	}else if(s.compare("VENDOR_SPECIFIC")==0){
		return HSA_PACKET_TYPE_VENDOR_SPECIFIC;
	}else if(s.compare("KERNEL_DISPATCH")==0){
		return HSA_PACKET_TYPE_KERNEL_DISPATCH;
	}else if(s.compare("BARRIER_AND")==0){
		return HSA_PACKET_TYPE_BARRIER_AND;
	}else if(s.compare("BARRIER_OR")==0){
		return HSA_PACKET_TYPE_BARRIER_OR;
	}else if(s.compare("INVALID")==0){
		return HSA_PACKET_TYPE_INVALID;
	}else{
		return -1;
	}
}

int get_barrier_int_representation(std::string s){
	if(s.compare("y")==0){
		return 1;
	}else if(s.compare("n")==0){
		return 0;
	}else{
		return -1;
	}
}

void printfile(const char *filename, void *packet_begin, uint32_t *pasid, unsigned int length){
	uint64_t *write = (uint64_t*)packet_begin;
	unsigned int line = 0;
	std::ofstream file(filename);
		
	// header for modelsim
	file << "// instance=/tb_packet_processor_top/inst_dram/bram" << std::endl;
	file << "// format=mti addressradix=d dataradix=h version=1.0 wordsperline=2" << std::endl;

	// write AQL packets
	for(unsigned int i=0; i<(length*(PACKETSIZE/8))/2; ++i){
		file << std::dec;
		file << line << ": ";
		file.width(16);
		file.fill('0');
		file << std::hex;
		file << *write << " ";	
		file.width(16);
		file.fill('0');
		file << *(write+1) << std::endl;
		write += 2;
		line += 2;
	}

	// write PASIDs
	line = MAX_QUEUE_LENGTH*(PACKETSIZE/8);
	unsigned int lines_to_write = (length+(4-(length&3))) >> 2;
	for(unsigned int i=0; i<lines_to_write; i+=4){
		file << std::dec;
		file << line << ": ";
		file.width(8);
		file.fill('0');
		file << std::hex;
		file << pasid[i+1];
		file.width(8);
		file.fill('0');
		file << pasid[i] << " ";	
		file.width(8);
		file.fill('0');
		file << pasid[i+3];
		file.width(8);
		file.fill('0');
		file << pasid[i+2] << std::endl;
		line += 2;
	}

	// write READ and WRITE INDEX
	line = MAX_QUEUE_LENGTH*(PACKETSIZE/8) + (MAX_QUEUE_LENGTH*4)/8;
	file << std::dec;
	file << line << ": ";
	file.width(16);
	file.fill('0');
	file << std::hex;
	file << 0x0 << " ";
	file.width(16);
	file.fill('0');
	file << length << std::endl;
}

uint16_t header(hsa_packet_type_t type){
	uint16_t header = type << HSA_PACKET_HEADER_TYPE;
	header |= 0 << HSA_PACKET_HEADER_BARRIER;
	header |= HSA_FENCE_SCOPE_NONE << HSA_PACKET_HEADER_SCACQUIRE_FENCE_SCOPE;
	header |= HSA_FENCE_SCOPE_NONE << HSA_PACKET_HEADER_SCRELEASE_FENCE_SCOPE;
	return header;
}

uint16_t header(hsa_packet_type_t type, uint16_t barrier){
	uint16_t header = type << HSA_PACKET_HEADER_TYPE;
	header |= (barrier & ((1 << HSA_PACKET_HEADER_WIDTH_BARRIER)-1)) << HSA_PACKET_HEADER_BARRIER;
	header |= HSA_FENCE_SCOPE_NONE << HSA_PACKET_HEADER_SCACQUIRE_FENCE_SCOPE;
	header |= HSA_FENCE_SCOPE_NONE << HSA_PACKET_HEADER_SCRELEASE_FENCE_SCOPE;
	return header;
}

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

int main(int argc, char *argv[]){
	
	if(argc != 2 && argc != 3){
		std::cout << "wrong usage: first argument must be output filename [optional: second argument string containing \"default\" for one or a number for more packets]" << std::endl;
	}

	char *alloc = new char[PACKETSIZE*MAX_QUEUE_LENGTH];
	// clear ram location
	for(int i=0; i<PACKETSIZE*MAX_QUEUE_LENGTH; ++i){
		alloc[i] = 0;
	}
	void *packet_begin = (void*)alloc;
	unsigned int packet_queue_end_idx = 0;

	uint32_t *pasid = new uint32_t[MAX_QUEUE_LENGTH];

	// printing default aql packet if desired
	if(argc==3){
		unsigned int num_packets = 1;
		std::string arg2(argv[2]);
		if(arg2.compare("default")!=0){
			num_packets = static_cast<unsigned int>(std::atoi(argv[2]));
		}
		if(num_packets > MAX_QUEUE_LENGTH){
			std::cerr << "ERROR: more than MAX_QUEUE_LENGTH " << MAX_QUEUE_LENGTH << " packets not statically assignable!!" << std::endl;
			return EXIT_FAILURE;
		}
		
		uint64_t op = UINT64_C(0x000100000000FFFF);
		uint32_t dim = 1;
		uint32_t sizex = 1024;
		uint32_t sizey = 1;
		uint32_t sizez = 1;
		uint32_t wgsizex = 64;
		uint32_t wgsizey = 1;
		uint32_t wgsizez = 1;
	
		uint64_t *kernargs = new uint64_t[4];
		
		uint32_t pid = 15;
		
		for(unsigned int i=0; i<num_packets; ++i){
			hsa_kernel_dispatch_packet_t *packet = (hsa_kernel_dispatch_packet_t*)((char*)packet_begin+PACKETSIZE*packet_queue_end_idx);

			int64_t *signal_value = new int64_t;
			*signal_value = 1;
			uint64_t handle = (uint64_t)signal_value;
			hsa_signal_t signal = {handle};

			uint64_t *kernargs = new uint64_t[4];
		
			// NOTE: this is just for test purposes so the header is not written atomically
			packet->header = header(HSA_PACKET_TYPE_KERNEL_DISPATCH);
			packet->setup = setup(dim);
			packet->kernel_object = (uint64_t)op;
			packet->kernarg_address = (void*)kernargs;
			packet->grid_size_x = sizex;
			packet->grid_size_y = sizey;
			packet->grid_size_z = sizez;
			packet->workgroup_size_x = wgsizex;
			packet->workgroup_size_y = wgsizey;
			packet->workgroup_size_z = wgsizez;
			packet->completion_signal = signal;
		
			pasid[packet_queue_end_idx] = pid;
		
			++packet_queue_end_idx;

			delete[] kernargs;
			delete signal_value;
		}
	}else{
		bool adding = true;
		while(adding){
			int ptype = 0;
			std::string ptypestring = "";
			std::cout << "NEW PACKET: (END to finish)" << std::endl;
			do{
				std::cout << "specify packet type: ";
				std::cin >> ptypestring;
				ptype = get_ptype_int_representation(ptypestring);
				if(ptypestring.compare("END")==0){
					adding = false;
					ptype = -1;
					break;
				}
			}while(ptype == -1);
			if(ptype != -1){
				std::cout << "packet type: " << ptype << std::endl;
				uint32_t pid = 1;
				std::cout << "enter Process ID: ";
				std::cin >> pid;
				pasid[packet_queue_end_idx] = pid;
			}

			uint16_t barrier = 0;
			std::string barrierstring = "";
			do{
				std::cout << "setup barrier (y/n): ";
				std::cin >> barrierstring;
				barrier = get_barrier_int_representation(barrierstring);
			}while(barrier == -1);
	
			if(ptype == HSA_PACKET_TYPE_KERNEL_DISPATCH){
				uint64_t op = 0;
				uint32_t dim = 0;
				uint32_t sizex = 1;
				uint32_t sizey = 1;
				uint32_t sizez = 1;
				uint32_t wgsizex = 1;
				uint32_t wgsizey = 1;
				uint32_t wgsizez = 1;
	
				std::cout << "enter kernel dispatch packet: " << std::endl;
				std::cout << "enter kernel handle: ";
				std::cin >> op;
				do{
					std::cout << "enter number of dimensions (1-3): ";
					std::cin >> dim;
				}while(dim>3 || dim==0);
				if(dim >=1){
					std::cout << "enter size x: ";
					std::cin >> sizex;
					std::cout << "enter workgroup size x: ";
					std::cin >> wgsizex;
				}
				if(dim >=1){
					std::cout << "enter size y: ";
					std::cin >> sizey;
					std::cout << "enter workgroup size y: ";
					std::cin >> wgsizey;
				}
				if(dim >=1){
					std::cout << "enter size z: ";
					std::cin >> sizez;
					std::cout << "enter workgroup size z: ";
					std::cin >> wgsizez;
				}
				
				hsa_kernel_dispatch_packet_t *packet = (hsa_kernel_dispatch_packet_t*)((char*)packet_begin+PACKETSIZE*packet_queue_end_idx);
	
				int64_t *signal_value = new int64_t;
				*signal_value = 1;
				uint64_t handle = (uint64_t)signal_value;
				hsa_signal_t signal = {handle};
	
				uint64_t *kernargs = new uint64_t[4];

				// NOTE: this is just for test purposes so the header is not written atomically
				packet->header = header(HSA_PACKET_TYPE_KERNEL_DISPATCH,barrier);
				packet->setup = setup(dim);
				packet->kernel_object = (uint64_t)op;
				packet->kernarg_address = (void*)kernargs;
				packet->grid_size_x = sizex;
				packet->grid_size_y = sizey;
				packet->grid_size_z = sizez;
				packet->workgroup_size_x = wgsizex;
				packet->workgroup_size_y = wgsizey;
				packet->workgroup_size_z = wgsizez;
				packet->completion_signal = signal;
				
				++packet_queue_end_idx;
	
				delete[] kernargs;
				delete signal_value;
			}else if(ptype == HSA_PACKET_TYPE_AGENT_DISPATCH){
				std::cout << "agent dispatch packets are not supported by our packet processor" << std::endl;
			}else if(ptype == HSA_PACKET_TYPE_BARRIER_AND){
				int numsig = 0;
	
				std::cout << "enter barrier_and packet: " << std::endl;
				do{
					std::cout << "enter number of signals: ";
					std::cin >> numsig;
				}while(numsig > 5 || numsig < 1);
	
				hsa_barrier_and_packet_t *packet = (hsa_barrier_and_packet_t*)((char*)packet_begin+PACKETSIZE*packet_queue_end_idx);
				
				packet->header = header(HSA_PACKET_TYPE_BARRIER_AND,barrier);
				int64_t **signal_values = new int64_t*[numsig];
				for(unsigned int i=0; i<5; ++i){
					if(i<numsig){
						signal_values[i] = new int64_t;
						*(signal_values[i]) = 1;
						uint64_t handle = (uint64_t)(signal_values[i]);
						hsa_signal_t signal = {handle};
						packet->dep_signal[i] = signal;
					}else{
						uint64_t handle = 0;
						hsa_signal_t signal = {handle};
						packet->dep_signal[i] = signal;
					}
				}
				int64_t *csignal_value = new int64_t;
				*csignal_value = 1;
				uint64_t handle = (uint64_t)csignal_value;
				hsa_signal_t csignal = {handle};
				packet->completion_signal = csignal;
				
				++packet_queue_end_idx;
	
				for(unsigned int i=0; i<numsig; ++i){
					delete signal_values[i];
				}
				delete[] signal_values;
				delete csignal_value;
	
			}else if(ptype == HSA_PACKET_TYPE_BARRIER_OR){
				int numsig = 0;
	
				std::cout << "enter barrier_or packet: " << std::endl;
				do{
					std::cout << "enter number of signals: ";
					std::cin >> numsig;
				}while(numsig > 5 || numsig < 1);
	
				hsa_barrier_or_packet_t *packet = (hsa_barrier_or_packet_t*)((char*)packet_begin+PACKETSIZE*packet_queue_end_idx);
				
				packet->header = header(HSA_PACKET_TYPE_BARRIER_OR,barrier);
				int64_t **signal_values = new int64_t*[numsig];
				for(unsigned int i=0; i<5; ++i){
					if(i<numsig){
						signal_values[i] = new int64_t;
						*(signal_values[i]) = 1;
						uint64_t handle = (uint64_t)(signal_values[i]);
						hsa_signal_t signal = {handle};
						packet->dep_signal[i] = signal;
					}else{
						uint64_t handle = 0;
						hsa_signal_t signal = {handle};
						packet->dep_signal[i] = signal;
					}
				}
				int64_t *csignal_value = new int64_t;
				*csignal_value = 1;
				uint64_t handle = (uint64_t)csignal_value;
				hsa_signal_t csignal = {handle};
				packet->completion_signal = csignal;
				
				++packet_queue_end_idx;
				
				for(unsigned int i=0; i<numsig; ++i){
					delete signal_values[i];
				}
				delete[] signal_values;
				delete csignal_value;	
			}else if(adding){
				std::cout << "not supported at the moment" << std::endl;
			}
			std::cout << std::endl << std::endl << std::endl;
		}
	}
	
	const char *filename = argv[1];
	printfile(filename,packet_begin,pasid,packet_queue_end_idx);

	delete[] alloc;
	delete[] pasid;
}

