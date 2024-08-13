/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_rsa_3.0: rsa_test.c 
 *
 *  Created on: 16/02/2023
 *      Author: apurba@imse-cnm.csic.es
 */
/****************************************************************************************/

#include "rsa_axi.h"
#include <time.h>

#define NIST_HEADER_BYTE_COUNT_KEY_E_D 106
#define NIST_HEADER_BYTE_COUNT_KEY_N 631
#define NIST_HEADER_BYTE_COUNT_MESSAGEIN 1159
#define NIST_HEADER_BYTE_COUNT_EXPDATAOUT 1310

#define HEADER_BYTE_COUNT_KEY_E_D 1867  
#define HEADER_BYTE_COUNT_KEY_N  1896
#define HEADER_BYTE_COUNT_MESSAGEIN 2424
#define HEADER_BYTE_COUNT_EXPDATAOUT 2959 

#define HEADER_BYTE_COUNT_KEY_E_D_1 HEADER_BYTE_COUNT_KEY_E_D + i*3021 
#define HEADER_BYTE_COUNT_KEY_N_1 HEADER_BYTE_COUNT_KEY_N + i*3021 
#define HEADER_BYTE_COUNT_MESSAGEIN_1 HEADER_BYTE_COUNT_MESSAGEIN + i*3021 
#define HEADER_BYTE_COUNT_EXPDATAOUT_1 HEADER_BYTE_COUNT_EXPDATAOUT + i*3021

#define NIST_HEADER_BYTE_COUNT_KEY_E_D_1 NIST_HEADER_BYTE_COUNT_KEY_E_D + i*3021 
#define NIST_HEADER_BYTE_COUNT_KEY_N_1 NIST_HEADER_BYTE_COUNT_KEY_N + i*3021 
#define NIST_HEADER_BYTE_COUNT_MESSAGEIN_1 NIST_HEADER_BYTE_COUNT_MESSAGEIN + i*3021 
#define NIST_HEADER_BYTE_COUNT_EXPDATAOUT_1 NIST_HEADER_BYTE_COUNT_EXPDATAOUT + i*3021 

#if defined(AXI64)
  #define DATA_WIDTH 16
#elif defined(AXI32)
  #define DATA_WIDTH 8
#endif

