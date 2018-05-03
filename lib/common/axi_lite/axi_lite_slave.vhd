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

use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity axi_lite_slave is
Generic (
    AXI_ADDR_WIDTH  : integer   := 64;
    AXI_DATA_WIDTH  : integer   := 64
);
Port (

    ---------------------------------
    -- OUT
    ADDR        : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    READ_DATA   : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    READ_EN     : out std_logic;
    WRITE_DATA  : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    WRITE_EN    : out std_logic;
    COMPLETED   : in  std_logic;
    ERROR       : in  std_logic;

    ---------------------------------
    -- AXI

	-- Global Clock Signal
    S_AXI_ACLK    : in std_logic;
    -- Global Reset Signal. This Signal is Active LOW
    S_AXI_ARESETN    : in std_logic;
   
    -- Write address. We assume it is always alligned to DATA_WIDTH.
    S_AXI_AWADDR    : in std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
    -- Write address valid. This signal indicates that
    -- the channel is signaling valid write address and
    -- control information.
    S_AXI_AWVALID    : in std_logic;
    -- Write address ready. This signal indicates that
    -- the slave is ready to accept an address and associated
    -- control signals.
    S_AXI_AWREADY    : out std_logic;
   
    -- Write Data
    S_AXI_WDATA    : in std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    -- Write strobes. This signal indicates which byte
    -- lanes hold valid data. There is one write strobe
    -- bit for each eight bits of the write data bus.
    S_AXI_WSTRB    : in std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0);
    -- Write valid. This signal indicates that valid write
    -- data and strobes are available.
    S_AXI_WVALID    : in std_logic;
    -- Write ready. This signal indicates that the slave
    -- can accept the write data.
    S_AXI_WREADY    : out std_logic;
   
    -- Write response. This signal indicates the status
    -- of the write transaction.
    S_AXI_BRESP    : out std_logic_vector(1 downto 0);
    -- Write response valid. This signal indicates that the
    -- channel is signaling a valid write response.
    S_AXI_BVALID    : out std_logic;
    -- Response ready. This signal indicates that the master
    -- can accept a write response.
    S_AXI_BREADY    : in std_logic;
    -- Read address. This signal indicates the initial
    -- address of a read burst transaction.
    S_AXI_ARADDR    : in std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
    -- Write address valid. This signal indicates that
    -- the channel is signaling valid read address and
    -- control information.
    S_AXI_ARVALID    : in std_logic;
    -- Read address ready. This signal indicates that
    -- the slave is ready to accept an address and associated
    -- control signals.
    S_AXI_ARREADY    : out std_logic;
    -- Read Data
    S_AXI_RDATA    : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    -- Read response. This signal indicates the status of
    -- the read transfer.
    S_AXI_RRESP    : out std_logic_vector(1 downto 0);
    -- Read valid. This signal indicates that the channel
    -- is signaling the required read data.
    S_AXI_RVALID    : out std_logic;
    -- Read ready. This signal indicates that the master can
    -- accept the read data and response information.
    S_AXI_RREADY    : in std_logic
);
end axi_lite_slave;

architecture Behavioral of axi_lite_slave is

    type axi_state_type is (idle, write_response, read_response);
    signal axi_state   : axi_state_type;
    
    signal decoded_addr : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
    signal decoded_addr_delayed : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
    signal wdata_delayed : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        
    signal axi_ram_addr : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
    signal axi_ram_dout : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    signal axi_ram_wen  : std_logic;
    signal axi_ram_ren  : std_logic;

        
begin

    S_AXI_RVALID <= '1' when axi_state = read_response and COMPLETED = '1' else '0';
    S_AXI_RRESP <= "00";
    S_AXI_RDATA <= axi_ram_dout when axi_state = read_response and COMPLETED = '1' else (others => '0');
    S_AXI_ARREADY <= '1' when axi_state = idle else '0';

    -- bresp signal
    S_AXI_BRESP <= "00";
    S_AXI_BVALID <= '1' when axi_state = write_response and COMPLETED = '1' else '0';

    axi_state_machine: process(S_AXI_ACLK, S_AXI_ARESETN)
    begin
        if S_AXI_ARESETN = '0' then
            axi_state <= idle;
        elsif rising_edge(S_AXI_ACLK) then
            case axi_state is
                when idle=>
                    if S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' then
                        axi_state <= write_response;
                    elsif S_AXI_ARVALID = '1' then
                        axi_state <= read_response;
                    else
                        axi_state <= idle;
                    end if;
                when write_response=>
                    if S_AXI_BREADY = '1' and COMPLETED = '1' then
                        axi_state <= idle;
                    else
                        axi_state <= write_response;
                    end if;
                when read_response=>
                    if S_AXI_RREADY = '1' and COMPLETED = '1' then
                        axi_state <= idle;
                    else
                        axi_state <= read_response;
                    end if;
            end case;
        end if;
    end process;

    S_AXI_AWREADY <= '1' when axi_state = idle else '0';
    S_AXI_WREADY <= '1' when axi_state = idle else '0';

    -- Address computation
    decoded_addr <= S_AXI_AWADDR when S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' else
                    S_AXI_ARADDR when S_AXI_ARVALID = '1' else (others => '0');
    axi_ram_addr <= decoded_addr when axi_state=idle else decoded_addr_delayed;
    
    hold_data : process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                decoded_addr_delayed <= (others => '0');
                wdata_delayed <= (others => '0');
            elsif ((S_AXI_WVALID = '1' and S_AXI_AWVALID = '1') or S_AXI_ARVALID = '1') and axi_state = idle then 
                decoded_addr_delayed <= decoded_addr;
                wdata_delayed <= S_AXI_WDATA;
	    else
                decoded_addr_delayed <= decoded_addr_delayed;
                wdata_delayed <= wdata_delayed;
            end if;
        end if;
    end process;

    -- generate signals for bram
    axi_ram_wen <= '1' when axi_state = write_response else '0';
    axi_ram_ren <= '1' when axi_state = read_response  else '0';

    -- output
    ADDR          <= axi_ram_addr;
    WRITE_DATA    <= wdata_delayed;
    WRITE_EN      <= axi_ram_wen;
    READ_EN       <= axi_ram_ren;
    axi_ram_dout <= READ_DATA;


end Behavioral;




