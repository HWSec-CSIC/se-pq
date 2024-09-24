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
    printf("\n Not supported yet in SE-QUBIP.");
}


void aes_256_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
    printf("\n Not supported yet in SE-QUBIP.");
}



// Function to encrypt a plaintext using AES-256 in ECB mode
void aes_128_ecb_encrypt_hw(unsigned char* key,	unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext, unsigned int plaintext_len,INTF interface)

{
    printf("\n Not supported yet in SE-QUBIP.");
}


void aes_128_ecb_decrypt_hw(unsigned char* key, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
   printf("\n Not supported yet in SE-QUBIP.");
}


// Function to encrypt a plaintext using AES-256 in CBC mode

void aes_256_cbc_encrypt_hw( unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext,  unsigned int plaintext_len, INTF interface) 

{
    printf("\n Not supported yet in SE-QUBIP.");
}


void aes_256_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
    printf("\n Not supported yet in SE-QUBIP.");
}

void aes_128_cbc_encrypt_hw( unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int* ciphertext_len, unsigned char* plaintext,  unsigned int plaintext_len, INTF interface) 

{
    printf("\n Not supported yet in SE-QUBIP.");
}




void aes_128_cbc_decrypt_hw(unsigned char* key, unsigned char* iv, unsigned char* ciphertext, unsigned int ciphertext_len, unsigned char* plaintext, unsigned int* plaintext_len, INTF interface)

{
    printf("\n Not supported yet in SE-QUBIP.");
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
    printf("\n Not supported yet in SE-QUBIP.");
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
    printf("\n Not supported yet in SE-QUBIP.");
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
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}  */
    
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &start_on,interface);
	    	        
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	nwc = 0;
	    while (result_valid != 1)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
		printf(" result_valid ...0x%8.8llX\n",result_valid);
		for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
		
    }
	nwc = 0;
}
	
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
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	
	    while (result_valid != 1)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
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
	
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	nwc = 0;
	    while (result_valid != 1)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
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
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);

	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	
	    while (result_valid != 1)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
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
	
	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);	    
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	nwc = 0;
	    while (result_valid != 1)
    	{
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
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

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	
	    while (result_valid != 1)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
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


	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);   
		    
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	nwc = 0;
	    while (result_valid != 1)
    	{
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
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

	aes_write(AES_ADDR_CTRL, AXI_BYTES/AXI_BYTES, &mode_operation,interface);
	aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
	
	    while (result_valid != 1)
    {
        aes_read(AES_ADDR_RESULT_VALID,AXI_BYTES/AXI_BYTES,&result_valid,interface);
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
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, interface);
	
	swapEndianness(plaintext, BLOCK_SIZE);

    	
    	control = (ADD_AES << 32) + AES_RST_ON + AES_INTF_RST;
    	write_INTF(interface, &control, CONTROL, AXI_BYTES);
}





