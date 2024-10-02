/**
  * @file aes_hw.c
  * @brief AES Test File
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

#include "aes_hw.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define BLOCK_SIZE 16  // AES block size in bytes (128 bits)

void aes_write(unsigned long long address, unsigned long long size,  void *data, INTF interface)
{
    unsigned long long addr = address;
    unsigned long long control = (ADD_AES << 32) + AES_LOAD + AES_RST_OFF;
    
    write_INTF(interface, &addr, ADDRESS, AXI_BYTES);
    write_INTF(interface, data, DATA_IN, AXI_BYTES);
    write_INTF(interface, &control, CONTROL, AXI_BYTES);

    for (int i = 1; i < size; i++)
    {
        addr = address + i;
        write_INTF(interface, &addr, ADDRESS, AXI_BYTES);
        write_INTF(interface, data + AXI_BYTES * i, DATA_IN, AXI_BYTES);
    }
    
    control = (ADD_AES << 32) + AES_RST_OFF;
    write_INTF(interface, &control, CONTROL, AXI_BYTES);
}

void aes_read(unsigned long long address, unsigned long long size, void *data, INTF interface)
{
    unsigned long long control = (ADD_AES << 32) + AES_READ + AES_RST_OFF;
    unsigned long long addr;

    write_INTF(interface, &control, CONTROL, AXI_BYTES);

    for (int i = 0; i < size; i++)
    {
        addr = address + i;
        write_INTF(interface, &addr, ADDRESS, AXI_BYTES);
        read_INTF(interface, data + AXI_BYTES * i, DATA_OUT, AXI_BYTES);
    }
    
    control = (ADD_AES << 32) + AES_RST_OFF;
    write_INTF(interface, &control, CONTROL, AXI_BYTES);
}


// Function to encrypt a plaintext using AES-256 in ECB mode
void aes_256_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,INTF interface)

{
    unsigned int num_blocks;

    // Calculate the number of blocks needed
    num_blocks = (plaintext_len + BLOCK_SIZE - 1) / BLOCK_SIZE;
	unsigned char key_len = KEY_BYTES;
	swapEndianness(key, key_len);
	//swapEndianness(plaintext, plaintext_len);
    // Encrypt each block
    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned int block_len = (i == num_blocks - 1 && plaintext_len % BLOCK_SIZE != 0) 
                                  ? plaintext_len % BLOCK_SIZE 
                                  : BLOCK_SIZE;

        unsigned char plaintext_block[BLOCK_SIZE] = {0}; // Zero-initialize the block
        unsigned char ciphertext_block[BLOCK_SIZE] = {0}; // Zero-initialize the ciphertext block

        // Copy the appropriate portion of plaintext into the block, padded with zeros if necessary
        if (plaintext == NULL || plaintext_block == NULL || block_len > BLOCK_SIZE) {
            fprintf(stderr, "Invalid memory operation: Null pointer or block length out of bounds.\n");
            exit(EXIT_FAILURE);
        }

        memcpy(plaintext_block, &plaintext[i * BLOCK_SIZE], block_len);

        // Encrypt the block using AES (ECB mode)
        aes_block_256_ecb_encrypt_hw(key, ciphertext_block,plaintext_block, interface);

        // Copy the encrypted block to the ciphertext output
        memcpy(&ciphertext[i * BLOCK_SIZE], ciphertext_block, BLOCK_SIZE);
    }

    // Set the length of the ciphertext
    *ciphertext_len = num_blocks * BLOCK_SIZE;
   // printf("Ciphertext length: %u bytes\n", *ciphertext_len);
}


void aes_256_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
    unsigned int num_blocks = (ciphertext_len + BLOCK_SIZE - 1) / BLOCK_SIZE;
    //unsigned char key_len = KEY_BYTES;
    //swapEndianness(key, key_len);
    //swapEndianness(ciphertext, ciphertext_len);

    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned int block_len = (i == num_blocks - 1 && ciphertext_len % BLOCK_SIZE != 0)
                                  ? ciphertext_len % BLOCK_SIZE
                                  : BLOCK_SIZE;

        unsigned char ciphertext_block[BLOCK_SIZE] = {0};
        unsigned char plaintext_block[BLOCK_SIZE] = {0};

        // Fill the ciphertext block with data
        memcpy(ciphertext_block, &ciphertext[i * BLOCK_SIZE], block_len);

        // Decrypt the block using AES (ECB mode)
        aes_block_256_ecb_decrypt_hw(key, ciphertext_block, plaintext_block, interface);
	
        // Copy the decrypted block to the plaintext output
        memcpy(&plaintext[i * BLOCK_SIZE], plaintext_block, BLOCK_SIZE);
    }

    // Set the length of the plaintext (if necessary)
    *plaintext_len = num_blocks * BLOCK_SIZE;
}



// Function to encrypt a plaintext using AES-256 in ECB mode
void aes_128_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,INTF interface)

{
    unsigned int num_blocks;

    // Calculate the number of blocks needed
    num_blocks = (plaintext_len + BLOCK_SIZE - 1) / BLOCK_SIZE;
	unsigned char key_len = KEY_BYTES;
	swapEndianness(key, key_len);
	//swapEndianness(plaintext, plaintext_len);
    // Encrypt each block
    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned int block_len = (i == num_blocks - 1 && plaintext_len % BLOCK_SIZE != 0) 
                                  ? plaintext_len % BLOCK_SIZE 
                                  : BLOCK_SIZE;

        unsigned char plaintext_block[BLOCK_SIZE] = {0}; // Zero-initialize the block
        unsigned char ciphertext_block[BLOCK_SIZE] = {0}; // Zero-initialize the ciphertext block

        // Copy the appropriate portion of plaintext into the block, padded with zeros if necessary
        if (plaintext == NULL || plaintext_block == NULL || block_len > BLOCK_SIZE) {
            fprintf(stderr, "Invalid memory operation: Null pointer or block length out of bounds.\n");
            exit(EXIT_FAILURE);
        }

        memcpy(plaintext_block, &plaintext[i * BLOCK_SIZE], block_len);

        // Encrypt the block using AES (ECB mode)
        aes_block_128_ecb_encrypt_hw(key, ciphertext_block,plaintext_block, interface);

        // Copy the encrypted block to the ciphertext output
        memcpy(&ciphertext[i * BLOCK_SIZE], ciphertext_block, BLOCK_SIZE);
    }

    // Set the length of the ciphertext
    *ciphertext_len = num_blocks * BLOCK_SIZE;
  //  printf("Ciphertext length: %u bytes\n", *ciphertext_len);
}


void aes_128_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
    unsigned int num_blocks = (ciphertext_len + BLOCK_SIZE - 1) / BLOCK_SIZE;
    //unsigned char key_len = KEY_BYTES;
    //swapEndianness(key, key_len);
    //swapEndianness(ciphertext, ciphertext_len);

    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned int block_len = (i == num_blocks - 1 && ciphertext_len % BLOCK_SIZE != 0)
                                  ? ciphertext_len % BLOCK_SIZE
                                  : BLOCK_SIZE;

        unsigned char ciphertext_block[BLOCK_SIZE] = {0};
        unsigned char plaintext_block[BLOCK_SIZE] = {0};

        // Fill the ciphertext block with data
        memcpy(ciphertext_block, &ciphertext[i * BLOCK_SIZE], block_len);

        // Decrypt the block using AES (ECB mode)
        aes_block_128_ecb_decrypt_hw(key, ciphertext_block, plaintext_block, interface);
	
        // Copy the decrypted block to the plaintext output
        memcpy(&plaintext[i * BLOCK_SIZE], plaintext_block, BLOCK_SIZE);
    }

    // Set the length of the plaintext (if necessary)
    *plaintext_len = num_blocks * BLOCK_SIZE;
}


// Function to encrypt a plaintext using AES-256 in CBC mode

void aes_256_cbc_encrypt_hw( unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext,  unsigned int plaintext_len, INTF interface) 

{
    unsigned int num_blocks = (plaintext_len + BLOCK_SIZE - 1) / BLOCK_SIZE;

    //printf("Number of blocks: %u\n", num_blocks);
    unsigned int calculated_ciphertext_len = num_blocks * BLOCK_SIZE;
    
    if (*ciphertext_len < calculated_ciphertext_len) {
        fprintf(stderr, "Error: Provided ciphertext buffer is too small.\n");
        return;
    }


    unsigned char previous_block[BLOCK_SIZE];
    
    memcpy(previous_block, iv, BLOCK_SIZE);  // Use the IV for the first block
    swapEndianness(previous_block, BLOCK_SIZE);
      /*  printf("Previous block (hex): ");
    for (int i = 0; i < BLOCK_SIZE; i++) {
        printf("%02x ", previous_block[i]);
    }*/
		
    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned int block_len = (i == num_blocks - 1 && plaintext_len % BLOCK_SIZE != 0)
                                  ? plaintext_len % BLOCK_SIZE
                                  : BLOCK_SIZE;

        unsigned char plaintext_block[BLOCK_SIZE] = {0};
        unsigned char ciphertext_block[BLOCK_SIZE] = {0};

        // Fill the plaintext block with data, padding with zeros if necessary
        memcpy(plaintext_block, &plaintext[i * BLOCK_SIZE], block_len);

        // Print the plaintext block in hexadecimal format
       /* printf("Plaintext block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", plaintext_block[j]);
        }
        printf("\n");*/

        // Encrypt the block using AES-256 CBC mode 
        aes_block_256_cbc_encrypt_hw(key, previous_block, ciphertext_block, plaintext_block, interface);

        // Print the ciphertext block in hexadecimal formathg
        /*printf("Ciphertext block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", ciphertext_block[j]);
        }
        printf("\n"); */
		        
	memcpy(&ciphertext[i * BLOCK_SIZE], ciphertext_block, BLOCK_SIZE);
	
	if (i < num_blocks - 1){
	memcpy(previous_block, ciphertext_block, BLOCK_SIZE);
	}
	/*		
	printf("Previous block (hex): ");
    	for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
        printf("%02x ", previous_block[j]);
    	}*/
       
    }
