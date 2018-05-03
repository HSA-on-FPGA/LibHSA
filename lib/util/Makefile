SUBDIRS = axi_address_converter/ dualclock_bram/ datamover/

.PHONY: build clean $(SUBDIRS)

build: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
