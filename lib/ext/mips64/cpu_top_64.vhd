-- cpu_top_64: Top level module
-- Copyright 2017 Tobias Lieske, Steffen Vaas
--
-- tobias.lieske@fau.de
-- steffen.vaas@fau.de
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

--------------------------------------------------------------------------------
-- LIBRARY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_pkg_64.all;
--use ieee.math_real.all;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
entity cpu_top_64 is
    generic(
        G_START_ADDRESS             : std_logic_vector(63 downto 0) := x"0000000000000000";
        G_EXCEPTION_HANDLER_ADDRESS : std_logic_vector(63 downto 0) := x"0000000000000010";
        -- interrupts
        G_TIMER_INTERRUPT           : boolean := false;
        G_NUM_HW_INTERRUPTS         : integer range 0 to 6 := 1;
        -- exceptions
        G_EXC_ADDRESS_ERROR_LOAD    : boolean := false;
        G_EXC_ADDRESS_ERROR_FETCH   : boolean := false;
        G_EXC_ADDRESS_ERROR_STORE   : boolean := false;
        G_EXC_INSTRUCTION_BUS_ERROR : boolean := false;
        G_EXC_DATA_BUS_ERROR        : boolean := false;
        G_EXC_SYSCALL               : boolean := false;
        G_EXC_BREAKPOINT            : boolean := false;
        G_EXC_RESERVED_INSTRUCTION  : boolean := false;
        G_EXC_COP_UNIMPLEMENTED     : boolean := false;
        G_EXC_ARITHMETIC_OVERFLOW   : boolean := false;
        G_EXC_TRAP                  : boolean := false;
        G_EXC_FLOATING_POINT        : boolean := false;
        -- ASIP
        G_SENSOR_DATA_WIDTH         : integer range 1 to 1024;
        G_SENSOR_CONF_WIDTH         : integer range 1 to 1024;
        G_BUSY_LIST_WIDTH           : integer range 1 to 1024
    );
    port(
        clk                         : in  std_logic;
        resetn                      : in  std_logic;
        enable                      : in  std_logic;

        interrupt                   : in  std_logic_vector(5 downto 0);
        interrupt_ack               : out std_logic;

        -- memory interface
		-- instruction memory interface
        inst_addr                   : out std_logic_vector(63 downto 0);
        inst_din                    : in  std_logic_vector(31 downto 0);
        inst_read_busy              : in  std_logic;

		-- data memory interface
        data_addr                   : out std_logic_vector(63 downto 0);
        data_din                    : in  std_logic_vector(63 downto 0);
        data_dout                   : out std_logic_vector(63 downto 0);
        data_read_busy              : in  std_logic;
        data_write_busy             : in  std_logic;

		-- control memory interface
        hazard_stall				: out std_logic;
		data_read_access			: out std_logic;
		data_write_access			: out std_logic;

        -- memory exceptions
        address_error_exc_load      : in  std_logic;
        address_error_exc_fetch     : in  std_logic;
        address_error_exc_store     : in  std_logic;
        instruction_bus_exc         : in  std_logic;
        data_bus_exc                : in  std_logic;

        -- sensor interface
        sensor_data_in              : in  std_logic_vector(G_SENSOR_DATA_WIDTH-1 downto 0);
        sensor_config_out           : out std_logic_vector(G_SENSOR_CONF_WIDTH-1 downto 0)
    );
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of cpu_top_64 is

--------------------------------------------------------------------------------
-- COMPONENTS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

component stage_pc_64 is
    generic(G_START_ADDRESS : std_logic_vector(63 downto 0) := x"0000000000000000");
    port(
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;
        syn_interrupt       : in  std_logic;

        -- data path
        pc_in               : in  std_logic_vector(63 downto 0);
        pc_out              : out std_logic_vector(63 downto 0)
    );
end component;


component instruction_fetch_64 is
    generic(
        G_EXCEPTION_HANDLER_ADDRESS : std_logic_vector(63 downto 0) := x"0000000000000010"
    );
    port(

        -- data path
        pc_branch           : in  std_logic_vector(63 downto 0);
        pc_current          : in  std_logic_vector(63 downto 0);
        pc_next             : out std_logic_vector(63 downto 0);
        instruction         : out std_logic_vector(31 downto 0);

        inst_data           : in  std_logic_vector(31 downto 0);
        inst_address        : out std_logic_vector(63 downto 0);

        -- control path
        interrupt_syn       : in  std_logic;
        take_branch         : in  std_logic

    );
end component;


component stage_if_id_64 is
    port(
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;
        syn_interrupt       : in  std_logic;

        -- data path
        pc_in               : in  std_logic_vector(63 downto 0);
        instruction_in      : in  std_logic_vector(31 downto 0);
        pc_out              : out std_logic_vector(63 downto 0);
        instruction_out     : out std_logic_vector(31 downto 0)
    );
end component;


