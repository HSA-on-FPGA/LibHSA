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
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity external_memory_interface_pp is
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
		C_DATA_AXI_CACHEABLE_TXN		: boolean		:= false;
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
	data_axi_awid	: out std_logic_vector(0 downto 0);
	data_axi_awaddr	: out std_logic_vector(C_DATA_AXI_ADDR_WIDTH-1 downto 0);
	data_axi_awlen	: out std_logic_vector(7 downto 0);
	data_axi_awsize	: out std_logic_vector(2 downto 0);
	data_axi_awburst: out std_logic_vector(1 downto 0);
	data_axi_awlock	: out std_logic;
	data_axi_awcache: out std_logic_vector(3 downto 0);
	data_axi_awprot	: out std_logic_vector(2 downto 0);
	data_axi_awqos	: out std_logic_vector(3 downto 0);
	data_axi_awvalid: out std_logic;
	data_axi_awready: in  std_logic;
	data_axi_wdata	: out std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
	data_axi_wstrb	: out std_logic_vector(C_DATA_AXI_DATA_WIDTH/8-1 downto 0);
	data_axi_wlast	: out std_logic;
	data_axi_wvalid	: out std_logic;
	data_axi_wready	: in  std_logic;
	data_axi_bid	: in  std_logic_vector(0 downto 0);
	data_axi_bresp	: in  std_logic_vector(1 downto 0);
	data_axi_bvalid	: in  std_logic;
	data_axi_bready	: out std_logic;
	data_axi_arid	: out std_logic_vector(0 downto 0);
	data_axi_araddr	: out std_logic_vector(C_DATA_AXI_ADDR_WIDTH-1 downto 0);
	data_axi_arlen	: out std_logic_vector(7 downto 0);
	data_axi_arsize	: out std_logic_vector(2 downto 0);
	data_axi_arburst: out std_logic_vector(1 downto 0);
	data_axi_arlock	: out std_logic;
	data_axi_arcache: out std_logic_vector(3 downto 0);
	data_axi_arprot	: out std_logic_vector(2 downto 0);
	data_axi_arqos	: out std_logic_vector(3 downto 0);
	data_axi_arvalid: out std_logic;
	data_axi_arready: in  std_logic;
	data_axi_rid	: in  std_logic_vector(0 downto 0);
	data_axi_rdata	: in  std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
	data_axi_rresp	: in  std_logic_vector(1 downto 0);
	data_axi_rlast	: in  std_logic;
	data_axi_rvalid	: in  std_logic;
	data_axi_rready	: out std_logic
    );
end entity;

architecture behav of external_memory_interface_pp is

component axi_lite_master is
	generic (
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 32
	);
	port (
		CPU_ADDR 	: in std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		CPU_WDATA 	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		CPU_RDATA 	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		CPU_ACCESS_MODE : in std_logic;
		INIT_AXI_TXN	: in std_logic;
		ERROR		: out std_logic;
		TXN_DONE	: out std_logic;
		M_AXI_ACLK	: in std_logic;
		M_AXI_ARESETN	: in std_logic;
		M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
		M_AXI_AWVALID	: out std_logic;
		M_AXI_AWREADY	: in std_logic;
		M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		M_AXI_WVALID	: out std_logic;
		M_AXI_WREADY	: in std_logic;
		M_AXI_BRESP	: in std_logic_vector(1 downto 0);
		M_AXI_BVALID	: in std_logic;
		M_AXI_BREADY	: out std_logic;
		M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
		M_AXI_ARVALID	: out std_logic;
		M_AXI_ARREADY	: in std_logic;
		M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_RRESP	: in std_logic_vector(1 downto 0);
		M_AXI_RVALID	: in std_logic;
		M_AXI_RREADY	: out std_logic
	);
end component axi_lite_master;

