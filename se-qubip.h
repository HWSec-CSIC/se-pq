
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

#include "se-qubip/src/common/intf.h"
#include "se-qubip/src/sha3/sha3_shake_hw.h"
#include "se-qubip/src/sha2/sha2_hw.h"
#include "se-qubip/src/eddsa/eddsa_hw.h"
#include "se-qubip/src/x25519/x25519_hw.h"
#include "se-qubip/src/trng/trng_hw.h"
#include "se-qubip/src/aes/aes_hw.h"
#include "se-qubip/src/mlkem/mlkem_hw.h"

//-- SHA-3 / SHAKE
#define sha3_512_hw			    sha3_512_hw_func
#define sha3_256_hw			    sha3_256_hw_func
#define shake_128_hw		    shake128_hw_func
#define shake_256_hw		    shake256_hw_func

#define sha_256_hw			    sha_256_hw_func
#define sha_384_hw			    sha_384_hw_func
#define sha_512_hw			    sha_512_hw_func
#define sha_512_256_hw		    sha_512_256_hw_func

//-- EdDSA25519
#define eddsa25519_genkeys_hw   eddsa25519_genkeys_hw
#define eddsa25519_sign_hw      eddsa25519_sign_hw
#define eddsa25519_verify_hw    eddsa25519_verify_hw

//-- X25519
#define x25519_genkeys_hw       x25519_genkeys_hw
#define x25519_ss_gen_hw        x25519_ss_gen_hw

//-- TRNG
#define trng_hw        			trng_hw

//-- AES-128/256 ECB/CBC/CMAC
#define aes_128_ecb_encrypt_hw  aes_128_ecb_encrypt_hw
#define aes_128_ecb_decrypt_hw  aes_128_ecb_decrypt_hw
#define aes_256_ecb_encrypt_hw  aes_256_ecb_encrypt_hw
#define aes_256_ecb_decrypt_hw  aes_256_ecb_decrypt_hw

#define aes_128_cbc_encrypt_hw  aes_128_cbc_encrypt_hw
#define aes_128_cbc_decrypt_hw  aes_128_cbc_decrypt_hw
#define aes_256_cbc_encrypt_hw  aes_256_cbc_encrypt_hw
#define aes_256_cbc_decrypt_hw  aes_256_cbc_decrypt_hw

#define aes_128_cmac_hw         aes_128_cmac_hw
#define aes_256_cmac_hw         aes_256_cmac_hw

//-- MLKEM
#define mlkem_512_gen_keys_hw   mlkem_512_gen_keys_hw
#define mlkem_768_gen_keys_hw   mlkem_768_gen_keys_hw
#define mlkem_1024_gen_keys_hw  mlkem_1024_gen_keys_hw
#define mlkem_gen_keys_hw       mlkem_gen_keys_hw

#define mlkem_512_enc_hw        mlkem_512_enc_hw
#define mlkem_768_enc_hw        mlkem_768_enc_hw
#define mlkem_1024_enc_hw       mlkem_1024_enc_hw
#define mlkem_enc_hw            mlkem_enc_hw
#define mlkem_enc_coins_hw      mlkem_enc_coins_hw

#define mlkem_512_dec_hw        mlkem_512_dec_hw 
#define mlkem_768_dec_hw        mlkem_768_dec_hw 
#define mlkem_1024_dec_hw       mlkem_1024_dec_hw
#define mlkem_dec_hw            mlkem_dec_hw     

//-- INTERFACE
#ifdef I2C
    #define INTF_ADDRESS            0x1A            //-- I2C_DEVICE_ADDRESS
    #define INTF_LENGTH		        0x40
#elif AXI
    // ------- MS2XL_BASEADDR ------- //
    #define INTF_LENGTH		        0x40

    #ifdef PYNQZ2
        #define INTF_ADDRESS		0x43C00000      //-- MS2XL_BASEADDR
    #elif ZCU104
        #define INTF_ADDRESS        0x00A0000000    //-- MS2XL_BASEADDR
    #else
        #define INTF_ADDRESS        0x0000000000
    #endif

    // ------- BITSTREAM_FILE ------- //
    #ifdef PYNQZ2
        #define BITSTREAM_AXI       "../se-qubip/bit/PYNQZ2_SE_QUBIP_0.9.bit"
    #elif ZCU104
        #define BITSTREAM_AXI       "../se-qubip/bit/ZCU104_SE_QUBIP_0.9.bit"
    #endif

    /* ------- FREQUENCIES DEFINITION ------- */
    #ifdef PYNQZ2
        #define FREQ_TYPICAL    100.0
        #define FREQ_EDDSA      60.0
        #define FREQ_X25519     90.0
        #define FREQ_AES        90.0
    #elif ZCU104
        #define FREQ_TYPICAL    100.0
        #define FREQ_EDDSA      200.0
        #define FREQ_X25519     200.0
        #define FREQ_AES        100.0
    #endif
#endif

#endif // SE_QUBIP_H_INCLUDED
