PROJECT = main

PATH_GCC		= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-gcc
PATH_AS			= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-as
PATH_LD			= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-ld
PATH_AR			= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-ar
PATH_NM			= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-nm
PATH_RANLIB		= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-ranlib
PATH_STRIP		= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-strip
PATH_READELF	= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-readelf
PATH_OBJDUMP	= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-objdump
PATH_OBJCOPY	= $(CROSSCOMPILER_PATH)/bin/$(CROSSCOMPILER_PREFIX)-objcopy

CC = $(PATH_GCC)
#CC = /tmp/clang/build_patched/bin/clang -target mips-mips_reduced-mips_reduced
AS = $(PATH_AS)
LD = $(PATH_LD)
HD = $(PATH_OBJDUMP)


BUILD_DIR = build/
SRC_DIR = src/
ASM_DIR = asm/
OBJ_DIR = obj/
LD_DIR = ld/
LD_SCRIPT = linker_script.ld
ELFFILE = $(PROJECT).elf
HEXFILE = $(PROJECT).hex
CONF = conf.sh
VSIM_DIR = vsim/
SCRIPTS_DIR = scripts/
SYSTEM_DIR = system/
HEX_DIR = ../../../../tools/hex_tools/

CROSSCOMPILER_PREFIX = $(MIPS32_GCC_PREFIX)
CROSSCOMPILER_PATH = $(MIPS32_GCC_PATH)
PATH_TARGETLIBRARIES = $(IMPERAS_HOME)/lib/$(IMPERAS_ARCH)/TargetLibraries
ARCHIVE1 = $(CROSSCOMPILER_PATH)/$(MIPS32_GCC_PREFIX)/lib/soft-float
ARCHIVE2 = $(CROSSCOMPILER_PATH)/lib/gcc/$(MIPS32_GCC_PREFIX)/5.3.0/soft-float

INCLUDES = \
	-I./src/ \
	-I./include/ \
	-I$(CROSSCOMPILER_PATH)/$(CROSSCOMPILER_PREFIX)/include \
	-I$(SYSTEM_DIR) \

LIBRARIES = \
	-L$(ARCHIVE1) -L$(ARCHIVE2) -lgcc -lc

# no div or mul
CFLAGS  =  $(INCLUDES) $(LIBRARIES) -mips1 -EL -mno-mips16 -msoft-float -mno-dsp -mno-smartmips -mno-mt -mno-branch-likely -mno-fp-exceptions -mno-check-zero-division -mno-unaligned-mem-access -mnohwdiv -mnohwmult -std=c99 -DSIZE=$(SIZE_) -DNUM_THREADS=$(NUM_NYUZI_THREADS) -nostartfiles -nodefaultlibs -nostdlib -c -S -Os -mno-gpopt
#CFLAGS  =  $(INCLUDES) $(LIBRARIES) -mips1 -EL -mno-mips16 -msoft-float -mno-dsp -mno-smartmips -mno-mt -mno-branch-likely -mno-fp-exceptions -mno-check-zero-division -mno-unaligned-mem-access -mnohwdiv -mnohwmult -std=c99 -DSIZE=$(SIZE_) -nostartfiles -nodefaultlibs -nostdlib -c -S -Os -fdata-sections -ffunction-sections -mno-gpopt
# WIDTH DIV AND MUL
#CFLAGS  =  $(INCLUDES) $(LIBRARIES) -march=mips1 -EL -mno-mips16 -msoft-float -mno-dsp -mno-smartmips -mno-mt -mno-branch-likely -mno-fp-exceptions -mno-check-zero-division -mno-unaligned-mem-access -std=c99 -DSIZE=$(SIZE_) -nostartfiles -nodefaultlibs -nostdlib -c -S -Os -fdata-sections -ffunction-sections -mno-gpopt
#CFLAGS  =  $(INCLUDES) $(LIBRARIES) -march=mips1 -EB -mno-mips16 -msoft-float -mno-dsp -mno-smartmips -mno-mt -mno-branch-likely -mno-fp-exceptions -mno-check-zero-division -mpatfree -mnohwdiv -mnohwmult -std=c99 -DSIZE=$(SIZE_) -nostartfiles -nodefaultlibs -nostdlib -c -S -Os -fdata-sections -ffunction-sections -mno-gpopt
#CFLAGS  =  $(INCLUDES) $(LIBRARIES) -EB -mno-mips16 -msoft-float -mno-dsp -mno-check-zero-division -std=c99 -DSIZE=$(SIZE_) -nostartfiles -nodefaultlibs -nostdlib -c -S -Os -fdata-sections -ffunction-sections
#CFLAGS  =  $(INCLUDES) $(LIBRARIES) -march=mips1 -EB -mno-mips16 -msoft-float -mno-dsp -mno-smartmips -mno-mt -mno-branch-likely -mno-fp-exceptions -mno-check-zero-division -mpatfree -mnohwdiv -mnohwmult -std=c99 -DSIZE=$(SIZE_) -nostartfiles -nodefaultlibs -nostdlib -c -S -O0
ASFLAGS = -EL -mips1 -no-mdebug -mno-micromips -mno-smartmips -no-mips3d -no-mdmx -mno-dsp -mno-mcu --no-trap -msoft-float

