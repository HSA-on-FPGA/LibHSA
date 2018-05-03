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
use ieee.std_logic_textio.all;
library std;
use std.textio.all;
 
entity bram_tdp is
generic (
    DATA        : integer := 32;      -- bits
    ADDR        : integer := 32;      -- bits
    SIZE        : integer := 128;     -- bits
    INIT_FILE   : string  := "";
    INIT_STRIDE : integer := 1;       -- words of size <DATA>. This must match the line size in <INIT_FILE>
    INIT_OFFSET : integer := 0        -- words of size <DATA>
);
port (
    -- Port A
    a_clk   : in  std_logic;
    a_en    : in  std_logic;
    a_wr    : in  std_logic;
    a_addr  : in  std_logic_vector(ADDR-1 downto 0);
    a_din   : in  std_logic_vector(DATA-1 downto 0);
    a_dout  : out std_logic_vector(DATA-1 downto 0);
     
    -- Port B
    b_clk   : in  std_logic;
    b_en    : in  std_logic;
    b_wr    : in  std_logic;
    b_addr  : in  std_logic_vector(ADDR-1 downto 0);
    b_din   : in  std_logic_vector(DATA-1 downto 0);
    b_dout  : out std_logic_vector(DATA-1 downto 0)
);
end bram_tdp;
 
architecture rtl of bram_tdp is


    constant NUM_LINES : integer := (SIZE) / DATA; 

    -- Shared memory
    type RamType is array ( 0 to NUM_LINES-1 ) of std_logic_vector(DATA-1 downto 0);
    
    impure function InitRamWithZeros return RamType is
        variable RAM : RamType;
    begin
        for I in RamType'range loop
            RAM(I) := (others => '0');
        end loop;
        return RAM;
    end function;
    
    impure function InitRamFromFile return RamType is
        FILE filehandle : text is in INIT_FILE;
        variable RAM : RamType;
        variable current_line : line;
        variable current_word : std_logic_vector(INIT_STRIDE * DATA - 1 downto 0);
    begin
        for I in RamType'range loop
            if endfile(filehandle) then
                RAM(I) := (others => '1');
            else
                readline(filehandle, current_line);
                hread(current_line, current_word);
                RAM(I) := current_word((INIT_OFFSET+1) * DATA - 1 downto INIT_OFFSET * DATA);
            end if;        
        end loop;
        return RAM;
    end function;
    
    impure function InitRam return RamType is
    begin
        if( INIT_FILE = "" ) then
            return InitRamWithZeros;
        else
            return InitRamFromFile;
        end if;
    end function;

    shared variable RAM:RamType:=InitRam;
    
begin

-- Port A
process(a_clk)
begin
    if(a_clk'event and a_clk='1') then
        if(a_en='1') then
            if(a_wr='1') then
                RAM(conv_integer(a_addr)) := a_din;
            end if;
            a_dout <= RAM(conv_integer(a_addr));
        end if;
    end if;
end process;
 
-- Port B
process(b_clk)
begin
    if(b_clk'event and b_clk='1') then
        if(b_en='1') then
            if(b_wr='1') then
                RAM(conv_integer(b_addr)) := b_din;
            end if;
            b_dout <= RAM(conv_integer(b_addr));
        end if;
    end if;
end process;
 
end rtl;
