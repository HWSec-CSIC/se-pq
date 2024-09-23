#include "../demo.h"
#include "test_func.h"

#define SHA256_DIGEST_LENGTH 32
#define SHA384_DIGEST_LENGTH 48
#define SHA512_DIGEST_LENGTH 64


void demo_sha2_hw(unsigned int verb, MMIO_WINDOW ms2xl) {

    // ---- SHA2 ---- //
    unsigned char* input;
    unsigned int len_input;
    unsigned char md[64]; 

    // unsigned char *exp_res_224 = "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f";
    unsigned char *exp_res_256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    unsigned char *exp_res_384 = "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b";
    unsigned char *exp_res_512 = "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e";
    // unsigned char *exp_res_512_224 = "6ed0dd02806fa89e25de060c19d3ac86cabb87d6a0ddd05c333b84f4";
    unsigned char *exp_res_512_256 = "c672b8d1ef56ed28ab87c3622c5114069bdd3ad7b8f9737498d0c01ecef0967a";

    // unsigned char res_224[28]; char2hex(exp_res_224, res_224);
    unsigned char res_256[32]; char2hex(exp_res_256, res_256);
    unsigned char res_384[48]; char2hex(exp_res_384, res_384);
    unsigned char res_512[64]; char2hex(exp_res_512, res_512);
    // unsigned char res_512_224[28]; char2hex(exp_res_512_224, res_512_224);
    unsigned char res_512_256[32]; char2hex(exp_res_512_256, res_512_256);

    input       = malloc(32);
    input[0]    = (unsigned char)('\0');
    len_input   = 0;

    /*
    // ---- sha_224 ---- //
    md = malloc(SHA224_DIGEST_LENGTH);
    sha_224(input, len_input, md);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA224_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_224, SHA224_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_224, SHA224_DIGEST_LENGTH)) printf("\n SHA-224 Test: \t\t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA-224 Test: \t\t\033[1;31m\u274c\033[0m FAIL");
    free(md);
    */

    // ---- sha_256 ---- //
    // md      = malloc(SHA256_DIGEST_LENGTH);
    sha_256_hw(input, len_input, md, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA256_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_256, SHA256_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_256, SHA256_DIGEST_LENGTH)) printf("\n SHA-256 Test: \t\t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA-256 Test: \t\t\033[1;31m\u274c\033[0m FAIL");
    // free(md);
    
    // ---- sha_384 ---- //
    // md = malloc(SHA384_DIGEST_LENGTH);
    sha_384_hw(input, len_input, md, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA384_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_384, SHA384_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_384, SHA384_DIGEST_LENGTH)) printf("\n SHA-384 Test: \t\t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA-384 Test: \t\t\033[1;31m\u274c\033[0m FAIL");
    // free(md);

    // ---- sha_512 ---- //
    // md = malloc(SHA512_DIGEST_LENGTH);
    sha_512_hw(input, len_input, md, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA512_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_512, SHA512_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_512, SHA512_DIGEST_LENGTH)) printf("\n SHA-512 Test: \t\t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA-512 Test: \t\t\033[1;31m\u274c\033[0m FAIL");
    // free(md);

    // ---- sha_512_224 ---- //
    /*
    md = malloc(SHA224_DIGEST_LENGTH);
    sha_512_224(input, len_input, md);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA224_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_512_224, SHA224_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_512_224, SHA224_DIGEST_LENGTH)) printf("\n SHA-512/224 Test: \t\t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA-512/224 Test: \t\t\033[1;31m\u274c\033[0m FAIL");
    free(md);
    */

    // ---- sha_512_256 ---- //
    // md = malloc(SHA256_DIGEST_LENGTH);
    sha_512_256_hw(input, len_input, md, ms2xl);
    if (verb >= 1) {
        printf("\n Obtained Result: ");  show_array(md, SHA256_DIGEST_LENGTH, 32);
        printf("\n Expected Result: ");  show_array(res_512_256, SHA256_DIGEST_LENGTH, 32);
    }
    if (!cmpchar(md, res_512_256, SHA256_DIGEST_LENGTH)) printf("\n SHA-512/256 Test: \t\033[1;32m\u2705\033[0m VALID");
    else printf("\n SHA-512/256 Test: \t\033[1;31m\u274c\033[0m FAIL");
    // free(md);
    
}