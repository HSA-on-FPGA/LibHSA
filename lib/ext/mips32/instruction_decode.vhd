-- instruction_decode: Instruction decode unit for mips pipeline
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
--use ieee.math_real.all;
use work.alu_pkg.all;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
entity instruction_decode is
    generic(
        G_EXC_RESERVED_INSTRUCTION  : boolean := false;
        G_EXC_COP_UNIMPLEMENTED     : boolean := false;
        G_BUSY_LIST_WIDTH           : integer range 1 to 1024
    );
    port(
        clk                             : in  std_logic; -- wird benötigt um aus den Registern in einem Takt zu lesen und in sie zu schreiben
        reset                           : in  std_logic;
        enable                          : in  std_logic;

        -- data path
        pc_in                           : in  std_logic_vector(31 downto 0);    -- Aktueller Programmzaehler
        pc_branch                       : out std_logic_vector(31 downto 0);    -- Sprungzieladresse
        instruction                     : in  std_logic_vector(31 downto 0);

        write_register                  : in  std_logic_vector( 4 downto 0);    -- Rueckschreibadresse
        write_data                      : in  std_logic_vector(31 downto 0);    -- Rueckschreibdaten
        reg_data_1                      : out std_logic_vector(31 downto 0);    -- Registerwert 1 fuer ALU
        reg_data_2                      : out std_logic_vector(31 downto 0);    -- Registerwert 2 fuer ALU
        immediate_value                 : out std_logic_vector(31 downto 0);    -- muss teilweise eine Vorzeichenerweiterung besitzen

        dest_reg                        : out std_logic_vector( 4 downto 0);    -- Adresse fuer R-Typ Befehle | rt oder rd

        -- forwarding
        forward_rs_addr                 : out std_logic_vector( 4 downto 0);
        forward_rt_addr                 : out std_logic_vector( 4 downto 0);
        forward_dest_ex_mem             : in  std_logic_vector( 4 downto 0);
        forward_dest_mem_wb             : in  std_logic_vector( 4 downto 0);
        forward_ex_mem                  : in  std_logic_vector(31 downto 0);
        forward_mem_wb                  : in  std_logic_vector(31 downto 0);
        ctrl_reg_write_id_ex            : in  std_logic;
        ctrl_reg_write_ex_mem           : in  std_logic;
        ctrl_reg_write_mem_wb           : in  std_logic;
        ex_result_dest                  : in  std_logic_vector( 4 downto 0);
        ex_ctrl_wb_out                  : in  std_logic_vector( 1 downto 0);

        -- hazard detection unit
        hazard_rt_id_ex                 : in  std_logic_vector( 4 downto 0);
        hazard_rt_ex_mem                : in  std_logic_vector( 4 downto 0);
        hazard_stall                    : out std_logic;

        -- Coproecessor
        cp0_addr                        : out std_logic_vector( 4 downto 0);
        cp0_sel                         : out std_logic_vector( 2 downto 0);
        cp0_data_in                     : out std_logic_vector(31 downto 0);
        cp0_ctrl                        : out std_logic_vector( 9 downto 0);
        cp0_epc_reg                     : in  std_logic_vector(31 downto 0);

        -- control path
        ctrl_reg_write                  : in  std_logic;                        -- Wert in Register zuruekschreiben
        alu_src                         : out std_logic;
        alu_ctrl                        : out alu_ctrl_t;
        ctrl_mem                        : out std_logic_vector( 4 downto 0);
        ctrl_wb                         : out std_logic_vector( 1 downto 0);

        ctrl_take_branch                : out std_logic;        -- Sprung ausfuehren

        -- interrupt
        syn_interrupt                   : in  std_logic;

        -- from execute
        execute_done                    : in  std_logic;
        execute_busy_list               : in std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);

        -- standby mode
        standby                         : out std_logic
    );
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of instruction_decode is

component branching_unit is
    port (
        -- general
        clk                     : in  std_logic;
        resetn                  : in  std_logic;
        enable                  : in  std_logic;
        hazard_stall            : in  std_logic;

        -- instruction data
        instruction             : in  std_logic_vector(31 downto 0);
        immediate               : in  std_logic_vector(31 downto 0);
        mtc                     : in  std_logic;

        -- input address signals
        pc                      : in  std_logic_vector(31 downto 0);
        forwarding_mtc          : in  std_logic_vector(31 downto 0);
        epc                     : in  std_logic_vector(31 downto 0);

        -- eval branch condition
        data_reg_1              : in  std_logic_vector(31 downto 0);
        data_reg_2              : in  std_logic_vector(31 downto 0);
        addr_reg_1              : in  std_logic_vector( 4 downto 0);
        addr_reg_2              : in  std_logic_vector( 4 downto 0);
        forward_dest_ex_mem     : in  std_logic_vector( 4 downto 0);
        ctrl_reg_write_ex_mem   : in  std_logic;
        forward_ex_mem          : in  std_logic_vector(31 downto 0);
        forward_dest_mem_wb     : in  std_logic_vector( 4 downto 0);
        ctrl_reg_write_mem_wb   : in  std_logic;
        forward_mem_wb          : in  std_logic_vector(31 downto 0);

        -- interrupt
        syn_interrupt           : in  std_logic;

        -- outputs
        pc_branch               : out std_logic_vector(31 downto 0);
        take_branch             : out std_logic
    );
end component;

component hazard_detection_unit is
    port (
        -- general
        clk                     : in  std_logic;
        resetn                  : in  std_logic;
        enable                  : in  std_logic;
        syn_interrupt           : in  std_logic;

        -- inputs
        opcode                  : in  std_logic_vector( 5 downto 0);
        funct                   : in  std_logic_vector( 5 downto 0);
        rs                      : in  std_logic_vector( 4 downto 0);
        rt                      : in  std_logic_vector( 4 downto 0);
        hazard_rt_id_ex         : in  std_logic_vector( 4 downto 0);
        ctrl_reg_write_id_ex    : in  std_logic;
        ex_result_dest          : in  std_logic_vector( 4 downto 0);
        ex_ctrl_wb              : in  std_logic_vector( 1 downto 0);

        -- outputs
        hazard_stall            : out std_logic
    );
end component;

component forwarding_unit is
    port (
        -- general
        clk                     : in  std_logic;
        resetn                  : in  std_logic;
        enable                  : in  std_logic;

        -- input
        data_reg_1              : in  std_logic_vector(31 downto 0);
        data_reg_2              : in  std_logic_vector(31 downto 0);
        addr_reg_1              : in  std_logic_vector( 4 downto 0);
        addr_reg_2              : in  std_logic_vector( 4 downto 0);

        -- forwarding ex mem stage
        ctrl_reg_write_ex_mem   : in  std_logic;
        forward_dest_ex_mem     : in  std_logic_vector( 4 downto 0);
        forward_ex_mem          : in  std_logic_vector(31 downto 0);

        -- forwarding mem wb stage
        ctrl_reg_write_mem_wb   : in  std_logic;
        forward_dest_mem_wb     : in  std_logic_vector( 4 downto 0);
        forward_mem_wb          : in  std_logic_vector(31 downto 0);

        -- output
        forwarded_value_1       : out std_logic_vector(31 downto 0);
        forwarded_value_2       : out std_logic_vector(31 downto 0);
        forwarded_value_mtc     : out std_logic_vector(31 downto 0)
    );
end component;

component decoder_unit is
    generic(
        G_EXC_RESERVED_INSTRUCTION  : boolean := false;
        G_EXC_COP_UNIMPLEMENTED     : boolean := false;
        G_BUSY_LIST_WIDTH           : integer range 1 to 1024
    );
    port (
        -- inputs
        instruction             : in  std_logic_vector(31 downto 0);
        forwarded_value_1       : in  std_logic_vector(31 downto 0);
        forwarded_value_2       : in  std_logic_vector(31 downto 0);
        execute_busy_list       : in  std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);

        -- outputs
        regwrite                : out std_logic;
        regdst                  : out std_logic;
        alu_src                 : out std_logic;
        memread                 : out std_logic;
        memwrite                : out std_logic;
        mem_byte                : out std_logic;
        mem_halfword            : out std_logic;
        mem_unsigned            : out std_logic;
        memtoreg                : out std_logic;
        branch_link             : out std_logic;
        iret                    : out std_logic;
        sign_extend             : out std_logic;
        alu_ctrl                : out alu_ctrl_t;
        is_branch_instruction   : out std_logic;

        -- CP0
        mfc                     : out std_logic;
        mtc                     : out std_logic;

        -- exceptions
        syscall                 : out std_logic;
        trap                    : out std_logic;
        reserved_instr          : out std_logic;
        cop_unimplemented       : out std_logic;
        breakpoint              : out std_logic;

        -- ASIP hazards
        stall                   : out std_logic;

        -- standby mode
        standby                 : out std_logic
    );
