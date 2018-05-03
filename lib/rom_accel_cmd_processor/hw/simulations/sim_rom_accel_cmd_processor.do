
# Author:      Tobias Lieske, Philipp Holzinger
# Email:       tobias.lieske@fau.de, philipp.holzinger@fau.de
# Date:        14.01.2017

set hsarepo "../../../.."
set src "$hsarepo/lib"
set mips32dir "$src/ext/mips32"
set acpdir "$src/rom_accel_cmd_processor/hw"
set commondir "$src/common"
set software "$src/rom_accel_cmd_processor/sw"
set core_software "$software/core0/vsim"
set config_data "$software/core0/vsim"

if {[file exists $core_software/simulation.env]} {
    # load the simulation.env file
    exec /bin/sed {s/export/set/g;s/=/ /g} "$core_software/simulation.env" > simulation_environment.do
    source simulation_environment.do
    set INSTR_MEM_BLOCKS $MIPS_NUM_TEXT_MEM_BLOCKS
    set DATA_MEM_BLOCKS $MIPS_NUM_DATA_MEM_BLOCKS
} else {
    # read out environmnet variables from the shell
    # keep in mind to restart vsim if it is a background process to update the
    # enviroment variables
    set INSTR_MEM_BLOCKS [if {[string is integer $::env(MIPS_NUM_TEXT_MEM_BLOCKS)] == 1} {expr $::env(MIPS_NUM_TEXT_MEM_BLOCKS)} {expr 1}]
    set DATA_MEM_BLOCKS [if {[string is integer $::env(MIPS_NUM_DATA_MEM_BLOCKS)] == 1} {expr $::env(MIPS_NUM_DATA_MEM_BLOCKS)} {expr 1}]
}

vlib work

# mips core sources
vcom -reportprogress 300 -work work $mips32dir/alu_pkg.vhd
vcom -reportprogress 300 -work work $mips32dir/asip_alu/asip_instruction_components_pkg.vhd
vcom -reportprogress 300 -work work $mips32dir/asip_alu/asip_alu.vhd
vcom -reportprogress 300 -work work $mips32dir/asip_alu/asip_decode.vhd
vcom -reportprogress 300 -work work $mips32dir/stage_pc.vhd
vcom -reportprogress 300 -work work $mips32dir/instruction_fetch.vhd
vcom -reportprogress 300 -work work $mips32dir/stage_if_id.vhd
vcom -reportprogress 300 -work work $mips32dir/branching_unit.vhd
vcom -reportprogress 300 -work work $mips32dir/decoder_unit.vhd
vcom -reportprogress 300 -work work $mips32dir/hazard_detection_unit.vhd
vcom -reportprogress 300 -work work $mips32dir/forwarding_unit.vhd
vcom -reportprogress 300 -work work $mips32dir/instruction_decode.vhd
vcom -reportprogress 300 -work work $mips32dir/stage_id_ex.vhd
vcom -reportprogress 300 -work work $mips32dir/execute.vhd
vcom -reportprogress 300 -work work $mips32dir/stage_ex_mem.vhd
vcom -reportprogress 300 -work work $mips32dir/memory_access.vhd
vcom -reportprogress 300 -work work $mips32dir/stage_mem_wb.vhd
vcom -reportprogress 300 -work work $mips32dir/write_back.vhd
vcom -reportprogress 300 -work work $mips32dir/coprocessor0.vhd
vcom -reportprogress 300 -work work $mips32dir/cpu_top.vhd

# memory sources
vcom -reportprogress 300 -work work $commondir/axi_lite/axi_lite_master.vhd
vcom -reportprogress 300 -work work $acpdir/memory_controller/external_memory_interface_racp.vhd
vcom -reportprogress 300 -work work $commondir/mem_router/bram_sp.vhd
vcom -reportprogress 300 -work work $commondir/mem_router/singleclock_bram.vhd
vcom -reportprogress 300 -work work $commondir/mem_router/mem_router.vhd
vcom -reportprogress 300 -work work $acpdir/memory_controller/memory_controller_racp.vhd

