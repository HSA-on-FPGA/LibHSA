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
	constant SLAVES: integer := 1;
end config;

use work.config.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;

entity tb_interrupt_transfer IS
end tb_interrupt_transfer;

architecture behav of tb_interrupt_transfer is

signal enable: std_logic;
signal reset: std_logic;
signal clock: std_logic;

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

signal irq_transfer: std_logic_vector(SLAVES-1 downto 0);
signal irq_transfer_ack: std_logic_vector(SLAVES-1 downto 0);
signal irq_transfer2: std_logic_vector(SLAVES-1 downto 0);
signal irq_transfer_ack2: std_logic_vector(SLAVES-1 downto 0);

signal sigIN2: std_logic_vector(SLAVES+2 downto 0);
signal sigINresp2: std_logic_vector(SLAVES+2 downto 0);
signal sigitype2: std_logic_vector(5 downto 0);
signal siginum2: std_logic_vector(integer(ceil(log2(real(SLAVES+3))))-1 downto 0);
signal iresponse2: std_logic;
signal aql_left2: std_logic;
signal aql_left_resp2: std_logic;
signal aql_left_resp_write2: std_logic;
signal sigcuint2: std_logic_vector(SLAVES+1 downto 0);
signal sigcuint_resp2: std_logic_vector(SLAVES+1 downto 0);
signal sigcunum2: std_logic_vector(integer(ceil(log2(real(SLAVES+2))))-1 downto 0);
signal sigworkint2: std_logic;

signal snd_dma_irq    	: std_logic;
signal snd_cpl_irq    	: std_logic;
signal rcv_aql_irq_ack	: std_logic;
signal rcv_dma_irq_ack	: std_logic;
signal rcv_cpl_irq_ack	: std_logic;
signal snd_dma_irq2    	: std_logic;
signal snd_cpl_irq2    	: std_logic;
signal rcv_aql_irq_ack2	: std_logic;
signal rcv_dma_irq_ack2	: std_logic;
signal rcv_cpl_irq_ack2	: std_logic;

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

uut1: INTERRUPT_CONTROLLER
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

uut2: INTERRUPT_CONTROLLER
generic map(
	N => SLAVES
)
port map(
	RCV_INT_LANES => sigIN2,
	RCV_INT_LANES_RESPONSE => sigINresp2,
	RCV_INT_TYPE => sigitype2,
	RCV_INT_NUM => siginum2,
	RCV_INT_RESPONSE => iresponse2,
	RCV_WORK_LEFT => aql_left2,
	RCV_WORK_LEFT_RESPONSE => aql_left_resp2,
	RCV_WORK_LEFT_RESPONSE_WRITE => aql_left_resp_write2,
    	SND_INT_LANES => sigcuint2,
	SND_INT_LANES_RESPONSE => sigcuint_resp2,
	SND_INT_NUM => sigcunum2,
	SND_INT_SIG => sigworkint2,
	EN => enable,
	RE => reset,
	CLK => clock
);

-- ic1 to ic2
snd_dma_irq		<= sigcuint(SLAVES+1);
snd_cpl_irq		<= sigcuint(SLAVES);
irq_transfer 		<= sigcuint(SLAVES-1 downto 0);

rcv_aql_irq_ack		<= sigINresp(SLAVES+2);
rcv_dma_irq_ack		<= sigINresp(SLAVES+1);
rcv_cpl_irq_ack		<= sigINresp(SLAVES);
irq_transfer_ack2 	<= sigINresp(SLAVES-1 downto 0);

sigIN2	 	<= "000" & irq_transfer;
sigcuint_resp2	<= "00" & irq_transfer_ack2;

-- ic2 to ic1
snd_dma_irq2		<= sigcuint2(SLAVES+1);
snd_cpl_irq2		<= sigcuint2(SLAVES);
irq_transfer2 		<= sigcuint2(SLAVES-1 downto 0);

rcv_aql_irq_ack2	<= sigINresp2(SLAVES+2);
rcv_dma_irq_ack2	<= sigINresp2(SLAVES+1);
rcv_cpl_irq_ack2	<= sigINresp2(SLAVES);
irq_transfer_ack 	<= sigINresp2(SLAVES-1 downto 0);

sigIN	 	<= "000" & irq_transfer2;
sigcuint_resp	<= "00" & irq_transfer_ack;


stimuli: process
begin
  reset <='0';
  enable <= '1';
  iresponse <= '0';
  aql_left_resp <= '0';
  aql_left_resp_write <= '0';
  sigworkint <= '0';
  sigcunum <= "00";
  iresponse2 <= '0';
  aql_left_resp2 <= '0';
  aql_left_resp_write2 <= '0';
  sigworkint2 <= '0';
  sigcunum2 <= "00";
  wait for 25 ns;
  reset <= '1';
  wait for 25 ns;
  -- notify CU
  sigcunum <= "00";
  sigworkint <= '1';
  wait for 20 ns;
  sigcunum <= "00";
  sigworkint <= '0';
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

