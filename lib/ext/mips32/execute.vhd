-- execute: Execute unit for mips pipeline
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
use work.alu_pkg.all;
--use ieee.math_real.all;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
-- /*start-folding-block*/
entity execute is
    generic(
        G_EXC_ARITHMETIC_OVERFLOW   : boolean := false;
        G_SENSOR_DATA_WIDTH         : integer range 1 to 1024;
        G_SENSOR_CONF_WIDTH         : integer range 1 to 1024;
        G_BUSY_LIST_WIDTH           : integer range 1 to 1024
    );
    port(
        -- general
        clk                 : in  std_logic;
        resetn              : in  std_logic;
        enable              : in  std_logic;

        -- data path
        reg_data_in_1       : in  std_logic_vector(31 downto 0);
        reg_data_in_2       : in  std_logic_vector(31 downto 0);
        immediate_value     : in  std_logic_vector(31 downto 0);
        dest_reg_in         : in  std_logic_vector( 4 downto 0);

        alu_result          : out std_logic_vector(31 downto 0);
        reg_data_out        : out std_logic_vector(31 downto 0);
        dest_reg_out        : out std_logic_vector( 4 downto 0);

        -- forwarding
        forward_rs_addr     : in  std_logic_vector( 4 downto 0);
        forward_rt_addr     : in  std_logic_vector( 4 downto 0);
        forward_dest_ex_mem : in  std_logic_vector( 4 downto 0);
        forward_dest_mem_wb : in  std_logic_vector( 4 downto 0);
        forward_ex_mem      : in  std_logic_vector(31 downto 0);
        forward_mem_wb      : in  std_logic_vector(31 downto 0);
        ctrl_reg_write_ex_mem: in  std_logic;
        ctrl_reg_write_mem_wb: in  std_logic;

        -- control path
        alu_flags           : out std_logic_vector( 4 downto 0);
        alu_src             : in  std_logic;
        alu_ctrl            : in  alu_ctrl_t;

        ctrl_mem_in         : in  std_logic_vector( 4 downto 0);
        ctrl_wb_in          : in  std_logic_vector( 1 downto 0);

        ctrl_mem_out        : out std_logic_vector( 6 downto 0);
        ctrl_wb_out         : out std_logic_vector( 1 downto 0);

        flush               : in  std_logic;
        -- ASIP
        done                : out std_logic;
        busy_list           : out std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);
        sensor_data_in      : in  std_logic_vector(G_SENSOR_DATA_WIDTH-1 downto 0);
        sensor_config_out   : out std_logic_vector(G_SENSOR_CONF_WIDTH-1 downto 0)
    );
end entity;
-- /*end-folding-block*/



--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture behav of execute is

--------------------------------------------------------------------------------
-- COMPONENTS
--------------------------------------------------------------------------------
-- /*start-folding-block*/

    component asip_alu is
        generic (
            G_SENSOR_DATA_WIDTH     : integer range 1 to 1024;
            G_SENSOR_CONF_WIDTH     : integer range 1 to 1024;
            G_BUSY_LIST_WIDTH       : integer range 1 to 1024
        );
        port (
            -- general
            clk             : in  std_logic;
            en              : in  std_logic;
            arstn           : in  std_logic;

            -- exception
            abort           : in  std_logic;

            -- inputs
            alu_op          : in  alu_ctrl_t;
            input0          : in  std_logic_vector(31 downto 0);
            input1          : in  std_logic_vector(31 downto 0);
            sensor_input    : in  std_logic_vector(G_SENSOR_DATA_WIDTH-1 downto 0);

            -- output
            busy_list       : out std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);
            output          : out std_logic_vector(31 downto 0);
            done            : out std_logic;
            sensor_conf     : out std_logic_vector(G_SENSOR_CONF_WIDTH-1 downto 0);
            valid_result    : out std_logic
        );
    end component asip_alu;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- CONSTANTS AND SIGNALS
--------------------------------------------------------------------------------
-- /*start-folding-block*/
alias shamt                 : std_logic_vector(4 downto 0) is immediate_value(10 downto 6);
--alias funct               : std_logic_vector(7 downto 0) is immediate_value(5 downto 0);


