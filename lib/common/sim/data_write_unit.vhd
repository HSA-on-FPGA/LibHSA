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
use ieee.math_real.all;

-- C_AXI_ADDR_WIDTH must always be a multiple of C_BRAM_LINE_WIDTH!!!
entity data_write_unit is
    generic(
		C_LOW_ADDR				: std_logic_vector	:= x"0002000000000000";
		C_AXI_ADDR_WIDTH			: integer		:= 64;
		C_AXI_DATA_WIDTH			: integer		:= 64;	
		C_NUM_4K_BRAM_BLOCKS			: integer		:= 4;
		C_BRAM_LINE_WIDTH			: integer		:= 32
    );
    port(
        clk                     : in  std_logic;
        rstn                    : in  std_logic;
	finished		: out std_logic;	
	
	M_AXI_ACLK	: in std_logic;
	M_AXI_ARESETN	: in std_logic;
	M_AXI_AWADDR	: out std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
	M_AXI_AWVALID	: out std_logic;
	M_AXI_AWREADY	: in std_logic;
	M_AXI_WDATA	: out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	M_AXI_WSTRB	: out std_logic_vector(C_AXI_DATA_WIDTH/8-1 downto 0);
	M_AXI_WVALID	: out std_logic;
	M_AXI_WREADY	: in std_logic;
	M_AXI_BRESP	: in std_logic_vector(1 downto 0);
	M_AXI_BVALID	: in std_logic;
	M_AXI_BREADY	: out std_logic;
	M_AXI_ARADDR	: out std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
	M_AXI_ARVALID	: out std_logic;
	M_AXI_ARREADY	: in std_logic;
	M_AXI_RDATA	: in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	M_AXI_RRESP	: in std_logic_vector(1 downto 0);
	M_AXI_RVALID	: in std_logic;
	M_AXI_RREADY	: out std_logic
    );
end entity;

architecture behav of data_write_unit is

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

    constant NUM_LINES 		: integer := ((C_NUM_4K_BRAM_BLOCKS*4096)*8)/C_BRAM_LINE_WIDTH;
    constant WIDTH_RATIO 	: integer := C_AXI_DATA_WIDTH/C_BRAM_LINE_WIDTH;
    
    -- Shared memory
    type mem_type is array ( 0 to NUM_LINES-1 ) of std_logic_vector(C_BRAM_LINE_WIDTH-1 downto 0);
    shared variable bram: mem_type;

    signal current_address 	: std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    signal current_bram_index 	: std_logic_vector(integer(ceil(log2(real(NUM_LINES))))-1 downto 0);
    signal current_offset 	: std_logic_vector(WIDTH_RATIO-1 downto 0);
    signal current_data_offset 	: std_logic_vector(integer(ceil(log2(real(C_AXI_DATA_WIDTH))))-1 downto 0);

-- AXI Master state
    type axi_state is (READY,TRANSFER_ALIGNED);
    signal state : axi_state;

-- writer state
    type writer_state is (READ_BRAM,AXI_TRANSFER,FIN);
    signal unit_state : writer_state;
    signal last			: std_logic;

-- CPU/AXI interface
    signal a_addr	: std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    signal a_dw		: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    signal a_we		: std_logic;
    signal a_bus_err	: std_logic;
    
-- signals from and to axi masters
    signal s_axi_addr 		: std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    signal s_axi_data 		: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    signal s_axi_rdata 		: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    signal s_axi_accessmode	: std_logic;
    signal s_init_axi_txn 	: std_logic;
    signal s_axi_error 		: std_logic;
    signal s_axi_txn_done 	: std_logic;

begin

-- Instantiation of Axi Bus Interface
axi_lite_master_inst : axi_lite_master
	generic map (
		C_M_AXI_ADDR_WIDTH	=> C_AXI_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_AXI_DATA_WIDTH
	)
	port map (
		CPU_ADDR 	=> s_axi_addr,
		CPU_WDATA 	=> s_axi_data,
		CPU_RDATA 	=> s_axi_rdata,
		CPU_ACCESS_MODE => s_axi_accessmode,
		INIT_AXI_TXN	=> s_init_axi_txn,
		ERROR		=> s_axi_error,
		TXN_DONE	=> s_axi_txn_done,
		M_AXI_ACLK	=> M_AXI_ACLK,	
		M_AXI_ARESETN	=> M_AXI_ARESETN,	
		M_AXI_AWADDR	=> M_AXI_AWADDR,	
		M_AXI_AWPROT	=> M_AXI_AWPROT,	
		M_AXI_AWVALID	=> M_AXI_AWVALID,	
		M_AXI_AWREADY	=> M_AXI_AWREADY,	
		M_AXI_WDATA	=> M_AXI_WDATA,	
		M_AXI_WSTRB	=> M_AXI_WSTRB,	
		M_AXI_WVALID	=> M_AXI_WVALID,	
		M_AXI_WREADY	=> M_AXI_WREADY,	
		M_AXI_BRESP	=> M_AXI_BRESP,	
		M_AXI_BVALID	=> M_AXI_BVALID,	
		M_AXI_BREADY	=> M_AXI_BREADY,	
		M_AXI_ARADDR	=> M_AXI_ARADDR,	
		M_AXI_ARPROT	=> M_AXI_ARPROT,	
		M_AXI_ARVALID	=> M_AXI_ARVALID,	
		M_AXI_ARREADY	=> M_AXI_ARREADY,	
		M_AXI_RDATA	=> M_AXI_RDATA,	
		M_AXI_RRESP	=> M_AXI_RRESP,	
		M_AXI_RVALID	=> M_AXI_RVALID,	
		M_AXI_RREADY	=> M_AXI_RREADY
	);

