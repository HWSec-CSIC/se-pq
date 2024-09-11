////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Apurba Karmakar
//
// Create Date: 11/09/2024
// File Name: aes_hw.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		AES HW Handler Functions
//
////////////////////////////////////////////////////////////////////////////////////

#include "aes_hw.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/aes.h>  // Include OpenSSL's AES header

#define BLOCK_SIZE 16  // AES block size in bytes (128 bits)

void aes_write(unsigned long long address, unsigned long long size,  void *data, MMIO_WINDOW ms2xl)
{
    unsigned long long addr = address;
    unsigned long long control = (ADD_AES << 32) + AES_LOAD + AES_RST_OFF;
    
    writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
    writeMMIO(&ms2xl, data, DATA_IN, AXI_BYTES);
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    for (int i = 1; i < size; i++)
    {
        addr = address + i;
        writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
        writeMMIO(&ms2xl, data + AXI_BYTES * i, DATA_IN, AXI_BYTES);
    }
    
    control = (ADD_AES << 32) + AES_RST_OFF;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void aes_read(unsigned long long address, unsigned long long size, void *data, MMIO_WINDOW ms2xl)
{
    unsigned long long control = (ADD_AES << 32) + AES_READ + AES_RST_OFF;
    unsigned long long addr;

    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    for (int i = 0; i < size; i++)
    {
        addr = address + i;
        writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
        readMMIO(&ms2xl, data + AXI_BYTES * i, DATA_OUT, AXI_BYTES);
    }
    
    control = (ADD_AES << 32) + AES_RST_OFF;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}



// Function to encrypt a plaintext using AES-256 in ECB mode
void aes_256_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,MMIO_WINDOW ms2xl)

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
        aes_block_256_ecb_encrypt_hw(key, ciphertext_block,plaintext_block, ms2xl);

        // Copy the encrypted block to the ciphertext output
        memcpy(&ciphertext[i * BLOCK_SIZE], ciphertext_block, BLOCK_SIZE);
    }

    // Set the length of the ciphertext
    *ciphertext_len = num_blocks * BLOCK_SIZE;
   // printf("Ciphertext length: %u bytes\n", *ciphertext_len);
}


void aes_256_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl)

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
        aes_block_256_ecb_decrypt_hw(key, ciphertext_block, plaintext_block, ms2xl);
	
        // Copy the decrypted block to the plaintext output
        memcpy(&plaintext[i * BLOCK_SIZE], plaintext_block, BLOCK_SIZE);
    }

    // Set the length of the plaintext (if necessary)
    *plaintext_len = num_blocks * BLOCK_SIZE;
}



// Function to encrypt a plaintext using AES-256 in ECB mode
void aes_128_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,MMIO_WINDOW ms2xl)

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
        aes_block_128_ecb_encrypt_hw(key, ciphertext_block,plaintext_block, ms2xl);

        // Copy the encrypted block to the ciphertext output
        memcpy(&ciphertext[i * BLOCK_SIZE], ciphertext_block, BLOCK_SIZE);
    }

    // Set the length of the ciphertext
    *ciphertext_len = num_blocks * BLOCK_SIZE;
  //  printf("Ciphertext length: %u bytes\n", *ciphertext_len);
}


void aes_128_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl)

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
        aes_block_128_ecb_decrypt_hw(key, ciphertext_block, plaintext_block, ms2xl);
	
        // Copy the decrypted block to the plaintext output
        memcpy(&plaintext[i * BLOCK_SIZE], plaintext_block, BLOCK_SIZE);
    }

    // Set the length of the plaintext (if necessary)
    *plaintext_len = num_blocks * BLOCK_SIZE;
}


// Function to encrypt a plaintext using AES-256 in CBC mode

void aes_256_cbc_encrypt_hw( unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext,  unsigned int plaintext_len, MMIO_WINDOW ms2xl) 

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
        aes_block_256_cbc_encrypt_hw(key, previous_block, ciphertext_block, plaintext_block, ms2xl);

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


void aes_256_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl)

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
        aes_block_256_cbc_decrypt_hw(key, previous_block, ciphertext_block, decrypted_block, ms2xl);

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

void aes_128_cbc_encrypt_hw( unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext,  unsigned int plaintext_len, MMIO_WINDOW ms2xl) 

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
        aes_block_128_cbc_encrypt_hw(key, previous_block, ciphertext_block, plaintext_block, ms2xl);

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


void aes_128_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl)

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
        aes_block_128_cbc_decrypt_hw(key, previous_block, ciphertext_block, decrypted_block, ms2xl);

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


/////////////////////////////////////////////////////////////////////////////////////////////
// 256-ENCRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////
void aes_block_256_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)


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
    unsigned long long mode_operation = AES_OP_256_ECB_ENC; //00110
    unsigned long long init_on = 0xE;//01110 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC    
    unsigned long long next_on = 0x16;//10110 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,ms2xl);	
	
    
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	  for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
		   
		    
	/*	  
		    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		nwc = 0;
	}*/
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	nwc = 0;
	    while (result_valid != 3)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    }
	nwc = 0;
}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, ms2xl);
	
	//swapEndianness(ciphertext, *ciphertext_len);
	    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}


