////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 10/07/2024
// File Name: demo_X25519.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		X25519 Demo File
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

#include "../demo.h"
#include "test_func.h"

#ifndef PYNQ
#define PYNQ
#endif

void demo_x25519_hw(unsigned int mode, unsigned int verb, MMIO_WINDOW ms2xl)
{

#if defined(PYNQ)
    unsigned int clk_index = 0;
    float clk_frequency;
    float set_clk_frequency = FREQ_X25519;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int) verb);
#endif

    // ---- KEY GEN ---- //
    
    //-- Set the seed for RNG
    seed_rng();

    unsigned char *pub_key_A;
    unsigned char *pri_key_A;
    unsigned int pub_len_A;
    unsigned int pri_len_A;

    if (mode == 25519)
        x25519_genkeys_hw(&pri_key_A, &pub_key_A, &pri_len_A, &pub_len_A, ms2xl);
    else{}
        // x448_genkeys_hw(&pri_key_A, &pub_key_A, &pri_len_A, &pub_len_A, ms2xl);

    if (verb >= 2)
        printf("\n pub_len: %d (bytes)", pub_len_A);
    if (verb >= 2)
        printf("\n pri_len: %d (bytes)\n", pri_len_A);

    if (verb >= 3)
    {
        printf("\n A public key: ");
        show_array(pub_key_A, pub_len_A, 32);
    }
    if (verb >= 3)
    {
        printf("\n A private key: ");
        show_array(pri_key_A, pri_len_A, 32);
    }

    unsigned char *pub_key_B;
    unsigned char *pri_key_B;
    unsigned int pub_len_B;
    unsigned int pri_len_B;

    if (mode == 25519)
        x25519_genkeys_hw(&pri_key_B, &pub_key_B, &pri_len_B, &pub_len_B, ms2xl);
    else{}
        // x448_genkeys_hw(&pri_key_B, &pub_key_B, &pri_len_B, &pub_len_B, ms2xl);

    if (verb >= 2)
        printf("\n pub_len: %d (bytes)", pub_len_B);
    if (verb >= 2)
        printf("\n pri_len: %d (bytes)\n", pri_len_B);

    if (verb >= 3)
    {
        printf("\n B public key: ");
        show_array(pub_key_B, pub_len_B, 32);
    }
    if (verb >= 3)
    {
        printf("\n B private key: ");
        show_array(pri_key_B, pri_len_B, 32);
    }

    // --- SHARED_SECRET --- //

    unsigned char *ss_A;
    unsigned int ss_len_A;
    if (mode == 25519)
        x25519_ss_gen_hw(&ss_A, &ss_len_A, pub_key_B, pub_len_B, pri_key_A, pri_len_A, ms2xl); // A Side
    else{}
        // x448_ss_gen_hw(&ss_A, &ss_len_A, pub_key_B, pub_len_B, pri_key_A, pri_len_A, ms2xl); // A Side

    unsigned char *ss_B;
    unsigned int ss_len_B;
    if (mode == 25519)
        x25519_ss_gen_hw(&ss_B, &ss_len_B, pub_key_A, pub_len_A, pri_key_B, pri_len_B, ms2xl); // B Side
    else{}
        // x448_ss_gen_hw(&ss_B, &ss_len_B, pub_key_A, pub_len_A, pri_key_B, pri_len_B, ms2xl); // B Side

    if (verb >= 2)
        printf("\n ss_len_A: %d (bytes)", ss_len_A);
    if (verb >= 3)
    {
        printf("\n ss_A: ");
        show_array(ss_A, ss_len_A, 32);
    }

    if (verb >= 2)
        printf("\n ss_len_B: %d (bytes)", ss_len_B);
    if (verb >= 3)
    {
        printf("\n ss_B: ");
        show_array(ss_B, ss_len_B, 32);
    }

    unsigned char s_mode[10];
    if (mode == 25519)
        sprintf(s_mode, "%s", "X25519");
    else
        sprintf(s_mode, "%s", "X448");

    if (!cmpchar(ss_A, ss_B, ss_len_A))
        printf("\n %s KEM Test: \t\033[1;32m\u2705\033[0m VALID", s_mode);
    else
        printf("\n %s KEM Test: \t\033[1;31m\u274c\033[0m FAIL", s_mode);

#if defined(PYNQ)
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif
}
