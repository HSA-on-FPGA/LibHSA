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

entity datamover is
    Generic (
            C_MM_DATA_WIDTH         : integer := 512
    );
    Port (
    -- AXI Control Interface
            axi_cfg_aclk            : in    STD_LOGIC;
            axi_cfg_aresetn         : in    STD_LOGIC;
                                    
            axi_cfg_awvalid         : in    STD_LOGIC;
            axi_cfg_awaddr          : in    STD_LOGIC_VECTOR (31 downto 0);
            axi_cfg_awready         : out   STD_LOGIC;
                                    
            axi_cfg_wvalid          : in    STD_LOGIC;
            axi_cfg_wdata           : in    STD_LOGIC_VECTOR (31 downto 0);
            axi_cfg_wstrb           : in    STD_LOGIC_VECTOR (3 downto 0);
            axi_cfg_wready          : out   STD_LOGIC; 
                                    
            axi_cfg_bvalid          : out   STD_LOGIC;
            axi_cfg_bresp           : out   STD_LOGIC_VECTOR (1 downto 0);
            axi_cfg_bready          : in    STD_LOGIC;
                                    
            axi_cfg_arvalid         : in    STD_LOGIC;
            axi_cfg_araddr          : in    STD_LOGIC_VECTOR (31 downto 0);
            axi_cfg_arready         : out   STD_LOGIC;
                                    
            axi_cfg_rvalid          : out   STD_LOGIC;
            axi_cfg_rdata           : out   STD_LOGIC_VECTOR (31 downto 0);
            axi_cfg_rresp           : out   STD_LOGIC_VECTOR (1 downto 0);
            axi_cfg_rready          : in    STD_LOGIC;
    
    -- Interrupts. Clocked with axi_cfg_aclk
            int_start               : in    STD_LOGIC;
            int_finished            : out   STD_LOGIC;
            int_finished_ack        : in    STD_LOGIC;
            int_error               : out   STD_LOGIC;

    -- Clock from Memory Domain
            axi_aclk            : in    STD_LOGIC;
            axi_aresetn         : in    STD_LOGIC;
    
    -- AXI from memory
            axi_mem_in_araddr       : out   STD_LOGIC_VECTOR ( 63 downto 0 );
            axi_mem_in_arburst      : out   STD_LOGIC_VECTOR ( 1 downto 0 );
            axi_mem_in_arcache      : out   STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_mem_in_arid         : out   STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_mem_in_arlen        : out   STD_LOGIC_VECTOR ( 7 downto 0 );
            axi_mem_in_arprot       : out   STD_LOGIC_VECTOR ( 2 downto 0 );
            axi_mem_in_arready      : in    STD_LOGIC;
            axi_mem_in_arsize       : out   STD_LOGIC_VECTOR ( 2 downto 0 );
            axi_mem_in_aruser       : out   STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_mem_in_arvalid      : out   STD_LOGIC;
            axi_mem_in_rdata        : in    STD_LOGIC_VECTOR ( C_MM_DATA_WIDTH-1 downto 0 );
            axi_mem_in_rlast        : in    STD_LOGIC;
            axi_mem_in_rready       : out   STD_LOGIC;
            axi_mem_in_rresp        : in    STD_LOGIC_VECTOR ( 1 downto 0 );
            axi_mem_in_rvalid       : in    STD_LOGIC;
               
    -- AXI to memory
            axi_mem_out_awaddr      : out   STD_LOGIC_VECTOR ( 63 downto 0 );
            axi_mem_out_awburst     : out   STD_LOGIC_VECTOR ( 1 downto 0 );
            axi_mem_out_awcache     : out   STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_mem_out_awid        : out   STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_mem_out_awlen       : out   STD_LOGIC_VECTOR ( 7 downto 0 );
            axi_mem_out_awprot      : out   STD_LOGIC_VECTOR ( 2 downto 0 );
            axi_mem_out_awready     : in    STD_LOGIC;
            axi_mem_out_awsize      : out   STD_LOGIC_VECTOR ( 2 downto 0 );
            axi_mem_out_awuser      : out   STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_mem_out_awvalid     : out   STD_LOGIC;
            axi_mem_out_bready      : out   STD_LOGIC;
            axi_mem_out_bresp       : in    STD_LOGIC_VECTOR ( 1 downto 0 );
            axi_mem_out_bvalid      : in    STD_LOGIC;
            axi_mem_out_wdata       : out   STD_LOGIC_VECTOR ( C_MM_DATA_WIDTH-1 downto 0 );
            axi_mem_out_wlast       : out   STD_LOGIC;
            axi_mem_out_wready      : in    STD_LOGIC;
            axi_mem_out_wstrb       : out   STD_LOGIC_VECTOR ( (C_MM_DATA_WIDTH/8)-1 downto 0 );
            axi_mem_out_wvalid      : out   STD_LOGIC;

    -- AXI Stream to Processing Element
            axi_stream_out_tdata    : out   STD_LOGIC_VECTOR ( 31 downto 0 );
            axi_stream_out_tkeep    : out   STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_stream_out_tlast    : out   STD_LOGIC;
            axi_stream_out_tready   : in    STD_LOGIC;
            axi_stream_out_tvalid   : out   STD_LOGIC;

    -- AXI Stream from Processing Element
            axi_stream_in_tdata     : in    STD_LOGIC_VECTOR ( 31 downto 0 );
            axi_stream_in_tkeep     : in    STD_LOGIC_VECTOR ( 3 downto 0 );
            axi_stream_in_tlast     : in    STD_LOGIC;
            axi_stream_in_tready    : out   STD_LOGIC;
            axi_stream_in_tvalid    : in    STD_LOGIC
           );
