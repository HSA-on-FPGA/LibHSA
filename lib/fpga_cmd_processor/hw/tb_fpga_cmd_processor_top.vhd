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
use STD.textio.all;

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
	constant CONF_CMD_HIGH_ADDR		: std_logic_vector	:= x"0004000200000000";
	constant CONF_CMD_AXI_ADDR_WIDTH	: integer		:= 64;
	constant CONF_CMD_AXI_DATA_WIDTH	: integer		:= 64;	
	constant CONF_DATA_LOW_ADDR		: std_logic_vector	:= x"0001000000000000";
	constant CONF_DATA_HIGH_ADDR		: std_logic_vector	:= x"0001000100000000";
	constant CONF_DATA_AXI_ADDR_WIDTH	: integer		:= 64;
	constant CONF_DATA_AXI_DATA_WIDTH	: integer		:= 64;
	constant CONF_CPU_HALT_NUM_ADDR		: std_logic_vector	:= x"0002000000000000";
	constant CONF_IRQ_SND_NUM_ADDR		: std_logic_vector	:= x"0002000000000008";
    	constant CONF_IMEM_LOW_ADDR       	: std_logic_vector	:= x"0003000000000000";
    	constant CONF_DMEM_LOW_ADDR       	: std_logic_vector 	:= x"0003000002000000";
    	constant CONF_IMEM_INIT_FILE    	: string 		:= "../../sw/core/vsim/instr.hex";
    	constant CONF_DMEM_INIT_FILE    	: string 		:= "../../sw/core/vsim/data.hex";
end config;

use work.config.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;


entity tb_fpga_cmd_processor_top IS
generic(
        G_MEM_NUM_4K_DATA_MEMS          : integer := 4;
        G_MEM_NUM_4K_INSTR_MEMS         : integer := 4;
	G_NUM_ACCELERATOR_CORES		: integer := 1
);
end tb_fpga_cmd_processor_top;

architecture behav of tb_fpga_cmd_processor_top is
signal s_rcv_dma_irq			: std_logic;
signal s_rcv_cpl_irq			: std_logic;
signal s_rcv_add_irq			: std_logic;
signal s_rcv_rem_irq			: std_logic;
signal s_rcv_dma_irq_ack		: std_logic;
signal s_rcv_cpl_irq_ack		: std_logic;
signal s_rcv_add_irq_ack		: std_logic;
signal s_rcv_rem_irq_ack		: std_logic;
signal s_snd_aql_irq			: std_logic;
signal s_snd_dma_irq			: std_logic;
signal s_snd_cpl_irq			: std_logic;
signal s_snd_add_irq			: std_logic;
signal s_snd_rem_irq			: std_logic;
signal s_snd_aql_irq_ack		: std_logic;
signal s_snd_dma_irq_ack		: std_logic;
signal s_snd_cpl_irq_ack		: std_logic;
signal s_snd_add_irq_ack		: std_logic;
signal s_snd_rem_irq_ack		: std_logic;
signal s_packet_processor_halt		: std_logic;
signal s_accelerator_core_halt_lanes	: std_logic_vector(G_NUM_ACCELERATOR_CORES-1 downto 0);
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
signal halt				: std_logic;
signal reset				: std_logic;
signal clock				: std_logic;
signal cmd_clock			: std_logic;
signal cmd_reset			: std_logic;
signal data_clock			: std_logic;
signal data_reset			: std_logic;

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

procedure oneway_handshake(signal i_snd_irq: in std_logic; signal o_snd_irq_ack: out std_logic) is
begin
  o_snd_irq_ack <= '0';
  if(i_snd_irq = '1') then
    wait for 20 ns;
    o_snd_irq_ack <= '1';
    wait until i_snd_irq = '0';
    o_snd_irq_ack <= '0';
  end if;
end procedure;

begin