/*	
    printf("\n");
        printf("Final ciphertext (hex): ");
    for (unsigned int i = 0; i < calculated_ciphertext_len; i++) {
        printf("%02x ", ciphertext[i]);
    }
    printf("\n");*/
    	
    *ciphertext_len = calculated_ciphertext_len;
    //printf("Ciphertext length: %u bytes\n", *ciphertext_len);

}


void aes_256_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
    unsigned int num_blocks = ciphertext_len / BLOCK_SIZE;

    //printf("Number of blocks: %u\n", num_blocks);

    unsigned char previous_block[BLOCK_SIZE];
    memcpy(previous_block, iv, BLOCK_SIZE);  // Use the IV for the first block
    swapEndianness(previous_block, BLOCK_SIZE);
    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned char ciphertext_block[BLOCK_SIZE] = {0};
        unsigned char decrypted_block[BLOCK_SIZE] = {0};

        // Copy the current ciphertext block
        memcpy(ciphertext_block, &ciphertext[i * BLOCK_SIZE], BLOCK_SIZE);

        // Print the ciphertext block in hexadecimal format
       /* printf("Ciphertext block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", ciphertext_block[j]);
        }
        printf("\n");*/

        // Decrypt the block using AES-256 CBC mode (hardware handles decryption and XOR)
        aes_block_256_cbc_decrypt_hw(key, previous_block, ciphertext_block, decrypted_block, interface);

        // Print the decrypted block in hexadecimal format
        /*printf("Decrypted block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", decrypted_block[j]);
        }
        printf("\n");*/

        // Copy the decrypted block to the plaintext output
        memcpy(&plaintext[i * BLOCK_SIZE], decrypted_block, BLOCK_SIZE);

        // Update the previous block for the next iteration
        if (i < num_blocks - 1){
        memcpy(previous_block, ciphertext_block, BLOCK_SIZE);
        }
    }
 
    // Set the length of the plaintext
    //*plaintext_len = num_blocks * BLOCK_SIZE;
    /*printf("\n");
        printf("Recovered Plaintext (hex): ");
    for (unsigned int i = 0; i < *plaintext_len; i++) {
        printf("%02x ", plaintext[i]);
    }
    printf("\n");*/
    // Print the length of the plaintext
    //printf("Plaintext length: %u bytes\n", *plaintext_len);
}

