/****************************************************************************************/
/*
 *  IMSE.CNM_QUBIP_aes_256_axi_256: aes_axi.h 
 *
 *  Created on: 19/06/2024
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

#define AES_CONTROL 0x00000005U
#define AES_INIT 0x00000001U
#define AES_NEXT 0x00000001U


MMIO_WINDOW aesWindow;

/****************************************************************************************/
/******************************** AES Function Definitions ******************************/
/****************************************************************************************/

void AES_256_ECB_DECRYPT(unsigned  char* key, unsigned  char* ciphertext, unsigned int* ciphertext_len, unsigned  char* plaintext, unsigned int* plaintext_len);


/****************************************************************************************/


#endif  // AES_AXI_H
