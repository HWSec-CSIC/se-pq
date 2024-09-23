#include "../demo.h"
#include "test_func.h"

#define SHA256_DIGEST_LENGTH 32
#define SHA512_DIGEST_LENGTH 64


void demo_sha3_hw(unsigned int verb, MMIO_WINDOW ms2xl) {

    // ---- SHA3 ---- //
    unsigned char* input;
    unsigned int len_input;
    unsigned char* md;

    // unsigned char* exp_res_3_224 = "6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7";
    unsigned char* exp_res_3_256 = "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a";
    // unsigned char* exp_res_3_384 = "0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004";
    unsigned char* exp_res_3_512 = "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26";
    unsigned char* exp_res_s_128 = "7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26";
    unsigned char* exp_res_s_256 = "46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762fd75dc4ddd8c0f200cb05019d67b592f6fc821c49479ab48640292eacb3b7c4be";

    // unsigned char res_3_224[28]; char2hex(exp_res_3_224, res_3_224);
    unsigned char res_3_256[32]; char2hex(exp_res_3_256, res_3_256);
    // unsigned char res_3_384[48]; char2hex(exp_res_3_384, res_3_384);
    unsigned char res_3_512[64]; char2hex(exp_res_3_512, res_3_512);
    unsigned char res_s_128[32]; char2hex(exp_res_s_128, res_s_128);
    unsigned char res_s_256[64]; char2hex(exp_res_s_256, res_s_256);

    input = malloc(32);
    input[0] = (unsigned char)('\0');
    len_input = 0;

    /*
    // ---- sha3_224 ---- //
    md = malloc(SHA224_DIGEST_LENGTH);
    sha3_224(input, len_input, md);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA224_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_224, SHA224_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_3_224, SHA224_DIGEST_LENGTH)) printf("\n SHA3-224 Test: \u2705 VALID");
    else printf("\n SHA3-224 Test: \u274c FAIL");
    free(md);
    */

    // ---- sha3_256 ---- //
    md = malloc(SHA256_DIGEST_LENGTH);
    sha3_256_hw(input, len_input, md, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA256_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_256, SHA256_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_3_256, SHA256_DIGEST_LENGTH)) printf("\n SHA3-256 Test: \t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA3-256 Test: \t\033[1;31m\u274c\033[0m FAIL");
    free(md);

    /*
    // ---- sha3_384 ---- //
    md = malloc(SHA384_DIGEST_LENGTH);
    sha3_384(input, len_input, md);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA384_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_384, SHA384_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_3_384, SHA384_DIGEST_LENGTH)) printf("\n SHA3-384 Test: \033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA3-384 Test: \033[1;31m\u274c\033[0m FAIL");
    free(md);
    */

    // ---- sha3_512 ---- //
    md = malloc(SHA512_DIGEST_LENGTH);
    sha3_512_hw(input, len_input, md, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA512_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_3_512, SHA512_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_3_512, SHA512_DIGEST_LENGTH)) printf("\n SHA3-512 Test: \t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA3-512 Test: \t\033[1;31m\u274c\033[0m FAIL");
    free(md);

    // ---- shake_128 ---- //
    md = malloc(32);
    shake_128_hw(input, len_input, md, 32, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, 32, 32);
        printf("\n Expected Result: ");  show_array(res_s_128, 32, 32);
    }
    if (!cmpchar(md, res_s_128, 32)) printf("\n SHAKE-128 Test: \t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHAKE-128 Test: \t\033[1;31m\u274c\033[0m FAIL");
    free(md);

    // ---- shake_256 ---- //
    md = malloc(64);
    shake_256_hw(input, len_input, md, 64, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, 64, 32);
        printf("\n Expected Result: ");  show_array(res_s_256, 64, 32);
    }
    if (!cmpchar(md, res_s_256, 64)) printf("\n SHAKE-256 Test: \t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHAKE-256 Test: \t\033[1;31m\u274c\033[0m FAIL");
    free(md);

}