prepare_data: process(clk)
begin
        if(rising_edge(clk)) then
		if(rstn='0') then
			unit_state 		<= READ_BRAM;
			a_addr 			<= C_LOW_ADDR;
			a_dw 			<= (others => '0');
			a_we 			<= '0';
			current_address 	<= C_LOW_ADDR;
    			current_bram_index 	<= (others => '0');
    			current_offset 		<= (others => '0');
			current_data_offset 	<= (others => '0');
			last 			<= '0';
			finished 		<= '0';
		else
			unit_state 		<= unit_state;
			current_address 	<= current_address;
			current_bram_index 	<= current_bram_index;
			current_offset 		<= current_offset;
			current_data_offset 	<= current_data_offset;
			a_addr 			<= current_address;
			a_dw 			<= a_dw;
			a_we 			<= '0';
			last 			<= last;
			finished 		<= '0';
			case unit_state is
				when READ_BRAM =>
					if(unsigned(current_offset) = to_unsigned(WIDTH_RATIO,current_offset'length)) then
						-- base case: all data read from bram, so send it over axi
						unit_state 	<= AXI_TRANSFER;
						a_dw 		<= a_dw;
						a_we 		<= '1';
					else
						-- read next data chunk from bram
						a_dw(to_integer(unsigned(current_data_offset))+C_BRAM_LINE_WIDTH-1 downto to_integer(unsigned(current_data_offset))) 
							<= bram(to_integer(unsigned(current_bram_index)));
						current_bram_index 	<= std_logic_vector(unsigned(current_bram_index)+1);
						current_offset 		<= std_logic_vector(unsigned(current_offset)+1);
						current_data_offset 	<= std_logic_vector(unsigned(current_data_offset)+to_unsigned(C_BRAM_LINE_WIDTH,current_data_offset'length));
						if(unsigned(current_bram_index) = to_unsigned(NUM_LINES-1-(WIDTH_RATIO-1),current_bram_index'length)) then
							-- this was the last transfer
							last <= '1';
						end if;
					end if;
				when AXI_TRANSFER =>
					a_we <= a_we;
					if(s_axi_txn_done = '1') then
						if(last = '1') then
							unit_state 		<= FIN;
							a_we 			<= '0';
						else
							-- reset the counters and start preparation for next transfer
							unit_state 		<= READ_BRAM;
							a_we 			<= '0';
							current_address 	<= std_logic_vector(unsigned(current_address)+to_unsigned(C_AXI_DATA_WIDTH/8,current_address'length));
							current_offset 		<= (others => '0');
						end if;
					elsif(s_axi_error = '1') then
						unit_state <= FIN;
						a_we 	   <= '0';
					end if;
				when FIN =>
					finished <= '1';
				when others =>
					unit_state <= READ_BRAM;
			end case;
		end if;
	end if;
end process;

manage_axi: process(clk)
begin
	if(rising_edge(clk)) then
		if(rstn='0') then
			state 			<= READY;
        		a_bus_err   	        <= '0';
			s_init_axi_txn 		<= '0';
			s_axi_accessmode 	<= '0';
			s_axi_data 		<= (others => '0');
   			s_axi_addr 		<= (others => '0');
		else
			state 		<= READY;
        		a_bus_err       <= '0';
			s_init_axi_txn 	<= '0';
			s_axi_accessmode<= '0';
			s_axi_data 	<= (others => '0');
   			s_axi_addr 	<= (others => '0');
			case state is
				when READY =>
   					s_axi_addr <= std_logic_vector(resize(unsigned(a_addr),s_axi_addr'length));
    					if(a_we='1') then
						state <= TRANSFER_ALIGNED;
						s_init_axi_txn <= '1';
						s_axi_accessmode <= '1';
						s_axi_data <= std_logic_vector(resize(unsigned(a_dw),s_axi_data'length));
					else
						state <= READY;
					end if;
				when TRANSFER_ALIGNED =>
   					s_axi_addr <= std_logic_vector(resize(unsigned(a_addr),s_axi_addr'length));
					if(s_axi_error = '1') then
						state <= READY;
						a_bus_err <= s_axi_error;
					elsif(s_axi_txn_done = '1') then
						state <= READY;
						s_init_axi_txn <= '0';
					else
						state <= TRANSFER_ALIGNED;
						s_init_axi_txn <= '1';
   						s_axi_addr <= std_logic_vector(resize(unsigned(a_addr),s_axi_addr'length));
    						if(a_we='1') then
							s_axi_accessmode <= '1';
							s_axi_data <= std_logic_vector(resize(unsigned(a_dw),s_axi_data'length));
						end if;
					end if;
				when others =>
					state <= READY;
			end case;
		end if;
	end if;
end process;

end architecture;
