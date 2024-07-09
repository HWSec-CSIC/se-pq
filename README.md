# SE-QUBIP

## Introduction

This is the repostiory of the Secure Element developed by CSIC-IMSE team within QUBIP project. 

## Description

The content of the SE-QUBIP library is depicted in the next container tree:
    
    .
    ├── se-qubip            # folder that contains all the files of the SE.
        .
        ├── bit             # folder to store the bitstream files
        ├── build           # folder to store the shared libraries 
        └── rtl             # folder that contains the RTL sources files
            .
            ├── common      # common files 
            ├── sha3        # SHA3 files 
            ├── sha2        # SHA2 files 
            ├── trng        # TRNG files
	    ├── eddsa	    # EdDSA files
	    └── x25519	    # X25519 files
	    
        └── src             # folder that contains the sources files of the library
            .
            ├── common      # common files 
            ├── sha3        # SHA3 files 
	    ├── sha2        # SHA2 files 
            ├── eddsa	    # EdDSA files
	    └── x25519	    # X25519 files
    ├── demo                # folder that contains the demo
    ├── se-qubip.h          # header of the library
    ├── Makefile            # To compile the library
    ├── SE_QUBIP_1_0.rar    # The IP Module of the Secure Element
    └── README.md  

For now (***v3.0***) the list of supported algorithms are:
- SHA2:
    - SHA-256
    - SHA-384
    - SHA-512
    - SHA-512/256
- SHA3:
    - SHA3-256
    - SHA3-512
    - SHAKE128
    - SHAKE256
- EDDSA:
    - EdDSA25519
- ECDH:
    - X25519


## Installation

### Library Installation

For the installation, it is necessary to follow the next steps: 

1. Download the repository
```bash
sudo git clone https://gitlab.com/hwsec/se-qubip
```

2. You can generate the shared libraries directly after the downloading and use them in any other program. For that, 
```bash
make build
```
The shared libraries will be generated in `se-qubip/build/` folder. 

It might be necessary to add the output libraries to the `LD_LIBRARY_PATH`. In our case: 
```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/xilinx/se-qubip/se-qubip/build
```

You can skip this step and go directly to the `demo` section. 

## Demo

The Demo presented in this repository is working just showing the functionality of the SE. For the use: 

1. In the folder `demo`, type: 
```bash
make demo-build
```
if the library in the step 2 of the Installation section has been compiled. Otherwise, type: 
```bash
make demo-all
```

2. To run the demo, type: 
```bash
./demo-build
```
or
```bash
./demo-all
```

3. It is optional to perform a speed demo (`demo_speed.c`). For that change `demo` to `demo-speed` in the step 2. An example can be: 
```bash
make demo-speed-build
./demo-speed-build
```
The results will also show performance in term of Elapsed Time (ET) of each cryptograhic algorithm. 

## Contact

**Eros Camacho-Ruiz** - (camacho@imse-cnm.csic.es)

_Hardware Cryptography Researcher_ 

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_

**Pablo Navarro-Torrero** - (navarro@imse-cnm.csic.es)

_Hardware Cryptography Researcher_ 

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_

## Developers

Eros Camacho-Ruiz

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_

Pablo Navarro-Torrero

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_