## Changes in Version 2.0 ##

### IP Repository ###

- aes\_axi\_1.0
	- (no reimplementation required)
- puf4R3\_2.0   
	- GUI: *AXI\_ADDR\_WIDTH* calculated automatically based on *AXI\_DATA\_WIDTH*
	- (no reimplementation required)
- rsa\_3.0      
	- Parameterizable in terms of Block-Size and AXI4 Bus-Width
	- Internal clock derived from AXI4 interface clock via the *CLK\_DIV\_BY* parameter					   
- sha2\_256_4.0 
	- New version of the IP-module that corrects errors and eliminates warnings

### Software Development Kit (RoT\_demo\_4.0) ###

- aes:  
	- Format changes in outgoing messages
	- Count of the number of tests passed and failed
- puf:  
	- Fixed some bugs in PUF applications
- rsa:
	- Functions to verify the correct operation of the module and illustrate its behavior   		  
- sha2: 
	- Format changes in outgoing messages
	- Count of the number of tests passed on SW and HW
	- Debug mode ***"-v 0"*** for quick behavior check
- Scripts: 
	- ***# run/spirs_demo.sh***: to illustrate the operation of the different elements of the SPIRS RoT
