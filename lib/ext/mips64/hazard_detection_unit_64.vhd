-- hazard_detection_unit_64: Hazard detection unit for mips pipeline
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

entity hazard_detection_unit_64 is
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
end entity hazard_detection_unit_64;

architecture behavior of hazard_detection_unit_64 is

    signal reg_opcode           : std_logic_vector( 5 downto 0);

begin

proc_reg_opcode :
    process (
        clk, resetn
    )
    begin
        if (resetn = '0') then
            reg_opcode      <= (others=>'0');
        elsif (clk'event and clk = '1') then
            if (syn_interrupt = '1') then
                reg_opcode  <= (others=>'0');
            end if;
            if (enable = '1') then
                reg_opcode  <= opcode;
            end if;
        end if;
    end process proc_reg_opcode;

proc_hazard_detection :
    process (
        opcode, funct, rs, rt, hazard_rt_id_ex, ctrl_reg_write_id_ex,
        ex_result_dest, ex_ctrl_wb, reg_opcode
    )

        variable v_idsrc_is_exdst       : std_logic;
        variable v_load_instr_delayed   : std_logic;
        variable v_opcode               : std_logic_vector(7 downto 0);
        variable v_reg_opcode           : std_logic_vector(7 downto 0);

    begin

        v_idsrc_is_exdst    := '0';
        v_opcode            := "00" & opcode;
        v_reg_opcode        := "00" & reg_opcode;

        hazard_stall      <= '0';

        if (
            -- any load instruction
            v_reg_opcode = x"20" or v_reg_opcode = x"21" or
            v_reg_opcode = x"23" or v_reg_opcode = x"24" or
            v_reg_opcode = x"25" or v_reg_opcode = x"27" or
            v_reg_opcode = x"37"
        ) then
                v_load_instr_delayed := '1';
        else
                v_load_instr_delayed := '0';
        end if;

        if ((hazard_rt_id_ex  = rs) or (hazard_rt_id_ex  = rt)) then
            v_idsrc_is_exdst  := '1';
        end if;


        if  (
            -- teq / tne accessing the register in which the current instruction in the
            -- execute phase will write back
            (
                ex_result_dest /= "00000" and
                (ex_result_dest = rs(4 downto 0) or ex_result_dest = rt(4 downto 0)) and
                ex_ctrl_wb(1) = '1' and v_opcode = x"00" and
                (funct = "110100" or funct = "110110")
            )
            -- any instruction depends on a directly preceding load instruction
            or (v_load_instr_delayed = '1' and ctrl_reg_write_id_ex='1' and v_idsrc_is_exdst='1')
        ) then
                hazard_stall  <= '1';
        end if;

    end process proc_hazard_detection;

end architecture behavior;