-- Function Register erweitert um 2 Bit zur besseren Darstellung
signal funct                : std_logic_vector( 7 downto 0);

signal s_alu_result         : std_logic_vector(31 downto 0);
signal s_alu_input_1        : std_logic_vector(31 downto 0);
signal s_alu_input_2        : std_logic_vector(31 downto 0);
signal s_forward_res_1      : std_logic_vector(31 downto 0);
signal s_forward_res_2      : std_logic_vector(31 downto 0);

-- alu flags
signal s_overflow           : std_logic;
signal s_react_to_overflow  : std_logic;

signal s_abort              : std_logic;

signal s_byte_offset        : std_logic_vector( 1 downto 0);
signal s_alu_result_tmp     : std_logic_vector(31 downto 0);

-- asip ALU signals

-- exception
signal s_asip_alu_abort           : std_logic;

-- inputs
signal s_asip_alu_alu_op          : alu_ctrl_t;
signal s_asip_alu_input0          : std_logic_vector(31 downto 0);
signal s_asip_alu_input1          : std_logic_vector(31 downto 0);
signal s_asip_alu_sensor_input    : std_logic_vector(G_SENSOR_DATA_WIDTH-1 downto 0);

-- output
signal s_asip_alu_busy_list       : std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);
signal s_asip_alu_output          : std_logic_vector(31 downto 0);
signal s_asip_alu_done            : std_logic;
signal s_asip_alu_sensor_conf     : std_logic_vector(G_SENSOR_CONF_WIDTH-1 downto 0);
signal s_asip_alu_valid_result    : std_logic;

-- /*end-folding-block*/

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

    -- Wert fuer store Befehl durchreichen
    reg_data_out    <= s_forward_res_2;

    -- Zieladresse weitergeben
    --dest_reg_out  <= dest_reg_in_1 when (regdst = '0') else dest_reg_in_2;
    dest_reg_out    <= dest_reg_in;

    alu_result      <= s_alu_result_tmp when s_asip_alu_valid_result = '0' else
                       s_asip_alu_output;

    done        <= s_asip_alu_done;
    busy_list   <= s_asip_alu_busy_list;


    funct           <= "00" & immediate_value(5 downto 0);

    s_alu_input_1   <= s_forward_res_1;
    s_alu_input_2   <= s_forward_res_2 when (alu_src='0') else immediate_value;

    -- alu flags
    alu_flags(0)    <= '0';
    alu_flags(1)    <= '0';
    alu_flags(2)    <= s_overflow;
    alu_flags(3)    <= '0';
    alu_flags(4)    <= '0';

    overflow_exc_enabled : if (G_EXC_ARITHMETIC_OVERFLOW = true) generate
        s_react_to_overflow <= s_overflow;
    end generate overflow_exc_enabled;

    overflow_exc_disabled : if (G_EXC_ARITHMETIC_OVERFLOW = false) generate
        s_react_to_overflow <= '0';
    end generate overflow_exc_disabled;

    s_abort         <= s_react_to_overflow or flush;


    -- s_abort execution on overflow exception
    -- instruction is not permitted to access the memory or the register file
    with s_abort select
        ctrl_mem_out(4 downto 0)    <=
                                        (others => '0') when '1',
                                        ctrl_mem_in when others;
    with s_abort select
        ctrl_mem_out(6 downto 5)    <=
                                        (others => '0') when '1',
                                        s_byte_offset when others;

    with s_abort select
        ctrl_wb_out    <=
                            (others => '0') when '1',
                            ctrl_wb_in when others;

-- /*end-folding-block*/

--------------------------------------------------------------------------------
-- PROCESSES
--------------------------------------------------------------------------------
-- /*start-folding-block*/

mem_byte_access: process(ctrl_mem_in, s_alu_result)
begin
    -- memory access write/read and byte/halfword access
    if ((ctrl_mem_in(0) = '1' or ctrl_mem_in(1) = '1') and (ctrl_mem_in(2) = '1' or ctrl_mem_in(3) = '1')) then
        s_byte_offset <= s_alu_result(1 downto 0);
        s_alu_result_tmp <= s_alu_result;
        -- byte access
        if (ctrl_mem_in(2) = '1') then
            s_alu_result_tmp(1 downto 0) <= (others => '0');
        end if;
        -- halfword access
        if (ctrl_mem_in(3) = '1') then
            s_alu_result_tmp(1) <= '0';
        end if;
    else
        s_byte_offset <= (others => '0');
        s_alu_result_tmp <= s_alu_result;
    end if;