component axi_full_master is
	generic (
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 32;
		C_M_AXI_CACHEABLE_TXN	: boolean	:= false
	);
	port (
		CPU_ADDR : in std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		CPU_WDATA : in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		CPU_RDATA : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		CPU_ACCESS_MODE : in std_logic;
		INIT_AXI_TXN	: in std_logic;
		ERROR	: out std_logic;
		TXN_DONE	: out std_logic;
		M_AXI_ACLK	: in std_logic;
		M_AXI_ARESETN	: in std_logic;
		M_AXI_AWID	: out std_logic_vector(0 downto 0);
		M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_AWLEN	: out std_logic_vector(7 downto 0);
		M_AXI_AWSIZE	: out std_logic_vector(2 downto 0);
		M_AXI_AWBURST	: out std_logic_vector(1 downto 0);
		M_AXI_AWLOCK	: out std_logic;
		M_AXI_AWCACHE	: out std_logic_vector(3 downto 0);
		M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
		M_AXI_AWQOS	: out std_logic_vector(3 downto 0);
		M_AXI_AWVALID	: out std_logic;
		M_AXI_AWREADY	: in std_logic;
		M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		M_AXI_WLAST	: out std_logic;
		M_AXI_WVALID	: out std_logic;
		M_AXI_WREADY	: in std_logic;
		M_AXI_BID	: in std_logic_vector(0 downto 0);
		M_AXI_BRESP	: in std_logic_vector(1 downto 0);
		M_AXI_BVALID	: in std_logic;
		M_AXI_BREADY	: out std_logic;
		M_AXI_ARID	: out std_logic_vector(0 downto 0);
		M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_ARLEN	: out std_logic_vector(7 downto 0);
		M_AXI_ARSIZE	: out std_logic_vector(2 downto 0);
		M_AXI_ARBURST	: out std_logic_vector(1 downto 0);
		M_AXI_ARLOCK	: out std_logic;
		M_AXI_ARCACHE	: out std_logic_vector(3 downto 0);
		M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
		M_AXI_ARQOS	: out std_logic_vector(3 downto 0);
		M_AXI_ARVALID	: out std_logic;
		M_AXI_ARREADY	: in std_logic;
		M_AXI_RID	: in std_logic_vector(0 downto 0);
		M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_RRESP	: in std_logic_vector(1 downto 0);
		M_AXI_RLAST	: in std_logic;
		M_AXI_RVALID	: in std_logic;
		M_AXI_RREADY	: out std_logic
	);
end component axi_full_master;

    signal s_read_busy     : std_logic;
    signal s_write_busy    : std_logic;

-- requested memory location
    type mem_location is (NONE,WORK_LEFT,SND_IRQ,RCV_IRQ_NUM,CMD_AXI,DATA_AXI);
    signal access_location : mem_location;
    signal access_location_delayed : mem_location;

-- AXI Master state
    type axi_state is (READY,TRANSFER_ALIGNED);
    signal cmd_state : axi_state;
    signal data_state : axi_state;

-- CPU/AXI interface
    signal a_cmd_addr	: std_logic_vector(C_CPU_ADDR_WIDTH-1 downto 0);
    signal a_cmd_dw	: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_cmd_we	: std_logic;
    signal a_cmd_re	: std_logic;
    signal a_cmd_dr	: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_cmd_dr_del	: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_cmd_done   : std_logic;
    signal a_data_addr	: std_logic_vector(C_CPU_ADDR_WIDTH-1 downto 0);
    signal a_data_dw	: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_data_we	: std_logic;
    signal a_data_re	: std_logic;
    signal a_data_dr	: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_data_dr_del: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_data_done  : std_logic;
    
-- AXI busy and error signals
    signal a_cmd_bus_err	: std_logic;
    signal a_data_bus_err	: std_logic;

-- signals from and to axi masters
    signal s_cmd_axi_addr 	: std_logic_vector(C_CMD_AXI_ADDR_WIDTH-1 downto 0);
    signal s_cmd_axi_wdata 	: std_logic_vector(C_CMD_AXI_DATA_WIDTH-1 downto 0);
    signal s_cmd_axi_rdata 	: std_logic_vector(C_CMD_AXI_DATA_WIDTH-1 downto 0);
    signal s_cmd_axi_accessmode : std_logic;
    signal s_init_cmd_axi_txn 	: std_logic;
    signal s_cmd_axi_error 	: std_logic;
    signal s_cmd_axi_txn_done 	: std_logic;
    signal s_data_axi_addr 	: std_logic_vector(C_DATA_AXI_ADDR_WIDTH-1 downto 0);
    signal s_data_axi_wdata 	: std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
    signal s_data_axi_rdata 	: std_logic_vector(C_DATA_AXI_DATA_WIDTH-1 downto 0);
    signal s_data_axi_accessmode: std_logic;
    signal s_init_data_axi_txn 	: std_logic;
    signal s_data_axi_error 	: std_logic;
    signal s_data_axi_txn_done 	: std_logic;

begin

-- Instantiation of Axi Bus Interface CMD_AXI
external_memory_interface_cmd_axi_inst : axi_lite_master
	generic map (
		C_M_AXI_ADDR_WIDTH	=> C_CMD_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_CMD_AXI_DATA_WIDTH
	)
	port map (
		CPU_ADDR 	=> s_cmd_axi_addr,
		CPU_WDATA 	=> s_cmd_axi_wdata,
		CPU_RDATA 	=> s_cmd_axi_rdata,
		CPU_ACCESS_MODE => s_cmd_axi_accessmode,
		INIT_AXI_TXN	=> s_init_cmd_axi_txn,
		ERROR		=> s_cmd_axi_error,
		TXN_DONE	=> s_cmd_axi_txn_done,
		M_AXI_ACLK	=> cmd_axi_aclk,   
		M_AXI_ARESETN	=> cmd_axi_aresetn,
		M_AXI_AWADDR	=> cmd_axi_awaddr,
		M_AXI_AWPROT	=> cmd_axi_awprot,
		M_AXI_AWVALID	=> cmd_axi_awvalid,
		M_AXI_AWREADY	=> cmd_axi_awready,
		M_AXI_WDATA	=> cmd_axi_wdata,
		M_AXI_WSTRB	=> cmd_axi_wstrb,
		M_AXI_WVALID	=> cmd_axi_wvalid,
		M_AXI_WREADY	=> cmd_axi_wready,
		M_AXI_BRESP	=> cmd_axi_bresp,
		M_AXI_BVALID	=> cmd_axi_bvalid,
		M_AXI_BREADY	=> cmd_axi_bready,
		M_AXI_ARADDR	=> cmd_axi_araddr,
		M_AXI_ARPROT	=> cmd_axi_arprot,
		M_AXI_ARVALID	=> cmd_axi_arvalid,
		M_AXI_ARREADY	=> cmd_axi_arready,
		M_AXI_RDATA	=> cmd_axi_rdata,
		M_AXI_RRESP	=> cmd_axi_rresp,
		M_AXI_RVALID	=> cmd_axi_rvalid,
		M_AXI_RREADY	=> cmd_axi_rready
	);

-- Instantiation of Axi Bus Interface DATA_AXI
external_memory_interface_data_axi_inst : axi_full_master
	generic map (
		C_M_AXI_ADDR_WIDTH	=> C_DATA_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_DATA_AXI_DATA_WIDTH,
		C_M_AXI_CACHEABLE_TXN	=> C_DATA_AXI_CACHEABLE_TXN
	)
	port map (
		CPU_ADDR 	=> s_data_axi_addr,
		CPU_WDATA 	=> s_data_axi_wdata,
		CPU_RDATA 	=> s_data_axi_rdata,
		CPU_ACCESS_MODE => s_data_axi_accessmode,
		INIT_AXI_TXN	=> s_init_data_axi_txn,
		ERROR		=> s_data_axi_error,
		TXN_DONE	=> s_data_axi_txn_done,
		M_AXI_ACLK	=> data_axi_aclk,   
		M_AXI_ARESETN	=> data_axi_aresetn,
		M_AXI_AWID	=> data_axi_awid,
                M_AXI_AWADDR	=> data_axi_awaddr,	
                M_AXI_AWLEN	=> data_axi_awlen,	
                M_AXI_AWSIZE	=> data_axi_awsize,	
                M_AXI_AWBURST	=> data_axi_awburst,	
                M_AXI_AWLOCK	=> data_axi_awlock,	
                M_AXI_AWCACHE	=> data_axi_awcache,	
                M_AXI_AWPROT	=> data_axi_awprot,	
                M_AXI_AWQOS	=> data_axi_awqos,	
                M_AXI_AWVALID	=> data_axi_awvalid,	
                M_AXI_AWREADY	=> data_axi_awready,	
                M_AXI_WDATA	=> data_axi_wdata,	
                M_AXI_WSTRB	=> data_axi_wstrb,	
                M_AXI_WLAST	=> data_axi_wlast,	
                M_AXI_WVALID	=> data_axi_wvalid,	
                M_AXI_WREADY	=> data_axi_wready,
                M_AXI_BID	=> data_axi_bid,	
                M_AXI_BRESP	=> data_axi_bresp,	
                M_AXI_BVALID	=> data_axi_bvalid,	
                M_AXI_BREADY	=> data_axi_bready,
                M_AXI_ARID	=> data_axi_arid,	
                M_AXI_ARADDR	=> data_axi_araddr,	
                M_AXI_ARLEN	=> data_axi_arlen,	
                M_AXI_ARSIZE	=> data_axi_arsize,	
                M_AXI_ARBURST	=> data_axi_arburst,	
                M_AXI_ARLOCK	=> data_axi_arlock,	
                M_AXI_ARCACHE	=> data_axi_arcache,	
                M_AXI_ARPROT	=> data_axi_arprot,	
                M_AXI_ARQOS	=> data_axi_arqos,	
                M_AXI_ARVALID	=> data_axi_arvalid,	
                M_AXI_ARREADY	=> data_axi_arready,	
                M_AXI_RID	=> data_axi_rid,
                M_AXI_RDATA	=> data_axi_rdata,	
                M_AXI_RRESP	=> data_axi_rresp,	
                M_AXI_RLAST	=> data_axi_rlast,	
                M_AXI_RVALID	=> data_axi_rvalid,	
                M_AXI_RREADY	=> data_axi_rready
	);