component instruction_decode_64 is
    generic(
        G_EXC_RESERVED_INSTRUCTION  : boolean := false;
        G_EXC_COP_UNIMPLEMENTED     : boolean := false;
        G_BUSY_LIST_WIDTH           : integer range 1 to 1024
    );
    port(
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;

        -- data path
        pc_in               : in  std_logic_vector(63 downto 0);
        pc_branch           : out std_logic_vector(63 downto 0);
        instruction         : in  std_logic_vector(31 downto 0);

        write_register      : in  std_logic_vector( 4 downto 0);
        write_data          : in  std_logic_vector(63 downto 0);
        reg_data_1          : out std_logic_vector(63 downto 0);
        reg_data_2          : out std_logic_vector(63 downto 0);
        immediate_value     : out std_logic_vector(63 downto 0);
        dest_reg            : out std_logic_vector( 4 downto 0);

        -- forwarding
        forward_rs_addr     : out std_logic_vector( 4 downto 0);
        forward_rt_addr     : out std_logic_vector( 4 downto 0);
        forward_dest_ex_mem : in  std_logic_vector( 4 downto 0);
        forward_dest_mem_wb : in  std_logic_vector( 4 downto 0);
        forward_ex_mem      : in  std_logic_vector(63 downto 0);
        forward_mem_wb      : in  std_logic_vector(63 downto 0);
        ctrl_reg_write_id_ex: in  std_logic;
        ctrl_reg_write_ex_mem: in  std_logic;
        ctrl_reg_write_mem_wb: in  std_logic;
        ex_result_dest      : in  std_logic_vector( 4 downto 0);
        ex_ctrl_wb_out      : in  std_logic_vector( 1 downto 0);

        -- hazard detection unit
        hazard_rt_id_ex     : in  std_logic_vector( 4 downto 0);
        hazard_rt_ex_mem    : in  std_logic_vector( 4 downto 0);
        hazard_stall        : out std_logic;

        -- Coproecessor
        cp0_addr            : out std_logic_vector( 4 downto 0);
        cp0_sel             : out std_logic_vector( 2 downto 0);
        cp0_data_in         : out std_logic_vector(63 downto 0);
        cp0_ctrl            : out std_logic_vector(10 downto 0);
        cp0_epc_reg         : in  std_logic_vector(63 downto 0);

        -- control path
        ctrl_reg_write      : in  std_logic;
        alu_src             : out std_logic;
        alu_ctrl            : out alu_ctrl_t;
        ctrl_mem            : out std_logic_vector( 5 downto 0);
        ctrl_wb             : out std_logic_vector( 1 downto 0);

        ctrl_take_branch    : out std_logic;

        -- interrupt
        syn_interrupt       : in std_logic;

        -- from execute
        execute_done        : in  std_logic;
        execute_busy_list   : in  std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);

        -- standby mode
        standby             : out std_logic
    );
end component;


component stage_id_ex_64 is
    port(
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;


        -- data path
        reg_data_in_1       : in  std_logic_vector(63 downto 0);
        reg_data_in_2       : in  std_logic_vector(63 downto 0);
        immediate_value_in  : in  std_logic_vector(63 downto 0);
        dest_reg_in         : in  std_logic_vector( 4 downto 0);

        reg_data_out_1      : out std_logic_vector(63 downto 0);
        reg_data_out_2      : out std_logic_vector(63 downto 0);
        immediate_value_out : out std_logic_vector(63 downto 0);
        dest_reg_out        : out std_logic_vector( 4 downto 0);

        -- forwarding
        forward_rs_addr_in  : in  std_logic_vector( 4 downto 0);
        forward_rt_addr_in  : in  std_logic_vector( 4 downto 0);
        forward_rs_addr_out : out std_logic_vector( 4 downto 0);
        forward_rt_addr_out : out std_logic_vector( 4 downto 0);

        -- control path
        alu_src_in          : in  std_logic;
        alu_ctrl_in         : in  alu_ctrl_t;
        ctrl_mem_in         : in  std_logic_vector( 5 downto 0);
        ctrl_wb_in          : in  std_logic_vector( 1 downto 0);

        alu_src_out         : out std_logic;
        alu_ctrl_out        : out alu_ctrl_t;
        ctrl_mem_out        : out std_logic_vector( 5 downto 0);
        ctrl_wb_out         : out std_logic_vector( 1 downto 0)
    );
end component;


component execute_64 is
    generic(
        G_EXC_ARITHMETIC_OVERFLOW   : boolean := false;
        G_SENSOR_DATA_WIDTH         : integer range 1 to 1024;
        G_SENSOR_CONF_WIDTH         : integer range 1 to 1024;
        G_BUSY_LIST_WIDTH           : integer range 1 to 1024
    );
    port(
        -- general
        clk                 : in  std_logic;
        resetn              : in  std_logic;
        enable              : in  std_logic;

        -- data path
        reg_data_in_1       : in  std_logic_vector(63 downto 0);
        reg_data_in_2       : in  std_logic_vector(63 downto 0);
        immediate_value     : in  std_logic_vector(63 downto 0);
        dest_reg_in         : in  std_logic_vector( 4 downto 0);

        alu_result          : out std_logic_vector(63 downto 0);
        reg_data_out        : out std_logic_vector(63 downto 0);
        dest_reg_out        : out std_logic_vector( 4 downto 0);

        -- forwarding
        forward_rs_addr     : in  std_logic_vector( 4 downto 0);
        forward_rt_addr     : in  std_logic_vector( 4 downto 0);
        forward_dest_ex_mem : in  std_logic_vector( 4 downto 0);
        forward_dest_mem_wb : in  std_logic_vector( 4 downto 0);
        forward_ex_mem      : in  std_logic_vector(63 downto 0);
        forward_mem_wb      : in  std_logic_vector(63 downto 0);
        ctrl_reg_write_ex_mem: in  std_logic;
        ctrl_reg_write_mem_wb: in  std_logic;

        -- control path
        alu_flags           : out std_logic_vector( 4 downto 0);
        alu_src             : in  std_logic;
        alu_ctrl            : in  alu_ctrl_t;

        ctrl_mem_in         : in  std_logic_vector( 5 downto 0);
        ctrl_wb_in          : in  std_logic_vector( 1 downto 0);

        ctrl_mem_out        : out std_logic_vector( 8 downto 0);
        ctrl_wb_out         : out std_logic_vector( 1 downto 0);

        flush               : in  std_logic;
        -- ASIP
        done                : out std_logic;
        busy_list           : out std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);
        sensor_data_in      : in  std_logic_vector(G_SENSOR_DATA_WIDTH-1 downto 0);
        sensor_config_out   : out std_logic_vector(G_SENSOR_CONF_WIDTH-1 downto 0)
    );
