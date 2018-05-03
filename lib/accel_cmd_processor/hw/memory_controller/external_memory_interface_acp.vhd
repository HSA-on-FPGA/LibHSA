-- Copyright (C) 2017 Philipp Holzinger
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

entity external_memory_interface_acp is
    generic(
		C_CPU_DATA_WIDTH			: integer		:= 32;
		C_CPU_ADDR_WIDTH			: integer		:= 32;
		C_AXI_LOW_ADDR				: std_logic_vector	:= x"11000000";
		C_AXI_HIGH_ADDR				: std_logic_vector	:= x"20000000";
		C_AXI_ADDR_WIDTH			: integer		:= 32;
		C_AXI_DATA_WIDTH			: integer		:= 32;
		C_IRQ_SND_NUM_ADDR			: std_logic_vector	:= x"10000000"
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
    	
	-- to interrupt demux
	SND_INT_NUM			: out std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
	SND_INT_SIG			: out std_logic;
		
	-- Ports of Axi Master Bus Interface DATA_AXI
	data_axi_aclk   : in    std_logic;                                              
	data_axi_aresetn: in    std_logic;
	data_axi_awaddr	: out std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	data_axi_awprot	: out std_logic_vector(2 downto 0);
	data_axi_awvalid: out std_logic;
	data_axi_awready: in std_logic;
	data_axi_wdata	: out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	data_axi_wstrb	: out std_logic_vector(C_AXI_DATA_WIDTH/8-1 downto 0);
	data_axi_wvalid	: out std_logic;
	data_axi_wready	: in std_logic;
	data_axi_bresp	: in std_logic_vector(1 downto 0);
	data_axi_bvalid	: in std_logic;
	data_axi_bready	: out std_logic;
	data_axi_araddr	: out std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	data_axi_arprot	: out std_logic_vector(2 downto 0);
	data_axi_arvalid: out std_logic;
	data_axi_arready: in std_logic;
	data_axi_rdata	: in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	data_axi_rresp	: in std_logic_vector(1 downto 0);
	data_axi_rvalid	: in std_logic;
	data_axi_rready	: out std_logic
    );
end entity;

architecture behav of external_memory_interface_acp is

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

    signal s_read_busy         		: std_logic;
    signal s_write_busy                 : std_logic;

-- requested memory location
    type mem_location is (NONE,SND_IRQ,DATA_AXI);
    signal access_location : mem_location;
    signal access_location_delayed : mem_location;

-- AXI Master state
    type axi_state is (READY,TRANSFER_ALIGNED);
    signal data_state : axi_state;

-- CPU/AXI interface
    signal a_data_addr	: std_logic_vector(C_CPU_ADDR_WIDTH-1 downto 0);
    signal a_data_dw	: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_data_we	: std_logic;
    signal a_data_re	: std_logic;
    signal a_data_dr	: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_data_dr_del: std_logic_vector(C_CPU_DATA_WIDTH-1 downto 0);
    signal a_data_done  : std_logic;
    
-- AXI busy and error signals
    signal a_data_bus_err	: std_logic;

-- signals from and to axi master
    signal s_data_axi_addr 	: std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    signal s_data_axi_wdata 	: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    signal s_data_axi_rdata 	: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    signal s_data_axi_accessmode: std_logic;
    signal s_init_data_axi_txn 	: std_logic;
    signal s_data_axi_error 	: std_logic;
    signal s_data_axi_txn_done 	: std_logic;

begin

-- Instantiation of Axi Bus Interface DATA_AXI
external_memory_interface_data_axi_inst : axi_lite_master
	generic map (
		C_M_AXI_ADDR_WIDTH	=> C_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_AXI_DATA_WIDTH
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
		M_AXI_AWADDR	=> data_axi_awaddr,
		M_AXI_AWPROT	=> data_axi_awprot,
		M_AXI_AWVALID	=> data_axi_awvalid,
		M_AXI_AWREADY	=> data_axi_awready,
		M_AXI_WDATA	=> data_axi_wdata,
		M_AXI_WSTRB	=> data_axi_wstrb,
		M_AXI_WVALID	=> data_axi_wvalid,
		M_AXI_WREADY	=> data_axi_wready,
		M_AXI_BRESP	=> data_axi_bresp,
		M_AXI_BVALID	=> data_axi_bvalid,
		M_AXI_BREADY	=> data_axi_bready,
		M_AXI_ARADDR	=> data_axi_araddr,
		M_AXI_ARPROT	=> data_axi_arprot,
		M_AXI_ARVALID	=> data_axi_arvalid,
		M_AXI_ARREADY	=> data_axi_arready,
		M_AXI_RDATA	=> data_axi_rdata,
		M_AXI_RRESP	=> data_axi_rresp,
		M_AXI_RVALID	=> data_axi_rvalid,
		M_AXI_RREADY	=> data_axi_rready
	);

data_read_busy 	<= s_read_busy AND NOT(a_data_done);
data_write_busy <= s_write_busy AND NOT(a_data_done);
data_bus_exc 	<= a_data_bus_err;

address_check: process(data_addr)
begin
	-- set registers prevent latches
	access_location <= NONE;

	-- send interrupt
	if(data_addr = C_IRQ_SND_NUM_ADDR) then
		access_location <= SND_IRQ;
	-- address points to DATA AXI bus
	elsif((data_addr >= C_AXI_LOW_ADDR) AND (data_addr < C_AXI_HIGH_ADDR)) then
		access_location <= DATA_AXI;
	-- address is invalid
	else
		access_location <= NONE;
	end if;
end process;

distribute_data: process(access_location,data_addr,data_re,data_we,data_din)
begin
        -- set registers prevent latches
	SND_INT_SIG 	<= '0';
	SND_INT_NUM 	<= std_logic_vector(resize(unsigned(data_din),SND_INT_NUM'length));
	s_read_busy 	<= '0';
	s_write_busy 	<= '0';
	a_data_addr 	<= (others => '0');
	a_data_dw 	<= (others => '0');
	a_data_re 	<= '0';
	a_data_we 	<= '0';
        address_error_exc_load  <= '0';
        address_error_exc_store <= '0';

	if(data_re = '1') then
		-- address points to DATA AXI bus
		if(access_location = DATA_AXI) then
			s_read_busy <= '1';
			a_data_addr <= data_addr;
			a_data_re <= '1';
		-- else address is invalid or no memory operation performed
		else
			address_error_exc_load <= '1';
		end if;
	elsif(data_we = '1') then
		-- send interrupt
		if(access_location = SND_IRQ) then
			-- default value is correct value
			SND_INT_SIG <= '1'; -- only one cycle
		-- address points to DATA AXI bus
		elsif(access_location = DATA_AXI) then
			s_write_busy <= '1';
			a_data_addr <= data_addr;
			a_data_dw <= data_din;
			a_data_we <= '1';
		-- else address is invalid or no memory operation performed
		else
			address_error_exc_store <= '1';
		end if;	
	end if;
end process;

collect_data: process(access_location_delayed,a_data_dr_del)
begin
	-- address points to DATA AXI bus
	if(access_location_delayed = DATA_AXI) then
		data_dout <= a_data_dr_del;
	-- else address is invalid or no memory operation performed
	else
		data_dout <= (others => '0');
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
			a_data_dr_del <= (others => '0');
		else
			a_data_dr_del <= a_data_dr;
		end if;
	end if;
end process;

end architecture;

