////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 10/07/2024
// File Name: test_X25519.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		X25519 Test File
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

#include "demo.h"
#include "test_func.h"

#ifndef PYNQ
#define PYNQ
#endif

void test_x25519(unsigned int verb, MMIO_WINDOW ms2xl)
{

#if defined(PYNQ)
    unsigned int clk_index = 0;
    float clk_frequency;
    float set_clk_frequency = FREQ_X25519;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif

    uint64_t start_t, stop_t;

    //-- Initialize to avoid 1st measure error
    start_t = timeInMicroseconds();
    stop_t = timeInMicroseconds();

    // ---- X25519 ---- //

    //-- Set the seed for RNG
    seed_rng();
    
    unsigned char *publ_key;
    unsigned char *priv_key;
    unsigned int pub_len;
    unsigned int pri_len;

    //-- Key Generation
    x25519_genkeys_hw(&priv_key, &publ_key, &pri_len, &pub_len, ms2xl);

    if (verb >= 2)
        printf("\n pub_len: %d (bytes)", pub_len);
    if (verb >= 2)
        printf("\n pri_len: %d (bytes)\n", pri_len);

    if (verb >= 3)
    {
        printf("\n public key: ");
        show_array(publ_key, pub_len, 32);
    }
    if (verb >= 3)
    {
        printf("\n private key: ");
        show_array(priv_key, pri_len, 32);
        printf("\n");
    }

    //-- Specific Value 1000 Times Test
    unsigned char pri_key[32] = {0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

    unsigned char pub_key[32] = {0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

    const unsigned char point_out_10_3[32] = {0x68, 0x4c, 0xf5, 0x9b, 0xa8, 0x33, 0x09, 0x55,
                                              0x28, 0x00, 0xef, 0x56, 0x6f, 0x2f, 0x4d, 0x3c,
                                              0x1c, 0x38, 0x87, 0xc4, 0x93, 0x60, 0xe3, 0x87,
                                              0x5f, 0x2e, 0xb9, 0x4d, 0x99, 0x53, 0x2c, 0x51};

    const unsigned char point_out_10_6[32] = {0x7c, 0x39, 0x11, 0xe0, 0xab, 0x25, 0x86, 0xfd,
                                              0x86, 0x44, 0x97, 0x29, 0x7e, 0x57, 0x5e, 0x6f,
                                              0x3b, 0xc6, 0x01, 0xc0, 0x88, 0x3c, 0x30, 0xdf,
                                              0x5f, 0x4d, 0xd2, 0xd2, 0x4f, 0x66, 0x54, 0x24};

    unsigned char *shared_secret;
    unsigned int shared_secret_len;

    unsigned int result;
    unsigned int percentage;
    float ETA_time;

    float total_time = 0;

    printf("\n After 1000 iterations test: \n");
    for (int i = 0; i < 1000; i++)
    {
        start_t = timeInMicroseconds();
        x25519_ss_gen_hw(&shared_secret, &shared_secret_len, pub_key, pub_len, pri_key, pri_len, ms2xl);
        stop_t = timeInMicroseconds();

        total_time += stop_t - start_t;

        memcpy(pub_key, pri_key, X25519_BYTES);
        memcpy(pri_key, shared_secret, X25519_BYTES);

        if ((i + 1) % 50 == 0)
        {
            percentage = ((float)(i + 1) / 1000) * 100;
            ETA_time = (1000 - 1 - i) * (total_time / 1000000.0) / (i + 1);
            print_progress_bar(percentage, ETA_time);
        }
    }

    //-- Remove progress bar and restore cursor position
    printf("\033[2K\033[2A");

    if (verb >= 3)
    {
        printf(" After 1000 iterations test: ");
        show_array(shared_secret, X25519_BYTES, 32);
    }

    result = memcmp(shared_secret, point_out_10_3, X25519_BYTES);

    printf("\n After 10^6 iterations test: \n");
    for (int i = 1000; i < 1000000; i++)
    {
        start_t = timeInMicroseconds();
        x25519_ss_gen_hw(&shared_secret, &shared_secret_len, pub_key, pub_len, pri_key, pri_len, ms2xl);
        stop_t = timeInMicroseconds();

        total_time += stop_t - start_t;

        memcpy(pub_key, pri_key, X25519_BYTES);
        memcpy(pri_key, shared_secret, X25519_BYTES);

        if ((i + 1) % 5000 == 0)
        {
            percentage = ((float)(i + 1) / 1000000) * 100;
            ETA_time = (1000000 - 1 - i) * (total_time / 1000000.0) / (i + 1);
            print_progress_bar(percentage, ETA_time);
        }
    }

    //-- Remove progress bar and restore cursor position
    printf("\033[2K\033[1A");

    if (verb >= 3)
    {
        printf(" After 10^6 iterations test: ");
        show_array(shared_secret, X25519_BYTES, 32);
        printf("\n");
    }

    result = (result == 0) ? result + memcmp(shared_secret, point_out_10_6, X25519_BYTES) : -1;

    if (result == 0)
        printf("\n X25519 Test: \033[1;32m\u2705\033[0m VALID");
    else
        printf("\n X25519 Test: \033[1;31m\u274c\033[0m FAIL");

    if (result == 0 && verb >= 3)
    {
        printf("\n X25519 Performance: %4.2f op./s\n", 1000000.0 / (total_time / 1000000.0));
    }

#if defined(PYNQ)
    set_clk_frequency = FREQ_TYPICAL;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency, (int)verb);
#endif
}