void aes_128_cbc_encrypt_hw( unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext,  unsigned int plaintext_len, INTF interface) 

{
    unsigned int num_blocks = (plaintext_len + BLOCK_SIZE - 1) / BLOCK_SIZE;

    //printf("Number of blocks: %u\n", num_blocks);
    unsigned int calculated_ciphertext_len = num_blocks * BLOCK_SIZE;
    
    if (*ciphertext_len < calculated_ciphertext_len) {
        fprintf(stderr, "Error: Provided ciphertext buffer is too small.\n");
        return;
    }


    unsigned char previous_block[BLOCK_SIZE];
    
    memcpy(previous_block, iv, BLOCK_SIZE);  // Use the IV for the first block
    swapEndianness(previous_block, BLOCK_SIZE);
      /*  printf("Previous block (hex): ");
    for (int i = 0; i < BLOCK_SIZE; i++) {
        printf("%02x ", previous_block[i]);
    }*/
		
    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned int block_len = (i == num_blocks - 1 && plaintext_len % BLOCK_SIZE != 0)
                                  ? plaintext_len % BLOCK_SIZE
                                  : BLOCK_SIZE;

        unsigned char plaintext_block[BLOCK_SIZE] = {0};
        unsigned char ciphertext_block[BLOCK_SIZE] = {0};

        // Fill the plaintext block with data, padding with zeros if necessary
        memcpy(plaintext_block, &plaintext[i * BLOCK_SIZE], block_len);

        // Print the plaintext block in hexadecimal format
       /* printf("Plaintext block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", plaintext_block[j]);
        }
        printf("\n");*/

        // Encrypt the block using AES-256 CBC mode 
        aes_block_128_cbc_encrypt_hw(key, previous_block, ciphertext_block, plaintext_block, interface);

        // Print the ciphertext block in hexadecimal formathg
        /*printf("Ciphertext block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", ciphertext_block[j]);
        }
        printf("\n"); */
		        
	memcpy(&ciphertext[i * BLOCK_SIZE], ciphertext_block, BLOCK_SIZE);
	
	if (i < num_blocks - 1){
	memcpy(previous_block, ciphertext_block, BLOCK_SIZE);
	}
	/*		
	printf("Previous block (hex): ");
    	for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
        printf("%02x ", previous_block[j]);
    	}*/
       
    }