int main(int argc, char** argv) {
	    
    int arg;
    int DBG = 0;
    int err = 0;
    int count = 2;  //Number of dataset
	char dataWord[DATA_WIDTH+1] = {" "};
    unsigned long long tic = 0;
    bool interactive = false;

#if defined(AXI64)
    unsigned long long Key_e_d[nrg]={0};
    unsigned long long Key_n[nrg]={0};
    unsigned long long rsaDataIn[nrg]={0};
    unsigned long long expDataOut[nrg]={0};
    unsigned long long *rsaDataOut;
#else
    unsigned int Key_e_d[nrg]={0};
    unsigned int Key_n[nrg]={0};
    unsigned int rsaDataIn[nrg]={0};
    unsigned int expDataOut[nrg]={0};
    unsigned int *rsaDataOut;
#endif

	for(arg=1; arg < argc; arg++) {
		if(argv[arg][0] == '-') {
			if(argv[arg][1] == 'h') {
				printf("\n  Usage: ./rsa_test [ -h | [-i] [-d <dbg_level>] [-n <n_tests>] \n\n");
				return SUCCESS;   
			} else if(argv[arg][1] == 'i') { 
				interactive = true;
			} else if(argv[arg][1] == 'd') { 
				if(arg<argc-1) {
					DBG = atoi(argv[arg+1]);
					if (DBG>0) interactive = true;
				}
			} else if(argv[arg][1] == 'n') { 
				if(arg<argc-1) {
					count = atoi(argv[arg+1]);
					if (count>6) count = 6;
					DBG = 1;
				}
			} else {
				printf("\n unknow option: %s\n\n", argv[arg]);
				return ERROR;
			}
		}
	}

 	printf("\n  RSA_1024 test ...\n");

 #if defined(PYNQZ2)

  	int Status;
 	FILE *bptr;
	char* bitstream_file = "./bit/SPIRS_RoT.bit";	

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
  
    printf("\n   Running  RSA_SIGN\n\n");

	
    // FILE *rsa1024Tests = fopen("./src/rsa/data/RSA1024.rsp","r");
    // FILE *rsa1024TestsLog = fopen("./out/rsa/RSA1024OUT.txt","wa");

    FILE *rsa1024Tests = fopen("./src/rsa/data/RSA2048.rsp","r");
    FILE *rsa1024TestsLog = fopen("./out/rsa/RSA2048OUT.txt","wa");

    time_t currentTime;
    currentTime = time(NULL);
    struct tm *dateTime = localtime(&currentTime);
    fprintf(rsa1024TestsLog,"This file was generated the day %d/%d/%d at %d:%02d:%02d\n\r", dateTime->tm_mday,1 + dateTime->tm_mon,1990 + dateTime->tm_year,1 + dateTime->tm_hour,dateTime->tm_min,dateTime->tm_sec);

    for (int i = 0; i < count; i++){
		
		printf("   Test Vector (Signature Generation)   %3d:   ",i+1);
		fprintf(rsa1024TestsLog,"  Test Vector (Signature Generation)   3%d: \n\n",i+1);
	
		if (DBG > 0) printf ("\n");
		
		//========JUMP THE NIST TESTS HEADER==========================
		fseek(rsa1024Tests,NIST_HEADER_BYTE_COUNT_KEY_E_D_1,SEEK_SET);
		{
			//========GETTING THE KEY_E_D VALUE===================================
	
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = 0; i <nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				Key_e_d[i]= strtoull(dataWord,NULL,16);			
			}
		}   
		
		fseek(rsa1024Tests,NIST_HEADER_BYTE_COUNT_KEY_N_1,SEEK_SET);
		{         
			//========GETTING THE KEY_N VALUE===================================
			
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = 0; i <nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				Key_n[i]= strtoull(dataWord,NULL,16); 
			}	
		}
	
		fseek(rsa1024Tests,NIST_HEADER_BYTE_COUNT_MESSAGEIN_1,SEEK_SET);
		{
			//========GETTING THE MESSAGE VALUE===================================
	
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = ((nrg*3)/4); i < nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				rsaDataIn[i]= strtoull(dataWord,NULL,16); 
			}			
		}

		fseek(rsa1024Tests,NIST_HEADER_BYTE_COUNT_EXPDATAOUT_1,SEEK_SET);
		{
			//========GETTING THE MESSAGE VALUE===================================
	
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = 0; i <nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				expDataOut[i]= strtoull(dataWord,NULL,16); 
			}			
		}

		tic = Wtime();
		rsaDataOut = RSA_SIGN(rsaDataIn, Key_e_d, Key_n, DBG);
		tic = Wtime() - tic;
	
		fprintf(rsa1024TestsLog,"  ***********************************************************************************************\n\r");
		fprintf(rsa1024TestsLog,"         KEY_D[0-31]        KEY_N[0-31]        INPUT[0-31]        SIGN[0-31]       EXPECTED[0-31]\n");
		fprintf(rsa1024TestsLog,"      ----------------   ----------------   ----------------   ---------------    ----------------\n");
        for (int i = 0; i< nrg; i++) {               
 		#if defined (AXI64)
			fprintf(rsa1024TestsLog,"      %16.16llX   %16.16llX   %16.16llX   %16.16llX   %16.16llX\n", Key_e_d[i], Key_n[i], rsaDataIn[i], rsaDataOut[i], expDataOut[i]);
		#elif defined (AXI32)
			fprintf(rsa1024TestsLog,"           %8.8X      %8.8X     %8.8X     %8.8X     %8.8X\n", Key_e_d[i], Key_n[i], rsaDataIn[i], rsaDataOut[i], expDataOut[i]);	
		#endif
       }               
		fprintf(rsa1024TestsLog,"\n    Operation time for signature generation:        %06llu us.\t\t\t\n\r",tic);


		if (DBG > 0) {
			printf("\n");
		  #if defined (AXI64)
			printf("    KEY_E_D            KEY_N              INPUT              OUTPUT             EXPECTED\n");
			printf("    ----------------   ----------------   ----------------   ---------------    ----------------\n");
		  #else
			printf("      KEY_E_D        KEY_N        INPUT        OUTPUT      EXPECTED\n");
			printf("      --------      --------     --------     --------     --------\n");
		  #endif
			for (int i = 0; i< nrg; i++) {
		  #if defined (AXI64)
				printf("    %16.16llX   %16.16llX   %16.16llX   %16.16llX   %16.16llX\n",
		  #else
				printf("      %8.8X      %8.8X     %8.8X     %8.8X     %8.8X\n",
		  #endif
				Key_e_d[i], Key_n[i], rsaDataIn[i], rsaDataOut[i], expDataOut[i]);
			}
		}
    
		for (int i = 0; i< nrg; i++) {
			if (rsaDataOut[i] != expDataOut[i]) {
				err++;
			}
		}
  			
		if (DBG > 0) printf ("\n   TEST ");
  
		if (err == 0 ) {
			printf ("PASSED \n\n");
		} else {
			printf ("FAILED \n\n");
		}

		if (interactive){
			printf("-- Press return to continue\n\n");
			getchar();
		}

    }
	

