#ifndef MLKEM_H
#define MLKEM_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "../common/intf.h"
#include "../common/conf.h"

#include "../../../se-qubip.h"

/************************ MS2XL Constant Definitions **********************/

#define MLKEM_RESET		    0x01
#define MLKEM_LOAD_COINS	0x02
#define MLKEM_LOAD_SK		0x04
#define MLKEM_READ_SK		0x05
#define MLKEM_LOAD_PK		0x06
#define MLKEM_READ_PK		0x07
#define MLKEM_LOAD_CT		0x08
#define MLKEM_READ_CT		0x09
#define MLKEM_LOAD_SS		0x0a
#define MLKEM_READ_SS		0x0b
#define MLKEM_START		    0x0c

#define MLKEM_GEN_KEYS_512	0x05
#define MLKEM_GEN_KEYS_768	0x06
#define MLKEM_GEN_KEYS_1024	0x07
#define MLKEM_ENCAP_512		0x09
#define MLKEM_ENCAP_768		0x0a
#define MLKEM_ENCAP_1024	0x0b
#define MLKEM_DECAP_512		0x0d
#define MLKEM_DECAP_768		0x0e
#define MLKEM_DECAP_1024	0x0f

/************************ MS2XL Function Definitions **********************/

/************************ Gen Keys Functions **********************/
void mlkem_512_gen_keys_hw(unsigned char* pk, unsigned char* sk, INTF interface);
void mlkem_768_gen_keys_hw(unsigned char* pk, unsigned char* sk, INTF interface);
void mlkem_1024_gen_keys_hw(unsigned char* pk, unsigned char* sk, INTF interface);
void mlkem_gen_keys_hw(int k, unsigned char* pk, unsigned char* sk, INTF interface);

/************************ Encryption Functions **********************/
void mlkem_512_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, INTF interface);
void mlkem_768_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, INTF interface);
void mlkem_1024_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, INTF interface);
void mlkem_enc_hw(int k, unsigned char* pk, unsigned char* ct, unsigned char* ss, INTF interface);
void mlkem_enc_coins_hw(int k, unsigned char* pk, unsigned char* ct, unsigned char* ss, unsigned char* coins, INTF interface);

/************************ Decryption Functions **********************/
void mlkem_512_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, INTF interface);
void mlkem_768_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, INTF interface);
void mlkem_1024_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, INTF interface);
void mlkem_dec_hw(int k, unsigned char* sk, unsigned char* ct, unsigned char* ss, INTF interface);
#endif