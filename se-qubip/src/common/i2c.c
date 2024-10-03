/**
  * @file i2c.c
  * @brief i2c HW test file
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
// File Name: i2c.c
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Description:
//
//		I2C Driver File
//
// Additional Comment:
//
//      https://www.i-programmer.info/programming/148-hardware/15599-raspberry-pi-iot-in-c-using-linux-drivers-the-i2c-linux-driver.html
//
//      In Raspberry Pi 4 devices to modify I2C baudrate, go to /boot/firmware/config.txt
//      and modify as follows:
//
//                  dtparam=i2c_arm=on,i2c_arm_baudrate=100000
//
//
////////////////////////////////////////////////////////////////////////////////////

#include "i2c.h"

/*
int main(int argc, char** argv) {
    
    // checkI2CBus();
    
    I2C_FD i2c_fd;
    uint8_t slave_addr = 0x1A;

    open_I2C(&i2c_fd);
    set_address_I2C(i2c_fd, slave_addr);

    size_t ptr_reg_test = 0x01;
    char read_test[1];

    //-- Read Test
    read_I2C(i2c_fd, read_test, ptr_reg_test, 1);
    printf("\nread_test = %x\n", read_test[0]);

    //-- Write Test: 0 to 15 counter with LEDs
    ptr_reg_test = 0x02;
    uint8_t LEDs = 0x01;

    for (int i = 0; i < 15; i++) 
    {
        write_I2C(i2c_fd, &LEDs, ptr_reg_test, 1);
        LEDs++;
        //-- 0.1s delay
        usleep(100*1000);
    }

    close_I2C(i2c_fd);

    return (EXIT_SUCCESS);
}
*/

//------------------------------------------------------------------
//-- Check I2C Port is available
//------------------------------------------------------------------

void checkI2CBus() {
    FILE *fd = doCommand("sudo dtparam -l");
    char output[1024];
    int txfound = 0;
    while (fgets(output, sizeof (output), fd) != NULL) {
        printf("%s\n\r", output);
        fflush(stdout);
        if (strstr(output, "i2c_arm=on") != NULL) {
            txfound = 1;
        }
        if (strstr(output, "i2c_arm=off") != NULL) {
            txfound = 0;
        }
    }
    pclose(fd);
    if (txfound == 0) {
        fd = doCommand("sudo dtparam i2c_arm=on");
        pclose(fd);
    }
}

FILE * doCommand(char *cmd) {
    FILE *fp = popen(cmd, "r");
    if (fp == NULL) {
        printf("Failed to run command %s \n\r", cmd);
        exit(1);
    }
    return fp;
}


//------------------------------------------------------------------
//-- Open and Close I2C Port
//------------------------------------------------------------------

void open_I2C(I2C_FD* i2c_fd)  {*i2c_fd = open("/dev/i2c-1", O_RDWR);}
void close_I2C(I2C_FD i2c_fd) {close(i2c_fd);}


//------------------------------------------------------------------
//-- Set I2C Slave Device Address
//------------------------------------------------------------------

void set_address_I2C(I2C_FD i2c_fd, uint8_t i2c_addr){ioctl(i2c_fd, I2C_SLAVE, i2c_addr);}


//------------------------------------------------------------------
//-- Read & Write I2C Slave Registers
//------------------------------------------------------------------

void read_I2C(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data)
{
    //-- Pointer Index
    unsigned char ptr_idx = (unsigned char) offset;
    //-- Write Pointer Index
    write(i2c_fd, &ptr_idx, 1);
    //-- Read from I2C Port
    read(i2c_fd, data, size_data);
}

void write_I2C(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data)
{
    //-- Buffer -> {Pointer_index, data_char}
    unsigned char buf[1 + size_data];
    //-- Pointer Index
    unsigned char ptr_idx[1] = {offset};
    //-- Copy to buffer
    memcpy(buf, ptr_idx, 1);
    memcpy(buf + 1, data, size_data);
    //-- Send through I2C Port 
    write(i2c_fd, buf, 1 + size_data);
}

void read_I2C_ull(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data)
{
    //-- Pointer Index
    unsigned char ptr_idx = (unsigned char) offset;
    //-- Write Pointer Index
    write(i2c_fd, &ptr_idx, 1);
    //-- Read from I2C Port
    unsigned char data_char[size_data];
    read(i2c_fd, data_char, size_data);
    //-- Cast char to unsigned long long
    size_t size_data_ull = (size_data % 8 == 0) ? (size_data / 8) : (size_data / 8 + 1);
    for (int i = 0; i < size_data_ull; i++)
    {
        swapEndianness(data_char + 8 * i, 8);
    }
    memcpy(data, data_char, size_data);
}

void write_I2C_ull(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data)
{
    //-- Cast unsigned long long to char
    unsigned char data_char[size_data];
    size_t size_data_ull = (size_data % 8 == 0) ? (size_data / 8) : (size_data / 8 + 1);
    memcpy(data_char, data, size_data);
    for (int i = 0; i < size_data_ull; i++)
    {
        swapEndianness(data_char + 8 * i, 8);
    }
    //-- Buffer -> {Pointer_index, data_char}
    unsigned char buf[1 + size_data];
    //-- Pointer Index
    unsigned char ptr_idx[1] = {offset};
    //-- Copy to buffer
    memcpy(buf, ptr_idx, 1);
    memcpy(buf + 1, data_char, size_data);
    //-- Send through I2C Port 
    write(i2c_fd, buf, 1 + size_data);
}

