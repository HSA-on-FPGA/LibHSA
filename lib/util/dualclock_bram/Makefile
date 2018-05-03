.PHONY: clean build

build: build/ip/component.xml

build/ip/component.xml:
	vivado -mode batch -source build.tcl

clean:
	rm -rf build/
	rm -f vivado*.jou
	rm -f vivado*.log
