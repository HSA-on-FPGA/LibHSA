-- coprocessor0_64: Coprocessor0
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
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
entity coprocessor0_64 is
	generic(
        G_START_ADDRESS	            : std_logic_vector(63 downto 0) := x"0000000000000000";
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
        interrupt_syn           : out std_logic;
        mfc_delayed             : out std_logic;
        interrupt_ack           : out std_logic;

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
        standby                 : in std_logic
    );
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of coprocessor0_64 is

--------------------------------------------------------------------------------
-- COMPONENTS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/
signal r_interrupt_syn      : std_logic;
signal r_mtc_delayed        : std_logic;
signal r_mtc_addr_delayed   : std_logic_vector(4 downto 0);
signal r_cop_dw_delayed     : std_logic;

signal is_branch_delay_id   : std_logic;
signal is_branch_delay_ex   : std_logic;
signal is_branch_delay_mem  : std_logic;


alias mtc                       : std_logic is id_ctrl_in(0);
alias mfc                       : std_logic is id_ctrl_in(1);
alias eret                      : std_logic is id_ctrl_in(2);
alias syscall                   : std_logic is id_ctrl_in(3);
alias trap                      : std_logic is id_ctrl_in(4);
alias delay_slot                : std_logic is id_ctrl_in(5);
alias coprocessor_unimpl_exc    : std_logic is id_ctrl_in(6);
alias reserved_instr_exc        : std_logic is id_ctrl_in(7);
alias breakpoint_exc            : std_logic is id_ctrl_in(8);
alias stall_delayed             : std_logic is id_ctrl_in(9);
-- indicate double word mtc and mfc operation
alias cop_dw                    : std_logic is id_ctrl_in(10);

signal badvaddr_reg      : std_logic_vector(63 downto 0); --  8
signal count_reg         : std_logic_vector(31 downto 0); --  9
signal compare_reg       : std_logic_vector(31 downto 0); -- 11
signal status_reg        : std_logic_vector(31 downto 0); -- 12
signal cause_reg         : std_logic_vector(31 downto 0); -- 13
signal s_epc_reg         : std_logic_vector(63 downto 0); -- 14
signal einstr_reg        : std_logic_vector(31 downto 0); -- 22

alias int_enable        : std_logic is status_reg(0);
alias exception_level   : std_logic is status_reg(1);

alias branch_delay      : std_logic is cause_reg(31);
alias exc_code          : std_logic_vector(4 downto 0) is cause_reg(6 downto 2);

alias arith_overflow    : std_logic is alu_flags(2);

constant C_IM0  : integer :=  8;
constant C_IM1  : integer :=  9;
constant C_IM2  : integer := 10;
constant C_IM3  : integer := 11;
constant C_IM4  : integer := 12;
constant C_IM5  : integer := 13;
constant C_IM6  : integer := 14;
constant C_IM7  : integer := 15;

constant C_EXC_INT          : integer :=  0;
constant C_EXC_ADEL         : integer :=  4;
constant C_EXC_ADES         : integer :=  5;
constant C_EXC_IBE          : integer :=  6;
constant C_EXC_DBE          : integer :=  7;
constant C_EXC_SYS          : integer :=  8;
constant C_EXC_BP           : integer :=  9;
constant C_EXC_RI           : integer := 10;
constant C_EXC_CPU          : integer := 11;
constant C_EXC_OV           : integer := 12;
constant C_EXC_TR           : integer := 13;
constant C_EXC_FPE          : integer := 15;

signal pc_decode            : std_logic_vector(63 downto 0);
signal instr_decode         : std_logic_vector(31 downto 0);
signal pc_exec              : std_logic_vector(63 downto 0);
signal instr_exec           : std_logic_vector(31 downto 0);
signal pc_mem               : std_logic_vector(63 downto 0);
signal instr_mem            : std_logic_vector(31 downto 0);
signal pc_wb                : std_logic_vector(63 downto 0);
signal instr_wb             : std_logic_vector(31 downto 0);