end component;


component stage_ex_mem_64 is
    port(
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;


        -- data path
        alu_result_in       : in  std_logic_vector(63 downto 0);
        write_data_in       : in  std_logic_vector(63 downto 0);
        dest_reg_in         : in  std_logic_vector( 4 downto 0);

        alu_result_out      : out std_logic_vector(63 downto 0);
        mem_address_out     : out std_logic_vector(63 downto 0);
        write_data_out      : out std_logic_vector(63 downto 0);
        dest_reg_out        : out std_logic_vector( 4 downto 0);


        -- control path
        ctrl_mem_in         : in  std_logic_vector( 8 downto 0);
        ctrl_wb_in          : in  std_logic_vector( 1 downto 0);

        ctrl_mem_out        : out std_logic_vector( 8 downto 0);
        ctrl_wb_out         : out std_logic_vector( 1 downto 0)
    );
end component;


component memory_access_64 is
    generic(
        G_EXC_ADDRESS_ERROR_LOAD    : boolean := false;
        G_EXC_ADDRESS_ERROR_STORE   : boolean := false;
        G_EXC_DATA_BUS_ERROR        : boolean := false
    );
    port(
        clk                         : in  std_logic;
        resetn                      : in  std_logic;
        enable                      : in  std_logic;

        -- data path
        alu_result_in               : in  std_logic_vector(63 downto 0);
        mem_address_in              : in  std_logic_vector(63 downto 0);
        reg_data_in                 : in  std_logic_vector(63 downto 0);

        alu_result_out              : out std_logic_vector(63 downto 0);
        memory_data                 : out std_logic_vector(63 downto 0);

        mem_address                 : out std_logic_vector(63 downto 0);
        mem_data_write              : out std_logic_vector(63 downto 0);
        mem_data_read               : in  std_logic_vector(63 downto 0);

        data_read_busy              : in  std_logic;
        data_write_busy             : in  std_logic;

        address_error_exc_load      : in  std_logic;
        address_error_exc_store     : in  std_logic;
        data_bus_exc                : in  std_logic;

        -- flush execute
        flush_execute               : out std_logic;

        ctrl_mem_in                 : in  std_logic_vector( 8 downto 0);
        ctrl_mem_out                : out std_logic_vector( 8 downto 0);

        data_read_access		    : out std_logic;
        data_write_access		    : out std_logic;

        unaligned_mem_access_busy   : out std_logic;

        ctrl_wb_in                  : in  std_logic_vector( 1 downto 0);
        ctrl_wb_out                 : out std_logic_vector( 1 downto 0)
    );
end component;


component stage_mem_wb_64 is
    port(
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;


        -- data path
        alu_result_in       : in  std_logic_vector(63 downto 0);
        read_data_in        : in  std_logic_vector(63 downto 0);
        dest_reg_in         : in  std_logic_vector( 4 downto 0);

        alu_result_out      : out std_logic_vector(63 downto 0);
        read_data_out       : out std_logic_vector(63 downto 0);
        dest_reg_out        : out std_logic_vector( 4 downto 0);


        -- control path
        ctrl_mem_in         : in  std_logic_vector( 8 downto 0);
        ctrl_mem_out        : out std_logic_vector( 8 downto 0);

        ctrl_wb_in          : in  std_logic_vector( 1 downto 0);
        ctrl_wb_out         : out std_logic_vector( 1 downto 0)
    );
end component;


component write_back_64 is
    port(
        -- data path
        alu_result          : in  std_logic_vector(63 downto 0);
        memory_data         : in  std_logic_vector(63 downto 0);
        write_data          : out std_logic_vector(63 downto 0);

        -- control path
        ctrl_mem_in         : in  std_logic_vector( 8 downto 0);
        ctrl_wb             : in  std_logic
    );
end component;



