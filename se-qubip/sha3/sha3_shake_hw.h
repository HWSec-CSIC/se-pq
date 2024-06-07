#ifndef SHA3_SHAKE_H
#define SHA3_SHAKE_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "sha3_shake_hw.h"
#include "math.h"

#include <pynq_api.h>

/************************ MS2XL Constant Definitions **********************/

#define MS2XL_LENGTH   0x40

#define LOAD_LENGTH				1
#define LOAD					2
#define START					3

#define DATA_IN  0x0		/**< data_in */
#define ADDRESS  0x8		/**< address */
#define CONTROL  0x10		/**< control */
#define DATA_OUT 0x18		/**< data_out */
#define END_OP   0x20		/**< end_op */

/************************ MS2XL Function Definitions **********************/

void sha3_shake_ms2xl_init(PYNQ_MMIO_WINDOW ms2xl, int VERSION);
void sha3_shake_ms2xl(unsigned long long int* a, unsigned long long int* b, PYNQ_MMIO_WINDOW ms2xl, unsigned int pos_pad, int pad, int shake, int VERSION, int SIZE_SHA3, int SIZE_BLOCK, int DBG);
void sha3_shake_hw(unsigned char* in, unsigned char* out, unsigned int length, unsigned int length_out, int VERSION, int SIZE_BLOCK, int SIZE_SHA3, PYNQ_MMIO_WINDOW ms2xl, int DBG);

/************************ Main Functions **********************/

void sha3_256_hw_func(unsigned char* in, unsigned char* out, unsigned int length, PYNQ_MMIO_WINDOW ms2xl);
void sha3_512_hw_func(unsigned char* in, unsigned char* out, unsigned int length, PYNQ_MMIO_WINDOW ms2xl);
void shake128_hw_func(unsigned char* in, unsigned char* out, unsigned int length, unsigned int length_out, PYNQ_MMIO_WINDOW ms2xl);
void shake256_hw_func(unsigned char* in, unsigned char* out, unsigned int length, unsigned int length_out, PYNQ_MMIO_WINDOW ms2xl);

#endif