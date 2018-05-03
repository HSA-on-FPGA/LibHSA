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

entity INTERRUPT_ARBITER is
generic(
	N: integer := 4
);
port(
    	INT_LANES: in std_logic_vector(N-1 downto 0);
    	INT_LANES_RESPONSE: out std_logic_vector(N-1 downto 0);
	INT_NUM: out std_logic_vector(integer(ceil(log2(real(N))))-1 downto 0);
	INT_SIG: out std_logic;
    	EN: in std_logic;
	RE: in std_logic;
	CLK: in std_logic
);
end INTERRUPT_ARBITER;

architecture IA_RTL of INTERRUPT_ARBITER is

signal INTS: std_logic_vector(N-1 downto 0);
signal ACKS: std_logic_vector(N-1 downto 0);

begin

schedule: process(clk)
variable one_hot: std_logic_vector(N-1 downto 0);
variable encoded: integer := 0;
variable sigint: std_logic := '0';
begin
if(rising_edge(CLK)) then
	if(RE='0') then
		INTS <= (others=>'0');
		ACKS <= (others=>'0');
		INT_NUM <= (others=>'0');
		INT_SIG <= '0';
		INT_LANES_RESPONSE <= (others => '0');
	elsif(EN='1') then
		one_hot := INTS AND std_logic_vector(unsigned(NOT INTS)+1);
		encoded := 0;
		sigint := '0';
		for I in 0 to N-1 loop
			sigint := INTS(I) OR sigint;
			if(one_hot(I) = '1') then
				encoded := I;
			end if;
		end loop;
		INT_NUM <= std_logic_vector(to_unsigned(encoded,INT_NUM'length));
		INT_SIG <= sigint;
		INTS <= (INTS OR (INT_LANES AND (NOT ACKS))) AND (NOT one_hot);
		ACKS <= INT_LANES;
		INT_LANES_RESPONSE <= ACKS;
	else
		INTS <= INTS OR (INT_LANES AND (NOT ACKS));
		ACKS <= INT_LANES;
		INT_NUM <= (others=>'0');
		INT_SIG <= '0';
		INT_LANES_RESPONSE <= ACKS;
	end if;
end if;
end process;

end IA_RTL;
