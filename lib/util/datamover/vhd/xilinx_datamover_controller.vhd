-- Copyright (C) 2017 Philipp Holzinger
-- Copyright (C) 2017 Martin Stumpf
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xilinx_datamover_controller is
Generic(
        DATAMOVER_BYTES_TO_TRANSFER_SIZE	: integer	:= 23;
        DATAMOVER_ADDRESS_SIZE              : integer   := 64
	);
Port (
    xdm_status_tdata :  in  STD_LOGIC_VECTOR ( 7 downto 0 );
    xdm_status_tkeep :  in  STD_LOGIC_VECTOR ( 0 to 0 );
    xdm_status_tlast :  in  STD_LOGIC;
    xdm_status_tready : out STD_LOGIC;
    xdm_status_tvalid : in  STD_LOGIC;
    xdm_cmd_tdata :     out STD_LOGIC_VECTOR ( 103 downto 0 ); 
    xdm_cmd_tready :    in  STD_LOGIC;
    xdm_cmd_tvalid :    out STD_LOGIC;
    xdm_err :           in  STD_LOGIC;
    sm_done :           out STD_LOGIC;
    sm_err :            out STD_LOGIC;
    sm_out_command :    in  STD_LOGIC;
    sm_out_size :       in  STD_LOGIC_VECTOR(DATAMOVER_BYTES_TO_TRANSFER_SIZE - 1 downto 0);
    sm_out_addr :       in  STD_LOGIC_VECTOR(DATAMOVER_ADDRESS_SIZE - 1 downto 0);
    sm_out_cmd_taken :  out STD_LOGIC
);
end xilinx_datamover_controller;

architecture Behavioral of xilinx_datamover_controller is

signal xdm_status_err : STD_LOGIC;

begin

    -- cmd bus
    cmd_bus: process(xdm_cmd_tready, sm_out_command, sm_out_size, sm_out_addr)
    begin
        sm_out_cmd_taken <= xdm_cmd_tready;
        xdm_cmd_tvalid <= sm_out_command;
        xdm_cmd_tdata <= (others => '0');
        xdm_cmd_tdata(22 downto 0) <= sm_out_size;
        xdm_cmd_tdata(23) <= '1';
        xdm_cmd_tdata(30) <= '1';
        xdm_cmd_tdata(DATAMOVER_ADDRESS_SIZE + 31 downto 32) <= sm_out_addr;  
    end process;
    
    -- status bus
    xdm_status_tready <= '1';
    
    -- err bus
    sm_err <= '0' when xdm_err = '0' and xdm_status_err = '0' else '1';
    xdm_status_err <= '1' when xdm_status_tdata(6 downto 4) /= "000" and xdm_status_tvalid = '1' else '0';
    sm_done <= '1' when xdm_status_tdata(7) = '1' and xdm_status_tvalid = '1' else '0';

end Behavioral;
