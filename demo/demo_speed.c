
#include "demo.h"

void main() {
	uint64_t start_t, stop_t;

	//-- Initialize to avoid 1st measure error
	start_t = timeInMicroseconds();
	stop_t  = timeInMicroseconds();

	// --- Loading bitstream --- //
	load_bitstream(0);
	MMIO_WINDOW ms2xl_se;
	createMMIOWindow(&ms2xl_se, MS2XL_BASEADDR, MS2XL_LENGTH);

	// ---- SHA3 ---- //
	/*
	start_t = timeInMicroseconds();
	demo_sha3_hw(0, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));



	// ---- AES ---- //
	start_t = timeInMicroseconds();
	demo_aes(128, 0);	// Security level: 128
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t)/1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_aes(192, 0);	// Security level: 192
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_aes(256, 0);	// Security level: 256
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));


	// ---- RSA ---- //
	start_t = timeInMicroseconds();
	demo_rsa(2048, 0);  // Security level: 112
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_rsa(3072, 0);  // Security level: 128
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_rsa(4096, 0);  // Security level: 152
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_rsa(6144, 0);  // Security level: 176
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_rsa(8192, 0);  // Security level: 200
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	// ---- EdDSA ---- //

	start_t = timeInMicroseconds();
	demo_eddsa(25519, 0, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	// start_t = timeInMicroseconds();
	// demo_eddsa(448, 0);
	// stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/
	// ---- X25519 ---- //
	
	start_t = timeInMicroseconds();
	demo_x25519(0, ms2xl_se);
	stop_t = timeInMicroseconds();
	printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	/*
	// ---- SHA2 ---- //
	start_t = timeInMicroseconds();
	demo_sha2(0);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	// ---- SHA3 ---- //

	start_t = timeInMicroseconds();
	demo_sha3(0);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	// ---- TRNG ---- //

	start_t = timeInMicroseconds();
	demo_trng(128);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng(256);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng(512);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng(1024);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng(2048);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	// ---- MLKEM ---- //
	start_t = timeInMicroseconds();
	demo_mlkem(512, 0);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_mlkem(768, 0);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_mlkem(1024, 0);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/

	printf("\n\n");
	closeMMIOWindow(&ms2xl_se);
}