/*	
    printf("\n");
        printf("Final ciphertext (hex): ");
    for (unsigned int i = 0; i < calculated_ciphertext_len; i++) {
        printf("%02x ", ciphertext[i]);
    }
    printf("\n");*/
    	
    *ciphertext_len = calculated_ciphertext_len;
    //printf("Ciphertext length: %u bytes\n", *ciphertext_len);

}




void aes_128_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
    unsigned int num_blocks = ciphertext_len / BLOCK_SIZE;

    //printf("Number of blocks: %u\n", num_blocks);

    unsigned char previous_block[BLOCK_SIZE];
    memcpy(previous_block, iv, BLOCK_SIZE);  // Use the IV for the first block
    swapEndianness(previous_block, BLOCK_SIZE);
    for (unsigned int i = 0; i < num_blocks; i++) {
        unsigned char ciphertext_block[BLOCK_SIZE] = {0};
        unsigned char decrypted_block[BLOCK_SIZE] = {0};

        // Copy the current ciphertext block
        memcpy(ciphertext_block, &ciphertext[i * BLOCK_SIZE], BLOCK_SIZE);

        // Print the ciphertext block in hexadecimal format
       /* printf("Ciphertext block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", ciphertext_block[j]);
        }
        printf("\n");*/

        // Decrypt the block using AES-256 CBC mode (hardware handles decryption and XOR)
        aes_block_128_cbc_decrypt_hw(key, previous_block, ciphertext_block, decrypted_block, interface);

        // Print the decrypted block in hexadecimal format
        /*printf("Decrypted block %d (hex): ", i);
        for (unsigned int j = 0; j < BLOCK_SIZE; j++) {
            printf("%02x ", decrypted_block[j]);
        }
        printf("\n");*/

        // Copy the decrypted block to the plaintext output
        memcpy(&plaintext[i * BLOCK_SIZE], decrypted_block, BLOCK_SIZE);

        // Update the previous block for the next iteration
        if (i < num_blocks - 1){
        memcpy(previous_block, ciphertext_block, BLOCK_SIZE);
        }
    }
 
    // Set the length of the plaintext
    //*plaintext_len = num_blocks * BLOCK_SIZE;
    /*printf("\n");
        printf("Recovered Plaintext (hex): ");
    for (unsigned int i = 0; i < *plaintext_len; i++) {
        printf("%02x ", plaintext[i]);
    }
    printf("\n");*/
    // Print the length of the plaintext
    //printf("Plaintext length: %u bytes\n", *plaintext_len);
}


