////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 09/07/2024
// File Name: x25519_hw.h
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		X25519 HW Handler Functions Header File
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

#ifndef X25519_H
#define X25519_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../common/mmio.h"
#include "../common/conf.h"
#include "../common/extra_func.h"

//-- Elements Bit Sizes
#define X25519_BYTES          32
#define AXI_BYTES              8

//-- Control Operations
#define X25519_RST_OFF      0x00
#define X25519_RST_ON       0x01
#define X25519_INTF_RST     0x02
#define X25519_INTF_OPER    0x00
#define X25519_INTF_LOAD    0x04
#define X25519_INTF_READ    0x08

//-- I/O Addresses
#define X25519_SCALAR      0x0
#define X25519_POINT_IN    0x4
#define X25519_POINT_OUT   0x0

//-- Debug
#define X25519_WAIT_TIME    5000
#define X25519_N_ITER       1000

//-- INTERFACE INIT/START & READ/WRITE
void x25519_init(MMIO_WINDOW ms2xl);
void x25519_start(MMIO_WINDOW ms2xl);
void x25519_write(unsigned long long address, unsigned long long size, void *data, unsigned long long reset, MMIO_WINDOW ms2xl);
void x25519_read(unsigned long long address, unsigned long long size, void *data, MMIO_WINDOW ms2xl);

//-- GENERATE PUBLIC KEY
void x25519_genkeys_hw(unsigned char **pri_key, unsigned char **pub_key, unsigned int *pri_len, unsigned int *pub_len, MMIO_WINDOW ms2xl);

//-- ECDH X25519 OPERATION
void x25519_hw(unsigned char *scalar, unsigned char *point_in, unsigned char *point_out, MMIO_WINDOW ms2xl);

#endif