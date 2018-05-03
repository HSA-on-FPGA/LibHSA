-- memory_access_64: Memory access unit for mips pipeline
-- Copyright 2017 Tobias Lieske, Steffen Vaas
--
-- tobias.lieske@fau.de
-- steffen.vaas@fau.de
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

--------------------------------------------------------------------------------
-- LIBRARY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
entity memory_access_64 is
	generic(
        G_EXC_ADDRESS_ERROR_LOAD    : boolean := false;
        G_EXC_ADDRESS_ERROR_STORE   : boolean := false;
        G_EXC_DATA_BUS_ERROR        : boolean := false
    );
	port(
        clk                         : in  std_logic;
        resetn                      : in  std_logic;
        enable                      : in  std_logic;

		-- data path
		alu_result_in		        : in  std_logic_vector(63 downto 0);	-- Speicheradresse
        mem_address_in              : in  std_logic_vector(63 downto 0);
		reg_data_in			        : in  std_logic_vector(63 downto 0);	-- Speicherwert

		alu_result_out		        : out std_logic_vector(63 downto 0);	-- ALU Ergebnis durchreichen, falls Speicher nicht verwendet
		memory_data			        : out std_logic_vector(63 downto 0);	-- gelesener Speicherwert


		mem_address			        : out std_logic_vector(63 downto 0);	-- Verbindungen zur Speichereinheit cpu_memory_sim.vhd
		mem_data_write		        : out std_logic_vector(63 downto 0);
		mem_data_read		        : in  std_logic_vector(63 downto 0);

        data_read_busy              : in  std_logic;
        data_write_busy             : in  std_logic;

        address_error_exc_load      : in  std_logic;
        address_error_exc_store     : in  std_logic;
        data_bus_exc                : in  std_logic;

        -- flush execute
        flush_execute               : out std_logic;

        ctrl_mem_in                 : in  std_logic_vector( 8 downto 0);
        ctrl_mem_out                : out std_logic_vector( 8 downto 0);
        data_read_access		    : out std_logic;
        data_write_access		    : out std_logic;

        unaligned_mem_access_busy   : out std_logic;

		ctrl_wb_in			        : in  std_logic_vector( 1 downto 0);
		ctrl_wb_out			        : out std_logic_vector( 1 downto 0)

	);
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of memory_access_64 is

--------------------------------------------------------------------------------
-- COMPONENTS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

-- /*end-folding-block*/

    type state_t is (NORMAL, UNALIGNED);
    signal state    : state_t;
    signal state_n  : state_t;

    signal s_address_error_exc_load     : std_logic;
    signal s_address_error_exc_store    : std_logic;
    signal s_data_bus_exc               : std_logic;
    signal s_flush_execute              : std_logic;

    signal s_unaligned_memory_write_exc : std_logic;
    signal s_unaligned_memory_read_exc  : std_logic;

    alias mem_read                  : std_logic is ctrl_mem_in(1);
    alias mem_write                 : std_logic is ctrl_mem_in(0);
    alias mem_byte                  : std_logic is ctrl_mem_in(2);
    alias mem_halfword              : std_logic is ctrl_mem_in(3);
    alias mem_word                  : std_logic is ctrl_mem_in(4);
    alias mem_unsigned              : std_logic is ctrl_mem_in(5);
    alias mem_byte_access_offset    : std_logic_vector(2 downto 0) is ctrl_mem_in(8 downto 6);

    signal reg_unaligned_write_adr  : std_logic_vector(63 downto 0);
    signal reg_unaligned_write_data : std_logic_vector(63 downto 0);
    signal reg_ctrl_mem             : std_logic_vector(8 downto 0);

    alias reg_mem_read                  : std_logic is reg_ctrl_mem(1);
    alias reg_mem_write                 : std_logic is reg_ctrl_mem(0);
    alias reg_mem_byte                  : std_logic is reg_ctrl_mem(2);
    alias reg_mem_halfword              : std_logic is reg_ctrl_mem(3);
    alias reg_mem_word                  : std_logic is reg_ctrl_mem(4);
    alias reg_mem_unsigned              : std_logic is reg_ctrl_mem(5);
    alias reg_mem_byte_access_offset    : std_logic_vector(2 downto 0) is reg_ctrl_mem(8 downto 6);

    signal init                     : std_logic;

    signal s_mem_data_write         : std_logic_vector(63 downto 0);

begin

