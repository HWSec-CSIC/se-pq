
#include "demo.h"


void main() {

	// --- Load Bitstream --- //
	load_bitstream(BITSTREAM_QUBIP);

	// --- Open MMIO Window --- //
	MMIO_WINDOW ms2xl_se;
	createMMIOWindow(&ms2xl_se, MS2XL_BASEADDR, MS2XL_LENGTH);

	data_conf data_conf;

	read_conf(&data_conf);

	printf("\n\t ---- Perfomance Evaluation --- ");
	printf("\n Configuration: ");
	printf("\n SHA3: \t\t");		if (data_conf.sha3)		printf("yes"); else printf("no");
	printf("\n SHA2: \t\t");		if (data_conf.sha2)		printf("yes"); else printf("no");
	printf("\n EdDSA-25519: \t");	if (data_conf.eddsa)	printf("yes"); else printf("no");
	printf("\n X25519: \t");		if (data_conf.x25519)	printf("yes"); else printf("no");
	printf("\n MLKEM: \t");			if (data_conf.mlkem)	printf("yes"); else printf("no");
	printf("\n TRNG: \t\t");		if (data_conf.trng)		printf("yes"); else printf("no");
	printf("\n Number of Tests: \t%d\n", data_conf.n_test);

	if (data_conf.sha3) {

		time_result tr;

		test_sha3(0, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_sha3(1, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_sha3(2, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_sha3(3, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);
	}
	else {
		printf("\n\n SHA3 has not been selected ... Moving to next test ... \n\n");
	}

	if (data_conf.sha2) {

		time_result tr;

		test_sha2(0, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_sha2(1, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_sha2(2, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_sha2(3, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);
	}
	else {
		printf("\n\n SHA2 has not been selected ... Moving to next test ... \n\n");
	}

	if (data_conf.eddsa) {

		#ifdef PYNQZ2  
		load_bitstream(BITSTREAM_QUBIP_EDDSA);
		#endif

		time_result tr_kg;
		time_result tr_si;
		time_result tr_ve;

		test_eddsa(25519, data_conf.n_test, 0, &tr_kg, &tr_si, &tr_ve, ms2xl_se);
		printf("\n ->>> Key Generation");
		print_results(0, 0, tr_kg);
		printf("\n ->>> Signature");
		print_results(0, 0, tr_si);
		printf("\n ->>> Verification");
		print_results(0, data_conf.n_test, tr_ve);

		#ifdef PYNQZ2 
				load_bitstream(BITSTREAM_QUBIP);
		#endif
	}
	else {
		printf("\n\n EDDSA has not been selected ... Moving to next test ... \n\n");
	}

	if (data_conf.mlkem) {

		time_result tr_kg;
		time_result tr_en;
		time_result tr_de;

		test_mlkem(512, data_conf.n_test, 0, &tr_kg, &tr_en, &tr_de, ms2xl_se);
		printf("\n ->>> Key Generation");
		print_results(0, 0, tr_kg);
		printf("\n ->>> Encapsulation");
		print_results(0, 0, tr_en);
		printf("\n ->>> Decapsulation");
		print_results(0, data_conf.n_test, tr_de);

		test_mlkem(768, data_conf.n_test, 0, &tr_kg, &tr_en, &tr_de, ms2xl_se);
		printf("\n ->>> Key Generation");
		print_results(0, 0, tr_kg);
		printf("\n ->>> Encapsulation");
		print_results(0, 0, tr_en);
		printf("\n ->>> Decapsulation");
		print_results(0, data_conf.n_test, tr_de);

		test_mlkem(1024, data_conf.n_test, 0, &tr_kg, &tr_en, &tr_de, ms2xl_se);
		printf("\n ->>> Key Generation");
		print_results(0, 0, tr_kg);
		printf("\n ->>> Encapsulation");
		print_results(0, 0, tr_en);
		printf("\n ->>> Decapsulation");
		print_results(0, data_conf.n_test, tr_de);
	}
	else {
		printf("\n\n MLKEM has not been selected ... Moving to next test ... \n\n");
	}

	if (data_conf.trng) {

		time_result tr;

		test_trng(64, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_trng(128, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_trng(256, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_trng(512, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_trng(1024, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_trng(2048, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);

		test_trng(4092, data_conf.n_test, &tr, 0, ms2xl_se);
		print_results(0, data_conf.n_test, tr);
	}
	else {
		printf("\n\n TRNG has not been selected ... Moving to next test ... \n\n");
	}

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
	/*
	start_t = timeInMicroseconds();
	demo_eddsa_hw(25519, 0, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/

	/*
	// start_t = timeInMicroseconds();
	// demo_eddsa(448, 0);
	// stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/

	// ---- X25519 ---- //
	/*
	start_t = timeInMicroseconds();
	demo_x25519_hw(25519, 0, ms2xl_se);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/

	/*
	// ---- SHA2 ---- //
	start_t = timeInMicroseconds();
	demo_sha2(0);
	stop_t = timeInMicroseconds(); printf("\t ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));
	*/
	
	/*
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
	*/

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