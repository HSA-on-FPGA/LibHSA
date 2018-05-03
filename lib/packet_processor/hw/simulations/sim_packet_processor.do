
# Author:      Tobias Lieske, Philipp Holzinger
# Email:       tobias.lieske@fau.de, philipp.holzinger@fau.de
# Date:        28.11.2016

set hsarepo "../../../.."
set src "$hsarepo/lib"
set mips64dir "$src/ext/mips64"
set ppdir "$src/packet_processor/hw"
set commondir "$src/common"
set core_software "$src/packet_processor/sw/core/vsim"
set dram_data "$core_software"

if {[file exists $core_software/simulation.env]} {
    # load the simulation.env file
    exec /bin/sed {s/export/set/g;s/=/ /g} "$core_software/simulation.env" > simulation_environment.do
    source simulation_environment.do
    set INSTR_MEM_BLOCKS $MIPS_NUM_TEXT_MEM_BLOCKS
    set DATA_MEM_BLOCKS $MIPS_NUM_DATA_MEM_BLOCKS
    set ACCELERATOR_CORES $MIPS_NUM_ACCELERATOR_CORES
} else {
    # read out environmnet variables from the shell
    # keep in mind to restart vsim if it is a background process to update the
    # enviroment variables
     set INSTR_MEM_BLOCKS [if {[string is integer $::env(MIPS_NUM_TEXT_MEM_BLOCKS)] == 1} {expr $::env(MIPS_NUM_TEXT_MEM_BLOCKS)} {expr 1}]
     set DATA_MEM_BLOCKS [if {[string is integer $::env(MIPS_NUM_DATA_MEM_BLOCKS)] == 1} {expr $::env(MIPS_NUM_DATA_MEM_BLOCKS)} {expr 1}]
     set ACCELERATOR_CORES [if {[string is integer $::env(MIPS_NUM_ACCELERATOR_CORES)] == 1} {expr $::env(MIPS_NUM_ACCELERATOR_CORES)} {expr 1}]
}

vlib work

# compile sources
vcom -reportprogress 300 -work work $mips64dir/alu_pkg_64.vhd
vcom -reportprogress 300 -work work $mips64dir/asip_alu/asip_instruction_components_pkg_64.vhd
vcom -reportprogress 300 -work work $mips64dir/asip_alu/asip_alu_64.vhd
vcom -reportprogress 300 -work work $mips64dir/asip_alu/asip_decode_64.vhd

# mips core sources
vcom -reportprogress 300 -work work $mips64dir/stage_pc_64.vhd
vcom -reportprogress 300 -work work $mips64dir/instruction_fetch_64.vhd
vcom -reportprogress 300 -work work $mips64dir/stage_if_id_64.vhd
vcom -reportprogress 300 -work work $mips64dir/branching_unit_64.vhd
vcom -reportprogress 300 -work work $mips64dir/decoder_unit_64.vhd
vcom -reportprogress 300 -work work $mips64dir/hazard_detection_unit_64.vhd
vcom -reportprogress 300 -work work $mips64dir/forwarding_unit_64.vhd
vcom -reportprogress 300 -work work $mips64dir/instruction_decode_64.vhd
vcom -reportprogress 300 -work work $mips64dir/stage_id_ex_64.vhd
vcom -reportprogress 300 -work work $mips64dir/execute_64.vhd
vcom -reportprogress 300 -work work $mips64dir/stage_ex_mem_64.vhd
vcom -reportprogress 300 -work work $mips64dir/memory_access_64.vhd
vcom -reportprogress 300 -work work $mips64dir/stage_mem_wb_64.vhd
vcom -reportprogress 300 -work work $mips64dir/write_back_64.vhd
vcom -reportprogress 300 -work work $mips64dir/coprocessor0_64.vhd
vcom -reportprogress 300 -work work $mips64dir/cpu_top_64.vhd

# memory sources
vcom -reportprogress 300 -work work $commondir/axi_lite/axi_lite_master.vhd
vcom -reportprogress 300 -work work $commondir/axi_full/axi_full_master.vhd
vcom -reportprogress 300 -work work $ppdir/memory_controller/external_memory/external_memory_interface_pp.vhd
vcom -reportprogress 300 -work work $commondir/mem_router/bram_sp.vhd
vcom -reportprogress 300 -work work $commondir/mem_router/singleclock_bram.vhd
vcom -reportprogress 300 -work work $commondir/mem_router/mem_router.vhd
vcom -reportprogress 300 -work work $ppdir/memory_controller/memory_controller_pp.vhd

# interrupt controller sources
vcom -reportprogress 300 -work work $commondir/interrupts/interrupt_demux.vhd
vcom -reportprogress 300 -work work $commondir/interrupts/interrupt_arbiter.vhd
vcom -reportprogress 300 -work work $ppdir/interrupt_controller/interrupt_controller.vhd

