SUBDIRS = lib/packet_processor lib/accel_cmd_processor lib/rom_accel_cmd_processor lib/fpga_cmd_processor lib/util

.PHONY: build debug clean $(SUBDIRS)

build: $(SUBDIRS)

debug: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
