#ifndef TEST_FUNC_H
#define	TEST_FUNC_H

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

#include <pynq_api.h>

void load_bitstream();
void show_array(const unsigned char* r, const unsigned int size, const unsigned int mod);
int cmpchar(unsigned char* in1, unsigned char* in2, unsigned int len);
void char2hex(unsigned char* in, unsigned char* out);
void char_to_hex(unsigned char in0, unsigned char in1, unsigned char* out);
uint64_t timeInMicroseconds();
#endif