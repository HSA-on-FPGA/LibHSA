-- decoder_unit: Decoder for mips pipeline
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_pkg.all;

entity decoder_unit is
    generic(
        G_EXC_RESERVED_INSTRUCTION  : boolean := false;
        G_EXC_COP_UNIMPLEMENTED     : boolean := false;
        G_BUSY_LIST_WIDTH           : integer range 1 to 1024
    );
    port (
        -- inputs
        instruction             : in  std_logic_vector(31 downto 0);
        forwarded_value_1       : in  std_logic_vector(31 downto 0);
        forwarded_value_2       : in  std_logic_vector(31 downto 0);
        execute_busy_list       : in  std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);

        -- outputs
        regwrite                : out std_logic;
        regdst                  : out std_logic;
        alu_src                 : out std_logic;
        memread                 : out std_logic;
        memwrite                : out std_logic;
        mem_byte                : out std_logic;
        mem_halfword            : out std_logic;
        mem_unsigned            : out std_logic;
        memtoreg                : out std_logic;
        branch_link             : out std_logic;
        iret                    : out std_logic;
        sign_extend             : out std_logic;
        alu_ctrl                : out alu_ctrl_t;
        is_branch_instruction   : out std_logic;

        --CP0
        mfc                     : out std_logic;
        mtc                     : out std_logic;
        -- exceptions
        syscall                 : out std_logic;
        trap                    : out std_logic;
        reserved_instr          : out std_logic;
        cop_unimplemented       : out std_logic;
        breakpoint              : out std_logic;

        -- ASIP hazards
        stall                   : out std_logic;

        -- standby mode
        standby                 : out std_logic
    );
end entity decoder_unit;


architecture behavior of decoder_unit is

    component asip_decode is
        generic(
            G_BUSY_LIST_WIDTH           : integer range 1 to 1024
        );
        port (
            -- inputs
            opcode          : in  std_logic_vector(5 downto 0);
            funct           : in  std_logic_vector(5 downto 0);
            busy_list       : in  std_logic_vector(G_BUSY_LIST_WIDTH-1 downto 0);

            -- output
            alu_op          : out alu_ctrl_t;
            reg_write       : out std_logic;
            reg_dst         : out std_logic;
            alu_src         : out std_logic;
            valid           : out std_logic;
            stall           : out std_logic
        );
    end component asip_decode;

    signal s_ctrl_zero      : std_logic;

    alias funct             : std_logic_vector(5 downto 0) is instruction(5 downto 0);
    signal opcode           : std_logic_vector(7 downto 0);
    signal rs               : std_logic_vector(7 downto 0);
    signal rt               : std_logic_vector(7 downto 0);

    signal s_asip_decode_alu_op         : alu_ctrl_t;
    signal s_asip_decode_reg_write      : std_logic;
    signal s_asip_decode_reg_dst        : std_logic;
    signal s_asip_decode_alu_src        : std_logic;
    signal s_asip_decode_valid          : std_logic;

    signal s_alu_ctrl       : alu_ctrl_t;
    signal s_regwrite       : std_logic;
    signal s_regdst         : std_logic;
    signal s_alu_src        : std_logic;

begin

    opcode                  <=  "00"  & instruction(31 downto 26);
    rs                      <=  "000" & instruction(25 downto 21);
    rt                      <=  "000" & instruction(20 downto 16);

    -- select decode result
    alu_ctrl <= s_asip_decode_alu_op when s_asip_decode_valid = '1' else
                s_alu_ctrl;
    regwrite <= s_asip_decode_reg_write when s_asip_decode_valid = '1' else
                s_regwrite;
    regdst   <= s_asip_decode_reg_dst when s_asip_decode_valid = '1' else
                s_regdst;
    alu_src  <= s_asip_decode_alu_src when s_asip_decode_valid = '1' else
                s_alu_src;

    asip_decode_inst : asip_decode
        generic map (
            G_BUSY_LIST_WIDTH => G_BUSY_LIST_WIDTH
        )
        port map (
            -- inputs
            opcode          => instruction(31 downto 26),
            funct           => funct,
            busy_list       => execute_busy_list,

            -- output
            alu_op          => s_asip_decode_alu_op,
            reg_write       => s_asip_decode_reg_write,
            reg_dst         => s_asip_decode_reg_dst,
            alu_src         => s_asip_decode_alu_src,
            valid           => s_asip_decode_valid,
            stall           => stall
        );

