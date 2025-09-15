/**
  * @file demo_mldsa.c
  * @brief Validation test for MLDSA code
  *
  * @section License
  *
  * MIT License
  *
  * Copyright (c) 2024 Eros Camacho
  *
  * Permission is hereby granted, free of charge, to any person obtaining a copy
  * of this software and associated documentation files (the "Software"), to deal
  * in the Software without restriction, including without limitation the rights
  * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  * copies of the Software, and to permit persons to whom the Software is
  * furnished to do so, subject to the following conditions:
  *
  * The above copyright notice and this permission notice shall be included in all
  * copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  * SOFTWARE.
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 5.0
  **/

#include "demo.h"

unsigned int TEST;

#define MAX_LINE 32000

static void read_json_key(unsigned int in_test, const char* mode,
    unsigned char* seed, unsigned int* seed_len,
    unsigned char* pk, unsigned int* pk_len,
    unsigned char* sk, unsigned int* sk_len
) {

    char name[100];
    char buf[100];

    sprintf(name, "%s", "src/nist/mldsa_");
    strcat(name, mode);
    sprintf(buf, "%s", "_key.json");
    strcat(name, buf);

    FILE* file = fopen(name, "r");
    if (file == NULL) {
        perror("Unable to open file");
        return;
    }

    char line[MAX_LINE];
    char seed_char[MAX_LINE], pk_char[MAX_LINE], sk_char[MAX_LINE];
    char test[10];

    memset(seed_char, '\0', MAX_LINE);
    memset(pk_char, '\0', MAX_LINE);
    memset(sk_char, '\0', MAX_LINE);

    unsigned int next_line = 0;

    while (fgets(line, sizeof(line), file)) {
        // printf("\n %s", line);

        if (next_line) {
            if (strstr(line, "seed")) {
                sscanf(line, " \"seed\": \"%s\",", seed_char);
                seed_char[strlen(seed_char) - 1] = '\0'; // remove ,
                seed_char[strlen(seed_char) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "pk")) {
                sscanf(line, " \"pk\": \"%s\",", pk_char);
                pk_char[strlen(pk_char) - 1] = '\0'; // remove ,
                pk_char[strlen(pk_char) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "sk")) {
                sscanf(line, " \"sk\": \"%s\",", sk_char);
                sk_char[strlen(sk_char) - 1] = '\0'; // remove "
            }
        }

        if (strstr(line, "tcId")) {
            memset(test, '\0', 10);
            sscanf(line, " \"tcId\": %s,", test);
            test[strlen(test) - 1] = '\0'; // remove ,

            if (atoi(test) == in_test) {
                next_line = 1;
            }
            else {
                next_line = 0;
            }
        }

    }

    char2hex(seed_char, seed);  *seed_len   = strlen(seed_char) / 2;
    char2hex(pk_char, pk);      *pk_len     = strlen(pk_char) / 2;
    char2hex(sk_char, sk);      *sk_len     = strlen(sk_char) / 2;

    fclose(file);

}

