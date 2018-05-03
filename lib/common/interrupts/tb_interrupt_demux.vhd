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

package config is
	constant SLAVES: integer := 8;
end config;

use work.config.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;

entity tb_interrupt_demux IS
end tb_interrupt_demux;

architecture behav of tb_interrupt_demux is

signal sigOUT: std_logic_vector(SLAVES-1 downto 0);
signal sigintresp: std_logic_vector(SLAVES-1 downto 0);
signal sigIN: std_logic_vector(integer(ceil(log2(real(SLAVES))))-1 downto 0);
signal interrupt: std_logic;
signal enable: std_logic;
signal reset: std_logic;
signal clock: std_logic;

component INTERRUPT_DEMUX
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
end component;

begin

uut: INTERRUPT_DEMUX
generic map(
	N => SLAVES
)
port map(
  INT_LANES => sigOUT,
  INT_LANES_RESPONSE => sigintresp,
  INT_NUM => sigIN,
  INT_SIG => interrupt,
  EN => enable,
  RE => reset,
  CLK => clock
);

stimuli: process
begin
  reset <='0';
  enable <= '1';
  interrupt <= '0';
  sigintresp <= x"00";
  wait for 25 ns;
  reset <= '1';
  sigIN <= "001";
  interrupt <= '1';
  wait for 20 ns;
  sigIN <= "011";
  wait for 10 ns;
  interrupt <= '0';
  sigIN <= "000";
  wait for 100 ns;
  sigintresp <= x"02";
  wait for 20 ns;
  sigintresp <= x"08";
  wait;
end process;

clock_P: process
begin
clock <= '0';
wait for 10 ns;
clock <= '1';
wait for 10 ns;
end process;

end behav;

