#include "../demo.h"
#include "test_func.h"

void demo_mlkem_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl) {
	
	if (mode == 512) {
		unsigned char *pk_512;
		unsigned char *sk_512;

		pk_512 = malloc(800);
		sk_512 = malloc(1632);

		mlkem512_genkeys_hw(pk_512, sk_512, ms2xl);

		if (verb >= 2) {
			printf("\n pk_512: \t");  show_array(pk_512, 800, 32);
			printf("\n sk_512: \t");  show_array(sk_512, 1632, 32);
		}

		unsigned char ss[32];
		unsigned char *ct_512;
		ct_512 = malloc(768);

		mlkem512_enc_hw(pk_512, ct_512, ss, ms2xl);

		if (verb >= 2) {
			printf("\n ct_512: \t");  show_array(ct_512, 768, 32);
		}

		unsigned char ss1[32];
		unsigned int result;

		mlkem512_dec_hw(sk_512, ct_512, ss1, &result, ms2xl);

		if (verb >= 1) {
			printf("\n ss original: \t");  show_array(ss, 32, 32);
			printf("\n ss recover: \t");   show_array(ss1, 32, 32);
		}

		if(!result) printf("\n MLKEM-512 Test: \u2705 VALID");
		else		printf("\n MLKEM-512 Test: \u274c FAIL");

		free(sk_512);
		free(pk_512);
		free(ct_512);
	
	}
	
	else if (mode == 768) {
		unsigned char* pk_768;
		unsigned char* sk_768;

		pk_768 = malloc(1184);
		sk_768 = malloc(2400);

		mlkem768_genkeys_hw(pk_768, sk_768, ms2xl);

		if (verb >= 2) {
			printf("\n pk_768: \t");  show_array(pk_768, 1184, 32);
			printf("\n sk_768: \t");  show_array(sk_768, 2400, 32);
		}

		unsigned char ss[32];
		unsigned char* ct_768;
		ct_768 = malloc(1088);

		mlkem768_enc_hw(pk_768, ct_768, ss, ms2xl);

		if (verb >= 2) {
			printf("\n ct_768: \t");  show_array(ct_768, 1088, 32);
		}

		unsigned char ss1[32];
		unsigned int result = 0;

		mlkem768_dec_hw(sk_768, ct_768, ss1, &result, ms2xl);

		if (verb >= 1) {
			printf("\n ss original: \t");  show_array(ss, 32, 32);
			printf("\n ss recover: \t");   show_array(ss1, 32, 32);
		}

		if (!result) printf("\n MLKEM-768 Test: \u2705 VALID");
		else		printf("\n MLKEM-768 Test: \u274c FAIL");

		free(sk_768);
		free(pk_768);
		free(ct_768);

	}
	else if (mode == 1024) {

		unsigned char* pk_1024;
		unsigned char* sk_1024;

		pk_1024 = malloc(1568);
		sk_1024 = malloc(3168);

		mlkem1024_genkeys_hw(pk_1024, sk_1024, ms2xl);

		if (verb >= 2) {
			printf("\n pk_1024: \t");  show_array(pk_1024, 1568, 32);
			printf("\n sk_1024: \t");  show_array(sk_1024, 3168, 32);
		}

		unsigned char ss[32];
		unsigned char* ct_1024;
		ct_1024 = malloc(1568);

		mlkem1024_enc_hw(pk_1024, ct_1024, ss, ms2xl);

		if (verb >= 2) {
			printf("\n ct_1024: \t");  show_array(ct_1024, 1568, 32);
		}

		unsigned char ss1[32];
		unsigned int result = 0;

		mlkem1024_dec_hw(sk_1024, ct_1024, ss1, &result, ms2xl);

		if (verb >= 1) {
			printf("\n ss original: \t");  show_array(ss, 32, 32);
			printf("\n ss recover: \t");   show_array(ss1, 32, 32);
		}

		if (!result) printf("\n MLKEM-1024 Test: \u2705 VALID");
		else		printf("\n MLKEM-1024 Test: \u274c FAIL");

		free(sk_1024);
		free(pk_1024);
		free(ct_1024);

	}
	

}