/////////////////////////////////////////////////////////////////////////////////////////////
// 256-DECRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////

void aes_block_256_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)


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
    unsigned long long mode_operation = AES_OP_256_ECB_DEC;
    unsigned long long init_on = 0xC; //01100 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long next_on = 0x14;//10100 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,ms2xl);	

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
		/* printf("Key (in bytes):\n");
    	for (int i = 0; i < KEY_BYTES; i++) {
        	printf("%02x ", key[i]);
    	}
	
		 printf("Ciphertext (in bytes):\n");
    	for (int i = 0; i < BLOCK_SIZE; i++) {
        	printf(" %02x   ", ciphertext[i]);
    	}     
    	printf("\n"); */
	
 	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		nwc = 0;
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	
	    while (result_valid != 3)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    }
	nwc = 0;
}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, ms2xl);
	
	swapEndianness(plaintext, BLOCK_SIZE);
    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}




/////////////////////////////////////////////////////////////////////////////////////////////
// 128-ENCRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////
void aes_block_128_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)


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
    unsigned long long init_on = 0xA;//01010 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC    
    unsigned long long next_on = 0x12;//10010 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,ms2xl);	
	    
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	  for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
		   
		    
	/*	  
		    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		nwc = 0;
	}*/
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	nwc = 0;
	    while (result_valid != 3)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    }
	nwc = 0;
}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, ms2xl);
	
	//swapEndianness(ciphertext, *ciphertext_len);
			    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
     	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}


/////////////////////////////////////////////////////////////////////////////////////////////
// 128-DECRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////

void aes_block_128_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)


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
    unsigned long long init_on = 0x8; //01000 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long next_on = 0x10;//10000 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,ms2xl);	

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
		/* printf("Key (in bytes):\n");
    	for (int i = 0; i < KEY_BYTES; i++) {
        	printf("%02x ", key[i]);
    	}
	
		 printf("Ciphertext (in bytes):\n");
    	for (int i = 0; i < BLOCK_SIZE; i++) {
        	printf(" %02x   ", ciphertext[i]);
    	}     
    	printf("\n"); */
	
 	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		nwc = 0;
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	
	    while (result_valid != 3)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    }
	nwc = 0;
}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, ms2xl);
	
	swapEndianness(plaintext, BLOCK_SIZE);
    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

///// 256-ENCRYPT-CBC-BLOCK ////

void aes_block_256_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)

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
    unsigned long long init_on = 0xF;//01111 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC    
    unsigned long long next_on = 0x17;//10111 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,ms2xl);	

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	  for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
		   
		    
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	nwc = 0;
	    while (result_valid != 3)
    	{
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    	}
	nwc = 0;
	}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, ms2xl);
	

    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

///// 256-DECRYPT-CBC-BLOCK ////

void aes_block_256_cbc_decrypt_hw(unsigned  char* key,  unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)


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
    unsigned long long init_on = 0xD; //01101 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long next_on = 0x15;//10101 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv ,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,ms2xl);	

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
	
 	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		nwc = 0;
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	
	    while (result_valid != 3)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    }
	nwc = 0;
}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, ms2xl);
	
	swapEndianness(plaintext, BLOCK_SIZE);

    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}



void aes_block_128_cbc_encrypt_hw(unsigned  char* key, unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)

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
    unsigned long long init_on = 0xB;//01011 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC    
    unsigned long long next_on = 0x13;//10011 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext,ms2xl);	

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	  for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
		   
		    
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	nwc = 0;
	    while (result_valid != 3)
    	{
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    	}
	nwc = 0;
	}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, ms2xl);
	

    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

///// 256-DECRYPT-CBC-BLOCK ////

void aes_block_128_cbc_decrypt_hw(unsigned  char* key,  unsigned  char* iv, unsigned  char* ciphertext, unsigned  char* plaintext, MMIO_WINDOW ms2xl)


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
    unsigned long long init_on = 0x9; //01001 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long next_on = 0x11;//10001 NEXT,INIT,KEYLEN,ENC_DEC,ECB_CBC
    unsigned long long result_valid;	
    
    int nwc = 0;
	//reset the AES
    control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	//reset off
    control = (ADD_AES << 32) + AES_RST_OFF + AES_INTF_OPER;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
    //write control(mode of operation, key, block,iv) 
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_write(AES_ADDR_KEY, KEY_BYTES/AXI_BYTES, key,ms2xl);
	aes_write(AES_ADDR_IV, BLOCK_OR_IV_BYTES/AXI_BYTES, iv ,ms2xl);
	aes_write(AES_ADDR_BLOCK, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext,ms2xl);	

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &init_on,ms2xl);
	
	
 	for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
	}
	nwc = 0;
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &next_on,ms2xl);
		
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		nwc = 0;
	}
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,ms2xl);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
	
	    while (result_valid != 3)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,ms2xl);
		//printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    }
	nwc = 0;
}
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, ms2xl);
	
	swapEndianness(plaintext, BLOCK_SIZE);

    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}





