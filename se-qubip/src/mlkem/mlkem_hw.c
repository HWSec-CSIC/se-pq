#include "mlkem_hw.h"

void mlkem_512_gen_keys_hw(unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl) {

	mlkem_gen_keys_hw(2, pk, sk, ms2xl);
	for (int i = 0; i < 800; i++)
		sk[i + 768] = pk[i];

	sha3_256_hw(pk, 800, sk + 1568, ms2xl);

	trng_hw(sk + 1568 + 32, 32, ms2xl);
}
void mlkem_768_gen_keys_hw(unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl) {

	mlkem_gen_keys_hw(3, pk, sk, ms2xl);
	for (int i = 0; i < 1184; i++)
		sk[i + 1152] = pk[i];

	sha3_256_hw(pk, 1184, sk + 2336, ms2xl);

	trng_hw(sk + 2336 + 32, 32, ms2xl);

}
void mlkem_1024_gen_keys_hw(unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl) {

	mlkem_gen_keys_hw(4, pk, sk, ms2xl);
	for (int i = 0; i < 1568; i++)
		sk[i + 1536] = pk[i];

	sha3_256_hw(pk, 1568, sk + 3104, ms2xl);

	trng_hw(sk + 3104 + 32, 32, ms2xl);

}

void mlkem_512_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl) {

	unsigned char buf[64];
	unsigned char kr[64];

	trng_hw(buf, 32, ms2xl);
	sha3_256_hw(pk, 800, buf + 32, ms2xl);
	sha3_512_hw(buf, 64, kr, ms2xl);

	mlkem_enc_coins_hw(2, pk, ct, buf, kr + 32, ms2xl);

	memcpy(ss, buf, 32);

}
void mlkem_768_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl) {

	unsigned char buf[64];
	unsigned char kr[64];

	trng_hw(buf, 32, ms2xl);
	sha3_256_hw(pk, 1184, buf + 32, ms2xl);
	sha3_512_hw(buf, 64, kr, ms2xl);

	mlkem_enc_coins_hw(3, pk, ct, buf, kr + 32, ms2xl);

	memcpy(ss, buf, 32);

}
void mlkem_1024_enc_hw(unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl) {

	unsigned char buf[64];
	unsigned char kr[64];

	trng_hw(buf, 32, ms2xl);
	sha3_256_hw(pk, 1568, buf + 32, ms2xl);
	sha3_512_hw(buf, 64, kr, ms2xl);

	mlkem_enc_coins_hw(4, pk, ct, buf, kr + 32, ms2xl);

	memcpy(ss, buf, 32);

}

void mlkem_512_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, MMIO_WINDOW ms2xl) {

	unsigned char buf[64];
	unsigned char kr[64];

	unsigned char cmp[768];
	unsigned char* pk = sk + 768;

	mlkem_dec_hw(2, sk, ct, buf, ms2xl);
	for (int i = 0; i < 32; i++)
		buf[i + 32] = sk[1568 + i];

	sha3_512_hw(buf, 64, kr, ms2xl);

	mlkem_enc_coins_hw(2, pk, cmp, buf, kr + 32, ms2xl);

	*result = memcmp(ct, cmp, 768);

	memcpy(ss, buf, 32);
	
}
void mlkem_768_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, MMIO_WINDOW ms2xl) {

	unsigned char buf[64];
	unsigned char kr[64];

	unsigned char cmp[1088];
	unsigned char* pk = sk + 1152;

	mlkem_dec_hw(3, sk, ct, buf, ms2xl);
	for (int i = 0; i < 32; i++)
		buf[i + 32] = sk[2336 + i];

	sha3_512_hw(buf, 64, kr, ms2xl);

	mlkem_enc_coins_hw(3, pk, cmp, buf, kr + 32, ms2xl);

	*result = memcmp(ct, cmp, 1088);

	memcpy(ss, buf, 32);

}
void mlkem_1024_dec_hw(unsigned char* sk, unsigned char* ct, unsigned char* ss, unsigned int* result, MMIO_WINDOW ms2xl) {

	unsigned char buf[64];
	unsigned char kr[64];

	unsigned char cmp[1568];
	unsigned char* pk = sk + 1536;

	mlkem_dec_hw(4, sk, ct, buf, ms2xl);
	for (int i = 0; i < 32; i++)
		buf[i + 32] = sk[3104 + i];

	sha3_512_hw(buf, 64, kr, ms2xl);

	mlkem_enc_coins_hw(4, pk, cmp, buf, kr + 32, ms2xl);

	*result = memcmp(ct, cmp, 1568);

	memcpy(ss, buf, 32);

}

