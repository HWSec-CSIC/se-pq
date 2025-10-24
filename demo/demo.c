/**
  * @file demo.c
  * @brief SEQUBIP Validation Test Code
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

	// --- Is it already programmed? --- //
	bool is_dev_prog = false;
	uint64_t control = 0;
    // read_INTF(interface, &control, PICORV32_CONTROL, AXI_BYTES);
	if (control == CMD_SE_CODE) is_dev_prog = true;

#ifdef AXI
	// --- Loading Bitstream --- //
	if (!is_dev_prog) 
	{
		// printf("\n\nPROGRAMMING DEVICE...\n\n");
		load_bitstream(BITSTREAM_AXI);
	}
	unsigned int clk_index = 0;
	float clk_frequency;
	float set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int) verb);
#endif

	// --- Load PICORV32 Program --- // 
	if (!is_dev_prog) 
	{
		// WRITE_PICORV_PROGRAM(interface);
		// READ_PICORV_PROGRAM(interface);
	}

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
	printf("\n %-10s: ", "MLDSA");		if (data_conf.mldsa)	printf("yes"); else printf("no");
  	printf("\n %-10s: ", "SLHDSA");		if (data_conf.slhdsa)	printf("yes"); else printf("no");


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
		demo_trng_hw(1048576, verb, interface);
	}

	if (data_conf.mldsa) {
    	demo_mldsa_hw(44, verb, interface);
    	demo_mldsa_hw(65, verb, interface);
    	demo_mldsa_hw(87, verb, interface);
		demo_mldsa_nist(interface, verb);
  	}

	if (data_conf.slhdsa) {
    	const slh_ph_func_t *ph = &slh_dsa_ph_shake_256;
		demo_slhdsa_hw(interface, ph, "shake-128-f", verb);
    	demo_slhdsa_hw(interface, ph, "shake-128-s", verb);
		demo_slhdsa_hw(interface, ph, "shake-192-f", verb);
		demo_slhdsa_hw(interface, ph, "shake-192-s", verb);
		demo_slhdsa_hw(interface, ph, "shake-256-f", verb);
		demo_slhdsa_hw(interface, ph, "shake-256-s", verb);
    	demo_slhdsa_hw(interface, ph, "sha-2-128-f", verb);
		demo_slhdsa_hw(interface, ph, "sha-2-128-s", verb);
		demo_slhdsa_hw(interface, ph, "sha-2-192-f", verb);
		demo_slhdsa_hw(interface, ph, "sha-2-192-s", verb);
		demo_slhdsa_hw(interface, ph, "sha-2-256-f", verb);
		demo_slhdsa_hw(interface, ph, "sha-2-256-s", verb);
	}
	
	while ((control != CMD_SE_CODE) && (control != CMD_END))
    {
        picorv32_control(interface, &control);
    }

	secmem_info(1, interface);

	printf("\n\n");

	// --- Close Interface --- //
	close_INTF(interface);
}