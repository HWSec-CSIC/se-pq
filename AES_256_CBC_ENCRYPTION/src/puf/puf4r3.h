/****************************************************************************************/
/*
 *  IMSE.CNM_SPIR-HwSec_puf4r3_2.0: puf4r3.h  
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 */
/****************************************************************************************/

#ifndef PUF4R3_H_INCLUDED
#define PUF4R3_H_INCLUDED

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

 #if defined(PYNQZ2)           // Pynq-Z2 Board with ARM (pynq or standalone)         
  #define Nx         8         // Number of columns of CLBs 
  #define Ny        20         // Number of rows of ROPs
  #define MN_PUFS   1         // Number of PUFs per FPGA board	
  
 #elif defined(G2RISCV)        // Genesys2 Board with Rocket64b1 Risc-V (debian)
  #define Nx         8         // Number of columns of CLBs 
  #define Ny        20         // Number of rows of ROPs
  #define MN_PUFS   1         // Number of PUFs per FPGA board	
  
 #endif	

 #define Ns       4            // Number of stages of ROs
 #define Nbc     14            // Number of bits of counters 

/******************************* Test parameters ******************************/

//#define IP_OPER
 #define BPC             	  4   // Bits per comparation in Operation mode
 
 #define MN_REGS 	BPC*Nx*Ny/8   // Max number of registers
 #define MN_CMPS     	4*Nx*Ny   // Max number of comparisons
 #define MN_BITS 	BPC*4*Nx*Ny   // Max number of bits
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

#if defined(AXI64)
  #define Dbw		64		// AXI4-Lite Data bus width
#else
  #define Dbw		32		// AXI4-Lite Data bus width
#endif
 
 #define OPER       0b0     // Operation  "---- ---- ---- ---0"
 #define RESET      0b1     // Reset      "---- ---- ---- ---1"
 #define START      0b10    // Start      "---- ---- ---- --10"
 //      LH         .  .  .  .  .  .      "---- ---- ---- -x--"
 //      NR         .  .  .  .  .  .      "---- ---- ---- x---"
 //      BG         .  .  .  .  .  .      "---- ---- ---x ----"
 //      PE         .  .  .  .  .  .      "---- ---- --x- ----"
 //      N_CMPS     .  .  .  .  .  .      "--xx xxxx xx-- ----"

 #define WCHL       (1<<16)   // Write    "---- ---1 ---- ----"
 #define RCHL       (1<<17)   // Read     "---- --1- ---- ----"

/************************************* Include Files ************************************/

  #include <stdio.h>
  #include <string.h>
  #include <stdlib.h>
  #include <unistd.h>
  #include <fcntl.h>
  #include <math.h>
  #include <sys/time.h>

 #if defined(STANDALONE)
  #include "xil_io.h"
 #else
  #include <sys/mman.h>
 #endif

 #if defined(PYNQZ2)
  #if !defined(STANDALONE)
    #include <pynq_api.h>
  #endif
 #endif


/************************************* Data structures **********************************/

 #if !defined(STANDALONE)
  typedef struct puf_mmio_state_struct {
    char * buffer;
    int file_handle;
    unsigned int length, address_base, virt_base, virt_offset;
  } MMIO_WINDOW;
 #else
  typedef int MMIO_WINDOW;
 #endif
  
  typedef struct HammingDistance_st {
	double mean;
	double max;
	double min;
  } HammDist;


/****************************************************************************************/
/******************************** Function Prototypes ***********************************/
/****************************************************************************************/

 #if defined(PYNQ)
  int PUF_loadBitstream(char* bitstream_file, int DBG);
 #endif

  int PUF_createMMIOWindow(MMIO_WINDOW* puf, int baseaddr, int lenght, int DBG);
  
#if defined(AXI64)
  int PUF_writeChallegesMask(MMIO_WINDOW* puf, long long puf_selr[], int regs, int DBG);
#else
  int PUF_writeChallegesMask(MMIO_WINDOW* puf, int puf_selr[], int regs, int DBG);
#endif

  int PUF_applyChallenges(MMIO_WINDOW* puf, int config, int cmps, int DBG);

#if defined(AXI64)
  int PUF_readOutput(MMIO_WINDOW* puf, int cmps, unsigned long long puf_out[], int DBG);   
#else
  int PUF_readOutput(MMIO_WINDOW* puf, int cmps, unsigned int puf_out[], int DBG);
#endif

  HammDist PUF_enrollment(MMIO_WINDOW* puf, int DBG, int CHD, unsigned int config, 
                          int E_tests, int N_cmps, int E_cmps, int puf_ref[], 
						  int puf_selm[]);

  HammDist PUF_HD(MMIO_WINDOW* puf, int DBG, unsigned int config, int puf_ref[], 
                  int puf_selm[], int N_tests, int N_cmps, int E_cmps); 

/****************************************************************************************/

#if defined(AXI64)

  void puf_rtob(long long puf_reg[], int n_regs, char* puf_bin);

  void puf_rtoc(unsigned long long puf_reg[], int n_regs, int puf_cmp[]);
  
  void chl_btor(int puf_selm[], int n_cmps, long long puf_selr[]);

#else

  void puf_rtob(int puf_reg[], int n_regs, char* puf_bin);

  void puf_rtoc(unsigned int puf_reg[], int n_regs, int puf_cmp[]);
  
  void chl_btor(int puf_selm[], int n_cmps, int puf_selr[]);

#endif

  void puf_ctob(int puf_cmp[], int n_cmps, char* puf_bin);
   
  void puf_ecc(char* bin_n, int n_bits, int R, char* bin_k);
  
/****************************************************************************************/

 #if !defined(STANDALONE)

  int createMMIOWindow(MMIO_WINDOW * state, size_t address_base, size_t length);

  int closeMMIOWindow(MMIO_WINDOW * state);

  int writeMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data);

  int readMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data);

 #endif

  unsigned long long Wtime();


/************************************ Standalone macros *********************************/

 #if defined(STANDALONE)

  #define PUF4R3_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

  #define PUF4R3_mWriteReg(BaseAddress, RegOffset, Data) \
   	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

 #endif

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
  
#endif // PUF4R3_H_INCLUDED
