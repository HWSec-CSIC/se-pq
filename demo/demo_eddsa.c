////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 13/06/2024
// File Name: demo_eddsa25519.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		EdDSA25519 Demo
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

#include "demo.h"
#include "test_func.h"

#ifndef PYNQ
#define PYNQ
#endif

void demo_eddsa_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl)
{

#if defined(PYNQ)
	unsigned int clk_index = 0;
	float clk_frequency;
	float set_clk_frequency = FREQ_EDDSA;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int) verb);
#endif

    // ---- EDDSA ---- //
    if (mode == 25519)
    {
        //-- Set the seed for RNG
        seed_rng();

        unsigned char *pub_key;
        unsigned char *pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        eddsa25519_genkeys_hw(&pri_key, &pub_key, &pri_len, &pub_len, ms2xl);

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

        
        unsigned char msg[] = "Hello, this is the SE of QUBIP project";
        

        unsigned char* sig;
        unsigned int sig_len;
        eddsa25519_sign_hw(msg, strlen(msg), pri_key, pri_len, pub_key, pub_len, &sig, &sig_len, ms2xl);

        if (verb >= 3)
        {
            printf("\n signature: ");
            show_array(sig, sig_len, 32);
        }

        unsigned int result;
        eddsa25519_verify_hw(msg, strlen(msg), pub_key, pub_len, sig, sig_len, &result, ms2xl);

        if (result)
            printf("\n EdDSA-25519 Test: \t\033[1;32m\u2705\033[0m VALID");
        else
            printf("\n EdDSA-25519 Test: \t\033[1;31m\u274c\033[0m FAIL");
    }
    else
    {
        /*
        unsigned char *pub_key;
        unsigned char *pri_key;
        unsigned int pub_len;
        unsigned int pri_len;

        eddsa448_genkeys_hw(&pri_key, &pub_key, &pri_len, &pub_len, ms2xl);

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

        unsigned char msg[50] = "Hello, this is the SE of QUBIP project";

        unsigned char *sig;
        unsigned int sig_len;
        eddsa448_sign_hw(msg, strlen(msg), (const unsigned char *)pri_key, pri_len, &sig, &sig_len);

        if (verb >= 3)
        {
            printf("\n signature: ");
            show_array(sig, sig_len, 32);
        }

        unsigned int result;
        eddsa448_verify_hw(msg, strlen(msg), (const unsigned char *)pub_key, pub_len, (const unsigned char *)sig, sig_len, &result);

        if (result)
            printf("\n EdDSA-448 Test: \u2705 VALID");
        else
            printf("\n EdDSA-448 Test: \u274c FAIL");
        */
    }

#if defined(PYNQ)
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif
}
