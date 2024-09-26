#ifndef SHA2_H
#define SHA2_H

#include <math.h>
#include "../common/intf.h"
#include "../common/extra_func.h"
#include "../common/conf.h"

/************************ interface Constant Definitions **********************/

#define LOAD_LENGTH_SHA2			1
#define LOAD_SHA2					2
#define START_SHA2					3

/************************ interface Function Definitions **********************/

void sha2_interface_init(INTF interface, unsigned long long int length, int VERSION, int DBG);
void sha2_interface(INTF interface, unsigned long long int* a, unsigned long long int* b, unsigned long long int length, int last_hb, int VERSION, int DBG);
void sha2_hw(INTF interface, unsigned char* in, unsigned char* out, unsigned long long int length, unsigned int VERSION, int DBG);

/************************ Main Functions **********************/

void sha_256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, INTF interface);
void sha_384_hw_func(unsigned char* in, unsigned int length, unsigned char* out, INTF interface);
void sha_512_hw_func(unsigned char* in, unsigned int length, unsigned char* out, INTF interface);
void sha_512_256_hw_func(unsigned char* in, unsigned int length, unsigned char* out, INTF interface);

#endif