end process mem_byte_access;


-- ALU Eingaenge waehlen
forwarding: process(reg_data_in_1, reg_data_in_2,
                    ctrl_reg_write_mem_wb, ctrl_reg_write_ex_mem,
                    forward_dest_mem_wb, forward_dest_ex_mem,
                    forward_rs_addr, forward_rt_addr,
                    forward_mem_wb,forward_ex_mem)
begin

    --forwardA=00
    s_forward_res_1 <= reg_data_in_1;
    --forwardB=00
    s_forward_res_2 <= reg_data_in_2;

    -- forward mem/wb stage
    if (ctrl_reg_write_mem_wb='1' and forward_dest_mem_wb/="00000" and forward_rs_addr=forward_dest_mem_wb) then
        --forwardA=01
        s_forward_res_1 <= forward_mem_wb;
    end if;
    if (ctrl_reg_write_mem_wb='1' and forward_dest_mem_wb/="00000" and forward_rt_addr=forward_dest_mem_wb) then
        --forwardB=01
        s_forward_res_2 <= forward_mem_wb;
    end if;

    -- forward ex/mem stage
    if (ctrl_reg_write_ex_mem='1' and forward_dest_ex_mem/="00000" and forward_rs_addr=forward_dest_ex_mem) then
        --forwardA=10
        s_forward_res_1 <= forward_ex_mem;
    end if;
    if (ctrl_reg_write_ex_mem='1' and forward_dest_ex_mem/="00000" and forward_rt_addr=forward_dest_ex_mem) then
        --forwardB=10
        s_forward_res_2 <= forward_ex_mem;
    end if;

end process forwarding;



-- ALU Berechnung
alu: process(alu_ctrl,s_alu_input_1,s_alu_input_2,funct,shamt)

    variable var_alu_result : std_logic_vector(32 downto 0);

