/**
  * @file demo.h
  * @brief Demo header
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

#ifndef DEMO_H
#define DEMO_H

#ifdef SEQUBIP_INST
#include <se-qubip.h>
#else
#include "../../se-qubip.h"
#endif // SEQUBIP_INST

#include "test_func.h"

void demo_eddsa_hw(unsigned int mode, unsigned int verb, INTF interface);
void demo_x25519_hw(unsigned int mode, unsigned int verb, INTF interface);
void demo_aes_hw(unsigned int bits, unsigned int verb, INTF interface);
void demo_sha2_hw(unsigned int verb, INTF interface);
void demo_sha3_hw(unsigned int verb, INTF interface);
void demo_trng_hw(unsigned int bits, unsigned verb, INTF interface);
void demo_mlkem_hw(unsigned int mode, unsigned int verb, INTF interface);

// test - speed
void test_aes_hw(unsigned char mode[4], unsigned int bits, unsigned int n_test, unsigned int verb, time_result* tr_en, time_result* tr_de, INTF interface);
void test_sha3_hw(unsigned int sel, unsigned int n_test, time_result* tr, unsigned int verb, INTF interface);
void test_sha2_hw(unsigned int sel, unsigned int n_test, time_result* tr, unsigned int verb, INTF interface);
void test_eddsa_hw(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_si, time_result* tr_ve, INTF interface);
void test_x25519_hw(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_ss, INTF interface);
void test_trng_hw(unsigned int mode, unsigned int bits, unsigned int n_test, time_result* tr, unsigned int verb, INTF interface);
void test_mlkem_hw(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_en, time_result* tr_de, INTF interface);

// test - acc
void test_aes_acc(unsigned char mode[4], unsigned int bits, unsigned int n_test, unsigned int verb, time_result* tr_en_hw, time_result* tr_de_hw, time_result* tr_en_sw, time_result* tr_de_sw, INTF interface);
void test_sha3_acc(unsigned int sel, unsigned int n_test, time_result* tr_hw, time_result* tr_sw, unsigned int verb, INTF interface);
void test_sha2_acc(unsigned int sel, unsigned int n_test, time_result* tr_hw, time_result* tr_sw, unsigned int verb, INTF interface);
void test_eddsa_acc(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg_hw, time_result* tr_si_hw, time_result* tr_ve_hw, time_result* tr_kg_sw, time_result* tr_si_sw, time_result* tr_ve_sw, INTF interface);
void test_x25519_acc(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg_hw, time_result* tr_ss_hw, time_result* tr_kg_sw, time_result* tr_ss_sw, INTF interface);
void test_mlkem_acc(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg_hw, time_result* tr_en_hw, time_result* tr_de_hw, time_result* tr_kg_sw, time_result* tr_en_sw, time_result* tr_de_sw, INTF interface);
void test_trng_acc(unsigned int mode, unsigned int bits, unsigned int n_test, time_result* tr_hw, time_result* tr_sw, unsigned int verb, INTF interface);

#endif