component coprocessor0_64 is
    generic(
        G_START_ADDRESS             : std_logic_vector(63 downto 0) := x"0000000000000000";
        -- interrupts
        G_TIMER_INTERRUPT           : boolean := false;
        G_NUM_HW_INTERRUPTS         : integer range 0 to 6 := 1;
        -- exceptions
        G_EXC_ADDRESS_ERROR_LOAD    : boolean := false;
        G_EXC_ADDRESS_ERROR_FETCH   : boolean := false;
        G_EXC_ADDRESS_ERROR_STORE   : boolean := false;
        G_EXC_INSTRUCTION_BUS_ERROR : boolean := false;
        G_EXC_DATA_BUS_ERROR        : boolean := false;
        G_EXC_SYSCALL               : boolean := false;
        G_EXC_BREAKPOINT            : boolean := false;
        G_EXC_RESERVED_INSTRUCTION  : boolean := false;
        G_EXC_COP_UNIMPLEMENTED     : boolean := false;
        G_EXC_ARITHMETIC_OVERFLOW   : boolean := false;
        G_EXC_TRAP                  : boolean := false;
        G_EXC_FLOATING_POINT        : boolean := false
    );
    port(
        clk                     : in  std_logic;
        reset                   : in  std_logic;
        enable                  : in  std_logic;

        interrupt               : in  std_logic_vector(5 downto 0);
        mfc_delayed             : out std_logic;
        interrupt_ack           : out std_logic;
        --interrupt_ack           : out std_logic_vector(1 downto 0);

        addr_in                 : in  std_logic_vector( 4 downto 0);
        sel_in                  : in  std_logic_vector( 2 downto 0);
        data_in                 : in  std_logic_vector(63 downto 0);
        data_out                : out std_logic_vector(63 downto 0);
        id_ctrl_in              : in  std_logic_vector(10 downto 0);

        alu_flags               : in  std_logic_vector( 4 downto 0);
        pc_in                   : in  std_logic_vector(63 downto 0);
        instruction_in          : in  std_logic_vector(31 downto 0);
        epc_reg                 : out std_logic_vector(63 downto 0);

        data_addr               : in  std_logic_vector(63 downto 0);

        -- exceptions
        address_error_exc_load  : in  std_logic;
        address_error_exc_fetch : in  std_logic;
        address_error_exc_store : in  std_logic;
        instruction_bus_exc     : in  std_logic;
        data_bus_exc            : in  std_logic;
        -- syscall see id_ctrl_in
        -- breakpoint_exc          see id_ctrl_in
        -- reserved_instr_exc      see id_ctrl_in
        -- coprocessor_unimpl_exc  see id_ctrl_in
        -- arithmtic overflow see alu_flags
        -- trap see id_ctrl_in
        fp_exc                  : in  std_logic;

        flush_if                : out std_logic;
        flush_id                : out std_logic;

        -- enable stages
        enable_id               : in  std_logic;
        enable_ex               : in  std_logic;
        enable_mem              : in  std_logic;
        enable_wb               : in  std_logic;

        -- standby mode
        standby                 : in  std_logic
    );
end component;
-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

-- stage_pc
    -- data path
signal s_stage_pc_in                    : std_logic_vector(63 downto 0);
signal s_stage_pc_out                   : std_logic_vector(63 downto 0);

    -- control path
signal s_stage_pc_stall                 : std_logic;
signal s_stage_pc_delay                 : std_logic;

-- instruction fetch
signal s_inst_addr                      : std_logic_vector(63 downto 0);


-- stage_if_id
    -- data path
--signal s_stage_if_id_pc_in              : std_logic_vector(31 downto 0);
signal s_stage_if_id_instruction_in     : std_logic_vector(31 downto 0);
signal s_stage_if_id_pc_out             : std_logic_vector(63 downto 0);
signal s_stage_if_id_instruction_out    : std_logic_vector(31 downto 0);

    -- control path
signal s_stage_if_id_stall              : std_logic;
signal s_stage_if_id_delay              : std_logic;

-- instruction_decode
signal s_id_pc_branch_out               : std_logic_vector(63 downto 0);
signal s_standby                        : std_logic;



-- stage id_ex
    -- data path
signal s_stage_id_ex_reg_data_in_1      : std_logic_vector(63 downto 0);
signal s_stage_id_ex_reg_data_in_2      : std_logic_vector(63 downto 0);
signal s_stage_id_ex_immediate_value_in : std_logic_vector(63 downto 0);
signal s_stage_id_ex_dest_reg_in        : std_logic_vector( 4 downto 0);

signal s_stage_id_ex_reg_data_out_1     : std_logic_vector(63 downto 0);
signal s_stage_id_ex_reg_data_out_2     : std_logic_vector(63 downto 0);
signal s_stage_id_ex_immediate_value_out: std_logic_vector(63 downto 0);
signal s_stage_id_ex_dest_reg_out       : std_logic_vector( 4 downto 0);

    -- forwarding
signal s_stage_id_ex_forward_rs_addr_in : std_logic_vector( 4 downto 0);
signal s_stage_id_ex_forward_rt_addr_in : std_logic_vector( 4 downto 0);
signal s_stage_id_ex_forward_rs_addr_out: std_logic_vector( 4 downto 0);
signal s_stage_id_ex_forward_rt_addr_out: std_logic_vector( 4 downto 0);

    -- control path
signal s_stage_id_ex_alu_src_in         : std_logic;
signal s_stage_id_ex_alu_ctrl_in        : alu_ctrl_t;
signal s_stage_id_ex_ctrl_mem_in        : std_logic_vector( 5 downto 0);
signal s_stage_id_ex_ctrl_wb_in         : std_logic_vector( 1 downto 0);

signal s_stage_id_ex_alu_src_out        : std_logic;
signal s_stage_id_ex_alu_ctrl_out       : alu_ctrl_t;
signal s_stage_id_ex_ctrl_mem_out       : std_logic_vector( 5 downto 0);
signal s_stage_id_ex_ctrl_wb_out        : std_logic_vector( 1 downto 0);

signal s_stage_ex_ctrl_mem_out          : std_logic_vector( 8 downto 0);
signal s_stage_ex_ctrl_wb_out           : std_logic_vector( 1 downto 0);

signal s_stage_id_ex_stall              : std_logic;
signal s_stage_id_ex_delay              : std_logic;

-- execute
signal s_execute_done           : std_logic;
signal s_execute_busy_list      : std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);



-- stage ex_mem
    -- data path
signal s_stage_ex_mem_alu_cp0           : std_logic_vector(63 downto 0);
signal s_stage_ex_mem_alu_result_in     : std_logic_vector(63 downto 0);
signal s_stage_ex_mem_write_data_in     : std_logic_vector(63 downto 0);
signal s_stage_ex_mem_dest_reg_in       : std_logic_vector( 4 downto 0);

signal s_stage_ex_mem_alu_result_out    : std_logic_vector(63 downto 0);
signal s_stage_ex_mem_mem_address_out   : std_logic_vector(63 downto 0);
signal s_stage_ex_mem_write_data_out    : std_logic_vector(63 downto 0);
signal s_stage_ex_mem_dest_reg_out      : std_logic_vector( 4 downto 0);

    -- control path
