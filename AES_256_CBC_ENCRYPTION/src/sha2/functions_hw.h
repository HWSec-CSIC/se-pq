/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: functions_hw.h
 *
 *  Created on: 20/12/2022
 *      Author: camacho@imse-cnm.csic.es
 */
/****************************************************************************************/

#include "sha2_hw.h"
void sha256_hw(unsigned char* in, unsigned char* out, unsigned long long length, MMIO_WINDOW ms2xl, int DBG);