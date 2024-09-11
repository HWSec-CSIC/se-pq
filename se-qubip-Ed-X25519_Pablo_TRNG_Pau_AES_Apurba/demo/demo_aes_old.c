#include "demo.h"
#include "test_func.h"

#ifndef PYNQ
#define PYNQ
#endif

void demo_aes_hw(unsigned int bits, unsigned int verb, MMIO_WINDOW ms2xl) {

#if defined(PYNQ)
    unsigned int clk_index = 0;
    float clk_frequency;
    float set_clk_frequency = FREQ_AES;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int) verb);
#endif

    unsigned char msg[128] = "Hello, this is the SE of QUBIP project";
    //unsigned char msg[16] = {0};
       // unsigned char* char_msg = "6BC1BEE22E409F96E93D7E117393172A";

	//unsigned char msg[16] = {0x6B, 0xC1, 0xBE, 0xE2, 0x2E, 0x40, 0x9F, 0x96, 
                      //   0xE9, 0x3D, 0x7E, 0x11, 0x73, 0x93, 0x17, 0x2A};//char2hex(char_msg, msg);

	//unsigned char msg[16] = {0x6B, 0xC1, 0xBE, 0xE2, 0x2E, 0x40, 0x9F, 0x96, 
           //              0xE9, 0x3D, 0x7E, 0x11, 0x73, 0x93, 0x17, 0x2A};




    // ---- AES-128 ---- //
    if (bits == 128) {
        unsigned char* recovered_msg_128;
        unsigned int recovered_msg_128_len;

        unsigned char* char_key_128 = "2b7e151628aed2a6abf7158809cf4f3c"; 
        unsigned char key_128[16] = {0};// char2hex(char_key_128, key_128);
        unsigned char* char_iv_128 = "000102030405060708090a0b0c0d0e0f";
        unsigned char iv_128[16]; char2hex(char_iv_128, iv_128);

        unsigned char* ciphertext_128;
        unsigned int ciphertext_128_len;

        ciphertext_128 = calloc(sizeof(char), 32 * 2);
        recovered_msg_128 = calloc(sizeof(char), 128);

        // --- ECB --- //
        aes_128_ecb_encrypt_hw(key_128, ciphertext_128, &ciphertext_128_len, msg, strlen(msg), ms2xl);
        aes_128_ecb_decrypt_hw(key_128, ciphertext_128, ciphertext_128_len, recovered_msg_128, &recovered_msg_128_len, ms2xl);

        if (verb >= 1) printf("\n original msg: %s", msg);
        if (verb >= 1) printf("\n recover msg: %s", recovered_msg_128);

        if (!strcmp(msg, recovered_msg_128)) printf("\n AES-128-ECB Test: \u2705 VALID");
        else printf("\n AES-128-ECB Test: \u274c FAIL");

        // --- CBC --- //
        //aes_128_cbc_encrypt(key_128, iv_128, ciphertext_128, &ciphertext_128_len, msg, strlen(msg));
        //aes_128_cbc_decrypt(key_128, iv_128, ciphertext_128, ciphertext_128_len, recovered_msg_128, &recovered_msg_128_len);

        if (verb >= 1) printf("\n original msg: %s", msg);
        if (verb >= 1) printf("\n recover msg: %s", recovered_msg_128);

        if (!strcmp(msg, recovered_msg_128)) printf("\n AES-128-CBC Test: \u2705 VALID");
        else printf("\n AES-128-CBC Test: \u274c FAIL");

        // --- CMAC --- //
        unsigned char* char_exp_mac_128 = "bb1d6929e95937287fa37d129b756746";
        unsigned char exp_mac_128[16]; char2hex(char_exp_mac_128, exp_mac_128);
        unsigned char* mac_128;
        unsigned int mac_128_len;
        mac_128 = calloc(sizeof(char), 16);

        //aes_128_cmac(key_128, mac_128, &mac_128_len, NULL, 0);

        if (verb >= 1) {
            printf("\n Obtained Result: ");  show_array(mac_128, 16, 32);
            printf("\n Expected Result: ");  show_array(exp_mac_128, 16, 32);
        }

        if (!cmpchar(exp_mac_128, mac_128, 16)) printf("\n AES-128-CMAC Test: \u2705 VALID");
        else printf("\n AES-128-CMAC Test: \u274c FAIL");

        //free(mac_128);
        free(ciphertext_128);
        free(recovered_msg_128);
    
    }
    // ---- AES-192 ---- //
    else if (bits == 192) {
        unsigned char* recovered_msg_192;
        unsigned int recovered_msg_192_len;

        unsigned char* char_key_192 = "8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b";
        unsigned char key_192[24]; char2hex(char_key_192, key_192);
        unsigned char* char_iv_192 = "000102030405060708090a0b0c0d0e0f";
        unsigned char iv_192[16]; char2hex(char_iv_192, iv_192);

        unsigned char* ciphertext_192;
        unsigned int ciphertext_192_len;

        ciphertext_192 = calloc(sizeof(char), 24 * 2);
        recovered_msg_192 = calloc(sizeof(char), 100);

        // --- ECB --- //
        //aes_192_ecb_encrypt(key_192, ciphertext_192, &ciphertext_192_len, msg, strlen(msg));
        //aes_192_ecb_decrypt(key_192, ciphertext_192, ciphertext_192_len, recovered_msg_192, &recovered_msg_192_len);

        if (verb >= 1) printf("\n original msg: %s", msg);
        if (verb >= 1) printf("\n recover msg: %s", recovered_msg_192);

        if (!strcmp(msg, recovered_msg_192)) printf("\n AES-192-ECB Test: \u2705 VALID");
        else printf("\n AES-192-ECB Test: \u274c FAIL");


        // --- CBC --- //
        ciphertext_192 = calloc(sizeof(char), 24 * 2);
        recovered_msg_192 = calloc(sizeof(char), 100);
        //aes_192_cbc_encrypt(key_192, iv_192, ciphertext_192, &ciphertext_192_len, msg, strlen(msg));
        //aes_192_cbc_decrypt(key_192, iv_192, ciphertext_192, ciphertext_192_len, recovered_msg_192, &recovered_msg_192_len);

        if (verb >= 1) printf("\n original msg: %s", msg);
        if (verb >= 1) printf("\n recover msg: %s", recovered_msg_192);

        if (!strcmp(msg, recovered_msg_192)) printf("\n AES-192-CBC Test: \u2705 VALID");
        else printf("\n AES-192-CBC Test: \u274c FAIL");

        // --- CMAC --- //
        unsigned char* char_exp_mac_192 = "d17ddf46adaacde531cac483de7a9367";
        unsigned char exp_mac_192[16]; char2hex(char_exp_mac_192, exp_mac_192);
        unsigned char* mac_192;
        unsigned int mac_192_len;
        mac_192 = calloc(sizeof(char), 16);

        //aes_192_cmac(key_192, mac_192, &mac_192_len, NULL, 0);

        if (verb >= 1) {
            printf("\n Obtained Result: ");  show_array(mac_192, 16, 32);
            printf("\n Expected Result: ");  show_array(exp_mac_192, 16, 32);
        }

        if (!cmpchar(exp_mac_192, mac_192, 16)) printf("\n AES-192-CMAC Test: \u2705 VALID");
        else printf("\n AES-192-CMAC Test: \u274c FAIL");

        free(mac_192);
        free(ciphertext_192);
        free(recovered_msg_192);
    }
    else {
        unsigned char* recovered_msg_256;
        //unsigned int recovered_msg_256_len;
	unsigned int recovered_msg_256_len = strlen(msg);
        unsigned char* char_key_256 = "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4";
        unsigned char key_256[32] ; char2hex(char_key_256, key_256);      
	//unsigned char key_256[32] = {0}; //char2hex(char_key_256, key_256);
	 
/*unsigned char key_256[32] = {
    0xf4, 0xdf, 0x14, 0x09, 0xa3, 0x10, 0x98, 0x2d,
    0xd7, 0x08, 0x61, 0x3b, 0x07, 0x2c, 0x35, 0x1f,
    0x81, 0x77, 0x7d, 0x85, 0xf0, 0xae, 0x73, 0x2b,
    0xbe, 0x71, 0xca, 0x15, 0x10, 0xeb, 0x3d, 0x60
};*/

        unsigned char* char_iv_256 = "000102030405060708090a0b0c0d0e0f";
        unsigned char iv_256[16]; char2hex(char_iv_256, iv_256);

        unsigned char* ciphertext_256;
        unsigned int ciphertext_256_len = ((strlen(msg) % BLOCK_OR_IV_BYTES) == 0) ? strlen(msg) : (strlen(msg) / BLOCK_OR_IV_BYTES + 1) * BLOCK_OR_IV_BYTES;

        ciphertext_256 = calloc(sizeof(char), 32 * 2);
        recovered_msg_256 = calloc(sizeof(char), 512);
	//recovered_msg_256 = calloc(500, sizeof(char));  
        // --- ECB --- //
        aes_256_ecb_encrypt_hw(key_256, ciphertext_256, &ciphertext_256_len, msg, strlen(msg), ms2xl);
        //aes_256_ecb_decrypt_hw(key_256, ciphertext_256, ciphertext_256_len, recovered_msg_256, &recovered_msg_256_len, ms2xl);
	aes_256_ecb_decrypt_hw(key_256, ciphertext_256, ciphertext_256_len, recovered_msg_256, &recovered_msg_256_len, ms2xl);
        /*if (verb >= 1) */
        printf("\n original msg: %s", msg);
        printf("\n ciphertext: %s", ciphertext_256);
	printf("\n recovered_msg: %s", recovered_msg_256);
        
        if (verb >= 1) printf("\n recover msg: %s", recovered_msg_256);

        if (!strcmp(msg, recovered_msg_256)) printf("\n AES-256-ECB Test: \u2705 VALID");
        else printf("\n AES-256-ECB Test: \u274c FAIL");
        
	/*
        // --- CBC --- //
        //aes_256_cbc_encrypt(key_256, iv_256, ciphertext_256, &ciphertext_256_len, msg, strlen(msg));
        //aes_256_cbc_decrypt(key_256, iv_256, ciphertext_256, ciphertext_256_len, recovered_msg_256, &recovered_msg_256_len);

        if (verb >= 1) printf("\n original msg: %s", msg);
        if (verb >= 1) printf("\n recover msg: %s", recovered_msg_256);

        if (!strcmp(msg, recovered_msg_256)) printf("\n AES-256-CBC Test: \u2705 VALID");
        else printf("\n AES-256-CBC Test: \u274c FAIL");

        // --- CMAC --- //
        unsigned char* char_exp_mac_256 = "028962f61b7bf89efc6b551f4667d983";
        unsigned char exp_mac_256[16]; char2hex(char_exp_mac_256, exp_mac_256);
        unsigned char* mac_256;
        unsigned int mac_256_len;
        mac_256 = calloc(sizeof(char), 16);

        //aes_256_cmac(key_256, mac_256, &mac_256_len, NULL, 0);

        if (verb >= 1) {
            printf("\n Obtained Result: ");  show_array(mac_256, 16, 32);
            printf("\n Expected Result: ");  show_array(exp_mac_256, 16, 32);
        }

        if (!cmpchar(exp_mac_256, mac_256, 16)) printf("\n AES-256-CMAC Test: \u2705 VALID");
        else printf("\n AES-256-CMAC Test: \u274c FAIL");
	*/
        // free(mac_256);
        free(ciphertext_256);
        free(recovered_msg_256);

    }
#if defined(PYNQ)
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif
}
