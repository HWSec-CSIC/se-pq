#include "sha3_shake_hw.h"

void sha3_256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, MMIO_WINDOW ms2xl)
{
	sha3_shake_hw(in, out, length*8, 256, 1, 1088, 256, ms2xl, 0);
}

void sha3_512_hw_func(unsigned char* in, unsigned int length, unsigned char* out, MMIO_WINDOW ms2xl)
{
	sha3_shake_hw(in, out, length*8, 512, 2, 576, 512, ms2xl, 0);
}

void shake128_hw_func(unsigned char* in, unsigned int length, unsigned char* out, unsigned int length_out, MMIO_WINDOW ms2xl)
{
	sha3_shake_hw(in, out, length*8, length_out*8, 3, 1344, 128, ms2xl, 0);
}

void shake256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, unsigned int length_out, MMIO_WINDOW ms2xl)
{
	sha3_shake_hw(in, out, length*8, length_out*8, 4, 1088, 256, ms2xl, 0);
}

void sha3_shake_ms2xl_init(MMIO_WINDOW ms2xl, int VERSION) {
	unsigned long long int op;
	unsigned long long int op_version;

	if (VERSION == 1)	op_version = 2 << 2; // SHA3-256
	else if (VERSION == 2)	op_version = 3 << 2; // SHA3-512
	else if (VERSION == 3)	op_version = 0 << 2; // SHAKE-128
	else if (VERSION == 4)	op_version = 1 << 2; // SHAKE-256
	else					op_version = 2 << 2;

	op = (unsigned long long int)ADD_SHA3 << 32 | ((op_version | 0) & 0xFFFFFFFF);; // RESET OFF
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned int));

}

void sha3_shake_ms2xl(unsigned long long int* a, unsigned long long int* b, MMIO_WINDOW ms2xl, unsigned int pos_pad, int pad, int shake, int VERSION, int SIZE_SHA3, int SIZE_BLOCK, int DBG) {

	unsigned long long int op;
	unsigned long long int op_version;
	unsigned long long int end_op = 0;
	unsigned long long int reg_addr;
	unsigned long long int reg_data_in;
	unsigned long long int reg_data_out;
	unsigned long long tic = 0, toc;

	if (VERSION == 1)	op_version = 2 << 2; // SHA3-256
	else if (VERSION == 2)	op_version = 3 << 2; // SHA3-512
	else if (VERSION == 3)	op_version = 0 << 2; // SHAKE-128
	else if (VERSION == 4)	op_version = 1 << 2; // SHAKE-256
	else					op_version = 2 << 2;

	if (shake != 1) {
		if (pad) {

			// ----------- LOAD LENGTH ---------- //
			if (DBG == 2) {
				printf("  -- sha2_ms2xl - Loading data padding ...................... \n");
				tic = Wtime();
			}

			op = (unsigned long long int)ADD_SHA3 << 32 | ((op_version | LOAD_LENGTH_SHA3) & 0xFFFFFFFF); // LOAD
			writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

			reg_addr = (unsigned long long int)(0);
			reg_data_in = (unsigned long long int)(pos_pad);
			writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
			writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
			if (DBG == 3) printf(" pos_pad: %lld\n\r", reg_data_in);
		}

		// ----------- LOAD ------------------ //
		if (DBG == 2) {
			printf("  -- sha2_ms2xl - Loading data .............................. \n");
			tic = Wtime();
		}

		op = (unsigned long long int)ADD_SHA3 << 32 | ((op_version | LOAD_SHA3) & 0xFFFFFFFF); // LOAD
		writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

		for (int i = 0; i < (SIZE_BLOCK / 64); i++) {
			reg_addr = (unsigned long long int)(i);
			reg_data_in = (unsigned long long int)(a[i]);
			writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
			writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
			if (DBG == 3) printf(" a(%d): %02llx\n\r", i, a[i]);
		}

		if (DBG == 2) {
			toc = Wtime() - tic;
			printf("(%3llu us.)\n", toc);
		}
	}


	// ----------- OPERATING ------------- //
	if (DBG == 2) {
		printf("  -- sha2_ms2xl - Operating .............. \n");
		tic = Wtime();
	}

	op = (unsigned long long int)ADD_SHA3 << 32 | ((op_version | START_SHA3) & 0xFFFFFFFF);; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	// wait END_OP
	while (!end_op) readMMIO(&ms2xl, &end_op, END_OP, sizeof(unsigned long long int));


	if (DBG == 2) {
		toc = Wtime() - tic;
		printf("(%3llu us.)\n", toc);
	}

	// ----------- READ ------------- //
	if (pad) {
		if (DBG == 2) {
			printf("  -- sha2_ms2xl - Reading output .............................. \n");
			tic = Wtime();
		}

		if (shake) {
			for (int i = 0; i < (SIZE_BLOCK / 64); i++) {
				reg_addr = (unsigned long long int)(i);
				writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
				readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
				b[i] = reg_data_out;
				if (DBG == 3) printf(" b(%d): %02llx\n\r", i, b[i]);
			}
		}
		else {
			for (int i = 0; i < (int)ceil((double)SIZE_SHA3 / (double)64); i++) {
				reg_addr = (unsigned long long int)(i);
				writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
				readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
				b[i] = reg_data_out;
				if (DBG == 3) printf(" b(%d): %02llx\n\r", i, b[i]);
			}
		}



		if (DBG == 2) {
			toc = Wtime() - tic;
			printf("(%3llu us.)\n", toc);
		}

		op = (unsigned long long int)ADD_SHA3 << 32 | ((op_version | LOAD_LENGTH_SHA3) & 0xFFFFFFFF);; // ENABLE_SHAKE
		writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	}
}

