#ifndef MAC_HW_H
#define MAC_HW_H

#include "mac_hw.h"

void hmac_sha2_256(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface) {
	hmac(0, key, msg, mac, interface);
}
void hmac_sha2_384(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface) {
	hmac(1, key, msg, mac, interface);
}
void hmac_sha2_512(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface) {
	hmac(2, key, msg, mac, interface);
}
void hmac_sha2_512_256(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface) {
	hmac(3, key, msg, mac, interface);
}
void hmac_sha3_256(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface) {
	hmac(4, key, msg, mac, interface);
}
void hmac_sha3_512(unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface) {
	hmac(5, key, msg, mac, interface);
}

void hmac(unsigned int mode, unsigned char* key, unsigned char* msg, unsigned char* mac, INTF interface) {
	
	unsigned int bs; 
	unsigned int lo;

	switch (mode) {
	case(0): bs = 64; lo = 32; break; // SHA-256
	case(1): bs = 128; lo = 48;  break; // SHA-384
	case(2): bs = 128; lo = 64;  break; // SHA-512
	case(3): bs = 128; lo = 32;  break; // SHA-512/256
	case(4): bs = 136; lo = 32;  break; // SHA3-256
	case(5): bs = 72; lo = 64;  break;	// SHA3-512
	default: bs = 72; lo = 64; break; // default: SHA3-512
	}
	
	// hash key
	unsigned int sk; sk = sizeof(key);
	unsigned char* hkey; hkey = malloc(lo);
	if (sk > bs) {
		switch (mode) {
		case(0): sha_256_hw_func(key, sk, hkey, interface); break; // SHA-256
		case(1): sha_384_hw_func(key, sk, hkey, interface);	break;			// SHA-384
		case(2): sha_512_hw_func(key, sk, hkey, interface);	break;			// SHA-512
		case(3): sha_512_256_hw_func(key, sk, hkey, interface);	break;		// SHA-512/256
		case(4): sha3_256_hw_func(key, sk, hkey, interface);  break;	// SHA3-256
		case(5): sha3_512_hw_func(key, sk, hkey, interface);  break;	// SHA3-512
		default: sha3_512_hw_func(key, sk, hkey, interface); break;		// default: SHA3-512
		}
	}
	else {
		memset(hkey, 0, lo);
		memcpy(hkey, key, sk);
	}

	// gen ko and ki
	unsigned char* ko; ko = malloc(lo);
	unsigned char* ki; ki = malloc(lo);

	for (int i = 0; i < lo; i++) {
		ko[i] = hkey[i] ^ opad;
		ki[i] = hkey[i] ^ ipad;
	}

	// concatenate msg and hash 
	unsigned char* msg2; msg2 = malloc(sizeof(msg) + lo);
	unsigned int len_msg2 = sizeof(msg2);
	memcpy(msg2, msg, sizeof(msg));
	memcpy(msg2 + sizeof(msg), ki, lo);

	unsigned char* hkim; hkim = malloc(lo);

	switch (mode) {
	case(0): sha_256_hw_func(msg2, len_msg2, hkim, interface); break; // SHA-256
	case(1): sha_384_hw_func(msg2, len_msg2, hkim, interface);	break;			// SHA-384
	case(2): sha_512_hw_func(msg2, len_msg2, hkim, interface);	break;			// SHA-512
	case(3): sha_512_256_hw_func(msg2, len_msg2, hkim, interface);	break;		// SHA-512/256
	case(4): sha3_256_hw_func(msg2, len_msg2, hkim, interface);  break;	// SHA3-256
	case(5): sha3_512_hw_func(msg2, len_msg2, hkim, interface);  break;	// SHA3-512
	default: sha3_512_hw_func(msg2, len_msg2, hkim, interface); break;		// default: SHA3-512
	}

	unsigned char* buf; buf = malloc(2 * lo);
	memcpy(buf, hkim, lo);
	memcpy(buf + lo, ko, lo);

	switch (mode) {
	case(0): sha_256_hw_func(buf, 2 * lo, mac, interface); break; // SHA-256
	case(1): sha_384_hw_func(buf, 2 * lo, mac, interface);	break;			// SHA-384
	case(2): sha_512_hw_func(buf, 2 * lo, mac, interface);	break;			// SHA-512
	case(3): sha_512_256_hw_func(buf, 2 * lo, mac, interface);	break;		// SHA-512/256
	case(4): sha3_256_hw_func(buf, 2 * lo, mac, interface);  break;	// SHA3-256
	case(5): sha3_512_hw_func(buf, 2 * lo, mac, interface);  break;	// SHA3-512
	default: sha3_512_hw_func(buf, 2 * lo, mac, interface); break;		// default: SHA3-512
	}
}

void kmac128(unsigned char* key, unsigned char* msg, unsigned int len, unsigned char* mac, INTF interface) {
	kmac(0, key, msg, len, mac, interface);
}
void kmac256(unsigned char* key, unsigned char* msg, unsigned int len, unsigned char* mac, INTF interface) {
	kmac(1, key, msg, len, mac, interface);
}

void kmac(unsigned int mode, unsigned char* key, unsigned char* msg, unsigned int len, unsigned char* mac, INTF interface) {
	
	// It has been implemented using SHAKE, but it should be migrated to cSHAKE
	unsigned char* buf; buf = malloc(sizeof(key) + sizeof(msg) + sizeof(len));
	memcpy(buf, key, sizeof(key));
	memcpy(buf + sizeof(key), msg, sizeof(msg));
	memcpy(buf, key, sizeof(key));

	if(mode == 0)	shake128_hw_func(buf, sizeof(buf), mac, len);
	else			shake256_hw_func(buf, sizeof(buf), mac, len);
}

#endif