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
use IEEE.NUMERIC_STD.ALL;

entity transfer_statemachine is
Generic(
        DATAMOVER_BYTES_TO_TRANSFER_SIZE	: integer	:= 23;
        ADDRESS_LENGTH                      : integer   := 64;
        TRANSFER_SIZE_LENGTH                : integer   := 64
	);
Port (
    transfer_size       : in    STD_LOGIC_VECTOR(ADDRESS_LENGTH - 1 downto 0);
    transfer_addr       : in    STD_LOGIC_VECTOR(ADDRESS_LENGTH -1 downto 0);
    int_start           : in    STD_LOGIC;
    transfer_finished   : out   STD_LOGIC;
    transfer_error      : out   STD_LOGIC;
    
    datamover_in_done       : in    STD_LOGIC;
    datamover_in_err        : in    STD_LOGIC;
    datamover_out_command   : out   STD_LOGIC;
    datamover_out_size      : out   STD_LOGIC_VECTOR(DATAMOVER_BYTES_TO_TRANSFER_SIZE - 1 downto 0);
    datamover_out_addr      : out   STD_LOGIC_VECTOR(ADDRESS_LENGTH - 1 downto 0);
    datamover_cmd_taken     : in    STD_LOGIC;  
    
    clk             : in    STD_LOGIC;
    aresetn         : in    STD_LOGIC
);
end transfer_statemachine;

architecture Behavioral of transfer_statemachine is

    -- state machine type and state
    type transfer_state_type is (IDLE, INITIALIZE, START_TRANSFER, TRANSFER, FINISHED, ERROR);
    signal transfer_state, transfer_state_next: transfer_state_type;
    
    constant DATAMOVER_MAX_BURST_LENGTH : integer := 2**DATAMOVER_BYTES_TO_TRANSFER_SIZE - 1;
    
    -- data transfer state
    signal num_data_left        : unsigned (TRANSFER_SIZE_LENGTH - 1 downto 0);
    signal current_burst_size   : unsigned (DATAMOVER_BYTES_TO_TRANSFER_SIZE - 1 downto 0);
    signal current_start_addr   : unsigned (ADDRESS_LENGTH - 1 downto 0);
        
begin

    -- num_data_left
    update_num_data_left: process(clk)
    begin
        if rising_edge(clk) then
            if(aresetn = '0') then
                num_data_left <= (others => '0');
                current_start_addr <= (others => '0');
            else
                num_data_left <= num_data_left;
                current_start_addr <= current_start_addr;
                -- transfer_state_next and not transfer_state because we are clocked and therefore have 1 delay
                if transfer_state_next = INITIALIZE then
                    num_data_left <= unsigned(transfer_size);
                    current_start_addr <= unsigned(transfer_addr);
                elsif transfer_state_next = START_TRANSFER and transfer_state = TRANSFER then
                    num_data_left <= num_data_left - current_burst_size;
                    current_start_addr <= current_start_addr + current_burst_size;
                end if;
            end if;
        end if;
    end process;
    
    -- finished flag
    transfer_finished <= '1' when transfer_state = FINISHED else '0';
    
    -- current_burst_size
    current_burst_size <= num_data_left(DATAMOVER_BYTES_TO_TRANSFER_SIZE - 1 downto 0) when num_data_left < DATAMOVER_MAX_BURST_LENGTH else to_unsigned(DATAMOVER_MAX_BURST_LENGTH,DATAMOVER_BYTES_TO_TRANSFER_SIZE);
    
    -- START_TRANSFER
    datamover_out_command <= '1' when transfer_state = START_TRANSFER else '0';
    datamover_out_size <= std_logic_vector(current_burst_size);
    datamover_out_addr <= std_logic_vector(current_start_addr);
    
    -- error
    transfer_error <= '1' when transfer_state = ERROR else '0';

    -- clocked part
    state_change: process(clk)
    begin
        if rising_edge(clk) then
           if aresetn = '0' then
              transfer_state <= IDLE;
           else
              transfer_state <= transfer_state_next;
           end if;
        end if;
    end process;
    
    -- next state calculation
    state_next: process(transfer_state, int_start, num_data_left, current_burst_size, datamover_in_done, datamover_cmd_taken, datamover_in_err)
    begin
        transfer_state_next <= transfer_state;
        
        case transfer_state is
            when IDLE =>
                if int_start = '1' then
                    transfer_state_next <= INITIALIZE;
                end if;
            when INITIALIZE =>
                transfer_state_next <= START_TRANSFER;
            when START_TRANSFER =>
                if datamover_cmd_taken = '1' then
                    transfer_state_next <= TRANSFER;
                end if;
            when TRANSFER =>
                if datamover_in_done = '1' then
                    if num_data_left - current_burst_size = 0 then
                        transfer_state_next <= FINISHED;
                    else
                        transfer_state_next <= START_TRANSFER;
                    end if;
                end if;
            when FINISHED =>
                transfer_state_next <= IDLE;
            when ERROR =>
                transfer_state_next <= ERROR;
        end case;
        
        if datamover_in_err = '1' then
            transfer_state_next <= ERROR;
        end if;
        
    end process;

end Behavioral;