void mlkem_gen_keys_hw(int k, unsigned char* pk, unsigned char* sk, MMIO_WINDOW ms2xl) {
	
	unsigned long long int op;
	unsigned long long int op_mode;

	if (k == 2)				op_mode = GEN_KEYS_512	<< 4; 
	else if (k == 3)		op_mode = GEN_KEYS_768	<< 4; 
	else if (k == 4)		op_mode = GEN_KEYS_1024 << 4; 
	else					op_mode = GEN_KEYS_512	<< 4;

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | RESET) & 0xFFFFFFFF);
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | START) & 0xFFFFFFFF);
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	unsigned long long int end_op = 0;
	// wait END_OP
	while (!end_op) readMMIO(&ms2xl, &end_op, END_OP, sizeof(unsigned long long int));

	// read pk
	unsigned long long int reg_addr;
	unsigned long long int reg_data_out;

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | READ_PK) & 0xFFFFFFFF);; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < (k * 384); i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
		pk[i] = reg_data_out & 0xFF;
	}

	int ind = k*384;

	for (int i = (4*384); i < (4 * 384) + 16; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));

		pk[ind]		= reg_data_out & 0x00FF;
		pk[ind + 1] = (reg_data_out & 0xFF00) >> 8;

		ind += 2;
	}

	// read sk
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | READ_SK) & 0xFFFFFFFF);; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < (k * 384); i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
		sk[i] = reg_data_out & 0xFF;
	}


}

void mlkem_enc_hw(int k, unsigned char* pk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl) {

	unsigned long long int op;
	unsigned long long int op_mode;

	unsigned long long int reg_addr;
	unsigned long long int reg_data_out;
	unsigned long long int reg_data_in;

	if (k == 2)				op_mode = ENCAP_512		<< 4;
	else if (k == 3)		op_mode = ENCAP_768		<< 4;
	else if (k == 4)		op_mode = ENCAP_1024	<< 4;
	else					op_mode = ENCAP_512		<< 4;

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | RESET) & 0xFFFFFFFF); // RESET ON
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	// load_pk
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | LOAD_PK) & 0xFFFFFFFF);  // START 
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < (4 * 384); i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		if (i < k * 384)	reg_data_in = (unsigned long long int)(pk[i]);
		else				reg_data_in = 0;
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
	}

	int ind = k * 384;

	for (int i = (4 * 384); i < (4 * 384) + 16; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		reg_data_in = (unsigned long long int)(pk[ind+1] << 8 | pk[ind]);
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));

		ind += 2;
	}

	// start
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | START) & 0xFFFFFFFF); // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	unsigned long long int end_op = 0;
	// wait END_OP
	while (!end_op) readMMIO(&ms2xl, &end_op, END_OP, sizeof(unsigned long long int));

	// read ct
	unsigned int i_end;

	if (k == 4) i_end = (k * 352 + 160);
	else		i_end = (k * 320 + 128);

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | READ_CT) & 0xFFFFFFFF); // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < i_end; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
		// printf("\n %lld %llx", reg_addr, reg_data_out);
		ct[i] = reg_data_out & 0xFF;
	}

	// read ss
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | READ_SS) & 0xFFFFFFFF); // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < 32; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
		ss[i] = reg_data_out & 0xFF;
	}

}

