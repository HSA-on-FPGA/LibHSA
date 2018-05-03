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


-- A parameterized, inferable, true dual-port, dual-clock block RAM in VHDL.
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;



entity dualclock_bram is
generic (
    DATA_A    : integer := 32;    -- databus a size in bit
    DATA_B    : integer := 64;    -- databus b size in bit
    ADDR      : integer := 32;    -- ADDR is byte address, not line address
    SIZE      : integer := 32;   -- SIZE in bytes
    INIT_FILE : string  := ""
);
port (
    -- Port A
    a_clk   : in  std_logic;
    a_en    : in  std_logic;
    a_wr    : in  std_logic;
    a_addr  : in  std_logic_vector(ADDR-1 downto 0);
    a_din   : in  std_logic_vector(DATA_A-1 downto 0);
    a_dout  : out std_logic_vector(DATA_A-1 downto 0);
        
    -- Port B
    b_clk   : in  std_logic;
    b_en    : in  std_logic;
    b_wr    : in  std_logic;
    b_addr  : in  std_logic_vector(ADDR-1 downto 0);
    b_din   : in  std_logic_vector(DATA_B-1 downto 0);
    b_dout  : out std_logic_vector(DATA_B-1 downto 0)
);
end dualclock_bram;
 

  
architecture rtl of dualclock_bram is
    
    function MIN (LEFT, RIGHT: INTEGER) return INTEGER is
    begin
        if LEFT < RIGHT then return LEFT;
        else return RIGHT;
        end if;
    end MIN;
    function MAX (LEFT, RIGHT: INTEGER) return INTEGER is
    begin
        if LEFT > RIGHT then return LEFT;
        else return RIGHT;
        end if;
    end MAX;

    constant SMALLER_DATA : integer := MIN(DATA_A, DATA_B);
    constant LARGER_DATA : integer := MAX(DATA_A, DATA_B);
    
    constant NUM_BRAMS : integer := LARGER_DATA/SMALLER_DATA;
    
    constant SIZE_BITS : integer := 8* SIZE;

    constant BRAM_SIZE_BITS : integer := SIZE_BITS / NUM_BRAMS;
    constant BRAM_DATA_WIDTH : integer := SMALLER_DATA;

    constant BLIND_ADDR_BITS_LARGER : integer := integer(ceil(log2(real(LARGER_DATA/8))));
    constant BLIND_ADDR_BITS_SMALLER : integer := integer(ceil(log2(real(SMALLER_DATA/8))));

    constant BRAM_ID_ADDR_WIDTH : integer := integer(ceil(log2(real(NUM_BRAMS))));

    type bram_data_type is array ( NUM_BRAMS-1 downto 0 ) of std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    type bram_addr_type is array ( NUM_BRAMS-1 downto 0 ) of std_logic_vector(ADDR-1 downto 0);
    type bram_wr_type is array ( NUM_BRAMS-1 downto 0 ) of std_logic;
    
    signal bram_a_din : bram_data_type;
    signal bram_a_dout : bram_data_type;
    signal bram_a_addr : bram_addr_type;
    signal bram_a_wr : bram_wr_type;
    signal bram_b_din : bram_data_type;
    signal bram_b_dout : bram_data_type;
    signal bram_b_addr : bram_addr_type;
    signal bram_b_wr : bram_wr_type;
    
    signal a_addr_delayed : std_logic_vector(ADDR-1 downto 0);
    signal b_addr_delayed : std_logic_vector(ADDR-1 downto 0);