data_read_busy 	<= s_read_busy and (not a_cmd_done) and (not a_data_done);
data_write_busy <= s_write_busy and (not a_cmd_done) and (not a_data_done);
data_bus_exc 	<= a_cmd_bus_err or a_data_bus_err;

address_check: process(data_addr)
begin
	-- set signals to prevent latches
	access_location <= NONE;

	-- access to WORK_LEFT register in interrupt controller
	if(data_addr = C_IRQ_WORK_LEFT_ADDR) then
		access_location <= WORK_LEFT;
	-- send interrupt
	elsif(data_addr = C_IRQ_SND_NUM_ADDR) then
		access_location <= SND_IRQ;
	-- get number of interrupt device
	elsif(data_addr = C_IRQ_RCV_NUM_ADDR) then
		access_location <= RCV_IRQ_NUM;
	-- address points to CMD AXI bus
	elsif((data_addr >= C_CMD_LOW_ADDR) AND (data_addr < C_CMD_HIGH_ADDR)) then
		access_location <= CMD_AXI;
	-- address points to DATA AXI bus
	elsif((data_addr >= C_DATA_LOW_ADDR) AND (data_addr < C_DATA_HIGH_ADDR)) then
		access_location <= DATA_AXI;
	-- address is invalid
	else
		access_location <= NONE;
	end if;
end process;

