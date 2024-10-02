/**
  * @file aes_hw.h
  * @brief AES HW header
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/

#ifndef _AES_AXI_H
#define _AES_AXI_H

/************************************* Include Files ************************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../common/intf.h"
#include "../common/conf.h"
#include "../common/extra_func.h"


//-- Elements Bit Sizes
#define BLOCK_SIZE	            16
#define BLOCK_OR_IV_BYTES       16
#define KEY_BYTES         	    32
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
#define AES_OP_256_ECB_ENC		0x6  //00110 KEYLEN,ENC_DEC,ECB_CBC		   
#define AES_OP_256_ECB_DEC		0X4  //00100 KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_ECB_ENC		0X2  //00010 KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_ECB_DEC		0X0  //00000 KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_256_CBC_ENC		0x7  //00111 KEYLEN,ENC_DEC,ECB_CBC	
#define AES_OP_256_CBC_DEC		0x5  //00101 KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_CBC_ENC		0x3  //00011 KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_CBC_DEC   		0x1  //00001 KEYLEN,ENC_DEC,ECB_CBC

/*
#define AES_OP_256_ECB_ENC		0x6  //00110 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC		   
#define AES_OP_256_ECB_DEC		0X4  //00100 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_ECB_ENC		0X2  //00010 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_ECB_DEC		0X0  //00000 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_256_CBC_ENC		0x7  //00111 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC	
#define AES_OP_256_CBC_DEC		0x5  //00101 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_CBC_ENC		0x3  //00011 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
#define AES_OP_128_CBC_DEC   		0x1  //00001 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
*/

/****************************************************************************************/
/******************************** AES Function Definitions ******************************/
/****************************************************************************************/

//-- INTERFACE INIT/START & READ/WRITE

void aes_write(unsigned long long address, unsigned long long size,  void *data, INTF interface);
void aes_read(unsigned long long address, unsigned long long size, void *data, INTF interface);

void aes_256_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,INTF interface);

void aes_256_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface);

void aes_128_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,INTF interface);

void aes_128_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface);

void aes_256_cbc_encrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,INTF interface);

void aes_256_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface);

void aes_128_cbc_encrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,INTF interface);

void aes_128_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface);

void subkeys_gen_hw(unsigned char* key, unsigned char* K1, unsigned char* K2, INTF interface);

void aes_128_cmac_hw(unsigned char* key, unsigned char* mac, unsigned int* mac_len, unsigned char* message, unsigned int message_len,  INTF interface);

void subkeys_gen_256_hw(unsigned char* key, unsigned char* K1, unsigned char* K2, INTF interface);

void aes_256_cmac_hw(unsigned char* key, unsigned char* mac, unsigned int* mac_len, unsigned char* message, unsigned int message_len,  INTF interface);

void aes_block_256_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext,  INTF interface);

void aes_block_256_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext,  INTF interface);

void aes_block_128_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface);

void aes_block_128_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface);

void aes_block_256_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, INTF interface);

void aes_block_256_cbc_decrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, INTF interface);

void aes_block_128_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, INTF interface);

void aes_block_128_cbc_decrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned char* ciphertext, unsigned char* plaintext, INTF interface);

#endif  