/*
//------------------------------------------------------------------
//-- Read & Write SAFE I2C Slave Registers
//------------------------------------------------------------------

void read_I2C_safe(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data)
{
    //-- Let check three times the values we are reading
    int end_condition = 0;
    //-- Three copies of data
    unsigned char data_1[size_data];
    unsigned char data_2[size_data];
    unsigned char data_3[size_data];
    unsigned char data_4[size_data];
    //-- While loop
    while (!end_condition)
    {
        read_I2C(i2c_fd, data_1, offset, size_data);
        read_I2C(i2c_fd, data_2, offset, size_data);
        read_I2C(i2c_fd, data_3, offset, size_data);
        read_I2C(i2c_fd, data_4, offset, size_data);

        if ((memcmp(data_1, data_2, size_data) == 0) && (memcmp(data_1, data_3, size_data) == 0))
        {
            memcpy(data, data_1, size_data);
            end_condition = 1;
        }
        else if ((memcmp(data_1, data_2, size_data) == 0) && (memcmp(data_1, data_4, size_data) == 0))
        {
            memcpy(data, data_1, size_data);
            end_condition = 1;
        }
        else if ((memcmp(data_1, data_3, size_data) == 0) && (memcmp(data_1, data_4, size_data) == 0))
        {
            memcpy(data, data_1, size_data);
            end_condition = 1;
        }
        else if ((memcmp(data_2, data_3, size_data) == 0) && (memcmp(data_2, data_4, size_data) == 0))
        {
            memcpy(data, data_2, size_data);
            end_condition = 1;
        }
        else 
        {
            end_condition = 0;
            printf("\nERROR IN RECEPTION!\n");
        }
    }
}

void write_I2C_safe(I2C_FD i2c_fd, void* data, size_t offset, size_t size_data)
{
    //-- Write Data
    write_I2C(i2c_fd, data, offset, size_data);
    
    //-- Read Data to ensure it was properly transmitted
    unsigned char data_read[size_data];
    read_I2C_safe(i2c_fd, data_read, offset, size_data);
    //-- If not equal transmit again
    while(memcmp(data, data_read, size_data) != 0)
    {
        write_I2C(i2c_fd, data, offset, size_data);
        read_I2C_safe(i2c_fd, data_read, offset, size_data);
        printf("\nERROR IN TRANSMISSION!\n");
    }
    
}

void read_I2C_ull_safe(I2C_FD i2c_fd, unsigned long long* data, size_t offset, size_t size_data)
{
    //-- Let check 4 times the values we are reading
    int end_condition = 0;
    //-- 4 copies of data
    size_t size_data_ull = (size_data % 8 == 0) ? (size_data / 8) : (size_data / 8 + 1);
    unsigned long long data_1[size_data_ull];
    unsigned long long data_2[size_data_ull];
    unsigned long long data_3[size_data_ull];
    unsigned long long data_4[size_data_ull];
    //-- While loop
    while (!end_condition)
    {
        read_I2C_ull(i2c_fd, data_1, offset, size_data);
        read_I2C_ull(i2c_fd, data_2, offset, size_data);
        read_I2C_ull(i2c_fd, data_3, offset, size_data);
        read_I2C_ull(i2c_fd, data_4, offset, size_data);

        if ((memcmp(data_1, data_2, size_data) == 0) && (memcmp(data_1, data_3, size_data) == 0))
        {
            memcpy(data, data_1, size_data);
            end_condition = 1;
        }
        else if ((memcmp(data_1, data_2, size_data) == 0) && (memcmp(data_1, data_4, size_data) == 0))
        {
            memcpy(data, data_1, size_data);
            end_condition = 1;
        }
        else if ((memcmp(data_1, data_3, size_data) == 0) && (memcmp(data_1, data_4, size_data) == 0))
        {
            memcpy(data, data_1, size_data);
            end_condition = 1;
        }
        else if ((memcmp(data_2, data_3, size_data) == 0) && (memcmp(data_2, data_4, size_data) == 0))
        {
            memcpy(data, data_2, size_data);
            end_condition = 1;
        }
        else 
        {
            end_condition = 0;
            printf("\nERROR IN RECEPTION ULL!\n");
        }
    }
}

void write_I2C_ull_safe(I2C_FD i2c_fd, unsigned long long* data, size_t offset, size_t size_data)
{
    //-- Write Data
    write_I2C_ull(i2c_fd, data, offset, size_data);
    //-- Read Data to ensure it was properly transmitted
    size_t size_data_ull = (size_data % 8 == 0) ? (size_data / 8) : (size_data / 8 + 1);
    unsigned long long data_read[size_data_ull];
    read_I2C_ull_safe(i2c_fd, data_read, offset, size_data);
    //-- If not equal transmit again
    while(memcmp(data, data_read, size_data) != 0)
    {
        write_I2C_ull(i2c_fd, data, offset, size_data);
        read_I2C_ull_safe(i2c_fd, data_read, offset, size_data);
        printf("\nERROR IN TRANSMISSION ULL!\n");
    }
}
*/