end datamover;

architecture Behavioral of datamover is

    signal config_addr_in   : STD_LOGIC_VECTOR(63 downto 0);
    signal config_addr_out  : STD_LOGIC_VECTOR(63 downto 0);
    signal config_size_in   : STD_LOGIC_VECTOR(63 downto 0);
    signal config_size_out  : STD_LOGIC_VECTOR(63 downto 0);
    signal config_data      : STD_LOGIC_VECTOR(255 downto 0);

    -- finished signals
    signal mm2s_finished : STD_LOGIC;
    signal s2mm_finished : STD_LOGIC;
    signal mm2s_finished_reg : STD_LOGIC;
    signal s2mm_finished_reg : STD_LOGIC;
    signal mm2s_error : STD_LOGIC;
    signal s2mm_error : STD_LOGIC;

    -- signals from xilinx_datamover
    signal xdm_mm2s_sts_tdata :     STD_LOGIC_VECTOR ( 7 downto 0 );
    signal xdm_mm2s_sts_tkeep :     STD_LOGIC_VECTOR ( 0 to 0 );
    signal xdm_mm2s_sts_tlast :     STD_LOGIC;
    signal xdm_mm2s_sts_tready :    STD_LOGIC;
    signal xdm_mm2s_sts_tvalid :    STD_LOGIC;
    signal xdm_mm2s_cmd_tdata :     STD_LOGIC_VECTOR ( 103 downto 0 ); 
    signal xdm_mm2s_cmd_tready :    STD_LOGIC;
    signal xdm_mm2s_cmd_tvalid :    STD_LOGIC;
    signal xdm_mm2s_err :           STD_LOGIC;
    signal sm_mm2s_done :           STD_LOGIC;
    signal sm_mm2s_err :            STD_LOGIC;
    signal sm_mm2s_out_command :    STD_LOGIC;
    signal sm_mm2s_out_size :       STD_LOGIC_VECTOR(22 downto 0);
    signal sm_mm2s_out_addr :       STD_LOGIC_VECTOR(63 downto 0);
    signal sm_mm2s_out_cmd_taken :  STD_LOGIC;
    signal xdm_s2mm_sts_tdata :     STD_LOGIC_VECTOR ( 7 downto 0 );
    signal xdm_s2mm_sts_tkeep :     STD_LOGIC_VECTOR ( 0 to 0 );
    signal xdm_s2mm_sts_tlast :     STD_LOGIC;
    signal xdm_s2mm_sts_tready :    STD_LOGIC;
    signal xdm_s2mm_sts_tvalid :    STD_LOGIC;
    signal xdm_s2mm_cmd_tdata :     STD_LOGIC_VECTOR ( 103 downto 0 ); 
    signal xdm_s2mm_cmd_tready :    STD_LOGIC;
    signal xdm_s2mm_cmd_tvalid :    STD_LOGIC;
    signal xdm_s2mm_err :           STD_LOGIC;
    signal sm_s2mm_done :           STD_LOGIC;
    signal sm_s2mm_err :            STD_LOGIC;
    signal sm_s2mm_out_command :    STD_LOGIC;
    signal sm_s2mm_out_size :       STD_LOGIC_VECTOR(22 downto 0);
    signal sm_s2mm_out_addr :       STD_LOGIC_VECTOR(63 downto 0);
    signal sm_s2mm_out_cmd_taken :  STD_LOGIC;

