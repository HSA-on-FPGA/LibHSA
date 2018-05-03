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
	constant CONF_START_ADDRESS		: std_logic_vector(63 downto 0)	:= x"0003000000000000";
	constant CONF_EXCEPTION_HANDLER_ADDRESS	: std_logic_vector(63 downto 0) := x"0003000000000070";
        constant CONF_TIMER_INTERRUPT           : boolean := false;
        constant CONF_EXC_ADDRESS_ERROR_LOAD    : boolean := true;
        constant CONF_EXC_ADDRESS_ERROR_FETCH   : boolean := true;
        constant CONF_EXC_ADDRESS_ERROR_STORE   : boolean := true;
        constant CONF_EXC_INSTRUCTION_BUS_ERROR : boolean := true;
        constant CONF_EXC_DATA_BUS_ERROR        : boolean := true;
        constant CONF_EXC_SYSCALL               : boolean := false;
        constant CONF_EXC_BREAKPOINT            : boolean := false;
        constant CONF_EXC_RESERVED_INSTRUCTION  : boolean := false;
        constant CONF_EXC_COP_UNIMPLEMENTED     : boolean := false;
        constant CONF_EXC_ARITHMETIC_OVERFLOW   : boolean := false;
        constant CONF_EXC_TRAP                  : boolean := false;
        constant CONF_EXC_FLOATING_POINT        : boolean := false;
	constant CONF_CMD_LOW_ADDR		: std_logic_vector	:= x"0002000000000000";
	constant CONF_CMD_HIGH_ADDR		: std_logic_vector	:= x"0002000000100000";
	constant CONF_CMD_AXI_ADDR_WIDTH	: integer		:= 64;
	constant CONF_CMD_AXI_DATA_WIDTH	: integer		:= 64;	
	constant CONF_DATA_LOW_ADDR		: std_logic_vector	:= x"0001000000000000";
	constant CONF_DATA_HIGH_ADDR		: std_logic_vector	:= x"0001000100000000";
	constant CONF_DATA_AXI_ADDR_WIDTH	: integer		:= 64;
	constant CONF_DATA_AXI_DATA_WIDTH	: integer		:= 64;
	constant CONF_DATA_AXI_CACHEABLE_TXN	: boolean		:= false;
	constant CONF_IRQ_WORK_LEFT_ADDR	: std_logic_vector	:= x"0002000000000000";
	constant CONF_IRQ_SND_NUM_ADDR		: std_logic_vector	:= x"0002000000000008";
	constant CONF_IRQ_RCV_NUM_ADDR		: std_logic_vector	:= x"0002000000000010";
    	constant CONF_IMEM_LOW_ADDR       	: std_logic_vector	:= x"0003000000000000";
    	constant CONF_DMEM_LOW_ADDR       	: std_logic_vector 	:= x"0003000002000000";
end config;

use work.config.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;


entity tb_packet_processor_top IS
generic(
        G_MEM_NUM_4K_DATA_MEMS          : integer := 4;
        G_MEM_NUM_4K_INSTR_MEMS         : integer := 4;
	G_NUM_ACCELERATOR_CORES		: integer := 1;
        G_IMEM_INIT_FILE    		: string  := "";
        G_DMEM_INIT_FILE    		: string  := ""
);
end tb_packet_processor_top;