static void read_json_sign( unsigned int in_test,   const char* mode, 
                            unsigned char* msg,     unsigned int* msg_len,
                            unsigned char* pk,      unsigned int* pk_len,
                            unsigned char* sk,      unsigned int* sk_len,
                            unsigned char* ctx,     unsigned int* ctx_len, 
                            unsigned char* sig,     unsigned int* sig_len
                            ) {
    
    char name[100];
    char buf[100];

    sprintf(name, "%s", "src/nist/mldsa_");
    strcat(name, mode);
    sprintf(buf, "%s", "_sign.json");
    strcat(name, buf);

    FILE* file = fopen(name, "r");
    if (file == NULL) {
        perror("Unable to open file"); 
        return;
    }

    char line[MAX_LINE];
    char message[MAX_LINE], pk_char[MAX_LINE], sk_char[MAX_LINE], context[MAX_LINE], signature[MAX_LINE];
    char test[10];

    memset(message, '\0', MAX_LINE);
    memset(pk_char, '\0', MAX_LINE);
    memset(sk_char, '\0', MAX_LINE);
    memset(context, '\0', MAX_LINE);
    memset(signature, '\0', MAX_LINE);

    unsigned int next_line = 0;

    while (fgets(line, sizeof(line), file)) {
        // printf("\n %s", line);

        if (next_line) {
            if (strstr(line, "message")) {
                sscanf(line, " \"message\": \"%s\",", message);
                message[strlen(message) - 1] = '\0'; // remove ,
                message[strlen(message) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "pk")) {
                sscanf(line, " \"pk\": \"%s\",", pk_char);
                pk_char[strlen(pk_char) - 1] = '\0'; // remove ,
                pk_char[strlen(pk_char) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "sk")) {
                sscanf(line, " \"sk\": \"%s\",", sk_char);
                sk_char[strlen(sk_char) - 1] = '\0'; // remove ,
                sk_char[strlen(sk_char) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "context")) {
                sscanf(line, " \"context\": \"%s\",", context);
                context[strlen(context) - 1] = '\0'; // remove ,
                context[strlen(context) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "signature")) {
                sscanf(line, " \"signature\": \"%s\",", signature);
                signature[strlen(signature) - 1] = '\0'; // remove "
            }
        }

        if (strstr(line, "tcId")) {
            memset(test, '\0', 10);
            sscanf(line, " \"tcId\": %s,", test);
            test[strlen(test) - 1] = '\0'; // remove ,

            if (atoi(test) == in_test) {
                next_line = 1;
            }
            else {
                next_line = 0;
            }
        }
        
    }

    /*
    printf("Message: %s\n", message);
    printf("Public Key: %s\n", pk_char);
    printf("Secret Key: %s\n", sk_char);
    printf("Context: %s\n", context);
    printf("Signature: %s\n", signature);
    */

    char2hex(message, msg);     *msg_len = strlen(message) / 2;
    char2hex(pk_char, pk);      *pk_len = strlen(pk_char) / 2;
    char2hex(sk_char, sk);      *sk_len = strlen(sk_char) / 2;
    char2hex(context, ctx);     *ctx_len = strlen(context) / 2;
    char2hex(signature, sig);   *sig_len = strlen(signature) / 2;

    fclose(file);

}

static void read_json_ver(  unsigned int in_test, const char* mode,
                            unsigned char* msg, unsigned int* msg_len,
                            unsigned char* pk, unsigned int* pk_len,
                            unsigned char* sk, unsigned int* sk_len,
                            unsigned char* ctx, unsigned int* ctx_len,
                            unsigned char* sig, unsigned int* sig_len,
                            unsigned int* exp_res
) {

    char name[100];
    char buf[100];

    sprintf(name, "%s", "src/nist/mldsa_");
    strcat(name, mode);
    sprintf(buf, "%s", "_ver.json");
    strcat(name, buf);

    FILE* file = fopen(name, "r");
    if (file == NULL) {
        perror("Unable to open file");
        return;
    }

    char line[MAX_LINE];
    char message[MAX_LINE], pk_char[MAX_LINE], sk_char[MAX_LINE], context[MAX_LINE], signature[MAX_LINE], result[MAX_LINE];
    char test[10];

    memset(message, '\0', MAX_LINE);
    memset(pk_char, '\0', MAX_LINE);
    memset(sk_char, '\0', MAX_LINE);
    memset(context, '\0', MAX_LINE);
    memset(signature,   '\0', MAX_LINE);
    memset(result,      '\0', MAX_LINE);

    unsigned int next_line = 0;
    *exp_res = 1;

    while (fgets(line, sizeof(line), file)) {

        if (next_line) {
            if (strstr(line, "reason")) {
                sscanf(line, " \"reason\": \"%s\",", result);
                if (strstr(result, "valid") != NULL) {
                    *exp_res = 0; // valid
                }
                else {
                    *exp_res = -1; // no-valid
                }
            }
            else if (strstr(line, "message")) {
                sscanf(line, " \"message\": \"%s\",", message);
                message[strlen(message) - 1] = '\0'; // remove ,
                message[strlen(message) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "pk")) {
                sscanf(line, " \"pk\": \"%s\",", pk_char);
                pk_char[strlen(pk_char) - 1] = '\0'; // remove ,
                pk_char[strlen(pk_char) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "sk")) {
                sscanf(line, " \"sk\": \"%s\",", sk_char);
                sk_char[strlen(sk_char) - 1] = '\0'; // remove ,
                sk_char[strlen(sk_char) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "context")) {
                sscanf(line, " \"context\": \"%s\",", context);
                context[strlen(context) - 1] = '\0'; // remove ,
                context[strlen(context) - 1] = '\0'; // remove "
            }
            else if (strstr(line, "signature")) {
                sscanf(line, " \"signature\": \"%s\",", signature);
                signature[strlen(signature) - 1] = '\0'; // remove ,
                signature[strlen(signature) - 1] = '\0'; // remove "
            }
        }

        if (strstr(line, "tcId")) {
            memset(test, '\0', 10);
            sscanf(line, " \"tcId\": %s,", test);
            test[strlen(test) - 1] = '\0'; // remove ,

            if (atoi(test) == in_test) {
                next_line = 1;
            }
            else {
                next_line = 0;
            }
        }

    }

    /*
    printf("Message: %s\n", message);
    printf("Public Key: %s\n", pk_char);
    printf("Secret Key: %s\n", sk_char);
    printf("Context: %s\n", context);
    printf("Signature: %s\n", signature);
    printf("Expected result: %d\n", *exp_res);
    */

    char2hex(message, msg);     *msg_len = strlen(message) / 2;
    char2hex(pk_char, pk);      *pk_len = strlen(pk_char) / 2;
    char2hex(sk_char, sk);      *sk_len = strlen(sk_char) / 2;
    char2hex(context, ctx);     *ctx_len = strlen(context) / 2;
    char2hex(signature, sig);   *sig_len = strlen(signature) / 2;

    fclose(file);

}

