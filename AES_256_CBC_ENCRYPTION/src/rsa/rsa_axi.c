/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_rsa_3.0: rsa_axi.c 
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 */
/****************************************************************************************/

#include "rsa_axi.h"

#if defined (AXI64)

  unsigned long long rsaOutput[nrg];
  unsigned long long op;
  unsigned long long address;
  unsigned long long data_in;
  unsigned long long data_read;
  unsigned long long data_out;
  
  unsigned long long *RSA_SIGN(unsigned long long msgin[], unsigned long long key_e_d[],  unsigned long long key_n[], int DBG) 
  {

#else
	
  unsigned int rsaOutput[nrg];
  unsigned int op;
  unsigned int address;
  unsigned int data_in;
  unsigned int data_read;
  unsigned int data_out;
  
  unsigned int *RSA_SIGN(unsigned int msgin[], unsigned int key_e_d[],  unsigned int key_n[], int DBG)
  {

#endif

	MMIO_WINDOW rsaWindow;
    unsigned long long toc, tl, to, tr;
    unsigned int doneValue = 0;
	int nwc = 0;
	int address;
   
    createMMIOWindow(&rsaWindow,RSA_BASEADDRESS,RSA_REGISTER_SPACE_LEN);

    if (DBG > 1) printf("    - RSA_RESET\n");
    op = RSA_RESET;
	writeMMIO(&rsaWindow, &op, CONTROL, sizeof(op));
    op = RSA_OPER;
	writeMMIO(&rsaWindow, &op, CONTROL, sizeof(op));
	
	if (DBG > 1) {
		printf("    - LOAD INPUTS .......... ");
        tl = Wtime();
	}
	
	for  (int i=0; i<nrg; i++) {
		address = (i<<8);
		op = RSA_OPER + address;
		writeMMIO(&rsaWindow, &op, CONTROL, sizeof(op));	
		data_in =  msgin[i];
		writeMMIO(&rsaWindow, &data_in, MSGIN, sizeof(data_in));		
		data_in =  key_e_d[i];
		writeMMIO(&rsaWindow, &data_in, KEY_ED, sizeof(data_in));
		data_in =  key_n[i];
		writeMMIO(&rsaWindow, &data_in, KEY_N, sizeof(data_in)); 
		op = RSA_LOAD + address ;
		writeMMIO(&rsaWindow, &op, CONTROL, sizeof(op));
    }
	
	if (DBG > 1) {
        toc = Wtime() - tl;
		printf("  (%7.3f ms)\n", toc/1000.);
		printf("    - RSA_START ............ ");
		to = Wtime();
	}
	
    op = RSA_START;
    writeMMIO(&rsaWindow, &op ,CONTROL, sizeof(op));
	
	if (DBG > 2) printf("\n    Operating ");	

    doneValue = 0;
    while (doneValue!=1)
    {
        readMMIO(&rsaWindow, &doneValue, STATUS, sizeof(doneValue));
		if (DBG > 2) printf(".");
		for (int t = 0; t < 100000; t++) {
		}
		nwc++;
		if (nwc == 10000) {
			printf("\n Maximum number of wait cycles reached. Bye ... \n\n");
			break;
		}
    }
    if (DBG > 2) printf("\n    - RSA_START ............ ");

	if (DBG > 1) {
        toc = Wtime() - to;
		printf("  (%7.3f ms)\n", toc/1000.);
		printf("    - READING OUTPUT ....... ");	
        tr = Wtime();
	}
	
	for  (int i=0; i<nrg; i++) {
		address = (i<<8);
		op = RSA_READ + address;
		writeMMIO(&rsaWindow, &op, CONTROL, sizeof(op));
		readMMIO(&rsaWindow, &data_out, MSGOUT, sizeof(data_out));
		rsaOutput[i] = data_out;
   }

	if (DBG > 1) {
        toc = Wtime() - tr;
		printf("  (%7.3f ms)\n", toc/1000.);
	}
	
    op = RSA_RESET;
	writeMMIO(&rsaWindow, &op, CONTROL, sizeof(op));
    op = RSA_OPER;
	writeMMIO(&rsaWindow, &op, CONTROL, sizeof(op));

    return rsaOutput;

}

