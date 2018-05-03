-- alu_pkg: Type definitions for the ALU
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

package alu_pkg is

    type alu_ctrl_t is
        (
            op_sll,
            op_srl,
            op_sra,
            op_sllv,
            op_srlv,
            op_srav,
            op_add,
            op_addu,
            op_sub,
            op_subu,
            op_and,
            op_or,
            op_xor,
            op_nor,
            op_slt,
            op_sltu,
            op_mov,
            op_lui,
            -- for power optimization
            op_nop
        );

end package alu_pkg;
