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

use IEEE.math_real.all;
use ieee.numeric_std.all;

entity mem_router is
Generic(
    ADDR_SIZE       : integer 		:= 32;
    IMEM_ADDR       : std_logic_vector 	:= x"00000000";
    IMEM_SIZE       : integer 		:= 16#1000#;
    IMEM_WIDTH      : integer 		:= 32;
    IMEM_INIT_FILE  : string		:= "";
    DMEM_ADDR       : std_logic_vector 	:= x"00001000";
    DMEM_SIZE       : integer 		:= 16#1000#;
    DMEM_WIDTH      : integer 		:= 32;
    DMEM_INIT_FILE  : string 		:= ""
);
Port (
    clk             : in    std_logic;
    resetn          : in    std_logic;
    halt            : in    std_logic;
    
    -- connections to MIPS
    mips_inst_addr  : in    std_logic_vector(ADDR_SIZE - 1 downto 0);
    mips_inst_re    : in    std_logic;
    mips_inst_dout  : out   std_logic_vector(IMEM_WIDTH - 1 downto 0);
    mips_data_addr  : in    std_logic_vector(ADDR_SIZE - 1 downto 0);
    mips_data_re    : in    std_logic;
    mips_data_we    : in    std_logic;
    mips_data_din   : in    std_logic_vector(DMEM_WIDTH - 1 downto 0);
    mips_data_dout  : out   std_logic_vector(DMEM_WIDTH - 1 downto 0);
    mips_inst_read_busy     : out   std_logic;
    mips_data_read_busy     : out   std_logic;
    mips_data_write_busy    : out   std_logic;
    
    -- exceptions to MIPS
    mips_address_error_exc_load     : out std_logic;
    mips_address_error_exc_fetch    : out std_logic;
    mips_address_error_exc_store    : out std_logic;
    mips_instruction_bus_exc        : out std_logic;
    mips_data_bus_exc               : out std_logic;
    
    -- connection to memory controller
    memctrl_addr                        : out   std_logic_vector(ADDR_SIZE - 1 downto 0);
    memctrl_din                         : in    std_logic_vector(DMEM_WIDTH - 1 downto 0);
    memctrl_dout                        : out   std_logic_vector(DMEM_WIDTH - 1 downto 0);
    memctrl_re                          : out   std_logic;
    memctrl_we                          : out   std_logic;
    memctrl_read_busy                   : in    std_logic;
    memctrl_write_busy                  : in    std_logic;
    memctrl_address_error_exc_load      : in    std_logic;
    memctrl_address_error_exc_store     : in    std_logic;
    memctrl_data_bus_exc                : in    std_logic
);
end mem_router;

architecture Behavioral of mem_router is

constant IMEM_LOCAL_NUM_ADDR_BITS : integer := integer(ceil(log2(real(IMEM_SIZE))));
constant DMEM_LOCAL_NUM_ADDR_BITS : integer := integer(ceil(log2(real(DMEM_SIZE))));

signal prev_halt          : std_logic;
signal data_addr_is_local : std_logic;
signal prev_busy          : std_logic;

signal local_read_busy		: std_logic;
signal local_read_busy_delayed	: std_logic;

signal data_from_dmem 		: std_logic_vector(DMEM_WIDTH - 1 downto 0);
signal data_from_dmem_reg 	: std_logic_vector(DMEM_WIDTH - 1 downto 0);
signal saved_result   		: std_logic_vector(DMEM_WIDTH - 1 downto 0);

signal write_to_local            : std_logic;
signal write_to_memctrl          : std_logic;
signal read_from_local           : std_logic;
signal read_from_memctrl         : std_logic;
signal read_from_local_delayed   : std_logic;
signal read_from_memctrl_delayed : std_logic;

signal iaddr_local :  std_logic_vector(IMEM_LOCAL_NUM_ADDR_BITS - 1 downto 0);
signal daddr_local :  std_logic_vector(DMEM_LOCAL_NUM_ADDR_BITS - 1 downto 0);
signal iaddr_local_long :  std_logic_vector(ADDR_SIZE - 1 downto 0);
signal daddr_local_long :  std_logic_vector(ADDR_SIZE - 1 downto 0);

signal bram_en : std_logic;

