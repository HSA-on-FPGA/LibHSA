source ../../../../global_conf.sh

export MIPS_NUM_TEXT_MEM_BLOCKS=2
export MIPS_NUM_DATA_MEM_BLOCKS=3
# number of 64 bit values possible to store
export MIPS_STACK_SIZE=256
export MIPS_HEAP_SIZE=512

export MIPS_TEXT_SIZE=$(expr 4096 \* $MIPS_NUM_TEXT_MEM_BLOCKS)
export MIPS_DATA_SIZE=$(expr 4096 \* $MIPS_NUM_DATA_MEM_BLOCKS)
