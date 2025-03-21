/**
  * @file demo_sha2_acc.c
  * @brief Performance Test for SHA2 Code
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

static void demo_sha2_perf_hw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, INTF interface) {

    if (sel == 0)           sha_256_hw(input, len_input, md, interface);
    else if (sel == 1)      sha_384_hw(input, len_input, md, interface);
    else if (sel == 2)      sha_512_hw(input, len_input, md, interface);
    else if (sel == 3)      sha_512_256_hw(input, len_input, md, interface);
    // else if (sel == 4)      sha_224(input, len_input, md);
    // else if (sel == 5)      sha_512_224(input, len_input, md);

}

static void demo_sha2_perf_sw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md) {

    if (sel == 0)           sha_256(input, len_input, md);
    else if (sel == 1)      sha_384(input, len_input, md);
    else if (sel == 2)      sha_512(input, len_input, md);
    else if (sel == 3)      sha_512_256(input, len_input, md);
    // else if (sel == 4)      sha_224(input, len_input, md);
    // else if (sel == 5)      sha_512_224(input, len_input, md);

}


void test_sha2_acc(unsigned int sel, unsigned int n_test, time_result* tr_hw, time_result* tr_sw, unsigned int verb, INTF interface) {

#ifdef AXI
    unsigned int clk_index = 0;
    float clk_frequency;
    float set_clk_frequency = FREQ_SHA2;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif

    srand(time(NULL));   // Initialization, should only be called once.

    uint64_t start_t_hw, stop_t_hw;
    uint64_t start_t_sw, stop_t_sw;

    //-- Initialize to avoid 1st measure error
    start_t_hw = timeInMicroseconds();
    stop_t_hw = timeInMicroseconds();
    start_t_sw = timeInMicroseconds();
    stop_t_sw = timeInMicroseconds();

    tr_hw->time_mean_value = 0;
    tr_hw->time_max_value = 0;
    tr_hw->time_min_value = 0;
    tr_hw->val_result = 0;

    tr_sw->time_mean_value = 0;
    tr_sw->time_max_value = 0;
    tr_sw->time_min_value = 0;
    tr_sw->val_result = 0;

    uint64_t time_hw = 0;
    uint64_t time_total_hw = 0;
    uint64_t time_sw = 0;
    uint64_t time_total_sw = 0;

    /*
    if (sel == 0)        printf("\n\n -- Test SHA3-256 --");
    else if (sel == 1)   printf("\n\n -- Test SHA3-512 --");
    else if (sel == 2)   printf("\n\n -- Test SHAKE-128 --");
    else if (sel == 3)   printf("\n\n -- Test SHAKE-256 --");
    else if (sel == 4)   printf("\n\n -- Test SHA3-224 --");
    else if (sel == 5)   printf("\n\n -- Test SHA3-384 --");
    */

    int buf_len = 1000;

    unsigned char md_hw[64];
    unsigned char md_sw[64];
    unsigned char buf[buf_len];
    unsigned int mod = 1000;

    // buf = malloc(1024);
    // md  = malloc(256);
    // md1 = malloc(256);

    for (unsigned int test = 1; test <= n_test; test++) {
        int r = rand() % buf_len;// 100000;
        ctr_drbg(buf, r); // from crypto_api_sw


        memset(md_sw, 0, 64);
        memset(md_hw, 0, 64);

        if (verb >= 2) printf("\n test: %d \t bytes: %d ", test, r);

        start_t_sw = timeInMicroseconds();
        demo_sha2_perf_sw(sel, buf, r, md_sw);
        stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

        start_t_hw = timeInMicroseconds();
        demo_sha2_perf_hw(sel, buf, r, md_hw, interface);
        stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

        time_sw = stop_t_sw - start_t_sw;
        time_total_sw += time_sw;
        time_hw = stop_t_hw - start_t_hw;
        time_total_hw += time_hw;

        if (test == 1)										tr_sw->time_min_value = time_sw;
        else if (tr_sw->time_min_value > time_sw)		    tr_sw->time_min_value = time_sw;
        if (tr_sw->time_max_value < time_sw)				tr_sw->time_max_value = time_sw;

        if (test == 1)										tr_hw->time_min_value = time_hw;
        else if (tr_hw->time_min_value > time_hw)		    tr_hw->time_min_value = time_hw;
        if (tr_hw->time_max_value < time_hw)				tr_hw->time_max_value = time_hw;

        if (!memcmp(md_hw, md_sw, 64)) tr_hw->val_result++;
        if (verb >= 3) { printf("\n md sw: "); show_array(md_sw, 64, 32); }
        if (verb >= 3) { printf("\n md hw: "); show_array(md_hw, 64, 32); }

    }

    tr_sw->time_mean_value = (uint64_t)(time_total_sw / n_test);
    tr_hw->time_mean_value = (uint64_t)(time_total_hw / n_test);

    // free(buf);
    // free(md);
    // free(md1);

#ifdef AXI
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif

}