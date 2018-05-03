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

#ifndef ACCEL_ADDRESS_CONFIG_H_
#define ACCEL_ADDRESS_CONFIG_H_

#define DRAM_BASE_ADDRESS        0x0001000000000000

#define SEND_INTERRUPT           0xF0000000

#define PP_CFG_GRIDSIZEX_OFFSET      0x0000
#define PP_CFG_GRIDSIZEY_OFFSET      0x0004
#define PP_CFG_GRIDSIZEZ_OFFSET      0x0008
#define PP_CFG_WORKGROUPSIZEX_OFFSET 0x000C
#define PP_CFG_WORKGROUPSIZEY_OFFSET 0x0010
#define PP_CFG_WORKGROUPSIZEZ_OFFSET 0x0014
#define PP_CFG_DIM_OFFSET            0x0018
#define PP_CFG_PASID_OFFSET          0x001C
#define PP_CFG_KERNEL_OFFSET         0x0020
#define PP_CFG_KERNARG_OFFSET        0x0028

#endif
