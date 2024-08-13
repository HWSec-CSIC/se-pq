/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: functions_hw.c 
 *
 *  Created on: 13/02/2023
 *      Author: camacho@imse-cnm.csic.es
 */
/****************************************************************************************/

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "sha2_hw.h"

#define SIZE_SHA2 512
#define SIZE_STREAM 32
#define SIZE_INPUT SIZE_SHA2 / 8
#define SIZE_OUTPUT SIZE_INPUT / 2

#if defined(AXI64)

  void sha256_hw(unsigned char* in, unsigned char* out, unsigned long long length, MMIO_WINDOW ms2xl, int DBG) {

	unsigned long long hb_num;
	unsigned long long L_pos;
	unsigned long long L_512;
	unsigned long long ind;
	int last_hb = 0;

	unsigned long long buffer_in[8];
	unsigned long long buffer_out[4];
	unsigned long long buf_1, buf_2;

	//unsigned long long tic = 0, toc;

	// ------- Number of hash blocks ----- //
	L_pos = (((unsigned long long)(length / 512) + 1) * 16) - 1;
	L_512 = length % 512;
	if (L_512 >= 448) L_pos = L_pos + 16;
	hb_num = (L_pos + 1) / 16;
	if (DBG == 1) printf("hb_num = %lld \n", hb_num);

	// ------- SHA2 Initialization --------//

	sha2_ms2xl_init(length, ms2xl, 0);

	// ------- Operation ---------------- //
	for (unsigned long long hb = 1; hb <= hb_num; hb++) {
		ind = (hb - 1) * 64;
		for (int i = 0; i < 8; i++) {
			if ((ind + 0) * 8 > length) in[ind + 0] = 0x00;
			if ((ind + 1) * 8 > length) in[ind + 1] = 0x00;
			if ((ind + 2) * 8 > length) in[ind + 2] = 0x00;
			if ((ind + 3) * 8 > length) in[ind + 3] = 0x00;
			if ((ind + 4) * 8 > length) in[ind + 4] = 0x00;
			if ((ind + 5) * 8 > length) in[ind + 5] = 0x00;
			if ((ind + 6) * 8 > length) in[ind + 6] = 0x00;
			if ((ind + 7) * 8 > length) in[ind + 7] = 0x00;

			buf_1 = ((unsigned long long)in[ind + 0] << 56) + ((unsigned long long)in[ind + 1] << 48) + ((unsigned long long)in[ind + 2] << 40) + ((unsigned long long)in[ind + 3] << 32);
			buf_2 = ((unsigned long long)in[ind + 4] << 24) + ((unsigned long long)in[ind + 5] << 16) + ((unsigned long long)in[ind + 6] << 8) + ((unsigned long long)in[ind + 7]);
			buffer_in[i] = buf_1 + buf_2;
			if (DBG == 1) printf("buf_1 = %02llx \n", buf_1);
			if (DBG == 1) printf("buf_2 = %02llx \n", buf_2);
			if (DBG == 1) printf("in[%lld] = %02x \t in[%lld] = %02x \t in[%lld] = %02x \t in[%lld] = %02x \n", ind, in[ind], ind + 1, in[ind + 1], ind + 2, in[ind + 2], ind + 3, in[ind + 3]);
			if (DBG == 1) printf("buffer_in[%d] = %02llx \n", i, buffer_in[i]);
			ind = ind + 8;
		}
		if (hb == hb_num) last_hb = 1;
		sha2_ms2xl(buffer_in, buffer_out, ms2xl, last_hb, DBG);
	}

	// ------- Change Out Format --------- //
	for (int i = 0; i < 4; i++) {
		ind = i * 8;
		out[ind + 0] = (buffer_out[i] >> 56);
		out[ind + 1] = (buffer_out[i] >> 48)	- (out[ind + 0] << 8);
		out[ind + 2] = (buffer_out[i] >> 40)	- (out[ind + 0] << 16)	- (out[ind + 1] << 8);
		out[ind + 3] = (buffer_out[i] >> 32)	- (out[ind + 0] << 24)	- (out[ind + 1] << 16)	- (out[ind + 2] << 8);

		out[ind + 4] = (buffer_out[i] >> 24)	- ((unsigned long long)out[ind + 0] << 32)	- (out[ind + 1] << 24)	- (out[ind + 2] << 16)	- (out[ind + 3] << 8);
		out[ind + 5] = (buffer_out[i] >> 16)	- ((unsigned long long)out[ind + 0] << 40)	- ((unsigned long long)out[ind + 1] << 32)	- (out[ind + 2] << 24)	- (out[ind + 3] << 16) - (out[ind + 4] << 8);
		out[ind + 6] = (buffer_out[i] >> 8)	- ((unsigned long long)out[ind + 0] << 48)	- ((unsigned long long)out[ind + 1] << 40)	- ((unsigned long long)out[ind + 2] << 32)	- (out[ind + 3] << 24) - (out[ind + 4] << 16)	- (out[ind + 5] << 8);
		out[ind + 7] = buffer_out[i]		- ((unsigned long long)out[ind + 0] << 56)	- ((unsigned long long)out[ind + 1] << 48)	- ((unsigned long long)out[ind + 2] << 40)	- ((unsigned long long)out[ind + 3] << 32) - (out[ind + 4] << 24)	- (out[ind + 5] << 16)	- (out[ind + 6] << 8);
	}


}

 #elif  defined(AXI32) 

  void sha256_hw(unsigned char* in, unsigned char* out, unsigned long long length, MMIO_WINDOW ms2xl, int DBG) {
	
	unsigned long long hb_num;
	unsigned long long L_pos;
	unsigned long long L_512;
	unsigned long long ind;
	int last_hb = 0;

	unsigned int buffer_in[16];
	unsigned int buffer_out[8];

	//unsigned long long tic = 0, toc;

	// ------- Number of hash blocks ----- //
	L_pos = (((unsigned long long)(length / 512) + 1) * 16) - 1;
	L_512 = length % 512;
	if (L_512 >= 448) L_pos = L_pos + 16;
	hb_num = (L_pos + 1) / 16;
	if (DBG == 1) printf("hb_num = %lld \n", hb_num);
	// ------- SHA2 Initialization --------//

	sha2_ms2xl_init(length, ms2xl, 0);

	// ------- Operation ---------------- //
	for (unsigned long long hb = 1; hb <= hb_num; hb++) {
		ind = (hb - 1)*64;
		for (int i = 0; i < 16; i++) {
			if (ind * 8			> length) in[ind]		= 0x00;
			if ((ind + 1) * 8	> length) in[ind + 1]	= 0x00;
			if ((ind + 2) * 8	> length) in[ind + 2]	= 0x00;
			if ((ind + 3) * 8	> length) in[ind + 3]	= 0x00;

			buffer_in[i] = (unsigned int)(in[ind] << 24) + (unsigned int)(in[ind + 1] << 16) + (unsigned int)(in[ind + 2] << 8) + (unsigned int)(in[ind + 3]);
			ind = ind + 4;
		}
		if (hb == hb_num) last_hb = 1;
		sha2_ms2xl(buffer_in, buffer_out, ms2xl, last_hb, DBG);
	}

	// ------- Change Out Format --------- //
	for (int i = 0; i < 8; i++) {
		ind = i * 4;
		out[ind]		= buffer_out[i] >> 24;
		out[ind + 1]	= (buffer_out[i] >> 16)	- (out[ind] << 8);
		out[ind + 2]	= (buffer_out[i] >> 8)	- (out[ind] << 16) - (out[ind + 1] << 8);
		out[ind + 3]	= buffer_out[i]			- (out[ind] << 24) - (out[ind + 1] << 16) - (out[ind + 2] << 8);
	}


}

 #endif

