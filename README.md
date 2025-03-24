# SE-QUBIP

## Introduction

This is the repository of the Secure Element (SE) developed by CSIC-IMSE team within QUBIP project.  

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
	        ├── eddsa       # EdDSA files
	        ├── x25519      # X25519 files
            ├── trng        # TRNG files
            ├── AES         # AES files
            └── MLKEM       # MLKEM files 	    	
        └── src             # folder that contains the sources files of the library
            .
            ├── common      # common files 
            ├── sha3        # SHA3 files 
	        ├── sha2        # SHA2 files 
            ├── eddsa       # EdDSA files
	        ├── x25519      # X25519 files
            ├── trng        # TRNG files
            ├── AES         # AES files
            └── MLKEM       # MLKEM files 
    ├── demo                # folder that contains the demo
    ├── se-qubip.h          # header of the library
    ├── Makefile            # To compile the library
    ├── SE_QUBIP_2_0.rar    # The IP Module of the Secure Element
    └── README.md  

For now (***v2.0***) the list of supported algorithms are:

| Sym. Enc. I   | Sym. Enc. II   | Hash          | EC            | RNG           | PQC           |
| --------      | --------       | ---------     | -------       | -------       | -------       |
| AES-128-ECB   | AES-192-CCM-8  | SHA-256       | EdDSA25519    | TRNG          | MLKEM-512     |
| AES-128-CBC   | AES-192-GCM    | SHA-384       | X25519        |               | MLKEM-768     |            
| AES-128-CMAC  | AES-256-ECB    | SHA-512       |               |               | MLKEM-1024    |
| AES-128-CCM-8 | AES-256-CBC    | SHA-512/256   |               |               |               |                           
| AES-128-GCM   | AES-256-CMAC   | SHA3-256      |               |               |               |                        
| AES-192-ECB   | AES-256-CCM-8  | SHA3-512      |               |               |               |
| AES-192-CBC   | AES-256-GCM    | SHAKE128      |               |               |               |
| AES-192-CMAC  |                | SHAKE256      |               |               |               |

<!--
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
- TRNG
- MLKEM:
    - MLKEM-512
    - MLKEM-768
    - MLKEM-1024
- AES:
    - AES-128-ECB
    - AES-128-CBC
    - AES-128-CMAC
    - AES-128-CCM-8
    - AES-128-GCM
    - AES-192-ECB
    - AES-192-CBC
    - AES-192-CMAC
    - AES-192-CCM-8
    - AES-192-GCM
    - AES-256-ECB
    - AES-256-CBC
    - AES-256-CMAC
    - AES-256-CCM-8
    - AES-256-GCM
-->

## Interface

### Vivado IP Integrator

#### SE-QUBIP Interface

The SE-QUBIP IP module (**SE_QUBIP_2_0.rar**) can be configured to use either the AXI-Lite or I2C interface. Additionally, each cryptographic algorithm can be independently selected for implementation. The following figure illustrates the interface in Vivado IP Integrator:

<img src="img/SE_QUBIP_Vivado_Interface.jpg" width="1000">

#### PYNQZ2 Block Diagram

For **PYNQZ2 platform** include the ZYNQ7 Processing System IP in the block diagram.

<img src="img/PYNQZ2_block_diagram.jpg" width="1000">

#### ZCU104 Block Diagram

For **ZCU104 platform** include the Zynq UltraScale+ MPSoC IP in the block diagram.

<img src="img/ZCU104_block_diagram.jpg" width="1000">

#### Genesys II Block Diagram

