-- asip_alu_64: ASIP ALU
-- Copyright 2017 Tobias Lieske
--
-- tobias.lieske@fau.de
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
use work.asip_instruction_components_pkg_64.all;
use work.alu_pkg_64.all;

entity asip_alu_64 is
    generic (
        G_SENSOR_DATA_WIDTH     : integer range 1 to 1024 := 1;
        G_SENSOR_CONF_WIDTH     : integer range 1 to 1024 := 1;
        G_BUSY_LIST_WIDTH       : integer range 1 to 1024 := 2
    );
    port (
        -- general
        clk             : in  std_logic;
        en              : in  std_logic;
        arstn           : in  std_logic;

        -- exception
        abort           : in  std_logic;

        -- inputs
        alu_op          : in  alu_ctrl_t;
        input0          : in  std_logic_vector(63 downto 0);
        input1          : in  std_logic_vector(63 downto 0);
        sensor_input    : in  std_logic_vector(G_SENSOR_DATA_WIDTH-1 downto 0);

        -- output
        busy_list       : out std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);
        output          : out std_logic_vector(63 downto 0);
        done            : out std_logic;
        sensor_conf     : out std_logic_vector(G_SENSOR_CONF_WIDTH-1 downto 0);
        valid_result    : out std_logic
    );
end entity asip_alu_64;

architecture behavioral of asip_alu_64 is


-- read only sensor data that can be used as instruction inputs

    alias sensor_sensor_dummy : std_logic_vector(0 downto 0) is sensor_input(0 downto 0);

    constant c_read_sensor_sensor_dummy : std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0) := (others => '0');



-- sensor config registers

    signal sensor_dummy_cfg_dummy : std_logic_vector(0 downto 0);



-- bit list which special registers and sensor config registers are in use: read / write
-- Beginning from MSB, bit 1 downto 2: Read access to special registers
-- Beginning from MSB, bit 2 downto 1: Read access to sensor config registers
-- Beginning from MSB, bit 0 downto 1: Write access to special registers
-- Beginning from MSB, bit 0 downto 0: Write access to sensor config registers
signal r_busy_list  : std_logic_vector(1 downto 0);
signal s_busy_list  : std_logic_vector(1 downto 0);



constant c_read_sensor_dummy_cfg_dummy : std_logic_vector(1 downto 0) := "10";

constant c_write_sensor_dummy_cfg_dummy : std_logic_vector(1 downto 0) := "01";


constant c_dummy_busy_list_zero : std_logic_vector(1 downto 0) := (others => '0');







-- special registers



-- instruction signals


begin

    busy_list <= s_busy_list;


-- propagate sensor config

        sensor_conf(0 downto 0) <= sensor_dummy_cfg_dummy;



-- propagate abort to current instruction




-- propagate current busy list to instruction decode to detect data hazards
proc_propagate_busy_list : process (

    alu_op, r_busy_list
)
    variable v_busy_list : std_logic_vector(1 downto 0);
begin
    v_busy_list := r_busy_list;
    case alu_op is

        when others =>
            s_busy_list <= r_busy_list;
    end case;

    s_busy_list <= v_busy_list;
end process proc_propagate_busy_list;



-- update busy list on finishing instructions
proc_update_busy_list : process (
    clk, arstn
)
    variable v_busy_list : std_logic_vector(1 downto 0);
begin
    if (arstn = '0') then
        r_busy_list <= (others => '0');
    elsif (clk'event and clk = '1') then
        
        r_busy_list <= s_busy_list;
    end if;
end process proc_update_busy_list;


-- start instructions



-- write back to internal special registers
proc_write_back : process (
    clk, arstn
)
begin
    if (arstn = '0') then
        sensor_dummy_cfg_dummy <= (others => '0');

    elsif (clk'event and clk = '1') then

    end if;
end process proc_write_back;


-- output
-- every instruction returning a result to the output port locks the pipeline
-- so we can use alu_op to multiplex the output port
proc_output : process (

    alu_op
)
begin
    output <= (others => '0');
    valid_result <= '0';
    case alu_op is

        when others =>
            done <= '1';
            output <= (others => '0');

    end case;
end process proc_output;



-- instruction instantiations


end architecture behavioral;