void mlkem_enc_coins_hw(int k, unsigned char* pk, unsigned char* ct, unsigned char* ss, unsigned char* coins, MMIO_WINDOW ms2xl) {

	unsigned long long int op;
	unsigned long long int op_mode;

	unsigned long long int reg_addr;
	unsigned long long int reg_data_out;
	unsigned long long int reg_data_in;

	if (k == 2)				op_mode = ENCAP_512 << 4;
	else if (k == 3)		op_mode = ENCAP_768 << 4;
	else if (k == 4)		op_mode = ENCAP_1024 << 4;
	else					op_mode = ENCAP_512 << 4;

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | RESET) & 0xFFFFFFFF); // RESET ON
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	// load_pk
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | LOAD_PK) & 0xFFFFFFFF);  // START 
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < (4 * 384); i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		if (i < k * 384)	reg_data_in = (unsigned long long int)(pk[i]);
		else				reg_data_in = 0;
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
	}

	int ind = k * 384;

	for (int i = (4 * 384); i < (4 * 384) + 16; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		reg_data_in = (unsigned long long int)(pk[ind + 1] << 8 | pk[ind]);
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));

		ind += 2;
	}

	// load ss
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | LOAD_SS) & 0xFFFFFFFF);  // START 
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < 32; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		reg_data_in = (unsigned long long int)(ss[i]);
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
	}

	// load coins
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | LOAD_COINS) & 0xFFFFFFFF);  // START 
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < 32; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		reg_data_in = (unsigned long long int)(coins[i]);
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
	}

	// start
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | START) & 0xFFFFFFFF); // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	unsigned long long int end_op = 0;
	// wait END_OP
	while (!end_op) readMMIO(&ms2xl, &end_op, END_OP, sizeof(unsigned long long int));

	// read ct
	unsigned int i_end;

	if (k == 4) i_end = (k * 352 + 160);
	else		i_end = (k * 320 + 128);

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | READ_CT) & 0xFFFFFFFF); // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < i_end; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
		// printf("\n %lld %llx", reg_addr, reg_data_out);
		ct[i] = reg_data_out & 0xFF;
	}

}

void mlkem_dec_hw(int k, unsigned char* sk, unsigned char* ct, unsigned char* ss, MMIO_WINDOW ms2xl) {

	unsigned long long int op;
	unsigned long long int op_mode;
	unsigned long long int reg_addr;
	unsigned long long int reg_data_out;
	unsigned long long int reg_data_in;

	if (k == 2)				op_mode = DECAP_512 << 4;
	else if (k == 3)		op_mode = DECAP_768 << 4;
	else if (k == 4)		op_mode = DECAP_1024 << 4;
	else					op_mode = DECAP_512 << 4;

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | RESET) & 0xFFFFFFFF);; // RESET ON
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	// load_sk
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | LOAD_SK) & 0xFFFFFFFF);; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < (k * 384); i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		if (i < k * 384)	reg_data_in = (unsigned long long int)(sk[i]);
		else				reg_data_in = 0;
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
	}

	// load_ct
	unsigned int i_end;

	if (k == 4) i_end = (k * 352 + 160);
	else		i_end = (k * 320 + 128);

	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | LOAD_CT) & 0xFFFFFFFF);; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < i_end; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		reg_data_in = (unsigned long long int)(ct[i]);
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned long long int));
	}

	// start
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | START) & 0xFFFFFFFF);; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	unsigned long long int end_op = 0;
	// wait END_OP
	while (!end_op) readMMIO(&ms2xl, &end_op, END_OP, sizeof(unsigned long long int));

	// read ss
	op = (unsigned long long int)ADD_MLKEM << 32 | ((op_mode | READ_SS) & 0xFFFFFFFF);; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(unsigned long long int));

	for (int i = 0; i < 32; i++) {
		reg_addr = (unsigned long long int)(i);
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned long long int));
		readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(unsigned long long int));
		// printf("\n %llx", reg_data_out);
		ss[i] = reg_data_out & 0xFF;
	}

}