uut: work.fpga_cmd_processor_top
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
	C_CPU_HALT_NUM_ADDR		=> CONF_CPU_HALT_NUM_ADDR,		
	C_IRQ_SND_NUM_ADDR		=> CONF_IRQ_SND_NUM_ADDR,
    	C_IMEM_LOW_ADDR       		=> CONF_IMEM_LOW_ADDR,       		
        C_IMEM_INIT_FILE    		=> CONF_IMEM_INIT_FILE,
    	C_DMEM_LOW_ADDR       		=> CONF_DMEM_LOW_ADDR,	
        C_DMEM_INIT_FILE    		=> CONF_DMEM_INIT_FILE
    )                                    
    port map(
        tp_clk              	=> clock,    
        tp_rstn             	=> reset,    
        --ingoing interrupts
        rcv_dma_irq		=> s_rcv_dma_irq,		
        rcv_cpl_irq		=> s_rcv_cpl_irq,		
        rcv_add_irq		=> s_rcv_add_irq,		
        rcv_rem_irq		=> s_rcv_rem_irq,		
	rcv_dma_irq_ack		=> s_rcv_dma_irq_ack,
	rcv_cpl_irq_ack		=> s_rcv_cpl_irq_ack,
	rcv_add_irq_ack		=> s_rcv_add_irq_ack,
	rcv_rem_irq_ack		=> s_rcv_rem_irq_ack,
        -- outgoing interrupts 
        snd_aql_irq		=> s_snd_aql_irq,
        snd_dma_irq		=> s_snd_dma_irq,
        snd_cpl_irq		=> s_snd_cpl_irq,
        snd_add_irq		=> s_snd_add_irq,
        snd_rem_irq		=> s_snd_rem_irq,
        snd_aql_irq_ack		=> s_snd_aql_irq_ack,
        snd_dma_irq_ack		=> s_snd_dma_irq_ack,
        snd_cpl_irq_ack		=> s_snd_cpl_irq_ack,
        snd_add_irq_ack		=> s_snd_add_irq_ack,
        snd_rem_irq_ack		=> s_snd_rem_irq_ack,
	
	pp_halt => s_packet_processor_halt,		
        ac_halt_lanes => s_accelerator_core_halt_lanes,	

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

inst_dram: generic_memory
    generic map(
		C_LOW_ADDR		=> CONF_DATA_LOW_ADDR,	   
		C_AXI_ADDR_WIDTH	=> CONF_DATA_AXI_ADDR_WIDTH,
		C_AXI_DATA_WIDTH	=> CONF_DATA_AXI_DATA_WIDTH,
		C_NUM_1K_BRAM_BLOCKS	=> 512,
		C_BRAM_LINE_WIDTH	=> 64
    )
    port map(
        clk       	=> clock,
        rstn            => reset,
	
	S_AXI_ACLK	=> data_clock,
	S_AXI_ARESETN	=> data_reset,
	S_AXI_AWADDR	=> s_data_axi_awaddr,   
	S_AXI_AWPROT	=> s_data_axi_awprot,
	S_AXI_AWVALID	=> s_data_axi_awvalid,
	S_AXI_AWREADY	=> s_data_axi_awready,
	S_AXI_WDATA	=> s_data_axi_wdata,
	S_AXI_WSTRB	=> s_data_axi_wstrb,
	S_AXI_WVALID	=> s_data_axi_wvalid,
	S_AXI_WREADY	=> s_data_axi_wready,
	S_AXI_BRESP	=> s_data_axi_bresp,
	S_AXI_BVALID	=> s_data_axi_bvalid,
	S_AXI_BREADY	=> s_data_axi_bready,
	S_AXI_ARADDR	=> s_data_axi_araddr,
	S_AXI_ARPROT	=> s_data_axi_arprot,
	S_AXI_ARVALID	=> s_data_axi_arvalid,
	S_AXI_ARREADY	=> s_data_axi_arready,
	S_AXI_RDATA	=> s_data_axi_rdata,
	S_AXI_RRESP	=> s_data_axi_rresp,
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

-- packet processor
oneway_handshake(s_snd_aql_irq, s_snd_aql_irq_ack);
oneway_handshake(s_snd_dma_irq, s_snd_dma_irq_ack);
oneway_handshake(s_snd_cpl_irq, s_snd_cpl_irq_ack);
handshake_controller(s_snd_add_irq, s_snd_add_irq_ack, s_rcv_add_irq, s_rcv_add_irq_ack, 1 us);
handshake_controller(s_snd_rem_irq, s_snd_rem_irq_ack, s_rcv_rem_irq, s_rcv_rem_irq_ack, 1 us);

stimuli: process
begin
  reset 	<= '0';
  cmd_reset 	<= '0';
  data_reset 	<= '0';
  halt 		<= '1';

  -- no interrupts arrive at the moment
  s_rcv_dma_irq <= '0';
  s_rcv_cpl_irq <= '0';

  wait for 25 ns;
  reset <= '1';
  cmd_reset <= '1';
  data_reset <= '1';
  wait for 5 ns;
  halt <= '0';
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