signal s_stage_ex_mem_ctrl_mem_out      : std_logic_vector( 8 downto 0);
signal s_stage_ex_mem_ctrl_wb_out       : std_logic_vector( 1 downto 0);

signal s_stage_ex_mem_stall             : std_logic;
signal s_stage_ex_mem_delay             : std_logic;


-- stage mem
signal s_stage_mem_ctrl_wb              : std_logic_vector( 1 downto 0);
signal s_en_mem_aligner                 : std_logic;

-- stage mem_wb
    -- data path
signal s_stage_mem_wb_alu_result_in     : std_logic_vector(63 downto 0);
signal s_stage_mem_wb_read_data_in      : std_logic_vector(63 downto 0);

signal s_stage_mem_wb_alu_result_out    : std_logic_vector(63 downto 0);
signal s_stage_mem_wb_read_data_out     : std_logic_vector(63 downto 0);
signal s_stage_mem_wb_dest_reg_out      : std_logic_vector( 4 downto 0);

    -- control path
signal s_stage_mem_wb_ctrl_wb_out       : std_logic_vector( 1 downto 0);

signal s_stage_mem_wb_ctrl_mem_in       : std_logic_vector( 8 downto 0);
signal s_stage_mem_wb_ctrl_mem_out      : std_logic_vector( 8 downto 0);
signal s_stage_mem_wb_stall             : std_logic;
signal s_stage_mem_wb_delay             : std_logic;

-- coprocessor
    -- data path
signal s_cp0_addr_in                    : std_logic_vector( 4 downto 0);
signal s_cp0_sel_in                     : std_logic_vector( 2 downto 0);
signal s_cp0_data_in                    : std_logic_vector(63 downto 0);
signal s_cp0_data_out                   : std_logic_vector(63 downto 0);

    -- control path
signal s_cp0_id_ctrl_in                 : std_logic_vector(10 downto 0);
signal s_cp0_alu_flags                  : std_logic_vector( 4 downto 0);
signal s_cp0_mfc_delayed                : std_logic;
signal s_cp0_epc_reg                    : std_logic_vector(63 downto 0);

signal s_cop_en                         : std_logic;



-- combinatorial
    -- data path
signal s_wb_write_data                  : std_logic_vector(63 downto 0);

    -- control path
signal s_if_take_branch                 : std_logic;
signal s_hazard_stall                   : std_logic;
signal s_flush_if                       : std_logic;
signal s_flush_id                       : std_logic;
signal s_interrupt_syn                  : std_logic;

signal halt                             : std_logic;

signal s_flush_execute                  : std_logic;

signal s_data_addr                      : std_logic_vector(63 downto 0);
signal s_data_read_access		        : std_logic;
signal s_data_write_access		        : std_logic;
signal s_unaligned_memory_access_busy   : std_logic;

signal en_id                            : std_logic;
signal en_ex                            : std_logic;
signal en_mem                           : std_logic;
signal en_wb                            : std_logic;


-- /*end-folding-block*/

begin

inst_addr <= s_inst_addr;

--------------------------------------------------------------------------------
-- PORT MAPS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

inst_stage_pc : stage_pc_64
    generic map(
        G_START_ADDRESS     => G_START_ADDRESS
    )
    port map(

        clk                 => clk,
        reset               => s_stage_pc_stall,
        enable              => s_stage_pc_delay,
        syn_interrupt       => s_flush_if,

        -- data path
        pc_in               => s_stage_pc_in,
        pc_out              => s_stage_pc_out
    );


inst_instruction_fetch : instruction_fetch_64
    generic map(
        G_EXCEPTION_HANDLER_ADDRESS => G_EXCEPTION_HANDLER_ADDRESS
    )
    port map(

        -- data path
        pc_branch           => s_id_pc_branch_out,
        pc_current          => s_stage_pc_out,
        pc_next             => s_stage_pc_in,
--        pc_plus4            => s_stage_if_id_pc_in,
        instruction         => s_stage_if_id_instruction_in,

        inst_data           => inst_din,
        inst_address        => s_inst_addr,

        -- control path
        interrupt_syn       => s_flush_if,
        take_branch         => s_if_take_branch
    );


inst_stage_if_id : stage_if_id_64
    port map(

        clk                 => clk,
        reset               => s_stage_if_id_stall,
        enable              => s_stage_if_id_delay,
        syn_interrupt       => s_flush_if,

        -- data path
        pc_in               => s_stage_pc_in,
        instruction_in      => s_stage_if_id_instruction_in,
        pc_out              => s_stage_if_id_pc_out,
        instruction_out     => s_stage_if_id_instruction_out
    );


