PROJECT = main

CXX = g++

BUILD_NAME = aql2mem
BUILD_DIR = build/
SRC_DIR = src/
OBJ_DIR = obj/
CONF = ../../global_conf.sh
VSIM_DIR = vsim/

INCLUDES = \
	-I./src/ \
	-I./include/ \

CXXFLAGS = $(INCLUDES) -std=c++0x -DMAX_QUEUE_LENGTH=$(SIZE_AQL_QUEUE) -c
LDFLAGS  = $(INCLUDES)

SRCS = $(wildcard $(SRC_DIR)*.cpp)
OBJ  = $(SRCS:$(SRC_DIR)%.cpp=$(OBJ_DIR)%.o)
PROGS = $(patsubst %.cpp,%,$(SRCS))

.PHONY: all run clean

# make starts everything in a child process
# this line sources the configuration file, prints out the environment of the
# child process, converts the bash sytnax to make syntax and stores the
# variables in the file makeenv
IGNORE := $(shell bash -c "source ../../global_conf.sh; env | sed 's/=/:=/' | sed 's/^/export /' > .makeenv")
include .makeenv

# depends on the binary
all: $(BUILD_DIR)$(BUILD_NAME)

# depends on the binary
run: $(BUILD_DIR)$(BUILD_NAME) $(VSIM_DIR)dram.mem

clean:
	rm -f $(VSIM_DIR)dram.mem
	rm -f .makeenv;
	rm -rf $(OBJ_DIR);
	rm -rf $(BUILD_DIR);

# depends on all user code object files
$(BUILD_DIR)$(BUILD_NAME): $(OBJ)
	mkdir -p $(BUILD_DIR);
	$(CXX) $(OBJ) $(LDFLAGS) -o $(BUILD_DIR)$(BUILD_NAME);

# build object files from c sources
$(OBJ_DIR)%.o: $(SRC_DIR)%.cpp $(CONF)
	mkdir -p $(OBJ_DIR);
	$(CXX) $(CXXFLAGS) $< -o $@;

$(VSIM_DIR)dram.mem: $(BUILD_DIR)$(BUILD_NAME) $(CONF)
	mkdir -p $(VSIM_DIR);
	./$(BUILD_DIR)$(BUILD_NAME) "dram.mem";
	mv ./$(BULD_DIR)"dram.mem" ./$(VSIM_DIR);

.FORCE:

