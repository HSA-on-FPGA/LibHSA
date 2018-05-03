-- asip_decode: ASIP decode unit
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

entity asip_decode_64 is
    generic (
        G_BUSY_LIST_WIDTH       : integer range 1 to 1024 := 2
    );
    port (
        -- inputs
        opcode          : in  std_logic_vector(5 downto 0);
        funct           : in  std_logic_vector(5 downto 0);
        busy_list       : in  std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);

        -- output
        alu_op          : out alu_ctrl_t;
        reg_write       : out std_logic;
        reg_dst         : out std_logic;
        alu_src         : out std_logic;
        valid           : out std_logic;
        stall           : out std_logic
    );
end entity asip_decode_64;

architecture behavioral of asip_decode_64 is

-- bit list which special registers and sensor config registers are in use: read / write
-- Beginning from MSB, bit 1 downto 2: Read access to special registers
-- Beginning from MSB, bit 2 downto 1: Read access to sensor config registers
-- Beginning from MSB, bit 0 downto 1: Write access to special registers
-- Beginning from MSB, bit 0 downto 0: Write access to sensor config registers



constant c_read_sensor_dummy_cfg_dummy : std_logic_vector(1 downto 0) := "10";

constant c_write_sensor_dummy_cfg_dummy : std_logic_vector(1 downto 0) := "01";

constant c_read_sensor_sensor_dummy : std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0) := (others => '0');


constant c_dummy_busy_list_zero : std_logic_vector(1 downto 0) := (others => '0');




begin

proc_decode : process (
    opcode, funct, busy_list
)
begin
    stall <= '0';
    alu_op <= op_nop;
    reg_write <= '0';
    reg_dst <= '0';
    alu_src <= '0';
    valid <= '0';
    case opcode is

        when others =>
            -- dummy

    end case;
end process proc_decode;



end architecture behavioral;