end component;

--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/


-- externe Kontrollsignale
signal s_ctrl_mem   : std_logic_vector( 4 downto 0);
signal s_ctrl_wb    : std_logic_vector( 1 downto 0);
signal s_hazard_stall_internal : std_logic;
signal s_hazard_stall : std_logic;
signal s_asip_decode_hazard_stall : std_logic;
signal s_alu_ctrl   : alu_ctrl_t;
signal s_alu_src    : std_logic;

-- needs to go through the pipeline to have functional forwarding
alias mtc               : std_logic is cp0_ctrl(0);
alias mfc               : std_logic is cp0_ctrl(1);
alias iret              : std_logic is cp0_ctrl(2);
alias syscall           : std_logic is cp0_ctrl(3);
alias trap              : std_logic is cp0_ctrl(4);
alias delay_slot        : std_logic is cp0_ctrl(5);
alias cop_unimplemented : std_logic is cp0_ctrl(6);
alias reserved_instr    : std_logic is cp0_ctrl(7);
alias breakpoint        : std_logic is cp0_ctrl(8);
alias stall_delayed     : std_logic is cp0_ctrl(9);

alias memread           : std_logic is s_ctrl_mem(1);
alias memwrite          : std_logic is s_ctrl_mem(0);
alias mem_byte          : std_logic is s_ctrl_mem(2);
alias mem_halfword      : std_logic is s_ctrl_mem(3);
alias mem_unsigned      : std_logic is s_ctrl_mem(4);

alias regwrite      : std_logic is s_ctrl_wb(1);
alias memtoreg      : std_logic is s_ctrl_wb(0);

alias funct         : std_logic_vector(5 downto 0) is instruction(5 downto 0);
signal opcode       : std_logic_vector( 7 downto 0);
signal rs           : std_logic_vector( 7 downto 0);
signal rt           : std_logic_vector( 7 downto 0);

signal regdst       : std_logic;

-- interne Kontrollsignale für die Sprungberechnung
signal branch_link  : std_logic;    -- Bei Befehlen mit Link-Option wird der PC in Register 31 gesichert

signal s_iret       : std_logic;

signal s_sign_extend: std_logic;

-- Signale damit Daten von gelesenen Registern an die Sprungberechnung geleitet werden können
signal s_forwarded_data_1     : std_logic_vector(31 downto 0);
signal s_forwarded_data_2     : std_logic_vector(31 downto 0);

signal s_immediate_value    : std_logic_vector(31 downto 0);    -- wird benötigt für Sprungberechnung
alias  rd                   : std_logic_vector( 4 downto 0) is instruction(15 downto 11);

-- Prozessorregister
type register_type is array (natural range <>) of std_logic_vector(31 downto 0);
signal registers : register_type(31 downto 0); -- := (others=>(others=>'0'));

-- mtc signals
signal s_forwarding_mtc     : std_logic_vector(31 downto 0);
signal s_mtc                : std_logic;

signal reg_hazard_stall : std_logic;

signal data_rs              : std_logic_vector(31 downto 0);
signal data_rt              : std_logic_vector(31 downto 0);

signal s_is_branch_instruction    : std_logic;
-- /*end-folding-block*/

begin


