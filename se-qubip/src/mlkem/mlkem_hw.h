#ifndef MLKEM_H
#define MLKEM_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "../common/mmio.h"
#include "../common/conf.h"

#include "../../../se-qubip.h"

/************************ MS2XL Constant Definitions **********************/

#define RESET		0x01
#define LOAD_COINS	0x02
#define LOAD_SK		0x04
#define READ_SK		0x05
#define LOAD_PK		0x06
#define READ_PK		0x07
#define LOAD_CT		0x08
#define READ_CT		0x09
#define LOAD_SS		0x0a
#define READ_SS		0x0b
#define START		0x0c

#define GEN_KEYS_512	0x05
#define GEN_KEYS_768	0x06
#define GEN_KEYS_1024	0x07
#define ENCAP_512		0x09
#define ENCAP_768		0x0a
#define ENCAP_1024		0x0b
#define DECAP_512		0x0d
#define DECAP_768		0x0e
#define DECAP_1024		0x0f

/************************ MS2XL Function Definitions **********************/

/************************ Gen Keys Functions **********************/
void mlkem_512_gen_keys_hw(unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl);
void mlkem_768_gen_keys_hw(unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl);
void mlkem_1024_gen_keys_hw(unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl);
void mlkem_gen_keys_hw(int k, unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl);

/************************ Encryption Functions **********************/
void mlkem_512_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl);
void mlkem_768_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl);
void mlkem_1024_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl);
void mlkem_enc_hw(int k, unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl);
void mlkem_enc_coins_hw(int k, unsigned char* pk, unsigned char* ct, unsigned char* ss, unsigned char* coins, MMIO_WINDOW ms2xl);

/************************ Decryption Functions **********************/
void mlkem_512_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, MMIO_WINDOW ms2xl);
void mlkem_768_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, MMIO_WINDOW ms2xl);
void mlkem_1024_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, MMIO_WINDOW ms2xl);
void mlkem_dec_hw(int k, unsigned char* sk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl);
#endif