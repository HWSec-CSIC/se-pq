#include "../demo.h"
#include "test_func.h"
#include <openssl/rand.h>
#include <mcheck.h>

void demo_sha2_perf_hw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, MMIO_WINDOW ms2xl) {

    if (sel == 0)        sha_256_hw(input, len_input, md, ms2xl);
    else if (sel == 1)   sha_384_hw(input, len_input, md, ms2xl);
    else if (sel == 2)   sha_512_hw(input, len_input, md, ms2xl);
    else if (sel == 3)   sha_512_256_hw(input, len_input, md, ms2xl);

}

// --- software from crypto_api_sw.h
#include <crypto_api_sw.h>

void demo_sha2_perf_sw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md) {

    if (sel == 0)           sha_256(input, len_input, md);
    else if (sel == 1)      sha_384(input, len_input, md);
    else if (sel == 2)      sha_512(input, len_input, md);
    else if (sel == 3)      sha_512_256(input, len_input, md);

}


void test_sha2(unsigned int sel, unsigned int n_test, time_result* tr, unsigned int verb, MMIO_WINDOW ms2xl) {

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

    if (sel == 0)        printf("\n\n -- Test SHA-256 --");
    else if (sel == 1)   printf("\n\n -- Test SHA-384 --");
    else if (sel == 2)   printf("\n\n -- Test SHA-512 --");
    else if (sel == 3)   printf("\n\n -- Test SHA-512/256 --");

    unsigned char md[64];
    unsigned char md1[64];
    unsigned char buf[100000];

    // buf = malloc(1024);
    // md  = malloc(256);
    // md1 = malloc(256);

    for (unsigned int test = 1; test <= n_test; test++) {
        int r = rand() % 100000;
        ctr_drbg(buf, r);

        memset(md, 0, 64);
        memset(md1, 0, 64);

        if (verb >= 2) printf("\n test: %d \t bytes: %d", test, r);

        start_t = timeInMicroseconds();
        demo_sha2_perf_hw(sel, buf, r, md, ms2xl);
        stop_t = timeInMicroseconds(); if (verb >= 2) printf("\n HW: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

        if (verb >= 1) show_array(md, 64, 32);

        time_hw = stop_t - start_t;
        time_total_hw += time_hw;

        if (test == 1)                                  tr->time_min_value_hw = time_hw;
        else if (tr->time_min_value_hw > time_hw)       tr->time_min_value_hw = time_hw;
        if (tr->time_max_value_hw < time_hw) tr->time_max_value_hw = time_hw;

        start_t = timeInMicroseconds();
        demo_sha2_perf_sw(sel, buf, r, md1);
        stop_t = timeInMicroseconds(); if (verb >= 2) printf("\n SW: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

        if (verb >= 1) show_array(md1, 64, 32);

        time_sw = stop_t - start_t;
        time_total_sw += time_sw;

        if (test == 1)                                  tr->time_min_value_sw = time_sw;
        else if (tr->time_min_value_sw > time_sw)       tr->time_min_value_sw = time_sw;
        if (tr->time_max_value_sw < time_sw) tr->time_max_value_sw = time_sw;

        if (!memcmp(md, md1, 64)) tr->val_result++;

    }

    tr->time_mean_value_hw = (uint64_t)(time_total_hw / n_test);
    tr->time_mean_value_sw = (uint64_t)(time_total_sw / n_test);

    // free(buf);
    // free(md);
    // free(md1);


}