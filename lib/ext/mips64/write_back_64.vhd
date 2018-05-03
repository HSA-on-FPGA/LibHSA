-- write_back_64: Write back unit mips pipeline
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
entity write_back_64 is
	port(
		-- data path
		alu_result			: in  std_logic_vector(63 downto 0);
		memory_data			: in  std_logic_vector(63 downto 0);
		write_data			: out std_logic_vector(63 downto 0);

		-- control path
        ctrl_mem_in         : in  std_logic_vector( 8 downto 0);

		ctrl_wb				: in  std_logic
	);
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of write_back_64 is

    alias mem_read                  : std_logic is ctrl_mem_in(1);
    alias mem_write                 : std_logic is ctrl_mem_in(0);
    alias mem_byte                  : std_logic is ctrl_mem_in(2);
    alias mem_halfword              : std_logic is ctrl_mem_in(3);
    alias mem_word                  : std_logic is ctrl_mem_in(4);
    alias mem_unsigned              : std_logic is ctrl_mem_in(5);
    alias mem_byte_access_offset    : std_logic_vector(2 downto 0) is ctrl_mem_in(8 downto 6);

    signal s_memory_data            : std_logic_vector(63 downto 0);

begin


--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    unaligned_read: process(mem_read, mem_byte, mem_halfword, mem_unsigned, mem_byte_access_offset, memory_data)
        variable loaded_byte        : std_logic_vector( 7 downto 0);
        variable loaded_halfword    : std_logic_vector(15 downto 0);
        variable loaded_word        : std_logic_vector(31 downto 0);
    begin
        if (mem_read = '1') then
            -- load byte
            if (mem_byte = '1') then
                case mem_byte_access_offset is
                    when "000" =>
                        loaded_byte := memory_data(7 downto 0);
                    when "001" =>
                        loaded_byte := memory_data(15 downto 8);
                    when "010" =>
                        loaded_byte := memory_data(23 downto 16);
                    when "011" =>
                        loaded_byte := memory_data(31 downto 24);
                    when "100" =>
                        loaded_byte := memory_data(39 downto 32);
                    when "101" =>
                        loaded_byte := memory_data(47 downto 40);
                    when "110" =>
                        loaded_byte := memory_data(55 downto 48);
                    when "111" =>
                        loaded_byte := memory_data(63 downto 56);
                    when others =>
                        -- dummy
                        loaded_byte := memory_data(7 downto 0);
                end case;
                -- unsigned, no sign extend
                if (mem_unsigned = '1') then
                    s_memory_data(63 downto 8) <= (others => '0');
                    s_memory_data(7 downto 0) <= loaded_byte;
                -- signed, sign extend
                else
                    s_memory_data(63 downto 8) <= (others => loaded_byte(7));
                    s_memory_data(7 downto 0) <= loaded_byte;
                end if;
            -- load halfword (unsigned)
            elsif (mem_halfword = '1') then
                case mem_byte_access_offset is
                    when "000" =>
                        loaded_halfword := memory_data(15 downto 0);
                    when "010" =>
                        loaded_halfword := memory_data(31 downto 16);
                    when "100" =>
                        loaded_halfword := memory_data(47 downto 32);
                    when "110" =>
                        loaded_halfword := memory_data(63 downto 48);
                    when others =>
                        -- do nothing
                        -- exception should have been signaled in memory_access
                        -- dummy
                        loaded_halfword := memory_data(15 downto 0);
                end case;
                -- unsigned, no sign extend
                if (mem_unsigned = '1') then
                    s_memory_data(63 downto 16) <= (others => '0');
                    s_memory_data(15 downto  0) <= loaded_halfword;
                -- signed, sign extend
                else
                    s_memory_data(63 downto 32) <= (others => '0');
                    s_memory_data(31 downto 16) <= (others => loaded_halfword(15));
                    s_memory_data(15 downto  0) <= loaded_halfword;
                end if;
            -- load word
            elsif (mem_word = '1') then
                case mem_byte_access_offset is
                    when "000" =>
                        loaded_word := memory_data(31 downto 0);
                    when "100" =>
                        loaded_word := memory_data(63 downto 32);
                    when others =>
                        -- do nothing
                        -- exception should have been signaled in memory_access
                        -- dummy
                        loaded_word := memory_data(31 downto 0);
                end case;
                -- unsigned, no sign extend
                if (mem_unsigned = '1') then
                    s_memory_data(63 downto 32) <= (others => '0');
                    s_memory_data(31 downto  0) <= loaded_word;
                -- signed, sign extend
                else
                    s_memory_data(63 downto 32) <= (others => loaded_word(31));
                    s_memory_data(31 downto  0) <= loaded_word;
                end if;
            -- load doubleword
            else
                s_memory_data <= memory_data;
            end if;
        else
            s_memory_data <= memory_data;
        end if;
    end process unaligned_read;

    write_data	<= s_memory_data when ctrl_wb = '1'
                    else alu_result;

-- /*end-folding-block*/


end architecture;