void xor_blocks(unsigned char* output, const unsigned char* input1, const unsigned char* input2, size_t length) {
    for (size_t i = 0; i < length; i++) {
        output[i] = input1[i] ^ input2[i];
    }
}

void block_leftshift(unsigned char* dst, unsigned char* src)
{
    unsigned char ovf = 0x00;
    for (int i = 15; i >= 0; i--) {
        dst[i] = src[i] << 1;
        dst[i] |= ovf;
        ovf = (src[i] & 0x80) ? 1 : 0;
    }
}


void subkeys_gen_hw(unsigned char* key, unsigned char* K1, unsigned char* K2, INTF interface) {
    unsigned char L[BLOCK_SIZE] = {0};
    unsigned char zero_block[BLOCK_SIZE] = {0};
    unsigned char const_Rb[BLOCK_SIZE] = {
        		0x00, 0x00, 0x00, 0x00,
       	 		0x00, 0x00, 0x00, 0x00,
        		0x00, 0x00, 0x00, 0x00,
        		0x00, 0x00, 0x00, 0x87
    			};
    // Encrypt zero block with the key to generate L
    aes_block_128_ecb_encrypt_hw(key, L, zero_block, interface);
    swapEndianness(L, BLOCK_SIZE);
    	
    block_leftshift(K1, L);
    if (L[0] & 0x80) {
        xor_blocks(K1, K1, const_Rb,BLOCK_SIZE);
    }

    block_leftshift(K2, K1);
    if (K1[0] & 0x80) {
        xor_blocks(K2, K2, const_Rb,BLOCK_SIZE);
    }
}

