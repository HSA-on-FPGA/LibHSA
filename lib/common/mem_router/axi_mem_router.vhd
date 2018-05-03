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

entity axi_mem_router is
Generic(
    ADDR_SIZE       : integer := 32;
    IMEM_ADDR       : std_logic_vector := x"00000000";
    IMEM_SIZE       : integer := 16#1000#;
    IMEM_WIDTH      : integer := 32;
    IMEM_INIT_FILE  : string := "";
    DMEM_ADDR       : std_logic_vector := x"00001000";
    DMEM_SIZE       : integer := 16#1000#;
    DMEM_WIDTH      : integer := 32;
    DMEM_INIT_FILE  : string := "";
    AXI_CFG_ADDR_SIZE : integer := 64;
    AXI_CFG_DATA_WIDTH : integer := 32
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
    memctrl_data_bus_exc                : in    std_logic;
        
    -- axi connection to instruction memory
    S_AXI_INST_ACLK         : in    std_logic;
    S_AXI_INST_ARESETN      : in    std_logic;
    S_AXI_INST_AWADDR       : in    std_logic_vector(AXI_CFG_ADDR_SIZE-1 downto 0);
    S_AXI_INST_AWVALID      : in    std_logic;
    S_AXI_INST_AWREADY      : out   std_logic;
    S_AXI_INST_WDATA        : in    std_logic_vector(AXI_CFG_DATA_WIDTH-1 downto 0);
    S_AXI_INST_WSTRB        : in    std_logic_vector((AXI_CFG_DATA_WIDTH/8)-1 downto 0);
    S_AXI_INST_WVALID       : in    std_logic;
    S_AXI_INST_WREADY       : out   std_logic;
    S_AXI_INST_BRESP        : out   std_logic_vector(1 downto 0);
    S_AXI_INST_BVALID       : out   std_logic;
    S_AXI_INST_BREADY       : in    std_logic;
    S_AXI_INST_ARADDR       : in    std_logic_vector(AXI_CFG_ADDR_SIZE-1 downto 0);
    S_AXI_INST_ARVALID      : in    std_logic;
    S_AXI_INST_ARREADY      : out   std_logic;
    S_AXI_INST_RDATA        : out   std_logic_vector(AXI_CFG_DATA_WIDTH-1 downto 0);
    S_AXI_INST_RRESP        : out   std_logic_vector(1 downto 0);
    S_AXI_INST_RVALID       : out   std_logic;
    S_AXI_INST_RREADY       : in    std_logic;
    
    -- axi connection to data memory
    S_AXI_DATA_ACLK         : in    std_logic;
    S_AXI_DATA_ARESETN      : in    std_logic;
    S_AXI_DATA_AWADDR       : in    std_logic_vector(AXI_CFG_ADDR_SIZE-1 downto 0);
    S_AXI_DATA_AWVALID      : in    std_logic;
    S_AXI_DATA_AWREADY      : out   std_logic;
    S_AXI_DATA_WDATA        : in    std_logic_vector(AXI_CFG_DATA_WIDTH-1 downto 0);
    S_AXI_DATA_WSTRB        : in    std_logic_vector((AXI_CFG_DATA_WIDTH/8)-1 downto 0);
    S_AXI_DATA_WVALID       : in    std_logic;
    S_AXI_DATA_WREADY       : out   std_logic;
    S_AXI_DATA_BRESP        : out   std_logic_vector(1 downto 0);
    S_AXI_DATA_BVALID       : out   std_logic;
    S_AXI_DATA_BREADY       : in    std_logic;
    S_AXI_DATA_ARADDR       : in    std_logic_vector(AXI_CFG_ADDR_SIZE-1 downto 0);
    S_AXI_DATA_ARVALID      : in    std_logic;
    S_AXI_DATA_ARREADY      : out   std_logic;
    S_AXI_DATA_RDATA        : out   std_logic_vector(AXI_CFG_DATA_WIDTH-1 downto 0);
    S_AXI_DATA_RRESP        : out   std_logic_vector(1 downto 0);
    S_AXI_DATA_RVALID       : out   std_logic;
    S_AXI_DATA_RREADY       : in    std_logic

);
end axi_mem_router;

architecture Behavioral of axi_mem_router is

constant IMEM_LOCAL_NUM_ADDR_BITS : integer := integer(ceil(log2(real(IMEM_SIZE))));
constant DMEM_LOCAL_NUM_ADDR_BITS : integer := integer(ceil(log2(real(DMEM_SIZE))));

signal prev_halt          : std_logic;
signal data_addr_is_local : std_logic;
signal prev_busy          : std_logic;