#LDFLAGS =   $(LIBRARIES) $(INCLUDES) -T $(LD_DIR)$(LD_SCRIPT) -nostartfiles -nostdlib -W1,--gc-sections -dead_strip -W1,--strip_all -fwhole-program -W1,-G1024
LDFLAGS =   $(LIBRARIES) $(INCLUDES) -T $(LD_DIR)$(LD_SCRIPT) -nostartfiles -nostdlib
HDFLAGS = -d

SRCS = $(wildcard $(SRC_DIR)*.c)
ASM  = $(SRCS:$(SRC_DIR)%.c=$(ASM_DIR)%.s)
OBJ  = $(SRCS:$(SRC_DIR)%.c=$(OBJ_DIR)%.o)
PROGS = $(patsubst %.c,%,$(SRCS))
SYS_SRC = $(wildcard $(SYSTEM_DIR)*.c)
SYS_ASM = $(SYS_SRC:$(SYSTEM_DIR)%.c=$(ASM_DIR)%.s)
SYS_OBJ = $(SYS_SRC:$(SYSTEM_DIR)%.c=$(OBJ_DIR)%.o)

.PHONY: clean application

.SECONDARY: $(ASM) $(SYS_ASM)

# make starts everything in a child process
# this line sources the configuration file, prints out the environment of the
# child process, converts the bash sytnax to make syntax and stores the
# variables in the file makeenv
IGNORE := $(shell env -i bash -c "source conf.sh; env | sed 's/=/:=/' | sed 's/^/export /' > .makeenv")
include .makeenv

# depends on the application and the elf binary
all: application $(BUILD_DIR)$(ELFFILE) $(VSIM_DIR)instr.mem $(VSIM_DIR)data.mem $(VSIM_DIR)instr.hex $(VSIM_DIR)data.hex $(VSIM_DIR)simulation.env

clean:
	rm -f $(ASM);
	rm -f $(SYS_ASM);
	rm -f $(OBJ);
	rm -f $(SYS_OBJ);
	rm -f $(LD_DIR)$(LD_SCRIPT);
	rm -f $(LD_DIR)startup.o;
	rm -f .makeenv;
	rm -f $(VSIM_DIR)instr.mem $(VSIM_DIR)data.mem $(VSIM_DIR)simulation.env
	rm -f $(VSIM_DIR)instr.hex $(VSIM_DIR)data.hex
	rm -rf $(BUILD_DIR);
	cd $(HEX_DIR) && $(MAKE) clean

# depends on the linker script, the startup object code and all user code object files
$(BUILD_DIR)$(ELFFILE): $(LD_DIR)$(LD_SCRIPT) $(LD_DIR)startup.o $(OBJ) $(SYS_OBJ)
	mkdir -p $(BUILD_DIR);
	$(CC) $(OBJ) $(SYS_OBJ) $(LDFLAGS) -o $(BUILD_DIR)$(ELFFILE);
	$(PATH_OBJDUMP) -d -j .text $(BUILD_DIR)$(ELFFILE) > $(BUILD_DIR)code_dump;

# build startup object code
$(LD_DIR)startup.o:
	$(AS) $(ASFLAGS) $(SRC_DIR)startup.s -o $@;

# build object files from user assember code
$(OBJ_DIR)%.o: $(ASM_DIR)%.s
	mkdir -p $(OBJ_DIR);
	$(AS) $(ASFLAGS) $< -o $@;

# build object files from system assember code
#$(SYS_OBJ): $(SYS_ASM)
#	mkdir -p $(OBJ_DIR);
#	$(AS) $(ASFLAGS) $< -o $@;

# build user assember code from c sources
$(ASM_DIR)%.s: $(SRC_DIR)%.c
	mkdir -p $(ASM_DIR);
	$(CC) $(CFLAGS) $< -o $@;

# build system assembler code from c sources
$(ASM_DIR)%.s: $(SYSTEM_DIR)%.c
	mkdir -p $(ASM_DIR);
	$(CC) $(CFLAGS) $< -o $@;

$(LD_DIR)$(LD_SCRIPT): $(CONF)
	./$(SCRIPTS_DIR)generate_linker_script.sh $(LD_DIR);

$(HEX_DIR)build/mti2hex:
	cd $(HEX_DIR) && $(MAKE)

$(VSIM_DIR)instr.mem: $(BUILD_DIR)$(ELFFILE) $(CONF)
	mkdir -p $(VSIM_DIR)
	./$(SCRIPTS_DIR)elf2mem.sh $(BUILD_DIR)$(ELFFILE) $(VSIM_DIR);

$(VSIM_DIR)data.mem: $(BUILD_DIR)$(ELFFILE) $(CONF)
	mkdir -p $(VSIM_DIR)
	./$(SCRIPTS_DIR)elf2mem.sh $(BUILD_DIR)$(ELFFILE) $(VSIM_DIR);

$(VSIM_DIR)instr.hex: $(HEX_DIR)build/mti2hex $(VSIM_DIR)instr.mem
	./$(HEX_DIR)build/mti2hex "$(VSIM_DIR)instr.mem" 64

$(VSIM_DIR)data.hex: $(HEX_DIR)build/mti2hex $(VSIM_DIR)data.mem
	./$(HEX_DIR)build/mti2hex "$(VSIM_DIR)data.mem" 64

# generate simulation environment file
# this file contains variables that are used to set generics in the VHDL
# testbench via tcl
$(VSIM_DIR)simulation.env: $(CONF)
	mkdir -p $(VSIM_DIR)
	./$(SCRIPTS_DIR)generate_simulation_env.sh $(VSIM_DIR);

.FORCE:

# add application specific dependencies here
application:
