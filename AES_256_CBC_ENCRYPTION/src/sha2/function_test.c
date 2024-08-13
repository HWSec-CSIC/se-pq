/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: function_test.c 
 *
 *  Created on: 20/12/2022
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

#define MAX_LINE_LENGTH SIZE_INPUT

void reset_in(unsigned char* INPUT) {
	for (int i = 0; i < SIZE_INPUT; i++) INPUT[i] = 0x00;
}

void input_nist(unsigned char* INPUT, unsigned char* OUTPUT, unsigned long long* LEN, int sel, int b, int DBG) {

	FILE* rsp;
	int selection; 
	if (b == 1) {
		if (sel < 65) {
			rsp = fopen("./src/sha2/shabytetestvectors/SHA256ShortMsg.rsp", "r");
			selection = sel;
		}
		else {
			rsp = fopen("./src/sha2/shabytetestvectors/SHA256LongMsg.rsp", "r");
			selection = sel - 65;
		}
	}
	else {
		if (sel < 513) {
			rsp = fopen("./src/sha2/shabittestvectors/SHA256ShortMsg.rsp", "r");
			selection = sel;
		}
		else {
			rsp = fopen("./src/sha2/shabittestvectors/SHA256LongMsg.rsp", "r");
			selection = sel - 513;
		}
	}

	char line[MAX_LINE_LENGTH] = { 0 };
	char line_buffer[MAX_LINE_LENGTH] = { 0 };
	unsigned char data_in[SIZE_INPUT];
	unsigned char data_out[SIZE_OUTPUT];
	int line_count = -8; // Necesario para eliminar las cabeceras de los archivos
	int ind1, ind2;

	memset(data_in, 0, SIZE_INPUT);
	memset(data_out, 0, SIZE_OUTPUT);

	while (fgets(line, MAX_LINE_LENGTH, rsp))
	{
		/* Print each line */
		if (DBG == 4) printf("line[%06d]: %s", ++line_count, line);
		else ++line_count;

		//printf("\n %d %d %d %d", line_count, line_count % 4, line_count / 4, sel);

		// Obtener LENGTH
		if (((line_count % 4) == 0) && ((line_count / 4) == selection)) {
			for (int i = 0; i < MAX_LINE_LENGTH; i++) {
				if (i > 5) line_buffer[i - 6] = line[i];
			}
			*LEN = atoll(line_buffer);
			if (DBG == 3) printf("\n %lld \n", *LEN);
		}

		// Obtener DATA_INPUT
		else if (((line_count % 4) == 1) && ((line_count / 4) == selection)) {
			if (DBG == 3) printf("\n");
			for (int i = 0; i < MAX_LINE_LENGTH; i++) {
				if (i > 5) line_buffer[i - 6] = line[i];
			}
			int ce = ceil((float)*LEN / 8);
			char buf;
			for (int i = 0; i < ce; i++) {
					ind1 = 2 * i;
					ind2 = ind1 + 1;
					char_to_hex(line_buffer[ind1], line_buffer[ind2], &buf);
					data_in[i] = buf;
					if (DBG == 3) printf("%02x", data_in[i]);
			}
			memcpy(INPUT, data_in, sizeof(data_in));

		}

		// Obtener DATA_OUTPUT
		else if (((line_count % 4) == 2) && ((line_count / 4) == selection)) {
			if (DBG == 3) printf("\n");
			for (int i = 0; i < MAX_LINE_LENGTH; i++) {
				if (i > 4) line_buffer[i - 5] = line[i];
			}
			for (int i = 0; i < SIZE_OUTPUT; i++) {
				ind1 = 2 * i;
				ind2 = ind1 + 1;
				char buf;
				char_to_hex(line_buffer[ind1], line_buffer[ind2], &buf);
				data_out[i] = buf;
				if (DBG == 3) printf("%02x", data_out[i]);
			}
			memcpy(OUTPUT, data_out, sizeof(data_out));

		}

		/* Add a trailing newline to lines that don't already have one */
		if (DBG == 3) {
			if (line[strlen(line) - 1] != '\n')
				printf("\n");
		}
	}
	fclose(rsp);
}

