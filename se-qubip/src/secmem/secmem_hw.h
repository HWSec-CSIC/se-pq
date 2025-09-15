////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 08/09/2025
// File Name: secmem_hw.h 
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		Secure Memory HW Handler Functions Header File
//
////////////////////////////////////////////////////////////////////////////////////

#ifndef SECMEM_H
#define SECMEM_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "../common/intf.h"
#include "../common/conf.h"
#include "../common/picorv32.h"
#include "../common/extra_func.h"

#define OP_STORE_KEY                (1 << 0)
#define OP_DELETE_KEY               (1 << 1)
#define OP_GET_KEY                  (1 << 2)
#define OP_INFO                     (1 << 3)

#define KEY_ID_OFFSET               4
#define KEY_ORIGIN_OFFSET           10
#define ALG_ID_OFFSET               11

#define ID_AES                      0
#define ID_X25519                   1
#define ID_EDDSA                    2
#define ID_SLHDSA                   3
#define ID_MLKEM                    4
#define ID_MLDSA                    5

//==============================================================================
// SECURE MEMORY OPERATIONS
//==============================================================================

void secmem_store_key(uint8_t alg_id, uint8_t* key_id, bool is_external, uint8_t* key_external, uint8_t key_len, INTF interface);
void secmem_delete_key(uint8_t alg_id, uint8_t key_id, INTF interface);
void secmem_get_key(uint8_t alg_id, uint8_t key_id, uint8_t* key_data, INTF interface);
void secmem_info(int DBG, INTF interface);

#endif
