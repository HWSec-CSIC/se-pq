////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 13/06/2024
// File Name: eddsa_hw.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		EdDSA HW Handler Functions
//
////////////////////////////////////////////////////////////////////////////////////

#include "x25519_hw.h"

/////////////////////////////////////////////////////////////////////////////////////////////
// INTERFACE INIT/START & READ/WRITE
/////////////////////////////////////////////////////////////////////////////////////////////

void x25519_init(MMIO_WINDOW ms2xl)
{
    unsigned long long control;

    //-- General and Interface Reset
    control = X25519_INTF_RST + X25519_RST_ON;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
    control = X25519_INTF_OPER + X25519_RST_ON;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void x25519_start(MMIO_WINDOW ms2xl)
{
    unsigned long long control = X25519_RST_OFF;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void x25519_write(unsigned long long address, unsigned long long size, void *data, unsigned long long reset, MMIO_WINDOW ms2xl)
{
    unsigned long long addr = address;
    unsigned long long control = (reset) ? X25519_INTF_LOAD + X25519_RST_ON : X25519_INTF_LOAD + X25519_RST_OFF;

    writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
    writeMMIO(&ms2xl, data, DATA_IN, AXI_BYTES);
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    for (int i = 1; i < size; i++)
    {
        addr = address + i;
        writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
        writeMMIO(&ms2xl, data + AXI_BYTES * i, DATA_IN, AXI_BYTES);
    }

    control = (reset) ? X25519_INTF_OPER + X25519_RST_ON : X25519_INTF_OPER + X25519_RST_OFF;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void x25519_read(unsigned long long address, unsigned long long size, void *data, MMIO_WINDOW ms2xl)
{
    unsigned long long control = X25519_INTF_READ;
    unsigned long long addr;

    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    for (int i = 0; i < size; i++)
    {
        addr = address + i;
        writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
        readMMIO(&ms2xl, data + AXI_BYTES * i, DATA_OUT, AXI_BYTES);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////
// GENERATE PUBLIC KEY
/////////////////////////////////////////////////////////////////////////////////////////////

void x25519_genkeys_hw(unsigned char **pri_key, unsigned char **pub_key, unsigned int *pri_len, unsigned int *pub_len, MMIO_WINDOW ms2xl)
{

    *pri_len = X25519_BYTES;
    *pub_len = X25519_BYTES;

    *pri_key = (unsigned char*) malloc(*pri_len);
    *pub_key = (unsigned char*) malloc(*pub_len);

    gen_priv_key(*pri_key, *pri_len);

    /*
    printf("Private = 0x");
    for (int i = 0; i < X25519_BYTES; i++)
    {
        printf("%02x", *(*pri_key + i));
    }
    printf("\n");
    */

    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    unsigned char x25519_base_point[32] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09};

    unsigned long long info;

    //-- INITIALIZATION: General/Interface Reset & Select Operation
    x25519_init(ms2xl);

    //-- Write Scalar and Input Point
    x25519_write(X25519_SCALAR, X25519_BYTES / AXI_BYTES, *pri_key, X25519_RST_ON, ms2xl);
    x25519_write(X25519_POINT_IN, X25519_BYTES / AXI_BYTES, x25519_base_point, X25519_RST_ON, ms2xl);

    //-- Start Execution
    x25519_start(ms2xl);

    //-- Detect when finish
    int count = 0;

    while (count < X25519_WAIT_TIME)
    {
        readMMIO(&ms2xl, &info, END_OP, AXI_BYTES);

        if (info & 0x1) break;

        count++;
    }
    if (count == X25519_WAIT_TIME)
        printf("X25519 FAIL!\t%d\n", count);

    count = 0;

    //////////////////////////////////////////////////////////////
    // RESULTS
    //////////////////////////////////////////////////////////////

    x25519_read(X25519_POINT_OUT, X25519_BYTES / AXI_BYTES, *pub_key, ms2xl);

    /*
    printf("point_out = 0x");
    for (int i = 0; i < X25519_BYTES; i++)
    {
        printf("%02x", *(*pub_key + i));
    }
    printf("\n");
    */

    swapEndianness(*pub_key, *pub_len);
    swapEndianness(*pri_key, *pri_len);
}

/////////////////////////////////////////////////////////////////////////////////////////////
// X25519
/////////////////////////////////////////////////////////////////////////////////////////////

void x25519_hw(unsigned char *scalar, unsigned char *point_in, unsigned char *point_out, MMIO_WINDOW ms2xl)
{

    unsigned long long info;

    /*
    printf("scalar = 0x");
    for (int i = 0; i < X25519_BYTES; i++)
    {
        printf("%02x", *scalar + i);
    }
    printf("\n");
    */

    /*
    printf("point_in = 0x");
    for (int i = 0; i < X25519_BYTES; i++)
    {
        printf("%02x", *point_in + i);
    }
    printf("\n");
    */

    swapEndianness(scalar, X25519_BYTES);
    swapEndianness(point_in, X25519_BYTES);

    //////////////////////////////////////////////////////////////
    // WRITING ON DEVICE
    //////////////////////////////////////////////////////////////

    //-- INITIALIZATION: General/Interface Reset & Select Operation
    x25519_init(ms2xl);

    //-- Write Scalar and Input Point
    x25519_write(X25519_SCALAR, X25519_BYTES / AXI_BYTES, scalar, X25519_RST_ON, ms2xl);
    x25519_write(X25519_POINT_IN, X25519_BYTES / AXI_BYTES, point_in, X25519_RST_ON, ms2xl);

    //-- Start Execution
    x25519_start(ms2xl);

    //-- Detect when finish
    int count = 0;

    while (count < X25519_WAIT_TIME)
    {
        readMMIO(&ms2xl, &info, END_OP, AXI_BYTES);

        if (info & 0x1) break;

        count++;
    }
    if (count == X25519_WAIT_TIME)
        printf("X25519 FAIL!\t%d\n", count);

    count = 0;

    //////////////////////////////////////////////////////////////
    // RESULTS
    //////////////////////////////////////////////////////////////

    x25519_read(X25519_POINT_OUT, X25519_BYTES / AXI_BYTES, point_out, ms2xl);
    
    /*
    printf("Point_out = 0x");
    for (int i = 0; i < SHA_BYTES; i++)
    {
        printf("%02x", *(point_out + i));
    }
    printf("\n");
    */
    
    swapEndianness(scalar, X25519_BYTES);
    swapEndianness(point_in, X25519_BYTES);
    swapEndianness(point_out, X25519_BYTES);
}
