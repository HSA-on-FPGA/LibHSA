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

typedef      int si_int;
typedef unsigned su_int;

typedef          long long di_int;
typedef unsigned long long du_int;

typedef union
{
    du_int all;
    struct
    {
        su_int low;
        su_int high;
    } s;
} udwords;

typedef union
{
    di_int all;
    struct
    {
        su_int low;
        si_int high;
    }s;
} dwords;

void *sbrk(int incr);

// multiplication
long __mulsi3(unsigned long a, unsigned long b);

//division
int __divsi3(int a, int b);
unsigned int __udivsi3(unsigned int n, unsigned int d);

unsigned int __umodsi3(unsigned int num, unsigned int den);

du_int __udivmoddi4(du_int a, du_int b, du_int* rem);

di_int __divdi3(di_int a, di_int b);

du_int __umoddi3(du_int a, du_int b);

du_int __udivdi3(du_int a, du_int b);

static di_int __muldsi3(su_int a, su_int b);

di_int __muldi3(di_int a, di_int b);
