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
	constant SLAVES: integer := 2;
end config;

use work.config.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;

entity tb_interrupt_controller IS
end tb_interrupt_controller;

architecture behav of tb_interrupt_controller is

signal sigIN: std_logic_vector(SLAVES+2 downto 0);
signal sigINresp: std_logic_vector(SLAVES+2 downto 0);
signal sigitype: std_logic_vector(5 downto 0);
signal siginum: std_logic_vector(integer(ceil(log2(real(SLAVES+3))))-1 downto 0);
signal iresponse: std_logic;
signal aql_left: std_logic;
signal aql_left_resp: std_logic;
signal aql_left_resp_write: std_logic;
signal sigcuint: std_logic_vector(SLAVES+1 downto 0);
signal sigcuint_resp: std_logic_vector(SLAVES+1 downto 0);
signal sigcunum: std_logic_vector(integer(ceil(log2(real(SLAVES+2))))-1 downto 0);
signal sigworkint: std_logic;
signal enable: std_logic;
signal reset: std_logic;
signal clock: std_logic;

component INTERRUPT_CONTROLLER
generic(
	N: integer := 4
);
port(
    	RCV_INT_LANES: in std_logic_vector(N+2 downto 0);
    	RCV_INT_LANES_RESPONSE: out std_logic_vector(N+2 downto 0);
	RCV_INT_TYPE: out std_logic_vector(5 downto 0);
	RCV_INT_NUM: out std_logic_vector(integer(ceil(log2(real(N+3))))-1 downto 0);
	RCV_INT_RESPONSE: in std_logic;
	RCV_WORK_LEFT: out std_logic;
	RCV_WORK_LEFT_RESPONSE: in std_logic;
	RCV_WORK_LEFT_RESPONSE_WRITE: in std_logic;
    	SND_INT_LANES: out std_logic_vector(N+1 downto 0);
	SND_INT_LANES_RESPONSE: in std_logic_vector(N+1 downto 0);
	SND_INT_NUM: in std_logic_vector(integer(ceil(log2(real(N+2))))-1 downto 0);
	SND_INT_SIG: in std_logic;
    	EN: in std_logic;
	RE: in std_logic;
	CLK: in std_logic
);
end component;

begin

uut: INTERRUPT_CONTROLLER
generic map(
	N => SLAVES
)
port map(
	RCV_INT_LANES => sigIN,
	RCV_INT_LANES_RESPONSE => sigINresp,
	RCV_INT_TYPE => sigitype,
	RCV_INT_NUM => siginum,
	RCV_INT_RESPONSE => iresponse,
	RCV_WORK_LEFT => aql_left,
	RCV_WORK_LEFT_RESPONSE => aql_left_resp,
	RCV_WORK_LEFT_RESPONSE_WRITE => aql_left_resp_write,
    	SND_INT_LANES => sigcuint,
	SND_INT_LANES_RESPONSE => sigcuint_resp,
	SND_INT_NUM => sigcunum,
	SND_INT_SIG => sigworkint,
	EN => enable,
	RE => reset,
	CLK => clock
);

stimuli: process
begin
  reset <='0';
  enable <= '1';
  iresponse <= '0';
  aql_left_resp <= '0';
  aql_left_resp_write <= '0';
  sigcuint_resp <= "0000";
  sigcunum <= "00";
  sigworkint <= '0';
  -- TPC sends a signal that aql packets have arrived
  wait for 25 ns;
  reset <= '1';
  sigIN <= "10000";
  wait for 10 ns;
  sigIN <= "00000";
  -- PP starts dispatching jobs when the work bit is set
  if(aql_left /= '1') then
  	wait until aql_left = '1';
  end if;
  wait for 25 ns;
  -- notify CU 1
  sigcunum <= "01";
  sigworkint <= '1';
  wait for 20 ns;
  sigcunum <= "00";
  sigworkint <= '0';
  -- CU is processing the job
  if(sigcuint /= "0010") then
  	wait until sigcuint = "0010";
  end if;
  wait for 25 ns;
  sigcuint_resp <= "0010";
  wait for 20 ns;
  sigcuint_resp <= "0000";
  wait for 100 ns;
  sigIN <= "00010";
  wait for 20 ns;
  sigIN <= "00000";
  -- when the PP gets the job response it sends the ack
  if(sigitype /= "100000") then
  	wait until sigitype = "100000";
  end if;
  wait for 25 ns;
  iresponse <= '1';
  wait for 20 ns;
  iresponse <= '0';
  wait for 20 ns;
  -- PP sends the completion signal
  -- notify DMA via DEC signal
  sigcunum <= "11";
  sigworkint <= '1';
  wait for 20 ns;
  sigcunum <= "00";
  sigworkint <= '0';
  -- DMA controller is processing the job
  if(sigcuint /= "1000") then
  	wait until sigcuint = "1000";
  end if;
  wait for 25 ns;
  sigcuint_resp <= "1000";
  wait for 20 ns;
  sigcuint_resp <= "0000";
  wait for 100 ns;
  sigIN <= "00100";
  wait for 20 ns;
  sigIN <= "00000";
  -- when the PP gets the completion job response it sends the ack and signals that no more work is left
  if(sigitype /= "001000") then
  	wait until sigitype = "001000";
  end if;
  wait for 25 ns;
  iresponse <= '1';
  wait for 20 ns;
  iresponse <= '0';
  wait for 20 ns;
  aql_left_resp <= '0';
  aql_left_resp_write <= '1';
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

