SW_DIR = sw/
HW_DIR = hw/

.PHONY: all clean

all:
	cd $(SW_DIR) && $(MAKE)
	cd $(HW_DIR) && $(MAKE)

clean:
	cd $(SW_DIR) && $(MAKE) clean
	cd $(HW_DIR) && $(MAKE) clean
