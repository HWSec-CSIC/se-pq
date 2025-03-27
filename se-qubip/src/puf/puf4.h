/****************************************************************************************/
/*
 *  IMSE.CNM_HwSec_puf4r5_2.1: puf4.h  
 *
 *  Created on: 18/01/2024
 *      Author: santiago@imse-cnm.csic.es
 *
 */
/****************************************************************************************/

#ifndef PUF_H_INCLUDED
#define PUF_H_INCLUDED

#define SUCCESS 1
#define ERROR   0

/*************************************** Test Board *************************************/
//
//	Uncomment the next define and the used board for standalone applications
//
// # define STANDALONE				
// # define PYNQZ2
// # define NEXYSA7

// #define AXI64/AXI32  --->  in Makefile
 
/************************************* PUF parameters ***********************************/
    
 #define Nx          4           // Number of columns of CLBs 
 #define Ny          4           // Number of rows of ROPs
 #define Ns          4           // Number of stages of ROs
 #define Nbc         14		    // Number of bits of counters 

/******************************* Test parameters ******************************/

 #define BPC             	  4   // Bits per comparation in Operation mode
 
 #define MN_CMPS      512*Nx*Ny   // Max number of comparisons
 #define MN_BITS  BPC*512*Nx*Ny   // Max number of bits
 #define MN_REGS   BPC*16*Nx*Ny   // Max number of registers
 #define ML_KEY            2048   // Max length Key  
 
 #define MN_TESTS          1000   // Max number of test for enrollment
 #define MaxTries      	  25000   // Max number of tries for operation -- 500
 #define inc_delay            1   // Incremental delay -- 50

/********************************* IP Parameters ******************************/

 #define MEMORY_DEV_PATH "/dev/mem"
 #define PUF_LENGTH   0x40
 
#if defined(AXI64)
 #define CONTROL    0x0     /**< n_cmps, pe, bg, nr, lh, start, reset >*/
 #define PUFADDR    0x8     /**< puf_addr > */
 #define DATAOUT    0x10    /**< ID, puf_end > */
 #define PUFOUT     0x18    /**< puf_out > */
 #define CHLADDC    0x20    /**< W, R,  mem_wadd> */
 #define CHLDATA	0x28	/**< mem_wdata > */
#else
 #define CONTROL    0x0     /**< n_cmps, pe, bg, nr, lh, start, reset >*/
 #define PUFADDR    0x4     /**< puf_addr > */
 #define DATAOUT    0x8     /**< ID, puf_end > */
 #define PUFOUT     0xC     /**< puf_out > */
 #define CHLADDC    0x10    /**< W, R,  mem_wadd> */
 #define CHLDATA	0x14	/**< mem_wdata > */
#endif

  #define Dbw		32		// AXI4-Lite Data bus width
 
 #define OPER       0b0     // Operation  "---- ---- ---- ---- ---- ---0"
 #define RESET      0b1     // Reset      "---- ---- ---- ---- ---- ---1"
 #define START      0b10    // Start      "---- ---- ---- ---- ---- --10"
 //      LH         .  .  .  .  .  .      "---- ---- ---- ---- ---- -x--"
 //      NR         .  .  .  .  .  .      "---- ---- ---- ---- ---- x---"
 //      BG         .  .  .  .  .  .      "---- ---- ---- ---- ---x ----"
 //      PE         .  .  .  .  .  .      "---- ---- ---- ---- --x- ----"
 //      N_CMPS     .  .  .  .  .  .      "---- xxxx xxxx xxxx xx-- ----"

 #define WCHL       (1<<16)   // Write    "---- ---- ---- ---1 ---- ----"
 #define RCHL       (1<<17)   // Read     "---- ---- ---- --1- ---- ----"

/************************************* Include Files ************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include "../common/intf.h"
#include "../common/conf.h"
#include "../common/extra_func.h"
#include <sys/mman.h>


/************************************* Data structures **********************************/
  
  typedef struct HammingDistance_st {
	double mean;
	double max;
	double min;
  } HammDist;


/****************************************************************************************/
/******************************** Function Prototypes ***********************************/
/****************************************************************************************/
  
  int PUF_writeChallegesMask(INTF* puf, int puf_selr[], int regs, int DBG);

  int PUF_applyChallenges(INTF* puf, unsigned int config, int cmps, int DBG);

  int PUF_readOutput(INTF* puf, int cmps, unsigned int puf_out[], int DBG);

  HammDist PUF_enrollment(INTF* puf, int DBG, int CHD, unsigned int config, 
                          int E_tests, int N_cmps, int E_cmps, int puf_ref[], 
						  int puf_selm[]);

  HammDist PUF_HD(INTF* puf, int DBG, unsigned int config, int puf_ref[], 
                  int puf_selm[], int N_tests, int N_cmps, int E_cmps); 

/****************************************************************************************/

  void puf_rtob(int puf_reg[], int n_regs, char* puf_bin);

  void puf_rtoc(unsigned int puf_reg[], int n_regs, int puf_cmp[]);
  
  void chl_btor(int puf_selm[], int n_cmps, int puf_selr[]);

  void puf_ctob(int puf_cmp[], int n_cmps, char* puf_bin);

  void puf_btoh(char* puf_bin, int n_bits, int puf_hex[]);

  void puf_ecc(char* bin_n, int n_bits, int R, char* bin_k);
  

/*********************************** max and min macros *********************************/

 #define max(a,b)             \
 ({                           \
     __typeof__ (a) _a = (a); \
     __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b;       \
 })
  
 #define min(a,b)             \
 ({                           \
     __typeof__ (a) _a = (a); \
     __typeof__ (b) _b = (b); \
     _a < _b ? _a : _b;       \
 })
  
#endif // PUF_H_INCLUDED