signal data_from_dmem : std_logic_vector(DMEM_WIDTH - 1 downto 0);
signal saved_result   : std_logic_vector(DMEM_WIDTH - 1 downto 0);

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
    mips_data_dout <= saved_result   when                                     prev_busy = '1' else
                      data_from_dmem when read_from_local_delayed = '1'   and prev_busy = '0' else
                      memctrl_din    when read_from_memctrl_delayed = '1' and prev_busy = '0' else (others => '0');
    
    -- busy flags
    mips_inst_read_busy  <= prev_halt;
    mips_data_read_busy  <= memctrl_read_busy   when read_from_memctrl = '1' else '0';
    mips_data_write_busy <= memctrl_write_busy  when write_to_memctrl = '1'  else '0';

    delay: process(clk)
    begin
	if(rising_edge(clk)) then
		if(resetn='0') then
			read_from_local_delayed   <= '0';
			read_from_memctrl_delayed <= '0';
			prev_halt                 <= '0';
			prev_busy                 <= '0';
		else
			read_from_local_delayed   <= read_from_local;
			read_from_memctrl_delayed <= read_from_memctrl;
			prev_halt                 <= halt;
			prev_busy                 <= memctrl_read_busy or memctrl_write_busy;
		end if;
	end if;
    end process;
    
    save_output: process(clk)
    begin
	if(rising_edge(clk)) then
		if(resetn='0') then
			saved_result <= (others => '0');
		elsif(prev_busy = '0' and read_from_local_delayed='1') then
			saved_result <= data_from_dmem;
		elsif(prev_busy = '0' and read_from_memctrl_delayed='1') then
			saved_result <= memctrl_din;
		else
			saved_result <= saved_result;
		end if;
	end if;
    end process;

    -- BRAM instanciations
    imem_bram_inst : entity work.axi_dualclock_bram
    generic map (
        BRAM_SIZE       => IMEM_SIZE,
        BRAM_ADDR_WIDTH => IMEM_LOCAL_NUM_ADDR_BITS,
        AXI_ADDR_WIDTH  => AXI_CFG_ADDR_SIZE,
        DATA_WIDTH      => IMEM_WIDTH,
        AXI_DATA_WIDTH  => AXI_CFG_DATA_WIDTH,
        INIT_FILE       => IMEM_INIT_FILE
    )
    port map (
        S_AXI_ACLK    => S_AXI_INST_ACLK,   
        S_AXI_ARESETN => S_AXI_INST_ARESETN,
        S_AXI_AWADDR  => S_AXI_INST_AWADDR, 
        S_AXI_AWVALID => S_AXI_INST_AWVALID,
        S_AXI_AWREADY => S_AXI_INST_AWREADY,
        S_AXI_WDATA   => S_AXI_INST_WDATA,  
        S_AXI_WSTRB   => S_AXI_INST_WSTRB,  
        S_AXI_WVALID  => S_AXI_INST_WVALID, 
        S_AXI_WREADY  => S_AXI_INST_WREADY, 
        S_AXI_BRESP   => S_AXI_INST_BRESP,  
        S_AXI_BVALID  => S_AXI_INST_BVALID, 
        S_AXI_BREADY  => S_AXI_INST_BREADY, 
        S_AXI_ARADDR  => S_AXI_INST_ARADDR, 
        S_AXI_ARVALID => S_AXI_INST_ARVALID,
        S_AXI_ARREADY => S_AXI_INST_ARREADY,
        S_AXI_RDATA   => S_AXI_INST_RDATA,  
        S_AXI_RRESP   => S_AXI_INST_RRESP,  
        S_AXI_RVALID  => S_AXI_INST_RVALID,
        S_AXI_RREADY  => S_AXI_INST_RREADY, 
        BRAM_CLK      => clk,
        BRAM_WREN     => '0',
        BRAM_ADDR     => iaddr_local,
        BRAM_DIN      => (others => '0'),
        BRAM_DOUT     => mips_inst_dout,
        BRAM_EN       => mips_inst_re
    );
    
    dmem_bram_inst : entity work.axi_dualclock_bram
    generic map (
        BRAM_SIZE       => DMEM_SIZE,
        BRAM_ADDR_WIDTH => DMEM_LOCAL_NUM_ADDR_BITS,
        AXI_ADDR_WIDTH  => AXI_CFG_ADDR_SIZE,
        DATA_WIDTH      => DMEM_WIDTH,
        AXI_DATA_WIDTH  => AXI_CFG_DATA_WIDTH,
        INIT_FILE       => DMEM_INIT_FILE
    )
    port map (
        S_AXI_ACLK    => S_AXI_DATA_ACLK,   
        S_AXI_ARESETN => S_AXI_DATA_ARESETN,
        S_AXI_AWADDR  => S_AXI_DATA_AWADDR, 
        S_AXI_AWVALID => S_AXI_DATA_AWVALID,
        S_AXI_AWREADY => S_AXI_DATA_AWREADY,
        S_AXI_WDATA   => S_AXI_DATA_WDATA,  
        S_AXI_WSTRB   => S_AXI_DATA_WSTRB,  
        S_AXI_WVALID  => S_AXI_DATA_WVALID, 
        S_AXI_WREADY  => S_AXI_DATA_WREADY, 
        S_AXI_BRESP   => S_AXI_DATA_BRESP,  
        S_AXI_BVALID  => S_AXI_DATA_BVALID, 
        S_AXI_BREADY  => S_AXI_DATA_BREADY, 
        S_AXI_ARADDR  => S_AXI_DATA_ARADDR, 
        S_AXI_ARVALID => S_AXI_DATA_ARVALID,
        S_AXI_ARREADY => S_AXI_DATA_ARREADY,
        S_AXI_RDATA   => S_AXI_DATA_RDATA,  
        S_AXI_RRESP   => S_AXI_DATA_RRESP,  
        S_AXI_RVALID  => S_AXI_DATA_RVALID,
        S_AXI_RREADY  => S_AXI_DATA_RREADY, 
        BRAM_CLK      => clk,
        BRAM_WREN     => write_to_local,
        BRAM_ADDR     => daddr_local,
        BRAM_DIN      => mips_data_din,
        BRAM_DOUT     => data_from_dmem,
        BRAM_EN       => bram_en
    );
        
    

end Behavioral;
