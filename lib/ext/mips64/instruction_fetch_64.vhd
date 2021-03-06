-- instruction_fetch_64: Instruction fetch unit for mips pipeline
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
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
entity instruction_fetch_64 is
    generic(
        G_EXCEPTION_HANDLER_ADDRESS : std_logic_vector(63 downto 0) := x"0000000000000010"
    );
    port(

        -- data path
        pc_branch           : in  std_logic_vector(63 downto 0);
        pc_current          : in  std_logic_vector(63 downto 0);
        pc_next             : out std_logic_vector(63 downto 0);
        instruction         : out std_logic_vector(31 downto 0);

        inst_address        : out std_logic_vector(63 downto 0);
        inst_data           : in  std_logic_vector(31 downto 0);

        -- control path
        interrupt_syn       : in  std_logic;
        take_branch         : in  std_logic

    );
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of instruction_fetch_64 is


--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/
constant c_exception_handler    : std_logic_vector(63 downto 0) := G_EXCEPTION_HANDLER_ADDRESS;

signal s_pc_plus4               : std_logic_vector(63 downto 0);
-- /*end-folding-block*/

begin


--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    pc_next         <= G_EXCEPTION_HANDLER_ADDRESS  when interrupt_syn = '1'
                  else s_pc_plus4;

    inst_address    <= pc_current when take_branch = '0'
                       else pc_branch;
    instruction     <= inst_data;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

process(pc_current, take_branch, pc_branch)
begin
    if (take_branch = '0') then
        s_pc_plus4  <= std_logic_vector(unsigned(pc_current) +4);
    else
        s_pc_plus4  <= std_logic_vector(unsigned(pc_branch) +4);
    end if;
end process;


-- /*end-folding-block*/

end architecture;