-- exception level assignments
constant C_LVL_EXEC_OV      : integer := C_IM2;
constant C_LVL_EXEC_INT     : integer := C_IM6;
constant C_LVL_EXEC_TIMER   : integer := C_IM7;

-- triggered exception
signal triggered_exception  : integer range 8 to 15;

-- exception signals
signal s_address_error_exc_load     : std_logic;
signal s_address_error_exc_fetch    : std_logic;
signal s_address_error_exc_store    : std_logic;
signal s_instruction_bus_exc        : std_logic;
signal s_data_bus_exc               : std_logic;
signal s_syscall                    : std_logic;
signal s_breakpoint_exc             : std_logic;
signal s_reserved_instr_exc         : std_logic;
signal s_coprocessor_unimpl_exc     : std_logic;
signal s_arith_overflow             : std_logic;
signal s_trap                       : std_logic;
signal s_fp_exc                     : std_logic;

signal r_hw_interrupt               : std_logic;

signal s_eret_delayed_1             : std_logic;
signal s_eret_delayed_2             : std_logic;

--signal s_handling_exception         : std_logic;

-- /*end-folding-block*/

begin

--------------------------------------------------------------------------------
-- PORT MAPS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/
epc_reg <= s_epc_reg;

-- enable / disable exception triggering
s_address_error_exc_load <= address_error_exc_load when G_EXC_ADDRESS_ERROR_LOAD = true else '0';
s_address_error_exc_fetch <= address_error_exc_fetch when G_EXC_ADDRESS_ERROR_FETCH = true else '0';
s_address_error_exc_store <= address_error_exc_store when G_EXC_ADDRESS_ERROR_STORE = true else '0';
s_instruction_bus_exc <= instruction_bus_exc when G_EXC_INSTRUCTION_BUS_ERROR = true else '0';
s_data_bus_exc <= data_bus_exc when G_EXC_DATA_BUS_ERROR = true else '0';
s_syscall <= syscall when G_EXC_SYSCALL = true else '0';
s_breakpoint_exc <= breakpoint_exc when G_EXC_BREAKPOINT = true else '0';
s_reserved_instr_exc <= reserved_instr_exc when G_EXC_RESERVED_INSTRUCTION = true else '0';
s_coprocessor_unimpl_exc <= coprocessor_unimpl_exc when G_EXC_COP_UNIMPLEMENTED = true else '0';
s_arith_overflow <= arith_overflow when G_EXC_ARITHMETIC_OVERFLOW = true else '0';
s_trap <= trap when G_EXC_TRAP = true else '0';
s_fp_exc <= fp_exc when G_EXC_FLOATING_POINT = true else '0';

interrupt_syn   <= r_interrupt_syn;

flush_if        <= ((int_enable and not exception_level) and
                    (r_interrupt_syn or
                     s_address_error_exc_load or
                     s_address_error_exc_fetch or
                     s_address_error_exc_store or
                     s_instruction_bus_exc or
                     s_data_bus_exc or
                     s_syscall or
                     s_breakpoint_exc or
                     s_reserved_instr_exc or
                     s_coprocessor_unimpl_exc or
                     s_arith_overflow or
                     s_trap or
                     s_fp_exc)) or
                     (int_enable and r_hw_interrupt);

flush_id        <= ((int_enable and not exception_level) and
                    (r_interrupt_syn or
                     s_address_error_exc_load or
                     s_address_error_exc_store or
                     s_data_bus_exc or
                     s_syscall or
                     s_breakpoint_exc or
                     s_reserved_instr_exc or
                     s_coprocessor_unimpl_exc or
                     s_arith_overflow or
                     s_trap or
                     s_fp_exc)) or
                     (int_enable and r_hw_interrupt);

-- for xilinx interrupt controller
--interrupt_ack   <=   "01" when r_interrupt_syn='1'
--                else "10" when eret='1'
--                else "11" when int_enable='1'
--                else "00";
with eret select
    interrupt_ack <= '1' when '1',
                     '0' when others;

instr_decode        <= instruction_in;
-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

