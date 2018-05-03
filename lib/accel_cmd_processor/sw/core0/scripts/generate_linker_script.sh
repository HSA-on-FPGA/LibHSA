#!/bin/bash

source conf.sh

mkdir -p $1

echo "\
OUTPUT_FORMAT(\"elf32-bigmips\",\"elf32-littlemips\",
          \"elf32-bigmips\")

MEMORY
	{
		TEXT : ORIGIN = 0x00000000, LENGTH = $MIPS32_TEXT_SIZE
		DATA : ORIGIN = 0x01000000, LENGTH = $MIPS32_DATA_SIZE
	}

REGION_ALIAS(\"REGION_TEXT\", TEXT);
REGION_ALIAS(\"REGION_RODATA\", DATA);
REGION_ALIAS(\"REGION_BSS\", DATA);
REGION_ALIAS(\"REGION_DATA\", DATA);

STARTUP(ld/startup.o)

/*GROUP(libgcc.a)*/
/*ENTRY (_start)*/

/* define stack size and heap size here */
stack_size = $MIPS32_STACK_SIZE;
heap_size = $MIPS32_HEAP_SIZE;

_stack_start = ORIGIN(DATA) + $MIPS32_DATA_SIZE - 4;

SECTIONS
{
        .text ALIGN(4):
	{
            *(.text .text.*)
            FILL(0x00000000);
            . = ORIGIN(TEXT) + LENGTH(TEXT) - 1;
            BYTE(0x00);
	} > REGION_TEXT
        . = ORIGIN(DATA);
	.rodata ALIGN(4):
	{
            FILL(0x00000000);
	    *(.rodata)
            *(.roadata)
            QUAD(0x00000000);
	} > REGION_RODATA
	.bss ALIGN(4):
	{
            FILL(0x00000000);
	    *(.bss)
            *(.sbss)
            QUAD(0x00000000);
	} > REGION_BSS
	.data ALIGN(4):
	{
	    *(.data)
            . = ALIGN(4);
	    *(.sdata)
            . = ALIGN(4);
            *(COMMON)
            . = ALIGN(4);
            *(.scommon)
            . = ALIGN(4);
            *(.heap)
            _heap_start = .;
            . += heap_size*4;
            _heap_end = . - 4;
            . = ALIGN(4);
            *(.stack)
            _stack_end = .;
            . = . + stack_size*4;
            FILL(0x00000000);
            . = ORIGIN(DATA) + LENGTH(DATA) - 1;
            BYTE(0x00);
	} > REGION_DATA

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
