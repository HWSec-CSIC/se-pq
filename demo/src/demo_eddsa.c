/**
  * @file demo_eddsa.c
  * @brief Validation test for EdDSA code
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

void demo_eddsa_hw(unsigned int mode, unsigned int verb, INTF interface) {

#ifdef AXI
	unsigned int clk_index = 0;
	float clk_frequency;
	float set_clk_frequency = FREQ_EDDSA;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int) verb);
#endif

    // ---- EDDSA ---- //
    if (mode == 25519) {
        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        eddsa25519_genkeys_hw(&pri_key, &pub_key, &pri_len, &pub_len, interface);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }


        unsigned char msg[] = "Hello, this is the SE of QUBIP project";

        unsigned char* sig; 
        unsigned int sig_len;
        eddsa25519_sign_hw(msg, strlen(msg), pri_key, pri_len, pub_key, pub_len, &sig, &sig_len, interface);

        if (verb >= 3)
        {
            printf("\n signature: ");
            show_array(sig, sig_len, 32);
        }

        unsigned int result;
        eddsa25519_verify_hw(msg, strlen(msg), pub_key, pub_len, sig, sig_len, &result, interface);

        print_result_valid("EdDSA-25519", !result);
    }
    else {
        /*
        unsigned char* pub_key;
        unsigned char* pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        eddsa448_genkeys(&pri_key, &pub_key, &pri_len, &pub_len);

        if (verb >= 2) printf("\n pub_len: %d (bytes)", pub_len);
        if (verb >= 2) printf("\n pri_len: %d (bytes)", pri_len);

        if (verb >= 3) { printf("\n public key: ");   show_array(pub_key, pub_len, 32); }
        if (verb >= 3) { printf("\n private key: "); show_array(pri_key, pri_len, 32); }


        unsigned char msg[50] = "Hello, this is the SE of QUBIP project";

        unsigned char* sig;
        unsigned int sig_len;
        eddsa448_sign(msg, strlen(msg), (const unsigned char*)pri_key, pri_len, &sig, &sig_len);

        if (verb >= 3) { printf("\n signature: ");   show_array(sig, sig_len, 32); }

        unsigned int result = 1;
        eddsa448_verify(msg, strlen(msg), (const unsigned char*)pub_key, pub_len, (const unsigned char*)sig, sig_len, &result);

        print_result_valid("EdDSA-448", result);
        */
    }
#ifdef AXI
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif
}