
#include "demo.h"

void main() {
	// --- Loading bitstream --- //
	load_bitstream(0);
	MMIO_WINDOW ms2xl_se;
	createMMIOWindow(&ms2xl_se, MS2XL_BASEADDR, MS2XL_LENGTH);

	/*
	demo_sha3_hw(0, ms2xl_se);
	demo_sha2_hw(0, ms2xl_se);

	demo_aes(128, 0);	// Security level: 128
	demo_aes(192, 0);	// Security level: 192
	demo_aes(256, 0);	// Security level: 256

	demo_rsa(2048, 0);  // Security level: 112
	demo_rsa(3072, 0);  // Security level: 128
	demo_rsa(4096, 0);  // Security level: 152
	demo_rsa(6144, 0);  // Security level: 176
	demo_rsa(8192, 0);  // Security level: 200

	demo_eddsa(25519, 3, ms2xl_se);
	*/
	
	demo_x25519(3, ms2xl_se);

	/*
	demo_eddsa(448, 0);

	demo_sha2(0);


	demo_trng(128);
	demo_trng(256);
	demo_trng(512);
	demo_trng(1024);
	demo_trng(2048);

	demo_mlkem(512, 0);
	demo_mlkem(768, 0);
	demo_mlkem(1024, 0);
	*/

	printf("\n\n");
	closeMMIOWindow(&ms2xl_se);
}