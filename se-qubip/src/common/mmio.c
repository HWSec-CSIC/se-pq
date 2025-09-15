/**
  * @file mmio.c
  * @brief PYNQ C-API
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/
	

////////////////////////////////////////////////////////////////////////////////
///////////                                                          ///////////
///////////          From PYNQ C-API Function Definitions            ///////////
///////////           https://github.com/mesham/pynq_api             ///////////
///////////                                                          ///////////
////////////////////////////////////////////////////////////////////////////////


#include "mmio.h"
#include <stdbool.h>

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
  munmap(state->buffer, state->length);
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


////////////////////////////////////////////////////////////////////////////////
///////////                   Change Clock Frequency                 ///////////
////////////////////////////////////////////////////////////////////////////////
	
  int Set_Clk_Freq(unsigned int clk_index, float * clk_frequency, float * set_clk_frequency, int DBG) {

  if (!PYNQ_getPLClockFreq(clk_index, clk_frequency)) {
		printf("\n  Cannot determine clock frequency\n\n");
	} else {
	  if (DBG > 0) printf("\n\n  Running   @ %6.2f MHz.\n", *clk_frequency);
	  if (DBG > 0) printf("  Selecting @ %6.2f MHz.\n", *set_clk_frequency);
	    if ( clk_frequency != set_clk_frequency) {
			int div0 = 1;
			int * p_div0 = &div0;
			int * p_div1 = NULL;
			if(!PYNQ_setPLClockFreq(clk_index, set_clk_frequency, p_div0, p_div1)) {
				printf("\n  Not changed  ... ");
				printf("\n %d %d \n", (*p_div0), (*p_div1));
			}
		}	
		if(!PYNQ_getPLClockFreq(clk_index, clk_frequency)) {
			printf("\n");
		} else {
	  if (DBG > 0) printf("  Setting   @ %6.2f MHz.\n", * clk_frequency);
		}
	}
	return SUCCESS;
  }
