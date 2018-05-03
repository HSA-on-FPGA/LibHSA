Description of code\_config.dat file format for vsim2cmd:
=========================================================

first line:
----------
- lookup table to the lines below.
- numbers or '-' separated by one space each
- Each entry describes an accelarator core
- '-' indicates this core doesn't need a configuration

second line and below:
----------------------
- describles where to find the mti files and how much space they need (in multiples of 4K byte)
- one line consits of 3 entries: 
  - path to vsim directory
  - memory needed for instructions
  - memory needed for data
- a vsim directory needs to contain a instr.mem and data.mem file (both in mti format)
- only 2 64 bit or 4 32 bit words in hexadecimal format per line are supported
