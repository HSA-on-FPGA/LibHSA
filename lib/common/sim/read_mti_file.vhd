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
use IEEE.STD_LOGIC_1164.ALL;
use STD.textio.all;
use IEEE.NUMERIC_STD.ALL;

entity read_mti_file is
Generic (
    DATA_VECTOR_SIZE : integer	:= 32;
    FILE_NAME        : string   := "data.mem"
);
Port (
    CLK         :   in  STD_LOGIC;
    NEXT_WORD   :   in  STD_LOGIC;
    DATA        :   out STD_LOGIC_VECTOR(DATA_VECTOR_SIZE - 1 downto 0);
    EOF         :   out STD_LOGIC
);
end read_mti_file;

architecture Behavioral of read_mti_file is
    file data_file: TEXT open read_mode is FILE_NAME;
    constant BUFFER_SIZE : integer := ((DATA_VECTOR_SIZE+3) / 4) * 4; -- ROUND TO NEXT HIGHER MULTIPLE OF 4

    procedure convert_hex_char (c_bin: out std_logic_vector(3 downto 0); c: in CHARACTER) is 
    begin
        case c is
            when '0' => c_bin := x"0";
            when '1' => c_bin := x"1";
            when '2' => c_bin := x"2";
            when '3' => c_bin := x"3";
            when '4' => c_bin := x"4";
            when '5' => c_bin := x"5";
            when '6' => c_bin := x"6";
            when '7' => c_bin := x"7";
            when '8' => c_bin := x"8";
            when '9' => c_bin := x"9";
            when 'a' => c_bin := x"a";
            when 'b' => c_bin := x"b";
            when 'c' => c_bin := x"c";
            when 'd' => c_bin := x"d";
            when 'e' => c_bin := x"e";
            when 'f' => c_bin := x"f";
            when 'A' => c_bin := x"a";
            when 'B' => c_bin := x"b";
            when 'C' => c_bin := x"c";
            when 'D' => c_bin := x"d";
            when 'E' => c_bin := x"e";
            when 'F' => c_bin := x"f";
            when others => c_bin := "XXXX";
        end case;
    end procedure;
    
    procedure convert_int_char (c_int: out integer; c: in CHARACTER) is
    begin
        case c is
            when '0' => c_int := 0;
            when '1' => c_int := 1;
            when '2' => c_int := 2;
            when '3' => c_int := 3;
            when '4' => c_int := 4;
            when '5' => c_int := 5;
            when '6' => c_int := 6;
            when '7' => c_int := 7;
            when '8' => c_int := 8;
            when '9' => c_int := 9;
            when others => c_int := 0;
        end case;
    end procedure;

    procedure read_word_from_line (l : inout line; word : out std_logic_vector(255 downto 0); size : out integer; end_of_line: out boolean) is
        variable c: character;
        variable good: boolean;
        variable c_bin: std_logic_vector(3 downto 0);
        variable l_out: line;
        variable word_tmp: std_logic_vector(255 downto 0);
        variable size_tmp: integer;
        constant str0 : string := "read_word_from_line";
        constant str1 : string := "READ: ";
        constant str2 : string := " - ";
    begin
        word_tmp := (others => '0');
        size_tmp := 0;
        
        --write(l_out, FILE_NAME);
        --write(l_out, str2);
        --write(l_out, str0);
        --writeline(OUTPUT, l_out);

        read(l, c, good);
        if not good then
            end_of_line := true;
            word := (others => '0');
            size := 0;
            return;
        end if;
        
        --write(l_out, FILE_NAME);
        --write(l_out, str2);
        --write(l_out, good);
        --write(l_out, str2);
        --write(l_out, c);
        --writeline(OUTPUT, l_out);

        
        while good loop
            if c = ' ' then
                exit;
            end if;
            convert_hex_char(c_bin, c);
            word_tmp(4*size_tmp + 3 downto 4*size_tmp) := c_bin;
            size_tmp := size_tmp + 1;                                     
            read(l, c, good);
        end loop;        
        
        --write(l_out, FILE_NAME);
        --write(l_out, str2);
        --write(l_out, str1);       
        --write(l_out, size_tmp);
        --write(l_out, str2);
        --write(l_out, to_integer(unsigned(word_tmp)));
        --writeline(OUTPUT, l_out);

        end_of_line := false;
        word := word_tmp;
        size := size_tmp;

    end procedure;
    

    shared variable buf: std_logic_vector(BUFFER_SIZE - 1 downto 0) := (others => '0');
    shared variable buf_size: integer := 0;
    shared variable current_buffer_pos: integer := 0;
    
    procedure write_to_buf(val: in std_logic_vector(3 downto 0); data_out: out STD_LOGIC_VECTOR(DATA_VECTOR_SIZE - 1 downto 0); data_ready: out boolean) is
    begin
        
        -- add value to buffer
        buf(BUFFER_SIZE - 5 downto 0) := buf(BUFFER_SIZE - 1 downto 4);
        buf(BUFFER_SIZE - 1 downto BUFFER_SIZE - 4) := val;
        buf_size := buf_size + 4;
        current_buffer_pos := current_buffer_pos + 1;
        
        -- check if enough bits are available in buffer
        if buf_size >= DATA_VECTOR_SIZE then

            -- write to DATA
            data_out := buf(buf_size - 1 downto buf_size - DATA_VECTOR_SIZE);
            buf_size := buf_size - DATA_VECTOR_SIZE;

            -- wait until we receive a 'NEXT_WORD' signal
            data_ready := true;
        else
            data_ready := false;
        end if; 
    
    end procedure;
    
    procedure wait_for_NEXT_WORD is
    begin
        loop
            wait until CLK='1';
            if NEXT_WORD = '1' then
                exit;
            end if;
        end loop;
    end procedure;
    
            