void aes_128_cmac_hw(unsigned char* key, unsigned char* mac, unsigned int* mac_len, unsigned char* message, unsigned int message_len,  INTF interface) {
    unsigned char K1[BLOCK_SIZE];
    unsigned char K2[BLOCK_SIZE];
    unsigned char last_block[BLOCK_SIZE] = {0};
    unsigned char ciphertext_block[BLOCK_SIZE] = {0};
    

    // Generate subkeys K1 and K2
    subkeys_gen_hw(key, K1, K2, interface);
	
// Handle the case where message is NULL or empty
    if (message == NULL || message_len == 0) {
        // Treat this as a special case, padding with 0x80 followed by zeros
        memset(last_block, 0, BLOCK_SIZE);
        last_block[0] = 0x80; // Apply padding with 0x80
        xor_blocks(last_block, last_block, K2, BLOCK_SIZE);

        // Encrypt the last block to produce the MAC
        unsigned char initial_block[BLOCK_SIZE] = {0}; // Initial vector is zero
        aes_block_128_cbc_encrypt_hw(key, initial_block, mac, last_block, interface);
	swapEndianness(mac, BLOCK_SIZE);
	
        // Set MAC length
        *mac_len = BLOCK_SIZE;
        return;
    }

    else {
    // Determine the number of blocks
    unsigned int num_blocks = (message_len + BLOCK_SIZE - 1) / BLOCK_SIZE;
    unsigned char* M_last;
    int is_complete_block = (message_len % BLOCK_SIZE == 0);

    // Set the last block depending on the padding situation
    if (is_complete_block && num_blocks > 0) {
        M_last = &message[(num_blocks - 1) * BLOCK_SIZE];
        xor_blocks(last_block, M_last, K1, BLOCK_SIZE);
    } else {
        memset(last_block, 0, BLOCK_SIZE);
        memcpy(last_block, &message[(num_blocks - 1) * BLOCK_SIZE], message_len % BLOCK_SIZE);
        last_block[message_len % BLOCK_SIZE] = 0x80; // Padding with 0x80 followed by zeros
        xor_blocks(last_block, last_block, K2, BLOCK_SIZE);
    }

    // Process all blocks except the last one
    unsigned char previous_block[BLOCK_SIZE] = {0}; // Initial is zero block
    
    for (unsigned int i = 0; i < num_blocks - 1; i++) {
        // Encrypt each block, chaining through CBC
       // aes_block_128_cbc_encrypt_hw(key, previous_block, ciphertext_block, &message[i * BLOCK_SIZE], interface);  
        aes_block_128_cbc_encrypt_hw(key, previous_block, previous_block, &message[i * BLOCK_SIZE], interface);

        //memcpy(previous_block, ciphertext_block, BLOCK_SIZE);
                     
    }
			
    // Process the last block
    aes_block_128_cbc_encrypt_hw(key, previous_block, mac, last_block, interface);
    swapEndianness(mac, BLOCK_SIZE);
    	       
    *mac_len = BLOCK_SIZE;
        
    }
                
}

void subkeys_gen_256_hw(unsigned char* key, unsigned char* K1, unsigned char* K2, INTF interface) {
    unsigned char L[BLOCK_SIZE] = {0};
    unsigned char zero_block[BLOCK_SIZE] = {0};
    unsigned char const_Rb[BLOCK_SIZE] = {
        		0x00, 0x00, 0x00, 0x00,
       	 		0x00, 0x00, 0x00, 0x00,
        		0x00, 0x00, 0x00, 0x00,
        		0x00, 0x00, 0x00, 0x87
    			};
    // Encrypt zero block with the key to generate L
    aes_block_256_ecb_encrypt_hw(key, L, zero_block, interface);
    swapEndianness(L, BLOCK_SIZE);
    	
    block_leftshift(K1, L);
    if (L[0] & 0x80) {
        xor_blocks(K1, K1, const_Rb,BLOCK_SIZE);
    }

    block_leftshift(K2, K1);
    if (K1[0] & 0x80) {
        xor_blocks(K2, K2, const_Rb,BLOCK_SIZE);
    }
}

