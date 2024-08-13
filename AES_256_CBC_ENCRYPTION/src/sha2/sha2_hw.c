/****************************************************************************************/
/*
 *  IMSE.CNM_SPIRS_sha2_256_3.0: sha2_hw.c
 *
 *  Created on: 13/02/2023
 *      Author: camacho@imse-cnm.csic.es
 */
/****************************************************************************************/

#include "sha2_hw.h"

void sha2_ms2xl_init(unsigned long long length, MMIO_WINDOW ms2xl, int DBG) {

  #if defined(AXI64)
	unsigned long long op;
	unsigned long long reg_addr;
	unsigned long long reg_data_in;
  #elif defined(AXI32)
	unsigned int op;
	unsigned int reg_addr;
	unsigned int reg_data_in;	
  #endif	
		
	unsigned long long tic = 0, toc;

	op = RESET; // RESET OFF
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(op));

	// ----------- LOAD LENGTH ------------- //
	if (DBG == 2) printf("  -- sha2_ms2xl - Loading length ........................ ");
	if (DBG == 2) tic = Wtime();

	op = LOAD_LENGTH; // LOAD_LENGTH
	reg_data_in = length;

	writeMMIO(&ms2xl, &op, CONTROL, sizeof(op));

	reg_addr = 0;
	reg_data_in = length;
	writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(reg_addr));
	writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(reg_data_in));

#if defined(AXI32)
	reg_addr = 1;
	reg_data_in = length >> 32;
	writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(unsigned int));
	writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(unsigned int));
#endif	

	if (DBG == 2) printf("LENGTH: %lld \n", length);

	if (DBG == 2) toc = Wtime() - tic;
	if (DBG == 2) printf("(%3llu us.)\n", toc);
}

#if defined(AXI64)

  void sha2_ms2xl(unsigned long long* a, unsigned long long* b, MMIO_WINDOW ms2xl, int last_hb, int DBG) {
	unsigned long long op;
	unsigned long long end_op = 0;
	unsigned long long reg_addr;
	unsigned long long reg_data_in;
	unsigned long long reg_data_out;
	
#elif defined(AXI32)

  void sha2_ms2xl(unsigned int* a, unsigned int* b, MMIO_WINDOW ms2xl, int last_hb, int DBG) {
	unsigned int op;
	unsigned int end_op = 0;
	unsigned int reg_addr;
	unsigned int reg_data_in;
	unsigned int reg_data_out;
	
#endif	

	unsigned long long tic = 0, toc;

	// ----------- LOAD ------------------ //
	if (DBG == 2) {
		printf("  -- sha2_ms2xl - Loading data .............................. \n");
		tic = Wtime();
	}

	op = LOAD; // LOAD
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(op));

#if defined(AXI64)
	for (int i = 0; i < 8; i++) {
#elif defined(AXI32)
	for (int i = 0; i < 16; i++) {
#endif	
		reg_addr = i;
		reg_data_in = a[i];
		writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(reg_addr));
		writeMMIO(&ms2xl, &reg_data_in, DATA_IN, sizeof(reg_data_in));
#if defined(AXI64)
		if (DBG == 3) printf(" a(%d): %02llx\n\r", i, a[i]);
#elif defined(AXI32)
		if (DBG == 3) printf(" a(%d): %02x\n\r", i, a[i]);
#endif	
	}

	if (DBG == 2) {
		toc = Wtime() - tic;
		printf("(%3llu us.)\n", toc);
	}

	// ----------- OPERATING ------------- //
	if (DBG == 2) {
		printf("  -- sha2_ms2xl - Operating .............. ");
		tic = Wtime();
	}

	op = START; // START
	writeMMIO(&ms2xl, &op, CONTROL, sizeof(op));

	// wait END_OP
	while (!end_op) readMMIO(&ms2xl, &end_op, END_OP, sizeof(end_op));

	if (DBG == 2) {
		toc = Wtime() - tic;
		printf("(%3llu us.)\n", toc);
	}

	// ----------- READ ------------- //
	if (last_hb) {
		if (DBG == 2) {
			printf("  -- sha2_ms2xl - Reading output .............................. \n");
			tic = Wtime();
		}

		op = READ; // READ
		writeMMIO(&ms2xl, &op, CONTROL, sizeof(op));

#if defined(AXI64)
		for (int i = 0; i < 4; i++) {
#elif defined(AXI32)
		for (int i = 0; i < 8; i++) {
#endif	
			reg_addr = i;
			writeMMIO(&ms2xl, &reg_addr, ADDRESS, sizeof(reg_addr));
			readMMIO(&ms2xl, &reg_data_out, DATA_OUT, sizeof(reg_data_out));
			b[i] = reg_data_out;
#if defined(AXI64)
			if (DBG == 3) printf(" b(%d): %02llx\n\r", i, b[i]);
#elif defined(AXI32)
			if (DBG == 3) printf(" b(%d): %02x\n\r", i, b[i]);
#endif	
		}

		if (DBG == 2) {
			toc = Wtime() - tic;
			printf("(%3llu us.)\n", toc);
		}
	}
}


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