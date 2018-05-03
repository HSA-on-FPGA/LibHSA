export MIPS32_GCC_PATH=/opt/hsa/gcc-mips32-installed
export MIPS32_GCC_PREFIX=mipsel-elf

export MIPS64_GCC_PATH=/opt/hsa/gcc-mips-installed
export MIPS64_GCC_PREFIX=mips64el-elf

export SIZE_AQL_QUEUE=128      # must be power of 2
export NUM_ACCELERATOR_CORES=1

export DRAM_SIZE=$((2**32))
export PP_DRAM_RESERVED=$((64 * SIZE_AQL_QUEUE + 4 * SIZE_AQL_QUEUE + 2 * 8))