-- eret takes two cycles to complete
-- and one extra cycle, until instruction decode is filled with correct data
-- this is necessary for pending interrupts
delay_eret : process(clk, reset)
begin
    if (reset = '0') then
        s_eret_delayed_1 <= '0';
        s_eret_delayed_2 <= '0';
    elsif (clk'event and clk = '1') then
        s_eret_delayed_1 <= eret;
        s_eret_delayed_2 <= s_eret_delayed_1;
    end if;
end process delay_eret;

delay_pc_in : process(clk, reset)
begin
    if (reset = '0') then
        pc_decode       <= G_START_ADDRESS;
        pc_exec         <= G_START_ADDRESS;
        pc_mem          <= G_START_ADDRESS;
        pc_wb           <= G_START_ADDRESS;
        instr_exec      <= (others => '0');
        instr_mem       <= (others => '0');
        instr_wb        <= (others => '0');
    elsif (clk'event and clk = '1') then
        if (enable_id = '1') then
            pc_decode       <= pc_in;
        end if;
        if (enable_ex = '1') then
            pc_exec     <= pc_decode;
            instr_exec  <= instr_decode;
        end if;
        if (enable_mem = '1') then
            pc_mem      <= pc_exec;
            instr_mem   <= instr_exec;
        end if;
        if (enable_wb = '1') then
            pc_wb       <= pc_mem;
            instr_wb    <= instr_mem;
        end if;
        if (s_eret_delayed_2 = '1') then
            pc_exec     <= s_epc_reg;
            pc_mem      <= s_epc_reg;
            pc_wb       <= s_epc_reg;
        end if;
    end if;
end process delay_pc_in;

branch_delay_proc : process (clk, reset)
begin
    if (reset = '0') then
        is_branch_delay_id  <= '0';
        is_branch_delay_ex  <= '0';
        is_branch_delay_mem <= '0';
    elsif (clk'event and clk = '1') then
        if(enable = '1') then
            is_branch_delay_id  <= delay_slot;
            is_branch_delay_ex  <= is_branch_delay_id;
            is_branch_delay_mem <= is_branch_delay_ex;
        end if;
    end if;
end process branch_delay_proc;

coprocessor0_register_access: process(clk, reset)
begin
    if (reset = '0') then
        data_out <= (others => '1');
    elsif (rising_edge(clk)) then
        if (enable = '1' and mfc = '1') then
            -- TODO
            -- use sel information where necessary
            case addr_in is
                when "01000" =>
                    if (cop_dw = '1') then
                        data_out <= badvaddr_reg;
                    end if;
                when "01001" =>
                    if (cop_dw = '0') then
                        data_out <= std_logic_vector(resize(signed(count_reg), 64));
                    end if;
                when "01011" =>
                    if (cop_dw = '0') then
                        data_out <= std_logic_vector(resize(signed(compare_reg), 64));
                    end if;
                when "01100" =>
                    if (cop_dw = '0') then
                        data_out <= std_logic_vector(resize(signed(status_reg), 64));
                    end if;
                when "01101"=>
                    if (cop_dw = '0') then
                        data_out <= std_logic_vector(resize(signed(cause_reg), 64));
                    end if;
                when "01110" =>
                    if (cop_dw = '1') then
                        data_out <= s_epc_reg;
                    end if;
                when "10110" =>
                    if (cop_dw = '0') then
                        data_out <= std_logic_vector(resize(signed(einstr_reg), 64));
                    end if;
                when others =>
                    data_out <= (others => '0');
            end case;
        end if;
    end if;
end process coprocessor0_register_access;

interrupt_synchronisation: process(clk, reset)
begin
    if (reset = '0') then
        badvaddr_reg            <= (others => '0');
        count_reg               <= (others => '0');
        compare_reg             <= (others => '0');
        status_reg              <= (others => '0');
        cause_reg               <= (others => '0');
        s_epc_reg               <= (others => '0');
        einstr_reg              <= (others => '0');
        r_interrupt_syn         <= '0';
        mfc_delayed             <= '0';
        r_mtc_delayed           <= '0';
        r_cop_dw_delayed        <= '0';
        r_mtc_addr_delayed      <= (others => '0');
        triggered_exception     <= 8;
        r_hw_interrupt          <= '0';
        --s_handling_exception    <= '0';
    elsif (rising_edge(clk)) then
        if (enable = '1') then
            r_interrupt_syn             <= '0';
            mfc_delayed                 <= mfc;
            r_mtc_delayed               <= mtc;
            r_mtc_addr_delayed          <= addr_in;
            r_cop_dw_delayed            <= cop_dw;
            r_hw_interrupt              <= '0';


            if (r_mtc_delayed = '1') then
                -- Clear timer interrupt in status register if compare value is set
                if (r_mtc_addr_delayed = "01011") then
                    status_reg(C_LVL_EXEC_TIMER) <= '0';
                end if;
                -- TODO
                -- make use of sel flag
                case r_mtc_addr_delayed is
                    when "01000" =>
                        if (r_cop_dw_delayed = '1') then
                            badvaddr_reg <= data_in;
                        end if;
                    when "01001" =>
                        if (r_cop_dw_delayed = '0') then
                            count_reg <= data_in(31 downto 0);
                        end if;
                    when "01011" =>
                        if (r_cop_dw_delayed = '0') then
                            compare_reg <= data_in(31 downto 0);
                        end if;
                    when "01100" =>
                        if (r_cop_dw_delayed = '0') then
                            status_reg <= data_in(31 downto 0);
                        end if;
                    when "01101"=>
                        if (r_cop_dw_delayed = '0') then
                            cause_reg <= data_in(31 downto 0);
                        end if;
                    when "01110" =>
                        if (r_cop_dw_delayed = '1') then
                            s_epc_reg <= data_in;
                        end if;
                    when "10110" =>
                        if (r_cop_dw_delayed = '0') then
                            einstr_reg <= data_in(31 downto 0);
                        end if;
                    when others =>
                        -- do nothing
                end case;
            end if;

            if (s_eret_delayed_2 = '1') then
                -- leave exception mode
                exception_level                 <= '0';
                --if (s_handling_exception = '0') then
                    -- remove interrupt pending signal for processed interrupt
                    cause_reg(triggered_exception)  <= '0';
                --else
                --    s_handling_exception <= '1';
                --end if;
                -- reset exception code
                exc_code        <= (others=>'0');
            end if;

            -- exceptions are sorted in respect to their priority. The further
            -- back they appear in the pipeline, the higher their pirority.

            -- in case an interrupt and an exception occur at the same time, the
            -- exception has the higher priority. The interrupt is being

            -- HW Interrupts
            loop_hw_interrupts : for i in 0 to G_NUM_HW_INTERRUPTS-1 loop

                if (i /= 0 or G_TIMER_INTERRUPT = false) then
                    -- always signal pending interrupt
                    if (interrupt(5 - i)='1') then
                        cause_reg(15 - i)    <= '1';
                    end if;
                    -- either:
                    -- hw interrupt level i is enabled and a level i hw interrupt occurs
                    -- or:
                    -- pending level i hw interrupt
                    if ((interrupt(5 - i)='1' or cause_reg(15 - i)='1') and status_reg(15 - i)='1' and int_enable='1' and exception_level='0') then
                        r_interrupt_syn     <= '1';
                        exception_level     <= '1';
                        r_hw_interrupt      <= '1';
                        branch_delay        <= is_branch_delay_id;
                        cause_reg(15 - i)   <= '1';
                        triggered_exception <= 15 - i;
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_INT,5));
                    end if;
                end if;

                if (i = 0 and G_TIMER_INTERRUPT = true) then
                    -- Hardware Interrupt 5
                    -- Timer

                    -- always signal pending interrupt
                    if (count_reg = compare_reg) then
                        cause_reg(15 - i)   <= '1';
                    end if;

                    -- either:
                    -- hw interrupt level 5 is enabled and a level 5 interrupt occurs
                    -- or:
                    -- pending level 5 interrupt
                    if ((count_reg = compare_reg or cause_reg(15) = '1') and status_reg(15)='1' and int_enable='1' and exception_level='0') then
                        r_interrupt_syn     <= '1';
                        exception_level     <= '1';
                        r_hw_interrupt      <= '1';
                        branch_delay        <= is_branch_delay_id;
                        cause_reg(15)   <= '1';
                        triggered_exception <= 15;
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_INT,5));
                    end if;
                    count_reg <= std_logic_vector(unsigned(count_reg) + 1);
                end if;

            end loop loop_hw_interrupts;

            if (r_interrupt_syn = '1') then
                if (is_branch_delay_id = '1') then
                    s_epc_reg       <= pc_exec;
                    einstr_reg      <= instr_exec;
                elsif (standby = '1') then
                    -- skip wait instruction
                    s_epc_reg       <= pc_in;
                    -- instruction at pc_in not available, therefore put
                    -- instr_decode (= wait) into the register
                    einstr_reg      <= instr_decode;
                else
                    s_epc_reg       <= pc_decode;
                    einstr_reg      <= instr_decode;
                end if;
            end if;

            -- exceptions
            -- sorted for priority, the farther back the exception happens in
            -- the pipeline, the higher its priority

            if (int_enable = '1' and exception_level = '0') then

                -- instruction fetch

                if (G_EXC_ADDRESS_ERROR_FETCH = true) then
                    -- address error on instruction fetch, should arrive
                    -- in the same cycle, as the memory access was issued
                    --
                    -- if the memory cannot hold this timing requirement, the
                    -- core has to be disabled until the memory has determined, if
                    -- an exception occured
                    if (address_error_exc_fetch = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_ADEL,5));
                        branch_delay        <= delay_slot;
                        badvaddr_reg        <= pc_in;
                        --s_handling_exception<= '1';
                        --if (delay_slot = '1' or stall_delayed = '1') then
                        if (delay_slot = '1' or enable_id = '0') then
                            -- store the pc value of the branch instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the fetch phase
                            s_epc_reg       <= pc_in;
                            einstr_reg      <= instruction_in;
                        end if;
                    end if;
                end if;

                if (G_EXC_INSTRUCTION_BUS_ERROR = true) then
                    -- instruction bus error on instruction fetch, should arrive
                    -- in the same cycle, as the memory access was issued
                    --
                    -- if the memory cannot hold this timing requirement, the
                    -- core has to be disabled until the memory has determined, if
                    -- an exception occured
                    if (instruction_bus_exc = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_IBE,5));
                        branch_delay        <= delay_slot;
                        badvaddr_reg        <= pc_in;
                        --s_handling_exception<= '1';
                        --if (delay_slot = '1' or stall_delayed = '1') then
                        if (delay_slot = '1' or enable_id = '0') then
                            -- store the pc value of the branch instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the fetch phase
                            s_epc_reg       <= pc_in;
                            einstr_reg      <= instruction_in;
                        end if;
                    end if;
                end if;

                -- instruction decode

                if (G_EXC_BREAKPOINT = true) then
                    if (breakpoint_exc = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_BP,5));
                        branch_delay        <= delay_slot;
                        --s_handling_exception<= '1';
                        --if (delay_slot = '1' or stall_delayed = '1') then
                        if (delay_slot = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_exec;
                            einstr_reg      <= instr_exec;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the fetch phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        end if;
                    end if;
                end if;

                if (G_EXC_FLOATING_POINT = true) then
                    if (fp_exc = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_FPE,5));
                        branch_delay        <= is_branch_delay_id;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_id = '1' or stall_delayed = '1') then
                        if (is_branch_delay_id = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the execute phase
                            s_epc_reg       <= pc_exec;
                            einstr_reg      <= instr_exec;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        end if;
                    end if;
                end if;

                if (G_EXC_SYSCALL = true) then
                    if (syscall = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_SYS,5));
                        branch_delay        <= is_branch_delay_id;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_id = '1' or stall_delayed = '1') then
                        if (is_branch_delay_id = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the execute phase
                            s_epc_reg       <= pc_exec;
                            einstr_reg      <= instr_exec;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        end if;
                    end if;
                end if;

                if (G_EXC_RESERVED_INSTRUCTION = true) then
                    if (reserved_instr_exc = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_RI,5));
                        branch_delay        <= is_branch_delay_id;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_id = '1' or stall_delayed = '1') then
                        if (is_branch_delay_id = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the execute phase
                            s_epc_reg       <= pc_in;
                            einstr_reg      <= instr_decode;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        end if;
                    end if;
                end if;

                if (G_EXC_COP_UNIMPLEMENTED = true) then
                    if (coprocessor_unimpl_exc = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_CPU,5));
                        branch_delay        <= is_branch_delay_id;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_id = '1' or stall_delayed = '1') then
                        if (is_branch_delay_id = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the execute phase
                            s_epc_reg       <= pc_exec;
                            einstr_reg      <= instr_exec;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        end if;
                    end if;
                end if;

                if (G_EXC_TRAP = true) then
                    if (trap = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_TR,5));
                        branch_delay        <= is_branch_delay_id;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_id = '1' or stall_delayed = '1') then
                        if (is_branch_delay_id = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the execute phase
                            s_epc_reg       <= pc_exec;
                            einstr_reg      <= instr_exec;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the decode phase
                            s_epc_reg       <= pc_decode;
                            einstr_reg      <= instr_decode;
                        end if;
                    end if;
                end if;


                -- execute

                if (G_EXC_ARITHMETIC_OVERFLOW = true) then
                    if (arith_overflow = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_OV ,5));
                        branch_delay        <= is_branch_delay_ex;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_ex = '1' or stall_delayed = '1') then
                        if (is_branch_delay_ex = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the mem phase
                            s_epc_reg       <= pc_mem;
                            einstr_reg      <= instr_mem;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the execute phase
                            s_epc_reg       <= pc_exec;
                            einstr_reg      <= instr_exec;
                        end if;
                    end if;
                end if;

                -- data memory

                if (G_EXC_ADDRESS_ERROR_LOAD = true) then
                    if (address_error_exc_load = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_ADEL ,5));
                        branch_delay        <= is_branch_delay_mem;
                        badvaddr_reg        <= data_addr;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_mem = '1' or stall_delayed = '1') then
                        if (is_branch_delay_mem = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the wb phase
                            s_epc_reg       <= pc_wb;
                            einstr_reg      <= instr_wb;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the mem phase
                            s_epc_reg       <= pc_mem;
                            einstr_reg      <= instr_mem;
                        end if;
                    end if;
                end if;

                if (G_EXC_ADDRESS_ERROR_STORE = true) then
                    if (address_error_exc_store = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_ADES ,5));
                        branch_delay        <= is_branch_delay_mem;
                        badvaddr_reg        <= data_addr;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_mem = '1' or stall_delayed = '1') then
                        if (is_branch_delay_mem = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the wb phase
                            s_epc_reg       <= pc_wb;
                            einstr_reg      <= instr_wb;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the mem phase
                            s_epc_reg       <= pc_mem;
                            einstr_reg      <= instr_mem;
                        end if;
                    end if;
                end if;

                if (G_EXC_DATA_BUS_ERROR = true) then
                    if (data_bus_exc = '1') then
                        exception_level     <= '1';
                        r_interrupt_syn     <= '0';
                        exc_code            <= std_logic_vector(to_unsigned(C_EXC_DBE ,5));
                        branch_delay        <= is_branch_delay_mem;
                        badvaddr_reg        <= data_addr;
                        --s_handling_exception<= '1';
                        --if (is_branch_delay_mem = '1' or stall_delayed = '1') then
                        if (is_branch_delay_mem = '1') then
                            -- store the pc value of the branch instruction
                            -- which is now in the wb phase
                            s_epc_reg       <= pc_wb;
                            einstr_reg      <= instr_wb;
                        else
                            -- store the pc value of the interrupted instruction
                            -- which is now in the mem phase
                            s_epc_reg       <= pc_mem;
                            einstr_reg      <= instr_mem;
                        end if;
                    end if;
                end if;

            end if;

        end if;
    end if;
end process interrupt_synchronisation;
-- /*end-folding-block*/

end architecture;

