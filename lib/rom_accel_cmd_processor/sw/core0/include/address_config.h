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

#ifndef IMAGE_ACCEL_ADDRESS_CONFIG_H_
#define IMAGE_ACCEL_ADDRESS_CONFIG_H_

#define SEND_INTERRUPT           0x10000000

#define BASE_ADDR_CFG            0x11000000
#define BASE_ADDR_CFG_PE         0x12000000
#define BASE_ADDR_CFG_DATAMOVER  0x13000000

#define DATAMOVER_CFG_ADDR_IN   0x00
#define DATAMOVER_CFG_ADDR_OUT  0x08
#define DATAMOVER_CFG_SIZE_IN   0x10
#define DATAMOVER_CFG_SIZE_OUT  0x18

#define CFG_TASK            0x0000 /*uint16_t*/
#define CFG_NORMALIZATION   0x0002 /*uint16_t*/
#define CFG_THRESHOLD       0x0004 /*uint16_t*/
#define CFG_COLOR_MODEL     0x0006 /*uint8_t*/
#define CFG_BORDER_HANDLING 0x0007 /*uint8_t*/
#define CFG_IMG_WIDTH       0x0008 /*uint32_t*/
#define CFG_IMG_HEIGHT      0x000C /*uint32_t*/
#define CFG_SRC_ADDR        0x0010 /*uint64_t*/
#define CFG_DST_ADDR        0x0018 /*uint64_t*/
#define CFG_MASK0           0x0020 /*int32_t*/
#define CFG_MASK1           0x0084 /*int32_t*/

#define PE_CFG_IMG_WIDTH     0x0000 /*uint32_t*/
#define PE_CFG_IMG_HEIGHT    0x0004 /*uint32_t*/
#define PE_CFG_IMG_SIZE      0x0008 /*uint32_t*/
#define PE_CFG_WINDOW_WIDTH  0x000C /*uint32_t*/
#define PE_CFG_WINDOW_HEIGHT 0x0010 /*uint32_t*/
#define PE_CFG_OPERATION     0x0014 /*uint32_t*/
#define PE_CFG_NORMALIZE_VAL 0x0018 /*uint32_t*/
#define PE_CFG_THRESHOLD_VAL 0x001C /*uint32_t*/
#define PE_CFG_COEFFS0       0x0020 /*uint32_t*/
#define PE_CFG_COEFFS1       0x0084 /*uint32_t*/

#define MASK_SIZE 25

#endif
