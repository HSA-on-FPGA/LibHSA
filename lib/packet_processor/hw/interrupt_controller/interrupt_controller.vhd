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

entity INTERRUPT_CONTROLLER is
generic(
	-- N is number of Accelerator Cores
	N: integer := 4
);
port(
	-- incoming interrupts
    	RCV_INT_LANES: in std_logic_vector(N+4 downto 0);
    	RCV_INT_LANES_RESPONSE: out std_logic_vector(N+4 downto 0);
	RCV_INT_TYPE: out std_logic_vector(5 downto 0);
	RCV_INT_NUM: out std_logic_vector(integer(ceil(log2(real(N+5))))-1 downto 0);
	RCV_INT_RESPONSE: in std_logic;
	RCV_WORK_LEFT: out std_logic;
	RCV_WORK_LEFT_RESPONSE: in std_logic;
	RCV_WORK_LEFT_RESPONSE_WRITE: in std_logic;
	-- outgoing interrupts
    	SND_INT_LANES: out std_logic_vector(N+3 downto 0);
	SND_INT_LANES_RESPONSE: in std_logic_vector(N+3 downto 0);
	SND_INT_NUM: in std_logic_vector(integer(ceil(log2(real(N+4))))-1 downto 0);
	SND_INT_SIG: in std_logic;
	-- more signals
    	EN: in std_logic;
	RE: in std_logic;
	CLK: in std_logic
);
end INTERRUPT_CONTROLLER;

architecture IC_RTL of INTERRUPT_CONTROLLER is

--internal registers
-- STATE:
-- 0 -> IDLE
-- 1 -> SEND
signal STATE: std_logic;
signal READY: std_logic;
signal INUMSLV: std_logic_vector(integer(ceil(log2(real(N+5))))-1 downto 0);
-- INTERRUPT TYPE:
-- 1 -> PROCESSING FINISHED
-- 2 -> TRANSACTION FINISHED
signal ITYPE: std_logic_vector(5 downto 0);
signal REG_WORK_LEFT: std_logic;
-- outgoing signals form arbiter
signal INT_NUM_OUT: std_logic_vector(integer(ceil(log2(real(N+5))))-1 downto 0);
signal ISIG: std_logic;

-- for sending interrupts: MSB for DEC, 2nd highest for DMA and rest for cores
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

-- for receiving interrupts: MSB for AQL, 2nd highest for DMA, 3rd highest for DEC and rest for cores
component INTERRUPT_ARBITER
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
end component;

begin

UID: INTERRUPT_DEMUX
generic map(
	N => N+4
)
port map(
    	INT_LANES => SND_INT_LANES,
    	INT_LANES_RESPONSE => SND_INT_LANES_RESPONSE,
	INT_NUM => SND_INT_NUM,
	INT_SIG => SND_INT_SIG,
    	EN => EN,
	RE => RE,
	CLK => CLK
);

UIA: INTERRUPT_ARBITER
generic map(
	N => N+5
)
port map(
    	INT_LANES => RCV_INT_LANES,
    	INT_LANES_RESPONSE => RCV_INT_LANES_RESPONSE,
	INT_NUM => INT_NUM_OUT,
	INT_SIG => ISIG,
    	EN => READY,
	RE => RE,
	CLK => CLK
);

READY <= ISIG NOR STATE;

processing: process(CLK)
begin
if(rising_edge(CLK)) then
if(RE='0') then
	STATE <= '0';
	ITYPE <= (others=>'0');
	INUMSLV <= (others=>'0');
	REG_WORK_LEFT <= '0';
	RCV_WORK_LEFT <= '0';
	RCV_INT_TYPE <= (others => '0');
	RCV_INT_NUM <= (others => '0');
else	
	-- internal signals
	STATE <= STATE;
	ITYPE <= ITYPE;
	INUMSLV <= INUMSLV;
	REG_WORK_LEFT <= REG_WORK_LEFT;
	-- outgoing signals
	RCV_INT_TYPE <= ITYPE;
	RCV_INT_NUM <= INUMSLV;
	RCV_WORK_LEFT <= REG_WORK_LEFT;
	if(EN='1') then
		if(RCV_WORK_LEFT_RESPONSE_WRITE='1') then
			REG_WORK_LEFT <= RCV_WORK_LEFT_RESPONSE;
			--forwarding value
			RCV_WORK_LEFT <= RCV_WORK_LEFT_RESPONSE;
		end if;
		case STATE is
			when '0' => 	
				if(ISIG='1') then
					-- work arrived interupt
					if(to_integer(unsigned(INT_NUM_OUT)) = N+4) then
						-- if the PP tries to reset the work register to 0, but an aql interrupt is pending in the same cycle, 
						-- use the conservative guess that more work is there (but the PP hasnt seen it yet) and leave the reg at value 1
						REG_WORK_LEFT <= '1';
						--forwarding value
						RCV_WORK_LEFT <= '1';
					-- DMA finished interrupt
					elsif(to_integer(unsigned(INT_NUM_OUT)) = N+3) then
						STATE <= '1';
						ITYPE <= "010000";
						INUMSLV <= INT_NUM_OUT;
						--interrupt forwarding
						RCV_INT_TYPE <= "010000";
						RCV_INT_NUM <= INT_NUM_OUT;
					-- decrement completion signal finished interrupt
					elsif(to_integer(unsigned(INT_NUM_OUT)) = N+2) then
						STATE <= '1';
						ITYPE <= "001000";
						INUMSLV <= INT_NUM_OUT;
						--interrupt forwarding
						RCV_INT_TYPE <= "001000";
						RCV_INT_NUM <= INT_NUM_OUT;
					-- add core interrupt
					elsif(to_integer(unsigned(INT_NUM_OUT)) = N+1) then
						STATE <= '1';
						ITYPE <= "000100";
						INUMSLV <= INT_NUM_OUT;
						--interrupt forwarding
						RCV_INT_TYPE <= "000100";
						RCV_INT_NUM <= INT_NUM_OUT;
					-- remove core interrupt
					elsif(to_integer(unsigned(INT_NUM_OUT)) = N) then
						STATE <= '1';
						ITYPE <= "000010";
						INUMSLV <= INT_NUM_OUT;
						--interrupt forwarding
						RCV_INT_TYPE <= "000010";
						RCV_INT_NUM <= INT_NUM_OUT;
					else
						STATE <= '1';
						ITYPE <= "100000";
						INUMSLV <= INT_NUM_OUT;
						--interrupt forwarding
						RCV_INT_TYPE <= "100000";
						RCV_INT_NUM <= INT_NUM_OUT;
					end if;
				end if;
			when '1' =>
				if(RCV_INT_RESPONSE = '1') then
					STATE <= '0';
					ITYPE <= "000000";
					RCV_INT_TYPE <= "000000";
				end if;
			when others => STATE <= STATE;
		end case;
	end if;
end if;
end if;
end process;

end IC_RTL;
