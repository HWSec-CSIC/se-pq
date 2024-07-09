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

void demo_x25519(unsigned int verb, MMIO_WINDOW ms2xl)
{

#if defined(PYNQ)
	unsigned int clk_index = 0;
	float clk_frequency;
	#ifdef PYNQZ2
	float set_clk_frequency = 100.;
	#elif ZCU104
	float set_clk_frequency = 450.;
	#endif
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency);
#endif

    uint64_t start_t, stop_t;

    //-- Initialize to avoid 1st measure error
    start_t = timeInMicroseconds();
    stop_t = timeInMicroseconds();

    // ---- X25519 ---- //
    unsigned char *pub_key;
    unsigned char *pri_key;
    unsigned int pub_len;
    unsigned int pri_len;

    //-- Key Generation
    x25519_genkeys_hw(&pri_key, &pub_key, &pri_len, &pub_len, ms2xl);

    if (verb >= 2)
        printf("\n pub_len: %d (bytes)", pub_len);
    if (verb >= 2)
        printf("\n pri_len: %d (bytes)\n", pri_len);

    if (verb >= 3)
    {
        printf("\n public key: ");
        show_array(pub_key, pub_len, 32);
    }
    if (verb >= 3)
    {
        printf("\n private key: ");
        show_array(pri_key, pri_len, 32);
        printf("\n");
    }

    //-- Specific Value 1000 Times Test
    unsigned char scalar[32] = {0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};


    unsigned char point_in[32] = {0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
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

    unsigned char point_out[32];
    unsigned int result;
    unsigned int percentage;
    float ETA_time;

    float total_time = 0;

    printf("\n After 1000 iterations test: \n");
    for (int i = 0; i < 1000; i++)
    {
        start_t = timeInMicroseconds();
        x25519_hw(scalar, point_in, point_out, ms2xl);
        stop_t = timeInMicroseconds();

        total_time += stop_t - start_t;
        
        memcpy(point_in, scalar, X25519_BYTES);
        memcpy(scalar, point_out, X25519_BYTES);

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
        show_array(point_out, X25519_BYTES, 32);
    }

    result = memcmp(point_out, point_out_10_3, X25519_BYTES);

    printf("\n After 10^6 iterations test: \n");
    for (int i = 1000; i < 1000000; i++)
    {
        start_t = timeInMicroseconds();
        x25519_hw(scalar, point_in, point_out, ms2xl);
        stop_t = timeInMicroseconds();

        total_time += stop_t - start_t;

        memcpy(point_in, scalar, X25519_BYTES);
        memcpy(scalar, point_out, X25519_BYTES);

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
        show_array(point_out, X25519_BYTES, 32);
        printf("\n");
    }

    result = (result == 0) ? result + memcmp(point_out, point_out_10_6, X25519_BYTES) : -1;

    if (result == 0)
        printf("\n X25519 Test: \033[1;32m\u2705\033[0m VALID");
    else
        printf("\n X25519 Test: \033[1;31m\u274c\033[0m FAIL");

    if (result == 0 && verb >= 3)
    {
        printf("\n X25519 Performance: %4.2f op./s\n", 1000000.0 / (total_time / 1000000.0));
    }

#if defined(PYNQ)
    set_clk_frequency = 100.;
    Set_Clk_Freq(clk_index, &clk_frequency, &set_clk_frequency);
#endif
}
