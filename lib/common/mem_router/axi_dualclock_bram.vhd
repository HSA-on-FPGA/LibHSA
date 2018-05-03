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

entity axi_dualclock_bram is
Generic (
    BRAM_SIZE       : integer   := 16#1000#;    -- in bytes
    BRAM_ADDR_WIDTH : integer   := 32;
    DATA_WIDTH      : integer   := 32;
    AXI_ADDR_WIDTH  : integer   := 64;
    AXI_DATA_WIDTH  : integer   := 32;
    INIT_FILE       : string    := ""
);
Port (

    ---------------------------------
    -- BRAM
    BRAM_CLK   : in  std_logic;
    BRAM_EN    : in  std_logic;
    BRAM_WREN  : in  std_logic;
    BRAM_ADDR  : in  std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    BRAM_DIN   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    BRAM_DOUT  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    
    
    ---------------------------------
    -- AXI

	-- Global Clock Signal
    S_AXI_ACLK    : in std_logic;
    -- Global Reset Signal. This Signal is Active LOW
    S_AXI_ARESETN    : in std_logic;
   
    -- Write address. We assume it is always alligned to DATA_WIDTH.
    S_AXI_AWADDR    : in std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
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
end axi_dualclock_bram;
architecture Behavioral of axi_dualclock_bram is

    constant AXI_ADDR_DEVICE_BITS : integer := integer(ceil(log2(real(BRAM_SIZE))));

    type axi_state_type is (idle, response);
    signal axi_state   : axi_state_type;
    
    signal decoded_addr : std_logic_vector(BRAM_ADDR_WIDTH - 1 downto 0);
    signal decoded_addr_delayed : std_logic_vector(BRAM_ADDR_WIDTH - 1 downto 0);
    signal wdata_delayed : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    signal wstrb_delayed : std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0);
    signal wdata_strobed : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        
    signal axi_bram_dout : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    signal axi_bram_wen : std_logic;
    signal axi_bram_addr : std_logic_vector(BRAM_ADDR_WIDTH - 1 downto 0);

        
begin

    -- diable reads
    S_AXI_RVALID <= '0';
    S_AXI_RRESP <= (others => '0');
    S_AXI_RDATA <= (others => '0');
    S_AXI_ARREADY <= '0';

    -- bresp signal
    S_AXI_BRESP <= "00";
    S_AXI_BVALID <= '1' when axi_state = response else '0';

    axi_state_machine: process(S_AXI_ACLK, S_AXI_ARESETN)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_state <= idle;
            else
                case axi_state is
                    when idle=>
                        if S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' then
                            axi_state <= response;
                        else
                            axi_state <= idle;
                        end if;
                    when response=>
                        if S_AXI_BREADY = '1' then
                            axi_state <= idle;
                        else
                            axi_state <= response;
                        end if;
                end case;
            end if;
        end if;
    end process;

    S_AXI_AWREADY <= '1' when axi_state = idle else '0';
    S_AXI_WREADY <= '1' when axi_state = idle else '0';

    -- Address computation
    decoded_addr(AXI_ADDR_DEVICE_BITS - 1 downto 0) <= S_AXI_AWADDR(AXI_ADDR_DEVICE_BITS - 1 downto 0) when S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' else (others => '0');
    decoded_addr(BRAM_ADDR_WIDTH - 1 downto AXI_ADDR_DEVICE_BITS) <= (others => '0');
    axi_bram_addr <= decoded_addr when axi_state=idle else decoded_addr_delayed;
    
    hold_wdata : process(S_AXI_ACLK, S_AXI_ARESETN)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                decoded_addr_delayed <= (others => '0');
                wdata_delayed <= (others => '0');
                wstrb_delayed <= (others => '0');
            elsif S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and axi_state = idle then 
                decoded_addr_delayed <= decoded_addr;
                wdata_delayed <= S_AXI_WDATA;
                wstrb_delayed <= S_AXI_WSTRB;
            end if;
        end if;
    end process;

    -- generate signals for bram
    axi_bram_wen <= '1' when axi_state = response else '0';
    compute_strobed_wdata : process(wdata_delayed, wstrb_delayed, axi_bram_dout)
    begin
        for I in 0 to wstrb_delayed'length - 1 loop
            if wstrb_delayed(I) = '1' then
                wdata_strobed(8*(I+1)-1 downto 8*I) <= wdata_delayed(8*(I+1)-1 downto 8*I);
            else
                wdata_strobed(8*(I+1)-1 downto 8*I) <= axi_bram_dout(8*(I+1)-1 downto 8*I);
            end if;
    end loop;
    end process;

    -- BRAM
    dualclock_bram_inst : entity work.dualclock_bram
    generic map (
        DATA_A    => AXI_DATA_WIDTH,
        DATA_B    => DATA_WIDTH ,
        ADDR      => BRAM_ADDR_WIDTH,
        SIZE      => BRAM_SIZE,
        INIT_FILE => INIT_FILE
    )
    port map (
        a_clk => S_AXI_ACLK,
        a_addr => axi_bram_addr,
        a_din => wdata_strobed,
        a_dout => axi_bram_dout,
        a_en => axi_bram_wen,
        a_wr => axi_bram_wen,
        b_clk => BRAM_CLK,
        b_en => BRAM_EN,
        b_addr => BRAM_ADDR,
        b_din => BRAM_DIN,
        b_dout => BRAM_DOUT,
        b_wr => BRAM_WREN   
    );


end Behavioral;
