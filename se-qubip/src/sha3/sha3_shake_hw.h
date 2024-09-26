#ifndef SHA3_SHAKE_H
#define SHA3_SHAKE_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "../common/intf.h"
#include "../common/conf.h"
#include "../common/extra_func.h"

/************************ Interface Constant Definitions **********************/

#define LOAD_LENGTH				1
#define LOAD					2
#define START					3

    void sha3_shake_interface_init(INTF interface, int VERSION);
    void sha3_shake_interface(unsigned long long int* a, unsigned long long int* b, INTF interface, unsigned int pos_pad, int pad, int shake, int VERSION, int SIZE_SHA3, int SIZE_BLOCK, int DBG);
    void sha3_shake_hw(unsigned char* in, unsigned char* out, unsigned int length, unsigned int length_out, int VERSION, int SIZE_BLOCK, int SIZE_SHA3, INTF interface, int DBG);

    /************************ Main Functions **********************/

    void sha3_256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, INTF interface);
    void sha3_512_hw_func(unsigned char* in, unsigned int length, unsigned char* out, INTF interface);
    void shake128_hw_func(unsigned char* in, unsigned int length, unsigned char* out, unsigned int length_out, INTF interface);
    void shake256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, unsigned int length_out, INTF interface);
#endif