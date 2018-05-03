CORE_DIR = core/
TOOL_DIR = ../../../tools/packet_tools/
HEX_DIR  = ../../../tools/hex_tools/

.PHONY: all custom clean

all:
	cd $(CORE_DIR) && $(MAKE)
	cd $(TOOL_DIR) && $(MAKE)
	cd $(TOOL_DIR)build && ./aql2mem "dram.mem" "default" && mv dram.mem ../../../lib/packet_processor/sw/core/vsim/
	cd $(HEX_DIR)  && $(MAKE)
	./$(HEX_DIR)build/mti2hex "$(CORE_DIR)vsim/instr.mem" 32
	./$(HEX_DIR)build/mti2hex "$(CORE_DIR)vsim/data.mem" 64

custom:
	cd $(CORE_DIR) && $(MAKE)
	cd $(TOOL_DIR) && $(MAKE) run
	cd $(HEX_DIR)  && $(MAKE)
	./$(HEX_DIR)build/mti2hex "$(CORE_DIR)vsim/instr.mem"
	./$(HEX_DIR)build/mti2hex "$(CORE_DIR)vsim/data.mem"

clean:
	cd $(CORE_DIR) && $(MAKE) clean
	cd $(TOOL_DIR) && $(MAKE) clean
	cd $(HEX_DIR)  && $(MAKE) clean
	rm -f $(CORE_DIR)vsim/instr.hex
	rm -f $(CORE_DIR)vsim/data.hex
	rm -f $(CORE_DIR)vsim/dram.mem