inst_instruction_decode : instruction_decode_64
    generic map(
        G_EXC_RESERVED_INSTRUCTION  => G_EXC_RESERVED_INSTRUCTION,
        G_EXC_COP_UNIMPLEMENTED     => G_EXC_COP_UNIMPLEMENTED,
        G_BUSY_LIST_WIDTH           => G_BUSY_LIST_WIDTH
    )
    port map(
        clk                 => clk,
        reset               => s_stage_if_id_stall,
        enable              => s_stage_id_ex_delay,

        -- data path
        pc_in               => s_stage_if_id_pc_out,
        pc_branch           => s_id_pc_branch_out,
        instruction         => s_stage_if_id_instruction_out,

        write_register      => s_stage_mem_wb_dest_reg_out,
        write_data          => s_wb_write_data,
        reg_data_1          => s_stage_id_ex_reg_data_in_1,
        reg_data_2          => s_stage_id_ex_reg_data_in_2,
        immediate_value     => s_stage_id_ex_immediate_value_in,
        dest_reg            => s_stage_id_ex_dest_reg_in,

        -- forwarding
        forward_rs_addr     => s_stage_id_ex_forward_rs_addr_in,
        forward_rt_addr     => s_stage_id_ex_forward_rt_addr_in,
        forward_dest_ex_mem => s_stage_ex_mem_dest_reg_out,
        forward_dest_mem_wb => s_stage_mem_wb_dest_reg_out,
        forward_ex_mem      => s_stage_ex_mem_alu_result_out,
        forward_mem_wb      => s_wb_write_data,
        ctrl_reg_write_id_ex=> s_stage_id_ex_ctrl_wb_out(1),
        ctrl_reg_write_ex_mem=> s_stage_ex_mem_ctrl_wb_out(1),
        ctrl_reg_write_mem_wb=> s_stage_mem_wb_ctrl_wb_out(1),
        ex_result_dest      => s_stage_ex_mem_dest_reg_in,
        ex_ctrl_wb_out      => s_stage_ex_ctrl_wb_out,

        -- hazard detection unit
        hazard_rt_id_ex     => s_stage_ex_mem_dest_reg_in,
        hazard_rt_ex_mem    => s_stage_ex_mem_dest_reg_out,
        hazard_stall        => s_hazard_stall,

        -- Coprocessor
        cp0_addr            => s_cp0_addr_in,
        cp0_sel             => s_cp0_sel_in,
        cp0_data_in         => s_cp0_data_in,
        cp0_ctrl            => s_cp0_id_ctrl_in,
        cp0_epc_reg         => s_cp0_epc_reg,


        -- control path
        ctrl_reg_write      => s_stage_mem_wb_ctrl_wb_out(1),
        alu_src             => s_stage_id_ex_alu_src_in,
        alu_ctrl            => s_stage_id_ex_alu_ctrl_in,
        ctrl_mem            => s_stage_id_ex_ctrl_mem_in,
        ctrl_wb             => s_stage_id_ex_ctrl_wb_in,

        ctrl_take_branch    => s_if_take_branch,

        -- interrupt
        syn_interrupt       => s_flush_id,

        -- from execute
        execute_done        => s_execute_done,
        execute_busy_list   => s_execute_busy_list,

        -- standby mode
        standby             => s_standby
    );


inst_stage_id_ex : stage_id_ex_64
    port map(

        clk                 => clk,
        reset               => s_stage_id_ex_stall,
        enable              => s_stage_id_ex_delay,


        -- data path
        reg_data_in_1       => s_stage_id_ex_reg_data_in_1,
        reg_data_in_2       => s_stage_id_ex_reg_data_in_2,
        immediate_value_in  => s_stage_id_ex_immediate_value_in,
        dest_reg_in         => s_stage_id_ex_dest_reg_in,

        reg_data_out_1      => s_stage_id_ex_reg_data_out_1,
        reg_data_out_2      => s_stage_id_ex_reg_data_out_2,
        immediate_value_out => s_stage_id_ex_immediate_value_out,
        dest_reg_out        => s_stage_id_ex_dest_reg_out,

        -- forwarding
        forward_rs_addr_in  => s_stage_id_ex_forward_rs_addr_in,
        forward_rt_addr_in  => s_stage_id_ex_forward_rt_addr_in,
        forward_rs_addr_out => s_stage_id_ex_forward_rs_addr_out,
        forward_rt_addr_out => s_stage_id_ex_forward_rt_addr_out,

        -- control path
        alu_src_in          => s_stage_id_ex_alu_src_in,
        alu_ctrl_in         => s_stage_id_ex_alu_ctrl_in,
        ctrl_mem_in         => s_stage_id_ex_ctrl_mem_in,
        ctrl_wb_in          => s_stage_id_ex_ctrl_wb_in,

        alu_src_out         => s_stage_id_ex_alu_src_out,
        alu_ctrl_out        => s_stage_id_ex_alu_ctrl_out,
        ctrl_mem_out        => s_stage_id_ex_ctrl_mem_out,
        ctrl_wb_out         => s_stage_id_ex_ctrl_wb_out
    );


inst_execute : execute_64
    generic map(
        G_EXC_ARITHMETIC_OVERFLOW   => G_EXC_ARITHMETIC_OVERFLOW,
        G_SENSOR_DATA_WIDTH         => G_SENSOR_DATA_WIDTH,
        G_SENSOR_CONF_WIDTH         => G_SENSOR_CONF_WIDTH,
        G_BUSY_LIST_WIDTH           => G_BUSY_LIST_WIDTH
    )
    port map(
        -- general
        clk                 => clk,
        resetn              => s_stage_ex_mem_stall,
        enable              => s_stage_ex_mem_delay,

        -- data path
        reg_data_in_1       => s_stage_id_ex_reg_data_out_1,
        reg_data_in_2       => s_stage_id_ex_reg_data_out_2,
        immediate_value     => s_stage_id_ex_immediate_value_out,
        dest_reg_in         => s_stage_id_ex_dest_reg_out,

        alu_result          => s_stage_ex_mem_alu_result_in,
        reg_data_out        => s_stage_ex_mem_write_data_in,
        dest_reg_out        => s_stage_ex_mem_dest_reg_in,

        -- forwarding
        forward_rs_addr     => s_stage_id_ex_forward_rs_addr_out,
        forward_rt_addr     => s_stage_id_ex_forward_rt_addr_out,
        forward_dest_ex_mem => s_stage_ex_mem_dest_reg_out,
        forward_dest_mem_wb => s_stage_mem_wb_dest_reg_out,
        forward_ex_mem      => s_stage_ex_mem_alu_result_out,
        forward_mem_wb      => s_wb_write_data,
        ctrl_reg_write_ex_mem=> s_stage_ex_mem_ctrl_wb_out(1),
        ctrl_reg_write_mem_wb=> s_stage_mem_wb_ctrl_wb_out(1),

        -- control path
        alu_flags           => s_cp0_alu_flags,
        alu_src             => s_stage_id_ex_alu_src_out,
        alu_ctrl            => s_stage_id_ex_alu_ctrl_out,

        ctrl_mem_in         => s_stage_id_ex_ctrl_mem_out,
        ctrl_wb_in          => s_stage_id_ex_ctrl_wb_out,

        ctrl_mem_out        => s_stage_ex_ctrl_mem_out,
        ctrl_wb_out         => s_stage_ex_ctrl_wb_out,

        flush               => s_flush_execute,
        -- ASIP
        done                => s_execute_done,
        busy_list           => s_execute_busy_list,
        sensor_data_in      => sensor_data_in,
        sensor_config_out   => sensor_config_out
    );


inst_stage_ex_mem : stage_ex_mem_64
    port map(

        clk                 => clk,
        reset               => s_stage_ex_mem_stall,
        enable              => s_stage_ex_mem_delay,


        -- data path
        alu_result_in       => s_stage_ex_mem_alu_cp0,
        write_data_in       => s_stage_ex_mem_write_data_in,
        dest_reg_in         => s_stage_ex_mem_dest_reg_in,

        alu_result_out      => s_stage_ex_mem_alu_result_out,
        mem_address_out     => s_stage_ex_mem_mem_address_out,
        write_data_out      => s_stage_ex_mem_write_data_out,
        dest_reg_out        => s_stage_ex_mem_dest_reg_out,


        -- control path
        ctrl_mem_in         => s_stage_ex_ctrl_mem_out,
        ctrl_wb_in          => s_stage_ex_ctrl_wb_out,

        ctrl_mem_out        => s_stage_ex_mem_ctrl_mem_out,
        ctrl_wb_out         => s_stage_ex_mem_ctrl_wb_out
    );


inst_memory_access : memory_access_64
    generic map(
        G_EXC_ADDRESS_ERROR_LOAD    => G_EXC_ADDRESS_ERROR_LOAD,
        G_EXC_ADDRESS_ERROR_STORE   => G_EXC_ADDRESS_ERROR_STORE,
        G_EXC_DATA_BUS_ERROR        => G_EXC_DATA_BUS_ERROR
    )
    port map(
        clk                         => clk,
        resetn                      => resetn,
        enable                      => s_en_mem_aligner,

        -- data path
        alu_result_in               => s_stage_ex_mem_alu_result_out,
        mem_address_in              => s_stage_ex_mem_mem_address_out,
        reg_data_in                 => s_stage_ex_mem_write_data_out,

        alu_result_out              => s_stage_mem_wb_alu_result_in,
        memory_data                 => s_stage_mem_wb_read_data_in,

        mem_address                 => s_data_addr,
        mem_data_write              => data_dout,
        mem_data_read               => data_din,

        data_read_busy              => data_read_busy,
        data_write_busy             => data_write_busy,

        address_error_exc_load      => address_error_exc_load,
        address_error_exc_store     => address_error_exc_store,
        data_bus_exc                => data_bus_exc,

        -- flush execute
        flush_execute               => s_flush_execute,

        ctrl_mem_in                 => s_stage_ex_mem_ctrl_mem_out,
        ctrl_mem_out                => s_stage_mem_wb_ctrl_mem_in,

        data_read_access		    => s_data_read_access,
        data_write_access		    => s_data_write_access,

        unaligned_mem_access_busy   => s_unaligned_memory_access_busy,

        ctrl_wb_in                  => s_stage_ex_mem_ctrl_wb_out,
        ctrl_wb_out                 => s_stage_mem_ctrl_wb
    );


inst_stage_mem_wb : stage_mem_wb_64
    port map(

        clk                 => clk,
        reset               => s_stage_mem_wb_stall,
        enable              => s_stage_mem_wb_delay,


        -- data path
        alu_result_in       => s_stage_mem_wb_alu_result_in,
        read_data_in        => s_stage_mem_wb_read_data_in,
        dest_reg_in         => s_stage_ex_mem_dest_reg_out,

        alu_result_out      => s_stage_mem_wb_alu_result_out,
        read_data_out       => s_stage_mem_wb_read_data_out,
        dest_reg_out        => s_stage_mem_wb_dest_reg_out,


        -- control path
        ctrl_mem_in         => s_stage_mem_wb_ctrl_mem_in,
        ctrl_mem_out        => s_stage_mem_wb_ctrl_mem_out,

        ctrl_wb_in          => s_stage_mem_ctrl_wb,
        ctrl_wb_out         => s_stage_mem_wb_ctrl_wb_out
    );


inst_write_back : write_back_64
    port map(

        -- data path
        alu_result          => s_stage_mem_wb_alu_result_out,
        memory_data         => s_stage_mem_wb_read_data_out,
        write_data          => s_wb_write_data,

        -- control path
        ctrl_mem_in         => s_stage_mem_wb_ctrl_mem_out,
        ctrl_wb             => s_stage_mem_wb_ctrl_wb_out(0)
    );


halt <= not enable;

