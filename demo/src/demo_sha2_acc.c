/**
  * @file demo_sha3_speed.c
  * @brief Performance test for SHA3 code
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

    unsigned char md_hw[64];
    unsigned char md_sw[64];
    unsigned char buf[100000];
    unsigned int mod = 1000;

    // buf = malloc(1024);
    // md  = malloc(256);
    // md1 = malloc(256);

    for (unsigned int test = 1; test <= n_test; test++) {
        int r = rand() % 100000;// 100000;
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


}