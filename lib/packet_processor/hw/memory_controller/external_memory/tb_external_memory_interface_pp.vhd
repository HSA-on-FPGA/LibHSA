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

library ieee;
use IEEE.std_logic_1164.all;

package config is
	constant CONF_CMD_LOW_ADDR		: std_logic_vector	:= x"0002000000000000";
	constant CONF_CMD_HIGH_ADDR		: std_logic_vector	:= x"0002000000010000";
	constant CONF_CMD_AXI_ADDR_WIDTH	: integer		:= 64;
	constant CONF_CMD_AXI_DATA_WIDTH	: integer		:= 64;	
	constant CONF_DATA_LOW_ADDR		: std_logic_vector	:= x"0001000000000000";
	constant CONF_DATA_HIGH_ADDR		: std_logic_vector	:= x"0001000100000000";
	constant CONF_DATA_AXI_ADDR_WIDTH	: integer		:= 64;
	constant CONF_DATA_AXI_DATA_WIDTH	: integer		:= 64;
	constant CONF_IRQ_WORK_LEFT_ADDR	: std_logic_vector	:= x"0002000000000000";
	constant CONF_IRQ_SND_NUM_ADDR		: std_logic_vector	:= x"0002000000000008";
	constant CONF_IRQ_RCV_NUM_ADDR		: std_logic_vector	:= x"0002000000000010";
end config;

use work.config.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;


entity tb_external_memory_interface_pp IS
end tb_external_memory_interface_pp;

architecture behav of tb_external_memory_interface_pp is
signal s_data_addr               	: std_logic_vector(63 downto 0);
signal s_data_din                	: std_logic_vector(63 downto 0);
signal s_data_we                 	: std_logic;
signal s_data_re                 	: std_logic;
signal s_data_dout               	: std_logic_vector(63 downto 0);
signal s_data_read_busy          	: std_logic;
signal s_data_write_busy         	: std_logic;
signal s_address_error_exc_load  	: std_logic;
signal s_address_error_exc_store 	: std_logic;
signal s_data_bus_exc            	: std_logic;
signal s_RCV_INT_NUM			: std_logic_vector(63 downto 0);
signal s_RCV_WORK_LEFT			: std_logic;
signal s_RCV_WORK_LEFT_RESPONSE		: std_logic;
signal s_RCV_WORK_LEFT_RESPONSE_WRITE	: std_logic;
signal s_SND_INT_NUM			: std_logic_vector(63 downto 0);
signal s_SND_INT_SIG			: std_logic;
signal s_cmd_axi_awaddr			: std_logic_vector(CONF_CMD_AXI_ADDR_WIDTH-1 downto 0);
signal s_cmd_axi_awprot			: std_logic_vector(2 downto 0);
signal s_cmd_axi_awvalid		: std_logic;
signal s_cmd_axi_awready		: std_logic;
signal s_cmd_axi_wdata			: std_logic_vector(CONF_CMD_AXI_DATA_WIDTH-1 downto 0);
signal s_cmd_axi_wstrb			: std_logic_vector(CONF_CMD_AXI_DATA_WIDTH/8-1 downto 0);
signal s_cmd_axi_wvalid			: std_logic;
signal s_cmd_axi_wready			: std_logic;
signal s_cmd_axi_bresp			: std_logic_vector(1 downto 0);
signal s_cmd_axi_bvalid			: std_logic;
signal s_cmd_axi_bready			: std_logic;
signal s_cmd_axi_araddr			: std_logic_vector(CONF_CMD_AXI_ADDR_WIDTH-1 downto 0);
signal s_cmd_axi_arprot			: std_logic_vector(2 downto 0);
signal s_cmd_axi_arvalid		: std_logic;
signal s_cmd_axi_arready		: std_logic;
signal s_cmd_axi_rdata			: std_logic_vector(CONF_CMD_AXI_DATA_WIDTH-1 downto 0);
signal s_cmd_axi_rresp			: std_logic_vector(1 downto 0);
signal s_cmd_axi_rvalid			: std_logic;
signal s_cmd_axi_rready			: std_logic;
signal s_data_axi_awaddr		: std_logic_vector(CONF_DATA_AXI_ADDR_WIDTH-1 downto 0);
signal s_data_axi_awprot		: std_logic_vector(2 downto 0);
signal s_data_axi_awvalid		: std_logic;
signal s_data_axi_awready		: std_logic;
signal s_data_axi_wdata			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH-1 downto 0);
signal s_data_axi_wstrb			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH/8-1 downto 0);
signal s_data_axi_wvalid		: std_logic;
signal s_data_axi_wready		: std_logic;
signal s_data_axi_bresp			: std_logic_vector(1 downto 0);
signal s_data_axi_bvalid		: std_logic;
signal s_data_axi_bready		: std_logic;
signal s_data_axi_araddr		: std_logic_vector(CONF_DATA_AXI_ADDR_WIDTH-1 downto 0);
signal s_data_axi_arprot		: std_logic_vector(2 downto 0);
signal s_data_axi_arvalid		: std_logic;
signal s_data_axi_arready		: std_logic;
signal s_data_axi_rdata			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH-1 downto 0);
signal s_data_axi_rresp			: std_logic_vector(1 downto 0);
signal s_data_axi_rvalid		: std_logic;
signal s_data_axi_rready		: std_logic;
signal halt_mem				: std_logic;
signal reset				: std_logic;
signal clock				: std_logic;
signal cmd_clock			: std_logic;
signal cmd_reset			: std_logic;
signal data_clock			: std_logic;
signal data_reset			: std_logic;

