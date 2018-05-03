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

#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include "address_config.h"

static volatile uint32_t start_execution = 0;

static volatile uint32_t sleep_var = 0;

#define INTERRUPT_TO_PACKETPROCESSOR 0
#define INTERRUPT_TO_ACCELERATOR 1

#define fire_interrupt(target) { *((volatile uint32_t*)(SEND_INTERRUPT)) = target; }
#define read_64(base, offset) (*((volatile uint64_t*)((base + offset))))
#define read_32(base, offset) (*((volatile uint32_t*)((base + offset))))
#define read_16(base, offset) (*((volatile uint16_t*)((base + offset))))
#define read_8(base, offset) (*((volatile uint8_t*)((base + offset))))
#define write_64(base, offset, value) \
    {*((volatile uint64_t*)((base) + (offset)))=(value);}
#define write_32(base, offset, value) \
    {*((volatile uint32_t*)((base) + (offset)))=(value);}
#define write_16(base, offset, value) \
    {*((volatile uint16_t*)((base) + (offset)))=(value);}
#define write_8(base, offset, value) \
    {*((volatile uint8_t*)((base) + (offset)))=(value);}

#define append(var, size, val) \
    { (var) = ((var)<<(size)) | ((val)&( (1<<(size))-1 )); }

void sleep(uint32_t counter){
	while(sleep_var < counter){
		++sleep_var;
	}
	sleep_var = 0;
}

void handle_interrupt_from_packetprocessor(){
	start_execution = 1;
}

static inline void run_computation(){
	// signal accelerator that work arrived
	fire_interrupt(INTERRUPT_TO_ACCELERATOR);
 
	// signal packet processor that we are done
	fire_interrupt(INTERRUPT_TO_PACKETPROCESSOR);
}

int main(){

    while(1){
        if(start_execution){
            start_execution = 0;
            run_computation();
        }
    }

    return 0;
}
