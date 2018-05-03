#!/bin/bash

source conf.sh

echo "\
export MIPS_NUM_TEXT_MEM_BLOCKS=$MIPS32_NUM_TEXT_MEM_BLOCKS
export MIPS_NUM_DATA_MEM_BLOCKS=$MIPS32_NUM_DATA_MEM_BLOCKS\
" > $1/simulation.env