begin

    config_addr_in  <= config_data(1*64-1 downto 0*64);
    config_addr_out <= config_data(2*64-1 downto 1*64);
    config_size_in  <= config_data(3*64-1 downto 2*64);
    config_size_out <= config_data(4*64-1 downto 3*64);

    int_finished <= mm2s_finished_reg and s2mm_finished_reg;
    int_error <= mm2s_error or s2mm_error;

    fin_stat: process(axi_aclk)
    begin
        if(rising_edge(axi_aclk)) then
            if(axi_aresetn='0') then
                mm2s_finished_reg <= '0';
                s2mm_finished_reg <= '0';
            else
                if(int_start='1' or int_finished_ack='1') then
                    mm2s_finished_reg <= '0';
                    s2mm_finished_reg <= '0';
                else
                    mm2s_finished_reg <= mm2s_finished_reg or mm2s_finished;
                    s2mm_finished_reg <= s2mm_finished_reg or s2mm_finished;
                end if;
            end if;
        end if;
    end process;

    config: entity work.axi_config
    port map (
        config_data => config_data,
        S_AXI_ACLK => axi_cfg_aclk,
        S_AXI_ARESETN => axi_cfg_aresetn,
        S_AXI_AWVALID => axi_cfg_awvalid,
        S_AXI_AWADDR => axi_cfg_awaddr,
        S_AXI_AWREADY => axi_cfg_awready,
        S_AXI_WVALID => axi_cfg_wvalid,
        S_AXI_WDATA => axi_cfg_wdata,
        S_AXI_WSTRB => axi_cfg_wstrb,
        S_AXI_WREADY => axi_cfg_wready,
        S_AXI_BVALID => axi_cfg_bvalid,
        S_AXI_BRESP => axi_cfg_bresp,
        S_AXI_BREADY => axi_cfg_bready,
        S_AXI_ARVALID => axi_cfg_arvalid,
        S_AXI_ARADDR => axi_cfg_araddr,
        S_AXI_ARREADY => axi_cfg_arready,
        S_AXI_RVALID => axi_cfg_rvalid,
        S_AXI_RDATA => axi_cfg_rdata,
        S_AXI_RRESP => axi_cfg_rresp,
        S_AXI_RREADY => axi_cfg_rready
    );

    mm2s_statemachine : entity work.transfer_statemachine
    port map (
        clk => axi_aclk,
        aresetn => axi_aresetn,
        
        transfer_size => config_size_in,
        transfer_addr => config_addr_in,
        int_start => int_start,
        transfer_finished => mm2s_finished,
        transfer_error => mm2s_error,
        
        datamover_in_done =>        sm_mm2s_done,         
        datamover_in_err =>         sm_mm2s_err,
        datamover_out_command =>    sm_mm2s_out_command,  
        datamover_out_size =>       sm_mm2s_out_size,     
        datamover_out_addr =>       sm_mm2s_out_addr,
        datamover_cmd_taken =>      sm_mm2s_out_cmd_taken
    );
    
    s2mm_statemachine : entity work.transfer_statemachine
    port map (
        clk => axi_aclk,
        aresetn => axi_aresetn,
        
        transfer_size => config_size_out,
        transfer_addr => config_addr_out,
        int_start => int_start,
        transfer_finished => s2mm_finished, 
        transfer_error => s2mm_error,

        datamover_in_done =>        sm_s2mm_done,     
        datamover_in_err =>         sm_s2mm_err,
        datamover_out_command =>    sm_s2mm_out_command,  
        datamover_out_size =>       sm_s2mm_out_size,  
        datamover_out_addr =>       sm_s2mm_out_addr,
        datamover_cmd_taken =>      sm_s2mm_out_cmd_taken

    );

    s2mm_datamover_controller : entity work.xilinx_datamover_controller
    port map (
        xdm_status_tdata  => xdm_s2mm_sts_tdata, 
        xdm_status_tkeep  => xdm_s2mm_sts_tkeep, 
        xdm_status_tlast  => xdm_s2mm_sts_tlast, 
        xdm_status_tready => xdm_s2mm_sts_tready,
        xdm_status_tvalid => xdm_s2mm_sts_tvalid,
        xdm_cmd_tdata     => xdm_s2mm_cmd_tdata,     
        xdm_cmd_tready    => xdm_s2mm_cmd_tready,    
        xdm_cmd_tvalid    => xdm_s2mm_cmd_tvalid,    
        xdm_err           => xdm_s2mm_err,           
        sm_done           => sm_s2mm_done,         
        sm_err            => sm_s2mm_err,         
        sm_out_command    => sm_s2mm_out_command,  
        sm_out_size       => sm_s2mm_out_size,    
        sm_out_addr       => sm_s2mm_out_addr,     
        sm_out_cmd_taken  => sm_s2mm_out_cmd_taken     
        
    );
    
    mm2s_datamover_controller : entity work.xilinx_datamover_controller
    port map (
        xdm_status_tdata  => xdm_mm2s_sts_tdata, 
        xdm_status_tkeep  => xdm_mm2s_sts_tkeep, 
        xdm_status_tlast  => xdm_mm2s_sts_tlast, 
        xdm_status_tready => xdm_mm2s_sts_tready,
        xdm_status_tvalid => xdm_mm2s_sts_tvalid,
        xdm_cmd_tdata     => xdm_mm2s_cmd_tdata,     
        xdm_cmd_tready    => xdm_mm2s_cmd_tready,    
        xdm_cmd_tvalid    => xdm_mm2s_cmd_tvalid,    
        xdm_err           => xdm_mm2s_err,           
        sm_done           => sm_mm2s_done,         
        sm_err            => sm_mm2s_err,         
        sm_out_command    => sm_mm2s_out_command,  
        sm_out_size       => sm_mm2s_out_size,    
        sm_out_addr       => sm_mm2s_out_addr,     
        sm_out_cmd_taken  => sm_mm2s_out_cmd_taken     
        
    );

    xilinx_datamover_inst: entity work.xilinx_datamover_wrapper
    port map (
        
        M_AXIS_MM2S_STS_tdata  => xdm_mm2s_sts_tdata,
        M_AXIS_MM2S_STS_tkeep  => xdm_mm2s_sts_tkeep,
        M_AXIS_MM2S_STS_tlast  => xdm_mm2s_sts_tlast,
        M_AXIS_MM2S_STS_tready => xdm_mm2s_sts_tready,
        M_AXIS_MM2S_STS_tvalid => xdm_mm2s_sts_tvalid,
        
        M_AXIS_MM2S_tdata      => axi_stream_out_tdata, 
        M_AXIS_MM2S_tkeep      => axi_stream_out_tkeep, 
        M_AXIS_MM2S_tlast      => axi_stream_out_tlast, 
        M_AXIS_MM2S_tready     => axi_stream_out_tready,
        M_AXIS_MM2S_tvalid     => axi_stream_out_tvalid,
   
        M_AXIS_S2MM_STS_tdata  => xdm_s2mm_sts_tdata,
        M_AXIS_S2MM_STS_tkeep  => xdm_s2mm_sts_tkeep,
        M_AXIS_S2MM_STS_tlast  => xdm_s2mm_sts_tlast,
        M_AXIS_S2MM_STS_tready => xdm_s2mm_sts_tready,
        M_AXIS_S2MM_STS_tvalid => xdm_s2mm_sts_tvalid,
        
        M_AXI_MM2S_araddr   => axi_mem_in_araddr,  
        M_AXI_MM2S_arburst  => axi_mem_in_arburst, 
        M_AXI_MM2S_arcache  => axi_mem_in_arcache,
        M_AXI_MM2S_arid     => axi_mem_in_arid,    
        M_AXI_MM2S_arlen    => axi_mem_in_arlen,   
        M_AXI_MM2S_arprot   => axi_mem_in_arprot,  
        M_AXI_MM2S_arready  => axi_mem_in_arready, 
        M_AXI_MM2S_arsize   => axi_mem_in_arsize,  
        M_AXI_MM2S_aruser   => axi_mem_in_aruser,  
        M_AXI_MM2S_arvalid  => axi_mem_in_arvalid, 
        M_AXI_MM2S_rdata    => axi_mem_in_rdata,   
        M_AXI_MM2S_rlast    => axi_mem_in_rlast,   
        M_AXI_MM2S_rready   => axi_mem_in_rready,  
        M_AXI_MM2S_rresp    => axi_mem_in_rresp,   
        M_AXI_MM2S_rvalid   => axi_mem_in_rvalid,  
        
        M_AXI_S2MM_awaddr   => axi_mem_out_awaddr,
        M_AXI_S2MM_awburst  => axi_mem_out_awburst,
        M_AXI_S2MM_awcache  => axi_mem_out_awcache,
        M_AXI_S2MM_awid     => axi_mem_out_awid,   
        M_AXI_S2MM_awlen    => axi_mem_out_awlen,  
        M_AXI_S2MM_awprot   => axi_mem_out_awprot, 
        M_AXI_S2MM_awready  => axi_mem_out_awready,
        M_AXI_S2MM_awsize   => axi_mem_out_awsize, 
        M_AXI_S2MM_awuser   => axi_mem_out_awuser, 
        M_AXI_S2MM_awvalid  => axi_mem_out_awvalid,
        M_AXI_S2MM_bready   => axi_mem_out_bready, 
        M_AXI_S2MM_bresp    => axi_mem_out_bresp,  
        M_AXI_S2MM_bvalid   => axi_mem_out_bvalid, 
        M_AXI_S2MM_wdata    => axi_mem_out_wdata,  
        M_AXI_S2MM_wlast    => axi_mem_out_wlast,  
        M_AXI_S2MM_wready   => axi_mem_out_wready, 
        M_AXI_S2MM_wstrb    => axi_mem_out_wstrb,  
        M_AXI_S2MM_wvalid   => axi_mem_out_wvalid, 
        
        S_AXIS_MM2S_CMD_tdata  => xdm_mm2s_cmd_tdata,
        S_AXIS_MM2S_CMD_tready => xdm_mm2s_cmd_tready,
        S_AXIS_MM2S_CMD_tvalid => xdm_mm2s_cmd_tvalid,
        S_AXIS_S2MM_CMD_tdata  => xdm_s2mm_cmd_tdata,
        S_AXIS_S2MM_CMD_tready => xdm_s2mm_cmd_tready,
        S_AXIS_S2MM_CMD_tvalid => xdm_s2mm_cmd_tvalid,


        S_AXIS_S2MM_tdata  => axi_stream_in_tdata, 
        S_AXIS_S2MM_tkeep  => axi_stream_in_tkeep, 
        S_AXIS_S2MM_tlast  => axi_stream_in_tlast, 
        S_AXIS_S2MM_tready => axi_stream_in_tready,
        S_AXIS_S2MM_tvalid => axi_stream_in_tvalid,
        
        aclk => axi_aclk,
        aresetn => axi_aresetn,
        mm2s_err => xdm_mm2s_err,
        s2mm_err => xdm_s2mm_err    
    );

end Behavioral;
