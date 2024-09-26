/**
  * @file demo_speed.c
  * @brief Performance Test code
  *
  * @section License
  *
  * MIT License
  *
  * Copyright (c) 2024 Eros Camacho
  *
  * Permission is hereby granted, free of charge, to any person obtaining a copy
  * of this software and associated documentation files (the "Software"), to deal
  * in the Software without restriction, including without limitation the rights
  * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  * copies of the Software, and to permit persons to whom the Software is
  * furnished to do so, subject to the following conditions:
  *
  * The above copyright notice and this permission notice shall be included in all
  * copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  * SOFTWARE.
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 4.0
  **/

#include "src/demo.h"
#include "src/test_func.h"

void main(int argc, char** argv) {

	print_title_demo();

	int verb = 0;

	for (int arg = 1; arg < argc; arg++) {

		if (argv[arg][0] == '-') {
			if (argv[arg][1] == 'h') {
				printf("\n Usage: ./demo-XXX-YYY [-h] [-v] [-vv] \n");
				printf("\n -h  : Show the help.");
				printf("\n -v  : Verbose level 1");
				printf("\n -vv : Verbose level 2");
				printf("\n \n");

				return;
			}
			else if (argv[arg][1] == 'v') {
				if (argv[arg][2] == 'v') verb = 3;
				else verb = 1;
			}
			else {
				printf("\n Unknow option: %s\n", argv[arg]);

				return;
			}
		}
	}

	// --- Open Interface --- //
	INTF interface;
	open_INTF(&interface, INTF_ADDRESS, INTF_LENGTH);

#ifdef AXI
	// --- Loading Bitstream --- //
	load_bitstream(BITSTREAM_AXI);
#endif

	data_conf data_conf;

	read_conf(&data_conf);

	printf("\n\t ---- Performance Evaluation --- ");
	printf("\n Configuration: ");
	printf("\n %-10s: ", "AES");		if (data_conf.aes)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "SHA3");		if (data_conf.sha3)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "SHA2");		if (data_conf.sha2)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "EdDSA");		if (data_conf.eddsa)	printf("yes"); else printf("no");
	printf("\n %-10s: ", "ECDH");		if (data_conf.ecdh)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "MLKEM");		if (data_conf.mlkem)	printf("yes"); else printf("no");
	printf("\n %-10s: ", "DRBG");		if (data_conf.drbg)		printf("yes"); else printf("no");
	printf("\n Number of Tests: \t%d\n", data_conf.n_test);

	printf("\n\n %-30s | %-30s | %-30s | %-30s | Validation Test ", "Algorithm", "HW Execution Time (us)", "SW Execution Time (us)", "Acceleration (x)");
	printf("\n %-30s | %-30s | %-30s | %-30s | --------------- ",	"---------", "----------------------", "----------------------", "----------------");

	if (data_conf.aes) {

		time_result tr_en_hw;
		time_result tr_en_sw;
		time_result tr_de_hw;
		time_result tr_de_sw;

		// 128
		test_aes_acc("ecb", 128, data_conf.n_test, verb, &tr_en_hw, &tr_de_hw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_2_acc(data_conf.n_test, "AES-128-ECB", tr_en_hw, tr_de_hw, tr_en_sw, tr_de_sw);

		test_aes_acc("cbc", 128, data_conf.n_test, verb, &tr_en_hw, &tr_de_hw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_2_acc(data_conf.n_test, "AES-128-CBC", tr_en_hw, tr_de_hw, tr_en_sw, tr_de_sw);

		test_aes_acc("cmac", 128, data_conf.n_test, verb, &tr_en_hw, &tr_de_hw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_1_acc(data_conf.n_test, "AES-128-CMAC", tr_en_hw, tr_en_sw);

		/*
		test_aes("gcm", 128, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-128-GCM", tr_en, tr_de);

		test_aes("ccm", 128, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-128-CCM-8", tr_en, tr_de);

		// 192
		test_aes("ecb", 192, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-ECB", tr_en, tr_de);

		test_aes("cbc", 192, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-CBC", tr_en, tr_de);

		test_aes("cmac", 192, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_1(data_conf.n_test, "AES-192-CMAC", tr_en);

		test_aes("gcm", 192, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-GCM", tr_en, tr_de);

		test_aes("ccm", 192, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-CCM-8", tr_en, tr_de);
		*/
		// 256
		test_aes_acc("ecb", 256, data_conf.n_test, verb, &tr_en_hw, &tr_de_hw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_2_acc(data_conf.n_test, "AES-256-ECB", tr_en_hw, tr_de_hw, tr_en_sw, tr_de_sw);

		test_aes_acc("cbc", 256, data_conf.n_test, verb, &tr_en_hw, &tr_de_hw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_2_acc(data_conf.n_test, "AES-256-CBC", tr_en_hw, tr_de_hw, tr_en_sw, tr_de_sw);

		test_aes_acc("cmac", 256, data_conf.n_test, verb, &tr_en_hw, &tr_de_hw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_1_acc(data_conf.n_test, "AES-256-CMAC", tr_en_hw, tr_en_sw);
		/*
		test_aes("gcm", 256, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-256-GCM", tr_en, tr_de);

		test_aes("ccm", 256, data_conf.n_test, verb, &tr_en, &tr_de);
		print_results_str_1_tab_2(data_conf.n_test, "AES-256-CCM-8", tr_en, tr_de);
		*/
	}
	else {
		printf("\n AES has not been selected ... Moving to next test ... ");
	}


	if (data_conf.sha3) {

		time_result tr_hw;
		time_result tr_sw;

		// test_sha3(4, data_conf.n_test, &tr, verb); // SHA3-224
		// print_results_str_1_tab_1(data_conf.n_test, "SHA3-224", tr);

		test_sha3_acc(0, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHA3-256
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHA3-256", tr_hw, tr_sw);

		// test_sha3(5, data_conf.n_test, &tr, verb); // SHA3-384
		// print_results_str_1_tab_1(data_conf.n_test, "SHA3-384", tr);

		test_sha3_acc(1, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHA3-512
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHA3-512", tr_hw, tr_sw);

		test_sha3_acc(2, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHAKE-128
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHAKE-128", tr_hw, tr_sw);

		test_sha3_acc(3, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHAKE-256
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHAKE-256", tr_hw, tr_sw);

	}
	else {
		printf("\n SHA3 has not been selected ... Moving to next test ... ");
	}

	if (data_conf.sha2) {

		time_result tr_hw;
		time_result tr_sw;

		// test_sha2(4, data_conf.n_test, &tr, verb); // SHA-224
		// print_results_str_1_tab_1(data_conf.n_test, "SHA-224", tr);

		test_sha2_acc(0, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHA-256
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHA-256", tr_hw, tr_sw);

		test_sha2_acc(1, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHA-384
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHA-384", tr_hw, tr_sw);
		
		test_sha2_acc(2, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHA-512
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHA-512", tr_hw, tr_sw);

		// test_sha2(5, data_conf.n_test, &tr, verb); // SHA-512/224
		// print_results_str_1_tab_1(data_conf.n_test, "SHA-512/224", tr);

		test_sha2_acc(3, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); // SHA-512/256
		print_results_str_1_tab_1_acc(data_conf.n_test, "SHA-512/256", tr_hw, tr_sw);

	}
	else {
		printf("\n SHA2 has not been selected ... Moving to next test ... ");
	}

	if (data_conf.eddsa) {

		time_result tr_kg_hw;
		time_result tr_si_hw;
		time_result tr_ve_hw;
		time_result tr_kg_sw;
		time_result tr_si_sw;
		time_result tr_ve_sw;

		test_eddsa_acc(25519, data_conf.n_test, verb, &tr_kg_hw, &tr_si_hw, &tr_ve_hw, &tr_kg_sw, &tr_si_sw, &tr_ve_sw, interface);
		print_results_str_1_tab_3_acc(data_conf.n_test, "EdDSA-25519", tr_kg_hw, tr_si_hw, tr_ve_hw, tr_kg_sw, tr_si_sw, tr_ve_sw);

		// test_eddsa(448, data_conf.n_test, verb, &tr_kg, &tr_si, &tr_ve);
		// print_results_str_1_tab_3(data_conf.n_test, "EdDSA-448", tr_kg, tr_si, tr_ve);

	}
	else {
		printf("\n EDDSA has not been selected ... Moving to next test ... ");
	}

	if (data_conf.ecdh) {

		time_result tr_kg_hw;
		time_result tr_ss_hw;
		time_result tr_kg_sw;
		time_result tr_ss_sw;

		test_x25519_acc(25519, data_conf.n_test, verb, &tr_kg_hw, &tr_ss_hw, &tr_kg_sw, &tr_ss_sw, interface);
		print_results_str_1_tab_2_acc(data_conf.n_test, "X25519", tr_kg_hw, tr_ss_hw, tr_kg_sw, tr_ss_sw);

		// test_x25519(448, data_conf.n_test, verb, &tr_kg, &tr_ss);
		// print_results_str_1_tab_2(data_conf.n_test, "X448", tr_kg, tr_ss);

	}
	else {
		printf("\n ECDH has not been selected ... Moving to next test ... ");
	}

	if (data_conf.mlkem) {

		time_result tr_kg_hw;
		time_result tr_en_hw;
		time_result tr_de_hw;


		time_result tr_kg_sw;
		time_result tr_en_sw;
		time_result tr_de_sw;

		test_mlkem_acc(512, data_conf.n_test, verb, &tr_kg_hw, &tr_en_hw, &tr_de_hw, &tr_kg_sw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_3_acc(data_conf.n_test, "MLKEM-512", tr_kg_hw, tr_en_hw, tr_de_hw, tr_kg_sw, tr_en_sw, tr_de_sw);

		test_mlkem_acc(768, data_conf.n_test, verb, &tr_kg_hw, &tr_en_hw, &tr_de_hw, &tr_kg_sw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_3_acc(data_conf.n_test, "MLKEM-768", tr_kg_hw, tr_en_hw, tr_de_hw, tr_kg_sw, tr_en_sw, tr_de_sw);

		test_mlkem_acc(1024, data_conf.n_test, verb, &tr_kg_hw, &tr_en_hw, &tr_de_hw, &tr_kg_sw, &tr_en_sw, &tr_de_sw, interface);
		print_results_str_1_tab_3_acc(data_conf.n_test, "MLKEM-1024", tr_kg_hw, tr_en_hw, tr_de_hw, tr_kg_sw, tr_en_sw, tr_de_sw);
	}
	else {
		printf("\n MLKEM has not been selected ... Moving to next test ... ");
	}


	if (data_conf.drbg) {

		time_result tr_hw;
		time_result tr_sw;

		test_trng_acc(0, 128, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); print_results_str_2_tab_1_acc(data_conf.n_test, "TRNG", "128 bits", tr_hw, tr_sw);
		// test_trng_hw(1, 128, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "128 bits", tr);
		// test_trng_hw(2, 128, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "128 bits", tr);

		test_trng_acc(0, 256, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); print_results_str_2_tab_1_acc(data_conf.n_test, "TRNG", "256 bits", tr_hw, tr_sw);
		// test_trng_hw(1, 256, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "256 bits", tr);
		// test_trng_hw(2, 256, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "256 bits", tr);

		test_trng_acc(0, 512, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); print_results_str_2_tab_1_acc(data_conf.n_test, "TRNG", "512 bits", tr_hw, tr_sw);
		// test_trng_hw(1, 512, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "512 bits", tr);
		// test_trng_hw(2, 512, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "512 bits", tr);

		test_trng_acc(0, 1024, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); print_results_str_2_tab_1_acc(data_conf.n_test, "TRNG", "1024 bits", tr_hw, tr_sw);
		// test_trng_hw(1, 1024, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "1024 bits", tr);
		// test_trng_hw(2, 1024, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "1024 bits", tr);

		test_trng_acc(0, 2048, data_conf.n_test, &tr_hw, &tr_sw, verb, interface); print_results_str_2_tab_1_acc(data_conf.n_test, "TRNG", "2048 bits", tr_hw, tr_sw);
		// test_trng_hw(1, 2048, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "2048 bits", tr);
		// test_trng_hw(2, 2048, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "2048 bits", tr);
	}
	else {
		printf("\n TRNG has not been selected ... Moving to next test ... ");
	}


	printf("\n\n");

	// --- Close Interface --- //
	close_INTF(interface);
}