static void demo_mldsa_nist_key(INTF interface, const char* mode, unsigned int verb) {


    unsigned int result = 1;

    // ---- EDDSA ---- //

    unsigned char seed[32];
    unsigned char* pk;
    unsigned char* sk;
    unsigned char* exp_pk;
    unsigned char* exp_sk;

    unsigned int seed_len;
    unsigned int pk_len;
    unsigned int sk_len;

    printf("\n\n --- NIST TEST MLDSA-%s-KEY --- \n", mode);

    // --- SIGNATURE --- // 
    if (!memcmp(mode, "44", 2)) {
        pk_len = 1312;
        sk_len = 2560;
    }
    else if (!memcmp(mode, "65", 2)) {
        pk_len = 1952;
        sk_len = 4032;
    }
    else if (!memcmp(mode, "87", 2)) {
        pk_len = 2592;
        sk_len = 4896;
    }

    pk = (unsigned char*)malloc(pk_len);
    sk = (unsigned char*)malloc(sk_len);
    exp_pk = (unsigned char*)malloc(pk_len);
    exp_sk = (unsigned char*)malloc(sk_len);

    for (TEST = 1; TEST < 16; TEST++) {
        // Read json
        // read_json_sign(test, "44", NULL, &msg_len, pk, &pk_len, sk, &sk_len, NULL, &ctx_len, exp_sig, &exp_sig_len);
        read_json_key(TEST, mode, seed, &seed_len, exp_pk, &pk_len, exp_sk, &sk_len);

        if (verb >= 3) { printf("\n seed: ");                show_array(seed, 32, 32); }
        if (verb >= 3) { printf("\n exp. public key: ");     show_array(exp_pk, pk_len, 32); }
        if (verb >= 3) { printf("\n exp. private key: ");    show_array(exp_sk, sk_len, 32); }

        

        if (!memcmp(mode, "44", 2)) {
            mldsa44_genkeys_hw(seed, pk, sk, interface);
        }
        else if (!memcmp(mode, "65", 2)) {
            mldsa65_genkeys_hw(seed, pk, sk, interface);
        }
        else if (!memcmp(mode, "87", 2)) {
            mldsa87_genkeys_hw(seed, pk, sk, interface);
        }

        if (verb >= 3) { printf("\n public key: ");     show_array(pk, pk_len, 32); }
        if (verb >= 3) { printf("\n private key: ");    show_array(sk, sk_len, 32); }

        char buf[30];
        sprintf(buf, "Test: %d", TEST);
        print_result_valid(buf, (memcmp(pk, exp_pk, pk_len) || memcmp(sk, exp_sk, sk_len))); // valid = 0
    }

    /* free(pk);
    free(sk);
    free(exp_pk);
    free(exp_sk); */
}