component external_memory_interface_pp is
    generic(
		C_CPU_DATA_WIDTH			: integer		:= 64;
		C_CPU_ADDR_WIDTH			: integer		:= 64;
		C_CMD_LOW_ADDR				: std_logic_vector	:= x"0002000000000000";
		C_CMD_HIGH_ADDR				: std_logic_vector	:= x"0002000000010000";
		C_CMD_AXI_ADDR_WIDTH			: integer		:= 64;
		C_CMD_AXI_DATA_WIDTH			: integer		:= 64;	
		C_DATA_LOW_ADDR				: std_logic_vector	:= x"0001000000000000";
		C_DATA_HIGH_ADDR			: std_logic_vector	:= x"0001000100000000";
		C_DATA_AXI_ADDR_WIDTH			: integer		:= 64;
		C_DATA_AXI_DATA_WIDTH			: integer		:= 64;
		C_IRQ_WORK_LEFT_ADDR			: std_logic_vector	:= x"0002000000000000";
		C_IRQ_SND_NUM_ADDR			: std_logic_vector	:= x"0002000000000008";
		C_IRQ_RCV_NUM_ADDR			: std_logic_vector	:= x"0002000000000010"
    );
    port(
        clk                     : in    std_logic;
        rstn                    : in    std_logic;
        halt                    : in    std_logic;

        data_addr               : in    std_logic_vector(C_CPU_ADDR_WIDTH-1 downto 0);
        data_din                : in    std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
        data_we                 : in    std_logic;
        data_re                 : in    std_logic;
        data_dout               : out   std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
        
	data_read_busy          : out std_logic;
        data_write_busy         : out std_logic;
        
	-- exceptions
        address_error_exc_load  : out std_logic;
        address_error_exc_store : out std_logic;
        data_bus_exc            : out std_logic;
    	
	-- to interrupt controller
	RCV_INT_NUM			: in std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	RCV_WORK_LEFT			: in std_logic;
	RCV_WORK_LEFT_RESPONSE		: out std_logic;
	RCV_WORK_LEFT_RESPONSE_WRITE	: out std_logic;
	SND_INT_NUM			: out std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	SND_INT_SIG			: out std_logic;
	
	-- AXI clock and reset
	cmd_axi_aclk      : in    std_logic; 
	cmd_axi_aresetn   : in    std_logic;
	data_axi_aclk     : in    std_logic;                                              
	data_axi_aresetn  : in    std_logic;
		
	-- Ports of Axi Master Bus Interface CMD_AXI
	cmd_axi_awaddr	: out std_logic_vector(C_CMD_AXI_ADDR_WIDTH-1 downto 0);
	cmd_axi_awprot	: out std_logic_vector(2 downto 0);
	cmd_axi_awvalid	: out std_logic;
	cmd_axi_awready	: in std_logic;
	cmd_axi_wdata	: out std_logic_vector(C_CMD_AXI_DATA_WIDTH-1 downto 0);
	cmd_axi_wstrb	: out std_logic_vector(C_CMD_AXI_DATA_WIDTH/8-1 downto 0);
	cmd_axi_wvalid	: out std_logic;
	cmd_axi_wready	: in std_logic;
	cmd_axi_bresp	: in std_logic_vector(1 downto 0);
	cmd_axi_bvalid	: in std_logic;
	cmd_axi_bready	: out std_logic;
	cmd_axi_araddr	: out std_logic_vector(C_CMD_AXI_ADDR_WIDTH-1 downto 0);
	cmd_axi_arprot	: out std_logic_vector(2 downto 0);
	cmd_axi_arvalid	: out std_logic;
	cmd_axi_arready	: in std_logic;
	cmd_axi_rdata	: in std_logic_vector(C_CMD_AXI_DATA_WIDTH-1 downto 0);
	cmd_axi_rresp	: in std_logic_vector(1 downto 0);
	cmd_axi_rvalid	: in std_logic;
	cmd_axi_rready	: out std_logic;
		
	-- Ports of Axi Master Bus Interface DATA_AXI
	data_axi_awaddr	: out std_logic_vector(C_DATA_AXI_ADDR_WIDTH-1 downto 0);
	data_axi_awprot	: out std_logic_vector(2 downto 0);
	data_axi_awvalid: out std_logic;
	data_axi_awready: in std_logic;
	data_axi_wdata	: out std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
	data_axi_wstrb	: out std_logic_vector(C_DATA_AXI_DATA_WIDTH/8-1 downto 0);
	data_axi_wvalid	: out std_logic;
	data_axi_wready	: in std_logic;
	data_axi_bresp	: in std_logic_vector(1 downto 0);
	data_axi_bvalid	: in std_logic;
	data_axi_bready	: out std_logic;
	data_axi_araddr	: out std_logic_vector(C_DATA_AXI_ADDR_WIDTH-1 downto 0);
	data_axi_arprot	: out std_logic_vector(2 downto 0);
	data_axi_arvalid: out std_logic;
	data_axi_arready: in std_logic;
	data_axi_rdata	: in std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
	data_axi_rresp	: in std_logic_vector(1 downto 0);
	data_axi_rvalid	: in std_logic;
	data_axi_rready	: out std_logic
    );
