/**
  * @file demo_mlkem.c
  * @brief Validation test for MLKEM code
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
  * @version 4.0
  **/ 

#include "demo.h"
#include "test_func.h"

void demo_mlkem_hw(unsigned int mode, unsigned int verb, INTF interface) {

    if (mode == 512) {
        // ---- MLKEM-512 ---- //
        unsigned char *pk_512;
		unsigned char *sk_512;

		pk_512 = malloc(800);
		sk_512 = malloc(1632);

		mlkem512_genkeys_hw(pk_512, sk_512, interface);

        if (verb >= 3) printf("\n pub_len: %d (bytes)", 800);
        if (verb >= 3) printf("\n pri_len: %d (bytes)", 1632);

        if (verb >= 3) { printf("\n public key: ");     show_array(pk_512, 800, 32); }
        if (verb >= 3) { printf("\n private key: ");    show_array(sk_512, 1632, 32); }

        unsigned char ss[32];
		unsigned char *ct_512;
		ct_512 = malloc(768);

		mlkem512_enc_hw(pk_512, ct_512, ss, interface);

        if (verb >= 3) printf("\n ss_len: %d (bytes)", 32);
        if (verb >= 3) printf("\n ct_len: %d (bytes)", 768);

        if (verb >= 1) { printf("\n ss: ");    show_array(ss, 32, 32); }
        if (verb >= 2) { printf("\n ct: ");    show_array(ct_512, 768, 32); }

        unsigned char ss1[32];
		unsigned int result;

		mlkem512_dec_hw(sk_512, ct_512, ss1, &result, interface);

        if (verb >= 3) printf("\n ss1_len: %d (bytes)", 32);
        if (verb >= 1) { printf("\n ss1: ");    show_array(ss1, 32, 32); }

        print_result_valid("MLKEM-512", result);

        free(sk_512);
		free(pk_512);
		free(ct_512);

    }
    else if (mode == 768) {
        // ---- MLKEM-768 ---- //
        unsigned char* pk_768;
		unsigned char* sk_768;

		pk_768 = malloc(1184);
		sk_768 = malloc(2400);

		mlkem768_genkeys_hw(pk_768, sk_768, interface);

        if (verb >= 3) printf("\n pub_len: %d (bytes)", 1184);
        if (verb >= 3) printf("\n pri_len: %d (bytes)", 2400);

        if (verb >= 3) { printf("\n public key: ");     show_array(pk_768, 1184, 32); }
        if (verb >= 3) { printf("\n private key: ");    show_array(sk_768, 2400, 32); }

        unsigned char ss[32];
		unsigned char* ct_768;
		ct_768 = malloc(1088);

		mlkem768_enc_hw(pk_768, ct_768, ss, interface);

        if (verb >= 3) printf("\n ss_len: %d (bytes)", 32);
        if (verb >= 3) printf("\n ct_len: %d (bytes)", 1088);

        if (verb >= 1) { printf("\n ss: ");    show_array(ss, 32, 32); }
        if (verb >= 2) { printf("\n ct: ");    show_array(ct_768, 1088, 32); }

        unsigned char ss1[32];
		unsigned int result = 0;

		mlkem768_dec_hw(sk_768, ct_768, ss1, &result, interface);

        if (verb >= 3) printf("\n ss1_len: %d (bytes)", 32);
        if (verb >= 1) { printf("\n ss1: ");    show_array(ss1, 32, 32); }

        print_result_valid("MLKEM-768", result);

        free(sk_768);
		free(pk_768);
		free(ct_768);
    
    }
    else {
        // ---- MLKEM-1024 ---- //
        unsigned char* pk_1024;
		unsigned char* sk_1024;

		pk_1024 = malloc(1568);
		sk_1024 = malloc(3168);

		mlkem1024_genkeys_hw(pk_1024, sk_1024, interface);

        if (verb >= 3) printf("\n pub_len: %d (bytes)", 1568);
        if (verb >= 3) printf("\n pri_len: %d (bytes)", 3168);

        if (verb >= 3) { printf("\n public key: ");     show_array(pk_1024, 1568, 32); }
        if (verb >= 3) { printf("\n private key: ");    show_array(sk_1024, 3168, 32); }

        unsigned char ss[32];
		unsigned char* ct_1024;
		ct_1024 = malloc(1568);

		mlkem1024_enc_hw(pk_1024, ct_1024, ss, interface);

        if (verb >= 3) printf("\n ss_len: %d (bytes)", 32);
        if (verb >= 3) printf("\n ct_len: %d (bytes)", 1568);

        if (verb >= 1) { printf("\n ss: ");    show_array(ss, 32, 32); }
        if (verb >= 2) { printf("\n ct: ");    show_array(ct_1024, 1568, 32); }

        unsigned char ss1[32];
		unsigned int result = 0;

		mlkem1024_dec_hw(sk_1024, ct_1024, ss1, &result, interface);

        if (verb >= 3) printf("\n ss1_len: %d (bytes)", 32);
        if (verb >= 1) { printf("\n ss1: ");    show_array(ss1, 32, 32); }

        print_result_valid("MLKEM-1024", result);

        free(sk_1024);
		free(pk_1024);
		free(ct_1024);

    }

}