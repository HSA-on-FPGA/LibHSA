CORE_DIR = core/
EXE_DIR  = ../../../tools/prepare_segments/
HEX_DIR  = ../../../tools/hex_tools/

.PHONY: all clean

all:
	cd $(EXE_DIR)  && $(MAKE)
	./$(EXE_DIR)build/vsim2cmd "code_config.dat" && mv code_segments.h $(CORE_DIR)src/
	cd $(CORE_DIR) && $(MAKE)
	cd $(HEX_DIR)  && $(MAKE)
	./$(HEX_DIR)build/mti2hex "$(CORE_DIR)vsim/instr.mem" 32
	./$(HEX_DIR)build/mti2hex "$(CORE_DIR)vsim/data.mem" 64

clean:
	cd $(CORE_DIR) && $(MAKE) clean
	cd $(EXE_DIR)  && $(MAKE) clean
	cd $(HEX_DIR)  && $(MAKE) clean
	rm -f $(CORE_DIR)src/code_segments.h
	rm -f $(CORE_DIR)vsim/instr.hex
	rm -f $(CORE_DIR)vsim/data.hex
