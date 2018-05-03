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

entity memory_controller_fcp is
    generic(
		C_CPU_INSTR_WIDTH			: integer		:= 32;
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
		C_CPU_HALT_NUM_ADDR			: std_logic_vector	:= x"0002000000000000";
		C_IRQ_SND_NUM_ADDR			: std_logic_vector	:= x"0002000000000008";
    		C_IMEM_LOW_ADDR       			: std_logic_vector	:= x"0003000000000000";
    		C_IMEM_BRAM_SIZE       			: integer 		:= 16348;
		C_IMEM_INIT_FILE  			: string 		:= "";
    		C_DMEM_LOW_ADDR       			: std_logic_vector 	:= x"0003000002000000";
    		C_DMEM_BRAM_SIZE       			: integer 		:= 16348;
		C_DMEM_INIT_FILE  			: string 		:= ""
    );
    port(
        clk                     : in    std_logic;
        rstn                    : in    std_logic;
        halt                    : in    std_logic;

	-- connections to MIPS
	mips_inst_addr  	: in    std_logic_vector(C_CPU_ADDR_WIDTH-1 downto 0);
	mips_inst_re    	: in    std_logic;
	mips_inst_dout  	: out   std_logic_vector(C_CPU_INSTR_WIDTH-1 downto 0);
	mips_data_addr  	: in    std_logic_vector(C_CPU_ADDR_WIDTH-1 downto 0);
	mips_data_re    	: in    std_logic;
	mips_data_we    	: in    std_logic;
	mips_data_din   	: in    std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	mips_data_dout  	: out   std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	mips_inst_read_busy     : out   std_logic;
	mips_data_read_busy     : out   std_logic;
	mips_data_write_busy    : out   std_logic;

	-- exceptions to MIPS
	mips_address_error_exc_load     : out std_logic;
	mips_address_error_exc_fetch    : out std_logic;
	mips_address_error_exc_store    : out std_logic;
	mips_instruction_bus_exc        : out std_logic;
	mips_data_bus_exc               : out std_logic; 
    	
	-- to interrupt controller
	SND_INT_NUM			: out std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	SND_INT_SIG			: out std_logic;
	
	-- to halt logic
	SND_CPU_HALT_NUM		: out std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	SND_CPU_HALT_SIG		: out std_logic;
	
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
end entity;

architecture behav of memory_controller_fcp is

component external_memory_interface_fcp is
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
		C_CPU_HALT_NUM_ADDR			: std_logic_vector	:= x"0002000000000000";
		C_IRQ_SND_NUM_ADDR			: std_logic_vector	:= x"0002000000000008"
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
	SND_INT_NUM			: out std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	SND_INT_SIG			: out std_logic;
	
	-- to halt logic
	SND_CPU_HALT_NUM		: out std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	SND_CPU_HALT_SIG		: out std_logic;
	
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
end component external_memory_interface_fcp;

component mem_router is
Generic(
    ADDR_SIZE       : integer := 32;
    IMEM_ADDR       : std_logic_vector := x"00000000";
    IMEM_SIZE       : integer := 16#1000#;
    IMEM_WIDTH      : integer := 32;
    IMEM_INIT_FILE  : string := "";
    DMEM_ADDR       : std_logic_vector := x"00000000";
    DMEM_SIZE       : integer := 16#1000#;
    DMEM_WIDTH      : integer := 32;
    DMEM_INIT_FILE  : string := ""
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
end component mem_router;

	signal s_forward_addr                        : std_logic_vector(C_CPU_ADDR_WIDTH-1 downto 0);
	signal s_forward_din                         : std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	signal s_forward_dout                        : std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	signal s_forward_re                          : std_logic;
	signal s_forward_we                          : std_logic;
	signal s_forward_read_busy                   : std_logic;
	signal s_forward_write_busy                  : std_logic;
	signal s_forward_address_error_exc_load      : std_logic;
	signal s_forward_address_error_exc_store     : std_logic;
	signal s_forward_data_bus_exc                : std_logic;

begin

external_memory_interface_inst: external_memory_interface_fcp
    generic map(
		C_CPU_DATA_WIDTH	=> C_CPU_DATA_WIDTH,
		C_CPU_ADDR_WIDTH	=> C_CPU_ADDR_WIDTH,
		C_CMD_LOW_ADDR		=> C_CMD_LOW_ADDR,
		C_CMD_HIGH_ADDR		=> C_CMD_HIGH_ADDR,		
		C_CMD_AXI_ADDR_WIDTH	=> C_CMD_AXI_ADDR_WIDTH,	
		C_CMD_AXI_DATA_WIDTH	=> C_CMD_AXI_DATA_WIDTH,	
		C_DATA_LOW_ADDR		=> C_DATA_LOW_ADDR,		
		C_DATA_HIGH_ADDR	=> C_DATA_HIGH_ADDR,	
		C_DATA_AXI_ADDR_WIDTH	=> C_DATA_AXI_ADDR_WIDTH,	
		C_DATA_AXI_DATA_WIDTH	=> C_DATA_AXI_DATA_WIDTH,	
		C_CPU_HALT_NUM_ADDR	=> C_CPU_HALT_NUM_ADDR,	
		C_IRQ_SND_NUM_ADDR	=> C_IRQ_SND_NUM_ADDR
    )
    port map(
        clk                     => clk,
        rstn                    => rstn,
        halt                    => halt,

        data_addr               => s_forward_addr,
        data_din                => s_forward_din,
        data_we                 => s_forward_we,
        data_re                 => s_forward_re,
        data_dout               => s_forward_dout, 
	data_read_busy          => s_forward_read_busy,
        data_write_busy         => s_forward_write_busy,
        
	-- exceptions
        address_error_exc_load  => s_forward_address_error_exc_load,
        address_error_exc_store => s_forward_address_error_exc_store,
        data_bus_exc            => s_forward_data_bus_exc,
    	
	-- to interrupt controller
	SND_INT_NUM			=> SND_INT_NUM,
	SND_INT_SIG			=> SND_INT_SIG,
	
	-- to halt logic
	SND_CPU_HALT_NUM		=> SND_CPU_HALT_NUM,
	SND_CPU_HALT_SIG		=> SND_CPU_HALT_SIG,
	
	-- AXI clock and reset
	cmd_axi_aclk      => cmd_axi_aclk,
	cmd_axi_aresetn   => cmd_axi_aresetn, 
	data_axi_aclk     => data_axi_aclk,                                              
	data_axi_aresetn  => data_axi_aresetn,
		
	-- Ports of Axi Master Bus Interface CMD_AXI
	cmd_axi_awaddr	=> cmd_axi_awaddr,	
	cmd_axi_awprot	=> cmd_axi_awprot,	
	cmd_axi_awvalid	=> cmd_axi_awvalid,	
	cmd_axi_awready	=> cmd_axi_awready,	
	cmd_axi_wdata	=> cmd_axi_wdata,	
	cmd_axi_wstrb	=> cmd_axi_wstrb,	
	cmd_axi_wvalid	=> cmd_axi_wvalid,	
	cmd_axi_wready	=> cmd_axi_wready,	
	cmd_axi_bresp	=> cmd_axi_bresp,	
	cmd_axi_bvalid	=> cmd_axi_bvalid,	
	cmd_axi_bready	=> cmd_axi_bready,	
	cmd_axi_araddr	=> cmd_axi_araddr,	
	cmd_axi_arprot	=> cmd_axi_arprot,	
	cmd_axi_arvalid	=> cmd_axi_arvalid,	
	cmd_axi_arready	=> cmd_axi_arready,	
	cmd_axi_rdata	=> cmd_axi_rdata,	
	cmd_axi_rresp	=> cmd_axi_rresp,	
	cmd_axi_rvalid	=> cmd_axi_rvalid,
	cmd_axi_rready	=> cmd_axi_rready,	
		
	-- Ports of Axi Master Bus Interface DATA_AXI
	data_axi_awaddr	=> data_axi_awaddr,	
	data_axi_awprot	=> data_axi_awprot,	
	data_axi_awvalid=> data_axi_awvalid,
	data_axi_awready=> data_axi_awready,
	data_axi_wdata	=> data_axi_wdata,	
	data_axi_wstrb	=> data_axi_wstrb,	
	data_axi_wvalid	=> data_axi_wvalid,	
	data_axi_wready	=> data_axi_wready,	
	data_axi_bresp	=> data_axi_bresp,	
	data_axi_bvalid	=> data_axi_bvalid,	
	data_axi_bready	=> data_axi_bready,	
	data_axi_araddr	=> data_axi_araddr,	
	data_axi_arprot	=> data_axi_arprot,	
	data_axi_arvalid=> data_axi_arvalid,
	data_axi_arready=> data_axi_arready,
	data_axi_rdata	=> data_axi_rdata,	
	data_axi_rresp	=> data_axi_rresp,	
	data_axi_rvalid	=> data_axi_rvalid,	
	data_axi_rready	=> data_axi_rready
    );

mem_router_inst: mem_router
generic map(
    ADDR_SIZE       	=> C_CPU_ADDR_WIDTH,
    IMEM_ADDR       	=> C_IMEM_LOW_ADDR,
    IMEM_SIZE       	=> C_IMEM_BRAM_SIZE,
    IMEM_WIDTH      	=> C_CPU_INSTR_WIDTH,
    IMEM_INIT_FILE      => C_IMEM_INIT_FILE,
    DMEM_ADDR       	=> C_DMEM_LOW_ADDR,
    DMEM_SIZE       	=> C_DMEM_BRAM_SIZE,
    DMEM_WIDTH      	=> C_CPU_DATA_WIDTH,
    DMEM_INIT_FILE      => C_DMEM_INIT_FILE
)
port map(
    clk            => clk, 
    resetn         => rstn,
    halt           => halt,
    
    -- connections to MIPS
    mips_inst_addr 	=>  mips_inst_addr, 	
    mips_inst_re    	=>  mips_inst_re,    	
    mips_inst_dout  	=>  mips_inst_dout,  	
    mips_data_addr  	=>  mips_data_addr,  	
    mips_data_re    	=>  mips_data_re,    	
    mips_data_we    	=>  mips_data_we,    	
    mips_data_din   	=>  mips_data_din,   	
    mips_data_dout  	=>  mips_data_dout,  	
    mips_inst_read_busy =>  mips_inst_read_busy,     
    mips_data_read_busy	=>  mips_data_read_busy,	
    mips_data_write_busy=>  mips_data_write_busy,
    
    -- exceptions to MIPS
    mips_address_error_exc_load    	=> mips_address_error_exc_load, 
    mips_address_error_exc_fetch	=> mips_address_error_exc_fetch,
    mips_address_error_exc_store    	=> mips_address_error_exc_store,
    mips_instruction_bus_exc        	=> mips_instruction_bus_exc,    
    mips_data_bus_exc               	=> mips_data_bus_exc,           
    
    -- connection to memory controller
    memctrl_addr                 	=> s_forward_addr,
    memctrl_din                         => s_forward_dout,
    memctrl_dout                        => s_forward_din,
    memctrl_re                          => s_forward_re,
    memctrl_we                          => s_forward_we,
    memctrl_read_busy                   => s_forward_read_busy,
    memctrl_write_busy                  => s_forward_write_busy,
    memctrl_address_error_exc_load      => s_forward_address_error_exc_load,
    memctrl_address_error_exc_store     => s_forward_address_error_exc_store,
    memctrl_data_bus_exc                => s_forward_data_bus_exc
);

end architecture;
