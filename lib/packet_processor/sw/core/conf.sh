source ../../../../global_conf.sh

export PP_NUM_TEXT_MEM_BLOCKS=3
export PP_NUM_DATA_MEM_BLOCKS=2

export PP_SIZE_DISPATCH_WINDOW=8  # must be power of 2

# number of 64 bit values possible to store
export PP_STACK_SIZE=128
export PP_HEAP_SIZE=$(((DRAM_SIZE - PP_DRAM_RESERVED) / 8))

export PP_TEXT_SIZE=$(expr 4096 \* $PP_NUM_TEXT_MEM_BLOCKS)
export PP_DATA_SIZE=$(expr 4096 \* $PP_NUM_DATA_MEM_BLOCKS)
