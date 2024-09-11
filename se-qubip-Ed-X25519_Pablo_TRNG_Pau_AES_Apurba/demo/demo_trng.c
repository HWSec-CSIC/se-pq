////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pau Ortega Castro
//
// Create Date: 10/07/2024
// File Name: demo_trng.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		TRNG Demo File
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

#include "demo.h"
#include "test_func.h"

void demo_trng_hw(unsigned int bits, MMIO_WINDOW ms2xl) 
{
    unsigned int bytes = (int)(bits / 8);
    unsigned char* random; 
    random = malloc(bytes);

    trng_hw(random, bytes, ms2xl);

    printf("\n Random %d bits: ", bits);  show_array(random, bytes, 32);
}
