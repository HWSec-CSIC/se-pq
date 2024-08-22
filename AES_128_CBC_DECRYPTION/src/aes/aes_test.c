/*****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_rsa_1024_axi_1.0: rsa_test.c 
 *
 *  Created on: 30/12/2022
 *      Author: apurba@imse-cnm.csic.es
 */
/****************************************************************************************/

#include "aes_axi.h"
#include <time.h>


#define msg0_in3 0x7d
#define msg0_in2 0x19
#define msg0_in1 0xe9
#define msg0_in0 0x12

#define msg0_in7 0x9b
#define msg0_in6 0x8e
#define msg0_in5 0xe9
#define msg0_in4 0xce

#define msg0_in11 0x46
#define msg0_in10 0xb2
#define msg0_in9 0x19 
#define msg0_in8 0x81

#define msg0_in15 0xac
#define msg0_in14 0xab
#define msg0_in13 0x49
#define msg0_in12 0x76


#define msg1_in3  0xb2
#define msg1_in2  0x78
#define msg1_in1  0x76
#define msg1_in0  0x91

#define msg1_in7  0x3a
#define msg1_in6  0x11
#define msg1_in5  0xdb
#define msg1_in4  0x95

#define msg1_in11  0xee
#define msg1_in10  0x19
#define msg1_in9 0x72
#define msg1_in8 0x50

#define msg1_in15 0x9b
#define msg1_in14 0xcb
#define msg1_in13 0x86
#define msg1_in12 0x50



#define msg2_in3  0x16
#define msg2_in2  0x95
#define msg2_in1  0x22
#define msg2_in0  0x22

#define msg2_in7  0x9e
#define msg2_in6  0xe6
#define msg2_in5  0x16
#define msg2_in4  0x71

#define msg2_in11  0x3b
#define msg2_in10  0x74
#define msg2_in9 0xc1
#define msg2_in8 0xe3

#define msg2_in15 0xb8
#define msg2_in14 0xd6
#define msg2_in13 0xbe
#define msg2_in12 0x73
 

#define msg3_in3  0xa7
#define msg3_in2  0xe1
#define msg3_in1  0x86
#define msg3_in0  0x75

#define msg3_in7  0x30
#define msg3_in6  0xca
#define msg3_in5  0x0e
#define msg3_in4  0x12

#define msg3_in11 0x09
#define msg3_in10  0xac
#define msg3_in9 0x1f
#define msg3_in8 0x68

#define msg3_in15 0xa1
#define msg3_in14 0xca
#define msg3_in13 0xf1
#define msg3_in12 0x3f




//iv_vector[4] ={0x0c0d0e0f,0x08090a0b, 0x04050607, 0x00010203 };



#define iv3 0x0f
#define iv2 0x0e
#define iv1 0x0d
#define iv0 0x0c

#define iv7 0x0b
#define iv6 0x0a
#define iv5 0x09
#define iv4 0x08

#define iv11 0x07
#define iv10 0x06
#define iv9 0x05
#define iv8 0x04

