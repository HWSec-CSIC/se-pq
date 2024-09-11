////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 13/06/2024
// File Name: eddsa_hw.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		EdDSA HW Handler Functions
//
////////////////////////////////////////////////////////////////////////////////////

#include "aes_hw.h"

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


/////////////////////////////////////////////////////////////////////////////////////////////
// 256-ENCRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////
void aes_256_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned int* ciphertext_len, unsigned  char* plaintext, unsigned int plaintext_len, MMIO_WINDOW ms2xl)


{
     
    
    unsigned char key_len = KEY_BYTES;
     //plaintext_len = BLOCK_OR_IV_BYTES;	   
    //*ciphertext_len = BLOCK_OR_IV_BYTES;
    	
	swapEndianness(key, key_len);           
	//swapEndianness(plaintext, plaintext_len); 
	

    
    
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
	
	printf("\n plaintext: %s", plaintext);
		printf("\n");
	printf("plaintext_len = %i\n", plaintext_len);		
	 printf("plaintext (in bytes):\n");
    	for (int i = 0; i < plaintext_len; i++) {
        	printf(" %02x   ", plaintext[i]);
    	}     
    	printf("\n");
	printf("\n");
	//printf("\n key: %s", key);
	
	 printf("Key (in bytes):\n");
    	for (int i = 0; i < KEY_BYTES; i++) {
        	printf("%02x ", key[i]);
    	}
     
    	printf("\n");
    
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
	
	aes_read(AES_ADDR_RESULT, (*ciphertext_len)/AXI_BYTES, ciphertext, ms2xl);
	
	swapEndianness(ciphertext, *ciphertext_len);
	
		 printf("Result Valid (in bytes):\n");
 
        	printf("%02llx ", result_valid);
    
	printf("ciphertext_len = %i\n", *ciphertext_len);		
	 printf("Ciphertext (in bytes):\n");
    	for (int i = 0; i < *ciphertext_len; i++) {
        	printf(" %02x   ", ciphertext[i]);
    	}     
    	printf("\n");
}


/////////////////////////////////////////////////////////////////////////////////////////////
// 256-DECRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////

void aes_256_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned int ciphertext_len, unsigned  char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl)


{
     
    
    unsigned char key_len = KEY_BYTES;
    //swapEndianness(key, key_len);	
 	   
    //ciphertext_len = BLOCK_OR_IV_BYTES;
    //*plaintext_len = BLOCK_OR_IV_BYTES;
    swapEndianness(ciphertext, ciphertext_len);
    
    
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
	
		 printf("Key (in bytes):\n");
    	for (int i = 0; i < KEY_BYTES; i++) {
        	printf("%02x ", key[i]);
    	}
	
		 printf("Ciphertext (in bytes):\n");
    	for (int i = 0; i < ciphertext_len; i++) {
        	printf(" %02x   ", ciphertext[i]);
    	}     
    	printf("\n");
	
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
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, ms2xl);
	
	//swapEndianness(plaintext, *plaintext_len);
	printf("\n recovered_msg: %s", plaintext);
	printf("\n");
	 printf("Recovered Plaintext (in bytes):\n");
    	for (int i = 0; i < *plaintext_len; i++) {
        	printf(" %02x   ", plaintext[i]);
    	}     
    	printf("\n");
}



/////////////////////////////////////////////////////////////////////////////////////////////
// 128-ENCRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////
void aes_128_ecb_encrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned int* ciphertext_len, unsigned  char* plaintext, unsigned int plaintext_len, MMIO_WINDOW ms2xl)


{
     
    
    unsigned char key_len = KEY_BYTES;
    //swapEndianness(key, key_len);	
 	   
    *ciphertext_len = BLOCK_OR_IV_BYTES;
    //swapEndianness(*plaintext, *ciphertext_len);
    
    
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
	
	printf("\n plaintext: %s", plaintext);
		printf("\n");	
	 printf("plaintext (in bytes):\n");
    	for (int i = 0; i < 16; i++) {
        	printf(" %02x   ", plaintext[i]);
    	}     
    	printf("\n");
	printf("\n");
	//printf("\n key: %s", key);
	
	 printf("Key (in bytes):\n");
    	for (int i = 0; i < 32; i++) {
        	printf("%02x ", key[i]);
    	}
     
    	printf("\n");
    
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
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, ciphertext, ms2xl);
	
	 //swapEndianness(*ciphertext, *ciphertext_len);
	 
		 printf("Result Valid (in bytes):\n");
 
        	printf("%02llx ", result_valid);
    
	
	 printf("Ciphertext (in bytes):\n");
    	for (int i = 0; i < 16; i++) {
        	printf(" %02x   ", ciphertext[i]);
    	}     
    	printf("\n");
}


/////////////////////////////////////////////////////////////////////////////////////////////
// 128-DECRYPT-ECB
/////////////////////////////////////////////////////////////////////////////////////////////

void aes_128_ecb_decrypt_hw(unsigned  char* key, unsigned  char* ciphertext, unsigned int ciphertext_len, unsigned  char* plaintext, unsigned int* plaintext_len, MMIO_WINDOW ms2xl)


{
     
    
    unsigned char key_len = KEY_BYTES;
    swapEndianness(key, key_len);	
 	   
    ciphertext_len = BLOCK_OR_IV_BYTES;
    *plaintext_len = BLOCK_OR_IV_BYTES;
    //swapEndianness(&ciphertext, ciphertext_len);
    
    
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
	
	aes_read(AES_ADDR_RESULT, BLOCK_OR_IV_BYTES/AXI_BYTES, plaintext, ms2xl);
	
	//swapEndianness(*plaintext, *ciphertext_len);

}

