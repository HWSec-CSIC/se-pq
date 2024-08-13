/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: sha2_test.c 
 *
 *  Created on: 13/02/2023
 *      Author: camacho@imse-cnm.csic.es
 */ 
/****************************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "functions_hw.h"
#include "function_test.h"
#include "sha256.h"
#include "sha2_hw.h"

#define SIZE_SHA2 256
#define SIZE_STREAM 32
#define SIZE_BYTE (unsigned long long)512E3
#define SIZE_BITS SIZE_BYTE * 8
#define SIZE_INPUT SIZE_BITS / 8
#define SIZE_OUTPUT SIZE_SHA2 / 8

int main(int argc, char** argv) {

	int DBG = 0;
	int v = 1;
	int b = 1;
	int ini = 0;
	int fin = 129;
	int n_test = 1;
	int stop = 0;
	
	for (int arg = 1; arg < argc; arg++) {

		if (argv[arg][0] == '-') {
			if (argv[arg][1] == 'h') {
				printf("\n Usage: ./sha256_test [-h] [-v] [-b] [-n] [-s] [-i] [-f] \n");
				printf("\n -h: Show the help.");
				printf("\n -v: Verbose Level:");
				printf("\n \t 1: Show the Acceleration of each NIST run (By default).");
				printf("\n \t 2: Show the Acceleration + Output Data of each NIST run.");
				printf("\n \t 3: Show the Acceleration + Input/Output Data of each NIST run.");
				printf("\n -b: Selection of NIST Test.");
				printf("\n \t 1: Use the NIST Byte Test (By default).");
				printf("\n \t 2: Use the NIST Bit Test. WARNING: The reference SW is not prepared for this test.");
				printf("\n -n: [Number] of test executions.");
				printf("\n -s: Stop in each run.");
				printf("\n -i: Initial run.");
				printf("\n -f: Final run.");
				printf("\n \n");
				return SUCCESS; 
			}
			else if (argv[arg][1] == 'v') {
				if (arg < argc - 1) v = atoi(argv[arg + 1]);
			}
			else if (argv[arg][1] == 'b') {
				if (arg < argc - 1) b = atoi(argv[arg + 1]);
			}
			else if (argv[arg][1] == 'n') {
				if (arg < argc - 1) n_test = atoi(argv[arg + 1]);
			}
			else if (argv[arg][1] == 's') {
				stop = 1;
			}
			else if (argv[arg][1] == 'i') {
				if (arg < argc - 1) ini = atoi(argv[arg + 1]);
			}
			else if (argv[arg][1] == 'f') {
				if (arg < argc - 1) fin = atoi(argv[arg + 1]);
			}
			else {
				printf("\n Unknow option: %s\n", argv[arg]);
			}
		}
	}


	unsigned char in[SIZE_INPUT];
	unsigned char out_hw[SIZE_OUTPUT];
	unsigned char out_nist[SIZE_OUTPUT];
	unsigned long long length;

	unsigned long long tic = 0;
	unsigned long long time_hw = 0, time_sw = 0;

	BYTE in_sw[SIZE_INPUT];
	SHA256_CTX ctx;
	BYTE out_sw[SIZE_OUTPUT];

	//load_bitstream(0, 64);

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

	if (v >= 1) printf("\n   Loading Bitstream ...");
			
	Status = PYNQ_loadBitstream(bitstream_file);
	if (Status != SUCCESS) {
		printf("LoadBitstream Failure\n");
		return ERROR;
	}
	
    if (v >= 1) printf(" done \n");
	
  #endif    

	MMIO_WINDOW ms2xl;
	createMMIOWindow(&ms2xl, MS2XL_BASEADDR, MS2XL_LENGTH);

	// Evaluation of NIST Tests
	if (b == 2) { // bittest
		ini = 0;
		fin = 1025;
	}

	int total_pass_hw = 0;
	int total_pass_sw = 0;

		for (int test = 1; test <= n_test; test++) {
			printf("\n   -------- TEST: %d ---------\n", test);
			total_pass_hw = 0;
			total_pass_sw = 0;

			for (int sel = ini; sel < fin; sel++) {

				// Get NIST Data: Length, Input Data & Output Data
				input_nist(in, out_nist, &length, sel, b, DBG);
				int input_chars = ceil((float)length / 8);

				// SHA2 HW Execution
				tic = Wtime();
				sha256_hw(in, out_hw, length, ms2xl, DBG);
				time_hw = Wtime() - tic;

				// SHA2 SW Execution
				memcpy(in_sw, in, SIZE_INPUT);

				tic = Wtime();
				sha256_init(&ctx);
				sha256_update(&ctx, in_sw, input_chars);
				sha256_final(&ctx, out_sw);
				time_sw = Wtime() - tic;

				// Comparison of results 
				int pass_hw = 1;
				for (int i = 0; i < SIZE_OUTPUT; i++) if (out_hw[i] != out_nist[i]) pass_hw = 0;
				if (pass_hw) ++total_pass_hw;
				int pass_sw = 1;
				for (int i = 0; i < SIZE_OUTPUT; i++) if (out_sw[i] != out_nist[i]) pass_sw = 0;
				if (pass_sw) ++total_pass_sw;

				// Print Result
				if (v >= 1) {
					printf("\n   -- Run %3d     Msg Length: %5lld (bits) %4lld (bytes)     Acceleration: %3.2f   HW Pass: %3d/%3d", 
						sel+1, length, length / 8, ((float)(time_sw) / (float)(time_hw)), total_pass_hw, (fin-ini));
					if (pass_hw) printf("     OK"); else printf("     FAIL");
				}
				if (v >= 2) {
					printf("\n \t OUT_HW: \t");	for (int i = 0; i < SIZE_OUTPUT; i++) printf("%02x", out_hw[i]);		printf("\t (%6llu us.)", time_hw);
					printf("\n \t OUT_SW: \t");	for (int i = 0; i < SIZE_OUTPUT; i++) printf("%02x", out_sw[i]);		printf("\t (%6llu us.)", time_sw);
					printf("\n \t OUT_NIST: \t");	for (int i = 0; i < SIZE_OUTPUT; i++) printf("%02x", out_nist[i]);
					printf("\n \t CHECK_HW: \t"); if (pass_hw) printf("OK"); else printf("FAIL");
					printf("\n \t CHECK_SW: \t"); if (pass_sw) printf("OK"); else printf("FAIL");
				}
				if (v >= 3) {
					printf("\n \t IN: ");		for (int i = 0; i < input_chars; i++) printf("%02x", in[i]);
					printf("\n");
				}

				if (stop) {
					printf("\n\n   Press any key to continue ... ");
					getchar();
				}
			}
		if (v >= 1) printf("\n"); 
		printf("\n                  TESTS PASSED -- SOFTWARE: %d/%d, HARDWARE: %d/%d\n\n\r", total_pass_sw, fin-ini, total_pass_hw, fin-ini);
		}
		
	printf("\n");
}
