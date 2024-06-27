
/****************************************************************************************/
/*
 *  SE_QUBIP: SE_QUBIP.h
 *
 *  Created on: 25/03/2024
 *      Author: Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
 *
 */
 /****************************************************************************************/

#ifndef SE_QUBIP_H_INCLUDED
#define SE_QUBIP_H_INCLUDED

#include <stdlib.h>
#include <pynq_api.h>

#include "se-qubip/src/common/mmio.h"
#include "se-qubip/src/sha3/sha3_shake_hw.h"
#include "se-qubip/src/sha2/sha2_hw.h"

#define sha3_512_hw			sha3_512_hw_func
#define sha3_256_hw			sha3_256_hw_func
#define shake_128_hw		shake128_hw_func
#define shake_256_hw		shake256_hw_func

#define sha_256_hw			sha_256_hw_func
#define sha_384_hw			sha_384_hw_func
#define sha_512_hw			sha_512_hw_func
#define sha_512_256_hw		sha_512_256_hw_func

// ------- MS2XL_BASEADDR ------- //

#define MS2XL_LENGTH		0x40

// Memory directions and size declaration

#define MS2XL_BASEADDR		0x43C00000


#endif // SE_QUBIP_H_INCLUDED
