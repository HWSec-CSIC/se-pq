/**
  * @file demo_mlkem_acc.c
  * @brief Performance Test for MLKEM Code
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

#include "demo.h"
#include "test_func.h"

#include <crypto_api_sw.h>

void test_mlkem_acc(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg_hw, time_result* tr_en_hw, time_result* tr_de_hw, time_result* tr_kg_sw, time_result* tr_en_sw, time_result* tr_de_sw, INTF interface) {

#ifdef AXI
	unsigned int clk_index = 0;
	float clk_frequency;
	float set_clk_frequency = FREQ_MLKEM;
	Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif

	uint64_t start_t_hw, stop_t_hw;
	uint64_t start_t_sw, stop_t_sw;

	//-- Initialize to avoid 1st measure error
	start_t_hw = timeInMicroseconds();
	stop_t_hw = timeInMicroseconds();
	start_t_sw = timeInMicroseconds();
	stop_t_sw = timeInMicroseconds();

	tr_kg_hw->time_mean_value = 0;
	tr_kg_hw->time_max_value = 0;
	tr_kg_hw->time_min_value = 0;
	tr_kg_hw->val_result = 0;

	tr_kg_sw->time_mean_value = 0;
	tr_kg_sw->time_max_value = 0;
	tr_kg_sw->time_min_value = 0;
	tr_kg_sw->val_result = 0;

	tr_en_hw->time_mean_value = 0;
	tr_en_hw->time_max_value = 0;
	tr_en_hw->time_min_value = 0;
	tr_en_hw->val_result = 0;

	tr_de_hw->time_mean_value = 0;
	tr_de_hw->time_max_value = 0;
	tr_de_hw->time_min_value = 0;
	tr_de_hw->val_result = 0;

	tr_en_sw->time_mean_value = 0;
	tr_en_sw->time_max_value = 0;
	tr_en_sw->time_min_value = 0;
	tr_en_sw->val_result = 0;

	tr_de_sw->time_mean_value = 0;
	tr_de_sw->time_max_value = 0;
	tr_de_sw->time_min_value = 0;
	tr_de_sw->val_result = 0;

	uint64_t time_sw = 0;
	uint64_t time_total_kg_sw = 0;
	uint64_t time_total_en_sw = 0;
	uint64_t time_total_de_sw = 0;

	uint64_t time_hw = 0;
	uint64_t time_total_kg_hw = 0;
	uint64_t time_total_en_hw = 0;
	uint64_t time_total_de_hw = 0;

	unsigned char* pk_512;
	unsigned char* sk_512;
	unsigned char* ct_512;
	unsigned char* pk_768;
	unsigned char* sk_768;
	unsigned char* ct_768;
	unsigned char* pk_1024;
	unsigned char* sk_1024;
	unsigned char* ct_1024;

	unsigned char* pk_512_sw;
	unsigned char* sk_512_sw;
	unsigned char* ct_512_sw;
	unsigned char* pk_768_sw;
	unsigned char* sk_768_sw;
	unsigned char* ct_768_sw;
	unsigned char* pk_1024_sw;
	unsigned char* sk_1024_sw;
	unsigned char* ct_1024_sw;

	unsigned char ss[32];
	unsigned char ss1[32];
	unsigned char ss_sw[32];
	unsigned char ss1_sw[32];
	unsigned int result = 0;

	pk_512 = malloc(800);
	sk_512 = malloc(1632);
	ct_512 = malloc(768);
	pk_768 = malloc(1184);
	sk_768 = malloc(2400);
	ct_768 = malloc(1088);
	pk_1024 = malloc(1568);
	sk_1024 = malloc(3168);
	ct_1024 = malloc(1568);

	pk_512_sw = malloc(800);
	sk_512_sw = malloc(1632);
	ct_512_sw = malloc(768);
	pk_768_sw = malloc(1184);
	sk_768_sw = malloc(2400);
	ct_768_sw = malloc(1088);
	pk_1024_sw = malloc(1568);
	sk_1024_sw = malloc(3168);
	ct_1024_sw = malloc(1568);

	/*
	if (mode == 512)        printf("\n\n -- Test MLKEM-512 --");
	else if (mode == 768)   printf("\n\n -- Test MLKEM-768 --");
	else if (mode == 1024)  printf("\n\n -- Test MLKEM-1024 --");
	*/

	for (int test = 1; test <= n_test; test++) {

		if (verb >= 1) printf("\n test: %d", test);

		if (mode == 512) {

			// keygen
			start_t_sw = timeInMicroseconds();
			mlkem512_genkeys(pk_512_sw, sk_512_sw);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem512_genkeys_hw(pk_512, sk_512, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW ENCRYPT: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));
			
			time_sw = stop_t_sw - start_t_sw;
			time_total_kg_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_kg_hw += time_hw;

			if (test == 1)										tr_kg_sw->time_min_value = time_sw;
			else if (tr_kg_sw->time_min_value > time_sw)		tr_kg_sw->time_min_value = time_sw;
			if (tr_kg_sw->time_max_value < time_sw)				tr_kg_sw->time_max_value = time_sw;

			if (test == 1)										tr_kg_hw->time_min_value = time_hw;
			else if (tr_kg_hw->time_min_value > time_hw)		tr_kg_hw->time_min_value = time_hw;
			if (tr_kg_hw->time_max_value < time_hw)				tr_kg_hw->time_max_value = time_hw;

			if (verb >= 3) {
				printf("\n pk_512: \t");  show_array(pk_512, 800, 32);
				printf("\n sk_512: \t");  show_array(sk_512, 1632, 32);
			}

			// encapsulation
			start_t_sw = timeInMicroseconds();
			mlkem512_enc(pk_512_sw, ct_512_sw, ss_sw);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW ENCAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem512_enc_hw(pk_512, ct_512, ss, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW ENCAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_en_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_en_hw += time_hw;

			if (test == 1)										tr_en_sw->time_min_value = time_sw;
			else if (tr_en_sw->time_min_value > time_sw)		tr_en_sw->time_min_value = time_sw;
			if (tr_en_sw->time_max_value < time_sw)				tr_en_sw->time_max_value = time_sw;

			if (test == 1)										tr_en_hw->time_min_value = time_hw;
			else if (tr_en_hw->time_min_value > time_hw)		tr_en_hw->time_min_value = time_hw;
			if (tr_en_hw->time_max_value < time_hw)				tr_en_hw->time_max_value = time_hw;

			if (verb >= 3) {
				printf("\n ct_512: \t");  show_array(ct_512, 768, 32);
			}

			// decapsulation
			start_t_sw = timeInMicroseconds();
			mlkem512_dec(sk_512_sw, ct_512_sw, ss1_sw, &result);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW DECAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem512_dec_hw(sk_512, ct_512, ss1, &result, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW DECAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_de_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_de_hw += time_hw;

			if (test == 1)										tr_de_sw->time_min_value = time_sw;
			else if (tr_de_sw->time_min_value > time_sw)		tr_de_sw->time_min_value = time_sw;
			if (tr_de_sw->time_max_value < time_sw)				tr_de_sw->time_max_value = time_sw;

			if (test == 1)										tr_de_hw->time_min_value = time_hw;
			else if (tr_de_hw->time_min_value > time_hw)		tr_de_hw->time_min_value = time_hw;
			if (tr_de_hw->time_max_value < time_hw)				tr_de_hw->time_max_value = time_hw;

			if (verb >= 2) {
				printf("\n ss original: \t");  show_array(ss, 32, 32);
				printf("\n ss recover: \t");   show_array(ss1, 32, 32);
			}

			if ((result >> 1) & !memcmp(ss, ss1, 32)) tr_de_hw->val_result++;

		}

		else if (mode == 768) {

			// keygen
			start_t_sw = timeInMicroseconds();
			mlkem768_genkeys(pk_768_sw, sk_768_sw);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem768_genkeys_hw(pk_768, sk_768, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW ENCRYPT: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_kg_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_kg_hw += time_hw;

			if (test == 1)										tr_kg_sw->time_min_value = time_sw;
			else if (tr_kg_sw->time_min_value > time_sw)		tr_kg_sw->time_min_value = time_sw;
			if (tr_kg_sw->time_max_value < time_sw)				tr_kg_sw->time_max_value = time_sw;

			if (test == 1)										tr_kg_hw->time_min_value = time_hw;
			else if (tr_kg_hw->time_min_value > time_hw)		tr_kg_hw->time_min_value = time_hw;
			if (tr_kg_hw->time_max_value < time_hw)				tr_kg_hw->time_max_value = time_hw;

			if (verb >= 2) {
				printf("\n pk_768: \t");  show_array(pk_768, 1184, 32);
				printf("\n sk_768: \t");  show_array(sk_768, 2400, 32);
			}

			// encapsulation
			start_t_sw = timeInMicroseconds();
			mlkem768_enc(pk_768_sw, ct_768_sw, ss_sw);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW ENCAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem768_enc_hw(pk_768, ct_768, ss, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW ENCAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_en_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_en_hw += time_hw;

			if (test == 1)										tr_en_sw->time_min_value = time_sw;
			else if (tr_en_sw->time_min_value > time_sw)		tr_en_sw->time_min_value = time_sw;
			if (tr_en_sw->time_max_value < time_sw)				tr_en_sw->time_max_value = time_sw;

			if (test == 1)										tr_en_hw->time_min_value = time_hw;
			else if (tr_en_hw->time_min_value > time_hw)		tr_en_hw->time_min_value = time_hw;
			if (tr_en_hw->time_max_value < time_hw)				tr_en_hw->time_max_value = time_hw;

			if (verb >= 2) {
				printf("\n ct_768: \t");  show_array(ct_768, 1088, 32);
			}

			// decapsulation
			start_t_sw = timeInMicroseconds();
			mlkem768_dec(sk_768_sw, ct_768_sw, ss1_sw, &result);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW DECAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem768_dec_hw(sk_768, ct_768, ss1, &result, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW DECAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_de_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_de_hw += time_hw;

			if (test == 1)										tr_de_sw->time_min_value = time_sw;
			else if (tr_de_sw->time_min_value > time_sw)		tr_de_sw->time_min_value = time_sw;
			if (tr_de_sw->time_max_value < time_sw)				tr_de_sw->time_max_value = time_sw;

			if (test == 1)										tr_de_hw->time_min_value = time_hw;
			else if (tr_de_hw->time_min_value > time_hw)		tr_de_hw->time_min_value = time_hw;
			if (tr_de_hw->time_max_value < time_hw)				tr_de_hw->time_max_value = time_hw;

			if (verb >= 2) {
				printf("\n ss original: \t");  show_array(ss, 32, 32);
				printf("\n ss recover: \t");   show_array(ss1, 32, 32);
			}

			if ((result >> 1) & !memcmp(ss, ss1, 32)) tr_de_hw->val_result++;

		}
		else if (mode == 1024) {

			// keygen
			start_t_sw = timeInMicroseconds();
			mlkem1024_genkeys(pk_1024_sw, sk_1024_sw);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem1024_genkeys_hw(pk_1024, sk_1024, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW ENCRYPT: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_kg_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_kg_hw += time_hw;

			if (test == 1)										tr_kg_sw->time_min_value = time_sw;
			else if (tr_kg_sw->time_min_value > time_sw)		tr_kg_sw->time_min_value = time_sw;
			if (tr_kg_sw->time_max_value < time_sw)				tr_kg_sw->time_max_value = time_sw;

			if (test == 1)										tr_kg_hw->time_min_value = time_hw;
			else if (tr_kg_hw->time_min_value > time_hw)		tr_kg_hw->time_min_value = time_hw;
			if (tr_kg_hw->time_max_value < time_hw)				tr_kg_hw->time_max_value = time_hw;

			if (verb >= 2) {
				printf("\n pk_1024: \t");  show_array(pk_1024, 1568, 32);
				printf("\n sk_1024: \t");  show_array(sk_1024, 3168, 32);
			}

			// encapsulation
			start_t_sw = timeInMicroseconds();
			mlkem1024_enc(pk_1024_sw, ct_1024_sw, ss_sw);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW ENCAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem1024_enc_hw(pk_1024, ct_1024, ss, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW ENCAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_en_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_en_hw += time_hw;

			if (test == 1)										tr_en_sw->time_min_value = time_sw;
			else if (tr_en_sw->time_min_value > time_sw)		tr_en_sw->time_min_value = time_sw;
			if (tr_en_sw->time_max_value < time_sw)				tr_en_sw->time_max_value = time_sw;

			if (test == 1)										tr_en_hw->time_min_value = time_hw;
			else if (tr_en_hw->time_min_value > time_hw)		tr_en_hw->time_min_value = time_hw;
			if (tr_en_hw->time_max_value < time_hw)				tr_en_hw->time_max_value = time_hw;

			if (verb >= 2) {
				printf("\n ct_1024: \t");  show_array(ct_1024, 1568, 32);
			}

			// decapsulation
			start_t_sw = timeInMicroseconds();
			mlkem1024_dec(sk_1024_sw, ct_1024_sw, ss1_sw, &result);
			stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW DECAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

			start_t_hw = timeInMicroseconds();
			mlkem1024_dec_hw(sk_1024, ct_1024, ss1, &result, interface);
			stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW DECAP: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

			time_sw = stop_t_sw - start_t_sw;
			time_total_de_sw += time_sw;
			time_hw = stop_t_hw - start_t_hw;
			time_total_de_hw += time_hw;

			if (test == 1)										tr_de_sw->time_min_value = time_sw;
			else if (tr_de_sw->time_min_value > time_sw)		tr_de_sw->time_min_value = time_sw;
			if (tr_de_sw->time_max_value < time_sw)				tr_de_sw->time_max_value = time_sw;

			if (test == 1)										tr_de_hw->time_min_value = time_hw;
			else if (tr_de_hw->time_min_value > time_hw)		tr_de_hw->time_min_value = time_hw;
			if (tr_de_hw->time_max_value < time_hw)				tr_de_hw->time_max_value = time_hw;

			if (verb >= 2) {
				printf("\n ss original: \t");  show_array(ss, 32, 32);
				printf("\n ss recover: \t");   show_array(ss1, 32, 32);
			}

			if ((result >> 1) & !memcmp(ss, ss1, 32)) tr_de_hw->val_result++;

		}
	}

	tr_kg_sw->time_mean_value = (uint64_t)(time_total_kg_sw / n_test);
	tr_en_sw->time_mean_value = (uint64_t)(time_total_en_sw / n_test);
	tr_de_sw->time_mean_value = (uint64_t)(time_total_de_sw / n_test);
	tr_kg_hw->time_mean_value = (uint64_t)(time_total_kg_hw / n_test);
	tr_en_hw->time_mean_value = (uint64_t)(time_total_en_hw / n_test);
	tr_de_hw->time_mean_value = (uint64_t)(time_total_de_hw / n_test);

	free(sk_512);
	free(pk_512);
	free(ct_512);

	free(sk_768);
	free(pk_768);
	free(ct_768);

	free(sk_1024);
	free(pk_1024);
	free(ct_1024);

	free(sk_512_sw);
	free(pk_512_sw);
	free(ct_512_sw);

	free(sk_768_sw);
	free(pk_768_sw);
	free(ct_768_sw);

	free(sk_1024_sw);
	free(pk_1024_sw);
	free(ct_1024_sw);

#ifdef AXI
	set_clk_frequency = FREQ_TYPICAL;
	Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif


}