end component;

begin

uut: external_memory_interface_pp
    generic map(
		C_CPU_DATA_WIDTH	=> 64,
		C_CPU_ADDR_WIDTH	=> 64,
		C_CMD_LOW_ADDR		=> CONF_CMD_LOW_ADDR,
		C_CMD_HIGH_ADDR		=> CONF_CMD_HIGH_ADDR,
		C_CMD_AXI_ADDR_WIDTH	=> CONF_CMD_AXI_ADDR_WIDTH,
		C_CMD_AXI_DATA_WIDTH	=> CONF_CMD_AXI_DATA_WIDTH,
		C_DATA_LOW_ADDR		=> CONF_DATA_LOW_ADDR,		
		C_DATA_HIGH_ADDR	=> CONF_DATA_HIGH_ADDR,
		C_DATA_AXI_ADDR_WIDTH	=> CONF_DATA_AXI_ADDR_WIDTH,
		C_DATA_AXI_DATA_WIDTH	=> CONF_DATA_AXI_DATA_WIDTH,
		C_IRQ_WORK_LEFT_ADDR	=> CONF_IRQ_WORK_LEFT_ADDR,
		C_IRQ_SND_NUM_ADDR	=> CONF_IRQ_SND_NUM_ADDR,
		C_IRQ_RCV_NUM_ADDR	=> CONF_IRQ_RCV_NUM_ADDR
    )                                    
    port map(
        clk                   	=> clock,
        rstn                    => reset,
        halt                    => halt_mem,
        data_addr               => s_data_addr,
        data_din                => s_data_din,
        data_we                 => s_data_we,
        data_re                 => s_data_re,
        data_dout               => s_data_dout,
	data_read_busy          => s_data_read_busy,
        data_write_busy         => s_data_write_busy,
        address_error_exc_load  => s_address_error_exc_load,
        address_error_exc_store => s_address_error_exc_store,
        data_bus_exc            => s_data_bus_exc,
	RCV_INT_NUM			=> s_RCV_INT_NUM,
	RCV_WORK_LEFT			=> s_RCV_WORK_LEFT,
	RCV_WORK_LEFT_RESPONSE		=> s_RCV_WORK_LEFT_RESPONSE,
	RCV_WORK_LEFT_RESPONSE_WRITE	=> s_RCV_WORK_LEFT_RESPONSE_WRITE,
	SND_INT_NUM			=> s_SND_INT_NUM,
	SND_INT_SIG			=> s_SND_INT_SIG,
	cmd_axi_aclk      => cmd_clock, 
	cmd_axi_aresetn   => cmd_reset,
	data_axi_aclk     => data_clock,                                              
	data_axi_aresetn  => data_reset,
	cmd_axi_awaddr	=> s_cmd_axi_awaddr,
	cmd_axi_awprot	=> s_cmd_axi_awprot,
	cmd_axi_awvalid	=> s_cmd_axi_awvalid,
	cmd_axi_awready	=> s_cmd_axi_awready,
	cmd_axi_wdata	=> s_cmd_axi_wdata,
	cmd_axi_wstrb	=> s_cmd_axi_wstrb,
	cmd_axi_wvalid	=> s_cmd_axi_wvalid,
	cmd_axi_wready	=> s_cmd_axi_wready,
	cmd_axi_bresp	=> s_cmd_axi_bresp,
	cmd_axi_bvalid	=> s_cmd_axi_bvalid,
	cmd_axi_bready	=> s_cmd_axi_bready,
	cmd_axi_araddr	=> s_cmd_axi_araddr,
	cmd_axi_arprot	=> s_cmd_axi_arprot,
	cmd_axi_arvalid	=> s_cmd_axi_arvalid,
	cmd_axi_arready	=> s_cmd_axi_arready,
	cmd_axi_rdata	=> s_cmd_axi_rdata,
	cmd_axi_rresp	=> s_cmd_axi_rresp,
	cmd_axi_rvalid	=> s_cmd_axi_rvalid,
	cmd_axi_rready	=> s_cmd_axi_rready,
		
	-- Ports of Axi Master Bus Interface DATA_AXI
	data_axi_awaddr	 => s_data_axi_awaddr,
	data_axi_awprot	 => s_data_axi_awprot,
	data_axi_awvalid => s_data_axi_awvalid,
	data_axi_awready => s_data_axi_awready,
	data_axi_wdata	 => s_data_axi_wdata,
	data_axi_wstrb   => s_data_axi_wstrb,
	data_axi_wvalid	 => s_data_axi_wvalid,
	data_axi_wready	 => s_data_axi_wready,
	data_axi_bresp	 => s_data_axi_bresp,
	data_axi_bvalid	 => s_data_axi_bvalid,
	data_axi_bready	 => s_data_axi_bready,
	data_axi_araddr  => s_data_axi_araddr,
	data_axi_arprot	 => s_data_axi_arprot,
	data_axi_arvalid => s_data_axi_arvalid,
	data_axi_arready => s_data_axi_arready,
	data_axi_rdata	 => s_data_axi_rdata,
	data_axi_rresp	 => s_data_axi_rresp,
	data_axi_rvalid	 => s_data_axi_rvalid,
	data_axi_rready	 => s_data_axi_rready
   );

