#ifndef DEMO_H
#define DEMO_H

#include "../se-qubip.h"
#include "test_func.h"

void demo_sha3_hw(unsigned int verb, MMIO_WINDOW ms2xl);
void demo_sha2_hw(unsigned int verb, MMIO_WINDOW ms2xl);
void demo_eddsa_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl);
void demo_x25519_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl);
void demo_trng_hw(unsigned int bits, MMIO_WINDOW ms2xl);




void demo_aes_hw(unsigned int bits, unsigned int verb, MMIO_WINDOW ms2xl);
/*
void demo_sha2(unsigned int verb);
void demo_rsa(unsigned int bits, unsigned int verb);
void demo_sha3(unsigned int verb);
void demo_mlkem(unsigned int mode, unsigned int verb);
*/


void test_x25519_hw(unsigned int verb, MMIO_WINDOW ms2xl);


#endif