begin
    s_alu_result    <= (others=>'0');
    var_alu_result  := (others=>'0');
    s_overflow      <= '0';

    case (alu_ctrl) is
        when op_sll =>   --sll R[d] = R[t] << shamt
            s_alu_result <= std_logic_vector(shift_left(unsigned(s_alu_input_2), to_integer(unsigned(shamt))));
        when op_srl =>   --srl R[d] = R[t] >> shamt
            s_alu_result <= std_logic_vector(shift_right(unsigned(s_alu_input_2), to_integer(unsigned(shamt))));
        when op_sra =>   --sra R[d] = R[t] >>> shamt
            s_alu_result <= std_logic_vector(shift_right(signed(s_alu_input_2), to_integer(unsigned(shamt))));
        when op_sllv =>   --sllv R[d] = R[t] << R[s](4 downto 0)
            s_alu_result <= std_logic_vector(shift_left(unsigned(s_alu_input_2), to_integer(unsigned(s_alu_input_1( 4 downto 0)))));
        when op_srlv =>   --srlv R[d] = R[t] >> R[s](4 downto 0)
            s_alu_result <= std_logic_vector(shift_right(unsigned(s_alu_input_2), to_integer(unsigned(s_alu_input_1( 4 downto 0)))));
        when op_srav =>   --srav R[d] = R[t] >>> R[s](4 downto 0)
            s_alu_result <= std_logic_vector(shift_right(signed(s_alu_input_2), to_integer(unsigned(s_alu_input_1( 4 downto 0)))));
        when op_add =>   -- add
            var_alu_result(31 downto 0) := std_logic_vector(signed(s_alu_input_1) + signed(s_alu_input_2));
            s_alu_result <= var_alu_result(31 downto 0);
            -- overflow detection
            if ( (s_alu_input_1(31) = '0' and s_alu_input_2(31) = '0' and var_alu_result(31) = '1')
                or (s_alu_input_1(31) = '1' and s_alu_input_2(31) = '1'and var_alu_result(31) = '0') ) then
                s_overflow <= '1';
            else
                s_overflow <= '0';
            end if;
        when op_addu =>   -- addu
            var_alu_result := std_logic_vector(unsigned('0' & s_alu_input_1) + unsigned('0' & s_alu_input_2));
            s_alu_result <= var_alu_result(31 downto 0);
            -- No Integer Overflow exception occurs under any
            -- circumstances.
        when op_sub =>   -- sub
            var_alu_result(31 downto 0) := std_logic_vector(signed(s_alu_input_1) - signed(s_alu_input_2));
            s_alu_result <= var_alu_result(31 downto 0);
            -- overflow detection
            if ( (s_alu_input_1(31) = '0' and s_alu_input_2(31) = '0' and var_alu_result(31) = '1')
                or (s_alu_input_1(31) = '1' and s_alu_input_2(31) = '1' and var_alu_result(31) = '0') ) then
                s_overflow <= '1';
            else
                s_overflow <= '0';
            end if;
        when op_subu =>   -- subu
            var_alu_result := std_logic_vector(unsigned('0' & s_alu_input_1) - unsigned('0' & s_alu_input_2));
            s_alu_result <= var_alu_result(31 downto 0);
            -- No Integer Overflow exception occurs under any
            -- circumstances.
        when op_and =>   -- and
            s_alu_result <= std_logic_vector(unsigned(s_alu_input_1) and unsigned(s_alu_input_2));
        when op_or =>   -- or
            s_alu_result <= std_logic_vector(unsigned(s_alu_input_1) or unsigned(s_alu_input_2));
        when op_xor =>   -- xor
            s_alu_result <= std_logic_vector(unsigned(s_alu_input_1) xor unsigned(s_alu_input_2));
        when op_nor =>   -- nor
            s_alu_result <= std_logic_vector(unsigned(s_alu_input_1) nor unsigned(s_alu_input_2));
        when op_slt =>   -- SLT
            s_alu_result <= (others=>'0');
            if ((signed(s_alu_input_1) < signed(s_alu_input_2))) then
                s_alu_result(0) <= '1';
            end if;
        when op_sltu =>   -- SLTU
            s_alu_result <= (others=>'0');
            if ((unsigned(s_alu_input_1) < unsigned(s_alu_input_2))) then
                s_alu_result(0) <= '1';
            end if;

        when op_mov =>  -- MOV
            s_alu_result <= s_alu_input_1;

        when op_lui =>  -- LUI
            s_alu_result <= s_alu_input_2(15 downto 0) & x"0000";

        when others =>
            --assert false report "undefined alu ctrl" severity failure;

    end case;

end process;


-- /*end-folding-block*/


    asip_alu_inst : asip_alu
        generic map (
            G_SENSOR_DATA_WIDTH     => G_SENSOR_DATA_WIDTH,
            G_SENSOR_CONF_WIDTH     => G_SENSOR_CONF_WIDTH,
            G_BUSY_LIST_WIDTH       => G_BUSY_LIST_WIDTH
        )
        port map (
            -- general
            clk             => clk,
            en              => enable,
            arstn           => resetn,

            -- exception
            abort           => s_asip_alu_abort,

            -- inputs
            alu_op          => s_asip_alu_alu_op,
            input0          => s_asip_alu_input0,
            input1          => s_asip_alu_input1,
            sensor_input    => s_asip_alu_sensor_input,

            -- output
            busy_list       => s_asip_alu_busy_list,
            output          => s_asip_alu_output,
            done            => s_asip_alu_done,
            sensor_conf     => s_asip_alu_sensor_conf,
            valid_result    => s_asip_alu_valid_result
        );

    -- exception
    s_asip_alu_abort <= flush;
    -- inputs
    s_asip_alu_alu_op <= alu_ctrl;
    s_asip_alu_input0 <= s_alu_input_1;
    s_asip_alu_input1 <= s_alu_input_2;
    s_asip_alu_sensor_input <= sensor_data_in;
    -- output
    sensor_config_out <= s_asip_alu_sensor_conf;


end architecture;