stimuli: process
begin
  reset <='0';
  cmd_reset <= '0';
  data_reset <= '0';
  halt_mem <= '0';
  s_data_addr <= x"0000000000000000";
  s_data_din <= x"0000000000000000";
  s_data_re <= '0';
  s_data_we <= '0';
  s_RCV_INT_NUM <= x"000000000001C1C1";
  s_RCV_WORK_LEFT	<= '1';
  s_cmd_axi_awready	<= '0';
  s_cmd_axi_wready	<= '0';
  s_cmd_axi_bresp	<= "00";
  s_cmd_axi_bvalid	<= '0';
  s_cmd_axi_arready	<= '0';
  s_cmd_axi_rdata	<= (others => '0');
  s_cmd_axi_rresp	<= "00";
  s_cmd_axi_rvalid	<= '0';
  s_data_axi_awready 	<= '0';
  s_data_axi_wready	<= '0';
  s_data_axi_bresp	<= "00";
  s_data_axi_bvalid	<= '0';
  s_data_axi_arready	<= '0';
  s_data_axi_rdata	<= (others => '0');
  s_data_axi_rresp	<= "00";
  s_data_axi_rvalid	<= '0';
  -- check if aql packets are in the queue
  wait for 25 ns;
  reset <= '1';
  cmd_reset <= '1';
  data_reset <= '1';
  wait for 5 ns;
  s_data_addr <= CONF_IRQ_WORK_LEFT_ADDR;
  s_data_re <= '1';
  s_data_we <= '0';
  -- send an interrupt to core number 10
  wait for 20 ns;
  s_data_addr <= CONF_IRQ_SND_NUM_ADDR;
  s_data_din <= x"000000000000000A";
  s_data_re <= '0';
  s_data_we <= '1';
  wait for 20 ns;
  -- get interrupt number
  s_data_addr <= CONF_IRQ_RCV_NUM_ADDR;
  s_data_din <= (others => '0');
  s_data_re <= '1';
  s_data_we <= '0';
  wait for 20 ns;
  -- read data from cmd AXI
  s_data_addr <= x"0002000000001000";
  s_data_din <= (others => '0');
  s_cmd_axi_rdata <= x"0000000000CAFFEE";
  s_data_re <= '1';
  s_data_we <= '0';
  if(s_cmd_axi_arvalid /= '1') then
  	wait until s_cmd_axi_arvalid = '1';
  end if;
  s_cmd_axi_rvalid <= '1';
  if(s_data_read_busy /= '0') then
  	wait until s_data_read_busy = '0';
	wait for 20 ns;
  end if;
  s_data_re <= '0';
  s_cmd_axi_rvalid <= '0';
  s_cmd_axi_rdata <= x"0000000000000000";
  wait for 40 ns;
  -- write data to cmd AXI
  s_data_addr <= x"0002000000001000";
  s_data_din <= x"00000000000DECAF";
  s_data_re <= '0';
  s_data_we <= '1';
  if(s_cmd_axi_awvalid /= '1') then
  	wait until s_cmd_axi_awvalid = '1';
  end if;
  s_cmd_axi_awready <= '1';
  if(s_cmd_axi_wvalid /= '1') then
  	wait until s_cmd_axi_wvalid = '1';
  end if;
  s_cmd_axi_wready <= '1';
  s_cmd_axi_bvalid <= '1';
  if(s_data_write_busy /= '0') then
  	wait until s_data_write_busy = '0';
	wait for 20 ns;
  end if;
  s_cmd_axi_bvalid <= '0';
  s_data_we <= '0';
  s_data_din <= x"0000000000000000";
  wait for 20 ns;
  -- read data from data AXI
  s_data_addr <= x"0001000000001000";
  s_data_din <= (others => '0');
  s_data_axi_rdata <= x"0000000000CAFFEE";
  s_data_re <= '1';
  s_data_we <= '0';
  if(s_data_axi_arvalid /= '1') then
  	wait until s_data_axi_arvalid = '1';
  end if;
  s_data_axi_rvalid <= '1';
  if(s_data_read_busy /= '0') then
  	wait until s_data_read_busy = '0';
	wait for 20 ns;
  end if;
  s_data_re <= '0';
  s_data_axi_rvalid <= '0';
  s_data_axi_rdata <= x"0000000000000000";
  wait for 40 ns;
  -- write data to data AXI
  s_data_addr <= x"0001000000001000";
  s_data_din <= x"00000000000DECAF";
  s_data_re <= '0';
  s_data_we <= '1';
  if(s_data_axi_awvalid /= '1') then
  	wait until s_data_axi_awvalid = '1';
  end if;
  s_data_axi_awready <= '1';
  if(s_data_axi_wvalid /= '1') then
  	wait until s_data_axi_wvalid = '1';
  end if;
  s_data_axi_wready <= '1';
  s_data_axi_bvalid <= '1';
  if(s_data_write_busy /= '0') then
  	wait until s_data_write_busy = '0';
	wait for 20 ns;
  end if;
  s_data_axi_bvalid <= '0';
  s_data_we <= '0';
  s_data_din <= x"0000000000000000";
  wait for 20 ns;
  -- try reading form invalid address
  s_data_addr <= x"0000000000001000";
  s_data_din <= x"000000000000DEAD";
  s_data_re <= '1';
  s_data_we <= '0';
  wait for 20 ns;
  -- try writing to invalid address
  s_data_addr <= x"0000000000001000";
  s_data_din <= x"000000000000DEAD";
  s_data_re <= '0';
  s_data_we <= '1';
  wait;
end process;

clock_P: process
begin
clock <= '0';
wait for 10 ns;
clock <= '1';
wait for 10 ns;
end process;

cmd_clock_P: process
begin
cmd_clock <= '0';
wait for 10 ns;
cmd_clock <= '1';
wait for 10 ns;
end process;

data_clock_P: process
begin
data_clock <= '0';
wait for 10 ns;
data_clock <= '1';
wait for 10 ns;
end process;

end behav;

