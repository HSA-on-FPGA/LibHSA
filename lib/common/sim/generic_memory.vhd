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
-- C_BRAM_LINE_WIDTH must always be a multiple of 2!!!
entity generic_memory is
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
    	S_AXI_RREADY    : in std_logic
    );
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of generic_memory is

component axi_lite_slave is
generic (
    AXI_ADDR_WIDTH  : integer   := 64;
    AXI_DATA_WIDTH  : integer   := 64
);
port (
    ADDR        : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    READ_DATA   : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    READ_EN     : out std_logic;
    WRITE_DATA  : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    WRITE_EN    : out std_logic;
    COMPLETED   : in  std_logic;
    ERROR       : in  std_logic;

    S_AXI_ACLK    : in  std_logic;
    S_AXI_ARESETN : in  std_logic;
    S_AXI_AWADDR  : in  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
    S_AXI_AWVALID : in  std_logic;
    S_AXI_AWREADY : out std_logic;
    S_AXI_WDATA   : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB   : in  std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in  std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in  std_logic;
    S_AXI_ARADDR  : in  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
    S_AXI_ARVALID : in  std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA   : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in  std_logic
);
end component axi_lite_slave;

    constant NUM_LINES 		: integer := ((C_NUM_1K_BRAM_BLOCKS*1024)*8)/C_BRAM_LINE_WIDTH;
    constant WIDTH_RATIO 	: integer := C_AXI_DATA_WIDTH/C_BRAM_LINE_WIDTH;
    constant ADDRESS_SHIFT 	: integer := integer(ceil(log2(real(C_BRAM_LINE_WIDTH/8))));
    
    -- Shared memory
    type mem_type is array ( 0 to NUM_LINES-1 ) of std_logic_vector(C_BRAM_LINE_WIDTH-1 downto 0);
    shared variable bram: mem_type;
    
    -- internal read/write state
    type unit_state is (IDLE,READ_BRAM,WRITE_BRAM);
    signal state : unit_state;
    
    signal current_bram_index 	: std_logic_vector(integer(ceil(log2(real(NUM_LINES))))-1 downto 0);
    signal current_offset 	: std_logic_vector(WIDTH_RATIO-1 downto 0);
    signal current_data_offset 	: std_logic_vector(integer(ceil(log2(real(C_AXI_DATA_WIDTH))))-1 downto 0);
    
    signal rebased_address      : std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);

    -- BRAM/AXI interface
    signal s_addr	: std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    signal r_dr	        : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    signal s_dw		: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    signal s_we		: std_logic;
    signal s_re		: std_logic;
    signal s_completed	: std_logic;
    signal s_error	: std_logic;

begin

-- Instantiation of Axi Bus Interface
slave_inst : axi_lite_slave
    generic map (
        AXI_ADDR_WIDTH => C_AXI_ADDR_WIDTH,
        AXI_DATA_WIDTH => C_AXI_DATA_WIDTH
    )
    port map (
        ADDR          => s_addr, 
        READ_DATA     => r_dr, 
    	READ_EN       => s_re,
        WRITE_DATA    => s_dw, 
        WRITE_EN      => s_we,
	COMPLETED     => s_completed,
	ERROR         => s_error,

        S_AXI_ACLK    => S_AXI_ACLK,   
        S_AXI_ARESETN => S_AXI_ARESETN,
        S_AXI_AWADDR  => S_AXI_AWADDR,  
        S_AXI_AWPROT  => S_AXI_AWPROT,  
        S_AXI_AWVALID => S_AXI_AWVALID,
        S_AXI_AWREADY => S_AXI_AWREADY,
        S_AXI_WDATA   => S_AXI_WDATA,
        S_AXI_WSTRB   => S_AXI_WSTRB,  
        S_AXI_WVALID  => S_AXI_WVALID,  
        S_AXI_WREADY  => S_AXI_WREADY,  
        S_AXI_BRESP   => S_AXI_BRESP,  
        S_AXI_BVALID  => S_AXI_BVALID,  
        S_AXI_BREADY  => S_AXI_BREADY,  
        S_AXI_ARADDR  => S_AXI_ARADDR,  
        S_AXI_ARPROT  => S_AXI_ARPROT,  
        S_AXI_ARVALID => S_AXI_ARVALID,
        S_AXI_ARREADY => S_AXI_ARREADY,  
        S_AXI_RDATA   => S_AXI_RDATA,
        S_AXI_RRESP   => S_AXI_RRESP,
        S_AXI_RVALID  => S_AXI_RVALID,  
        S_AXI_RREADY  => S_AXI_RREADY
    );