#define iv15 0x03
#define iv14 0x02
#define iv13 0x01
#define iv12 0x00



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

 	FILE *bptr;
	char* bitstream_file = "./bit/SPIRS_RoT.bit";
	int Status;
	unsigned char ciphertext0[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	unsigned char ciphertext1[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	unsigned char ciphertext2[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	unsigned char ciphertext3[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	
	
	
		unsigned int ciphertext_len = 128 ;
	unsigned int plaintext_len = 128 ;
	unsigned char Key[32]        	=   {   key_0,  key_1,  key_2,  key_3,  key_4,  key_5,  key_6,  key_7, key_8,  key_9,  key_10,  key_11,  key_12,  key_13,  key_14,  key_15, key_16,  key_17,  key_18,  key_19,  key_20,  key_21,  key_22,  key_23, key_24,  key_25,  key_26,  key_27,  key_28,  key_29,  key_30,  key_31};
		//unsigned char iv_vector[4] ={0x0c0d0e0f,0x08090a0b, 0x04050607, 0x00010203 };	
	
	unsigned char iv_vector[16] = {iv0,iv1,iv2,iv3,iv4,iv5,iv6,iv7,iv8,iv9,iv10,iv11,iv12,iv13,iv14,iv15};

	
	unsigned char aesDataIn0[16] = {
    msg0_in0,  msg0_in1,  msg0_in2,  msg0_in3,
    msg0_in4,  msg0_in5,  msg0_in6,  msg0_in7,
    msg0_in8,  msg0_in9,  msg0_in10, msg0_in11,
    msg0_in12, msg0_in13, msg0_in14, msg0_in15
};
	
	

	unsigned char aesDataIn1[16] = {
    msg1_in0,  msg1_in1,  msg1_in2,  msg1_in3,
    msg1_in4,  msg1_in5,  msg1_in6,  msg1_in7,
    msg1_in8,  msg1_in9,  msg1_in10, msg1_in11,
    msg1_in12, msg1_in13, msg1_in14, msg1_in15
};
	

	unsigned char aesDataIn2[16] = {
    msg2_in0,  msg2_in1,  msg2_in2,  msg2_in3,
    msg2_in4,  msg2_in5,  msg2_in6,  msg2_in7,
    msg2_in8,  msg2_in9,  msg2_in10, msg2_in11,
    msg2_in12, msg2_in13, msg2_in14, msg2_in15
};
	
	
	unsigned char aesDataIn3[16] = {
    msg3_in0,  msg3_in1,  msg3_in2,  msg3_in3,
    msg3_in4,  msg3_in5,  msg3_in6,  msg3_in7,
    msg3_in8,  msg3_in9,  msg3_in10, msg3_in11,
    msg3_in12, msg3_in13, msg3_in14, msg3_in15
};

			

						   

	printf("\n AES CBC test ...\n");
	
	
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

    	AES_128_CBC_DECRYPT(Key,iv_vector,ciphertext0, &ciphertext_len,aesDataIn0 , &plaintext_len);  	
	
	    	printf("\n	Ciphertext0:\n");
    	for (int i = 0; i< 16; i++) {
		printf("	0x%02x",
		      ciphertext0[i]);
	}
	/* unsigned char out0_in1[16] = {ciphertext0[3],ciphertext0[2],ciphertext0[1],ciphertext0[0],
	ciphertext0[7],ciphertext0[6],ciphertext0[5],ciphertext0[4],
	ciphertext0[11],ciphertext0[10],ciphertext0[9],ciphertext0[8],
	ciphertext0[15],ciphertext0[14],ciphertext0[13],ciphertext0[12]};
	*/
    	AES_128_CBC_DECRYPT(Key,aesDataIn0,ciphertext1, &ciphertext_len,aesDataIn1 , &plaintext_len);  	    	
    		
    			    	printf("\n	Ciphertext1:\n");
    	for (int i = 0; i< 16; i++) {
		printf("	0x%02x",
		      ciphertext1[i]);
	}
    	/*	unsigned char out1_in2[16] = {
    	ciphertext1[3], ciphertext1[2], ciphertext1[1], ciphertext1[0],
    	ciphertext1[7], ciphertext1[6], ciphertext1[5], ciphertext1[4],
    	ciphertext1[11], ciphertext1[10], ciphertext1[9], ciphertext1[8],
    	ciphertext1[15], ciphertext1[14], ciphertext1[13], ciphertext1[12]
	}; */

	AES_128_CBC_DECRYPT(Key,aesDataIn1,ciphertext2, &ciphertext_len,aesDataIn2 , &plaintext_len);
	
	    			    	printf("\n	Ciphertext2:\n");
    	for (int i = 0; i< 16; i++) {
		printf("	0x%02x",
		      ciphertext2[i]);
	}
	
	/*unsigned char out2_in3[16] = {
    	ciphertext2[3], ciphertext2[2], ciphertext2[1], ciphertext2[0],
    	ciphertext2[7], ciphertext2[6], ciphertext2[5], ciphertext2[4],
    	ciphertext2[11], ciphertext2[10], ciphertext2[9], ciphertext2[8],
    	ciphertext2[15], ciphertext2[14], ciphertext2[13], ciphertext2[12]
	};*/
    	
	AES_128_CBC_DECRYPT(Key,aesDataIn2,ciphertext3, &ciphertext_len,aesDataIn3 , &plaintext_len);
	    			    	printf("\n	Ciphertext3:\n");
    	for (int i = 0; i< 16; i++) {
		printf("	0x%02x",
		      ciphertext3[i]);
	}
/*	
		    for (int i = 0; i < 4; i++) {
        if (ciphertext1[i] != aesDataOut1[i]) {
            printf("Error\n");
           // return;
        		}
    		}
    	printf("Test Passed\n");
	
	
	
	aesDataOut2 = AES_CIPHER(aesDataIn2, Key,aesDataOut1);
	

	
	printf("     INPUT       OUTPUT\n");
	for (int i = 0; i< 4; i++) {
		printf("    0x%8.8lX    0x%8.8lX\n",
		      aesDataIn2[i], aesDataOut2[i]);
	}
		    for (int i = 0; i < 4; i++) {
        if (ciphertext2[i] != aesDataOut2[i]) {
            printf("Error\n");
        		}
    		}
    	printf("Test Passed\n");
	
	
	
	aesDataOut_final = AES_CIPHER(aesDataIn3, Key,aesDataOut2);
		
	
	printf("     INPUT       OUTPUT\n");
	for (int i = 0; i< 4; i++) {
		printf("    0x%8.8lX    0x%8.8lX\n",
		      aesDataIn3[i], aesDataOut_final[i]);
	}
	
		    for (int i = 0; i < 4; i++) {
        if (ciphertext3[i] != aesDataOut_final[i]) {
            printf("Error\n");        
        		}
    		}
    	printf("Test Passed\n");
*/	
	
	
    return 0;
}




