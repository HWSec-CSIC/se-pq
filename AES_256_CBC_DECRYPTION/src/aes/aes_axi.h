/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_rsa_1024_axi_1.0: rsa_axi.h 
 *
 *  Created on: 30/12/2022
 *      Author: apurba@imse-cnm.csic.es
 */
/****************************************************************************************/

#ifndef _AES_AXI_H
#define _AES_AXI_H

/************************************* Include Files ************************************/

#include <stdbool.h>
#include "mmio.h"

#define AESIP_BASEADDRESS 0x43C00000

#define MEMORY_DEV_PATH "/dev/mem"

#define AESIP_REGISTER_SPACE_LEN 20

#define AES_CONTROL 0x0000000D
#define AES_INIT 0x00000001U
#define AES_NEXT 0x00000001U


MMIO_WINDOW aesWindow;

/****************************************************************************************/
/******************************** RSA Function Definitions ******************************/
/****************************************************************************************/

void AES_256_CBC_DECRYPT(unsigned  char* key,unsigned  char* iv, unsigned  char* ciphertext, unsigned int* ciphertext_len, unsigned  char* plaintext, unsigned int* plaintext_len);

//unsigned long *AES_DEC(unsigned long *Plaintext, unsigned long *Key, bool KEY_SIZE);

/****************************************************************************************/

#endif  // AES_AXI_H
