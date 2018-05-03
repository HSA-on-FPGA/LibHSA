PROJECT = main

CXX = g++

BUILD_NAME = mti2hex
BUILD_DIR = build/
SRC_DIR = src/
OBJ_DIR = obj/

INCLUDES = \
	-I./src/ \
	-I../include/ \

CXXFLAGS = $(INCLUDES) -std=c++0x -c
LDFLAGS  = $(INCLUDES)

SRCS = $(wildcard $(SRC_DIR)*.cpp)
OBJ  = $(SRCS:$(SRC_DIR)%.cpp=$(OBJ_DIR)%.o)
PROGS = $(patsubst %.cpp,%,$(SRCS))

.PHONY: all run clean

# depends on the binary
all: $(BUILD_DIR)$(BUILD_NAME)

# depends on the binary
run: $(BUILD_DIR)$(BUILD_NAME)

clean:
	rm -f .makeenv;
	rm -rf $(OBJ_DIR);
	rm -rf $(BUILD_DIR);

# depends on all user code object files
$(BUILD_DIR)$(BUILD_NAME): $(OBJ)
	mkdir -p $(BUILD_DIR);
	$(CXX) $(OBJ) $(LDFLAGS) -o $(BUILD_DIR)$(BUILD_NAME);

# build object files from cpp sources
$(OBJ_DIR)%.o: $(SRC_DIR)%.cpp $(CONF)
	mkdir -p $(OBJ_DIR);
	$(CXX) $(CXXFLAGS) $< -o $@;

.FORCE:

