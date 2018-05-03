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

#ifndef HSA_PACKETS_H_
#define HSA_PACKETS_H_

#include "stdint.h"

#define HSA_LARGE_MODEL
#define PACKETSIZE 64

typedef struct hsa_signal_s {
	uint64_t handle;
} hsa_signal_t;

typedef enum {
	HSA_PACKET_TYPE_VENDOR_SPECIFIC = 0,
	HSA_PACKET_TYPE_INVALID = 1,
	HSA_PACKET_TYPE_KERNEL_DISPATCH = 2,
	HSA_PACKET_TYPE_BARRIER_AND = 3,
	HSA_PACKET_TYPE_AGENT_DISPATCH = 4,
	HSA_PACKET_TYPE_BARRIER_OR = 5
} hsa_packet_type_t;

typedef enum {
	HSA_PACKET_HEADER_TYPE = 0,
	HSA_PACKET_HEADER_BARRIER = 8,
	HSA_PACKET_HEADER_SCACQUIRE_FENCE_SCOPE = 9,
	HSA_PACKET_HEADER_ACQUIRE_FENCE_SCOPE = 9,
	HSA_PACKET_HEADER_SCRELEASE_FENCE_SCOPE = 11,
	HSA_PACKET_HEADER_RELEASE_FENCE_SCOPE = 11
} hsa_packet_header_t;

typedef enum {
	HSA_PACKET_HEADER_WIDTH_TYPE = 8,
	HSA_PACKET_HEADER_WIDTH_BARRIER = 1,
	HSA_PACKET_HEADER_WIDTH_SCACQUIRE_FENCE_SCOPE = 2,
	HSA_PACKET_HEADER_WIDTH_ACQUIRE_FENCE_SCOPE = 2,
	HSA_PACKET_HEADER_WIDTH_SCRELEASE_FENCE_SCOPE = 2,
	HSA_PACKET_HEADER_WIDTH_RELEASE_FENCE_SCOPE = 2
} hsa_packet_header_width_t;

typedef enum {
	HSA_FENCE_SCOPE_NONE = 0,
	HSA_FENCE_SCOPE_AGENT = 1,
	HSA_FENCE_SCOPE_SYSTEM = 2
} hsa_fence_scope_t;

typedef enum {
	HSA_KERNEL_DISPATCH_PACKET_SETUP_DIMENSIONS = 0
}  hsa_kernel_dispatch_packet_setup_t;

typedef enum {
	HSA_KERNEL_DISPATCH_PACKET_SETUP_WIDTH_DIMENSIONS = 2
}   hsa_kernel_dispatch_packet_setup_width_t;

typedef struct hsa_kernel_dispatch_packet_s {
	uint16_t header ;
	uint16_t setup;
	uint16_t workgroup_size_x ;
	uint16_t workgroup_size_y ;
	uint16_t workgroup_size_z;
	uint16_t reserved0;
	uint32_t grid_size_x ;
	uint32_t grid_size_y ;
	uint32_t grid_size_z;
	uint32_t private_segment_size;
	uint32_t group_segment_size;
	uint64_t kernel_object ;
	#ifdef HSA_LARGE_MODEL
	void * kernarg_address;
	#elif defined HSA_LITTLE_ENDIAN
	void * kernarg_address;
	uint32_t reserved1;
	#else
	uint32_t reserved1;
	void * kernarg_address;
	#endif
	uint64_t reserved2;
	hsa_signal_t completion_signal;
} hsa_kernel_dispatch_packet_t;

typedef struct hsa_agent_dispatch_packet_s {
	uint16_t header;
	uint16_t type;
	uint32_t reserved0;
	#ifdef HSA_LARGE_MODEL
	void * return_address;
	#elif defined HSA_LITTLE_ENDIAN
	void * return_address;
	uint32_t reserved1;
	#else
	uint32_t reserved1;
	void * return_address;
	#endif
	uint64_t arg[4];
	uint64_t reserved2;
	hsa_signal_t completion_signal;
} hsa_agent_dispatch_packet_t;

typedef struct hsa_barrier_and_packet_s {
	uint16_t header;
	uint16_t reserved0;
	uint32_t reserved1;
	hsa_signal_t dep_signal[5];
	uint64_t reserved2;
	hsa_signal_t completion_signal;
} hsa_barrier_and_packet_t;

typedef struct hsa_barrier_or_packet_s {
	uint16_t header;
	uint16_t reserved0;
	uint32_t reserved1;
	hsa_signal_t dep_signal[5];
	uint64_t reserved2;
	hsa_signal_t completion_signal;
} hsa_barrier_or_packet_t;

typedef enum {
	HSA_AGENT_INFO_NAME = 0,
	HSA_AGENT_INFO_VENDOR_NAME = 1,
	HSA_AGENT_INFO_FEATURE = 2,
	HSA_AGENT_INFO_MACHINE_MODEL = 3,
	HSA_AGENT_INFO_PROFILE = 4,
	HSA_AGENT_INFO_DEFAULT_FLOAT_ROUNDING_MODE = 5,
	HSA_AGENT_INFO_BASE_PROFILE_DEFAULT_FLOAT_ROUNDING_MODES = 23,
	HSA_AGENT_INFO_FAST_F16_OPERATION = 24,
	HSA_AGENT_INFO_WAVEFRONT_SIZE = 6,
	HSA_AGENT_INFO_WORKGROUP_MAX_DIM = 7,
	HSA_AGENT_INFO_WORKGROUP_MAX_SIZE = 8,
	HSA_AGENT_INFO_GRID_MAX_DIM = 9,
	HSA_AGENT_INFO_GRID_MAX_SIZE = 10,
	HSA_AGENT_INFO_FBARRIER_MAX_SIZE = 11,
	HSA_AGENT_INFO_QUEUES_MAX = 12,
	HSA_AGENT_INFO_QUEUE_MIN_SIZE = 13,
	HSA_AGENT_INFO_QUEUE_MAX_SIZE = 14,
	HSA_AGENT_INFO_QUEUE_TYPE = 15,
	HSA_AGENT_INFO_NODE = 16,
	HSA_AGENT_INFO_DEVICE = 17,
	HSA_AGENT_INFO_CACHE_SIZE = 18,
	HSA_AGENT_INFO_ISA = 19,
	HSA_AGENT_INFO_EXTENSIONS = 20,
	HSA_AGENT_INFO_VERSION_MAJOR = 21,
	HSA_AGENT_INFO_VERSION_MINOR = 22
} hsa_agent_info_t;

#endif
