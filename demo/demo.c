/**
  * @file demo.c
  * @brief Validation Test code
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

	printf("\n\t ---- Test Evaluation --- ");
	printf("\n Configuration: ");
	printf("\n %-10s: ", "AES");		if (data_conf.aes)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "SHA3");		if (data_conf.sha3)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "SHA2");		if (data_conf.sha2)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "EdDSA");		if (data_conf.eddsa)	printf("yes"); else printf("no");
	printf("\n %-10s: ", "ECDH");		if (data_conf.ecdh)		printf("yes"); else printf("no");
	printf("\n %-10s: ", "MLKEM");		if (data_conf.mlkem)	printf("yes"); else printf("no");
	printf("\n %-10s: ", "DRBG");		if (data_conf.drbg)		printf("yes"); else printf("no");


	printf("\n\n %-30s | Result ", "Algorithm");
	printf("\n %-30s | ------ ", "---------");

	if (data_conf.aes) {
		demo_aes_hw(128, verb, interface);	// Security level: 128
		demo_aes_hw(192, verb, interface);	// Security level: 192
		demo_aes_hw(256, verb, interface);	// Security level: 256
	}

	if (data_conf.sha3) {
		demo_sha3_hw(verb, interface);
	}

	if (data_conf.sha2) {
		demo_sha2_hw(verb, interface);
	}

	if (data_conf.eddsa) {
		demo_eddsa_hw(25519, verb, interface);
	}

	if (data_conf.ecdh) {
		demo_x25519_hw(25519, verb, interface);
	}

	
	if (data_conf.mlkem) {
		demo_mlkem_hw(512, verb, interface);
		demo_mlkem_hw(768, verb, interface);
		demo_mlkem_hw(1024, verb, interface);
	}
	
	if (data_conf.drbg) {
		demo_trng_hw(128, verb, interface);
		demo_trng_hw(256, verb, interface);
		demo_trng_hw(512, verb, interface);
		demo_trng_hw(1024, verb, interface);
		demo_trng_hw(2048, verb, interface);
	}
	

	printf("\n\n");

	// --- Close Interface --- //
	close_INTF(interface);
}