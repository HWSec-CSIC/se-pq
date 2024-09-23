#include "../demo.h"
#include "test_func.h"
#include <openssl/rand.h>
#include <mcheck.h>

void demo_sha3_perf_hw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, unsigned int len_shake, MMIO_WINDOW ms2xl) {

    if (sel == 0)         sha3_256_hw(input, len_input, md, ms2xl);
    else if (sel == 1)   sha3_512_hw(input, len_input, md, ms2xl);
    else if (sel == 2)   shake_128_hw(input, len_input, md, len_shake, ms2xl);
    else if (sel == 3)   shake_256_hw(input, len_input, md, len_shake, ms2xl);

}

// --- software from crypto_api_sw.h
#include <crypto_api_sw.h>

void demo_sha3_perf_sw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, unsigned int len_shake) {

    if (sel == 0)           sha3_256(input, len_input, md);
    else if (sel == 1)      sha3_512(input, len_input, md);
    else if (sel == 2)      shake_128(input, len_input, md, len_shake);
    else if (sel == 3)      shake_256(input, len_input, md, len_shake);

}


void test_sha3(unsigned int sel, unsigned int n_test, time_result* tr, unsigned int verb, MMIO_WINDOW ms2xl) {

    srand(time(NULL));   // Initialization, should only be called once.

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

    if (sel == 0)        printf("\n\n -- Test SHA3-256 --");
    else if (sel == 1)   printf("\n\n -- Test SHA3-512 --");
    else if (sel == 2)   printf("\n\n -- Test SHAKE-128 --");
    else if (sel == 3)   printf("\n\n -- Test SHAKE-256 --");

    unsigned char md[64];
    unsigned char md1[64];
    unsigned char buf[100000];
    unsigned int mod = 1000;
    int ls;

    // buf = malloc(1024);
    // md  = malloc(256);
    // md1 = malloc(256);

    for (unsigned int test = 1; test <= n_test; test++) {
        int r = rand() % 100000;
        ctr_drbg(buf, r);

        if (sel == 0 | sel == 1)    ls = 64;
        else                        ls = 64;

        memset(md, 0, ls);
        memset(md1, 0, ls);

        if (verb >= 2) printf("\n test: %d \t bytes: %d \t len_shake: %d", test, r, ls);

        start_t = timeInMicroseconds();
        demo_sha3_perf_hw(sel, buf, r, md, ls, ms2xl);
        stop_t = timeInMicroseconds(); if (verb >= 2) printf("\n HW: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

        time_hw = stop_t - start_t;
        time_total_hw += time_hw;

        if (test == 1)                              tr->time_min_value_hw = time_hw;
        else if (tr->time_min_value_hw > time_hw)    tr->time_min_value_hw = time_hw;

        if (tr->time_max_value_hw < time_hw) tr->time_max_value_hw = time_hw;

        start_t = timeInMicroseconds();
        demo_sha3_perf_sw(sel, buf, r, md1, ls);
        stop_t = timeInMicroseconds(); if (verb >= 2) printf("\n SW: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

        time_sw = stop_t - start_t;
        time_total_sw += time_sw;

        if (test == 1)                                  tr->time_min_value_sw = time_sw;
        else if (tr->time_min_value_sw > time_sw)       tr->time_min_value_sw = time_sw;
        if (tr->time_max_value_sw < time_sw) tr->time_max_value_sw = time_sw;

        if (!memcmp(md, md1, ls)) tr->val_result++;

    }

    tr->time_mean_value_hw = (uint64_t)(time_total_hw / n_test);
    tr->time_mean_value_sw = (uint64_t)(time_total_sw / n_test);

    // free(buf);
    // free(md);
    // free(md1);


}