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

void test_slhdsa_hw(INTF interface, const slh_ph_func_t *ph, const char mode[12], unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_si, time_result* tr_ve)
{

    const char* msg_string = "Hello, this is the SE of QUBIP project";
    const char* ctx_string = "";

    const unsigned int len_msg = strlen((const char*) msg_string);// / 2;
    const unsigned int ctx_len = strlen((const char*) ctx_string) / 2;

    unsigned char msg[len_msg]; memset(msg, 0, len_msg); memcpy(msg, msg_string, len_msg); // char2hex((unsigned char*) msg_string, msg);
    unsigned char ctx[ctx_len]; memset(ctx, 0, ctx_len); char2hex((unsigned char*) ctx_string, ctx);

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
    unsigned char* sig;
    unsigned int sig_len;
    unsigned int result = 1;
    unsigned char msg2[50];
    unsigned int len_msg2;

    if (!memcmp(mode, "shake-128-f", 12)) {
        pri_len = 64;
        pub_len = 32;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 17088;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "shake-128-s", 12)) {
        pri_len = 64;
        pub_len = 32;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 7856;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "shake-192-f", 12)) {
        pri_len = 96;
        pub_len = 48;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 35664;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "shake-192-s", 12)) {
        pri_len = 96;
        pub_len = 48;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 16224;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "shake-256-f", 12)) {
        pri_len = 128;
        pub_len = 64;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 49856;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "shake-256-s", 12)) {
        pri_len = 128;
        pub_len = 64;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 29792;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "sha-2-128-f", 12)) {
        pri_len = 64;
        pub_len = 32;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 17088;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "sha-2-128-s", 12)) {
        pri_len = 64;
        pub_len = 32;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 7856;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "sha-2-192-f", 12)) {
        pri_len = 96;
        pub_len = 48;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 35664;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "sha-2-192-s", 12)) {
        pri_len = 96;
        pub_len = 48;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 16224;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "sha-2-256-f", 12)) {
        pri_len = 128;
        pub_len = 64;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 49856;
        sig = malloc(sig_len);
    }
    else if (!memcmp(mode, "sha-2-256-s", 12)) {
        pri_len = 128;
        pub_len = 64;
        pri_key = malloc(pri_len);
        pub_key = malloc(pub_len);

        sig_len = 29792;
        sig = malloc(sig_len);
    }

    bool ext_key  	= true;
    uint8_t key_id	= 0;

    for (int test = 1; test <= n_test; test++) {

        if (verb >= 1) printf("\n test: %d", test);

        result = 1;

        // ---- SLHDSA ---- //
        if (!memcmp(mode, "shake-128-f", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_shake_128_f_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_shake_128_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_shake_128_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "shake-128-s", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_shake_128_s_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_shake_128_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_shake_128_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "shake-192-f", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_shake_192_f_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_shake_192_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_shake_192_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "shake-192-s", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_shake_192_s_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_shake_192_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_shake_192_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "shake-256-f", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_shake_256_f_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_shake_256_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_shake_256_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

         }

        else if (!memcmp(mode, "shake-256-s", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_shake_256_s_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_shake_256_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_shake_256_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

         }
        else if (!memcmp(mode, "sha-2-128-f", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_sha2_128_f_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_sha2_128_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_sha2_128_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "sha-2-128-s", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_sha2_128_s_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_sha2_128_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_sha2_128_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "sha-2-192-f", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_sha2_192_f_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_sha2_192_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_sha2_192_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "sha-2-192-s", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_sha2_192_s_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_sha2_192_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_sha2_192_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

        }

        else if (!memcmp(mode, "sha-2-256-f", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_sha2_256_f_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_sha2_256_f_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_sha2_256_f_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

         }

        else if (!memcmp(mode, "sha-2-256-s", 12))
        {

            // -----------------
            // keygen
            start_t = timeInMicroseconds();
            slhdsa_sha2_256_s_gen_keys_hw(pri_key, pub_key, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN keys_hw: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

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
            slhdsa_sha2_256_s_ph_sign_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pri_key, sig, &sig_len, ext_key, &key_id, interface);
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
            slhdsa_sha2_256_s_ph_verify_hw(ph, msg, len_msg, ctx, ctx_len, (const unsigned char*)pub_key, (const unsigned char*)sig, sig_len, &result, ext_key, &key_id, interface);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time = stop_t - start_t;
            time_total_ve += time;

            if (test == 1)										tr_ve->time_min_value = time;
            else if (tr_ve->time_min_value > time)		tr_ve->time_min_value = time;
            if (tr_ve->time_max_value < time)				tr_ve->time_max_value = time;

            if (result) tr_ve->val_result++;

         }

    }

    tr_kg->time_mean_value = (uint64_t)(time_total_kg / n_test);
    tr_si->time_mean_value = (uint64_t)(time_total_si / n_test);
    tr_ve->time_mean_value = (uint64_t)(time_total_ve / n_test);

}
