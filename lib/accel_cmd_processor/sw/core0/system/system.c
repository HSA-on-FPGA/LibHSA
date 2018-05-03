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

#include "system.h"

#define CHAR_BIT 8

void *sbrk(int incr) {
    extern void _heap_start;
    static void *heap_end;
    void *prev_heap_end;
    if (heap_end == 0) {
        heap_end = &_heap_start;
    }
    prev_heap_end = heap_end;
    // TODO
    // check for error
    // trigger interrupt
    heap_end += incr;
    return prev_heap_end;
}

long __mulsi3(unsigned long a, unsigned long b) {
    long res = 0;
    while (a) {
        if (a & 1) {
            res += b;
        }
        b <<= 1;
        a >>=1;
    }
    return res;
}

int __divsi3(int a, int b)
{
    const int bits_in_word_m1 = (int)(sizeof(int) * CHAR_BIT) - 1;
    int s_a = a >> bits_in_word_m1;           /* s_a = a < 0 ? -1 : 0 */
    int s_b = b >> bits_in_word_m1;           /* s_b = b < 0 ? -1 : 0 */
    a = (a ^ s_a) - s_a;                         /* negate if s_a == -1 */
    b = (b ^ s_b) - s_b;                         /* negate if s_b == -1 */
    s_a ^= s_b;                                  /* sign of quotient */
    return (__udivsi3(a, b) ^ s_a) - s_a;        /* negate if s_a == -1 */
}

unsigned int __udivsi3(unsigned int n, unsigned int d)
{
    const unsigned n_uword_bits = sizeof(unsigned int) * CHAR_BIT;
    unsigned int q;
    unsigned int r;
    unsigned sr;
    /* special cases */
    if (d == 0)
        return 0; /* ?! */
    if (n == 0)
        return 0;
    sr = __builtin_clz(d) - __builtin_clz(n);
    /* 0 <= sr <= n_uword_bits - 1 or sr large */
    if (sr > n_uword_bits - 1)  /* d > r */
        return 0;
    if (sr == n_uword_bits - 1)  /* d == 1 */
        return n;
    ++sr;
    /* 1 <= sr <= n_uword_bits - 1 */
    /* Not a special case */
    q = n << (n_uword_bits - sr);
    r = n >> sr;
    unsigned int carry = 0;
    for (; sr > 0; --sr)
    {
        /* r:q = ((r:q)  << 1) | carry */
        r = (r << 1) | (q >> (n_uword_bits - 1));
        q = (q << 1) | carry;
        /* carry = 0;
         * if (r.all >= d.all)
         * {
         *      r.all -= d.all;
         *      carry = 1;
         * }
         */
        const int s = (int)(d - r - 1) >> (n_uword_bits - 1);
        carry = s & 1;
        r -= d & s;
    }
    q = (q << 1) | carry;
    return q;
}



unsigned int __umodsi3(unsigned int num, unsigned int den)
{
	unsigned int quot = 0;
	unsigned int qbit = 1;

	if (den == 0)
	{
		//asm volatile ("int $0");
		return 0;	/* if trap returns... */
	}

	/* left-justify denominator and count shift */
	while ((int) den >= 0)
	{
		den <<= 1;
		qbit <<= 1;
	}

	while (qbit)
	{
		if (den <= num)
		{
			num -= den;
			quot += qbit;
		}
		den >>= 1;
		qbit >>= 1;
	}

	return num;
}
