/**
  * @file test_func.h
  * @brief Extra Function Header
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

#ifndef TEST_FUNC_H
#define	TEST_FUNC_H

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>
#ifdef AXI
    #include <pynq_api.h>
#endif
#include "../../se-qubip.h"

typedef struct {
	unsigned int aes;
	unsigned int sha3;
	unsigned int sha2;
	unsigned int eddsa;
	unsigned int ecdh;
	unsigned int mlkem;
	unsigned int drbg;
	unsigned int n_test;
} data_conf;


typedef struct {
	uint64_t time_mean_value;
	uint64_t time_max_value;
	uint64_t time_min_value;
	uint64_t val_result;
} time_result;

#ifdef AXI
    void load_bitstream(char* BITSTREAM_FILE);
#endif

int test_random(unsigned char* random, unsigned int size);
void print_result_valid(unsigned char* str, unsigned int fail);
void print_result_double_valid(unsigned char* str, unsigned char* str2, unsigned int fail);
void print_results(unsigned int verb, unsigned int n_test, time_result tr);
void print_results_str_1_tab_3(unsigned int n_test, unsigned char* str, time_result tr1, time_result tr2, time_result tr3);
void print_results_str_1_tab_2(unsigned int n_test, unsigned char* str, time_result tr1, time_result tr2);
void print_results_str_1_tab_1(unsigned int n_test, unsigned char* str, time_result tr);
void print_results_str_2_tab_1(unsigned int n_test, unsigned char* str1, unsigned char* str2, time_result tr);
void print_results_str_1_tab_2_acc(unsigned int n_test, unsigned char* str, time_result tr1_hw, time_result tr2_hw, time_result tr1_sw, time_result tr2_sw);
void print_results_str_1_tab_1_acc(unsigned int n_test, unsigned char* str, time_result tr_hw, time_result tr_sw);
void print_results_str_1_tab_3_acc(unsigned int n_test, unsigned char* str, time_result tr1_hw, time_result tr2_hw, time_result tr3_hw, time_result tr1_sw, time_result tr2_sw, time_result tr3_sw);
void print_results_str_2_tab_1_acc(unsigned int n_test, unsigned char* str1, unsigned char* str2, time_result tr_hw, time_result tr_sw);
void read_conf(data_conf* data);


void show_array(const unsigned char* r, const unsigned int size, const unsigned int mod);
int cmpchar(unsigned char* in1, unsigned char* in2, unsigned int len);
void char2hex(unsigned char* in, unsigned char* out);
void char_to_hex(unsigned char in0, unsigned char in1, unsigned char* out);
uint64_t timeInMicroseconds();

void print_title_demo();

#endif