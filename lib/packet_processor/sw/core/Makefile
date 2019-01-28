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

CROSSCOMPILER_PREFIX = $(MIPS64_GCC_PREFIX)
CROSSCOMPILER_PATH = $(MIPS64_GCC_PATH)
PATH_TARGETLIBRARIES = $(IMPERAS_HOME)/lib/$(IMPERAS_ARCH)/TargetLibraries
ARCHIVE1 = $(CROSSCOMPILER_PATH)/$(MIPS64_GCC_PREFIX)/lib/soft-float
ARCHIVE2 = $(CROSSCOMPILER_PATH)/lib/gcc/$(MIPS64_GCC_PREFIX)/5.3.0/soft-float

INCLUDES = \
	-I./src/ \
	-I../include/ \
	-I$(CROSSCOMPILER_PATH)/$(CROSSCOMPILER_PREFIX)/include \
	-I$(SYSTEM_DIR) \

LIBRARIES = \
	-L$(ARCHIVE1) -L$(ARCHIVE2) -lgcc -lc

# no div or mul
CFLAGS  =  $(INCLUDES) $(LIBRARIES) -mips3 -mabi=64 -mlong64 -mno-sym32 -EL -mno-mips16 -msoft-float -mno-dsp -mno-smartmips -mno-mt -mno-branch-likely -mno-fp-exceptions -mno-check-zero-division -mno-unaligned-mem-access -mnohwdiv -mnohwmult -std=c99 -DSIZE=$(SIZE_) -DMAX_QUEUE_LENGTH=$(SIZE_AQL_QUEUE) -DAVAILABLE_CORES=$(NUM_ACCELERATOR_CORES) -DDISPATCH_WINDOW_SIZE=$(PP_SIZE_DISPATCH_WINDOW) -nostartfiles -nodefaultlibs -nostdlib -c -S -Os -fdata-sections -ffunction-sections -mno-gpopt
ASFLAGS = -EL -mips3 -mabi=64 -64 -mno-sym32 -no-mdebug -mno-micromips -mno-smartmips -no-mips3d -no-mdmx -mno-dsp -mno-mcu --no-trap -msoft-float

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
#-0 | tr '\\n' '\\t' | tr '\\0' '\\n' | sed 's/^.*\\t.*$//' | sed '/^$/d' |
# make starts everything in a child process
# this line sources the configuration file, prints out the environment of the
# child process, converts the bash sytnax to make syntax and stores the
# variables in the file makeenv
IGNORE := $(shell env -i bash -c "source conf.sh; env | sed 's/=/:=/' | sed 's/^/export /' > .makeenv")
include .makeenv

# depends on the application and the elf binary
all: application $(BUILD_DIR)$(ELFFILE) $(VSIM_DIR)instr.mem $(VSIM_DIR)data.mem $(VSIM_DIR)simulation.env

clean:
	rm -f $(ASM);
	rm -f $(SYS_ASM);
	rm -f $(OBJ);
	rm -f $(SYS_OBJ);
	rm -f $(LD_DIR)$(LD_SCRIPT);
	rm -f $(LD_DIR)startup.o;
	rm -f .makeenv;
	rm -f $(VSIM_DIR)instr.mem $(VSIM_DIR)data.mem $(VSIM_DIR)simulation.env
	rm -rf $(BUILD_DIR);

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

$(VSIM_DIR)instr.mem: $(BUILD_DIR)$(ELFFILE) $(CONF)
	mkdir -p $(VSIM_DIR)
	./$(SCRIPTS_DIR)elf2mem.sh $(BUILD_DIR)$(ELFFILE) $(VSIM_DIR);

$(VSIM_DIR)data.mem: $(BUILD_DIR)$(ELFFILE) $(CONF)
	mkdir -p $(VSIM_DIR)
	./$(SCRIPTS_DIR)elf2mem.sh $(BUILD_DIR)$(ELFFILE) $(VSIM_DIR);

# generate simulation environment file
# this file contains variables that are used to set generics in the VHDL
# testbench via tcl
$(VSIM_DIR)simulation.env: $(CONF)
	mkdir -p $(VSIM_DIR)
	./$(SCRIPTS_DIR)generate_simulation_env.sh $(VSIM_DIR);

.FORCE:

# add application specific dependencies here
application:
