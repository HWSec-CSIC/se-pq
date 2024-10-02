/**
  * @file demo_speed.c
  * @brief Performance Test Code
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
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

	printf("\n\n %-30s | %-30s | %-30s | Validation Test ", "Algorithm", "Execution Time (ms)", "Execution Time (us)");
	printf("\n %-30s | %-30s | %-30s | --------------- ", "---------", "-------------------", "-------------------");

	if (data_conf.aes) {

		time_result tr_en;
		time_result tr_de;
		
		// 128
		test_aes_hw("ecb", 128, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-128-ECB", tr_en, tr_de);

		test_aes_hw("cbc", 128, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-128-CBC", tr_en, tr_de);

		test_aes_hw("cmac", 128, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_1(data_conf.n_test, "AES-128-CMAC", tr_en);
		
		test_aes_hw("gcm", 128, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-128-GCM", tr_en, tr_de);

		test_aes_hw("ccm", 128, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-128-CCM-8", tr_en, tr_de);
		
		// 192
		test_aes_hw("ecb", 192, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-ECB", tr_en, tr_de);

		test_aes_hw("cbc", 192, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-CBC", tr_en, tr_de);

		test_aes_hw("cmac", 192, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_1(data_conf.n_test, "AES-192-CMAC", tr_en);

		test_aes_hw("gcm", 192, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-GCM", tr_en, tr_de);

		test_aes_hw("ccm", 192, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-192-CCM-8", tr_en, tr_de);
		
		// 256
		test_aes_hw("ecb", 256, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-256-ECB", tr_en, tr_de);

		test_aes_hw("cbc", 256, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-256-CBC", tr_en, tr_de);

		test_aes_hw("cmac", 256, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_1(data_conf.n_test, "AES-256-CMAC", tr_en);
		
		test_aes_hw("gcm", 256, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-256-GCM", tr_en, tr_de);

		test_aes_hw("ccm", 256, data_conf.n_test, verb, &tr_en, &tr_de, interface);
		print_results_str_1_tab_2(data_conf.n_test, "AES-256-CCM-8", tr_en, tr_de);
		
	}
	else {
		printf("\n AES has not been selected ... Moving to next test ... ");
	}


	if (data_conf.sha3) {

		time_result tr;

		// test_sha3(4, data_conf.n_test, &tr, verb); // SHA3-224
		// print_results_str_1_tab_1(data_conf.n_test, "SHA3-224", tr);

		test_sha3_hw(0, data_conf.n_test, &tr, verb, interface); // SHA3-256
		print_results_str_1_tab_1(data_conf.n_test, "SHA3-256", tr);

		// test_sha3(5, data_conf.n_test, &tr, verb); // SHA3-384
		// print_results_str_1_tab_1(data_conf.n_test, "SHA3-384", tr);

		test_sha3_hw(1, data_conf.n_test, &tr, verb, interface); // SHA3-512
		print_results_str_1_tab_1(data_conf.n_test, "SHA3-512", tr);

		test_sha3_hw(2, data_conf.n_test, &tr, verb, interface); // SHAKE-128
		print_results_str_1_tab_1(data_conf.n_test, "SHAKE-128", tr);

		test_sha3_hw(3, data_conf.n_test, &tr, verb, interface); // SHAKE-256
		print_results_str_1_tab_1(data_conf.n_test, "SHAKE-256", tr);

	}
	else {
		printf("\n SHA3 has not been selected ... Moving to next test ... ");
	}

	if (data_conf.sha2) {

		time_result tr;

		// test_sha2(4, data_conf.n_test, &tr, verb); // SHA-224
		// print_results_str_1_tab_1(data_conf.n_test, "SHA-224", tr);

		test_sha2_hw(0, data_conf.n_test, &tr, verb, interface); // SHA-256
		print_results_str_1_tab_1(data_conf.n_test, "SHA-256", tr);

		test_sha2_hw(1, data_conf.n_test, &tr, verb, interface); // SHA-384
		print_results_str_1_tab_1(data_conf.n_test, "SHA-384", tr);

		test_sha2_hw(2, data_conf.n_test, &tr, verb, interface); // SHA-512
		print_results_str_1_tab_1(data_conf.n_test, "SHA-512", tr);

		// test_sha2(5, data_conf.n_test, &tr, verb); // SHA-512/224
		// print_results_str_1_tab_1(data_conf.n_test, "SHA-512/224", tr);

		test_sha2_hw(3, data_conf.n_test, &tr, verb, interface); // SHA-512/256
		print_results_str_1_tab_1(data_conf.n_test, "SHA-512/256", tr);

	}
	else {
		printf("\n SHA2 has not been selected ... Moving to next test ... ");
	}

	if (data_conf.eddsa) {

		time_result tr_kg;
		time_result tr_si;
		time_result tr_ve;

		test_eddsa_hw(25519, data_conf.n_test, verb, &tr_kg, &tr_si, &tr_ve, interface);
		print_results_str_1_tab_3(data_conf.n_test, "EdDSA-25519", tr_kg, tr_si, tr_ve);

		// test_eddsa(448, data_conf.n_test, verb, &tr_kg, &tr_si, &tr_ve);
		// print_results_str_1_tab_3(data_conf.n_test, "EdDSA-448", tr_kg, tr_si, tr_ve);

	}
	else {
		printf("\n EDDSA has not been selected ... Moving to next test ... ");
	}

	if (data_conf.ecdh) {

		time_result tr_kg;
		time_result tr_ss;

		test_x25519_hw(25519, data_conf.n_test, verb, &tr_kg, &tr_ss, interface);
		print_results_str_1_tab_2(data_conf.n_test, "X25519", tr_kg, tr_ss);

		// test_x25519(448, data_conf.n_test, verb, &tr_kg, &tr_ss);
		// print_results_str_1_tab_2(data_conf.n_test, "X448", tr_kg, tr_ss);

	}
	else {
		printf("\n ECDH has not been selected ... Moving to next test ... ");
	}

	if (data_conf.mlkem) {

		time_result tr_kg;
		time_result tr_en;
		time_result tr_de;

		test_mlkem_hw(512, data_conf.n_test, verb, &tr_kg, &tr_en, &tr_de, interface);
		print_results_str_1_tab_3(data_conf.n_test, "MLKEM-512", tr_kg, tr_en, tr_de);

		test_mlkem_hw(768, data_conf.n_test, verb, &tr_kg, &tr_en, &tr_de, interface);
		print_results_str_1_tab_3(data_conf.n_test, "MLKEM-768", tr_kg, tr_en, tr_de);

		test_mlkem_hw(1024, data_conf.n_test, verb, &tr_kg, &tr_en, &tr_de, interface);
		print_results_str_1_tab_3(data_conf.n_test, "MLKEM-1024", tr_kg, tr_en, tr_de);
	}
	else {
		printf("\n MLKEM has not been selected ... Moving to next test ... ");
	}


	if (data_conf.drbg) {

		time_result tr;

		test_trng_hw(0, 128, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "TRNG", "128 bits", tr);
		// test_trng_hw(1, 128, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "128 bits", tr);
		// test_trng_hw(2, 128, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "128 bits", tr);

		test_trng_hw(0, 256, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "TRNG", "256 bits", tr);
		// test_trng_hw(1, 256, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "256 bits", tr);
		// test_trng_hw(2, 256, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "256 bits", tr);

		test_trng_hw(0, 512, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "TRNG", "512 bits", tr);
		// test_trng_hw(1, 512, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "512 bits", tr);
		// test_trng_hw(2, 512, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "512 bits", tr);

		test_trng_hw(0, 1024, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "TRNG", "1024 bits", tr);
		// test_trng_hw(1, 1024, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "CTR-DRBG", "1024 bits", tr);
		// test_trng_hw(2, 1024, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "HMAC-DRBG", "1024 bits", tr);

		test_trng_hw(0, 2048, data_conf.n_test, &tr, verb, interface); print_results_str_2_tab_1(data_conf.n_test, "TRNG", "2048 bits", tr);
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