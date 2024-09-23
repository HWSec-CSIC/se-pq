#include "../demo.h"
#include "test_func.h"
#include <crypto_api_sw.h>

void test_trng(unsigned int bits, unsigned int n_test, time_result* tr, unsigned int verb, MMIO_WINDOW ms2xl)
{
    unsigned int bytes = (int)(bits / 8);
    unsigned char* random;
    random = malloc(bytes);

    uint64_t start_t, stop_t;

    //-- Initialize to avoid 1st measure error
    start_t = timeInMicroseconds();
    stop_t = timeInMicroseconds();

    tr->time_mean_value_hw = 0;
    tr->time_max_value_hw = 0;
    tr->time_min_value_hw = 0;
    tr->time_mean_value_sw = 0;
    tr->time_max_value_sw = 0;
    tr->time_min_value_sw = 0;
    tr->val_result = 0;

    uint64_t time_hw = 0;
    uint64_t time_sw = 0;
    uint64_t time_total_hw = 0;
    uint64_t time_total_sw = 0;

    printf("\n\n -- Test TRNG %d bits --", bits);

    for (unsigned int test = 1; test <= n_test; test++) {
        start_t = timeInMicroseconds();
        trng_hw(random, bytes, ms2xl);
        stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n HW: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

        time_hw = stop_t - start_t;
        time_total_hw += time_hw;

        if (test == 1)                               tr->time_min_value_hw = time_hw;
        else if (tr->time_min_value_hw > time_hw)    tr->time_min_value_hw = time_hw;

        if (tr->time_max_value_hw < time_hw)         tr->time_max_value_hw = time_hw;

        if (verb >= 2) show_array(random, bytes, 32);

        start_t = timeInMicroseconds();
        trng(random, bytes); // from crypto_api_sw.h
        stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

        time_sw = stop_t - start_t;
        time_total_sw += time_sw;

        if (test == 1)                               tr->time_min_value_sw = time_sw;
        else if (tr->time_min_value_sw > time_sw)    tr->time_min_value_sw = time_sw;

        if (tr->time_max_value_sw < time_sw)         tr->time_max_value_sw = time_sw;

        if (verb >= 2) show_array(random, bytes, 32);

    }

    tr->time_mean_value_hw = (uint64_t)(time_total_hw / n_test);
    tr->time_mean_value_sw = (uint64_t)(time_total_sw / n_test);

    free(random);
}
