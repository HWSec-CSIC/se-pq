
#include "demo.h"

void main() {
	uint64_t start_t, stop_t;

	//-- Initialize to avoid 1st measure error
	start_t = timeInMicroseconds();
	stop_t  = timeInMicroseconds();

	// --- Load Bitstream --- //
	load_bitstream(BITSTREAM_QUBIP);

	// --- Open MMIO Window --- //
	MMIO_WINDOW ms2xl_se;
	createMMIOWindow(&ms2xl_se, MS2XL_BASEADDR, MS2XL_LENGTH);

	/*
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
	*/
	
	// ---- EdDSA ---- //
	start_t = timeInMicroseconds();
	demo_eddsa_hw(25519, 0, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	/*
	// start_t = timeInMicroseconds();
	// demo_eddsa(448, 0);
	// stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/

	// ---- X25519 ---- //
	start_t = timeInMicroseconds();
	demo_x25519_hw(25519, 0, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	/*
	// ---- SHA2 ---- //
	start_t = timeInMicroseconds();
	demo_sha2(0);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/

	// ---- SHA3 ---- //
	start_t = timeInMicroseconds();
	demo_sha3_hw(0, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	
	// ---- TRNG ---- //
	start_t = timeInMicroseconds();
	demo_trng_hw(128, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng_hw(256, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng_hw(512, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng_hw(1024, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

	start_t = timeInMicroseconds();
	demo_trng_hw(2048, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	
	/*
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
	// --- Close MMIO Window --- //
	closeMMIOWindow(&ms2xl_se);
}