For **Genesys II platform** include the Clocking Wizard IP, together with the constraint file **genesys_ii.xdc** which can be found at **/se-qubip/rtl/common/** folder.

<img src="img/GENESYS_II_block_diagram.jpg" width="1000">

### AXI-Lite (MPU flavour)

The AXI-Lite drivers are described using the PYNQ API interface. To use the SE in the MPU IoT device, it is mandatory to have installed this interface. In the case, the developers desire to test the SE in **PYNQZ2 platform** should follow the next steps to install the PYNQ API repository:  

1. Download the PYNQ C-API from [here](https://github.com/mesham/pynq_api/). 

2. To modify the clock frequency (it is mandatory for the demo) you must edit the file ```src/pynq_api.c``` to replace **0x00** with **address** on _line 327_:

```c
    // return PYNQ_writeMMIO(&(state->mmio_window), &write_data, **0x00**, sizeof(unsigned int));
    return PYNQ_writeMMIO(&(state->mmio_window), &write_data, **address**, sizeof(unsigned int));
```

3. Then, issue ```make```. Once it is built, issue ```sudo make install```. 

By default, within the QUBIP project, the platform to be used will be the **ZCU104**. For that, the developers just have to follow the instructions of the modified PYNQ API [here](https://gitlab.com/hwsec/pynq-api-ultrascale).

### I2C (MCU flavour)

The **I2C Slave Interface** enables communication between a master device (such as a **Raspberry Pi 4B**) and the SE-QUBIP platform, allowing for read and write operations with the cryptographic IP cores. It supports several key features including glitch filtering and dynamic configuration.

#### Key Features
- **Device Address**: The I2C address is set to `0x1A` by default.
- **Supported Cryptographic Cores**: SHA-3, SHA-2, AES, EDDSA, X25519, TRNG, MLKEM.
- **Glitch Filtering**: Configurable filtering for cleaner signal transmission, with dynamic adjustments possible via registers:
  - **Register `0xFD`**: Zero-threshold filter value.
  - **Register `0xFE`**: One-threshold filter value.
  - **Register `0xFF`**: Filter width value.

#### I2C Communication and Configuration
- **SCL & SDA Lines**: The I2C communication takes place over the **SCL** (clock) and **SDA** (data) lines, which are synchronized and filtered to detect start/stop conditions and maintain stable data exchange.
- **State Machine (FSM)**: Manages the I2C protocol flow, including address recognition, data transmission, and synchronization with the Raspberry Pi.
- **Data Registers**: Internal registers store data from the master writes and provide output for read operations.
- **Configuration Registers**: Support dynamic adjustments in communication behavior and glitch filtering.

#### Raspberry Pi 4B as Master
The Raspberry Pi 4B, acting as the I2C master, controls the communication via its built-in Linux I2C libraries. It generates the clock signals and manages data transmission, sending start conditions, addressing the FPGA, and performing read/write operations according to the I2C protocol.

#### Pin Connections

The following diagram shows the I/O connections between the **Raspberry Pi 4B** and the **Genesys Board II**:

<img src="img/I2C_Diagram.jpg" width="1000">

## Installation

### Makefile Configuration

The SE-QUBIP library is ready to perform the communication to the hardware through two different interfaces: AXI-Lite and I2C. All this implementation has been done through the `INTF` variable into the code. 
To select this configuration during the compilation process, it is ***mandatory*** to change the variable `INTERFACE` (`AXI` or `I2C`) and `BOARD` (`ZCU104` or `PYNQZ2`). If `INTERFACE = I2C`, then the variable `BOARD` is not applied.

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

3. There is also possible to install the library into the system local folder. For that, 
```bash
make install
```

4. In case it was necessary to remove the old version of the SE-QUBIP library already installed in the system folder type:
```bash
make uninstall
```

You can skip this step and go directly to the `demo` section. 

## Demo

It has been implemented different type of demo:
- `demo`: the basic demo is working just showing the functionality of the SE. It will return a ✅ in case the implemented algorithm is working properly or ❌ in other case.
- `demo-speed`: The results will show performance in term of Elapsed Time (ET) of each cryptograhic algorithm. 
- `demo-acc`: It will return the HW acceleration versus the SW implementation of the algorithms for different flavours already presented in [CRYPTO_API](https://gitlab.com/hwsec/crypto_api_sw). 

For the use type `make XXX-YYY` where `XXX` and `YYY` can be: 

| XXX                   | Meaning   |
| ----------            | --------- |
| demo                  | Functionality Demo                                        |
| demo-speed            | Execution Time Demo                                       |
| demo-acc-openssl      | HW Acceleration vs OpenSSL flavour of [CRYPTO_API](https://gitlab.com/hwsec/crypto_api_sw)           |
| demo-acc-mbedtls      | HW Acceleration vs MbedTLS flavour of [CRYPTO_API](https://gitlab.com/hwsec/crypto_api_sw)           |
| demo-acc-alt          | HW Acceleration vs ALT flavour of [CRYPTO_API](https://gitlab.com/hwsec/crypto_api_sw)               |

| YYY           | Meaning   |
| ----------    | --------- |
| all           | Local compilation of the whole SE-QUBIP library                    |
| build         | Use of the local shared libraries in build/ folder                 |
| install       | Use of the *already* installed library in the system local folder  |

*Note: To perform the acc test it is ***mandatory*** to have installed the [CRYPTO_API](https://gitlab.com/hwsec/crypto_api_sw) library*.

It is possible to change the behaviour of demo with the file ```config.conf```. The variables ```SHA-2```, ```SHA-3```, etc. represent the type of algorithm to be tested. If ```1``` is set the test will be performed, while a ```0``` will point out that this test won't be performed. The variable ```N_TEST``` set the number of test to be performed to calculate the average execution time.  

For any demo it is possible to type `-v` or `-vv` for different verbose level. For example, `./demo-install -vv`. *We do not recommend that for long test.*  

## Results of Performance

***Results of SE will be published soon.***

<!-- 
The next section describe the average Execution Time of different platforms and libraries of the cryptography algorithms after ***1000*** tests. This results are shown in the `results` folder.  

| Plattform         | Speed Test                                | acc vs OpenSSL 3                          | acc vs MbedTLS                            | acc vs ALT                                    |
| ----------        | ---------                                 | -------                                   | ---------                                 | ---------                                     |
| **Pynq-Z2** *(AXI)*  | TBD                             | TBD     | TBD      |TBD                             |
| **ZCU-104** *(AXI)*           | [link](results/zcu104/zcu104_speed.txt)   | <a href="https://hwsec.gitlab.io/se-qubip/zcu104/zcu104_acc_openssl.html" target="_blank">link<a> | TBD | <a href="https://hwsec.gitlab.io/se-qubip/zcu104/zcu104_acc_openssl.html" target="_blank">link</a>  |
| **Genesys2** *(I2C)*           | TBD                                            | TBD                                        | TBD      | TBD                                           |

\* _TBD: To Be Done_
-->

## Contact

**Eros Camacho-Ruiz** - (camacho@imse-cnm.csic.es)

_Hardware Cryptography Researcher_ 

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_

## Developers

Eros Camacho-Ruiz, Pablo Navarro-Torrero, Pau Ortega-Castro, Apurba Karmakar

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_

## Note 

The .html files of results have been generated with this command: 

```bash
sudo apt-get install colorized-logs
./demo-acc-alt-all | ansi2html > output.html
```