void aes_256_cmac_hw(unsigned char* key, unsigned char* mac, unsigned int* mac_len, unsigned char* message, unsigned int message_len,  INTF interface) {
    unsigned char K1[BLOCK_SIZE];
    unsigned char K2[BLOCK_SIZE];
    unsigned char last_block[BLOCK_SIZE] = {0};
    unsigned char ciphertext_block[BLOCK_SIZE] = {0};
    

    // Generate subkeys K1 and K2
    subkeys_gen_256_hw(key, K1, K2, interface);
	
// Handle the case where message is NULL or empty
    if (message == NULL || message_len == 0) {
        // Treat this as a special case, padding with 0x80 followed by zeros
        memset(last_block, 0, BLOCK_SIZE);
        last_block[0] = 0x80; // Apply padding with 0x80
        xor_blocks(last_block, last_block, K2, BLOCK_SIZE);

        // Encrypt the last block to produce the MAC
        unsigned char initial_block[BLOCK_SIZE] = {0}; // Initial vector is zero
        aes_block_256_cbc_encrypt_hw(key, initial_block, mac, last_block, interface);
	swapEndianness(mac, BLOCK_SIZE);
	
        // Set MAC length
        *mac_len = BLOCK_SIZE;
        return;
    }

    else {
    // Determine the number of blocks
    unsigned int num_blocks = (message_len + BLOCK_SIZE - 1) / BLOCK_SIZE;
    unsigned char* M_last;
    int is_complete_block = (message_len % BLOCK_SIZE == 0);

    // Set the last block depending on the padding situation
    if (is_complete_block && num_blocks > 0) {
        M_last = &message[(num_blocks - 1) * BLOCK_SIZE];
        xor_blocks(last_block, M_last, K1, BLOCK_SIZE);
    } else {
        memset(last_block, 0, BLOCK_SIZE);
        memcpy(last_block, &message[(num_blocks - 1) * BLOCK_SIZE], message_len % BLOCK_SIZE);
        last_block[message_len % BLOCK_SIZE] = 0x80; // Padding with 0x80 followed by zeros
        xor_blocks(last_block, last_block, K2, BLOCK_SIZE);
    }

    // Process all blocks except the last one
    unsigned char previous_block[BLOCK_SIZE] = {0}; // Initial is zero block
    
    for (unsigned int i = 0; i < num_blocks - 1; i++) {
        // Encrypt each block, chaining through CBC
       // aes_block_128_cbc_encrypt_hw(key, previous_block, ciphertext_block, &message[i * BLOCK_SIZE], interface);  
        aes_block_256_cbc_encrypt_hw(key, previous_block, previous_block, &message[i * BLOCK_SIZE], interface);

        //memcpy(previous_block, ciphertext_block, BLOCK_SIZE);
                     
    }
			
    // Process the last block
    aes_block_256_cbc_encrypt_hw(key, previous_block, mac, last_block, interface);
    swapEndianness(mac, BLOCK_SIZE);
    	       
    *mac_len = BLOCK_SIZE;
        
    }
                
}





/////////////////////////////////////////////////////////////////////////////////////////////
// 256-ENCRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////
void aes_block_256_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)


{
       
        
	swapEndianness(plaintext, BLOCK_SIZE); 
	   
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_256_ECB_ENC; //00110
    unsigned long long start_on = 0xE;
    unsigned long long result_valid;	
    
    int nwc = 0;
    

    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
   
	
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,interface);
	
	
	    	    /*    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 1000000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}  */
    
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);
	    	        
	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);

    while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, interface);
	
	//swapEndianness(ciphertext, *ciphertext_len);
		    	
	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);

}


/////////////////////////////////////////////////////////////////////////////////////////////
// 256-DECRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////

void aes_block_256_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)


{
        
    
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_256_ECB_DEC;
    unsigned long long start_on = 0xC; //01100 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    //unsigned long long next_on = 0x14;//10100 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES

    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,interface);	
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);
	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);

    while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, interface);
	
	swapEndianness(plaintext, BLOCK_SIZE);
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
}




/////////////////////////////////////////////////////////////////////////////////////////////
// 128-ENCRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////
void aes_block_128_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)


{
     
    
    //unsigned char key_len = KEY_BYTES;
     //plaintext_len = BLOCK_OR_IV_BYTES;	   
    //*ciphertext_len = BLOCK_OR_IV_BYTES;
    	
	//swapEndianness(key, key_len);           
	swapEndianness(plaintext, BLOCK_SIZE); 
	

    
    
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_128_ECB_ENC; //00010 AES_OP_128_ECB_ENC
    unsigned long long start_on = 0xA;//01010 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC    
    //unsigned long long next_on = 0x12;//10010 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
			    	
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,interface);	
	
	//start
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);
	
	
	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);

	while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
    
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, interface);
		  
    	
	//swapEndianness(ciphertext, *ciphertext_len);
			    	
   control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
}


/////////////////////////////////////////////////////////////////////////////////////////////
// 128-DECRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////

void aes_block_128_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)