begin

    process
        variable l: line;
        variable c: character;
        variable good: boolean;
        variable end_of_line: boolean;
        variable c_bin: std_logic_vector(3 downto 0);
        variable tmp_int: integer := 0;
        variable current_line_pos: integer := 0;
        variable l_out: line;
        constant new_line_str : string := "-----NEW LINE----- offset: ";
        constant str1 : string := " - ";
                
        constant padding: std_logic_vector(3 downto 0) := (others => '0');
        variable data_out : STD_LOGIC_VECTOR(DATA_VECTOR_SIZE - 1 downto 0);
        variable data_ready: boolean;
        variable current_word : std_logic_vector(255 downto 0);
        variable current_word_size : integer;
    begin
    
        EOF <= '0';
        
        while not endfile(data_file) loop
        
            -- read new line
            readline(data_file, l);
            --write(l_out, FILE_NAME);
            --write(l_out, str1);
            --write(l_out, new_line_str);
            --writeline(OUTPUT, l_out);

            -- remove comments, remove position numbers
            current_line_pos := 0;
            loop
                read(l, c, good);
                if not good then
                    exit;
                end if;
                if c = ':' then
                    exit;
                end if;
                if c = '/' then
                    good := false;
                    exit;
                end if;
                
                -- compute current line position
                convert_int_char(tmp_int, c);
                current_line_pos := current_line_pos * 10 + tmp_int;                
            end loop;
            
            -- if data available in current line, process data
            if good then
                -- current_line_pos is in 32bit-words. we read 4-bit words.
                -- therefore we need to multiply by 8
                current_line_pos := current_line_pos * 8;
                
                --write(l_out, FILE_NAME);
                --write(l_out, str1);
                --write(l_out, new_line_str);
                --write(l_out, current_line_pos);
                --writeline(OUTPUT, l_out);

                while(current_line_pos > current_buffer_pos) loop
                    write_to_buf(padding, data_out, data_ready);
                    if data_ready then
                        DATA <= data_out;
                        wait_for_NEXT_WORD;
                    end if;
                end loop;

                loop
                    --read(l,c,good);
                    read_word_from_line (l, current_word, current_word_size, end_of_line);
                    if end_of_line then
                        exit;
                    end if;
                    while(current_word_size > 0) loop
                        current_word_size := current_word_size - 1;
                        write_to_buf(current_word(current_word_size * 4 + 3 downto current_word_size * 4), data_out, data_ready);
                        if data_ready then
                            DATA <= data_out;
                            wait_for_NEXT_WORD;
                        end if;
                    end loop;
                end loop;
            end if;

        end loop;
        
        EOF <= '1';
        wait;    
    
    end process;

end Behavioral;
