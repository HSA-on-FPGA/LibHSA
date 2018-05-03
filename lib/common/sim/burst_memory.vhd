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
use ieee.math_real.all;

entity burst_memory is
    generic(
		C_LOW_ADDR				: std_logic_vector	:= x"0001000000000000";
		C_AXI_ADDR_WIDTH			: integer		:= 64;
		C_AXI_DATA_WIDTH			: integer		:= 64;	
		C_NUM_1K_BRAM_BLOCKS			: integer		:= 4
    );
    port(
        clk             : in  std_logic;
        rstn            : in  std_logic;
	
    	S_AXI_ACLK    	: in std_logic;
    	S_AXI_ARESETN   : in std_logic;
	S_AXI_AWID	: in std_logic_vector(0 downto 0);
	S_AXI_AWADDR	: in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	S_AXI_AWLEN	: in std_logic_vector(7 downto 0);
	S_AXI_AWSIZE	: in std_logic_vector(2 downto 0);
	S_AXI_AWBURST	: in std_logic_vector(1 downto 0);
	S_AXI_AWLOCK	: in std_logic;
	S_AXI_AWCACHE	: in std_logic_vector(3 downto 0);
	S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	S_AXI_AWQOS	: in std_logic_vector(3 downto 0);
	S_AXI_AWREGION	: in std_logic_vector(3 downto 0);
	S_AXI_AWVALID	: in std_logic;
	S_AXI_AWREADY	: out std_logic;
	S_AXI_WDATA	: in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	S_AXI_WSTRB	: in std_logic_vector((C_AXI_DATA_WIDTH/8)-1 downto 0);
	S_AXI_WLAST	: in std_logic;
	S_AXI_WVALID	: in std_logic;
	S_AXI_WREADY	: out std_logic;
	S_AXI_BID	: out std_logic_vector(0 downto 0);
	S_AXI_BRESP	: out std_logic_vector(1 downto 0);
	S_AXI_BVALID	: out std_logic;
	S_AXI_BREADY	: in std_logic;
	S_AXI_ARID	: in std_logic_vector(0 downto 0);
	S_AXI_ARADDR	: in std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
	S_AXI_ARLEN	: in std_logic_vector(7 downto 0);
	S_AXI_ARSIZE	: in std_logic_vector(2 downto 0);
	S_AXI_ARBURST	: in std_logic_vector(1 downto 0);
	S_AXI_ARLOCK	: in std_logic;
	S_AXI_ARCACHE	: in std_logic_vector(3 downto 0);
	S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	S_AXI_ARQOS	: in std_logic_vector(3 downto 0);
	S_AXI_ARREGION	: in std_logic_vector(3 downto 0);
	S_AXI_ARVALID	: in std_logic;
	S_AXI_ARREADY	: out std_logic;
	S_AXI_RID	: out std_logic_vector(0 downto 0);
	S_AXI_RDATA	: out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
	S_AXI_RRESP	: out std_logic_vector(1 downto 0);
	S_AXI_RLAST	: out std_logic;
	S_AXI_RVALID	: out std_logic;
	S_AXI_RREADY	: in std_logic
    );
end entity;

architecture behav of burst_memory is

    constant NUM_LINES 		: integer := ((C_NUM_1K_BRAM_BLOCKS*1024)*8)/C_AXI_DATA_WIDTH;
    constant WIDTH_RATIO 	: integer := 1;
    constant ADDRESS_SHIFT 	: integer := integer(ceil(log2(real(C_AXI_DATA_WIDTH/8))));
    
    -- Shared memory
    type mem_type is array ( 0 to NUM_LINES-1 ) of std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    shared variable bram: mem_type;
    
    -- internal read/write state
    type unit_state is (IDLE,READ_BRAM,WRITE_BRAM);
    signal axi_state : unit_state;
    
    signal current_bram_index 	: std_logic_vector(integer(ceil(log2(real(NUM_LINES))))-1 downto 0);
    
    signal single_write		: std_logic;
    
    signal rebased_address      : std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    signal decoded_addr		: std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);

    -- AXI4FULL signals
    signal axi_arlen_cntr	: std_logic_vector(7 downto 0);

begin

	rebased_address <= std_logic_vector(unsigned(decoded_addr)-unsigned(C_LOW_ADDR));

	S_AXI_BID 	<= S_AXI_AWID;
	S_AXI_RID 	<= S_AXI_ARID;

	S_AXI_RVALID 	<= '1' when axi_state = READ_BRAM else '0';
	S_AXI_RRESP 	<= "00";
	S_AXI_RDATA 	<= bram(to_integer(unsigned(current_bram_index))) when axi_state = READ_BRAM else (others => '0');
	S_AXI_ARREADY 	<= '1' when axi_state /= WRITE_BRAM else '0';

	-- bresp signal
	S_AXI_BRESP 	<= "00";
	S_AXI_BVALID 	<= '1' when axi_state = WRITE_BRAM and (S_AXI_WLAST = '1' or single_write = '1') else '0';

	S_AXI_AWREADY 	<= '1' when axi_state /= READ_BRAM else '0';
	S_AXI_WREADY 	<= '1' when axi_state /= READ_BRAM else '0';
	
	S_AXI_RLAST	<= '1' when unsigned(axi_arlen_cntr) >= unsigned(S_AXI_AWLEN) else '0';

	-- Address computation
	decoded_addr <= S_AXI_AWADDR when S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' else
        	        S_AXI_ARADDR when S_AXI_ARVALID = '1' else (others => '0');

    axi_state_machine: process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_state <= IDLE;
                current_bram_index <= (others => '0');
                axi_arlen_cntr <= (others => '0');
                single_write  <= '0';
            else
                case axi_state is
                    when IDLE =>
                        axi_arlen_cntr <= (others => '0');
                        if S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' then
                            axi_state <= WRITE_BRAM;
                            current_bram_index <= rebased_address(integer(ceil(log2(real(NUM_LINES))))-1+ADDRESS_SHIFT downto ADDRESS_SHIFT);
                            single_write <= S_AXI_WLAST;
                        elsif S_AXI_ARVALID = '1' then
                            axi_state <= READ_BRAM;
                            current_bram_index <= rebased_address(integer(ceil(log2(real(NUM_LINES))))-1+ADDRESS_SHIFT downto ADDRESS_SHIFT);
                        else
                            axi_state <= IDLE;
                        end if;
                    when WRITE_BRAM =>
                        if (S_AXI_BREADY = '1' and S_AXI_WVALID = '1' and S_AXI_WLAST = '1') or single_write = '1' then
                            axi_state <= IDLE;
                            bram(to_integer(unsigned(current_bram_index))) := S_AXI_WDATA;
                            single_write <= '0';
                        else
                            axi_state <= WRITE_BRAM;
                            if S_AXI_WVALID = '1' then
                                current_bram_index <= std_logic_vector(unsigned(current_bram_index)+1);
                                bram(to_integer(unsigned(current_bram_index))) := S_AXI_WDATA;
                            end if;
                        end if;
                    when READ_BRAM =>
                        if unsigned(axi_arlen_cntr) = unsigned(S_AXI_AWLEN) then
                            axi_state <= IDLE;
                        else
                            axi_state <= READ_BRAM;
                            if S_AXI_RREADY = '1' then
                                current_bram_index <= std_logic_vector(unsigned(current_bram_index)+1);
                                axi_arlen_cntr <= std_logic_vector(unsigned(axi_arlen_cntr)+1);
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
end architecture;

