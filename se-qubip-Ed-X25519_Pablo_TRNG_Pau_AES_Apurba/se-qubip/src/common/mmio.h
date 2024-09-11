/****************************************************************************************/
/*
 *  SE_QUBIP: mmio.h
 *
 *  Updated on: 25/05/2023
 */
/****************************************************************************************/

#ifndef MMIO_INCLUDED
#define MMIO_INCLUDED

#define SUCCESS 1
#define ERROR   0

/************************************* Include Files ************************************/

  #include <pynq_api.h>
  #include <stdio.h>
  #include <string.h>
  #include <stdlib.h>
  #include <unistd.h>
  #include <fcntl.h>
  #include <math.h>
  #include <sys/time.h>
  #include <sys/mman.h>


/************************************* Data structures **********************************/

 #define MEMORY_DEV_PATH "/dev/mem"

  typedef struct id_mmio_state_struct {
    char * buffer;
    int file_handle;
    unsigned int length, address_base, virt_base, virt_offset;
  } MMIO_WINDOW;


/****************************************************************************************/
/******************************** Function Prototypes ***********************************/
/****************************************************************************************/
	
  int createMMIOWindow(MMIO_WINDOW * state, size_t address_base, size_t length);

  int closeMMIOWindow(MMIO_WINDOW * state);

  int writeMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data);

  int readMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data);

/****************************************************************************************/

  int Set_Clk_Freq( unsigned int clk_index, float * clk_frequency, float * set_clk_frequency, int DBG);

  unsigned long long Wtime();

#endif  //  MMIO_INCLUDED
