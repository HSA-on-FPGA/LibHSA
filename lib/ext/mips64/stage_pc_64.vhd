-- stage_pc_64: Pipeline stage program counter
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
entity stage_pc_64 is
	generic(G_START_ADDRESS	: std_logic_vector(63 downto 0) := x"0000000000000000");
	port(
		clk					: in  std_logic;
		reset				: in  std_logic;
		enable				: in  std_logic;
        syn_interrupt       : in  std_logic;

		-- data path
		pc_in				: in  std_logic_vector(63 downto 0);
		pc_out				: out std_logic_vector(63 downto 0)
	);
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of stage_pc_64 is


--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

signal s_pc				: std_logic_vector(63 downto 0);

-- /*end-folding-block*/

begin


--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/

	-- data path
	pc_out			<= s_pc;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

	process(clk, reset)
	begin
		if (reset='0') then
			--s_pc			<= (others=>'0');
            s_pc			<= G_START_ADDRESS;
		elsif (rising_edge(clk)) then
			if (enable='1' or syn_interrupt = '1') then
				s_pc 			<= pc_in;
			end if;
		end if;
	end process;

-- /*end-folding-block*/

end architecture;

