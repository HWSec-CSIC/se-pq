/**
  * @file demo_trng_speed.c
  * @brief Performance test for Random Number Generator code
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

void test_trng_acc(unsigned int mode, unsigned int bits, unsigned int n_test, time_result* tr_hw, time_result* tr_sw, unsigned int verb, INTF interface)
{
    unsigned int bytes = (int)(bits / 8);
    unsigned char* random_trng; random_trng = malloc(bytes);
    unsigned char* random_ctr;  random_ctr = malloc(bytes);
    unsigned char* random_hmac;  random_hmac = malloc(bytes);

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
    if (mode == 0)        printf("\n\n -- Test TRNG %d bits --", bits);
    else if (mode == 1)   printf("\n\n -- Test CTR-DRBG %d bits --", bits);
    else if (mode == 2)   printf("\n\n -- Test HASH-DRBG %d bits --", bits);
    */

    for (unsigned int test = 1; test <= n_test; test++) {

        if (mode == 0) {
            start_t_sw = timeInMicroseconds();
            trng(random_trng, bytes); // from crypto_api_sw.h
            stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));
            
            start_t_hw = timeInMicroseconds();
            trng_hw(random_trng, bytes, interface);
            stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

            
            if (!test_random(random_trng, bytes)) tr_hw->val_result++;
            if (verb >= 2) show_array(random_trng, bytes, 32);
        }
        else if (mode == 1) {
            /*
                start_t = timeInMicroseconds();
                ctr_drbg(random_ctr, bytes); // from crypto_api_sw.h
                stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));
                if (!test_random(random_ctr, bytes)) tr->val_result++;
                if (verb >= 2) show_array(random_ctr, bytes, 32);
            */
        }
        else if (mode == 2) {
            /*
                start_t = timeInMicroseconds();
                hash_drbg(random_hmac, bytes); // from crypto_api_sw.h
                stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));
                if (!test_random(random_hmac, bytes)) tr->val_result++;
                if (verb >= 2) show_array(random_hmac, bytes, 32);
            */
        }

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


    }

    tr_sw->time_mean_value = (uint64_t)(time_total_sw / n_test);
    tr_hw->time_mean_value = (uint64_t)(time_total_hw / n_test);

    free(random_trng);
    free(random_ctr);
    free(random_hmac);
}
