#!/bin/bash

source conf.sh

mkdir -p $1

echo "\
OUTPUT_FORMAT(\"elf64-littlemips\")

MEMORY
	{
		TEXT : ORIGIN = 0x0003000000000000, LENGTH = $PP_TEXT_SIZE
		DATA : ORIGIN = 0x0003000002000000, LENGTH = $PP_DATA_SIZE
		DRAM : ORIGIN = 0x0001000000000000, LENGTH = $DRAM_SIZE
	}

REGION_ALIAS(\"REGION_TEXT\", TEXT);
REGION_ALIAS(\"REGION_RODATA\", DATA);
REGION_ALIAS(\"REGION_DATA\", DATA);
REGION_ALIAS(\"REGION_BSS\", DATA);
REGION_ALIAS(\"RAM\", DRAM);

STARTUP(ld/startup.o)

/*GROUP(libgcc.a)*/
/*ENTRY (_start)*/

/* define stack size and heap size here */
stack_size = $PP_STACK_SIZE;
heap_size = $PP_HEAP_SIZE;

_stack_start = ORIGIN(DATA) + $PP_DATA_SIZE - 8;
_heap_start = ORIGIN(DRAM) + $PP_DRAM_RESERVED;

SECTIONS
{
	. = ORIGIN(TEXT);
    	.text ALIGN(4):
	{
		*(.text .stub .text.*)
            	FILL(0x00000000);
            	. = ORIGIN(TEXT) + LENGTH(TEXT) - 1;
            	BYTE(0x00);
	} > REGION_TEXT
    	. = ORIGIN(DATA);
    	.rodata ALIGN(8):
	{
            	FILL(0x00000000);
		*(.rodata)
		*(.rodata.*)
            	QUAD(0x00000000);
	} > REGION_RODATA
	.bss ALIGN(8):
	{
            	FILL(0x00000000);
		*(.bss)
		*(.bss.*)
		*(.sbss)
		*(.sbss.*)
            	*(COMMON)
	} > REGION_BSS
	.data ALIGN(8):
	{
		*(.data)
            	. = ALIGN(8);
		*(.sdata)
            	. = ALIGN(8);
		*(.sdata.*)
            	. = ALIGN(8);
            	*(COMMON)
            	. = ALIGN(8);
            	*(.scommon)
            	. = ALIGN(8);
            	*(.stack)
            	_stack_end = .;
            	. = . + stack_size*8;
            	FILL(0x00000000);
            	. = ORIGIN(DATA) + LENGTH(DATA) - 1;
            	BYTE(0x00);
	} > REGION_DATA
	. = _heap_start;
	.heap ALIGN(8):
        {
            	*(.heap)
            	. += heap_size*8;
            	_heap_end = . - 8;
        } > RAM
    
	/* Remove information from the standard libraries */
    	/DISCARD/ :
    	{
        	libc.a ( * )
        	libm.a ( * )
        	libgcc.a ( * )
        	*(.MIPS.abiflags)
    	}
}

" > $1/linker_script.ld
