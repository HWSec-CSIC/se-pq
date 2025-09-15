/**
  * @file demo_mldsa_speed.c
  * @brief Performance test for MLDSA code
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
#include "test_func.h"

void test_mldsa_hw(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_si, time_result* tr_ve, INTF interface)
{

    uint64_t start_t, stop_t;

    //-- Initialize to avoid 1st measure error
    start_t = timeInMicroseconds();
    stop_t = timeInMicroseconds();

    tr_kg->time_mean_value = 0;
    tr_kg->time_max_value = 0;
    tr_kg->time_min_value = 0;
    tr_kg->val_result = 0;

    tr_si->time_mean_value = 0;
    tr_si->time_max_value = 0;
    tr_si->time_min_value = 0;
    tr_si->val_result = 0;

    tr_ve->time_mean_value = 0;
    tr_ve->time_max_value = 0;
    tr_ve->time_min_value = 0;
    tr_ve->val_result = 0;

    uint64_t time = 0;
    uint64_t time_total_kg = 0;
    uint64_t time_total_ve = 0;
    uint64_t time_total_si = 0;

    unsigned char* pub_key;
    unsigned char* pri_key;
    unsigned int pub_len;
    unsigned int pri_len;
    unsigned char msg[50] = "Hello, this is the SE of QUBIP project";
    unsigned char* sig;
    unsigned int sig_len;
    unsigned int result = 1;
    unsigned char msg2[50];
    unsigned int len_msg2;

    unsigned char seed_char[65] = "D71361C000F9A7BC99DFB425BCB6BB27C32C36AB444FF3708B2D93B4E66D5B5B"; // NIST TEST
    unsigned char seed[32];
    char2hex(seed_char, seed);

    if (mode == 44) {
        pri_len = 2560;
        pub_len = 1312;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 2420;
        sig = malloc(sig_len);
    }
    else if(mode == 65) {
        pri_len = 4032;
        pub_len = 1952;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 3309;
        sig = malloc(sig_len);
    }
    else {
        pri_len = 4896;
        pub_len = 2592;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 4627;
        sig = malloc(sig_len);
    }

    for (int test = 1; test <= n_test; test++) {

        if (verb >= 1) printf("\n test: %d", test);

        result = 1;

        // ---- MLDSA ---- //
        if (mode == 44)
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            mldsa44_genkeys_hw(seed, pub_key, pri_key, interface);

            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_kg += time;

            if (test == 1)										tr_kg->time_min_value = time;
            else if (tr_kg->time_min_value > time)		tr_kg->time_min_value = time;
            if (tr_kg->time_max_value < time)				tr_kg->time_max_value = time;

            if (verb >= 2)
                printf("\n pub_len: %d (bytes)", pub_len);
            if (verb >= 2)
                printf("\n pri_len: %d (bytes)", pri_len);

            if (verb >= 3)
            {
                printf("\n public key: ");
                show_array(pub_key, pub_len, 32);
            }
            if (verb >= 3)
            {
                printf("\n private key: ");
                show_array(pri_key, pri_len, 32);
            }

            // sign_hw
            start_t = timeInMicroseconds();
            mldsa44_sign_hw(msg, strlen(msg), (unsigned char*)pri_key, sig, &sig_len, NULL, 0, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW SIGN: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_si += time;

            if (test == 1)										tr_si->time_min_value = time;
            else if (tr_si->time_min_value > time)		tr_si->time_min_value = time;
            if (tr_si->time_max_value < time)				tr_si->time_max_value = time;

            if (verb >= 3)
            {
                printf("\n signature: ");
                show_array(sig, sig_len, 32);
            }

            // dec_hw

            start_t = timeInMicroseconds();
            mldsa44_verify_hw(msg, strlen(msg), (unsigned char*)pub_key, (unsigned char*)sig, sig_len, NULL, 0, &result, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (!(result)) tr_ve->val_result++;

        }

        // ---- MLDSA ---- //
        if (mode == 65)
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            mldsa65_genkeys_hw(seed, pub_key, pri_key, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_kg += time;

            if (test == 1)										tr_kg->time_min_value = time;
            else if (tr_kg->time_min_value > time)		tr_kg->time_min_value = time;
            if (tr_kg->time_max_value < time)				tr_kg->time_max_value = time;

            if (verb >= 2)
                printf("\n pub_len: %d (bytes)", pub_len);
            if (verb >= 2)
                printf("\n pri_len: %d (bytes)", pri_len);

            if (verb >= 3)
            {
                printf("\n public key: ");
                show_array(pub_key, pub_len, 32);
            }
            if (verb >= 3)
            {
                printf("\n private key: ");
                show_array(pri_key, pri_len, 32);
            }

            // sign_hw
            start_t = timeInMicroseconds();
            mldsa65_sign_hw(msg, strlen(msg), (unsigned char*)pri_key, sig, &sig_len, NULL, 0, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW SIGN: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_si += time;

            if (test == 1)										tr_si->time_min_value = time;
            else if (tr_si->time_min_value > time)		tr_si->time_min_value = time;
            if (tr_si->time_max_value < time)				tr_si->time_max_value = time;

            if (verb >= 3)
            {
                printf("\n signature: ");
                show_array(sig, sig_len, 32);
            }

            // dec_hw

            start_t = timeInMicroseconds();
            mldsa65_verify_hw(msg, strlen(msg), (unsigned char*)pub_key, (unsigned char*)sig, sig_len, NULL, 0, &result, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (!(result)) tr_ve->val_result++;

        }

        if (mode == 87)
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            mldsa87_genkeys_hw(seed, pub_key, pri_key, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_kg += time;

            if (test == 1)										tr_kg->time_min_value = time;
            else if (tr_kg->time_min_value > time)		tr_kg->time_min_value = time;
            if (tr_kg->time_max_value < time)				tr_kg->time_max_value = time;

            if (verb >= 2)
                printf("\n pub_len: %d (bytes)", pub_len);
            if (verb >= 2)
                printf("\n pri_len: %d (bytes)", pri_len);

            if (verb >= 3)
            {
                printf("\n public key: ");
                show_array(pub_key, pub_len, 32);
            }
            if (verb >= 3)
            {
                printf("\n private key: ");
                show_array(pri_key, pri_len, 32);
            }

            // sign_hw
            start_t = timeInMicroseconds();
            mldsa87_sign_hw(msg, strlen(msg), (unsigned char*)pri_key, sig, &sig_len, NULL, 0, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW SIGN: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_si += time;

            if (test == 1)										tr_si->time_min_value = time;
            else if (tr_si->time_min_value > time)		tr_si->time_min_value = time;
            if (tr_si->time_max_value < time)				tr_si->time_max_value = time;

            if (verb >= 3)
            {
                printf("\n signature: ");
                show_array(sig, sig_len, 32);
            }

            // dec_hw

            start_t = timeInMicroseconds();
            mldsa87_verify_hw(msg, strlen(msg), (unsigned char*)pub_key, (unsigned char*)sig, sig_len, NULL, 0, &result, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (!(result)) tr_ve->val_result++;

        }

    }

    tr_kg->time_mean_value = (uint64_t)(time_total_kg / n_test);
    tr_si->time_mean_value = (uint64_t)(time_total_si / n_test);
    tr_ve->time_mean_value = (uint64_t)(time_total_ve / n_test);

}