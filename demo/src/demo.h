/**
  * @file demo.h
  * @brief Demo header
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
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