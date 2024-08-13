/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_rsa_3.0: mmio.c 
 *
 *  Created on: 10/12/2022
 */
/****************************************************************************************/

  #include "mmio.h"
  #include <stdbool.h>

////////////////////////////////////////////////////////////////////////////////
///////////                                                          ///////////
///////////          From PYNQ C-API Function Definitions            ///////////
///////////           https://github.com/mesham/pynq_api             ///////////
///////////                                                          ///////////
////////////////////////////////////////////////////////////////////////////////


/**
* Creates an MMIO window at a specific base address of a provided size
*/
int createMMIOWindow(MMIO_WINDOW * state, size_t address_base, size_t length) {
  // Align the base address with the pages
  state->virt_base = address_base & ~(sysconf(_SC_PAGESIZE) - 1);
  state->virt_offset = address_base - state->virt_base;
  state->length=length;
  state->address_base=address_base;

  state->file_handle=open(MEMORY_DEV_PATH, O_RDWR | O_SYNC);
  if (state->file_handle == -1) {
    fprintf(stderr, "Unable to open '%s' to create memory window", MEMORY_DEV_PATH);
    return ERROR;
  }
  state->buffer=mmap(NULL, length+state->virt_offset, PROT_READ | PROT_WRITE, 
                     MAP_SHARED, state->file_handle, state->virt_base);
  if (state->buffer == MAP_FAILED) {
    fprintf(stderr, "Mapping memory to MMIO region failed");
    return ERROR;
  }
  return SUCCESS;
}

/**
* Closes an MMIO window that we have previously created
*/
int closeMMIOWindow(MMIO_WINDOW * state) {
  close(state->file_handle);
  return SUCCESS;
}

/**
* Writes some data, of provided size to the specified offset in the memory window
*/
int writeMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data) {
  memcpy(&(state->buffer[offset]), data, size_data);
  return SUCCESS;
}

/**
* Reads some data, of provided size to the specified offset from the memory window
*/
int readMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data) {
  memcpy(data, &(state->buffer[offset]), size_data);
  return SUCCESS;
}

/**
* Returns the time in microseconds since the epoch
*/
unsigned long long Wtime() {
  struct timeval time_val;
  gettimeofday(&time_val, NULL);
  return time_val.tv_sec * 1000000 + time_val.tv_usec;
}
