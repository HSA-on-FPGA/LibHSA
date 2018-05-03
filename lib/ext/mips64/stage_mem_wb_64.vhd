-- stage_mem_wb_64: Pipeline stage memory/write back
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
entity stage_mem_wb_64 is
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
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of stage_mem_wb_64 is


--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/


-- data path
signal r_alu_result     : std_logic_vector(63 downto 0);
signal r_dest_reg       : std_logic_vector( 4 downto 0);

-- control path
signal r_ctrl_wb        : std_logic_vector( 1 downto 0);
signal r_ctrl_mem_in    : std_logic_vector( 8 downto 0);

-- /*end-folding-block*/

begin


--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    -- data path
    alu_result_out      <= r_alu_result;
    read_data_out       <= read_data_in;
    dest_reg_out        <= r_dest_reg;



    -- control path
    ctrl_wb_out         <= r_ctrl_wb;
    ctrl_mem_out        <= r_ctrl_mem_in;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    process(clk, reset)
    begin
        if (reset='0') then
            -- data path
            r_alu_result    <= (others=>'0');
            r_dest_reg      <= (others=>'0');

            -- control path
            r_ctrl_wb       <= (others=>'0');
            r_ctrl_mem_in   <= (others=>'0');
        elsif (rising_edge(clk)) then
            if (enable='1') then

                -- data path
                r_alu_result    <= alu_result_in;
                r_dest_reg      <= dest_reg_in;


                -- control path
                r_ctrl_wb       <= ctrl_wb_in;
                r_ctrl_mem_in   <= ctrl_mem_in;

            end if;
        end if;
    end process;

-- /*end-folding-block*/

end architecture;

