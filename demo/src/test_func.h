#ifndef TEST_FUNC_H
#define	TEST_FUNC_H

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

#include <pynq_api.h>
#include "../../se-qubip.h"

typedef struct {
	unsigned int sha3;
	unsigned int sha2;
	unsigned int eddsa;
	unsigned int x25519;
	unsigned int mlkem;
	unsigned int trng;
	unsigned int n_test;
} data_conf;


typedef struct {
	uint64_t time_mean_value_hw;
	uint64_t time_max_value_hw;
	uint64_t time_min_value_hw;
	uint64_t time_mean_value_sw;
	uint64_t time_max_value_sw;
	uint64_t time_min_value_sw;
	uint64_t val_result;
} time_result;

void read_conf(data_conf* data);
void print_results(unsigned int verb, unsigned int n_test, time_result tr);
void load_bitstream(char* BITSTREAM_FILE);
void show_array(const unsigned char* r, const unsigned int size, const unsigned int mod);
int cmpchar(unsigned char* in1, unsigned char* in2, unsigned int len);
void char2hex(unsigned char* in, unsigned char* out);
void char_to_hex(unsigned char in0, unsigned char in1, unsigned char* out);
uint64_t timeInMicroseconds();
#endif