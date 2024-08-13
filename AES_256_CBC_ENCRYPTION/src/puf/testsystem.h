/*****************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSec_puf4r3_2.0: testsystem.h  
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 */
/*****************************************************************************/

#ifndef TESTSYSTEM_H_INCLUDED
#define TESTSYSTEM_H_INCLUDED

/****************************** Global variables *****************************/

 #if defined(PYNQZ2)
  
	char * opt[] = {"00"};
							   
	int PUF_BASEADDR[] = {0x43C00000};

  #if defined(PYNQ)				   			   
	char * InF    = "./bit/SPIRS_RoT";
	char * OutF   = "./out/puf/SPIRS_RoT_";
  #else
	char * InF    = "SPIRS_RoT";
	char * OutF   = "SPIRS_RoT_";
  #endif 
  
 #elif defined(G2RISCV)

	char * opt[] = {"00"};
                   
	int PUF_BASEADDR[] = {0x60040000};
                    
	char * InF  = "bit/SPIRS_RoT";
	char * OutF = "out/puf/SPIRS_RoT_";

 #endif

#endif // TESTSYSTEM_H_INCLUDED
