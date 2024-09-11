/****************************************************************************************/
/*
 *  IMSE.CNM_QUBIP_aes_axi_256: aes_hw.h 
 *
 *  Created on: 26/08/2024
 *      Author: apurba@imse-cnm.csic.es
 */
/****************************************************************************************/

#ifndef _AES_AXI_H
#define _AES_AXI_H

/************************************* Include Files ************************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../common/mmio.h"
#include "../common/conf.h"
#include "../common/extra_func.h"


//-- Elements Bit Sizes
#define BLOCK_SIZE	        16
#define BLOCK_OR_IV_BYTES       16
#define KEY_BYTES         	32
#define AXI_BYTES           	8

#define MAX_PLAINTEXT_LENGTH	16

//-- Control Operations // CONTROL[3:0] -->> READ,LOAD,RST_ITF,RST

#define AES_RST_ON       	0x00   	//0000  RESET THE MODULE
#define AES_RST_OFF        	0x01	//0001	RESET OFF, MODULE READY TO GO
#define AES_INTF_RST      	0x02	//0010  RESET INTERFACE OF THE MODULE
#define AES_INTF_OPER     	0x01	//0001	RESET INTERFACE OFF, MODULE INTERFACE READY TO GO
#define AES_LOAD        	0x04	//0100	RESET OFF, MODULE IS READY TO LOAD THE DATA
#define AES_READ        	0x08	//1000	RESET OFF, MODULE IS READY TO READ THE DATA

//-- I/O Addresses

#define AES_ADDR_CTRL     	0x0
#define AES_ADDR_KEY     	0x1
#define AES_ADDR_IV     	0x5
#define AES_ADDR_BLOCK     	0x7
#define AES_ADDR_RESULT     	0x1
#define AES_ADDR_RESULT_VALID	0x0

//-- Operation Modes
#define AES_OP_256_ECB_ENC		0x6  //00110 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC		   
#define AES_OP_256_ECB_DEC		0X4  //00100 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_ECB_ENC		0X2  //00010 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_ECB_DEC		0X0  //00000 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_256_CBC_ENC		0x7  //00111 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC	
#define AES_OP_256_CBC_DEC		0x5  //00101 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_CBC_ENC		0x3  //00011 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_CBC_DEC   		0x1  //00001 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC



/****************************************************************************************/
/******************************** AES Function Definitions ******************************/
/****************************************************************************************/

//-- INTERFACE INIT/START & READ/WRITE

void aes_write(unsigned long long address, unsigned long long size,  void *data, MMIO_WINDOW ms2xl);
void aes_read(unsigned long long address, unsigned long long size, void *data, MMIO_WINDOW ms2xl);

void aes_256_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,MMIO_WINDOW ms2xl);

void aes_256_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl);

void aes_128_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,MMIO_WINDOW ms2xl);

void aes_128_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl);

void aes_256_cbc_encrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,MMIO_WINDOW ms2xl);

void aes_256_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl);

void aes_128_cbc_encrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,MMIO_WINDOW ms2xl);

void aes_128_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl);

void aes_block_256_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext,  MMIO_WINDOW ms2xl);

void aes_block_256_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext,  MMIO_WINDOW ms2xl);

void aes_block_128_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl);

void aes_block_128_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl);

void aes_block_256_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, MMIO_WINDOW ms2xl);

void aes_block_256_cbc_decrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, MMIO_WINDOW ms2xl);

void aes_block_128_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, MMIO_WINDOW ms2xl);

void aes_block_128_cbc_decrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, MMIO_WINDOW ms2xl);

#endif  
