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
use ieee.std_logic_textio.all;
library std;
use std.textio.all;
 
entity bram_sp is
generic (
    C_DATA        : integer := 32;      -- bits
    C_ADDR        : integer := 32;      -- bits
    C_SIZE        : integer := 128;     -- bits
    C_INIT_FILE   : string  := ""
);
port (
    -- Port A
    clk   : in  std_logic;
    en    : in  std_logic;
    wr    : in  std_logic;
    addr  : in  std_logic_vector(C_ADDR-1 downto 0);
    din   : in  std_logic_vector(C_DATA-1 downto 0);
    dout  : out std_logic_vector(C_DATA-1 downto 0)
);
end bram_sp;
 
architecture rtl of bram_sp is

    constant NUM_LINES : integer := (C_SIZE) / C_DATA; 

    -- Shared memory
    type RamType is array ( 0 to NUM_LINES-1 ) of std_logic_vector(C_DATA-1 downto 0);
    
    impure function InitRamWithZeros return RamType is
        variable RAM : RamType;
    begin
        for I in RamType'range loop
            RAM(I) := (others => '0');
        end loop;
        return RAM;
    end function;
    
    impure function InitRamFromFile return RamType is
        FILE filehandle : text is in C_INIT_FILE;
        variable RAM : RamType;
        variable current_line : line;
        variable current_word : std_logic_vector(C_DATA-1 downto 0);
    begin
        for I in RamType'range loop
            if endfile(filehandle) then
                RAM(I) := (others => '0');
            else
                readline(filehandle, current_line);
                hread(current_line, current_word);
                RAM(I) := current_word;
            end if;        
        end loop;
        return RAM;
    end function;
    
    impure function InitRam return RamType is
    begin
        if( C_INIT_FILE = "" ) then
            return InitRamWithZeros;
        else
            return InitRamFromFile;
        end if;
    end function;

    shared variable RAM:RamType:=InitRam;
    
begin

-- Port A
process(clk)
begin
    if(clk'event and clk='1') then
        if(en='1') then
            if(wr='1') then
                RAM(conv_integer(addr)) := din;
            end if;
            dout <= RAM(conv_integer(addr));
        end if;
    end if;
end process;
 
end rtl;