architecture behav of tb_packet_processor_top is
signal s_rcv_acc_irq_lanes		: std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
signal s_rcv_aql_irq			: std_logic;
signal s_rcv_dma_irq			: std_logic;
signal s_rcv_cpl_irq			: std_logic;
signal s_rcv_add_irq			: std_logic;
signal s_rcv_rem_irq			: std_logic;
signal s_rcv_acc_irq_lanes_ack		: std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
signal s_rcv_aql_irq_ack		: std_logic;
signal s_rcv_dma_irq_ack		: std_logic;
signal s_rcv_cpl_irq_ack		: std_logic;
signal s_rcv_add_irq_ack		: std_logic;
signal s_rcv_rem_irq_ack		: std_logic;
signal s_snd_acc_irq_lanes		: std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
signal s_snd_dma_irq			: std_logic;
signal s_snd_cpl_irq			: std_logic;
signal s_snd_add_irq			: std_logic;
signal s_snd_rem_irq			: std_logic;
signal s_snd_acc_irq_lanes_ack		: std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
signal s_snd_dma_irq_ack		: std_logic;
signal s_snd_cpl_irq_ack		: std_logic;
signal s_snd_add_irq_ack		: std_logic;
signal s_snd_rem_irq_ack		: std_logic;
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
signal s_data_axi_awid			: std_logic_vector(0 downto 0);
signal s_data_axi_awaddr		: std_logic_vector(CONF_DATA_AXI_ADDR_WIDTH-1 downto 0);
signal s_data_axi_awlen			: std_logic_vector(7 downto 0);
signal s_data_axi_awsize		: std_logic_vector(2 downto 0);
signal s_data_axi_awburst		: std_logic_vector(1 downto 0);
signal s_data_axi_awlock		: std_logic;
signal s_data_axi_awcache		: std_logic_vector(3 downto 0);
signal s_data_axi_awprot		: std_logic_vector(2 downto 0);
signal s_data_axi_awqos			: std_logic_vector(3 downto 0);
signal s_data_axi_awvalid		: std_logic;
signal s_data_axi_awready		: std_logic;
signal s_data_axi_wdata			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH-1 downto 0);
signal s_data_axi_wstrb			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH/8-1 downto 0);
signal s_data_axi_wlast			: std_logic;
signal s_data_axi_wvalid		: std_logic;
signal s_data_axi_wready		: std_logic;
signal s_data_axi_bid			: std_logic_vector(0 downto 0);
signal s_data_axi_bresp			: std_logic_vector(1 downto 0);
signal s_data_axi_bvalid		: std_logic;
signal s_data_axi_bready		: std_logic;
signal s_data_axi_arid			: std_logic_vector(0 downto 0);
signal s_data_axi_araddr		: std_logic_vector(CONF_DATA_AXI_ADDR_WIDTH-1 downto 0);
signal s_data_axi_arlen			: std_logic_vector(7 downto 0);
signal s_data_axi_arsize		: std_logic_vector(2 downto 0);
signal s_data_axi_arburst		: std_logic_vector(1 downto 0);
signal s_data_axi_arlock		: std_logic;
signal s_data_axi_arcache		: std_logic_vector(3 downto 0);
signal s_data_axi_arprot		: std_logic_vector(2 downto 0);
signal s_data_axi_arqos			: std_logic_vector(3 downto 0);
signal s_data_axi_arvalid		: std_logic;
signal s_data_axi_arready		: std_logic;
signal s_data_axi_rid			: std_logic_vector(0 downto 0);
signal s_data_axi_rdata			: std_logic_vector(CONF_DATA_AXI_DATA_WIDTH-1 downto 0);
signal s_data_axi_rresp			: std_logic_vector(1 downto 0);
signal s_data_axi_rlast			: std_logic;
signal s_data_axi_rvalid		: std_logic;
signal s_data_axi_rready		: std_logic;
signal halt				: std_logic;
signal reset				: std_logic;
signal clock				: std_logic;
signal cmd_clock			: std_logic;
signal cmd_reset			: std_logic;
signal data_clock			: std_logic;
signal data_reset			: std_logic;

