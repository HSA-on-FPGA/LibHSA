.PHONY: clean build

build: build/ip/component.xml

build/ip/component.xml:
	vivado -mode batch -source build.tcl

clean:
	rm -rf build/
	rm -rf .Xil/
	rm -f vivado*.log
	rm -f vivado*.jou
