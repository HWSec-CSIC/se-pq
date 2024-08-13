/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: sha2_hw.h 
 *
 *  Created on: 13/02/2023
 *      Author: camacho@imse-cnm.csic.es
 */
/****************************************************************************************/

#ifndef SHA2_HW_H_INCLUDED
#define SHA2_HW_H_INCLUDED

#define SUCCESS 1
#define ERROR   0

/************************ MS2XL Constant Definitions **********************/

#if defined(PYNQZ2)
  #define MS2XL_BASEADDR 0x43C10000
#elif defined(G2RISCV)
  #define MS2XL_BASEADDR 0x60050000
#endif

#define MEMORY_DEV_PATH "/dev/mem"
#define MS2XL_LENGTH   0x40

#define RESET		1
#define LOAD_LENGTH	2
#define LOAD		4
#define START		8
#define READ		16

#if defined(AXI64)
  #define CONTROL  0x0		/**< control */
  #define ADDRESS  0x8		/**< address */
  #define DATA_IN  0x10		/**< data_in */
  #define DATA_OUT 0x18		/**< data_out */
  #define END_OP   0x20		/**< end_op */
#else
  #define CONTROL  0x0		/**< control */
  #define ADDRESS  0x4		/**< address */
  #define DATA_IN  0x8		/**< data_in */
  #define DATA_OUT 0xC		/**< data_out */
  #define END_OP   0x10		/**< end_op */
#endif
 
/************************************* Include Files ************************************/

  #include <stdio.h>
  #include <string.h>
  #include <stdlib.h>
  #include <unistd.h>
  #include <fcntl.h>
  #include <math.h>
  #include <sys/time.h>
  #include <sys/mman.h>

 #if defined(PYNQZ2)
  #include <pynq_api.h>
 #endif

/************************************* Data structures **********************************/

  typedef struct sha2_mmio_state_struct {
    char * buffer;
    int file_handle;
    unsigned int length, address_base, virt_base, virt_offset;
  } MMIO_WINDOW;
  

/****************************************************************************************/
/****************************** MS2XL Function Definitions ******************************/
/****************************************************************************************/

  void sha2_ms2xl_init(unsigned long long length, MMIO_WINDOW ms2xl, int DBG);
#if defined(AXI64)
  void sha2_ms2xl(unsigned long long* a, unsigned long long* b, MMIO_WINDOW ms2xl, int last_hb, int DBG);
#elif defined(AXI32)
  void sha2_ms2xl(unsigned int* a, unsigned int* b, MMIO_WINDOW ms2xl, int last_hb, int DBG);
#endif	

/****************************************************************************************/
/******************************** Function Prototypes ***********************************/
/****************************************************************************************/

  int createMMIOWindow(MMIO_WINDOW * state, size_t address_base, size_t length);

  int closeMMIOWindow(MMIO_WINDOW * state);

  int writeMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data);

  int readMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data);
  
  unsigned long long Wtime();

/****************************************************************************************/

#endif // SHA2_HW_H_INCLUDED