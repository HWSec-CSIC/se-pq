#include "../demo.h"
#include "test_func.h"
#include <crypto_api_sw.h>

void test_eddsa(unsigned int mode, unsigned int n_test, unsigned int verb, time_result* tr_kg, time_result* tr_si, time_result* tr_ve, MMIO_WINDOW ms2xl)
{

#if defined(PYNQ)
    unsigned int clk_index = 0;
    float clk_frequency;
    float set_clk_frequency = FREQ_EDDSA;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif

    uint64_t start_t, stop_t;

    //-- Initialize to avoid 1st measure error
    start_t = timeInMicroseconds();
    stop_t = timeInMicroseconds();

    tr_kg->time_mean_value_hw = 0;
    tr_kg->time_max_value_hw = 0;
    tr_kg->time_min_value_hw = 0;
    tr_kg->time_mean_value_sw = 0;
    tr_kg->time_max_value_sw = 0;
    tr_kg->time_min_value_sw = 0;
    tr_kg->val_result = 0;

    tr_si->time_mean_value_hw = 0;
    tr_si->time_max_value_hw = 0;
    tr_si->time_min_value_hw = 0;
    tr_si->time_mean_value_sw = 0;
    tr_si->time_max_value_sw = 0;
    tr_si->time_min_value_sw = 0;
    tr_si->val_result = 0;

    tr_ve->time_mean_value_hw = 0;
    tr_ve->time_max_value_hw = 0;
    tr_ve->time_min_value_hw = 0;
    tr_ve->time_mean_value_sw = 0;
    tr_ve->time_max_value_sw = 0;
    tr_ve->time_min_value_sw = 0;
    tr_ve->val_result = 0;

    uint64_t time_hw = 0;
    uint64_t time_sw = 0;
    uint64_t time_total_kg_hw = 0;
    uint64_t time_total_ve_hw = 0;
    uint64_t time_total_si_hw = 0;
    uint64_t time_total_kg_sw = 0;
    uint64_t time_total_ve_sw = 0;
    uint64_t time_total_si_sw = 0;

    unsigned char* pub_key;
    unsigned char* pri_key;
    unsigned int pub_len;
    unsigned int pri_len;
    unsigned char msg[] = "Hello, this is the SE of QUBIP project";
    unsigned char* sig;
    unsigned int sig_len;
    unsigned int result;

    if (mode == 25519)        printf("\n\n -- Test EdDSA-25519 --");

    for (int test = 1; test <= n_test; test++) {

        if (verb >= 1) printf("\n test: %d", test);

        // ---- EDDSA ---- //
        if (mode == 25519)
        {
            //-- Set the seed for RNG
            seed_rng();

            // keygen_hw
            start_t = timeInMicroseconds();
            eddsa25519_genkeys_hw(&pri_key, &pub_key, &pri_len, &pub_len, ms2xl);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n HW GEN KEYS: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

            time_hw = stop_t - start_t;
            time_total_kg_hw += time_hw;

            if (test == 1)										tr_kg->time_min_value_hw = time_hw;
            else if (tr_kg->time_min_value_hw > time_hw)		tr_kg->time_min_value_hw = time_hw;
            if (tr_kg->time_max_value_hw < time_hw)				tr_kg->time_max_value_hw = time_hw;

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
            eddsa25519_sign_hw(msg, strlen(msg), pri_key, pri_len, pub_key, pub_len, &sig, &sig_len, ms2xl);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n HW SIGN: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

            time_hw = stop_t - start_t;
            time_total_si_hw += time_hw;

            if (test == 1)										tr_si->time_min_value_hw = time_hw;
            else if (tr_si->time_min_value_hw > time_hw)		tr_si->time_min_value_hw = time_hw;
            if (tr_si->time_max_value_hw < time_hw)				tr_si->time_max_value_hw = time_hw;

            if (verb >= 3)
            {
                printf("\n signature: ");
                show_array(sig, sig_len, 32);
            }

            // dec_hw

            start_t = timeInMicroseconds();
            eddsa25519_verify_hw(msg, strlen(msg), pub_key, pub_len, sig, sig_len, &result, ms2xl);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n HW VERIFY: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

            time_hw = stop_t - start_t;
            time_total_ve_hw += time_hw;

            if (test == 1)										tr_ve->time_min_value_hw = time_hw;
            else if (tr_ve->time_min_value_hw > time_hw)		tr_ve->time_min_value_hw = time_hw;
            if (tr_ve->time_max_value_hw < time_hw)				tr_ve->time_max_value_hw = time_hw;

            if (result) tr_ve->val_result++;

            // -----------------
            // keygen_sw
            start_t = timeInMicroseconds();
            eddsa25519_genkeys(&pri_key, &pub_key, &pri_len, &pub_len); // from crypto_api_sw.h
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW GEN KEYS: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

            time_sw = stop_t - start_t;
            time_total_kg_sw += time_sw;

            if (test == 1)										tr_kg->time_min_value_sw = time_sw;
            else if (tr_kg->time_min_value_sw > time_sw)		tr_kg->time_min_value_sw = time_sw;
            if (tr_kg->time_max_value_sw < time_sw)				tr_kg->time_max_value_sw = time_sw;

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
            eddsa25519_sign(msg, strlen(msg), pri_key, pri_len, pub_key, pub_len, &sig, &sig_len); // from crypto_api_sw.h
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW SIGN: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

            time_sw = stop_t - start_t;
            time_total_si_sw += time_sw;

            if (test == 1)										tr_si->time_min_value_sw = time_sw;
            else if (tr_si->time_min_value_sw > time_sw)		tr_si->time_min_value_sw = time_sw;
            if (tr_si->time_max_value_sw < time_sw)				tr_si->time_max_value_sw = time_sw;

            if (verb >= 3)
            {
                printf("\n signature: ");
                show_array(sig, sig_len, 32);
            }

            // dec_hw

            start_t = timeInMicroseconds();
            eddsa25519_verify(msg, strlen(msg), pub_key, pub_len, sig, sig_len, &result);
            stop_t = timeInMicroseconds(); if (verb >= 1) printf("\n SW VERIFY: ET: %.3f s \t %.3f ms \t %ld us", (stop_t - start_t) / 1000000.0, (stop_t - start_t) / 1000.0, (stop_t - start_t));

            time_sw = stop_t - start_t;
            time_total_ve_sw += time_sw;

            if (test == 1)										tr_ve->time_min_value_sw = time_sw;
            else if (tr_ve->time_min_value_sw > time_sw)		tr_ve->time_min_value_sw = time_sw;
            if (tr_ve->time_max_value_sw < time_sw)				tr_ve->time_max_value_sw = time_sw;

        }
    }

    tr_kg->time_mean_value_hw = (uint64_t)(time_total_kg_hw / n_test);
    tr_kg->time_mean_value_sw = (uint64_t)(time_total_kg_sw / n_test);
    tr_si->time_mean_value_hw = (uint64_t)(time_total_si_hw / n_test);
    tr_si->time_mean_value_sw = (uint64_t)(time_total_si_sw / n_test);
    tr_ve->time_mean_value_hw = (uint64_t)(time_total_ve_hw / n_test);
    tr_ve->time_mean_value_sw = (uint64_t)(time_total_ve_sw / n_test);
    

#if defined(PYNQ)
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif
}