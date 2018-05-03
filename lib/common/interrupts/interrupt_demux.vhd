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
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity INTERRUPT_DEMUX is
generic(
	N: integer := 4
);
port(
    	INT_LANES: out std_logic_vector(N-1 downto 0);
    	INT_LANES_RESPONSE: in std_logic_vector(N-1 downto 0);
	INT_NUM: in std_logic_vector(integer(ceil(log2(real(N))))-1 downto 0);
	INT_SIG: in std_logic;
    	EN: in std_logic;
	RE: in std_logic;
	CLK: in std_logic
);
end INTERRUPT_DEMUX;

architecture ID_RTL of INTERRUPT_DEMUX is

signal INTS: std_logic_vector(N-1 downto 0);

begin

distribute: process(RE,CLK)
begin
if(rising_edge(CLK)) then
if(RE='0') then
	INTS <= (others=>'0');
	INT_LANES <= (others=>'0');
else
	INTS <= INTS AND (NOT INT_LANES_RESPONSE);
	INT_LANES <= INTS;
	if(EN='1' AND INT_SIG='1') then
		INTS(to_integer(unsigned(INT_NUM))) <= '1';
	end if;
end if;
end if;
end process;

end ID_RTL;