void input_file(unsigned char* INPUT, unsigned long long* LEN, char* FILE_NAME, int DBG) {

	FILE* rsp;
	//int selection;
	
	if (!(rsp = fopen(FILE_NAME, "r"))) {
		printf("\n   File %s not found. Bye ...\n\n", FILE_NAME);
		exit (0);
	}

	char line[MAX_LINE_LENGTH] = { 0 };
	char line_buffer[MAX_LINE_LENGTH] = { 0 };
	unsigned char data_in[SIZE_INPUT];
	unsigned char data_out[SIZE_OUTPUT];
	int line_count = 0;
	int ind1, ind2;

	memset(data_in, 0, SIZE_INPUT);
	memset(data_out, 0, SIZE_OUTPUT);

	while (fgets(line, MAX_LINE_LENGTH, rsp))
	{
		/* Print each line */
		if (DBG == 4) printf("line[%06d]: %s", ++line_count, line);
		else ++line_count;

		// Obtener DATA_INPUT
		if (DBG == 3) printf("\n data_in:");
		for (int i = 0; i < MAX_LINE_LENGTH; i++) {
			line_buffer[i] = line[i];
		}
		*LEN = strlen(line) / 2;
		unsigned long long ce = *LEN;
		char buf;
		for (int i = 0; i < ce; i++) {
			ind1 = 2 * i;
			ind2 = ind1 + 1;
			char_to_hex(line_buffer[ind1], line_buffer[ind2], &buf);
			data_in[i] = buf;
			if (DBG == 3) printf("%02x", data_in[i]);
		}
		memcpy(INPUT, data_in, sizeof(data_in));

		/* Add a trailing newline to lines that don't already have one */
		if (DBG == 3) {
			if (line[strlen(line) - 1] != '\n')
				printf("\n");
		}
	}
	fclose(rsp);
}

