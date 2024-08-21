/****************************************************************************************/
/*
 *  IMSE.CNM_QUBIP_aes_256_axi_256: aes_axi.h 
 *
 *  Created on: 19/06/2024
 *      Author: apurba@imse-cnm.csic.es
 */
/****************************************************************************************/
#include <time.h>
#include "aes_axi.h"

	void convert_char_to_long(const unsigned char *charKey, unsigned long *longKey, size_t length) {
    for (size_t i = 0; i < length / 4; i++) {
        longKey[i] = ((unsigned long)charKey[i * 4] << 24) |
                     ((unsigned long)charKey[i * 4 + 1] << 16) |
                     ((unsigned long)charKey[i * 4 + 2] << 8) |
                     (unsigned long)charKey[i * 4 + 3];
    }
}

void ulong_array_to_uchar_array(unsigned long* ulong_array, size_t ulong_array_len, unsigned char* uchar_array, size_t uchar_array_len) {
    size_t ulong_size = sizeof(unsigned long);

    // Ensure the uchar_array has enough space to hold all the bytes
    if (uchar_array_len < ulong_array_len * ulong_size) {
        fprintf(stderr, "Unsigned char array size is too small to hold the unsigned long array values\n");
        return;
    }

    for (size_t i = 0; i < ulong_array_len; i++) {
        for (size_t j = 0; j < ulong_size; j++) {
            uchar_array[i * ulong_size + j] = (ulong_array[i] >> (j * 8)) & 0xFF;
        }
    }
}

	void AES_256_ECB_ENCRYPT(unsigned  char* key, unsigned  char* ciphertext, unsigned int* ciphertext_len, unsigned  char* plaintext, unsigned int* plaintext_len){
	
    unsigned int No_of_ciphertext_reg;
    unsigned int No_of_plaintext_reg;
    
    unsigned int ciphertext_len_value = *ciphertext_len;
    unsigned int plaintext_len_value = *plaintext_len;
    
    No_of_ciphertext_reg = ciphertext_len_value/32;
    No_of_plaintext_reg = plaintext_len_value/32;
    
    size_t length_key = 32;
    size_t length = 16;
    unsigned long keylong[8];
    
    unsigned long plaintextlong[4];
    
    
    unsigned long ciphertextlong[4];
    
    size_t ulong_array_len = 4;
    size_t uchar_array_len = 16;
    //unsigned char ciphertext_char[16];
    
    

    convert_char_to_long(plaintext, plaintextlong, length);
    convert_char_to_long(key, keylong, length_key);
    
    /*
  
        printf("	Plaintext:\n");
        	for (int i = 0; i< 4; i++) {
		printf("	0x%8.8lX\n",
		      plaintextlong[i]);
	}
    
    
    //convertKey(ciphertext, ciphertextlong, length);
    
    
    unsigned long doneValue = 0;
    unsigned long controlWord = AES_CONTROL;
    unsigned long init = AES_INIT;
    unsigned long init_zero = 0;
    unsigned long next = AES_NEXT;
    unsigned long next_zero = 0;
    */
    	
    unsigned long ready = 0;
    unsigned long doneValue = 0;
    unsigned long controlWord = AES_CONTROL;
    unsigned long init = AES_INIT;
    unsigned long init_zero = 0;
    unsigned long next = AES_NEXT;
    unsigned long next_zero = 0;
    //unsigned long doneValue = 0;
	int nwc = 0;
   
    createMMIOWindow(&aesWindow,AESIP_BASEADDRESS,AESIP_REGISTER_SPACE_LEN*64/8);


///reset_n, encdec & keylen   
    writeMMIO(&aesWindow, &controlWord ,sizeof(unsigned long)*0,sizeof(unsigned long)*1);   
    
    writeMMIO(&aesWindow,keylong,sizeof(unsigned long)*3,sizeof(unsigned long)*8);
    writeMMIO(&aesWindow,plaintextlong,sizeof(unsigned long)*11,sizeof(unsigned long)*(No_of_plaintext_reg)); // plaintext_len/32 = 128/32 = 4 ; (so number of registers is 4)
    
    writeMMIO(&aesWindow, &next_zero ,sizeof(unsigned long)*2,sizeof(unsigned long)*1);
    //init
    writeMMIO(&aesWindow, &init ,sizeof(unsigned long)*1,sizeof(unsigned long)*1);

     for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
   writeMMIO(&aesWindow, &init_zero ,sizeof(unsigned long)*1,sizeof(unsigned long)*1);		

   
    //key & message

    
    
    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
    
    //if ready = 1, then start next
    
    readMMIO(&aesWindow,&ready,sizeof(unsigned long)*19,sizeof(unsigned long)*1);
    
    writeMMIO(&aesWindow, &next ,sizeof(unsigned long)*2,sizeof(unsigned long)*1);
    

	
	    for (int t = 0; t < 1000000; t++) {
		
		nwc++;
		if (nwc == 10000) {
			//printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
	}
//	sleep (1);
   writeMMIO(&aesWindow, &next_zero ,sizeof(unsigned long)*2,sizeof(unsigned long)*1);
    

    readMMIO(&aesWindow,&doneValue,sizeof(unsigned long)*23,sizeof(unsigned long)*1);
    
    while (doneValue != 1)
    {
        readMMIO(&aesWindow,&doneValue,sizeof(unsigned long)*23,sizeof(unsigned long)*1);
		printf(" donevalue ...0x%8.8lX\n",doneValue);
		for (int t = 0; t < 1000000; t++) {
		}
		nwc++;
		if (nwc == 10000) {
			printf(" Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
    }
    
    readMMIO(&aesWindow,ciphertextlong,sizeof(unsigned long)*19,sizeof(unsigned long)*(No_of_ciphertext_reg)); // ciphertext_len/32 = 128/32 = 4 ; (so number of registers is 4)
    //convertKey(ciphertext, ciphertextlong, length);
    
	
    
    	printf("\n	KEY:\n");
    	for (int i = 0; i< 8; i++) {
		printf("	0x%8.8lX\n",
		      keylong[i]);
	}
	    
	
	printf("\n	Plaintext	Ciphertext:\n");
	for (int i = 0; i< 4; i++) {
		printf("	0x%8.8lX	0x%8.8lX\n",
		      plaintextlong[i],ciphertextlong[i]);
	}
    
    ulong_array_to_uchar_array(ciphertextlong, ulong_array_len, ciphertext, uchar_array_len);
    
    //ciphertext = ciphertext_char;
       
    writeMMIO(&aesWindow, &controlWord ,sizeof(unsigned long)*1,sizeof(unsigned long)*1);
    
    doneValue = 0;

    //return 0;

}
