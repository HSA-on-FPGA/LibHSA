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

#ifndef HSA_FPGA_H
#define HSA_FPGA_H

// define LOAD and STORE values for DMA requests
typedef enum {
	LOAD_DATA  = 0x0000,
	STORE_DATA = 0x0001,
} fpga_dma_direction_t;

// define border handling modes for FPGA proccessing
typedef enum {
	CLAMP_TO_ZERO = 0x0,
	CLAMP_TO_EDGE = 0x1,
} fpga_borderhandling_t;

// define supported color models for FPGA proccessing
typedef enum {
	UINT16_GRAY_SCALE = 0x0,
	UINT8_RGB         = 0x1,
} fpga_colormodel_t;

// define supported FPGA operations
typedef enum {
	SOBELX3x3        = 0x01,
	SOBELY3x3        = 0x02,
	SOBELXY3x3       = 0x03,
	SOBELX5x5        = 0x04,
	SOBELY5x5        = 0x05,
	SOBELXY5x5       = 0x06,
	GAUSS3x3         = 0x11,
	GAUSS5x5         = 0x12,
	MIN_FILTER3x3    = 0x21,
	MIN_FILTER5x5    = 0x22,
	MAX_FILTER3x3    = 0x23,
	MAX_FILTER5x5    = 0x24,
	MEDIAN_FILTER3x3 = 0x25,
	MEDIAN_FILTER5x5 = 0x26,
	CUSTOM_FILTER3x3 = 0x31,
	CUSTOM_FILTER5x5 = 0x32,
} fpga_operation_type_t;

inline int get_pixel_storage(uint64_t colormodel){
	switch(colormodel){
		case UINT16_GRAY_SCALE: return 2;
		case UINT8_RGB: return 3;
		default: return 0;
	}
}

// available filter masks
const int8_t sobelX_3x3_mask[25] = { 1, 0,-1, 0, 0,
				     2, 0,-2, 0, 0,
				     1, 0,-1, 0, 0,
				     0, 0, 0, 0, 0,
				     0, 0, 0, 0, 0};
const int8_t sobelY_3x3_mask[25] = { 1, 2, 1, 0, 0,
				     0, 0, 0, 0, 0,
				    -1,-2,-1, 0, 0,
				     0, 0, 0, 0, 0,
				     0, 0, 0, 0, 0};
const int8_t sobelX_5x5_mask[25] = { 1, 2, 0, -2,-1,
				     4, 8, 0, -8,-4,
				     6,12, 0,-12,-6,
				     4, 8, 0, -8,-4,
				     1, 2, 0, -2,-1};
const int8_t sobelY_5x5_mask[25] = { 1, 4,  6, 4, 1,
				     2, 8, 12, 8, 2,
				     0, 0,  0, 0, 0,
				    -2,-8,-12,-8,-2,
				    -1,-4, -6,-4,-1};
const int8_t gauss_3x3_mask[25]  = { 1, 2, 1, 0, 0,
				     2, 4, 2, 0, 0,
				     1, 2, 1, 0, 0,
				     0, 0, 0, 0, 0,
				     0, 0, 0, 0, 0};
const int8_t gauss_5x5_mask[25]  = { 1, 4, 6, 4, 1,
				     4,16,24,16, 4,
				     6,24,36,24, 6,
				     4,16,24,16, 4,
				     1, 4, 6, 4, 1};

// normalization values for filter masks
const int16_t gauss_3x3_normalization = 16;
const int16_t gauss_5x5_normalization = 256;

#endif
