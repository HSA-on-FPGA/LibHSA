-- branching_unit_64: Branching unit
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branching_unit_64 is
    port (
        -- general
        clk                     : in  std_logic;
        resetn                  : in  std_logic;
        enable                  : in  std_logic;
        hazard_stall            : in  std_logic;

        -- instruction data
        instruction             : in  std_logic_vector(31 downto 0);
        immediate               : in  std_logic_vector(63 downto 0);
        mtc                     : in  std_logic;

        -- input address signals
        pc                      : in  std_logic_vector(63 downto 0);
        forwarding_mtc          : in  std_logic_vector(63 downto 0);
        epc                     : in  std_logic_vector(63 downto 0);

        -- eval branch condition
        data_reg_1              : in  std_logic_vector(63 downto 0);
        data_reg_2              : in  std_logic_vector(63 downto 0);
        addr_reg_1              : in  std_logic_vector( 4 downto 0);
        addr_reg_2              : in  std_logic_vector( 4 downto 0);
        forward_dest_ex_mem     : in  std_logic_vector( 4 downto 0);
        ctrl_reg_write_ex_mem   : in  std_logic;
        forward_ex_mem          : in  std_logic_vector(63 downto 0);
        forward_dest_mem_wb     : in  std_logic_vector( 4 downto 0);
        ctrl_reg_write_mem_wb   : in  std_logic;
        forward_mem_wb          : in  std_logic_vector(63 downto 0);

        -- interrupt
        syn_interrupt           : in  std_logic;

        -- outputs
        pc_branch               : out std_logic_vector(63 downto 0);
        take_branch             : out std_logic
    );
end entity branching_unit_64;

architecture behavior of branching_unit_64 is

    -- instruction type
    signal s_branch             : std_logic;
    signal s_rel_jump           : std_logic;
    signal s_jump               : std_logic;
    signal s_iret               : std_logic;

    -- instruction data
    signal reg_instruction      : std_logic_vector(31 downto 0);
    signal reg_immediate        : std_logic_vector(63 downto 0);
    signal reg_mtc              : std_logic;

    -- input address signals
    signal reg_pc               : std_logic_vector(63 downto 0);
    signal reg_forwarding_mtc   : std_logic_vector(63 downto 0);
    signal reg_epc              : std_logic_vector(63 downto 0);

    -- eval branch condition
    signal reg_data_reg_1       : std_logic_vector(63 downto 0);
    signal reg_data_reg_2       : std_logic_vector(63 downto 0);
    signal reg_addr_reg_1       : std_logic_vector( 4 downto 0);
    signal reg_addr_reg_2       : std_logic_vector( 4 downto 0);

    signal s_compare_data_1     : std_logic_vector(63 downto 0);
    signal s_compare_data_2     : std_logic_vector(63 downto 0);

    signal s_eval_zero          : std_logic;
    signal s_eval_sign          : std_logic;

    signal reg_opcode           : std_logic_vector( 7 downto 0);
    alias reg_funct             : std_logic_vector( 5 downto 0) is reg_instruction(5 downto 0);

    signal reg_cp0_addr_delayed : std_logic_vector( 4 downto 0);

    signal reg_syn_interrupt    : std_logic;