# top sources
vcom -reportprogress 300 -work work $ppdir/packet_processor_top.vhd
vcom -reportprogress 300 -work work $commondir/axi_lite/axi_lite_slave.vhd
vcom -reportprogress 300 -work work $commondir/sim/generic_memory.vhd
vcom -reportprogress 300 -work work $commondir/sim/burst_memory.vhd
vcom -reportprogress 300 -work work $ppdir/tb_packet_processor_top.vhd

# start simulation

vsim -t 1ps -novopt -GG_MEM_NUM_4K_DATA_MEMS=$DATA_MEM_BLOCKS -GG_MEM_NUM_4K_INSTR_MEMS=$INSTR_MEM_BLOCKS -GG_NUM_ACCELERATOR_CORES=$ACCELERATOR_CORES -GG_IMEM_INIT_FILE=$core_software/instr.hex -GG_DMEM_INIT_FILE=$core_software/data.hex work.tb_packet_processor_top
view wave

# load dram
mem load -i $dram_data/dram.mem -filltype value -filldata 0 -fillradix hexadecimal -skip 0 /tb_packet_processor_top/inst_dram/bram

# initialize config
mem load -filltype value -filldata 0 -fillradix hexadecimal -skip 0 /tb_packet_processor_top/inst_config/bram

config wave -signalnamewidth 1

add wave -noupdate -divider -height 32 testbench
add wave -radix hex sim:/tb_packet_processor_top/*
#*/

add wave -noupdate -divider -height 32 packet_processor_internal
add wave -radix hex sim:/tb_packet_processor_top/uut/*
#*/

add wave -noupdate -divider -height 32 mem_ctrl
add wave -radix hex sim:/tb_packet_processor_top/uut/inst_memory_controller/*
#*/

add wave -noupdate -divider -height 32 external_mem
add wave -radix hex sim:/tb_packet_processor_top/uut/inst_memory_controller/external_memory_interface_inst/*
#*/

add wave -noupdate -divider -height 32 irq_ctrl
add wave -radix hex sim:/tb_packet_processor_top/uut/inst_interrupt_controller/*
#*/

add wave -noupdate -divider -height 32 mem_router
add wave -radix hex sim:/tb_packet_processor_top/uut/inst_memory_controller/mem_router_inst/*
#*/

add wave -noupdate -divider -height 32 mem_router_data_mem_axi
add wave -radix hex sim:/tb_packet_processor_top/uut/inst_memory_controller/mem_router_inst/dmem_bram_inst/*
#*/

add wave -noupdate -divider -height 32 cpu_top
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/*
#*/

add wave -noupdate -divider -height 32 stage_PC
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_stage_pc/*
#*/

add wave -noupdate -divider -height 32 INSTRUCTION_FETCH
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_instruction_fetch/*
#*/

add wave -noupdate -divider -height 32 stage_IF_ID
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_stage_if_id/*
#*/

add wave -noupdate -divider -height 32 INSTRUCTION_DECODE
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_instruction_decode/*
#*/

add wave -noupdate -divider -height 32 BRANCHING_UNIT
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_instruction_decode/branching_unit_inst/*
#*/

add wave -noupdate -divider -height 32 DECODER_UNIT
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_instruction_decode/decoder_unit_inst/*
#*/

add wave -noupdate -divider -height 32 ASIP_DECODE
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_instruction_decode/decoder_unit_inst/asip_decode_inst/*
#*/

add wave -noupdate -divider -height 32 FORWARDING_UNIT
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_instruction_decode/forwarding_unit_inst/*
#*/

add wave -noupdate -divider -height 32 HAZARD_DETECTION_UNIT
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_instruction_decode/hazard_detection_unit_inst/*
#*/

add wave -noupdate -divider -height 32 stage_ID_EX
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_stage_id_ex/*
#*/

add wave -noupdate -divider -height 32 EXECUTE
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_execute/*
#*/

add wave -noupdate -divider -height 32 ASIP_ALU
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_execute/asip_alu_inst/*
#*/

add wave -noupdate -divider -height 32 stage_EX_MEM
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_stage_ex_mem/*
#*/

add wave -noupdate -divider -height 32 MEMORY_ACCESS
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_memory_access/*
#*/

add wave -noupdate -divider -height 32 stage_MEM_WB
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_stage_mem_wb/*
#*/

add wave -noupdate -divider -height 32 WRITE_BACK
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_write_back/*
#*/

add wave -noupdate -divider -height 32 COPROCESSOR
add wave -radix hex sim:/tb_packet_processor_top/uut/cpu_top_inst/inst_coprocessor0/*
#*/

add wave -noupdate -divider -height 32 simulation_dram
add wave -radix hex sim:/tb_packet_processor_top/inst_dram/*
#*/

add wave -noupdate -divider -height 32 simulation_config
add wave -radix hex sim:/tb_packet_processor_top/inst_config/*
#*/

run 10 ms

# store configuration bram memory to file
mem save -format mti -dataradix hex -wordsperline 2 -outfile config_out.mem /tb_packet_processor_top/inst_config/bram

# store dram (simulation bram memory) to file
#mem save -format mti -dataradix hex -wordsperline 2 -outfile dram_out.mem /tb_packet_processor_top/inst_dram/bram