--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    s_hazard_stall <= s_hazard_stall_internal or s_asip_decode_hazard_stall or (not execute_done);

    opcode          <=  "00"  & instruction(31 downto 26);
    rs              <=  "000" & instruction(25 downto 21);
    rt              <=  "000" & instruction(20 downto 16);
    s_immediate_value   <=   x"0000" & instruction(15 downto 0) when s_sign_extend='0'
                        else std_logic_vector(to_signed( to_integer(signed(instruction(15 downto 0))),32)); -- Vorzeichenerweiterung

    -- destination registers
    dest_reg        <= "00000"                      when s_hazard_stall='1' else
                       "11111"                      when branch_link='1'    else
                       instruction(20 downto 16)    when regdst='0'         else
                       instruction(15 downto 11);

    immediate_value <= s_immediate_value;

    reg_data_1      <= s_forwarded_data_1 when branch_link='0' else pc_in;
    reg_data_2      <= s_forwarded_data_2 when branch_link='0' else x"00000004";

    forward_rs_addr <= rs(4 downto 0) when (branch_link='0' and s_hazard_stall='0') else "00000";
    forward_rt_addr <= rt(4 downto 0) when (branch_link='0' and s_hazard_stall='0') else "00000";

    hazard_stall    <= s_hazard_stall;
    alu_src         <= s_alu_src    when (s_hazard_stall='0' and syn_interrupt='0') else '0';
    alu_ctrl        <= s_alu_ctrl   when (s_hazard_stall='0' and syn_interrupt='0') else op_nop;
    ctrl_mem        <= s_ctrl_mem   when (s_hazard_stall='0' and syn_interrupt='0') else (others=>'0');
    ctrl_wb         <= s_ctrl_wb    when (s_hazard_stall='0' and syn_interrupt='0') else (others=>'0');

    delay_slot      <= s_is_branch_instruction when (s_hazard_stall='0') else '0';

    iret            <= s_iret;
    cp0_addr        <= instruction(15 downto 11);
    cp0_sel         <= instruction(2 downto 0);
    cp0_data_in     <= s_forwarding_mtc;
    mtc             <= s_mtc;

    stall_delayed   <= reg_hazard_stall;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

proc_forward_branching_unit_data: process(rs,rt, ctrl_reg_write_mem_wb,
    forward_dest_mem_wb, forward_mem_wb, registers)
begin

    --forwardA=00
    data_rs    <= registers(to_integer(unsigned(rs)));
    --forwardB=00
    data_rt    <= registers(to_integer(unsigned(rt)));

    -- forward mem/wb stage
    if (ctrl_reg_write_mem_wb='1' and forward_dest_mem_wb/="00000" and rs(4 downto 0)=forward_dest_mem_wb) then
        --forwardA=01
        data_rs    <= forward_mem_wb;
    end if;
    if (ctrl_reg_write_mem_wb='1' and forward_dest_mem_wb/="00000" and rt(4 downto 0)=forward_dest_mem_wb) then
        --forwardB=01
        data_rt    <= forward_mem_wb;
    end if;

end process proc_forward_branching_unit_data;