//========START THE SIGN VERIFICATION OPERATION WITH KEY E==========================

    for (int i = 0; i < count; i++){

		printf("   Test Vector (Signature Verification) %3d:   ",i+1);
		fprintf(rsa1024TestsLog,"  Test Vector (Signature Verification) 3%d: \n\n",i+1);
			
		if (DBG > 0) printf ("\n");

		for (int i = 0; i < nrg; i++){
			Key_e_d[i]= 0;
			Key_n[i] = 0;
			rsaDataIn[i]= 0;
			expDataOut[i] = 0;
		}	
	
		//========JUMP THE NIST TESTS HEADER==========================
		fseek(rsa1024Tests,HEADER_BYTE_COUNT_KEY_E_D_1,SEEK_SET);
		{
			//========GETTING THE KEY_E VALUE===================================
	
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = nrg-1; i < nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				Key_e_d[i]= strtoull(dataWord,NULL,16);
			}	
		}   
	
		fseek(rsa1024Tests,HEADER_BYTE_COUNT_KEY_N_1,SEEK_SET);
		{         
			//========GETTING THE KEY_N VALUE===================================
			
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = 0; i <nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				Key_n[i]= strtoull(dataWord,NULL,16); 
			}	
		}
	
		fseek(rsa1024Tests,HEADER_BYTE_COUNT_MESSAGEIN_1,SEEK_SET);
		{
			//========GETTING THE MESSAGE VALUE===================================
	
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = 0; i <nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				rsaDataIn[i]= strtoull(dataWord,NULL,16); 
			}			
		}
		
		fseek(rsa1024Tests,NIST_HEADER_BYTE_COUNT_MESSAGEIN_1,SEEK_SET);
		{
			//========GETTING THE MESSAGE VALUE===================================
	
			fseek(rsa1024Tests,DATA_WIDTH,SEEK_CUR);
			
			for (int i = ((nrg*3)/4); i < nrg ; i++)
			{   
				fgets(dataWord,DATA_WIDTH + 1,rsa1024Tests);
				expDataOut[i]= strtoull(dataWord,NULL,16); 
			}			
		}
		
		tic = Wtime();
		rsaDataOut = RSA_SIGN(rsaDataIn, Key_e_d, Key_n, DBG);
		tic = Wtime() - tic;
	
		fprintf(rsa1024TestsLog," ************************************************************************************************\n\r");
		fprintf(rsa1024TestsLog,"         KEY_E[0-31]        KEY_N[0-31]        SIGN[0-31]       OUTPUT[0-31]       EXPECTED[0-31]\n");
		fprintf(rsa1024TestsLog,"      ----------------   ----------------   ----------------   ---------------    ----------------\n");
		for (int i = 0; i< nrg; i++) {				
		#if defined (AXI64)
			fprintf(rsa1024TestsLog,"      %16.16llX   %16.16llX   %16.16llX   %16.16llX   %16.16llX\n", Key_e_d[i], Key_n[i], rsaDataIn[i], rsaDataOut[i], expDataOut[i]);
		#elif defined (AXI32)
			fprintf(rsa1024TestsLog,"           %8.8X      %8.8X     %8.8X     %8.8X     %8.8X\n", Key_e_d[i], Key_n[i], rsaDataIn[i], rsaDataOut[i], expDataOut[i]);	
		#endif
		}               
		fprintf(rsa1024TestsLog,"\n    Operation time for signature verification:        %06llu us.\t\t\t\n\r",tic);
	
		if (DBG > 0) {
			printf("\n");
		#if defined (AXI64)
			printf("    KEY_E_D            KEY_N              INPUT              OUTPUT             EXPECTED\n");
			printf("    ----------------   ----------------   ----------------   ---------------    ----------------\n");
		#else
			printf("      KEY_E_D        KEY_N        INPUT        OUTPUT      EXPECTED\n");
			printf("      --------      --------     --------     --------     --------\n");
		#endif
			for (int i = 0; i< nrg; i++) {
		#if defined (AXI64)
				printf("    %16.16llX   %16.16llX   %16.16llX   %16.16llX   %16.16llX\n",
		#elif defined (AXI32)
				printf("      %8.8X      %8.8X     %8.8X     %8.8X     %8.8X\n",
		#endif
				Key_e_d[i], Key_n[i], rsaDataIn[i], rsaDataOut[i], expDataOut[i]);
			}
		}
		
		for (int i = 0; i< nrg; i++) {
			if (rsaDataOut[i] != expDataOut[i]) {
				err++;
			}
		}
		
		if (DBG > 0) printf ("\n   TEST ");

		if (err == 0 ) {
			printf ("PASSED & SIGNATURE VERIFIED\n\n");
		} else {
			printf ("FAILED\n\n");
		}
		
		
		if (interactive){
			printf("-- Press return to continue\n\n");
			getchar();
		}

    }

	printf("\n\n");
	fclose(rsa1024Tests);
    fclose(rsa1024TestsLog);
    return 0;

}