distribute_data: process(access_location,data_addr,data_re,data_we,data_din)
begin
        -- prevent latches
	RCV_WORK_LEFT_RESPONSE 		<= data_din(0);
	RCV_WORK_LEFT_RESPONSE_WRITE 	<= '0';
	SND_INT_SIG 			<= '0';
	SND_INT_NUM 			<= std_logic_vector(resize(unsigned(data_din),SND_INT_NUM'length));
	a_cmd_addr 	<= (others => '0');
	a_cmd_dw 	<= (others => '0');
	a_data_addr 	<= (others => '0');
	a_data_dw 	<= (others => '0');
	a_cmd_re 	<= '0';
	a_data_re 	<= '0';
	a_cmd_we 	<= '0';
	a_data_we 	<= '0';
	s_read_busy     <= '0';
	s_write_busy    <= '0';
        address_error_exc_load  <= '0';
        address_error_exc_store <= '0';

	if(data_re = '1') then
		-- send interrupt
		if(access_location = SND_IRQ) then
			-- cannot be read
        		address_error_exc_load  <= '1';
		-- address points to CMD AXI bus
		elsif(access_location = CMD_AXI) then
			s_read_busy <= '1';
			a_cmd_addr <= data_addr;
			a_cmd_re <= '1';
		-- address points to DATA AXI bus
		elsif(access_location = DATA_AXI) then
			s_read_busy <= '1';
			a_data_addr <= data_addr;
			a_data_re <= '1';
		-- else address is invalid or no memory operation performed
		elsif(access_location /= WORK_LEFT and access_location /= RCV_IRQ_NUM) then
        		address_error_exc_load  <= '1';
		end if;
	elsif(data_we = '1') then
		-- access to WORK_LEFT register in interrupt controller
		if(access_location = WORK_LEFT) then
			-- default value is correct value
			RCV_WORK_LEFT_RESPONSE_WRITE <= '1'; -- only one cycle
		-- send interrupt
		elsif(access_location = SND_IRQ) then
			-- default value is correct value
			SND_INT_SIG <= '1'; -- only one cycle
		-- get number of interrupt device
		elsif(access_location = RCV_IRQ_NUM) then
			-- cannot be written
        		address_error_exc_store <= '1';
		-- address points to CMD AXI bus
		elsif(access_location = CMD_AXI) then
			s_write_busy <= '1';
			a_cmd_addr <= data_addr;
			a_cmd_dw <= data_din;
			a_cmd_we <= '1';
		-- address points to DATA AXI bus
		elsif(access_location = DATA_AXI) then
			s_write_busy <= '1';
			a_data_addr <= data_addr;
			a_data_dw <= data_din;
			a_data_we <= '1';
		-- else address is invalid or no memory operation performed
		else
        		address_error_exc_store  <= '1';
		end if;	
	end if;
end process;

collect_data: process(access_location_delayed,RCV_WORK_LEFT,RCV_INT_NUM,a_cmd_dr_del,a_data_dr_del)
begin
	-- access to WORK_LEFT register in interrupt controller
	if(access_location_delayed = WORK_LEFT) then
		data_dout    <= (others => '0');
		data_dout(0) <= RCV_WORK_LEFT;
	-- get number of interrupt device
	elsif(access_location_delayed = RCV_IRQ_NUM) then
		data_dout <= RCV_INT_NUM;
	-- address points to CMD AXI bus
	elsif(access_location_delayed = CMD_AXI) then
		data_dout <= a_cmd_dr_del;
	-- address points to DATA AXI bus
	elsif(access_location_delayed = DATA_AXI) then
		data_dout <= a_data_dr_del;
	-- else address is invalid or no memory operation performed
	else
		data_dout <= (others => '0');
	end if;
end process;

manage_cmd_axi: process(clk)
begin
	if(rising_edge(clk)) then
		if(rstn='0') then
			a_cmd_dr 		<= (others => '0');
			cmd_state 		<= READY;
        		a_cmd_bus_err           <= '0';
			a_cmd_done              <= '0';
			s_init_cmd_axi_txn 	<= '0';
			s_cmd_axi_accessmode 	<= '0';
			s_cmd_axi_wdata 	<= (others => '0');
   			s_cmd_axi_addr 		<= (others => '0');
		else
			a_cmd_dr 		<= a_cmd_dr;
			cmd_state 		<= READY;
        		a_cmd_bus_err           <= '0';
			a_cmd_done              <= '0';
			s_init_cmd_axi_txn 	<= '0';
			s_cmd_axi_accessmode 	<= '0';
			s_cmd_axi_wdata 	<= (others => '0');
   			s_cmd_axi_addr 		<= (others => '0');
			case cmd_state is
				when READY =>
   					s_cmd_axi_addr <= std_logic_vector(resize(unsigned(a_cmd_addr),s_cmd_axi_addr'length));
					if(a_cmd_we='1' and a_cmd_done='0') then
						cmd_state <= TRANSFER_ALIGNED;
						s_cmd_axi_accessmode <= '1';
						s_cmd_axi_wdata <= std_logic_vector(resize(unsigned(a_cmd_dw),s_cmd_axi_wdata'length));
					elsif(a_cmd_re='1' and a_cmd_done='0') then
						cmd_state <= TRANSFER_ALIGNED;
						s_cmd_axi_accessmode <= '0';
					else
						cmd_state <= READY;
					end if;
				when TRANSFER_ALIGNED =>
   					s_cmd_axi_addr <= std_logic_vector(resize(unsigned(a_cmd_addr),s_cmd_axi_addr'length));
					if(s_cmd_axi_error = '1') then
						cmd_state <= READY;
						a_cmd_bus_err <= s_cmd_axi_error;
					elsif(s_cmd_axi_txn_done = '1') then
						cmd_state <= READY;
						s_init_cmd_axi_txn <= '0';
						a_cmd_done <= '1';
    						if(a_cmd_re='1') then 
							a_cmd_dr <= std_logic_vector(resize(unsigned(s_cmd_axi_rdata),a_cmd_dr'length));
						end if;
					else
						cmd_state <= TRANSFER_ALIGNED;
						s_init_cmd_axi_txn <= '1';
    						if(a_cmd_we='1') then
							s_cmd_axi_accessmode <= '1';
							s_cmd_axi_wdata <= std_logic_vector(resize(unsigned(a_cmd_dw),s_cmd_axi_wdata'length));
						elsif(a_cmd_re='1') then
							s_cmd_axi_accessmode <= '0';
						end if;
					end if;
				when others =>
					cmd_state <= READY;
			end case;
		end if;
	end if;
end process;

manage_data_axi: process(clk)
begin
	if(rising_edge(clk)) then
		if(rstn='0') then
			a_data_dr 		<= (others => '0');
			data_state 		<= READY;
        		a_data_bus_err          <= '0';
			a_data_done             <= '0';
			s_init_data_axi_txn 	<= '0';
			s_data_axi_accessmode 	<= '0';
			s_data_axi_wdata 	<= (others => '0');
   			s_data_axi_addr 	<= (others => '0');
		else
			a_data_dr 		<= a_data_dr;
			data_state 		<= READY;
        		a_data_bus_err          <= '0';
			a_data_done             <= '0';
			s_init_data_axi_txn 	<= '0';
			s_data_axi_accessmode 	<= '0';
			s_data_axi_wdata 	<= (others => '0');
   			s_data_axi_addr 	<= (others => '0');
			case data_state is
				when READY =>
   					s_data_axi_addr <= std_logic_vector(resize(unsigned(a_data_addr),s_data_axi_addr'length));
    					if(a_data_we='1' and a_data_done='0') then
						data_state <= TRANSFER_ALIGNED;
						s_data_axi_accessmode <= '1';
						s_data_axi_wdata <= std_logic_vector(resize(unsigned(a_data_dw),s_data_axi_wdata'length));
					elsif(a_data_re='1' and a_data_done='0') then
						data_state <= TRANSFER_ALIGNED;
						s_data_axi_accessmode <= '0';
					else
						data_state <= READY;
					end if;
				when TRANSFER_ALIGNED =>
   					s_data_axi_addr <= std_logic_vector(resize(unsigned(a_data_addr),s_data_axi_addr'length));
					if(s_data_axi_error = '1') then
						data_state <= READY;
						a_data_bus_err <= s_data_axi_error;
					elsif(s_data_axi_txn_done = '1') then
						data_state <= READY;
						s_init_data_axi_txn <= '0';
						a_data_done <= '1';
    						if(a_data_re='1') then 
							a_data_dr <= std_logic_vector(resize(unsigned(s_data_axi_rdata),a_data_dr'length));
						end if;
					else
						data_state <= TRANSFER_ALIGNED;
						s_init_data_axi_txn <= '1';
    						if(a_data_we='1') then
							s_data_axi_accessmode <= '1';
							s_data_axi_wdata <= std_logic_vector(resize(unsigned(a_data_dw),s_data_axi_wdata'length));
						elsif(a_data_re='1') then
							s_data_axi_accessmode <= '0';
						end if;
					end if;
				when others =>
					data_state <= READY;
			end case;
		end if;
	end if;
end process;

delay_access_location: process(clk)
begin
	if(rising_edge(clk)) then
		if(rstn='0') then
			access_location_delayed <= NONE;
		else
			access_location_delayed <= access_location;
		end if;
	end if;
end process;

delay_axi_output: process(clk)
begin
	if(rising_edge(clk)) then
		if(rstn='0') then
			a_cmd_dr_del  <= (others => '0');
			a_data_dr_del <= (others => '0');
		else
			a_cmd_dr_del  <= a_cmd_dr;
			a_data_dr_del <= a_data_dr;
		end if;
	end if;
end process;

end architecture;

