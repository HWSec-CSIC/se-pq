/******************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSec_puf4r3_2.0: puf_es_health_check.c for PUF4R3  32/64-bits
 *
 *  Created on: 10/02/2023
 *      Author: rojas@imse-cnm.csic.es
 *
 *  Function:
 *  - Detects whether the entropy source is presenting a failure by evaluating the
 *    2 health tests (Repetition Count and Adaptative Propotion) presented in the 
 *    NIST recommendation 800-90b. The parameters required to evaluate these tests 
 *    were calculated during the process of characterizing the PUF as an entropy source. 
 *
 *  Outputs:
 *  - Health check tests parameters 
 *	- Health check tests results
*/
/******************************************************************************/
 
/******************************** Include Files *******************************/

#include "puf4r3.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

int main(int argc, char** argv)
{
	char OutF[] = "./out/puf/SPIRS_RoT_PUF_ES_data.bin";
	char *binfile;
	
	float alpha   = 0.00000502515530065; 
	char  A 	  = 0;
	int   B 	  = 0;
	int   Bmax    = 0;
	char  C_rc    = 0;
	int   C_ap    = 612;
	float H 	  = 0.834914;
	int   N_CMPS  = 250;	
	int   N_tests = 1000;	
	char  X       = 0;
	int   W 	  = 1024;
	
	FILE *bin_file;  
	
    binfile = OutF; 

	for(int arg=1; arg < argc; arg++) {
		if(argv[arg][0] == '-') {
			if(argv[arg][1] == 'h') {
				printf("\n Usage: puf_es_health_check [-h] [-f <filename.bin>]");
				exit(0);
			} else if(argv[arg][1] == 'f') { 
				if(arg<argc-1) binfile = argv[arg+1];
			} else if(argv[arg][1] == 's') {
				if(arg<argc-1) H = atof(argv[arg+1]);
			} else if(argv[arg][1] == 'x') {
				if(arg<argc-1) C_ap = atoi(argv[arg+1]);
			} else if(argv[arg][1] == 'a') {
				if(arg<argc-1) alpha = atof(argv[arg+1]);	
			}   else {
				printf("\nunknow option: %s\n", argv[arg]);
			}
		}	
	}	
	
	int lb=1000000; 
	unsigned char buffer[lb];
	
	printf("\n\t>> HEALTH CHECK TESTS EXECUTION -- \n\n");
	
	printf( "\t-- PARAMETERS -- \n\n");
	printf( "\t 1)Bin file name : %s \n", binfile );
	printf( "\t 2)No. Tests     : %d \n", N_tests);
	printf( "\t 3)No. Cmps      : %d \n", N_CMPS);
	printf( "\t 4)No. bits      : %d \n", lb );
	printf( "\t 5)H_estimated   : %f \n", H );
	printf( "\t 6)Alpha         : %.17f \n", alpha );
	printf( "\t 7)AP_cutoff     : %d \n\n", C_ap );
		
	// Reading *.bin file
	bin_file = fopen(binfile,"rb");  
	fread(buffer,sizeof(buffer),1,bin_file); 
	fclose(bin_file);   
	
	// HEALTH CHECKS 
	//---------------------------------------------------------------------------------------------------
	// REPETITION COUNT Test 
	/*
	* Parameters:
	*
	* 	H     : estimated entropy
	* 	alpha : false-positive probability 
	*	C_rc  : cutoff value
	*
	*	H	  =H_original
	*	alpha = calulated in restart tests ;  (recommended in SP800-90b - Section 4.3.3)
	*	C_rc  = 1+ [-log2(alpha) / H]  = 1 + [20/H]
	*/
	
	printf( "\t-- TESTS -- \n\n"); 
	
   	C_rc = 1 + ((-log2(alpha))/H);
	Bmax = 0;

	printf("\t > Performing Repetition Count Test... \n");
	for(int i = 0; i<lb-C_rc; i++)
	{
		A = buffer[i];
		B = 1; 
		next : X = buffer[i+B];
		if(X==A)
		{
			B++;
			if(B>C_rc)
			{				
				printf(" Repetition count tests : FAILURE \n Cutoff value (%d)  reached at position %d \n",B,i); 
				goto HC_2;
			}
			goto next; 
		}
		if(Bmax<B)
		{
			Bmax=B;
		}
		i = i+B-1;
	 }
	
	printf("\t > Max.rep/Cutoff.value=%d/%d \n\t > Repetition Count Test result : SUCCESS \n\n",Bmax,C_rc); 
	
	// ADAPTATIVE PROPORTION Test 
	/*
	* Parameters:
	*
	*	C_ap	: f(H)
	*	W		: window length
	*	H		: estimated entropy
	*	alpha	: false-positive probability 
	*
	*	C_ap  = 1+CRITBINOM(W, power(2,( −H)),1−alpha) ; (Excel formula quoted in SP800-90b - Section 4.4.2)
	*	W	  = 1024;  (recommended in SP800-90b - Section 4.4.2)
	*	alpha = 2^(-20) ;  (recommended in SP800-90b - Section 4.3.3)
	*/
	
	Bmax = 0;
	
	printf("\t > Performing Adaptive Proportion Test... \n");
	HC_2 : for(int i = 0; i<lb-W; i++)
	{
		A = buffer[i];
		B = 1; 
 		 for(int j = 1; j<W-1; j++)
		 {
			 if(A==buffer[i+j]) B++;
			 if(B>=C_ap) 
			 {
				printf(" Adaptive proportion test : FAILURE \n Cutoff value reached : C_ap=%d \n",B); 
				exit(0);
			}
		 } 
		 if(Bmax<B) Bmax=B;
	}
	
	printf("\t > Max.prop/Cutoff.value=%d/%d \n\t > Adaptive Proportion Test result : SUCCESS \n\n",Bmax,C_ap); 
	printf("\t--- Health check tests execution: finished!!! \n\n");
	printf("\n>> ENTROPY SOURCE VALIDATION : finished!!! \n\n");
	
    return SUCCESS;
}