inst_coprocessor0 : coprocessor0_64
    generic map(
        G_START_ADDRESS             => G_START_ADDRESS,
        -- interrupts
        G_TIMER_INTERRUPT           => G_TIMER_INTERRUPT,
        G_NUM_HW_INTERRUPTS         => G_NUM_HW_INTERRUPTS,
        -- exceptions
        G_EXC_ADDRESS_ERROR_LOAD    => G_EXC_ADDRESS_ERROR_LOAD,
        G_EXC_ADDRESS_ERROR_FETCH   => G_EXC_ADDRESS_ERROR_FETCH,
        G_EXC_ADDRESS_ERROR_STORE   => G_EXC_ADDRESS_ERROR_STORE,
        G_EXC_INSTRUCTION_BUS_ERROR => G_EXC_INSTRUCTION_BUS_ERROR,
        G_EXC_DATA_BUS_ERROR        => G_EXC_DATA_BUS_ERROR,
        G_EXC_SYSCALL               => G_EXC_SYSCALL,
        G_EXC_BREAKPOINT            => G_EXC_BREAKPOINT,
        G_EXC_RESERVED_INSTRUCTION  => G_EXC_RESERVED_INSTRUCTION,
        G_EXC_COP_UNIMPLEMENTED     => G_EXC_COP_UNIMPLEMENTED,
        G_EXC_ARITHMETIC_OVERFLOW   => G_EXC_ARITHMETIC_OVERFLOW,
        G_EXC_TRAP                  => G_EXC_TRAP,
        G_EXC_FLOATING_POINT        => G_EXC_FLOATING_POINT
    )
    port map(
        clk                     => clk,
        reset                   => resetn,
        enable                  => s_cop_en,

        interrupt               => interrupt,
        mfc_delayed             => s_cp0_mfc_delayed,
        interrupt_ack           => interrupt_ack,

        addr_in                 => s_cp0_addr_in,
        sel_in                  => s_cp0_sel_in,
        data_in                 => s_cp0_data_in,
        data_out                => s_cp0_data_out,
        id_ctrl_in              => s_cp0_id_ctrl_in,

        alu_flags               => s_cp0_alu_flags,

        pc_in                   => s_inst_addr,

        instruction_in          => s_stage_if_id_instruction_out,

        epc_reg                 => s_cp0_epc_reg,

        data_addr               => s_data_addr,

        -- exceptions
        address_error_exc_load  => address_error_exc_load,
        address_error_exc_fetch => address_error_exc_fetch,
        address_error_exc_store => address_error_exc_store,
        instruction_bus_exc     => instruction_bus_exc,
        data_bus_exc            => data_bus_exc,
        -- syscall see id_ctrl_in
        -- breakpoint_exc          see id_ctrl_in
        -- reserved_instr_exc      see id_ctrl_in
        -- coprocessor_unimpl_exc  see id_ctrl_in
        -- arithmtic overflow see alu_flags
        -- trap see id_ctrl_in
        fp_exc                  => '0',

        flush_if                => s_flush_if,
        flush_id                => s_flush_id,

        -- enable stages
        enable_id               => s_stage_if_id_delay,
        enable_ex               => s_stage_id_ex_delay,
        enable_mem              => s_stage_ex_mem_delay,
        enable_wb               => s_stage_mem_wb_delay,

        -- standby mode
        standby                 => s_standby
    );

-- /*end-folding-block*/


--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/


s_stage_ex_mem_alu_cp0  <= s_stage_ex_mem_alu_result_in when (s_cp0_mfc_delayed='0') else s_cp0_data_out;


s_stage_pc_stall        <= resetn;
s_stage_pc_delay        <= en_id and not inst_read_busy and not data_read_busy and not data_write_busy and not s_unaligned_memory_access_busy and not s_hazard_stall and not s_standby;
--s_stage_if_id_stall       <= resetn or s_interrupt_syn;
s_stage_if_id_stall     <= resetn;
s_stage_if_id_delay     <= en_id and not inst_read_busy and not data_read_busy and not data_write_busy and not s_unaligned_memory_access_busy and not s_hazard_stall and not s_standby;
s_stage_id_ex_stall     <= resetn;
s_stage_id_ex_delay     <= en_ex and not inst_read_busy and not data_read_busy and not data_write_busy and not s_unaligned_memory_access_busy and s_execute_done and not s_standby;
s_stage_ex_mem_stall    <= resetn;
s_stage_ex_mem_delay    <= en_mem and not inst_read_busy and not data_read_busy and not data_write_busy and not s_unaligned_memory_access_busy and not s_standby;
s_en_mem_aligner        <= en_mem and not inst_read_busy and not data_read_busy and not data_write_busy and not s_standby;
s_stage_mem_wb_stall    <= resetn;
s_stage_mem_wb_delay    <= en_wb and not inst_read_busy and not data_read_busy and not data_write_busy and not s_unaligned_memory_access_busy and not s_standby;
s_cop_en                <= enable and not inst_read_busy and not data_read_busy and not data_write_busy and not s_unaligned_memory_access_busy;

--data_we                 <= s_stage_ex_mem_ctrl_mem_out(0);
hazard_stall			<= s_hazard_stall;
data_read_access		<= s_data_read_access;
data_write_access		<= s_data_write_access;
data_addr               <= s_data_addr;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

process(clk, resetn)
begin
    if (resetn = '0') then
        en_id  <= '0';
        en_ex  <= '0';
        en_mem <= '0';
        en_wb  <= '0';
    elsif (clk'event and clk = '1') then
        en_id  <= enable;
        en_ex  <= en_id;
        en_mem <= en_ex;
        en_wb  <= en_mem;
    end if;
end process;


-- /*end-folding-block*/

end architecture;