static void demo_mldsa_nist_sign(INTF interface, const char* mode, unsigned int verb) {


    unsigned int result = 1;
    TEST = 0;

    // ---- EDDSA ---- //

    unsigned char* msg;
    unsigned char* pk;
    unsigned char* sk;
    unsigned char* ctx;
    unsigned char* sig;
    unsigned char* exp_sig;

    unsigned int msg_len;
    unsigned int pk_len;
    unsigned int sk_len;
    unsigned int ctx_len;
    unsigned int exp_sig_len;
    unsigned int sig_len;

    printf("\n\n --- NIST TEST MLDSA-%s-SIGN --- \n", mode);

    msg = (unsigned char*)malloc(10000);
    ctx = (unsigned char*)malloc(1024);

    // --- SIGNATURE --- // 
    if (!memcmp(mode, "44", 2)) {
        pk_len = 1312;
        sk_len = 2560;
        sig_len = 2420;
        exp_sig_len = 2420;
    }
    else if (!memcmp(mode, "65", 2)) {
        pk_len = 1952;
        sk_len = 4032;
        sig_len = 3309;
        exp_sig_len = 3309;
    }
    else if (!memcmp(mode, "87", 2)) {
        pk_len = 2592;
        sk_len = 4896;
        sig_len = 4627;
        exp_sig_len = 4627;
    }
    
    pk = (unsigned char*)malloc(pk_len);
    sk = (unsigned char*)malloc(sk_len);
    sig = (unsigned char*)malloc(sig_len);
    exp_sig = (unsigned char*)malloc(exp_sig_len);

    for (TEST = 1; TEST < 16; TEST++) {
        // Read json
        // read_json_sign(test, "44", NULL, &msg_len, pk, &pk_len, sk, &sk_len, NULL, &ctx_len, exp_sig, &exp_sig_len);
        read_json_sign(TEST, mode, msg, &msg_len, pk, &pk_len, sk, &sk_len, ctx, &ctx_len, exp_sig, &exp_sig_len);

        if (verb >= 3) { printf("\n public key: ");     show_array(pk, pk_len, 32); }
        if (verb >= 3) { printf("\n private key: ");    show_array(sk, sk_len, 32); }
        if (verb >= 3) { printf("\n ctx: ");            show_array(ctx, ctx_len, 32); }
        if (verb >= 3) { printf("\n ctx_len: %d", ctx_len); }
        if (verb >= 3) { printf("\n msg: ");            show_array(msg, msg_len, 32); }
        if (verb >= 3) { printf("\n msg_len: %d", msg_len); }
        if (verb >= 3) { printf("\n exp. signature: "); show_array(exp_sig, exp_sig_len, 32); }
        if (verb >= 3) { printf("\n exp_sig_len: %d", exp_sig_len); }

        if (!memcmp(mode, "44", 2)) {
            mldsa44_sign_hw(msg, msg_len, sk, sig, &sig_len, ctx, ctx_len, interface);
        }
        else if (!memcmp(mode, "65", 2)) {
            mldsa65_sign_hw(msg, msg_len, sk, sig, &sig_len, ctx, ctx_len, interface);
        }
        else if (!memcmp(mode, "87", 2)) {
            mldsa87_sign_hw(msg, msg_len, sk, sig, &sig_len, ctx, ctx_len, interface);
        }

        if (verb >= 3) { printf("\n signature: ");          show_array(sig, sig_len, 32); }
        if (verb >= 3) { printf("\n sig_len: %d", sig_len); }

        char buf[30];
        sprintf(buf, "Test: %d", TEST);
        print_result_valid(buf, memcmp(sig, exp_sig, sig_len)); // valid = 0
    }

    /* free(pk);
    free(sk);
    free(exp_sig);
    free(sig);

    free(msg);
    free(ctx); */

}

