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

static void demo_sha3_perf_hw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, unsigned int len_shake, INTF interface) {

    if (sel == 0)           sha3_256_hw(input, len_input, md, interface);
    else if (sel == 1)      sha3_512_hw(input, len_input, md, interface);
    else if (sel == 2)      shake_128_hw(input, len_input, md, len_shake, interface);
    else if (sel == 3)      shake_256_hw(input, len_input, md, len_shake, interface);
    // else if (sel == 4)      sha3_224(input, len_input, md);
    // else if (sel == 5)      sha3_384(input, len_input, md);

}


void test_sha3_hw(unsigned int sel, unsigned int n_test, time_result* tr, unsigned int verb, INTF interface) {

    srand(time(NULL));   // Initialization, should only be called once.

    uint64_t start_t, stop_t;

    //-- Initialize to avoid 1st measure error
    start_t = timeInMicroseconds();
    stop_t = timeInMicroseconds();

    tr->time_mean_value = 0;
    tr->time_max_value = 0;
    tr->time_min_value = 0;
    tr->val_result = 0xFFFFFFFF;

    uint64_t time_hw = 0;
    uint64_t time_total_hw = 0;

    /*
    if (sel == 0)        printf("\n\n -- Test SHA3-256 --");
    else if (sel == 1)   printf("\n\n -- Test SHA3-512 --");
    else if (sel == 2)   printf("\n\n -- Test SHAKE-128 --");
    else if (sel == 3)   printf("\n\n -- Test SHAKE-256 --");
    else if (sel == 4)   printf("\n\n -- Test SHA3-224 --");
    else if (sel == 5)   printf("\n\n -- Test SHA3-384 --");
    */

    unsigned char md[64];
    unsigned char buf[100000];
    unsigned int mod = 1000;
    int ls;

    // buf = malloc(1024);
    // md  = malloc(256);
    // md1 = malloc(256);

    for (unsigned int test = 1; test <= n_test; test++) {
        int r = rand() % 100000;// 100000;
        // ctr_drbg(buf, r);
        trng_hw(buf, r, interface);

        if (sel == 0 | sel == 1)    ls = 64;
        else                        ls = 64;

        memset(md, 0, ls);

        if (verb >= 2) printf("\n test: %d \t bytes: %d \t len_shake: %d", test, r, ls);

        start_t = timeInMicroseconds();
        demo_sha3_perf_hw(sel, buf, r, md, ls, interface);
        stop_t = timeInMicroseconds(); if (verb >= 2) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

        time_hw = stop_t - start_t;
        time_total_hw += time_hw;

        if (test == 1)                                  tr->time_min_value = time_hw;
        else if (tr->time_min_value > time_hw)       tr->time_min_value = time_hw;
        if (tr->time_max_value < time_hw) tr->time_max_value = time_hw;

    }

    tr->time_mean_value = (uint64_t)(time_total_hw / n_test);

    // free(buf);
    // free(md);
    // free(md1);


}