void sha3_shake_hw(unsigned char* in, unsigned char* out, unsigned int length, unsigned int length_out, int VERSION, int SIZE_BLOCK, int SIZE_SHA3, MMIO_WINDOW ms2xl, int DBG) {

	unsigned int hb_num;
	unsigned int hb_num_out;
	unsigned int pos_pad;
	unsigned int ind;
	int last_hb = 0;
	int shake = 0;

	unsigned long long int* buffer_in;
	unsigned long long int* buffer_out;

	buffer_in = malloc(sizeof(unsigned long long int) * (SIZE_BLOCK / 64));
	buffer_out = malloc(sizeof(unsigned long long int) * (SIZE_BLOCK / 64));

	unsigned char in_prev[1344 / 8];
	// memset(in_prev, 0, sizeof(unsigned char) * (1344 / 8));
	// in_prev = malloc(sizeof(unsigned char) * ((SIZE_BLOCK / 8) + 1));

	// ------- Number of hash blocks ----- //
	hb_num = (length / SIZE_BLOCK) + 1;
	hb_num_out = (length_out / SIZE_BLOCK) + 1;
	pos_pad = length % SIZE_BLOCK;

	if (DBG == 1) {
		printf("\n hb_num = %d \n", hb_num);
		printf("\n hb_num_out = %d \n", hb_num_out);
		printf("\n length = %d \n", length);
		printf("\n pos_pad = %d \n", pos_pad);
	}

	// ------- SHA3 Initialization --------//

	sha3_shake_ms2xl_init(ms2xl, VERSION);

	// ------- Operation ---------------- //

	for (unsigned int hb = 1; hb <= hb_num; hb++) {
		ind = (hb - 1) * (SIZE_BLOCK / 8);
		for (int j = 0; j < (SIZE_BLOCK / 8); j++) {
			if ((ind + j) >= (length / 8))	in_prev[j] = 0x00;
			else							in_prev[j] = in[ind + j];
		}
		// memcpy(in_prev, in + ind, sizeof(unsigned char) * (SIZE_BLOCK / 8));
		ind = 0;
		for (int i = 0; i < (SIZE_BLOCK / 64); i++) {
			/*
			if ((ind + 0) * 8 >= length) in_prev[ind + 0] = 0x00;
			if ((ind + 1) * 8 >= length) in_prev[ind + 1] = 0x00;
			if ((ind + 2) * 8 >= length) in_prev[ind + 2] = 0x00;
			if ((ind + 3) * 8 >= length) in_prev[ind + 3] = 0x00;
			if ((ind + 4) * 8 >= length) in_prev[ind + 4] = 0x00;
			if ((ind + 5) * 8 >= length) in_prev[ind + 5] = 0x00;
			if ((ind + 6) * 8 >= length) in_prev[ind + 6] = 0x00;
			if ((ind + 7) * 8 >= length) in_prev[ind + 7] = 0x00;

			buf_1 = ((unsigned long long int)in[ind + 7] << 56) + ((unsigned long long int)in[ind + 6] << 48) + ((unsigned long long int)in[ind + 5] << 40) + ((unsigned long long int)in[ind + 4] << 32);
			buf_2 = ((unsigned long long int)in[ind + 3] << 24) + ((unsigned long long int)in[ind + 2] << 16) + ((unsigned long long int)in[ind + 1] << 8) + ((unsigned long long int)in[ind + 0]);
			buffer_in[i] = buf_1 + buf_2;
			*/
			buffer_in[i] =
				((unsigned long long)(in_prev[ind + 7]) << 56) |
				((unsigned long long)(in_prev[ind + 6]) << 48) |
				((unsigned long long)(in_prev[ind + 5]) << 40) |
				((unsigned long long)(in_prev[ind + 4]) << 32) |
				((unsigned long long)(in_prev[ind + 3]) << 24) |
				((unsigned long long)(in_prev[ind + 2]) << 16) |
				((unsigned long long)(in_prev[ind + 1]) << 8) |
				((unsigned long long)(in_prev[ind + 0]) << 0);

			if (DBG == 1) printf("in[%d] = %02x \t in[%d] = %02x \t in[%d] = %02x \t in[%d] = %02x \n", ind, in_prev[ind], ind + 1, in_prev[ind + 1], ind + 2, in_prev[ind + 2], ind + 3, in_prev[ind + 3]);
			if (DBG == 1) printf("buffer_in[%d] = %02llx \n", i, buffer_in[i]);
			ind = ind + 8;
		}

		if (hb == hb_num)						last_hb = 1;
		else									last_hb = 0;

		if (length_out > SIZE_SHA3)				shake = 2;
		else									shake = 0;

		if (DBG == 1) {
			printf("\n last_hb = %d \n", last_hb);
		}

		sha3_shake_ms2xl(buffer_in, buffer_out, ms2xl, (pos_pad / 8), last_hb, shake, VERSION, SIZE_SHA3, SIZE_BLOCK, DBG); // shake = 0
	}

	// ------- Change Out Format --------- //
	if (hb_num_out > hb_num) {
		for (int i = 0; i < (SIZE_BLOCK / 64); i++) {
			ind = i * 8;
			out[ind + 0] = (buffer_out[i] & 0x00000000000000FF) >> 0;
			out[ind + 1] = (buffer_out[i] & 0x000000000000FF00) >> 8;
			out[ind + 2] = (buffer_out[i] & 0x0000000000FF0000) >> 16;
			out[ind + 3] = (buffer_out[i] & 0x00000000FF000000) >> 24;
			out[ind + 4] = (buffer_out[i] & 0x000000FF00000000) >> 32;
			out[ind + 5] = (buffer_out[i] & 0x0000FF0000000000) >> 40;
			out[ind + 6] = (buffer_out[i] & 0x00FF000000000000) >> 48;
			out[ind + 7] = (buffer_out[i] & 0xFF00000000000000) >> 56;
		}

		int hb_shake = 0;
		for (unsigned int hb = hb_num; hb < hb_num_out; hb++) {
			sha3_shake_ms2xl(buffer_in, buffer_out, ms2xl, (pos_pad / 8), last_hb, 1, VERSION, SIZE_SHA3, SIZE_BLOCK, DBG);
			hb_shake++;
			for (int i = 0; i < (SIZE_BLOCK / 64); i++) {
				ind = i * 8 + hb_shake * (SIZE_BLOCK / 8);
				out[ind + 0] = (buffer_out[i] & 0x00000000000000FF) >> 0;
				out[ind + 1] = (buffer_out[i] & 0x000000000000FF00) >> 8;
				out[ind + 2] = (buffer_out[i] & 0x0000000000FF0000) >> 16;
				out[ind + 3] = (buffer_out[i] & 0x00000000FF000000) >> 24;
				out[ind + 4] = (buffer_out[i] & 0x000000FF00000000) >> 32;
				out[ind + 5] = (buffer_out[i] & 0x0000FF0000000000) >> 40;
				out[ind + 6] = (buffer_out[i] & 0x00FF000000000000) >> 48;
				out[ind + 7] = (buffer_out[i] & 0xFF00000000000000) >> 56;
			}
		}
	}
	else {
		for (int i = 0; i < (int)ceil((double)length_out / (double)64); i++) {
			ind = i * 8;
			out[ind + 0] = (buffer_out[i] & 0x00000000000000FF) >> 0;
			out[ind + 1] = (buffer_out[i] & 0x000000000000FF00) >> 8;
			out[ind + 2] = (buffer_out[i] & 0x0000000000FF0000) >> 16;
			out[ind + 3] = (buffer_out[i] & 0x00000000FF000000) >> 24;
			out[ind + 4] = (buffer_out[i] & 0x000000FF00000000) >> 32;
			out[ind + 5] = (buffer_out[i] & 0x0000FF0000000000) >> 40;
			out[ind + 6] = (buffer_out[i] & 0x00FF000000000000) >> 48;
			out[ind + 7] = (buffer_out[i] & 0xFF00000000000000) >> 56;
		}
	}

}