delay_hazard_stall: process(clk, reset)
begin
    if (reset = '0') then
        reg_hazard_stall <= '0';
    elsif (clk'event and clk = '1') then
        reg_hazard_stall <= s_hazard_stall;
    end if;
end process delay_hazard_stall;

-- Schreibzugriff auf Register
--reg_access: process(ctrl_reg_write,write_register,write_data)
reg_access: process(clk, reset)
begin
    if (reset='0') then
        registers <= (others=>(others=>'0'));
    elsif rising_edge(clk) then
        if (ctrl_reg_write = '1' and write_register/="00000") then
            registers(to_integer(unsigned(write_register))) <= write_data;
        end if;
    end if;
end process;

branching_unit_inst : branching_unit
    port map (
        -- general
        clk                     => clk,
        resetn                  => reset,
        enable                  => enable,
        hazard_stall            => s_hazard_stall,

        -- instruction data
        instruction             => instruction,
        immediate               => s_immediate_value,
        mtc                     => s_mtc,

        -- input address signals
        pc                      => pc_in,
        forwarding_mtc          => s_forwarding_mtc,
        epc                     => cp0_epc_reg,

        -- eval branch condition
        data_reg_1              => data_rs,
        data_reg_2              => data_rt,
        addr_reg_1              => rs(4 downto 0),
        addr_reg_2              => rt(4 downto 0),
        forward_dest_ex_mem     => forward_dest_ex_mem,
        ctrl_reg_write_ex_mem   => ctrl_reg_write_ex_mem,
        forward_ex_mem          => forward_ex_mem,
        forward_dest_mem_wb     => forward_dest_mem_wb,
        ctrl_reg_write_mem_wb   => ctrl_reg_write_mem_wb,
        forward_mem_wb          => forward_mem_wb,

        -- interrupt
        syn_interrupt           => syn_interrupt,

        -- outputs
        pc_branch               => pc_branch,
        take_branch             => ctrl_take_branch
    );

hazard_detection_unit_inst : hazard_detection_unit
    port map (
        -- general
        clk                     => clk,
        resetn                  => reset,
        enable                  => enable,
        syn_interrupt           => syn_interrupt,

        -- inputs
        opcode                  => opcode(5 downto 0),
        funct                   => funct,
        rs                      => rs(4 downto 0),
        rt                      => rt(4 downto 0),
        hazard_rt_id_ex         => hazard_rt_id_ex,
        ctrl_reg_write_id_ex    => ctrl_reg_write_id_ex,
        ex_result_dest          => ex_result_dest,
        ex_ctrl_wb              => ex_ctrl_wb_out,

        -- outputs
        hazard_stall            => s_hazard_stall_internal
    );

forwarding_unit_inst : forwarding_unit
    port map (
        -- general
        clk                     => clk,
        resetn                  => reset,
        enable                  => enable,

        -- input
        data_reg_1              => data_rs,
        data_reg_2              => data_rt,
        addr_reg_1              => rs(4 downto 0),
        addr_reg_2              => rt(4 downto 0),

        -- forwarding ex mem stage
        ctrl_reg_write_ex_mem   => ctrl_reg_write_ex_mem,
        forward_dest_ex_mem     => forward_dest_ex_mem,
        forward_ex_mem          => forward_ex_mem,

        -- forwarding mem wb stage
        ctrl_reg_write_mem_wb   => ctrl_reg_write_mem_wb,
        forward_dest_mem_wb     => forward_dest_mem_wb,
        forward_mem_wb          => forward_mem_wb,

        -- output
        forwarded_value_1       => s_forwarded_data_1,
        forwarded_value_2       => s_forwarded_data_2,
        forwarded_value_mtc     => s_forwarding_mtc
    );

decoder_unit_inst : decoder_unit
    generic map(
        G_EXC_RESERVED_INSTRUCTION  => G_EXC_RESERVED_INSTRUCTION,
        G_EXC_COP_UNIMPLEMENTED     => G_EXC_COP_UNIMPLEMENTED,
        G_BUSY_LIST_WIDTH           => G_BUSY_LIST_WIDTH
    )
    port map (
        -- inputs
        instruction             => instruction,
        forwarded_value_1       => s_forwarded_data_1,
        forwarded_value_2       => s_forwarded_data_2,
        execute_busy_list       => execute_busy_list,

        -- outputs
        regwrite                => regwrite,
        regdst                  => regdst,
        alu_src                 => s_alu_src,
        memread                 => memread,
        memwrite                => memwrite,
        mem_byte                => mem_byte,
        mem_halfword            => mem_halfword,
        mem_unsigned            => mem_unsigned,
        memtoreg                => memtoreg,
        branch_link             => branch_link,
        iret                    => s_iret,
        sign_extend             => s_sign_extend,
        alu_ctrl                => s_alu_ctrl,
        is_branch_instruction   => s_is_branch_instruction,

        --CP0
        mfc                     => mfc,
        mtc                     => s_mtc,
        -- exceptions
        syscall                 => syscall,
        trap                    => trap,
        reserved_instr          => reserved_instr,
        cop_unimplemented       => cop_unimplemented,
        breakpoint              => breakpoint,

        -- ASIP hazards
        stall                   => s_asip_decode_hazard_stall,

        -- standby mode
        standby                 => standby
    );

-- /*end-folding-block*/

end architecture;
