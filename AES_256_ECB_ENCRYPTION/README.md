# QUBIP AES DEMO 1.0 --- Pynq-Z2 Board * #

----------

### Directory structure ###

- bin: binary files
- bit: bitstream for Pynq-Z2 board
- out: output files
- src: source files
	- aes: Advanced Encryption Standard (AES)
	
- Makefile: to generate executables
- README.md: this file 


### Instalation and use ###

- Install C-API in the SD of Pynq-Z2 board
- Copy this distribution to the SD and unzip it
- Run **make** utility to build the executables
- Become root to run the applications and shellscripts:

	**# sudo ./bin/aes_test  (to test the QUBIP AES Module)
 

### Makefile options ###

- all: generate executables for all applications
- bin/*app*: generate executable for this application
- dist: generate distribution file
- clean: delete all binary and output files
- outclean: delete all output files
- distclean: delete distribution file

----------


