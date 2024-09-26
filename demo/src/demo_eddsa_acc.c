/**
  * @file demo_eddsa_speed.c
  * @brief Performance test for EdDSA code
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

#include <crypto_api_sw.h>

void test_eddsa_acc(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg_hw, time_result* tr_si_hw, time_result* tr_ve_hw, time_result* tr_kg_sw, time_result* tr_si_sw, time_result* tr_ve_sw, INTF interface)
{

#ifdef AXI
    unsigned int clk_index = 0;
    float clk_frequency;
    float set_clk_frequency = FREQ_EDDSA;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif

    uint64_t start_t_hw, stop_t_hw;
    uint64_t start_t_sw, stop_t_sw;

    //-- Initialize to avoid 1st measure error
    start_t_hw = timeInMicroseconds();
    stop_t_hw = timeInMicroseconds();
    start_t_sw = timeInMicroseconds();
    stop_t_sw = timeInMicroseconds();

    tr_kg_hw->time_mean_value = 0;
    tr_kg_hw->time_max_value = 0;
    tr_kg_hw->time_min_value = 0;
    tr_kg_hw->val_result = 0;

    tr_kg_sw->time_mean_value = 0;
    tr_kg_sw->time_max_value = 0;
    tr_kg_sw->time_min_value = 0;
    tr_kg_sw->val_result = 0;

    tr_si_hw->time_mean_value = 0;
    tr_si_hw->time_max_value = 0;
    tr_si_hw->time_min_value = 0;
    tr_si_hw->val_result = 0;

    tr_si_sw->time_mean_value = 0;
    tr_si_sw->time_max_value = 0;
    tr_si_sw->time_min_value = 0;
    tr_si_sw->val_result = 0;

    tr_ve_hw->time_mean_value = 0;
    tr_ve_hw->time_max_value = 0;
    tr_ve_hw->time_min_value = 0;
    tr_ve_hw->val_result = 0;

    tr_ve_sw->time_mean_value = 0;
    tr_ve_sw->time_max_value = 0;
    tr_ve_sw->time_min_value = 0;
    tr_ve_sw->val_result = 0;

    uint64_t time_hw = 0;
    uint64_t time_total_kg_hw = 0;
    uint64_t time_total_ve_hw = 0;
    uint64_t time_total_si_hw = 0;

    uint64_t time_sw = 0;
    uint64_t time_total_kg_sw = 0;
    uint64_t time_total_ve_sw = 0;
    uint64_t time_total_si_sw = 0;

    unsigned char* pub_key;
    unsigned char* pub_key_sw;
    unsigned char* pri_key;
    unsigned char* pri_key_sw;
    unsigned int pub_len;
    unsigned int pub_len_sw;
    unsigned int pri_len;
    unsigned int pri_len_sw;
    unsigned char msg[] = "Hello, this is the SE of QUBIP project";
    unsigned char* sig;
    unsigned char* sig_sw;
    unsigned int sig_len;
    unsigned int sig_len_sw;
    unsigned int result = 1;

    /*
    if (mode == 25519)          printf("\n\n -- Test EdDSA-25519 --");
    if (mode == 448)            printf("\n\n -- Test EdDSA-448 --");
    */

    for (int test = 1; test <= n_test; test++) {

        if (verb >= 1) printf("\n test: %d", test);

        result = 1;

        // ---- EDDSA ---- //
        if (mode == 25519)
        {

            // -----------------
            // keygen
            start_t_sw = timeInMicroseconds();
            eddsa25519_genkeys(&pri_key_sw, &pub_key_sw, &pri_len_sw, &pub_len_sw);
            stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

            start_t_hw = timeInMicroseconds();
            eddsa25519_genkeys_hw(&pri_key, &pub_key, &pri_len, &pub_len, interface);
            stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));


            time_sw = stop_t_sw - start_t_sw;
            time_total_kg_sw += time_sw;
            time_hw = stop_t_hw - start_t_hw;
            time_total_kg_hw += time_hw;

            if (test == 1)										tr_kg_sw->time_min_value = time_sw;
            else if (tr_kg_sw->time_min_value > time_sw)		tr_kg_sw->time_min_value = time_sw;
            if (tr_kg_sw->time_max_value < time_sw)				tr_kg_sw->time_max_value = time_sw;

            if (test == 1)										tr_kg_hw->time_min_value = time_hw;
            else if (tr_kg_hw->time_min_value > time_hw)		tr_kg_hw->time_min_value = time_hw;
            if (tr_kg_hw->time_max_value < time_hw)				tr_kg_hw->time_max_value = time_hw;


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

            // sign
            start_t_sw = timeInMicroseconds();
            eddsa25519_sign(msg, strlen(msg), (const unsigned char*)pri_key_sw, pri_len_sw, &sig_sw, &sig_len_sw);
            stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

            start_t_hw = timeInMicroseconds();
            eddsa25519_sign_hw(msg, strlen(msg), pri_key, pri_len, pub_key, pub_len, &sig, &sig_len, interface);
            stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));


            time_sw = stop_t_sw - start_t_sw;
            time_total_si_sw += time_sw;
            time_hw = stop_t_hw - start_t_hw;
            time_total_si_hw += time_hw;

            if (test == 1)										tr_si_sw->time_min_value = time_sw;
            else if (tr_si_sw->time_min_value > time_sw)		tr_si_sw->time_min_value = time_sw;
            if (tr_si_sw->time_max_value < time_sw)				tr_si_sw->time_max_value = time_sw;

            if (test == 1)										tr_si_hw->time_min_value = time_hw;
            else if (tr_si_hw->time_min_value > time_hw)		tr_si_hw->time_min_value = time_hw;
            if (tr_si_hw->time_max_value < time_hw)				tr_si_hw->time_max_value = time_hw;

            if (verb >= 3)
            {
                printf("\n signature: ");
                show_array(sig, sig_len, 32);
            }

            // verify

            start_t_sw = timeInMicroseconds();
            eddsa25519_verify(msg, strlen(msg), (const unsigned char*)pub_key_sw, pub_len_sw, (const unsigned char*)sig_sw, sig_len_sw, &result);
            stop_t_sw = timeInMicroseconds(); if (verb >= 1) printf("\n SW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_sw - start_t_sw) / 1000000.0, (stop_t_sw - start_t_sw) / 1000.0, (unsigned int)(stop_t_sw - start_t_sw));

            start_t_hw = timeInMicroseconds();
            eddsa25519_verify_hw(msg, strlen(msg), pub_key, pub_len, sig, sig_len, &result, interface);
            stop_t_hw = timeInMicroseconds(); if (verb >= 1) printf("\n HW: ET: %.3f s \t %.3f ms \t %d us", (stop_t_hw - start_t_hw) / 1000000.0, (stop_t_hw - start_t_hw) / 1000.0, (unsigned int)(stop_t_hw - start_t_hw));

            time_sw = stop_t_sw - start_t_sw;
            time_total_ve_sw += time_sw;
            time_hw = stop_t_hw - start_t_hw;
            time_total_ve_hw += time_hw;

            if (test == 1)										tr_ve_sw->time_min_value = time_sw;
            else if (tr_ve_sw->time_min_value > time_sw)		tr_ve_sw->time_min_value = time_sw;
            if (tr_ve_sw->time_max_value < time_sw)				tr_ve_sw->time_max_value = time_sw;

            if (test == 1)										tr_ve_hw->time_min_value = time_hw;
            else if (tr_ve_hw->time_min_value > time_hw)		tr_ve_hw->time_min_value = time_hw;
            if (tr_ve_hw->time_max_value < time_hw)				tr_ve_hw->time_max_value = time_hw;

            if (result) tr_ve_hw->val_result++;

        }

        // ---- EDDSA ---- //
        if (mode == 448)
        {
            /*
            // -----------------
            // keygen_sw
            start_t = timeInMicroseconds();
            eddsa448_genkeys(&pri_key, &pub_key, &pri_len, &pub_len); // from crypto_api_sw.h
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time_hw = stop_t - start_t;
            time_total_kg_hw += time_hw;

            if (test == 1)										tr_kg->time_min_value = time_hw;
            else if (tr_kg->time_min_value > time_hw)		tr_kg->time_min_value = time_hw;
            if (tr_kg->time_max_value < time_hw)				tr_kg->time_max_value = time_hw;

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
            eddsa448_sign(msg, strlen(msg), (const unsigned char*)pri_key, pri_len, &sig, &sig_len); // from crypto_api_sw.h
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW SIGN: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time_hw = stop_t - start_t;
            time_total_si_hw += time_hw;

            if (test == 1)										tr_si->time_min_value = time_hw;
            else if (tr_si->time_min_value > time_hw)		tr_si->time_min_value = time_hw;
            if (tr_si->time_max_value < time_hw)				tr_si->time_max_value = time_hw;

            if (verb >= 3)
            {
                printf("\n signature: ");
                show_array(sig, sig_len, 32);
            }

            // dec_hw

            start_t = timeInMicroseconds();
            eddsa448_verify(msg, strlen(msg), (const unsigned char*)pub_key, pub_len, (const unsigned char*)sig, sig_len, &result);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %d us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (unsigned int)(stop_t - start_t));

            time_hw = stop_t - start_t;
            time_total_ve_hw += time_hw;

            if (test == 1)										tr_ve->time_min_value = time_hw;
            else if (tr_ve->time_min_value > time_hw)		tr_ve->time_min_value = time_hw;
            if (tr_ve->time_max_value < time_hw)				tr_ve->time_max_value = time_hw;

            if (!result) tr_ve->val_result++;
        */
        }

    }

    tr_kg_hw->time_mean_value = (uint64_t)(time_total_kg_hw / n_test);
    tr_si_hw->time_mean_value = (uint64_t)(time_total_si_hw / n_test);
    tr_ve_hw->time_mean_value = (uint64_t)(time_total_ve_hw / n_test);

    tr_kg_sw->time_mean_value = (uint64_t)(time_total_kg_sw / n_test);
    tr_si_sw->time_mean_value = (uint64_t)(time_total_si_sw / n_test);
    tr_ve_sw->time_mean_value = (uint64_t)(time_total_ve_sw / n_test);

#ifdef AXI
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif
}