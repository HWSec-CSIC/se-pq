#ifndef DEMO_H
#define DEMO_H

#include "../se-qubip.h"
#include "src/test_func.h"
#include <mcheck.h>

// demo_sha3
void demo_sha3_hw(unsigned int verb, MMIO_WINDOW ms2xl);
// demo_sha3_speed
void demo_sha3_perf_hw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, unsigned int len_shake, MMIO_WINDOW ms2xl);
void demo_sha3_perf_sw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, unsigned int len_shake);
void test_sha3(unsigned int sel, unsigned int n_test, time_result* tr, unsigned int verb, MMIO_WINDOW ms2xl);
// demo_sha2
void demo_sha2_hw(unsigned int verb, MMIO_WINDOW ms2xl);
// demo_sha2_speed
void demo_sha2_perf_hw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md, MMIO_WINDOW ms2xl);
void demo_sha2_perf_sw(unsigned int sel, unsigned char* input, unsigned int len_input, unsigned char* md);
void test_sha2(unsigned int sel, unsigned int n_test, time_result* tr, unsigned int verb, MMIO_WINDOW ms2xl);
// demo_eddsa
void demo_eddsa_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl);
// demo_eddsa_speed
void test_eddsa(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_si, time_result* tr_ve, MMIO_WINDOW ms2xl);
void demo_x25519_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl);
// demo_trng
void demo_trng_hw(unsigned int bits, MMIO_WINDOW ms2xl);
// demo_trng_speed
void test_trng(unsigned int bits, unsigned int n_test, time_result* tr, unsigned int verb, MMIO_WINDOW ms2xl);
// demo_mlkem
void demo_mlkem_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl);
// test_mlkem
void test_mlkem(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_en, time_result* tr_de, MMIO_WINDOW ms2xl);
void test_x25519_hw(unsigned int verb, MMIO_WINDOW ms2xl);


#endif