rebased_address <= std_logic_vector(unsigned(s_addr)-unsigned(C_LOW_ADDR));

prepare_data: process(clk)
begin
        if(rising_edge(clk)) then
		if(rstn='0') then
			state 		    <= idle;
			r_dr 		    <= (others => '0');
    			current_bram_index  <= (others => '0');
    			current_offset 	    <= (others => '0');
    			current_data_offset <= (others => '0');
			s_completed 	    <= '0';
			s_error 	    <= '0';
		else
			state 		    <= state;
			r_dr 		    <= r_dr;
			current_bram_index  <= current_bram_index;
			current_offset 	    <= current_offset;
			current_data_offset <= current_data_offset;
			s_completed 	    <= '0';
			s_error 	    <= '0';
			case state is
				when IDLE =>
					if(s_re = '1' and s_completed = '0') then
						state <= READ_BRAM;
						if(unsigned(s_addr)>=unsigned(C_LOW_ADDR) and unsigned(s_addr)<(unsigned(C_LOW_ADDR)+to_unsigned(C_NUM_1K_BRAM_BLOCKS*1024,C_LOW_ADDR'length))) then
							current_bram_index <= rebased_address(integer(ceil(log2(real(NUM_LINES))))-1+ADDRESS_SHIFT downto ADDRESS_SHIFT);
						else 
							s_error <= '1';
						end if;
					elsif(s_we = '1' and s_completed = '0') then
						state <= WRITE_BRAM;
						if(unsigned(s_addr)>=unsigned(C_LOW_ADDR) and unsigned(s_addr)<(unsigned(C_LOW_ADDR)+to_unsigned(C_NUM_1K_BRAM_BLOCKS*1024,C_LOW_ADDR'length))) then
							current_bram_index <= rebased_address(integer(ceil(log2(real(NUM_LINES))))-1+ADDRESS_SHIFT downto ADDRESS_SHIFT);
						else 
							s_error <= '1';
						end if;
					end if;
				when READ_BRAM =>
					if(unsigned(current_offset) = to_unsigned(WIDTH_RATIO,current_offset'length)) then
						-- base case: all data read from bram, so send it over axi
						state 	            <= IDLE;
						r_dr 		    <= r_dr;
						s_completed         <= '1';
    						current_bram_index  <= (others => '0');
    						current_offset 	    <= (others => '0');
    						current_data_offset <= (others => '0');
					else
						-- read next data chunk from bram
						r_dr(to_integer(unsigned(current_data_offset))+C_BRAM_LINE_WIDTH-1 downto to_integer(unsigned(current_data_offset))) 
							<= bram(to_integer(unsigned(current_bram_index)));
						current_bram_index 	<= std_logic_vector(unsigned(current_bram_index)+1);
						current_offset 		<= std_logic_vector(unsigned(current_offset)+1);
						current_data_offset 	<= std_logic_vector(unsigned(current_data_offset)+to_unsigned(C_BRAM_LINE_WIDTH,current_data_offset'length));
					end if;
				when WRITE_BRAM =>
					if(unsigned(current_offset) = to_unsigned(WIDTH_RATIO,current_offset'length)) then
						-- base case: all data written to bram, so notify axi
						state 	            <= IDLE;
						s_completed         <= '1';
    						current_bram_index  <= (others => '0');
    						current_offset 	    <= (others => '0');
    						current_data_offset <= (others => '0');
					else
						-- write next data chunk to bram
						bram(to_integer(unsigned(current_bram_index))) := s_dw(to_integer(unsigned(current_data_offset))+C_BRAM_LINE_WIDTH-1 downto to_integer(unsigned(current_data_offset)));
						current_bram_index 	<= std_logic_vector(unsigned(current_bram_index)+1);
						current_offset 		<= std_logic_vector(unsigned(current_offset)+1);
						current_data_offset 	<= std_logic_vector(unsigned(current_data_offset)+to_unsigned(C_BRAM_LINE_WIDTH,current_data_offset'length));
					end if;
				when others =>
					state <= IDLE;
			end case;
		end if;
	end if;
end process;

end architecture;