void char_to_hex(unsigned char in0, unsigned char in1, char* out) {
	switch (in0) {
	case '0':
		switch (in1) {
		case '0': *out = 0x00; break;
		case '1': *out = 0x01; break;
		case '2': *out = 0x02; break;
		case '3': *out = 0x03; break;
		case '4': *out = 0x04; break;
		case '5': *out = 0x05; break;
		case '6': *out = 0x06; break;
		case '7': *out = 0x07; break;
		case '8': *out = 0x08; break;
		case '9': *out = 0x09; break;
		case 'a': *out = 0x0a; break;
		case 'b': *out = 0x0b; break;
		case 'c': *out = 0x0c; break;
		case 'd': *out = 0x0d; break;
		case 'e': *out = 0x0e; break;
		case 'f': *out = 0x0f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '1':
		switch (in1) {
		case '0': *out = 0x10; break;
		case '1': *out = 0x11; break;
		case '2': *out = 0x12; break;
		case '3': *out = 0x13; break;
		case '4': *out = 0x14; break;
		case '5': *out = 0x15; break;
		case '6': *out = 0x16; break;
		case '7': *out = 0x17; break;
		case '8': *out = 0x18; break;
		case '9': *out = 0x19; break;
		case 'a': *out = 0x1a; break;
		case 'b': *out = 0x1b; break;
		case 'c': *out = 0x1c; break;
		case 'd': *out = 0x1d; break;
		case 'e': *out = 0x1e; break;
		case 'f': *out = 0x1f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '2':
		switch (in1) {
		case '0': *out = 0x20; break;
		case '1': *out = 0x21; break;
		case '2': *out = 0x22; break;
		case '3': *out = 0x23; break;
		case '4': *out = 0x24; break;
		case '5': *out = 0x25; break;
		case '6': *out = 0x26; break;
		case '7': *out = 0x27; break;
		case '8': *out = 0x28; break;
		case '9': *out = 0x29; break;
		case 'a': *out = 0x2a; break;
		case 'b': *out = 0x2b; break;
		case 'c': *out = 0x2c; break;
		case 'd': *out = 0x2d; break;
		case 'e': *out = 0x2e; break;
		case 'f': *out = 0x2f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '3':
		switch (in1) {
		case '0': *out = 0x30; break;
		case '1': *out = 0x31; break;
		case '2': *out = 0x32; break;
		case '3': *out = 0x33; break;
		case '4': *out = 0x34; break;
		case '5': *out = 0x35; break;
		case '6': *out = 0x36; break;
		case '7': *out = 0x37; break;
		case '8': *out = 0x38; break;
		case '9': *out = 0x39; break;
		case 'a': *out = 0x3a; break;
		case 'b': *out = 0x3b; break;
		case 'c': *out = 0x3c; break;
		case 'd': *out = 0x3d; break;
		case 'e': *out = 0x3e; break;
		case 'f': *out = 0x3f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '4':
		switch (in1) {
		case '0': *out = 0x40; break;
		case '1': *out = 0x41; break;
		case '2': *out = 0x42; break;
		case '3': *out = 0x43; break;
		case '4': *out = 0x44; break;
		case '5': *out = 0x45; break;
		case '6': *out = 0x46; break;
		case '7': *out = 0x47; break;
		case '8': *out = 0x48; break;
		case '9': *out = 0x49; break;
		case 'a': *out = 0x4a; break;
		case 'b': *out = 0x4b; break;
		case 'c': *out = 0x4c; break;
		case 'd': *out = 0x4d; break;
		case 'e': *out = 0x4e; break;
		case 'f': *out = 0x4f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '5':
		switch (in1) {
		case '0': *out = 0x50; break;
		case '1': *out = 0x51; break;
		case '2': *out = 0x52; break;
		case '3': *out = 0x53; break;
		case '4': *out = 0x54; break;
		case '5': *out = 0x55; break;
		case '6': *out = 0x56; break;
		case '7': *out = 0x57; break;
		case '8': *out = 0x58; break;
		case '9': *out = 0x59; break;
		case 'a': *out = 0x5a; break;
		case 'b': *out = 0x5b; break;
		case 'c': *out = 0x5c; break;
		case 'd': *out = 0x5d; break;
		case 'e': *out = 0x5e; break;
		case 'f': *out = 0x5f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '6':
		switch (in1) {
		case '0': *out = 0x60; break;
		case '1': *out = 0x61; break;
		case '2': *out = 0x62; break;
		case '3': *out = 0x63; break;
		case '4': *out = 0x64; break;
		case '5': *out = 0x65; break;
		case '6': *out = 0x66; break;
		case '7': *out = 0x67; break;
		case '8': *out = 0x68; break;
		case '9': *out = 0x69; break;
		case 'a': *out = 0x6a; break;
		case 'b': *out = 0x6b; break;
		case 'c': *out = 0x6c; break;
		case 'd': *out = 0x6d; break;
		case 'e': *out = 0x6e; break;
		case 'f': *out = 0x6f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '7':
		switch (in1) {
		case '0': *out = 0x70; break;
		case '1': *out = 0x71; break;
		case '2': *out = 0x72; break;
		case '3': *out = 0x73; break;
		case '4': *out = 0x74; break;
		case '5': *out = 0x75; break;
		case '6': *out = 0x76; break;
		case '7': *out = 0x77; break;
		case '8': *out = 0x78; break;
		case '9': *out = 0x79; break;
		case 'a': *out = 0x7a; break;
		case 'b': *out = 0x7b; break;
		case 'c': *out = 0x7c; break;
		case 'd': *out = 0x7d; break;
		case 'e': *out = 0x7e; break;
		case 'f': *out = 0x7f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '8':
		switch (in1) {
		case '0': *out = 0x80; break;
		case '1': *out = 0x81; break;
		case '2': *out = 0x82; break;
		case '3': *out = 0x83; break;
		case '4': *out = 0x84; break;
		case '5': *out = 0x85; break;
		case '6': *out = 0x86; break;
		case '7': *out = 0x87; break;
		case '8': *out = 0x88; break;
		case '9': *out = 0x89; break;
		case 'a': *out = 0x8a; break;
		case 'b': *out = 0x8b; break;
		case 'c': *out = 0x8c; break;
		case 'd': *out = 0x8d; break;
		case 'e': *out = 0x8e; break;
		case 'f': *out = 0x8f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case '9':
		switch (in1) {
		case '0': *out = 0x90; break;
		case '1': *out = 0x91; break;
		case '2': *out = 0x92; break;
		case '3': *out = 0x93; break;
		case '4': *out = 0x94; break;
		case '5': *out = 0x95; break;
		case '6': *out = 0x96; break;
		case '7': *out = 0x97; break;
		case '8': *out = 0x98; break;
		case '9': *out = 0x99; break;
		case 'a': *out = 0x9a; break;
		case 'b': *out = 0x9b; break;
		case 'c': *out = 0x9c; break;
		case 'd': *out = 0x9d; break;
		case 'e': *out = 0x9e; break;
		case 'f': *out = 0x9f; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case 'a':
		switch (in1) {
		case '0': *out = 0xa0; break;
		case '1': *out = 0xa1; break;
		case '2': *out = 0xa2; break;
		case '3': *out = 0xa3; break;
		case '4': *out = 0xa4; break;
		case '5': *out = 0xa5; break;
		case '6': *out = 0xa6; break;
		case '7': *out = 0xa7; break;
		case '8': *out = 0xa8; break;
		case '9': *out = 0xa9; break;
		case 'a': *out = 0xaa; break;
		case 'b': *out = 0xab; break;
		case 'c': *out = 0xac; break;
		case 'd': *out = 0xad; break;
		case 'e': *out = 0xae; break;
		case 'f': *out = 0xaf; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case 'b':
		switch (in1) {
		case '0': *out = 0xb0; break;
		case '1': *out = 0xb1; break;
		case '2': *out = 0xb2; break;
		case '3': *out = 0xb3; break;
		case '4': *out = 0xb4; break;
		case '5': *out = 0xb5; break;
		case '6': *out = 0xb6; break;
		case '7': *out = 0xb7; break;
		case '8': *out = 0xb8; break;
		case '9': *out = 0xb9; break;
		case 'a': *out = 0xba; break;
		case 'b': *out = 0xbb; break;
		case 'c': *out = 0xbc; break;
		case 'd': *out = 0xbd; break;
		case 'e': *out = 0xbe; break;
		case 'f': *out = 0xbf; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case 'c':
		switch (in1) {
		case '0': *out = 0xc0; break;
		case '1': *out = 0xc1; break;
		case '2': *out = 0xc2; break;
		case '3': *out = 0xc3; break;
		case '4': *out = 0xc4; break;
		case '5': *out = 0xc5; break;
		case '6': *out = 0xc6; break;
		case '7': *out = 0xc7; break;
		case '8': *out = 0xc8; break;
		case '9': *out = 0xc9; break;
		case 'a': *out = 0xca; break;
		case 'b': *out = 0xcb; break;
		case 'c': *out = 0xcc; break;
		case 'd': *out = 0xcd; break;
		case 'e': *out = 0xce; break;
		case 'f': *out = 0xcf; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case 'd':
		switch (in1) {
		case '0': *out = 0xd0; break;
		case '1': *out = 0xd1; break;
		case '2': *out = 0xd2; break;
		case '3': *out = 0xd3; break;
		case '4': *out = 0xd4; break;
		case '5': *out = 0xd5; break;
		case '6': *out = 0xd6; break;
		case '7': *out = 0xd7; break;
		case '8': *out = 0xd8; break;
		case '9': *out = 0xd9; break;
		case 'a': *out = 0xda; break;
		case 'b': *out = 0xdb; break;
		case 'c': *out = 0xdc; break;
		case 'd': *out = 0xdd; break;
		case 'e': *out = 0xde; break;
		case 'f': *out = 0xdf; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case 'e':
		switch (in1) {
		case '0': *out = 0xe0; break;
		case '1': *out = 0xe1; break;
		case '2': *out = 0xe2; break;
		case '3': *out = 0xe3; break;
		case '4': *out = 0xe4; break;
		case '5': *out = 0xe5; break;
		case '6': *out = 0xe6; break;
		case '7': *out = 0xe7; break;
		case '8': *out = 0xe8; break;
		case '9': *out = 0xe9; break;
		case 'a': *out = 0xea; break;
		case 'b': *out = 0xeb; break;
		case 'c': *out = 0xec; break;
		case 'd': *out = 0xed; break;
		case 'e': *out = 0xee; break;
		case 'f': *out = 0xef; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	case 'f':
		switch (in1) {
		case '0': *out = 0xf0; break;
		case '1': *out = 0xf1; break;
		case '2': *out = 0xf2; break;
		case '3': *out = 0xf3; break;
		case '4': *out = 0xf4; break;
		case '5': *out = 0xf5; break;
		case '6': *out = 0xf6; break;
		case '7': *out = 0xf7; break;
		case '8': *out = 0xf8; break;
		case '9': *out = 0xf9; break;
		case 'a': *out = 0xfa; break;
		case 'b': *out = 0xfb; break;
		case 'c': *out = 0xfc; break;
		case 'd': *out = 0xfd; break;
		case 'e': *out = 0xfe; break;
		case 'f': *out = 0xff; break;
		default	:	printf("\n\n The input character is not hexadecimal. Bye ... \n\n"); exit(0); break;
		} break;
	default: 
		printf("\n\n The input character is not hexadecimal. Bye ... \n\n");
		exit(0);
		break;
	}
	
}