# top sources
vcom -reportprogress 300 -work work $commondir/interrupts/interrupt_demux.vhd
vcom -reportprogress 300 -work work $acpdir/rom_accel_cmd_processor_top.vhd
vcom -reportprogress 300 -work work $commondir/axi_lite/axi_lite_slave.vhd
vcom -reportprogress 300 -work work $commondir/sim/generic_memory.vhd
vcom -reportprogress 300 -work work $acpdir/tb_rom_accel_cmd_processor_top.vhd

# start simulation

vsim -t 1ps -novopt -GG_MEM_NUM_4K_DATA_MEMS=$DATA_MEM_BLOCKS -GG_MEM_NUM_4K_INSTR_MEMS=$INSTR_MEM_BLOCKS work.tb_rom_accel_cmd_processor_top -GG_IMEM_INIT_FILE=$core_software/instr.hex -GG_DMEM_INIT_FILE=$core_software/data.hex
view wave

# load config memory
mem load -filltype value -filldata 0 -fillradix hexadecimal -skip 0 /tb_rom_accel_cmd_processor_top/inst_config/bram
#mem load -i $config_data/config.mem -filltype value -filldata 0 -fillradix hexadecimal -skip 0 /tb_rom_accel_cmd_processor_top/inst_config/bram

config wave -signalnamewidth 1

add wave -noupdate -divider -height 32 testbench
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/*
#*/

add wave -noupdate -divider -height 32 mips_internal
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/*
#*/

add wave -noupdate -divider -height 32 mem_ctrl
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/inst_memory_controller/*
#*/

add wave -noupdate -divider -height 32 external_mem
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/inst_memory_controller/external_memory_interface_inst/*
#*/

add wave -noupdate -divider -height 32 irq_ctrl
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/inst_interrupt_demux/*
#*/

add wave -noupdate -divider -height 32 mem_router
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/inst_memory_controller/mem_router_inst/*
#*/

add wave -noupdate -divider -height 32 mem_router_data_mem_axi
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/inst_memory_controller/mem_router_inst/dmem_bram_inst/*
#*/

add wave -noupdate -divider -height 32 cpu_top
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/*
#*/

add wave -noupdate -divider -height 32 stage_PC
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_stage_pc/*
#*/

add wave -noupdate -divider -height 32 INSTRUCTION_FETCH
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_instruction_fetch/*
#*/

add wave -noupdate -divider -height 32 stage_IF_ID
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_stage_if_id/*
#*/

add wave -noupdate -divider -height 32 INSTRUCTION_DECODE
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_instruction_decode/*
#*/

add wave -noupdate -divider -height 32 BRANCHING_UNIT
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_instruction_decode/branching_unit_inst/*
#*/

add wave -noupdate -divider -height 32 DECODER_UNIT
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_instruction_decode/decoder_unit_inst/*
#*/

add wave -noupdate -divider -height 32 FORWARDING_UNIT
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_instruction_decode/forwarding_unit_inst/*
#*/

add wave -noupdate -divider -height 32 HAZARD_DETECTION_UNIT
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_instruction_decode/hazard_detection_unit_inst/*
#*/

add wave -noupdate -divider -height 32 stage_ID_EX
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_stage_id_ex/*
#*/

add wave -noupdate -divider -height 32 EXECUTE
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_execute/*
#*/

add wave -noupdate -divider -height 32 stage_EX_MEM
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_stage_ex_mem/*
#*/

add wave -noupdate -divider -height 32 MEMORY_ACCESS
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_memory_access/*
#*/

add wave -noupdate -divider -height 32 stage_MEM_WB
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_stage_mem_wb/*
#*/

add wave -noupdate -divider -height 32 WRITE_BACK
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_write_back/*
#*/

add wave -noupdate -divider -height 32 COPROCESSOR
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/uut/cpu_top_inst/inst_coprocessor0/*
#*/

add wave -noupdate -divider -height 32 simulation_config
add wave -radix hex sim:/tb_rom_accel_cmd_processor_top/inst_config/*
#*/

run 2 ms

# store configuration bram memory to file
mem save -format mti -dataradix hex -wordsperline 4 -outfile config_out.mem /tb_rom_accel_cmd_processor_top/inst_config/bram

