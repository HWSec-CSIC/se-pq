////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pau Ortega Castro
// Engineer: Pablo Navarro Torrero
// Create Date: 24/07/2024
// File Name: trng_hw.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		TRNG HW Handler Functions
//
////////////////////////////////////////////////////////////////////////////////////

#include "trng_hw.h"

/////////////////////////////////////////////////////////////////////////////////////////////
// INTERFACE INIT/START & READ/WRITE
/////////////////////////////////////////////////////////////////////////////////////////////

void trng_init(MMIO_WINDOW ms2xl)
{
    unsigned long long control;

    //-- General and Interface Reset
    control = (ADD_TRNG << 32) + TRNG_INTF_RST + TRNG_RST_ON;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);

    control = (ADD_TRNG << 32) + TRNG_INTF_OPER + TRNG_RST_ON;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}

void trng_start(unsigned int bytes, MMIO_WINDOW ms2xl)
{
    unsigned long long control;
	unsigned long long addr;
	unsigned long long data_in;

	control = (ADD_TRNG << 32) + TRNG_INTF_LOAD + TRNG_RST_OFF;
	writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
	
	addr = 0;
	writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);

	data_in = ((2*bytes) << 5) + 1;	
	writeMMIO(&ms2xl, &data_in, DATA_IN, AXI_BYTES);

	control = (ADD_TRNG << 32) + TRNG_INTF_OPER + TRNG_RST_OFF;
    writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
}


void trng_read(unsigned char* out, unsigned int bytes, MMIO_WINDOW ms2xl)
{
    unsigned long long in_data;
	unsigned long long control;
	// unsigned long long addr;
	
	int loop = (bytes % AXI_BYTES == 0) ? (bytes / AXI_BYTES) : (bytes / AXI_BYTES + 1); 
	
    for (int i = 0; i < loop; i++)
    {
        in_data = (i << 18) + ((2*bytes) << 5) + 1;
		control = (ADD_TRNG << 32) + TRNG_INTF_LOAD + TRNG_RST_OFF;
		// addr = 0;
		
		writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
		// writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
		writeMMIO(&ms2xl, &in_data, DATA_IN, AXI_BYTES);
		
		control = (ADD_TRNG << 32) + TRNG_INTF_READ + TRNG_RST_OFF;
		// addr = 1;
		writeMMIO(&ms2xl, &control, CONTROL, AXI_BYTES);
		// writeMMIO(&ms2xl, &addr, ADDRESS, AXI_BYTES);
		
		readMMIO(&ms2xl, out + AXI_BYTES * i, DATA_OUT, AXI_BYTES);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////
// TRNG FUNCTION
/////////////////////////////////////////////////////////////////////////////////////////////

void trng_hw(unsigned char* out, unsigned int bytes, MMIO_WINDOW ms2xl)
{
	if (bytes > TRNG_MAX_BYTES) {
		printf("\n\n********************************************************************************");
		printf("\nTRNG FAIL: Max bytes = %d\n ", TRNG_MAX_BYTES);
		printf("********************************************************************************\n\n");
		exit(1);
	}
	
	trng_init(ms2xl);
	
	trng_start(bytes, ms2xl);
	
	//-- Detect when finish
	unsigned long long info;
    int count = 0;
	
    while (count < TRNG_WAIT_TIME)
    {
        readMMIO(&ms2xl, &info, END_OP, AXI_BYTES);

        if (info & 0x1) break;

        count++;
    }

    if (count == TRNG_WAIT_TIME) printf("\nTRNG FAIL!: TIMEOUT \t%d\n", count);

    count = 0;
	
	trng_read(out, bytes, ms2xl);
}

