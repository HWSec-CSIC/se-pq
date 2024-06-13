#ifndef DEMO_H
#define DEMO_H

#include "../se-qubip.h"
#include "test_func.h"

void demo_sha3_hw(unsigned int verb, MMIO_WINDOW ms2xl);

/*
void demo_rsa(unsigned int bits, unsigned int verb);
void demo_eddsa(unsigned int mode, unsigned int verb);
void demo_aes(unsigned int bits, unsigned int verb);
void demo_sha2(unsigned int verb);
void demo_sha3(unsigned int verb);
void demo_trng(unsigned int bits);
void demo_mlkem(unsigned int mode, unsigned int verb);
*/

#endif