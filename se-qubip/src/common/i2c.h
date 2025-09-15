/**
  * @file i2c.h
  * @brief i2c HW header
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

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
//
// Create Date: 03/09/2024
// File Name: i2c.h
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		I2C Driver Header File
//
// Additional Comment:
//
//      https://www.i-programmer.info/programming/148-hardware/15599-raspberry-pi-iot-in-c-using-linux-drivers-the-i2c-linux-driver.html
//
////////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <sys/time.h>
#include <sys/mman.h>
#include "extra_func.h"

//-- Create new type for the I2C File Descriptor
typedef int I2C_FD;

//-- Check I2C Port is available
void checkI2CBus();
FILE * doCommand(char *cmd);

//-- Open and Close I2C Port
void open_I2C(I2C_FD* i2c_fd);
void close_I2C(I2C_FD i2c_fd);

//-- Set I2C Slave Device Address
void set_address_I2C(I2C_FD i2c_fd, uint8_t slave_addr);

//-- Read & Write I2C Slave Registers
void read_I2C(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data);
void write_I2C(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data);
void read_I2C_ull(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data);
void write_I2C_ull(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data);

/*
//-- Read & Write SAFE I2C Slave Registers
void read_I2C_safe(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data);
void write_I2C_safe(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data);
void read_I2C_ull_safe(I2C_FD i2c_fd, unsigned long long* data, size_t offset, size_t size_data);
void write_I2C_ull_safe(I2C_FD i2c_fd, unsigned long long* data, size_t offset, size_t size_data);
*/
