#ifndef SHA3_SHAKE_H
#define SHA3_SHAKE_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "../common/mmio.h"
#include "../common/conf.h"

/************************ MS2XL Constant Definitions **********************/

#define LOAD_LENGTH_SHA3			1
#define LOAD_SHA3					2
#define START_SHA3					3

/************************ MS2XL Function Definitions **********************/

void sha3_shake_ms2xl_init(MMIO_WINDOW ms2xl, int VERSION);
void sha3_shake_ms2xl(unsigned long long int* a, unsigned long long int* b, MMIO_WINDOW ms2xl, unsigned int pos_pad, int pad, int shake, int VERSION, int SIZE_SHA3, int SIZE_BLOCK, int DBG);
void sha3_shake_hw(unsigned char* in, unsigned char* out, unsigned int length, unsigned int length_out, int VERSION, int SIZE_BLOCK, int SIZE_SHA3, MMIO_WINDOW ms2xl, int DBG);

/************************ Main Functions **********************/

void sha3_256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, MMIO_WINDOW ms2xl);
void sha3_512_hw_func(unsigned char* in, unsigned int length, unsigned char* out, MMIO_WINDOW ms2xl);
void shake128_hw_func(unsigned char* in, unsigned int length, unsigned char* out, unsigned int length_out, MMIO_WINDOW ms2xl);
void shake256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, unsigned int length_out, MMIO_WINDOW ms2xl);

#endif