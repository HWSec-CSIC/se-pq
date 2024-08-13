# SPIRS RoT DEMO 2.0 --- Pynq-Z2 Board * #

----------

### Directory structure ###

- bin: binary files
- bit: bitstream for Pynq-Z2 board
- out: output files
- run: shellscripts for applications
- src: source files
	- aes: Advanced Encryption Standard (AES)
	- puf: Physical Unclonable Function (PUF/TRNG)
	- rsa: Rivest, Shamir & Adleman Algorithm (RSA)
	- sha2: Secure Hash Algorithm (SHA2)
- Makefile: to generate executables
- README.md: this file 


### Instalation and use ###

- Install C-API in the SD of Pynq-Z2 board
- Copy this distribution to the SD and unzip it
- Run **make** utility to build the executables
- Become root to run the applications and shellscripts:

	**# *run/spirs_demo.sh*** (to try the different SPIRS RoT modules)
 

### Makefile options ###

- all: generate executables for all applications
- bin/*app*: generate executable for this application
- dist: generate distribution file
- clean: delete all binary and output files
- outclean: delete all output files
- distclean: delete distribution file

----------

(*) Use ***changelog.md*** to see the differences from version 1.0 of the SPIRS demonstrator
# AES