begin

    reg_opcode      <=  "00"  & reg_instruction(31 downto 26);
    -- do not execute pending jump when an interrupt occured
    take_branch     <= ((not reg_syn_interrupt) and (s_branch or s_rel_jump or s_jump or s_iret)) when (hazard_stall = '0')
                            else '0';

    proc_instr_type :
        process (
            reg_opcode, s_eval_zero, s_eval_sign, reg_funct, reg_addr_reg_1,
            reg_addr_reg_2, reg_instruction
        )

        variable v_reg_addr_reg_1 : std_logic_vector(7 downto 0);
        variable v_reg_addr_reg_2 : std_logic_vector(7 downto 0);

        begin

            v_reg_addr_reg_1 := "000" & reg_addr_reg_1;
            v_reg_addr_reg_2 := "000" & reg_addr_reg_2;

            s_jump      <= '0';
            s_branch    <= '0';
            s_rel_jump  <= '0';
            s_iret      <= '0';

            case reg_opcode is
                when x"00" =>       -- R Type
                    case (reg_funct) is
                        when "001000" =>    -- jump register
                            s_rel_jump  <= '1';

                        when "001001" =>    -- jump and link register
                            s_rel_jump  <= '1';

                        when others =>
                            -- dummy
                    end case;

                when x"01" =>       -- extended opcodes
                    case (v_reg_addr_reg_2) is
                        when x"00" =>       -- branch less than zero
                            if (s_eval_sign = '1') then
                                s_branch <= '1';
                            end if;

                        when x"01" =>       -- branch greater equal zero
                            if (s_eval_zero = '1' or s_eval_sign = '0') then
                                s_branch <= '1';
                            end if;

                        when x"10" =>       -- branch less than zero and link
                            if (s_eval_sign = '1') then
                                s_branch <= '1';
                            end if;

                        when x"11" =>       -- branch greater equal zero and link
                            if (s_eval_zero = '1' or s_eval_sign = '0') then
                                s_branch <= '1';
                            end if;

                        when others =>
                            -- dummy

                    end case;

                when x"02" =>       -- jump
                    s_jump      <= '1';

                when x"03" =>       -- jump and link
                    s_jump      <= '1';

                when x"04" =>       -- branch equal
                    if (s_eval_zero = '1') then
                        s_branch    <= '1';
                    end if;

                when x"05" =>       -- branch not equal
                    if (s_eval_zero = '0') then
                        s_branch    <= '1';
                    end if;

                when x"06" =>       -- branch less equal zero
                    if (s_eval_zero = '1' or s_eval_sign = '1') then
                        s_branch    <= '1';
                    end if;

                when x"07" =>       -- branch greater than zero
                    if (s_eval_sign = '0') then
                        s_branch    <= '1';
                    end if;

                when x"10" =>       -- Coprocessor 0
                    case (v_reg_addr_reg_1) is
                        when x"10" =>
                            if (reg_instruction=x"42000018" ) then  -- eret
                                s_iret      <= '1';
                            end if;

                        when others =>
                            -- dummy
                    end case;

                when others =>
                    -- dummy

            end case;
        end process proc_instr_type;

    proc_reg :
        process (
            clk, resetn
        )

        begin

            if (resetn = '0') then

                -- instruction data
                reg_instruction             <= (others => '0');
                reg_immediate               <= (others => '0');
                reg_mtc                     <= '0';

                -- input address signals
                reg_pc                      <= (others => '0');
                reg_forwarding_mtc          <= (others => '0');
                reg_epc                     <= (others => '0');

                -- eval branch condition
                reg_data_reg_1              <= (others => '0');
                reg_data_reg_2              <= (others => '0');
                reg_addr_reg_1              <= (others => '0');
                reg_addr_reg_2              <= (others => '0');

                reg_cp0_addr_delayed        <= (others => '0');

                -- interrupt
                reg_syn_interrupt           <= '0';

            elsif (clk'event and clk = '1') then

                if (enable = '1' and hazard_stall = '0') then

                    -- instruction data
                    reg_instruction             <= instruction;
                    reg_immediate               <= immediate;
                    reg_mtc                     <= mtc;

                    -- input address signals
                    reg_pc                      <= pc;
                    reg_forwarding_mtc          <= forwarding_mtc;
                    reg_epc                     <= epc;

                    -- eval branch condition
                    reg_data_reg_1              <= data_reg_1;
                    reg_data_reg_2              <= data_reg_2;
                    reg_addr_reg_1              <= addr_reg_1;
                    reg_addr_reg_2              <= addr_reg_2;

                    reg_cp0_addr_delayed        <= instruction(15 downto 11);

                    -- interrupt
                    reg_syn_interrupt           <= syn_interrupt;

                end if;

            end if;

        end process proc_reg;


    proc_pc_branch :
        process (
            reg_pc, reg_immediate(61 downto 0), s_compare_data_1, s_branch,
            s_rel_jump, s_iret, reg_instruction(25 downto 0),
            reg_cp0_addr_delayed, reg_forwarding_mtc, reg_mtc, reg_epc
        )

        variable v_branch_offset : std_logic_vector(63 downto 0);

        begin
            v_branch_offset := (reg_immediate(61 downto 0) & "00");
            if (s_branch = '1') then
                pc_branch       <= std_logic_vector(signed(reg_pc) + signed(v_branch_offset));
            elsif (s_rel_jump = '1') then
                pc_branch       <= s_compare_data_1;
            elsif (s_iret = '1') then
                if (reg_cp0_addr_delayed = "01110" and reg_mtc = '1') then
                    pc_branch   <= reg_forwarding_mtc;
                else
                    pc_branch   <= reg_epc;
                end if;
            else
                pc_branch       <= reg_pc(63 downto 28) & reg_instruction(25 downto 0) & "00";
            end if;
        end process proc_pc_branch;

    proc_forwarding :
        process(
            reg_addr_reg_1, reg_addr_reg_2, ctrl_reg_write_mem_wb,
            ctrl_reg_write_ex_mem, forward_dest_mem_wb, forward_dest_ex_mem,
            forward_mem_wb, forward_ex_mem, reg_data_reg_1, reg_data_reg_2
        )
        begin

            --forwardA=00
            s_compare_data_1    <= reg_data_reg_1;
            --forwardB=00
            s_compare_data_2    <= reg_data_reg_2;

            -- forward mem/wb stage
            if (
                ctrl_reg_write_mem_wb = '1' and forward_dest_mem_wb /= "00000"
                and reg_addr_reg_1(4 downto 0) = forward_dest_mem_wb
            ) then
                --forwardA=01
                s_compare_data_1    <= forward_mem_wb;
            end if;

            if (
                ctrl_reg_write_mem_wb = '1' and forward_dest_mem_wb /= "00000"
                and reg_addr_reg_2(4 downto 0) = forward_dest_mem_wb
            ) then
                --forwardB=01
                s_compare_data_2    <= forward_mem_wb;
            end if;

            -- forward ex/mem stage
            if (
                ctrl_reg_write_ex_mem = '1' and forward_dest_ex_mem /= "00000"
                and reg_addr_reg_1(4 downto 0) = forward_dest_ex_mem
            ) then
                --forwardA=10
                s_compare_data_1    <= forward_ex_mem;
            end if;

            if (
                ctrl_reg_write_ex_mem = '1' and forward_dest_ex_mem /= "00000"
                and reg_addr_reg_2(4 downto 0) = forward_dest_ex_mem
            ) then
                --forwardB=10
                s_compare_data_2    <= forward_ex_mem;
            end if;

        end process proc_forwarding;

    proc_eval :
        process(
            s_compare_data_1,s_compare_data_2
        )
        begin

            s_eval_zero <= '0';
            s_eval_sign <= '0';

            if (s_compare_data_1 = s_compare_data_2) then
                s_eval_zero <= '1';
            end if;

            if (s_compare_data_1(63)='1') then
                s_eval_sign <= '1';
            end if;

        end process proc_eval;

end architecture behavior;
