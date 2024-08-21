/*******************************************************************************************/
/*
 *  IMSE.CNM_QUBIP_aes_256_axi_256: aes_axi.h 
 *
 *  Created on: 19/06/2024
 *      Author: apurba@imse-cnm.csic.es
 */
/****************************************************************************************/

#include "aes_axi.h"
#include <time.h>

#define msg_in3 0x2a
#define msg_in2 0x17
#define msg_in1 0x93
#define msg_in0 0x73

#define msg_in7 0x11
#define msg_in6 0x7e
#define msg_in5 0x3d
#define msg_in4 0xe9

#define msg_in11 0x96
#define msg_in10 0x9f
#define msg_in9 0x40 
#define msg_in8 0x2e


#define msg_in15 0xe2
#define msg_in14 0xbe
#define msg_in13 0xc1
#define msg_in12 0x6b  
  

/*
#define msg_in0  0x7393172aU
#define msg_in1  0xe93d7e11U
#define msg_in2  0x2e409f96U
#define msg_in3  0x6bc1bee2U




#define key_0  0x00000000U
#define key_1  0x00000000U
#define key_2  0x00000000U
#define key_3  0x00000000U
#define key_4  0x09cf4f3cU
#define key_5  0xabf71588U
#define key_6  0x28aed2a6U
#define key_7  0x2b7e1516U

*/

#define key_3 0x00
#define key_2 0x00
#define key_1 0x00
#define key_0 0x00

#define key_7 0x00
#define key_6 0x00
#define key_5 0x00
#define key_4 0x00

#define key_11 0x00
#define key_10 0x00
#define key_9 0x00
#define key_8 0x00

#define key_15 0x00
#define key_14 0x00
#define key_13 0x00
#define key_12 0x00



#define key_19 0x3C
#define key_18 0x4F
#define key_17 0xCF
#define key_16 0x09  

#define key_23 0x88
#define key_22 0x15
#define key_21 0xF7
#define key_20 0xAB  


#define key_27 0xA6
#define key_26 0xD2
#define key_25 0xAE
#define key_24 0x28

#define key_31 0x16
#define key_30 0x15
#define key_29 0x7E
#define key_28 0x2B  
  





int main() 


{

 	 clock_t t; 
	    double time_taken;
	FILE *bptr;
	char* bitstream_file = "./bit/SPIRS_RoT.bit";
	int Status;
	unsigned int ciphertext_len = 128 ;
	unsigned int plaintext_len = 128 ;
	
	//unsigned char ciphertext[16] = {0,0,0,0};
	
	unsigned char ciphertext[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	//unsigned char Key [32] = 0 ;
	
	unsigned char Key[32]        	=   {   key_0,  key_1,  key_2,  key_3,  key_4,  key_5,  key_6,  key_7, key_8,  key_9,  key_10,  key_11,  key_12,  key_13,  key_14,  key_15, key_16,  key_17,  key_18,  key_19,  key_20,  key_21,  key_22,  key_23, key_24,  key_25,  key_26,  key_27,  key_28,  key_29,  key_30,  key_31};
	
	//unsigned char Key[32]        	=   {	key_31, key_30, key_29, key_28, key_27, key_26, key_25, key_24, key_23, key_22, key_21, key_20, key_19, key_18, key_17, key_16, key_15, key_14, key_13, key_12, key_11, key_10, key_9, key_8, key_7, key_6, key_5, key_4, key_3, key_2, key_1, key_0};

										   
	unsigned char aesDataIn[16]	=   {	msg_in0,  msg_in1,  msg_in2,  msg_in3, msg_in4,  msg_in5,  msg_in6,  msg_in7, msg_in8,  msg_in9,  msg_in10,  msg_in11, msg_in12,  msg_in13,  msg_in14,  msg_in15};
	
	//unsigned char aesDataIn[16] = {	msg_in15, msg_in14, msg_in13, msg_in12, msg_in11, msg_in10, msg_in9, msg_in8, msg_in7, msg_in6, msg_in5, msg_in4, msg_in3, msg_in2, msg_in1, msg_in0};
	
								   
   // unsigned long *aesDataOut;
    
	printf("\n AES test ...\n");
	
	
	 #if defined (PYNQZ2)
  	if ((bptr = fopen(bitstream_file, "r"))) {
		fclose(bptr);
	} else {
		printf("\n   Bitstream doesn't exist. Bye ...\n\n");
		exit(ERROR);
	}

    printf("\n   Loading Bitstream ...");
			
	Status = PYNQ_loadBitstream(bitstream_file);
	if (Status != SUCCESS) {
		printf("LoadBitstream Failure\n");
		return ERROR;
	}
	
    printf(" done \n");
     #endif
    

  t = clock(); 
	
	AES_128_ECB_ENCRYPT(Key, ciphertext, &ciphertext_len, aesDataIn, &plaintext_len);

   t = clock() - t; 
     time_taken = ((double)t)/CLOCKS_PER_SEC; // in seconds 
      
         printf("AES took %f seconds to execute \n", time_taken); 

/*
	printf("      KEY:\n");
	for (int i = 0; i< 32; i++) {
		printf("    %02x\n",
		      Key[i]);
	}
	
	
	printf("     INPUT       OUTPUT\n");
	for (int i = 0; i< 16; i++) {
		printf("    %02x       %02x\n",
		      aesDataIn[i], ciphertext[i]);
	}
*/
    return 0;
}