component packet_processor_top is
    generic(
	G_START_ADDRESS			: std_logic_vector(63 downto 0)	:= x"0003000000000000";
	G_EXCEPTION_HANDLER_ADDRESS	: std_logic_vector(63 downto 0) := x"0003000000000070";
        -- interrupts
        G_TIMER_INTERRUPT               : boolean := false;
	G_NUM_ACCELERATOR_CORES		: integer := 1;
        -- exceptions
        G_EXC_ADDRESS_ERROR_LOAD        : boolean := true;
        G_EXC_ADDRESS_ERROR_FETCH       : boolean := true;
        G_EXC_ADDRESS_ERROR_STORE       : boolean := true;
        G_EXC_INSTRUCTION_BUS_ERROR     : boolean := true;
        G_EXC_DATA_BUS_ERROR            : boolean := true;
        G_EXC_SYSCALL                   : boolean := false;
        G_EXC_BREAKPOINT                : boolean := false;
        G_EXC_RESERVED_INSTRUCTION      : boolean := false;
        G_EXC_COP_UNIMPLEMENTED         : boolean := false;
        G_EXC_ARITHMETIC_OVERFLOW       : boolean := false;
        G_EXC_TRAP                      : boolean := false;
        G_EXC_FLOATING_POINT            : boolean := false;
        -- memory configuration
        G_MEM_NUM_4K_DATA_MEMS          : integer := 2;
        G_MEM_NUM_4K_INSTR_MEMS         : integer := 3;
	-- configuration addresses	
	C_CMD_LOW_ADDR			: std_logic_vector	:= x"0002000000000000";
	C_CMD_HIGH_ADDR			: std_logic_vector	:= x"0002000000100000";
	C_CMD_AXI_ADDR_WIDTH		: integer		:= 64;
	C_CMD_AXI_DATA_WIDTH		: integer		:= 64;	
	C_DATA_LOW_ADDR			: std_logic_vector	:= x"0001000000000000";
	C_DATA_HIGH_ADDR		: std_logic_vector	:= x"0001000100000000";
	C_DATA_AXI_ADDR_WIDTH		: integer		:= 64;
	C_DATA_AXI_DATA_WIDTH		: integer		:= 64;
	C_DATA_AXI_CACHEABLE_TXN	: boolean		:= false;
	C_IRQ_WORK_LEFT_ADDR		: std_logic_vector	:= x"0002000000000000";
	C_IRQ_SND_NUM_ADDR		: std_logic_vector	:= x"0002000000000008";
	C_IRQ_RCV_NUM_ADDR		: std_logic_vector	:= x"0002000000000010";
    	C_IMEM_LOW_ADDR       		: std_logic_vector	:= x"0003000000000000";
        C_IMEM_INIT_FILE    		: string 		:= "";
    	C_DMEM_LOW_ADDR       		: std_logic_vector 	:= x"0003000002000000";
        C_DMEM_INIT_FILE    		: string 		:= ""
    );
    port(
        tp_clk                  : in  std_logic;
        tp_rstn                 : in  std_logic;
        tp_halt                 : in  std_logic;
    	--ingoing interrupts
	rcv_acc_irq_lanes	: in std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
	rcv_aql_irq		: in std_logic;
	rcv_dma_irq		: in std_logic;
	rcv_cpl_irq		: in std_logic;
	rcv_add_irq		: in std_logic;
	rcv_rem_irq		: in std_logic;
	rcv_acc_irq_lanes_ack	: out std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
	rcv_aql_irq_ack		: out std_logic;
	rcv_dma_irq_ack		: out std_logic;
	rcv_cpl_irq_ack		: out std_logic;
	rcv_add_irq_ack		: out std_logic;
	rcv_rem_irq_ack		: out std_logic;
        -- outgoing interrupts
        snd_acc_irq_lanes	: out std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
        snd_dma_irq		: out std_logic;
        snd_cpl_irq		: out std_logic;
        snd_add_irq		: out std_logic;
        snd_rem_irq		: out std_logic;
        snd_acc_irq_lanes_ack	: in std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
        snd_dma_irq_ack		: in std_logic;
        snd_cpl_irq_ack		: in std_logic;
        snd_add_irq_ack		: in std_logic;
        snd_rem_irq_ack		: in std_logic;
	
	-- axi interfaces
	cmd_axi_aclk      : in    std_logic; 
	cmd_axi_aresetn   : in    std_logic;
	data_axi_aclk     : in    std_logic;                                              
	data_axi_aresetn  : in    std_logic;
	
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
end component;

component burst_memory is
    generic(
		C_LOW_ADDR			: std_logic_vector	:= x"0001000000000000";
		C_AXI_ADDR_WIDTH		: integer		:= 64;
		C_AXI_DATA_WIDTH		: integer		:= 64;	
		C_NUM_1K_BRAM_BLOCKS		: integer		:= 4
    );
    port(
        clk             : in  std_logic;
        rstn            : in  std_logic;
	
    	S_AXI_ACLK    	: in  std_logic;
    	S_AXI_ARESETN   : in  std_logic;
	S_AXI_AWID	: in  std_logic_vector(0 downto 0);
	S_AXI_AWADDR	: in  std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	S_AXI_AWLEN	: in  std_logic_vector(7 downto 0);
	S_AXI_AWSIZE	: in  std_logic_vector(2 downto 0);
	S_AXI_AWBURST	: in  std_logic_vector(1 downto 0);
	S_AXI_AWLOCK	: in  std_logic;
	S_AXI_AWCACHE	: in  std_logic_vector(3 downto 0);
	S_AXI_AWPROT	: in  std_logic_vector(2 downto 0);
	S_AXI_AWQOS	: in  std_logic_vector(3 downto 0);
	S_AXI_AWREGION	: in  std_logic_vector(3 downto 0);
	S_AXI_AWUSER	: in  std_logic_vector(-1 downto 0);
	S_AXI_AWVALID	: in  std_logic;
	S_AXI_AWREADY	: out std_logic;
	S_AXI_WDATA	: in  std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	S_AXI_WSTRB	: in  std_logic_vector((C_AXI_DATA_WIDTH/8)-1 downto 0);
	S_AXI_WLAST	: in  std_logic;
	S_AXI_WUSER	: in  std_logic_vector(-1 downto 0);
	S_AXI_WVALID	: in  std_logic;
	S_AXI_WREADY	: out std_logic;
	S_AXI_BID	: out std_logic_vector(0 downto 0);
	S_AXI_BRESP	: out std_logic_vector(1 downto 0);
	S_AXI_BUSER	: out std_logic_vector(-1 downto 0);
	S_AXI_BVALID	: out std_logic;
	S_AXI_BREADY	: in  std_logic;
	S_AXI_ARID	: in  std_logic_vector(0 downto 0);
	S_AXI_ARADDR	: in  std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	S_AXI_ARLEN	: in  std_logic_vector(7 downto 0);
	S_AXI_ARSIZE	: in  std_logic_vector(2 downto 0);
	S_AXI_ARBURST	: in  std_logic_vector(1 downto 0);
	S_AXI_ARLOCK	: in  std_logic;
	S_AXI_ARCACHE	: in  std_logic_vector(3 downto 0);
	S_AXI_ARPROT	: in  std_logic_vector(2 downto 0);
	S_AXI_ARQOS	: in  std_logic_vector(3 downto 0);
	S_AXI_ARREGION	: in  std_logic_vector(3 downto 0);
	S_AXI_ARUSER	: in  std_logic_vector(-1 downto 0);
	S_AXI_ARVALID	: in  std_logic;
	S_AXI_ARREADY	: out std_logic;
	S_AXI_RID	: out std_logic_vector(0 downto 0);
	S_AXI_RDATA	: out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	S_AXI_RRESP	: out std_logic_vector(1 downto 0);
	S_AXI_RLAST	: out std_logic;
	S_AXI_RUSER	: out std_logic_vector(-1 downto 0);
	S_AXI_RVALID	: out std_logic;
	S_AXI_RREADY	: in  std_logic
    );
end component;

component generic_memory is
    generic(
		C_LOW_ADDR				: std_logic_vector	:= x"0001000000000000";
		C_AXI_ADDR_WIDTH			: integer		:= 64;
		C_AXI_DATA_WIDTH			: integer		:= 64;	
		C_NUM_1K_BRAM_BLOCKS			: integer		:= 4;
		C_BRAM_LINE_WIDTH			: integer		:= 32
    );
    port(
        clk             : in  std_logic;
        rstn            : in  std_logic;
	
    	S_AXI_ACLK    	: in std_logic;
    	S_AXI_ARESETN   : in std_logic;
    	S_AXI_AWADDR    : in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    	S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
    	S_AXI_AWVALID   : in std_logic;
    	S_AXI_AWREADY   : out std_logic;
    	S_AXI_WDATA    	: in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    	S_AXI_WSTRB    	: in std_logic_vector((C_AXI_DATA_WIDTH/8)-1 downto 0);
    	S_AXI_WVALID    : in std_logic;
    	S_AXI_WREADY    : out std_logic;
    	S_AXI_BRESP    	: out std_logic_vector(1 downto 0);
    	S_AXI_BVALID    : out std_logic;
    	S_AXI_BREADY    : in std_logic;
    	S_AXI_ARADDR    : in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    	S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
    	S_AXI_ARVALID   : in std_logic;
    	S_AXI_ARREADY   : out std_logic;
    	S_AXI_RDATA     : out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    	S_AXI_RRESP     : out std_logic_vector(1 downto 0);
    	S_AXI_RVALID    : out std_logic;
    	S_AXI_RREADY    : in  std_logic
    );
end component;

procedure handshake_controller(signal i_snd_irq: in std_logic; signal o_snd_irq_ack: out std_logic; 
			       signal o_rcv_irq: out std_logic; signal i_rcv_irq_ack: in std_logic; constant TIMEOUT: in time) is
begin
  o_snd_irq_ack <= '0';
  o_rcv_irq <= '0';
  if(i_snd_irq = '1') then
    wait for 20 ns;
    o_snd_irq_ack <= '1';
    wait until i_snd_irq = '0';
    o_snd_irq_ack <= '0';
    wait for TIMEOUT;
    -- controller finished the transfer
    o_rcv_irq <= '1';
    wait until i_rcv_irq_ack = '1';
    o_rcv_irq <= '0';
  end if;
end procedure;

procedure single_handshake_controller(signal irq: in std_logic; signal irq_ack: out std_logic) is
begin
  irq_ack <= '0';
  if(irq = '1') then
    wait for 20 ns;
    irq_ack <= '1';
    wait until irq = '0';
    irq_ack <= '0';
  end if;
end procedure;

begin

uut: packet_processor_top
    generic map(
	G_START_ADDRESS			=> CONF_START_ADDRESS,			
	G_EXCEPTION_HANDLER_ADDRESS	=> CONF_EXCEPTION_HANDLER_ADDRESS,	
        -- interrupts                     
        G_TIMER_INTERRUPT               => CONF_TIMER_INTERRUPT,               
	G_NUM_ACCELERATOR_CORES		=> G_NUM_ACCELERATOR_CORES,		
        -- exceptions                    
        G_EXC_ADDRESS_ERROR_LOAD        => CONF_EXC_ADDRESS_ERROR_LOAD,        
        G_EXC_ADDRESS_ERROR_FETCH       => CONF_EXC_ADDRESS_ERROR_FETCH,       
        G_EXC_ADDRESS_ERROR_STORE       => CONF_EXC_ADDRESS_ERROR_STORE,       
        G_EXC_INSTRUCTION_BUS_ERROR     => CONF_EXC_INSTRUCTION_BUS_ERROR,     
        G_EXC_DATA_BUS_ERROR            => CONF_EXC_DATA_BUS_ERROR,            
        G_EXC_SYSCALL                   => CONF_EXC_SYSCALL,                   
        G_EXC_BREAKPOINT                => CONF_EXC_BREAKPOINT,                
        G_EXC_RESERVED_INSTRUCTION      => CONF_EXC_RESERVED_INSTRUCTION,      
        G_EXC_COP_UNIMPLEMENTED         => CONF_EXC_COP_UNIMPLEMENTED,         
        G_EXC_ARITHMETIC_OVERFLOW       => CONF_EXC_ARITHMETIC_OVERFLOW,       
        G_EXC_TRAP                      => CONF_EXC_TRAP,                      
        G_EXC_FLOATING_POINT            => CONF_EXC_FLOATING_POINT,            
        -- memory configuration          
        G_MEM_NUM_4K_DATA_MEMS          => G_MEM_NUM_4K_DATA_MEMS,          
        G_MEM_NUM_4K_INSTR_MEMS         => G_MEM_NUM_4K_INSTR_MEMS,         
	-- configuration addresses	 
	C_CMD_LOW_ADDR			=> CONF_CMD_LOW_ADDR,			
	C_CMD_HIGH_ADDR			=> CONF_CMD_HIGH_ADDR,			
	C_CMD_AXI_ADDR_WIDTH		=> CONF_CMD_AXI_ADDR_WIDTH,		
	C_CMD_AXI_DATA_WIDTH		=> CONF_CMD_AXI_DATA_WIDTH,		
	C_DATA_LOW_ADDR			=> CONF_DATA_LOW_ADDR,			
	C_DATA_HIGH_ADDR		=> CONF_DATA_HIGH_ADDR,		
	C_DATA_AXI_ADDR_WIDTH		=> CONF_DATA_AXI_ADDR_WIDTH,		
	C_DATA_AXI_DATA_WIDTH		=> CONF_DATA_AXI_DATA_WIDTH,		
	C_DATA_AXI_CACHEABLE_TXN	=> CONF_DATA_AXI_CACHEABLE_TXN,
	C_IRQ_WORK_LEFT_ADDR		=> CONF_IRQ_WORK_LEFT_ADDR,		
	C_IRQ_SND_NUM_ADDR		=> CONF_IRQ_SND_NUM_ADDR,
	C_IRQ_RCV_NUM_ADDR		=> CONF_IRQ_RCV_NUM_ADDR,		
    	C_IMEM_LOW_ADDR       		=> CONF_IMEM_LOW_ADDR,       		
        C_IMEM_INIT_FILE    		=> G_IMEM_INIT_FILE,
    	C_DMEM_LOW_ADDR       		=> CONF_DMEM_LOW_ADDR,
        C_DMEM_INIT_FILE    		=> G_DMEM_INIT_FILE
    )                                    
    port map(
        tp_clk              	=> clock,    
        tp_rstn             	=> reset,    
        tp_halt             	=> halt,    
        --ingoing interrupts
        rcv_acc_irq_lanes	=> s_rcv_acc_irq_lanes,	
        rcv_aql_irq		=> s_rcv_aql_irq,		
        rcv_dma_irq		=> s_rcv_dma_irq,		
        rcv_cpl_irq		=> s_rcv_cpl_irq,		
        rcv_add_irq		=> s_rcv_add_irq,		
        rcv_rem_irq		=> s_rcv_rem_irq,		
	rcv_acc_irq_lanes_ack	=> s_rcv_acc_irq_lanes_ack,
	rcv_aql_irq_ack		=> s_rcv_aql_irq_ack,
	rcv_dma_irq_ack		=> s_rcv_dma_irq_ack,
	rcv_cpl_irq_ack		=> s_rcv_cpl_irq_ack,
	rcv_add_irq_ack		=> s_rcv_add_irq_ack,
	rcv_rem_irq_ack		=> s_rcv_rem_irq_ack,
        -- outgoing interrupts 
        snd_acc_irq_lanes	=> s_snd_acc_irq_lanes,	
        snd_dma_irq		=> s_snd_dma_irq,
        snd_cpl_irq		=> s_snd_cpl_irq,
        snd_add_irq		=> s_snd_add_irq,
        snd_rem_irq		=> s_snd_rem_irq,
        snd_acc_irq_lanes_ack	=> s_snd_acc_irq_lanes_ack,
        snd_dma_irq_ack		=> s_snd_dma_irq_ack,
        snd_cpl_irq_ack		=> s_snd_cpl_irq_ack,
        snd_add_irq_ack		=> s_snd_add_irq_ack,
        snd_rem_irq_ack		=> s_snd_rem_irq_ack,
	-- AXI	
	cmd_axi_aclk    => cmd_clock,
        cmd_axi_aresetn => cmd_reset,
        data_axi_aclk   => data_clock,
        data_axi_aresetn=> data_reset,

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

	data_axi_awid	=> s_data_axi_awid,
        data_axi_awaddr	=> s_data_axi_awaddr,	
        data_axi_awlen	=> s_data_axi_awlen,	
        data_axi_awsize	=> s_data_axi_awsize,	
        data_axi_awburst=> s_data_axi_awburst,	
        data_axi_awlock	=> s_data_axi_awlock,	
        data_axi_awcache=> s_data_axi_awcache,	
        data_axi_awprot	=> s_data_axi_awprot,	
        data_axi_awqos	=> s_data_axi_awqos,	
        data_axi_awvalid=> s_data_axi_awvalid,	
        data_axi_awready=> s_data_axi_awready,	
        data_axi_wdata	=> s_data_axi_wdata,	
        data_axi_wstrb	=> s_data_axi_wstrb,	
        data_axi_wlast	=> s_data_axi_wlast,	
        data_axi_wvalid	=> s_data_axi_wvalid,	
        data_axi_wready	=> s_data_axi_wready,
        data_axi_bid	=> s_data_axi_bid,	
        data_axi_bresp	=> s_data_axi_bresp,	
        data_axi_bvalid	=> s_data_axi_bvalid,	
        data_axi_bready	=> s_data_axi_bready,
        data_axi_arid	=> s_data_axi_arid,	
        data_axi_araddr	=> s_data_axi_araddr,	
        data_axi_arlen	=> s_data_axi_arlen,	
        data_axi_arsize	=> s_data_axi_arsize,	
        data_axi_arburst=> s_data_axi_arburst,	
        data_axi_arlock	=> s_data_axi_arlock,	
        data_axi_arcache=> s_data_axi_arcache,	
        data_axi_arprot	=> s_data_axi_arprot,	
        data_axi_arqos	=> s_data_axi_arqos,	
        data_axi_arvalid=> s_data_axi_arvalid,	
        data_axi_arready=> s_data_axi_arready,	
        data_axi_rid	=> s_data_axi_rid,
        data_axi_rdata	=> s_data_axi_rdata,	
        data_axi_rresp	=> s_data_axi_rresp,	
        data_axi_rlast	=> s_data_axi_rlast,	
        data_axi_rvalid	=> s_data_axi_rvalid,	
        data_axi_rready	=> s_data_axi_rready
   );

inst_dram: entity work.burst_memory
    generic map(
		C_LOW_ADDR		=> CONF_DATA_LOW_ADDR,
		C_AXI_ADDR_WIDTH	=> CONF_DATA_AXI_ADDR_WIDTH,
		C_AXI_DATA_WIDTH	=> CONF_DATA_AXI_DATA_WIDTH,
		C_NUM_1K_BRAM_BLOCKS	=> 4096
    )
    port map(
        clk       	=> clock,
        rstn            => reset,
	
	S_AXI_ACLK	=> data_clock,
	S_AXI_ARESETN	=> data_reset,
	S_AXI_AWID	=> s_data_axi_awid,
	S_AXI_AWADDR	=> s_data_axi_awaddr,	
	S_AXI_AWLEN	=> s_data_axi_awlen,	
	S_AXI_AWSIZE	=> s_data_axi_awsize,	
	S_AXI_AWBURST	=> s_data_axi_awburst,	
	S_AXI_AWLOCK	=> s_data_axi_awlock,	
	S_AXI_AWCACHE	=> s_data_axi_awcache,	
	S_AXI_AWPROT	=> s_data_axi_awprot,	
	S_AXI_AWQOS	=> s_data_axi_awqos,	
	S_AXI_AWREGION  => (others => '0'),
	S_AXI_AWVALID	=> s_data_axi_awvalid,	
	S_AXI_AWREADY	=> s_data_axi_awready,	
	S_AXI_WDATA	=> s_data_axi_wdata,	
	S_AXI_WSTRB	=> s_data_axi_wstrb,	
	S_AXI_WLAST	=> s_data_axi_wlast,	
	S_AXI_WVALID	=> s_data_axi_wvalid,	
	S_AXI_WREADY	=> s_data_axi_wready,
	S_AXI_BID	=> s_data_axi_bid,	
	S_AXI_BRESP	=> s_data_axi_bresp,	
	S_AXI_BVALID	=> s_data_axi_bvalid,	
	S_AXI_BREADY	=> s_data_axi_bready,
	S_AXI_ARID	=> s_data_axi_arid,	
	S_AXI_ARADDR	=> s_data_axi_araddr,	
	S_AXI_ARLEN	=> s_data_axi_arlen,	
	S_AXI_ARSIZE	=> s_data_axi_arsize,	
	S_AXI_ARBURST	=> s_data_axi_arburst,	
	S_AXI_ARLOCK	=> s_data_axi_arlock,	
	S_AXI_ARCACHE	=> s_data_axi_arcache,	
	S_AXI_ARPROT	=> s_data_axi_arprot,	
	S_AXI_ARQOS	=> s_data_axi_arqos,
	S_AXI_ARREGION  => (others => '0'),
	S_AXI_ARVALID	=> s_data_axi_arvalid,	
	S_AXI_ARREADY	=> s_data_axi_arready,	
	S_AXI_RID	=> s_data_axi_rid,
	S_AXI_RDATA	=> s_data_axi_rdata,	
	S_AXI_RRESP	=> s_data_axi_rresp,	
	S_AXI_RLAST	=> s_data_axi_rlast,	
	S_AXI_RVALID	=> s_data_axi_rvalid,	
	S_AXI_RREADY	=> s_data_axi_rready
);

inst_config: generic_memory
    generic map(
		C_LOW_ADDR		=> CONF_CMD_LOW_ADDR,	   
		C_AXI_ADDR_WIDTH	=> CONF_CMD_AXI_ADDR_WIDTH,
		C_AXI_DATA_WIDTH	=> CONF_CMD_AXI_DATA_WIDTH,
		C_NUM_1K_BRAM_BLOCKS	=> (G_NUM_ACCELERATOR_CORES+1)*4,
		C_BRAM_LINE_WIDTH	=> 64
    )
    port map(
        clk       	=> clock,
        rstn            => reset,
	
	S_AXI_ACLK	=> cmd_clock,
	S_AXI_ARESETN	=> cmd_reset,
	S_AXI_AWADDR	=> s_cmd_axi_awaddr,   
	S_AXI_AWPROT	=> s_cmd_axi_awprot,
	S_AXI_AWVALID	=> s_cmd_axi_awvalid,
	S_AXI_AWREADY	=> s_cmd_axi_awready,
	S_AXI_WDATA	=> s_cmd_axi_wdata,
	S_AXI_WSTRB	=> s_cmd_axi_wstrb,
	S_AXI_WVALID	=> s_cmd_axi_wvalid,
	S_AXI_WREADY	=> s_cmd_axi_wready,
	S_AXI_BRESP	=> s_cmd_axi_bresp,
	S_AXI_BVALID	=> s_cmd_axi_bvalid,
	S_AXI_BREADY	=> s_cmd_axi_bready,
	S_AXI_ARADDR	=> s_cmd_axi_araddr,
	S_AXI_ARPROT	=> s_cmd_axi_arprot,
	S_AXI_ARVALID	=> s_cmd_axi_arvalid,
	S_AXI_ARREADY	=> s_cmd_axi_arready,
	S_AXI_RDATA	=> s_cmd_axi_rdata,
	S_AXI_RRESP	=> s_cmd_axi_rresp,
	S_AXI_RVALID	=> s_cmd_axi_rvalid,
	S_AXI_RREADY	=> s_cmd_axi_rready
);

-- DMA controller
handshake_controller(s_snd_dma_irq, s_snd_dma_irq_ack, s_rcv_dma_irq, s_rcv_dma_irq_ack, 100 us);
-- completion_signal controller
handshake_controller(s_snd_cpl_irq, s_snd_cpl_irq_ack, s_rcv_cpl_irq, s_rcv_cpl_irq_ack, 1 us);
-- add core controller
single_handshake_controller(s_snd_add_irq, s_snd_add_irq_ack);
-- remove core controller
single_handshake_controller(s_snd_rem_irq, s_snd_rem_irq_ack);
-- accelerator cores
simulate_cores: for i in 0 to G_NUM_ACCELERATOR_CORES-1 generate
  handshake_controller(s_snd_acc_irq_lanes(i), s_snd_acc_irq_lanes_ack(i), s_rcv_acc_irq_lanes(i), s_rcv_acc_irq_lanes_ack(i), 10 us);
end generate;

stimuli: process
begin
  reset 	<= '0';
  cmd_reset 	<= '0';
  data_reset 	<= '0';
  halt 		<= '1';
  -- for the moment no interrupts arrive
  s_rcv_aql_irq	<= '0';
  s_rcv_add_irq <= '0';
  s_rcv_rem_irq <= '0';
  wait for 25 ns;
  reset <= '1';
  cmd_reset <= '1';
  data_reset <= '1';
  wait for 5 ns;
  halt <= '0';

  -- TPC sends a signal that aql packets have arrived
  -- PP starts dispatching jobs when the work bit is set
  wait for 25 ns;
  s_rcv_aql_irq <= '1';
  wait for 20 ns;
  s_rcv_aql_irq <= '0';
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

