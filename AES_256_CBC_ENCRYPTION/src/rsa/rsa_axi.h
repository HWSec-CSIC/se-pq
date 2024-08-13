/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_rsa_3.0: rsa_axi.h 
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 */
/****************************************************************************************/

#ifndef _RSA_AXI_H
#define _RSA_AXI_H

/************************************* Include Files ************************************/

#include <stdbool.h>
#include "mmio.h"

// #define BLOCK_SIZE 512
// #define BLOCK_SIZE 1024
#define BLOCK_SIZE 2048

#if defined(PYNQZ2)
  #define RSA_BASEADDRESS 0x43C30000
#elif defined(G2RISCV)
  #define RSA_BASEADDRESS 0x44A00000
#endif

#define MEMORY_DEV_PATH "/dev/mem"

#define RSA_REGISTER_SPACE_LEN 80

 #define RSA_RESET 0x01
 #define RSA_OPER  0x00
 #define RSA_START 0x02
 #define RSA_LOAD  0x04
 #define RSA_READ  0x08

#if defined(AXI64)
  #define nrg 		BLOCK_SIZE/64
  #define CONTROL    0x0     /**< address, read, load, start, reset >*/
  #define MSGIN      0x8     /**< msgin_din > */
  #define KEY_ED     0x10    /**< key_e_d_din > */
  #define KEY_N      0x18    /**< key_n_din  > */
  #define MSGOUT     0x20    /**< msgout_dout> */
  #define STATUS 	 0x28	 /**< msgout_valid > */
#else
  #define nrg 		BLOCK_SIZE/32
  #define CONTROL    0x0     /**< address, read, load, start, reset >*/
  #define MSGIN      0x4     /**< msgin_din > */
  #define KEY_ED     0x8     /**< key_e_d_din > */
  #define KEY_N      0xC     /**< key_n_din  > */
  #define MSGOUT     0x10    /**< msgout_dout> */
  #define STATUS 	 0x14	 /**< msgout_valid > */
#endif	

/****************************************************************************************/
/******************************** RSA Function Definitions ******************************/
/****************************************************************************************/

#if defined(AXI64)
  unsigned long long *RSA_SIGN(unsigned long long msgin[], unsigned long long key_e_d[], 
	unsigned long long key_n[], int DBG);
#else
  unsigned int *RSA_SIGN(unsigned int msgin[], unsigned int key_e_d[], unsigned int key_n[],
	int DBG);
#endif	

/****************************************************************************************/

#endif  // RSA_AXI_H

