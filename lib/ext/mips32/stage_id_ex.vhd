-- stage_id_ex: Pipeline stage instruction decode/execute
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
use work.alu_pkg.all;
--use ieee.math_real.all;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
entity stage_id_ex is
    port(
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;


        -- data path
        reg_data_in_1       : in  std_logic_vector(31 downto 0);
        reg_data_in_2       : in  std_logic_vector(31 downto 0);
        immediate_value_in  : in  std_logic_vector(31 downto 0);
        --dest_reg_in_1     : in  std_logic_vector( 4 downto 0); --rt
        --dest_reg_in_2     : in  std_logic_vector( 4 downto 0); --rd
        dest_reg_in         : in  std_logic_vector( 4 downto 0);

        reg_data_out_1      : out std_logic_vector(31 downto 0);
        reg_data_out_2      : out std_logic_vector(31 downto 0);
        immediate_value_out : out std_logic_vector(31 downto 0);
        --dest_reg_out_1        : out std_logic_vector( 4 downto 0); --rt
        --dest_reg_out_2        : out std_logic_vector( 4 downto 0); --rd
        dest_reg_out        : out std_logic_vector( 4 downto 0);

        -- forwarding
        forward_rs_addr_in  : in  std_logic_vector( 4 downto 0);
        forward_rt_addr_in  : in  std_logic_vector( 4 downto 0);
        forward_rs_addr_out : out std_logic_vector( 4 downto 0);
        forward_rt_addr_out : out std_logic_vector( 4 downto 0);

        -- control path
        alu_src_in          : in  std_logic;
        alu_ctrl_in         : in  alu_ctrl_t;
        ctrl_mem_in         : in  std_logic_vector( 4 downto 0);
        ctrl_wb_in          : in  std_logic_vector( 1 downto 0);

        alu_src_out         : out std_logic;
        alu_ctrl_out        : out alu_ctrl_t;
        ctrl_mem_out        : out std_logic_vector( 4 downto 0);
        ctrl_wb_out         : out std_logic_vector( 1 downto 0)
    );
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of stage_id_ex is


--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

alias memwrite          : std_logic is ctrl_mem_in(0);

-- data path
signal s_reg_data_1     : std_logic_vector(31 downto 0);
signal s_reg_data_2     : std_logic_vector(31 downto 0);
signal s_immediate_value: std_logic_vector(31 downto 0);
signal s_dest_reg       : std_logic_vector( 4 downto 0);

-- forwardung
signal s_forward_rs_addr: std_logic_vector( 4 downto 0);
signal s_forward_rt_addr: std_logic_vector( 4 downto 0);

-- control path
signal s_alu_src        : std_logic;
signal s_alu_ctrl       : alu_ctrl_t;
signal s_ctrl_mem       : std_logic_vector( 4 downto 0);
signal s_ctrl_wb        : std_logic_vector( 1 downto 0);

-- /*end-folding-block*/

begin


--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    -- data path
    reg_data_out_1      <= s_reg_data_1;
    reg_data_out_2      <= s_reg_data_2;
    immediate_value_out <= s_immediate_value;
    dest_reg_out        <= s_dest_reg;

    -- forwarding
    forward_rs_addr_out <= s_forward_rs_addr;
    forward_rt_addr_out <= s_forward_rt_addr;

    -- control path
    alu_src_out         <= s_alu_src;
    alu_ctrl_out        <= s_alu_ctrl;
    ctrl_mem_out        <= s_ctrl_mem;
    ctrl_wb_out         <= s_ctrl_wb;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    process(clk, reset)
    begin
        if (reset='0') then
            -- data path
            s_reg_data_1        <= (others=>'0');
            s_reg_data_2        <= (others=>'0');
            s_immediate_value   <= (others=>'0');
            s_dest_reg          <= (others=>'0');

            --forwarding
            s_forward_rs_addr   <= (others=>'0');
            s_forward_rt_addr   <= (others=>'0');

            -- control path
            s_alu_src           <= '0';
            s_alu_ctrl          <= op_sll;
            s_ctrl_mem          <= (others=>'0');
            s_ctrl_wb           <= (others=>'0');
        elsif (rising_edge(clk)) then
            if (enable='1') then
                -- forwarding
                s_forward_rs_addr   <= forward_rs_addr_in;
                s_forward_rt_addr   <= forward_rt_addr_in;

                s_ctrl_mem          <= ctrl_mem_in;
                s_ctrl_wb           <= ctrl_wb_in;

                -- needs to always update in order to leave stall status
                s_dest_reg          <= dest_reg_in;

                -- for op_nop instructions, the following singals are not read
                -- and thus kept fixed to reduce switching power
                if (alu_ctrl_in /= op_nop) then
                    s_alu_ctrl          <= alu_ctrl_in;

                    -- control path
                    s_alu_src           <= alu_src_in;

                    s_immediate_value   <= immediate_value_in;

                    -- data path
                    s_reg_data_1        <= reg_data_in_1;

                    -- keep the pipeline register fixed if it is not read anyway
                    if (alu_src_in = '0' or memwrite = '1') then
                        s_reg_data_2        <= reg_data_in_2;
                    end if;
                end if;
            end if;
        end if;
    end process;

-- /*end-folding-block*/

end architecture;

