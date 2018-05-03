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

set mips64_dir "../../ext/mips64"
set common_dir "../../common"

add_files "packet_processor_top.vhd"

add_files "interrupt_controller/interrupt_controller.vhd"

add_files "memory_controller/memory_controller_pp.vhd"
add_files "memory_controller/external_memory/external_memory_interface_pp.vhd"

add_files "${common_dir}/axi_lite/axi_lite_master.vhd"
add_files "${common_dir}/axi_full/axi_full_master.vhd"
add_files "${common_dir}/interrupts/interrupt_arbiter.vhd"
add_files "${common_dir}/interrupts/interrupt_demux.vhd"
add_files "${common_dir}/mem_router/mem_router.vhd"
add_files "${common_dir}/mem_router/singleclock_bram.vhd"
add_files "${common_dir}/mem_router/bram_sp.vhd"

add_files "${mips64_dir}/branching_unit_64.vhd"
add_files "${mips64_dir}/asip_alu/asip_alu_64.vhd"
add_files "${mips64_dir}/asip_alu/asip_instruction_components_pkg_64.vhd"
add_files "${mips64_dir}/asip_alu/asip_decode_64.vhd"
add_files "${mips64_dir}/instruction_fetch_64.vhd"
add_files "${mips64_dir}/alu_pkg_64.vhd"
add_files "${mips64_dir}/stage_mem_wb_64.vhd"
add_files "${mips64_dir}/hazard_detection_unit_64.vhd"
add_files "${mips64_dir}/stage_id_ex_64.vhd"
add_files "${mips64_dir}/memory_access_64.vhd"
add_files "${mips64_dir}/stage_pc_64.vhd"
add_files "${mips64_dir}/cpu_top_64.vhd"
add_files "${mips64_dir}/stage_if_id_64.vhd"
add_files "${mips64_dir}/forwarding_unit_64.vhd"
add_files "${mips64_dir}/decoder_unit_64.vhd"
add_files "${mips64_dir}/coprocessor0_64.vhd"
add_files "${mips64_dir}/stage_ex_mem_64.vhd"
add_files "${mips64_dir}/write_back_64.vhd"
add_files "${mips64_dir}/execute_64.vhd"
add_files "${mips64_dir}/instruction_decode_64.vhd"