begin
	bram_en <= read_from_local or write_to_local;

    iaddr_local_long <= std_logic_vector(unsigned(mips_inst_addr) - unsigned(IMEM_ADDR));
    daddr_local_long <= std_logic_vector(unsigned(mips_data_addr) - unsigned(DMEM_ADDR));
    iaddr_local <= iaddr_local_long(IMEM_LOCAL_NUM_ADDR_BITS - 1 downto 0);
    daddr_local <= daddr_local_long(DMEM_LOCAL_NUM_ADDR_BITS - 1 downto 0);
        
    -- exceptions
    mips_address_error_exc_load  <= memctrl_address_error_exc_load;
    mips_address_error_exc_fetch <= '1' when unsigned(mips_inst_addr)<unsigned(IMEM_ADDR) and mips_inst_re = '1' else
				    '1' when unsigned(iaddr_local_long)>=to_unsigned(IMEM_SIZE,iaddr_local_long'length) and mips_inst_re = '1' 
					else '0';
 
    mips_address_error_exc_store <= memctrl_address_error_exc_store;
    mips_instruction_bus_exc     <= '0';
    mips_data_bus_exc            <= memctrl_data_bus_exc;
 
    -- memctrl signals
    memctrl_addr <= mips_data_addr;
    memctrl_dout <= mips_data_din;
    memctrl_re   <= read_from_memctrl;
    memctrl_we   <= write_to_memctrl; 
    
    -- compute whether or not current addr is local or in memctrl
    data_addr_is_local <= '1' when unsigned(mips_data_addr) >= unsigned(DMEM_ADDR) and unsigned(mips_data_addr) < (unsigned(DMEM_ADDR) + to_unsigned(DMEM_SIZE, DMEM_ADDR'length)) else '0';
    
    -- compute whether or not we need to write to local
    write_to_local <= '1' when data_addr_is_local = '1' and mips_data_we = '1' else '0';
    write_to_memctrl <= '1' when data_addr_is_local = '0' and mips_data_we = '1' else '0';
    read_from_local <= '1' when data_addr_is_local = '1' and mips_data_re = '1' else '0';
    read_from_memctrl <= '1' when data_addr_is_local = '0' and mips_data_re = '1' else '0';
    
    -- switch dout depending on current state
    mips_data_dout <= saved_result       when                                     prev_busy = '1' else
                      data_from_dmem_reg when read_from_local_delayed = '1'   and prev_busy = '0' else
                      memctrl_din        when read_from_memctrl_delayed = '1' and prev_busy = '0' else (others => '0');
    
    -- busy flags
    mips_inst_read_busy  <= prev_halt;
    mips_data_write_busy <= memctrl_write_busy  when write_to_memctrl = '1'  else '0';
    mips_data_read_busy  <= memctrl_read_busy   when read_from_memctrl = '1' else
                            local_read_busy     when read_from_local = '1'   else '0';
		
    local_read_busy <= read_from_local and (not local_read_busy_delayed);

    delay: process(clk)
    begin
	if(rising_edge(clk)) then
		if(resetn='0') then
			read_from_local_delayed   <= '0';
			read_from_memctrl_delayed <= '0';
			prev_halt                 <= '0';
			prev_busy                 <= '0';
			local_read_busy_delayed   <= '0';
		else
			read_from_local_delayed   <= read_from_local;
			read_from_memctrl_delayed <= read_from_memctrl;
			prev_halt                 <= halt;
			prev_busy                 <= memctrl_read_busy or memctrl_write_busy or local_read_busy;
			local_read_busy_delayed   <= local_read_busy;
		end if;
	end if;
    end process;

    dmem_register: process(clk)
    begin
	if(rising_edge(clk)) then
		if(resetn='0') then
			data_from_dmem_reg 	<= (others => '0');
		else
			data_from_dmem_reg	<= data_from_dmem;
		end if;
	end if;
    end process;
    
    save_output: process(clk)
    begin
	if(rising_edge(clk)) then
		if(resetn='0') then
			saved_result <= (others => '0');
		elsif(prev_busy = '0' and read_from_local_delayed='1') then
			saved_result <= data_from_dmem_reg;
		elsif(prev_busy = '0' and read_from_memctrl_delayed='1') then
			saved_result <= memctrl_din;
		else
			saved_result <= saved_result;
		end if;
	end if;
    end process;

    -- BRAM instanciations
    imem_bram_inst : entity work.singleclock_bram
    generic map (
        C_DATA      => IMEM_WIDTH,
        C_ADDR      => IMEM_LOCAL_NUM_ADDR_BITS,
        C_SIZE      => IMEM_SIZE,
        C_INIT_FILE => IMEM_INIT_FILE
    )
    port map (
        clk   => clk,
        en    => mips_inst_re,
        wr    => '0',
        addr  => iaddr_local,
        din   => (others => '0'),
        dout  => mips_inst_dout
    );
    
    dmem_bram_inst : entity work.singleclock_bram
    generic map (
        C_DATA      => DMEM_WIDTH,
        C_ADDR      => DMEM_LOCAL_NUM_ADDR_BITS,
        C_SIZE      => DMEM_SIZE,
        C_INIT_FILE => DMEM_INIT_FILE
    )
    port map (
        clk   => clk,
        en    => bram_en,
        wr    => write_to_local,
        addr  => daddr_local,
        din   => mips_data_din,
        dout  => data_from_dmem
    );

end Behavioral;