{
        
    //unsigned char key_len = KEY_BYTES;
    //swapEndianness(key, key_len);	
 	   
    //ciphertext_len = BLOCK_OR_IV_BYTES;
    //*plaintext_len = BLOCK_OR_IV_BYTES;
    //swapEndianness(ciphertext, ciphertext_len);
    
    
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////


    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_128_ECB_DEC; //AES_OP_128_ECB_DEC //00000		
    unsigned long long start_on = 0x8; //01000 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    //unsigned long long next_on = 0x10;//10000 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,interface);	

	
    //start
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);
	
	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);

	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	
    while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, interface);
	
	swapEndianness(plaintext, BLOCK_SIZE);
    	 control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);    
}

///// 256-ENCRYPT-CBC-BLOCK ////

void aes_block_256_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)

{
     
    
    //unsigned char key_len = KEY_BYTES;
     //plaintext_len = BLOCK_OR_IV_BYTES;	   
    //*ciphertext_len = BLOCK_OR_IV_BYTES;
    	
	//swapEndianness(key, key_len);           
	swapEndianness(plaintext, BLOCK_SIZE); 
	  
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_256_CBC_ENC; //00111
    unsigned long long start_on = 0xF;//01111 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC    
   // unsigned long long next_on = 0x17;//10111 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
   //reset the AES
   	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv,interface);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,interface);	

	    //start
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);
	
	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);	    
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);

    while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, interface);
	

    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);	
}

///// 256-DECRYPT-CBC-BLOCK ////

void aes_block_256_cbc_decrypt_hw(unsigned  char* key,  unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)


{
        
    //unsigned char key_len = KEY_BYTES;
    //swapEndianness(key, key_len);	
 	   
    //ciphertext_len = BLOCK_OR_IV_BYTES;
    //*plaintext_len = BLOCK_OR_IV_BYTES;
    //swapEndianness(ciphertext, ciphertext_len);
    
    
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////


    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_256_CBC_DEC; //AES_OP_128_ECB_DEC //00101		
    unsigned long long start_on = 0xD; //01101 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
   // unsigned long long next_on = 0x15;//10101 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
   //reset the AES
   	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv ,interface);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,interface);	

	    //start
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);

	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	
    while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, interface);
	
	swapEndianness(plaintext, BLOCK_SIZE);

    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
}



void aes_block_128_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)

{
     
    
    //unsigned char key_len = KEY_BYTES;
     //plaintext_len = BLOCK_OR_IV_BYTES;	   
    //*ciphertext_len = BLOCK_OR_IV_BYTES;
    	
	//swapEndianness(key, key_len);           
	swapEndianness(plaintext, BLOCK_SIZE); 
	  
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_128_CBC_ENC; //00011
    unsigned long long start_on = 0xB;//01011 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC    
    //unsigned long long next_on = 0x13;//10011 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
//reset the AES
   	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv,interface);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,interface);	

 //start
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);


	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);   
		    
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);

    while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, interface);
	

    	
 	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
}

///// 256-DECRYPT-CBC-BLOCK ////

void aes_block_128_cbc_decrypt_hw(unsigned  char* key,  unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, INTF interface)


{
        
    //unsigned char key_len = KEY_BYTES;
    //swapEndianness(key, key_len);	
 	   
    //ciphertext_len = BLOCK_OR_IV_BYTES;
    //*plaintext_len = BLOCK_OR_IV_BYTES;
    //swapEndianness(ciphertext, ciphertext_len);
    
    
    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////


    unsigned long long control;
    unsigned long long address;
    unsigned long long data_in;
    unsigned long long mode_operation = AES_OP_128_CBC_DEC; // //00001		
    unsigned long long start_on = 0x9; //01001 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
   // unsigned long long next_on = 0x11;//10001 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
   	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	//reset off

    	control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,interface);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv ,interface);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,interface);	

//start
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);

	//aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);

    while (result_valid != 1) aes_read(AES_ADDR_RESULT_VALID, AXI_BYTES / AXI_BYTES, &result_valid, interface);
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, interface);
	
	swapEndianness(plaintext, BLOCK_SIZE);

    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
}