begin
 
    process (a_clk)
    begin
        if rising_edge(a_clk) then
            a_addr_delayed <= a_addr;
        end if;
    end process;

    process (b_clk)
    begin
        if rising_edge(b_clk) then
            b_addr_delayed <= b_addr;
        end if;
    end process;

    bram_instantiations:
    for i in 0 to NUM_BRAMS-1 generate
        bram_ints : entity work.bram_tdp
        generic map (
            DATA => BRAM_DATA_WIDTH,
            ADDR => ADDR,
            SIZE => BRAM_SIZE_BITS,
            INIT_FILE => INIT_FILE,
            INIT_STRIDE => NUM_BRAMS,
            INIT_OFFSET => i
        )
        port map ( 
            a_clk => a_clk,
            a_en => a_en,
            a_din => bram_a_din(i),
            a_dout => bram_a_dout(i),
            a_addr => bram_a_addr(i),
            a_wr => bram_a_wr(i),

            b_clk => b_clk,
            b_en => b_en,
            b_din => bram_b_din(i),
            b_dout => bram_b_dout(i),
            b_addr => bram_b_addr(i),
            b_wr => bram_b_wr(i)
        );  
    end generate;
    
    A_LARGER:
    if DATA_A = LARGER_DATA and DATA_B /= LARGER_DATA generate
    
        connect_larger_brams:
        for i in 0 to NUM_BRAMS-1 generate
            bram_a_wr(i) <= a_wr;        
            bram_a_din(i) <= a_din(BRAM_DATA_WIDTH*(i+1) -1 downto BRAM_DATA_WIDTH*i);
            a_dout (BRAM_DATA_WIDTH*(i+1) -1 downto BRAM_DATA_WIDTH*i) <= bram_a_dout(i);
            bram_a_addr(i)(ADDR-1 downto ADDR - BLIND_ADDR_BITS_LARGER) <= (others => '0');
            bram_a_addr(i)(ADDR - BLIND_ADDR_BITS_LARGER - 1 downto 0) <= a_addr(ADDR-1 downto BLIND_ADDR_BITS_LARGER);
        end generate;
        
        connect_smaller_brams:
        for i in 0 to NUM_BRAMS-1 generate
            bram_b_wr(i) <= b_wr when unsigned(b_addr(BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH - 1 downto BLIND_ADDR_BITS_SMALLER)) = i else '0';        
            bram_b_din(i) <= b_din;
            bram_b_addr(i)(ADDR-1 downto ADDR - (BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH)) <= (others => '0');
            bram_b_addr(i)(ADDR - (BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH) - 1 downto 0) <= b_addr(ADDR-1 downto BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH);
        end generate;
        b_dout <= bram_b_dout(to_integer(unsigned(b_addr_delayed(BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH - 1 downto BLIND_ADDR_BITS_SMALLER))));
                
        
    end generate;
    
    B_LARGER:
    if DATA_B = LARGER_DATA and DATA_A /= LARGER_DATA generate
    
        connect_larger_brams:
        for i in 0 to NUM_BRAMS-1 generate
            bram_b_wr(i) <= b_wr;        
            bram_b_din(i) <= b_din(BRAM_DATA_WIDTH*(i+1) -1 downto BRAM_DATA_WIDTH*i);
            b_dout (BRAM_DATA_WIDTH*(i+1) -1 downto BRAM_DATA_WIDTH*i) <= bram_b_dout(i);
            bram_b_addr(i)(ADDR-1 downto ADDR - BLIND_ADDR_BITS_LARGER) <= (others => '0');
            bram_b_addr(i)(ADDR - BLIND_ADDR_BITS_LARGER - 1 downto 0) <= b_addr(ADDR-1 downto BLIND_ADDR_BITS_LARGER);
        end generate;
        
        connect_smaller_brams:
        for i in 0 to NUM_BRAMS-1 generate
            bram_a_wr(i) <= a_wr when unsigned(a_addr(BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH - 1 downto BLIND_ADDR_BITS_SMALLER)) = i else '0';        
            bram_a_din(i) <= a_din;
            bram_a_addr(i)(ADDR-1 downto ADDR - (BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH)) <= (others => '0');
            bram_a_addr(i)(ADDR - (BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH) - 1 downto 0) <= a_addr(ADDR-1 downto BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH);
        end generate;
        a_dout <= bram_a_dout(to_integer(unsigned(a_addr_delayed(BLIND_ADDR_BITS_SMALLER + BRAM_ID_ADDR_WIDTH - 1 downto BLIND_ADDR_BITS_SMALLER))));

    end generate;
    
    BOTH_EVEN:
    if DATA_A = DATA_B generate
    
        bram_b_wr(0) <= b_wr;
        bram_b_din(0) <= b_din;
        b_dout <= bram_b_dout(0);
        bram_b_addr(0)(ADDR-1 downto ADDR - BLIND_ADDR_BITS_LARGER) <= (others => '0');
        bram_b_addr(0)(ADDR - BLIND_ADDR_BITS_LARGER - 1 downto 0) <= b_addr(ADDR-1 downto BLIND_ADDR_BITS_LARGER);
        
        bram_a_wr(0) <= a_wr;
        bram_a_din(0) <= a_din;
        a_dout <= bram_a_dout(0);
        bram_a_addr(0)(ADDR-1 downto ADDR - BLIND_ADDR_BITS_LARGER) <= (others => '0');
        bram_a_addr(0)(ADDR - BLIND_ADDR_BITS_LARGER - 1 downto 0) <= a_addr(ADDR-1 downto BLIND_ADDR_BITS_LARGER);

    end generate;
 
end rtl;
