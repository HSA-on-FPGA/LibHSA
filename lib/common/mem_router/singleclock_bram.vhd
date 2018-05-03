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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity singleclock_bram is
generic (
    C_DATA      : integer := 32;    -- databus a size in bit
    C_ADDR      : integer := 32;    -- ADDR is byte address, not line address
    C_SIZE      : integer := 32;   -- SIZE in bytes
    C_INIT_FILE : string  := ""
);
port (
    clk   : in  std_logic;
    en    : in  std_logic;
    wr    : in  std_logic;
    addr  : in  std_logic_vector(C_ADDR-1 downto 0);
    din   : in  std_logic_vector(C_DATA-1 downto 0);
    dout  : out std_logic_vector(C_DATA-1 downto 0)
);
end singleclock_bram;
 
architecture rtl of singleclock_bram is

    constant SIZE_BITS : integer := 8*C_SIZE;
    constant BLIND_ADDR_BITS : integer := integer(ceil(log2(real(C_DATA/8))));

    signal bram_din  : std_logic_vector(C_DATA-1 downto 0);
    signal bram_dout : std_logic_vector(C_DATA-1 downto 0);
    signal bram_addr : std_logic_vector(C_ADDR-1 downto 0);
    signal bram_wr   : std_logic;
    
    signal addr_delayed : std_logic_vector(C_ADDR-1 downto 0);

begin
 
    process (clk)
    begin
        if rising_edge(clk) then
            addr_delayed <= addr;
        end if;
    end process;

    bram_ints : entity work.bram_sp
    generic map (
        C_DATA => C_DATA,
        C_ADDR => C_ADDR,
        C_SIZE => SIZE_BITS,
        C_INIT_FILE => C_INIT_FILE
    )
    port map ( 
        clk  => clk,
        en   => en,
        din  => bram_din,
        dout => bram_dout,
        addr => bram_addr,
        wr   => bram_wr
    );
    
    bram_wr  <= wr;
    bram_din <= din;
    dout     <= bram_dout;
    bram_addr(C_ADDR-1 downto C_ADDR - BLIND_ADDR_BITS) <= (others => '0');
    bram_addr(C_ADDR - BLIND_ADDR_BITS-1 downto 0)  <= addr(C_ADDR-1 downto BLIND_ADDR_BITS);
 
end rtl;
