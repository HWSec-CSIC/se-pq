////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pau Ortega Castro
//
// Create Date: 24/07/2024
// File Name: trng_hw.h
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		TRNG HW Handler Functions Header
//
////////////////////////////////////////////////////////////////////////////////////

#ifndef TRNG_H
#define TRNG_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../common/mmio.h"
#include "../common/conf.h"
#include "../common/extra_func.h"

//-- Elements Bit Sizes
#define TRNG_MAX_BYTES          2048
#define AXI_BYTES              	8

//-- Control Operations
#define TRNG_RST_OFF      		0x00
#define TRNG_RST_ON       		0x01
#define TRNG_INTF_RST     		0x02
#define TRNG_INTF_OPER    		0x00
#define TRNG_INTF_LOAD    		0x04
#define TRNG_INTF_READ    		0x08

//-- I/O Addresses
#define TRNG_IN      	 		0x0
#define TRNG_PUF_OUT    		0x0
#define TRNG_PUF_ADDW 	 		0x1

//-- Debug
#define TRNG_WAIT_TIME    		500000

//-- INTERFACE INIT/START & READ/WRITE
void trng_init(MMIO_WINDOW ms2xl);
void trng_start(unsigned int bytes, MMIO_WINDOW ms2xl);
void trng_read(unsigned char* out, unsigned int bytes, MMIO_WINDOW ms2xl);

//-- TRNG Function
void trng_hw(unsigned char* out, unsigned int bytes, MMIO_WINDOW ms2xl);


#endif