proc_decoder :
    process (
        opcode, rt, rs, instruction, s_ctrl_zero, funct, forwarded_value_2
    )
    begin
        -- default values
        s_regwrite                      <= '0';
        s_regdst                        <= '0';
        s_alu_src                       <= '0';
        memread                         <= '0';
        memwrite                        <= '0';
        mem_byte                        <= '0';
        mem_halfword                    <= '0';
        mem_unsigned                    <= '0';
        memtoreg                        <= '0';
        branch_link                     <= '0';
        iret                            <= '0';
        sign_extend                     <= '1';
        s_alu_ctrl                      <= op_nop;
        is_branch_instruction           <= '0';

        --CP0
        mfc                             <= '0';
        mtc                             <= '0';
        -- exceptions
        syscall                         <= '0';
        trap                            <= '0';
        reserved_instr                  <= '0';
        cop_unimplemented               <= '0';
        breakpoint                      <= '0';

        standby                         <= '0';

        case (opcode) is

            when x"00" =>       -- R Type
                s_regwrite    <= '1';
                s_regdst      <= '1';

                case (funct) is

                    when "000000" =>   --sll
                        s_alu_ctrl    <= op_sll;

                    when "000010" =>   --srl
                        s_alu_ctrl    <= op_srl;

                    when "000011" =>   --sra
                        s_alu_ctrl    <= op_sra;

                    when "000100" =>   --sllv
                        s_alu_ctrl    <= op_sllv;

                    when "000110" =>   --srlv
                        s_alu_ctrl    <= op_srlv;

                    when "000111" =>   --srav
                        s_alu_ctrl    <= op_srav;

                    when "100000" =>   -- add
                        s_alu_ctrl    <= op_add;

                    when "100001" =>   -- addu
                        s_alu_ctrl    <= op_addu;

                    when "100010" =>   -- sub
                        s_alu_ctrl    <= op_sub;

                    when "100011" =>   -- subu
                        s_alu_ctrl    <= op_subu;

                    when "100100" =>   -- and
                        s_alu_ctrl    <= op_and;

                    when "100101" =>   -- or
                        s_alu_ctrl    <= op_or;

                    when "100110" =>   -- xor
                        s_alu_ctrl    <= op_xor;

                    when "100111" =>   -- nor
                        s_alu_ctrl    <= op_nor;

                    when "101010" =>   -- SLT
                        s_alu_ctrl    <= op_slt;

                    when "101011" =>   -- SLTU
                        s_alu_ctrl    <= op_sltu;

                    when "001000" =>    -- jump register
                        s_regwrite    <= '0';
                        s_alu_ctrl    <= op_and;
                        is_branch_instruction <= '1';

                    when "001001" =>    -- jump and link register
                        branch_link <= '1';
                        s_regwrite    <= '1';
                        s_alu_ctrl    <= op_addu;
                        is_branch_instruction <= '1';

                    when "001010" =>    -- movz
                        s_regwrite    <= '0';
                        if (forwarded_value_2 = x"00000000") then
                            s_regwrite    <= '1';
                            s_alu_ctrl    <= op_mov;
                        end if;

                    when "001011" =>    -- movn
                        s_regwrite    <= '0';
                        if (forwarded_value_2 /= x"00000000") then
                            s_regwrite    <= '1';
                            s_alu_ctrl    <= op_mov;
                        end if;

                    when "001100" =>    -- syscall
                        s_regwrite    <= '0';
                        syscall     <= '1';

                    when "001101" =>    -- break
                        breakpoint  <= '1';

                    when "110100" =>    -- teq
                        if (s_ctrl_zero = '1') then
                            trap <= '1';
                        end if;

                    when "110110" =>    -- tne
                        if (s_ctrl_zero = '0') then
                            trap <= '1';
                        end if;

                    when others =>

                end case;

            when x"01" =>       -- extended opcodes
                case (rt) is
                    when x"00" =>       -- branch less than zero
                        s_regwrite    <= '0';
                        s_regdst      <= '-';
                        memtoreg    <= '-';
                        is_branch_instruction <= '1';

                    when x"01" =>       -- branch greater equal zero
                        s_regwrite    <= '0';
                        s_regdst      <= '-';
                        memtoreg    <= '-';
                        is_branch_instruction <= '1';

                    when x"10" =>       -- branch less than zero and link
                        s_regdst      <= '-';
                        memtoreg    <= '0';
                        branch_link <= '1';
                        s_regwrite    <= '1';
                        s_alu_ctrl    <= op_addu;
                        is_branch_instruction <= '1';

                    when x"11" =>       -- branch greater equal zero and link
                        s_regdst      <= '-';
                        memtoreg    <= '0';
                        branch_link <= '1';
                        s_regwrite    <= '1';
                        s_alu_ctrl    <= op_addu;
                        is_branch_instruction <= '1';

                    when others =>

                end case;

            when x"02" =>       -- jump
                s_regwrite    <= '0';
                s_regdst      <= '-';
                s_alu_src        <= '-';
                memtoreg    <= '-';
                is_branch_instruction <= '1';

            when x"03" =>       -- jump and link
                s_regdst      <= '-';
                memtoreg    <= '0';
                branch_link <= '1';
                s_regwrite    <= '1';
                s_alu_ctrl    <= op_addu;
                is_branch_instruction <= '1';

            when x"04" =>       -- branch equal
                s_regwrite        <= '0';
                s_regdst          <= '-';
                memtoreg        <= '-';
                is_branch_instruction <= '1';

            when x"05" =>       -- branch not equal
                s_regwrite        <= '0';
                s_regdst          <= '-';
                memtoreg        <= '-';
                is_branch_instruction <= '1';

            when x"06" =>       -- branch less equal zero
                s_regwrite        <= '0';
                s_regdst          <= '-';
                memtoreg        <= '-';
                is_branch_instruction <= '1';

            when x"07" =>       -- branch greater than zero
                s_regwrite        <= '0';
                s_regdst          <= '-';
                memtoreg        <= '-';
                is_branch_instruction <= '1';

            when x"08" =>       -- add immediate
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                s_alu_ctrl        <= op_add;

            when x"09" =>       -- add immediate unsigned
                -- the immediate is being sign extended (see doc)!
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                s_alu_ctrl        <= op_addu;

            when x"0A" =>       -- set less than immediate
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                s_alu_ctrl        <= op_slt;

            when x"0B" =>       -- set less than immediate unsigned
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                s_alu_ctrl        <= op_sltu;
                sign_extend     <= '1';

            when x"0C" =>       -- and immediate
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                sign_extend     <= '0';
                s_alu_ctrl        <= op_and;

            when x"0D" =>       -- or immediate
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                sign_extend     <= '0';
                s_alu_ctrl        <= op_or;

            when x"0E" =>       -- xor immediate
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                sign_extend     <= '0';
                s_alu_ctrl        <= op_xor;

            when x"0F" =>       -- load upper immediate
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                sign_extend     <= '-';
                s_alu_ctrl        <= op_lui;

            when x"10" =>       -- Coprocessor 0
                case (rs) is

                    when x"00" =>       -- move from Coprocessor0
                        mfc         <= '1';
                        s_regwrite    <= '1';
                        s_regdst      <= '0';

                    when x"04" =>       -- move to Coprocessor0
                        mtc         <= '1';
                        s_regdst      <= '1';
                        s_alu_src     <= '1';

                    when x"10" =>
                        if (instruction=x"42000018" ) then  -- eret
                            s_alu_ctrl    <= op_and;
                            iret        <= '1';
                        end if;

                    when others =>

                end case;

                -- wait, enter standby mode
                if (funct = "100000" and instruction(25) = '1') then
                    standby <= '1';
                end if;

            when x"11" =>       -- Coprocessor 1
                if (G_EXC_COP_UNIMPLEMENTED = true) then
                    cop_unimplemented <= '1';
                end if;

            when x"12" =>       -- Coprocessor 2
                if (G_EXC_COP_UNIMPLEMENTED = true) then
                    cop_unimplemented <= '1';
                end if;

            when x"20" =>       -- load byte
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                memread         <= '1';
                memtoreg        <= '1';
                s_alu_ctrl        <= op_add;
                mem_byte        <= '1';

            when x"24" =>       -- load byte unsigned
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                memread         <= '1';
                memtoreg        <= '1';
                s_alu_ctrl        <= op_add;
                mem_byte        <= '1';
                mem_unsigned    <= '1';

            when x"21" =>       -- load halfword
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                memread         <= '1';
                memtoreg        <= '1';
                s_alu_ctrl        <= op_add;
                mem_halfword    <= '1';

            when x"25" =>       -- load halfword unsigned
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                memread         <= '1';
                memtoreg        <= '1';
                s_alu_ctrl        <= op_add;
                mem_halfword    <= '1';
                mem_unsigned    <= '1';

            when x"23" =>       -- load word
                s_regwrite        <= '1';
                s_alu_src         <= '1';
                memread         <= '1';
                memtoreg        <= '1';
                s_alu_ctrl        <= op_add;

            when x"28" =>           -- store byte
                s_alu_src         <= '1';
                memwrite        <= '1';
                s_alu_ctrl        <= op_add;
                mem_byte        <= '1';

            when x"29" =>           -- store halfword
                s_alu_src         <= '1';
                memwrite        <= '1';
                s_alu_ctrl        <= op_add;
                mem_halfword    <= '1';

            when x"2B" =>           -- store word
                s_alu_src         <= '1';
                memwrite        <= '1';
                s_alu_ctrl        <= op_add;

            when others =>
                if (G_EXC_RESERVED_INSTRUCTION = true) then
                    reserved_instr <= '1';
                end if;

        end case;

    end process proc_decoder;

proc_compare :
    process (
        forwarded_value_1, forwarded_value_2
    )
    begin
        s_ctrl_zero <= '0';

        if (forwarded_value_1 = forwarded_value_2) then
            s_ctrl_zero <= '1';
        end if;

    end process proc_compare;

end architecture behavior;