static void demo_mldsa_nist_ver(INTF interface, const char* mode, unsigned int verb) {

    
    // ---- EDDSA ---- //

    unsigned char* msg;
    unsigned char* pk;
    unsigned char* sk;
    unsigned char* ctx;
    unsigned char* sig;

    unsigned int msg_len;
    unsigned int pk_len;
    unsigned int sk_len;
    unsigned int ctx_len;
    unsigned int sig_len;

    unsigned int res;
    unsigned int exp_res;

    printf("\n\n --- NIST TEST MLDSA-%s-VERIFY --- \n", mode);

    msg = (unsigned char*)malloc(10000);
    ctx = (unsigned char*)malloc(1024);

    // --- SIGNATURE --- // 
    if (!memcmp(mode, "44", 2)) {
        pk_len = 1312;
        sk_len = 2560;
        sig_len = 2420;
    }
    else if (!memcmp(mode, "65", 2)) {
        pk_len = 1952;
        sk_len = 4032;
        sig_len = 3309;
    }
    else if (!memcmp(mode, "87", 2)) {
        pk_len = 2592;
        sk_len = 4896;
        sig_len = 4627;
    }


    pk = (unsigned char*)malloc(pk_len);
    sk = (unsigned char*)malloc(sk_len);
    sig = (unsigned char*)malloc(sig_len);

    for (int TEST = 1; TEST < 16; TEST++) {
        // Read json
        // read_json_sign(test, "44", NULL, &msg_len, pk, &pk_len, sk, &sk_len, NULL, &ctx_len, exp_sig, &exp_sig_len);
        read_json_ver(TEST, mode, msg, &msg_len, pk, &pk_len, sk, &sk_len, ctx, &ctx_len, sig, &sig_len, &exp_res);

        if (verb >= 3) { printf("\n public key: ");     show_array(pk, pk_len, 32); }
        if (verb >= 3) { printf("\n private key: ");    show_array(sk, sk_len, 32); }
        if (verb >= 3) { printf("\n ctx: ");            show_array(ctx, ctx_len, 32); }
        if (verb >= 3) { printf("\n ctx_len: %d", ctx_len); }
        if (verb >= 3) { printf("\n msg: ");            show_array(msg, msg_len, 32); }
        if (verb >= 3) { printf("\n msg_len: %d", msg_len); }
        if (verb >= 3) { printf("\n signature: ");          show_array(sig, sig_len, 32); }
        if (verb >= 3) { printf("\n sig_len: %d", sig_len); }
        if (verb >= 3) { printf("\n expected result: %d", exp_res); }

        if (!memcmp(mode, "44", 2)) {
            mldsa44_verify_hw(msg, msg_len, pk, sig, sig_len, ctx, ctx_len, &res, interface);
        }
        else if (!memcmp(mode, "65", 2)) {
            mldsa65_verify_hw(msg, msg_len, pk, sig, sig_len, ctx, ctx_len, &res, interface);
        }
        else if (!memcmp(mode, "87", 2)) {
            mldsa87_verify_hw(msg, msg_len, pk, sig, sig_len, ctx, ctx_len, &res, interface);
        }

        if (verb >= 3) { printf("\n result: %d", res); }

        char buf[30];
        sprintf(buf, "Test: %d", TEST);
        print_result_valid(buf, !(res == exp_res)); // valid = 0; res == exp_res = 1; !(res == exp_res) = 0 (valid)

        if (exp_res == -1) {
            printf("\texp_res: (no-valid)");

            if(res == -1)   printf("\tres: (no-valid)");
            else            printf("\tres: (valid)");
        }
        else {
            printf("\texp_res: (valid)");

            if (res == -1)      printf("\tres: (no-valid)");
            else                printf("\tres: (valid)");
        
        }         
    }

    /* free(pk);
    free(sk);
    free(sig);

    free(msg);
    free(ctx); */

}


void demo_mldsa_nist(INTF interface, unsigned int verb) {

    demo_mldsa_nist_key(interface, "44", verb);
    demo_mldsa_nist_key(interface, "65", verb);
    demo_mldsa_nist_key(interface, "87", verb);

    demo_mldsa_nist_sign(interface, "44", verb);
    demo_mldsa_nist_sign(interface, "65", verb);
    demo_mldsa_nist_sign(interface, "87", verb);

    demo_mldsa_nist_ver(interface, "44", verb);
    demo_mldsa_nist_ver(interface, "65", verb);
    demo_mldsa_nist_ver(interface, "87", verb);

}

