// Copyright (C) 2017 Tobias Lieske
// Copyright (C) 2017 Philipp Holzinger
// Copyright (C) 2017 Martin Stumpf
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// op field values of (potentially) unimplemented instructions

enum OP_FIELD {
    C_OP_FIELD_LB   = 0x20, // load byte
    C_OP_FIELD_LBU  = 0x24, // load byte unsigned
    C_OP_FIELD_LH   = 0x21, // load halfword
    C_OP_FIELD_LHU  = 0x25, // load halfword unsigned
    C_OP_FIELD_SB   = 0x28, // store byte
    C_OP_FIELD_SH   = 0x29  // store halfword
};
