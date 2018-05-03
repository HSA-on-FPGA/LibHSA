-- forwarding_unit: Forwarding unit for mips pipeline
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

entity forwarding_unit is
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
end entity forwarding_unit;

architecture behavior of forwarding_unit is

    signal reg_data_reg_2       : std_logic_vector (31 downto 0);
    signal reg_addr_reg_2       : std_logic_vector ( 4 downto 0);

begin

    proc_reg :
        process (
            clk, resetn
        )
        begin
            if (resetn = '0') then
                reg_data_reg_2 <= (others => '0');
                reg_addr_reg_2 <= (others => '0');
            elsif (clk'event and clk = '1') then
                if (enable = '1') then
                    reg_data_reg_2 <= data_reg_2;
                    reg_addr_reg_2 <= addr_reg_2;
                end if;
            end if;
        end process proc_reg;

    proc_forwarding :
        process (
            data_reg_1, data_reg_2, ctrl_reg_write_mem_wb, forward_dest_mem_wb,
            addr_reg_1, addr_reg_2, forward_mem_wb, ctrl_reg_write_ex_mem,
            forward_dest_ex_mem, forward_ex_mem
        )
        begin

            --forwardA=00
            forwarded_value_1    <= data_reg_1;
            --forwardB=00
            forwarded_value_2    <= data_reg_2;

            -- forward mem/wb stage
            if (
                ctrl_reg_write_mem_wb = '1' and forward_dest_mem_wb /= "00000" and addr_reg_1 = forward_dest_mem_wb
            ) then
                --forwardA=01
                forwarded_value_1    <= forward_mem_wb;
            end if;
            if (
                ctrl_reg_write_mem_wb = '1' and forward_dest_mem_wb /= "00000" and addr_reg_2 = forward_dest_mem_wb
            ) then
                --forwardB=01
                forwarded_value_2    <= forward_mem_wb;
            end if;

            -- forward ex/mem stage
            if (
                ctrl_reg_write_ex_mem = '1' and forward_dest_ex_mem /= "00000" and addr_reg_1 = forward_dest_ex_mem
            ) then
                --forwardA=10
                forwarded_value_1    <= forward_ex_mem;
            end if;
            if (
                ctrl_reg_write_ex_mem = '1' and forward_dest_ex_mem /= "00000" and addr_reg_2 = forward_dest_ex_mem
            ) then
                --forwardB=10
                forwarded_value_2    <= forward_ex_mem;
            end if;

        end process proc_forwarding;

    proc_forwarding_mtc :
        process (
            reg_data_reg_2, ctrl_reg_write_mem_wb, forward_dest_mem_wb,
            reg_addr_reg_2, forward_mem_wb, ctrl_reg_write_ex_mem,
            forward_dest_ex_mem, forward_ex_mem
        )
        begin

            --forwardB=00
            forwarded_value_mtc    <= reg_data_reg_2;

            -- forward mem/wb stage
            if (
                ctrl_reg_write_mem_wb = '1' and forward_dest_mem_wb /= "00000" and reg_addr_reg_2 = forward_dest_mem_wb
            ) then
                --forwardB=01
                forwarded_value_mtc    <= forward_mem_wb;
            end if;

            -- forward ex/mem stage
            if (
                ctrl_reg_write_ex_mem = '1' and forward_dest_ex_mem /= "00000" and reg_addr_reg_2 = forward_dest_ex_mem
            ) then
                --forwardB=10
                forwarded_value_mtc    <= forward_ex_mem;
            end if;

        end process proc_forwarding_mtc;

end architecture behavior;
