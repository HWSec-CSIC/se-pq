/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: function_test.h 
 *
 *  Created on: 20/12/2022
 *      Author: camacho@imse-cnm.csic.es
 */
/****************************************************************************************/
void reset_in(unsigned char* INPUT);
void input_nist(unsigned char* INPUT, unsigned char* OUTPUT, unsigned long long * LEN, int sel, int b, int DBG);
void input_file(unsigned char* INPUT, unsigned long long * LEN, char* FILE_NAME, int DBG);
void char_to_hex(unsigned char in0, unsigned char in1, char* out);