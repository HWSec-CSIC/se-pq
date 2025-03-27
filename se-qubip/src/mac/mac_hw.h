
#include "../sha2/sha2_hw.h"
#include "../sha3/sha3_shake_hw.h"

#define ipad 0x36
#define opad 0x5c

void hmac(unsigned int mode, unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface);

void hmac_sha2_256(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface);
void hmac_sha2_384(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface);
void hmac_sha2_512(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface);
void hmac_sha2_512_256(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface);
void hmac_sha3_256(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface);
void hmac_sha3_512(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface);

void kmac(unsigned int mode, unsigned char* key, unsigned char* msg, unsigned int len, unsigned char* mac, INTF interface);

void kmac256(unsigned char* key, unsigned char* msg, unsigned int len, unsigned char* mac, INTF interface);
void kmac128(unsigned char* key, unsigned char* msg, unsigned int len, unsigned char* mac, INTF interface);