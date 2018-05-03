# Copyright (C) 2017 Philipp Holzinger
# Copyright (C) 2017 Martin Stumpf
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set mips32_dir "../../ext/mips32"
set common_dir "../../common"

add_files "accel_cmd_processor_top.vhd"


add_files "memory_controller/external_memory_interface_acp.vhd"
add_files "memory_controller/memory_controller_acp.vhd"

add_files "${common_dir}/axi_lite/axi_lite_master.vhd"
add_files "${common_dir}/interrupts/interrupt_demux.vhd"
add_files "${common_dir}/mem_router/axi_mem_router.vhd"
add_files "${common_dir}/mem_router/dualclock_bram.vhd"
add_files "${common_dir}/mem_router/axi_dualclock_bram.vhd"
add_files "${common_dir}/mem_router/bram_tdp.vhd"

add_files "${mips32_dir}/asip_alu/asip_alu.vhd"
add_files "${mips32_dir}/asip_alu/asip_decode.vhd"
add_files "${mips32_dir}/asip_alu/asip_instruction_components_pkg.vhd"
add_files "${mips32_dir}/hazard_detection_unit.vhd"
add_files "${mips32_dir}/instruction_decode.vhd"
add_files "${mips32_dir}/alu_pkg.vhd"
add_files "${mips32_dir}/cpu_top.vhd"
add_files "${mips32_dir}/stage_ex_mem.vhd"
add_files "${mips32_dir}/instruction_fetch.vhd"
add_files "${mips32_dir}/execute.vhd"
add_files "${mips32_dir}/decoder_unit.vhd"
add_files "${mips32_dir}/stage_mem_wb.vhd"
add_files "${mips32_dir}/branching_unit.vhd"
add_files "${mips32_dir}/forwarding_unit.vhd"
add_files "${mips32_dir}/write_back.vhd"
add_files "${mips32_dir}/stage_if_id.vhd"
add_files "${mips32_dir}/stage_id_ex.vhd"
add_files "${mips32_dir}/coprocessor0.vhd"
add_files "${mips32_dir}/memory_access.vhd"
add_files "${mips32_dir}/stage_pc.vhd"
