/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: sha2_spirs.c 
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

	unsigned long long length;
	unsigned long long length_bit;
	char buf[SIZE_INPUT];
	char file_name[100];
	int f = 0;
	int v = 1;
	int DBG = 0;

	for (int arg = 1; arg < argc; arg++) {

		if (argv[arg][0] == '-') {
			if (argv[arg][1] == 'h') {
				printf("\n Usage: ./sha256_spirs [-h] [-v] [-m <message>] [-f <input_file>] \n");
				printf("\n -h: Show the help.");
				printf("\n -v: Verbose Level:");
				printf("\n \t 1: Show the Acceleration (By default).");
				printf("\n \t 2: Show the Acceleration + Output Data.");
				printf("\n \t 3: Show the Acceleration + Input/Output Data.");
				printf("\n -m: Input message (HEX format).");
				printf("\n -f: Input file (txt file).");
				printf("\n \n");
				return SUCCESS;
			}
			else if (argv[arg][1] == 'm') {
				if (arg < argc - 1) memcpy(buf,argv[arg + 1], 1000);
			}
			else if (argv[arg][1] == 'f') {
				if (arg < argc - 1) memcpy(file_name, argv[arg + 1], 100);
				f = 1;
			}
			else if (argv[arg][1] == 'v') {
				if (arg < argc - 1) v = atoi(argv[arg + 1]);
			}
			else {
				printf("\n Unknow option: %s\n", argv[arg]);
			}
		}
	}

	unsigned char in[SIZE_INPUT];
	unsigned char out_hw[SIZE_OUTPUT];

	memset(in, 0, SIZE_INPUT);

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

    if (v > 1) printf("\n  Loading Bitstream ...");
			
	Status = PYNQ_loadBitstream(bitstream_file);
	if (Status != SUCCESS) {
		printf("LoadBitstream Failure\n");
		return ERROR;
	}
	
    if (v > 1) printf(" done \n");
	
  #endif    

	MMIO_WINDOW ms2xl;
	createMMIOWindow(&ms2xl, MS2XL_BASEADDR, MS2XL_LENGTH);

	length = (unsigned long long)strlen(buf) / 2;

		// Get Data: Length & Input Data
	if (f) {
		input_file(in, &length, file_name, DBG);
	}
	else {
		int ind1, ind2;
		char character;
		for (int i = 0; i < length; i++) {
			ind1 = 2 * i;
			ind2 = ind1 + 1;
			char_to_hex(buf[ind1], buf[ind2], &character);
			in[i] = character;
		}
	}

	length_bit = 8 * length;
	// SHA2 HW Execution
	tic = Wtime();
	sha256_hw(in, out_hw, length_bit, ms2xl, DBG);
	time_hw = Wtime() - tic;

	// SHA2 SW Execution
	memcpy(in_sw, in, SIZE_INPUT);

	tic = Wtime();
	sha256_init(&ctx);
	sha256_update(&ctx, in_sw, length);
	sha256_final(&ctx, out_sw);
	time_sw = Wtime() - tic;

	// Comparison of results 
	int pass_hw = 1;
	for (int i = 0; i < SIZE_OUTPUT; i++) if (out_hw[i] != out_sw[i]) pass_hw = 0;

	// Print Result
	if (v >= 1) {
		if(pass_hw) printf("\n  -- Results of the Execution -- \n\n     Msg. Length:   %5lld (bits)  %5lld (bytes)     Acceleration: %4.2f      HW Pass: YES",
			length_bit, length, ((float)(time_sw) / (float)(time_hw)));
		else printf("\n  -- Results of the Execution -- \n\n     Msg. Length: %5lld (bits) %5lld (bytes)      Acceleration: %4.2f     HW Pass: FAIL",
			length_bit, length, ((float)(time_sw) / (float)(time_hw)));
		printf("\n\n     Hash Result: \t");	for (int i = 0; i < SIZE_OUTPUT; i++) printf("%02x", out_hw[i]);
		printf("\n");
	}
	if (v >= 2) {
		printf("\n \t OUT_HW: \t");	for (int i = 0; i < SIZE_OUTPUT; i++) printf("%02x", out_hw[i]);		printf("\t (%6llu us.)", time_hw);
		printf("\n \t OUT_SW: \t");	for (int i = 0; i < SIZE_OUTPUT; i++) printf("%02x", out_sw[i]);		printf("\t (%6llu us.)", time_sw);
		printf("\n \t CHECK_HW: \t"); if (pass_hw) printf("OK"); else printf("FAIL");
	}
	if (v >= 3) {
		printf("\n \t IN: ");		for (int i = 0; i < length; i++) printf("%02x", in[i]);
		printf("\n");
	}
	
	printf("\n \n");
	
}
