
/****************************************************************************************/
/*
 *  SE_QUBIP: SE_QUBIP.h
 *
 *  Created on: 25/03/2024
 *      Author: Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
 *
 */
 /****************************************************************************************/

#ifndef SE_QUBIP_H_INCLUDED
#define SE_QUBIP_H_INCLUDED

#include <stdlib.h>
#include <pynq_api.h>

#include "se-qubip/src/common/mmio.h"
#include "se-qubip/src/sha3/sha3_shake_hw.h"
#include "se-qubip/src/sha2/sha2_hw.h"
#include "se-qubip/src/eddsa/eddsa_hw.h"
#include "se-qubip/src/x25519/x25519_hw.h"
#include "se-qubip/src/trng/trng_hw.h"
#include "se-qubip/src/aes/aes_hw.h"


#define sha3_512_hw			    sha3_512_hw_func
#define sha3_256_hw			    sha3_256_hw_func
#define shake_128_hw		    shake128_hw_func
#define shake_256_hw		    shake256_hw_func

#define sha_256_hw			    sha_256_hw_func
#define sha_384_hw			    sha_384_hw_func
#define sha_512_hw			    sha_512_hw_func
#define sha_512_256_hw		    sha_512_256_hw_func

#define eddsa25519_genkeys_hw   eddsa25519_genkeys_hw
#define eddsa25519_sign_hw      eddsa25519_sign_hw
#define eddsa25519_verify_hw    eddsa25519_verify_hw

#define x25519_genkeys_hw       x25519_genkeys_hw
#define x25519_ss_gen_hw        x25519_ss_gen_hw

#define trng_hw        			trng_hw


#define aes_256_ecb_encrypt_hw	aes_256_ecb_encrypt_hw
#define aes_256_ecb_decrypt_hw	aes_256_ecb_decrypt_hw
#define aes_128_ecb_encrypt_hw	aes_128_ecb_encrypt_hw
#define aes_128_ecb_decrypt_hw	aes_128_ecb_decrypt_hw
#define aes_256_cbc_encrypt_hw	aes_256_cbc_encrypt_hw
#define aes_256_cbc_decrypt_hw	aes_256_cbc_decrypt_hw
#define aes_128_cbc_encrypt_hw	aes_128_cbc_encrypt_hw
#define aes_128_cbc_decrypt_hw	aes_128_cbc_decrypt_hw

#define aes_block_256_ecb_encrypt_hw	aes_block_256_ecb_encrypt_hw
#define aes_block_256_ecb_decrypt_hw	aes_block_256_ecb_decrypt_hw
#define aes_block_128_ecb_encrypt_hw	aes_block_128_ecb_encrypt_hw
#define aes_block_128_ecb_decrypt_hw	aes_block_128_ecb_decrypt_hw
#define aes_block_256_cbc_encrypt_hw	aes_block_256_cbc_encrypt_hw
#define aes_block_256_cbc_decrypt_hw	aes_block_256_cbc_decrypt_hw
#define aes_block_128_cbc_encrypt_hw	aes_block_128_cbc_encrypt_hw
#define aes_block_128_cbc_decrypt_hw	aes_block_128_cbc_decrypt_hw

// ------- BITSTREAM_FILE ------- //
#ifdef PYNQZ2
#define BITSTREAM_QUBIP         "../se-qubip/bit/SE_QUBIP_PYNQZ2.bit"
#elif ZCU104
#define BITSTREAM_QUBIP         "../se-qubip/bit/SE_QUBIP_ZCU104.bit"
#endif

// ------- MS2XL_BASEADDR ------- //

//#define MS2XL_LENGTH		0x40

#define MS2XL_LENGTH		0x80

#ifdef PYNQZ2
#define MS2XL_BASEADDR		0x43C00000
#elif ZCU104
#define MS2XL_BASEADDR      0x00A0000000
#endif

/* ------- FREQUENCIES DEFINITION ------- */
#ifdef PYNQZ2
#define FREQ_TYPICAL        100.0
#define FREQ_EDDSA           70.0
#define FREQ_X25519          90.0
#define FREQ_AES	     50.0
#elif ZCU104
#define FREQ_TYPICAL        150.0
#define FREQ_EDDSA          300.0
#define FREQ_X25519         300.0
#endif

#endif // SE_QUBIP_H_INCLUDED
