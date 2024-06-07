# CRYPTO_API_SW

## Introduction

This SW API is a compilation of different crypto primitives described in SW that will work as a basic elements for HW implementations. This library is going to work as a SW reference of HW developing. 

## Description

The content of the CRYPTO-API SW library is depicted in the next container tree:
    
    .
    ├── CRYPTO_API_SW       # folder that all the files of the API.
        .
        ├── build           # folder to store the shared libraries 
        └── src             # folder that contains the sources files
            .
            ├── aes         # AES files
            ├── eddsa       # EdDSA files 
            ├── mlkem       # ML-KEM files 
            ├── rsa         # RSA files 
            ├── sha2        # SHA2 files 
            ├── sha3        # SHA3 files 
            └── trng        # TRNG files
    ├── demo                # folder that contains the demo
    ├── CRYPTO_API_SW.h     # header of the library
    ├── Makefile            # To compile the library
    └── README.md  

For now (v1.0) the list of supported algorithms are:
- AES:
    - AES-128-ECB
    - AES-128-CBC
    - AES-128-CMAC
    - AES-192-ECB
    - AES-192-CBC
    - AES-192-CMAC
    - AES-256-ECB
    - AES-256-CBC
    - AES-256-CMAC
- RSA:
    - RSA-2048-PKE
    - RSA-3072-PKE
    - RSA-4096-PKE
    - RSA-6144-PKE
    - RSA-8192-PKE
- EdDSA:
    - EdDSA-25519   
    - EdDSA-448
- SHA2:
    - SHA-224
    - SHA-256
    - SHA-384
    - SHA-512
    - SHA-512/224
    - SHA-512/256
- SHA3:
    - SHA3-224
    - SHA3-256
    - SHA3-384
    - SHA3-512
    - SHAKE128
    - SHAKE256
- MLKEM:
    - MLKEM-512
    - MLKEM-768
    - MLKEM-1024
- TRNG:
    - Undeterminated number of bytes

## Installation

### OpenSSL 3

The library requires the latest version of OpenSSL. Visit the [OpenSSL Website](https://www.openssl.org/source/) to download and install it. 

We recomend the following installation settings: 

1. After downloading the OpenSSL distribution go to the `openssl` folder. 

```bash
git clone https://github.com/openssl/openssl.git
cd openssl
```

2. If you are using a different version of OpenSSL, ***we strongly recomend to not overwrite the OS version.*** For that, type: 
```bash
./Configure --prefix=/opt/openssl --openssldir=/usr/local/ssl
```

3. Then, initiate the installation:
```bash
make install
```

4. After that, we recomend to add the libraries to the `LD_LIBRARY_PATH`. In our case: 
```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/xilinx/openssl/
```

### Library Installation

For the installation, it is necessary to follow the next steps: 

1. Download the repository
```bash
sudo git clone https://gitlab.com/hwsec/crypto_api_sw
```

2. At this point there are two ways to installation. You can generate the shared libraries directly after the downloading and use them in any other program. For that, 
```bash
make build
```
The shared libraries will be generated in `CRYPTO_API_SW/build/` folder. 

If you are using a local OpenSSL library (as it is detailed in the Installation section), you can modify the `OPENSSL_DIR` variable in the Makefile, and type: 
```bash
make build-lib
```

It might be necessary to add the output libraries to the `LD_LIBRARY_PATH`. In our case: 
```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/xilinx/crypto_api_sw/CRYPTO_API_SW/build
```

You can skip this step and go directly to the `demo` section. 

## Demo

The Demo presented in this repository is working just showing the functionality of the SW API. For the use: 

1. In the folder `demo`, type: 
```bash
make demo-build
```
if the library in the step 2 of the Installation section has been compiled. Otherwise, type: 
```bash
make demo-all
```
This will compile the library and the demo. If you are using a local OpenSSL library (as it is detailed in the Installation section), you can modify the `OPENSSL_DIR` variable in the Makefile, and type: 
```bash
make demo-all-lib
```

2. To run the demo, type: 
```bash
./demo-build
```
or
```bash
./demo-all
```
or
```bash
./demo-all-lib
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

## Developers

Eros Camacho-Ruiz

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_