--------------------------------------------------------------------------------
-- PORT MAPS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- COMBINATIONAL
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    ctrl_mem_out <= ctrl_mem_in;

    mem_data_write <= s_mem_data_write;

    process(clk, resetn)
    begin
        if (resetn = '0') then
            state <= NORMAL;
        elsif (clk'event and clk = '1') then
            if (enable = '1') then
                state <= state_n;
            end if;
        end if;
    end process;

    reg_proc: process(clk, resetn)
    begin
        if (resetn = '0') then
            init <= '1';
            reg_unaligned_write_adr <= (others => '0');
            reg_unaligned_write_data <= (others => '0');
            reg_ctrl_mem <= (others => '0');
        elsif (clk'event and clk = '1') then
            if (enable = '1') then
                case state is
                    when NORMAL =>
                        if (mem_write = '1' and
                            (mem_byte = '1' or mem_halfword = '1' or mem_word = '1') and
                            (
                                init = '1' or
                                (reg_unaligned_write_adr /= mem_address_in and reg_unaligned_write_data /= reg_data_in)
                            )
                        ) then
                            init <= '0';
                            reg_unaligned_write_adr <= mem_address_in;
                            reg_unaligned_write_data <= reg_data_in;
                            reg_ctrl_mem <= ctrl_mem_in;
                        end if;

                    when UNALIGNED =>
                        -- word loaded
                        if (data_read_busy = '0') then
                            init <= '1';
                        end if;

                    when others =>
                        -- dummy

                end case;
            end if;
        end if;
    end process;

    unaligned_write: process(state, ctrl_mem_in, data_read_busy, mem_byte,
        mem_data_read, mem_write, mem_halfword, init, reg_unaligned_write_adr,
        mem_address_in, reg_unaligned_write_data, reg_data_in,
        mem_byte_access_offset, reg_mem_byte, reg_mem_byte_access_offset
    )
    begin
        data_read_access <= '0';
        data_write_access <= '0';
        unaligned_mem_access_busy <= '0';
        s_unaligned_memory_write_exc <= '0';
        s_unaligned_memory_read_exc <= '0';
        s_mem_data_write <= mem_data_read;
        state_n <= state;
        mem_address <= mem_address_in;
        case state is
            when NORMAL =>
                -- unaligned memory access
                if (mem_write = '1' and (mem_byte = '1' or mem_halfword = '1' or mem_word = '1') and
                    (
                        init = '1' or
                        (reg_unaligned_write_adr /= mem_address_in and reg_unaligned_write_data /= reg_data_in)
                    )
                ) then
                    state_n <= UNALIGNED;
                    -- load complete word
                    data_read_access <= '1';
                else
                    if (mem_read = '1') then
                        data_read_access <= '1';
                        if (
                            -- load halfword must be 2 byte aligned
                            (mem_halfword = '1' and mem_byte_access_offset(0) = '1')
                            or
                            -- load word must be 4 byte aligned
                            (mem_word = '1' and mem_byte_access_offset(1 downto 0) /= "00")
                        ) then
                            s_unaligned_memory_read_exc <= '1';
                        end if;
                    end if;
                    if (mem_write = '1') then
                        s_mem_data_write	<= reg_data_in;
                        data_write_access <= '1';
                    end if;
                end if;

            when UNALIGNED =>
                mem_address <= reg_unaligned_write_adr;
                -- following memory access
                if (mem_read = '1' or mem_write = '1') then
                    unaligned_mem_access_busy <= '1';
                end if;
                -- word loaded
                if (data_read_busy = '0') then
                    -- update byte
                    if (reg_mem_byte = '1') then
                        case reg_mem_byte_access_offset is
                            when "000" =>
                                s_mem_data_write(63 downto  8) <= mem_data_read(63 downto  8);
                                s_mem_data_write( 7 downto  0) <= reg_unaligned_write_data(7 downto 0);
                            when "001" =>
                                s_mem_data_write(63 downto 16) <= mem_data_read(63 downto 16);
                                s_mem_data_write(15 downto  8) <= reg_unaligned_write_data(7 downto 0);
                                s_mem_data_write( 7 downto  0) <= mem_data_read( 7 downto  0);
                            when "010" =>
                                s_mem_data_write(63 downto 24) <= mem_data_read(63 downto 24);
                                s_mem_data_write(23 downto 16) <= reg_unaligned_write_data(7 downto 0);
                                s_mem_data_write(15 downto  0) <= mem_data_read(15 downto  0);
                            when "011" =>
                                s_mem_data_write(63 downto 32) <= mem_data_read(63 downto 32);
                                s_mem_data_write(31 downto 24) <= reg_unaligned_write_data(7 downto 0);
                                s_mem_data_write(23 downto  0) <= mem_data_read(23 downto  0);
                            when "100" =>
                                s_mem_data_write(63 downto 40) <= mem_data_read(63 downto 40);
                                s_mem_data_write(39 downto 32) <= reg_unaligned_write_data(7 downto 0);
                                s_mem_data_write(31 downto  0) <= mem_data_read(31 downto  0);
                            when "101" =>
                                s_mem_data_write(63 downto 48) <= mem_data_read(63 downto 48);
                                s_mem_data_write(47 downto 40) <= reg_unaligned_write_data(7 downto 0);
                                s_mem_data_write(39 downto  0) <= mem_data_read(39 downto  0);
                            when "110" =>
                                s_mem_data_write(63 downto 56) <= mem_data_read(63 downto 56);
                                s_mem_data_write(55 downto 48) <= reg_unaligned_write_data(7 downto 0);
                                s_mem_data_write(47 downto  0) <= mem_data_read(47 downto  0);
                            when "111" =>
                                s_mem_data_write(63 downto 56) <= reg_unaligned_write_data(7 downto 0);
                                s_mem_data_write(55 downto  0) <= mem_data_read(55 downto  0);
                            when others =>
                                -- dummy
                                s_mem_data_write(31 downto  8) <= mem_data_read(31 downto  8);
                                s_mem_data_write( 7 downto  0) <= reg_unaligned_write_data(7 downto 0);
                        end case;
                    -- update halfword
                    elsif (reg_mem_halfword = '1') then
                    -- avoid latches
                        case reg_mem_byte_access_offset is
                            when "000" =>
                                s_mem_data_write(63 downto 16) <= mem_data_read(63 downto 16);
                                s_mem_data_write(15 downto  0) <= reg_unaligned_write_data(15 downto 0);
                            when "010" =>
                                s_mem_data_write(63 downto 32) <= mem_data_read(63 downto 32);
                                s_mem_data_write(31 downto 16) <= reg_unaligned_write_data(15 downto 0);
                                s_mem_data_write(15 downto  0) <= mem_data_read(15 downto  0);
                            when "100" =>
                                s_mem_data_write(63 downto 48) <= mem_data_read(63 downto 48);
                                s_mem_data_write(47 downto 32) <= reg_unaligned_write_data(15 downto 0);
                                s_mem_data_write(31 downto  0) <= mem_data_read(31 downto 0);
                            when "110" =>
                                s_mem_data_write(63 downto 48) <= reg_unaligned_write_data(15 downto 0);
                                s_mem_data_write(47 downto  0) <= mem_data_read(47 downto  0);
                            when others =>
                                s_unaligned_memory_write_exc <= '1';
                        end case;
                    -- update word
                    -- elsif (reg_mem_word = '1') then
                    else
                        case reg_mem_byte_access_offset is
                            when "000" =>
                                s_mem_data_write(63 downto 32) <= mem_data_read(63 downto 32);
                                s_mem_data_write(31 downto  0) <= reg_unaligned_write_data(31 downto 0);
                            when "100" =>
                                s_mem_data_write(63 downto 32) <= reg_unaligned_write_data(31 downto 0);
                                s_mem_data_write(31 downto  0) <= mem_data_read(31 downto 0);
                            when others =>
                                s_unaligned_memory_write_exc <= '1';
                        end case;
                    end if;
                    -- write back updated word
                    state_n <= NORMAL;
                    data_write_access <= '1';
                -- word not yet loaded
                else
                    -- another memory access occurs while the unaligned write
                    -- acces has not finished yet, stall the pipeline
                    if (mem_read = '1' or mem_write = '1') then
                        unaligned_mem_access_busy <= '1';
                    end if;
                end if;

            when others =>
                -- dummy

        end case;
    end process;



	alu_result_out	<= alu_result_in;

	memory_data		<= mem_data_read;

    s_flush_execute <= s_address_error_exc_load or s_address_error_exc_store or s_data_bus_exc;
    flush_execute   <= s_flush_execute;

    with s_flush_execute select
        ctrl_wb_out <= ctrl_wb_in when '0',
                       (others => '0') when others;

    address_error_exc_load_enabled : if (G_EXC_ADDRESS_ERROR_LOAD = true) generate
        s_address_error_exc_load <= address_error_exc_load or s_unaligned_memory_read_exc;
    end generate address_error_exc_load_enabled;

    address_error_exc_load_disabled : if (G_EXC_ADDRESS_ERROR_LOAD = false) generate
        s_address_error_exc_load <= '0';
    end generate address_error_exc_load_disabled;

    address_error_exc_store_enabled : if (G_EXC_ADDRESS_ERROR_STORE = true) generate
        s_address_error_exc_store <= address_error_exc_store or s_unaligned_memory_write_exc;
    end generate address_error_exc_store_enabled;

    address_error_exc_store_disabled : if (G_EXC_ADDRESS_ERROR_STORE = false) generate
        s_address_error_exc_store <= '0';
    end generate address_error_exc_store_disabled;

    data_bus_exc_enabled : if (G_EXC_DATA_BUS_ERROR = true) generate
        s_data_bus_exc <= data_bus_exc;
    end generate data_bus_exc_enabled;

    data_bus_exc_disabled : if (G_EXC_DATA_BUS_ERROR = false) generate
        s_data_bus_exc <= '0';
    end generate data_bus_exc_disabled;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/


-- /*end-folding-block*/

end architecture;

