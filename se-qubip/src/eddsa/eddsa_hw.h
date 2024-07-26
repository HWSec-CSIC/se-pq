////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 13/06/2024
// File Name: eddsa_hw.h
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		EdDSA HW Handler Functions Header File
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

#ifndef EDDSA_H
#define EDDSA_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../common/mmio.h"
#include "../common/conf.h"
#include "../common/extra_func.h"

//-- Elements Bit Sizes
#define BLOCK_BYTES         128
#define SHA_BYTES           64
#define EDDSA_BYTES         32
#define AXI_BYTES           8

//-- Max. Message Length
#define MAX_MSG_LENGTH      2048

//-- Control Operations
#define EDDSA_RST_OFF       0x00
#define EDDSA_RST_ON        0x01
#define EDDSA_INTF_RST      0x02
#define EDDSA_INTF_OPER     0x00
#define EDDSA_INTF_LOAD     0x04
#define EDDSA_INTF_READ     0x08

//-- I/O Addresses
#define EDDSA_ADDR_CTRL     0x0
#define EDDSA_ADDR_PRIV     0x1
#define EDDSA_ADDR_PUB      0x5
#define EDDSA_ADDR_MSG      0x9
#define EDDSA_ADDR_LEN      0x19
#define EDDSA_ADDR_SIGVER   0x1A
#define EDDSA_ADDR_SIGPUB   0x1

//-- Operation Modes
#define EDDSA_OP_GEN_KEY    0x4
#define EDDSA_OP_SIGN       0x8
#define EDDSA_OP_VERIFY     0xC

//-- Debug
#define EDDSA_WAIT_TIME     5000
#define EDDSA_N_ITER        1000

//-- INTERFACE INIT/START & READ/WRITE
void eddsa25519_init(unsigned long long operation, MMIO_WINDOW ms2xl);
void eddsa25519_start(MMIO_WINDOW ms2xl);
void eddsa25519_write(unsigned long long address, unsigned long long size, void *data, unsigned long long reset, MMIO_WINDOW ms2xl);
void eddsa25519_read(unsigned long long address, unsigned long long size, void *data, MMIO_WINDOW ms2xl);

//-- GENERATE PUBLIC KEY
void eddsa25519_genkeys_hw(unsigned char **pri_key, unsigned char **pub_key, unsigned int *pri_len, unsigned int *pub_len, MMIO_WINDOW ms2xl);
void eddsa448_genkeys_hw(unsigned char **pri_key, unsigned char **pub_key, unsigned int *pri_len, unsigned int *pub_len, MMIO_WINDOW ms2xl);

//-- SIGN
void eddsa25519_sign_hw(unsigned char *msg, unsigned int msg_len, unsigned char *pri_key, unsigned int pri_len, unsigned char *pub_key, unsigned int pub_len, unsigned char **sig, unsigned int *sig_len, MMIO_WINDOW ms2xl);
void eddsa448_sign_hw(unsigned char *msg, unsigned int msg_len, unsigned char *pri_key, unsigned int pri_len, unsigned char *pub_key, unsigned int pub_len, unsigned char **sig, unsigned int *sig_len, MMIO_WINDOW ms2xl);

//-- VERIFY
void eddsa25519_verify_hw(unsigned char *msg, unsigned int msg_len, unsigned char *pub_key, unsigned int pub_len, unsigned char *sig, unsigned int sig_len, unsigned int *result, MMIO_WINDOW ms2xl);
void eddsa448_verify_hw(unsigned char *msg, unsigned int msg_len, unsigned char *pub_key, unsigned int pub_len, unsigned char *sig, unsigned int sig_len, unsigned int *result, MMIO_WINDOW ms2xl);

#endif