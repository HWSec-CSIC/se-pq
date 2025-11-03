/**
  * @file sha2_padding.v
  * @brief Data Padding Module
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


`timescale 1ns / 1ps

module sha2_padding (
    input                   clk,
    input                   rst,
    input  [7:0]            control,
    input  [4:0]            ad_in,
    input  [63:0]      data_in,
    output  [63:0]     data_out
    );
    
    reg     [2*64-1:0] LENGTH;
    reg     [2*64-1:0] LENGTH_BLOCK;
    wire    [2*64-1:0] LENGTH_CURRENT;
    reg     [2*64-1:0] BLOCK_SIZE;
    
    assign reset        = !(!control[1] & !control[0]) & rst;   // XX00 -> RESET
    assign load_length  =   !control[1] &  control[0];            // XX01 -> LOAD_LENGTH   
    assign load_data    =    control[1] & !control[0];            // XX10 -> LOAD_DATA
    assign start        =    control[1] &  control[0];            // XX11 -> START
    
    assign sha_256      = !control[3] & !control[2]; // 00XX -> SHA_256
    assign sha_384      = !control[3] &  control[2]; // 01XX -> SHA_384
    assign sha_512      =  control[3] & !control[2]; // 10XX -> SHA_512
    assign sha_512_256  =  control[3] &  control[2]; // 11XX -> SHA_512_256
    
    assign mode_sha2    = (sha_256) ? 0 : 1;
    
    reg  [63:0]     data_out_reg;
    assign data_out = data_out_reg;
    
    reg save_length;
    reg flag;
    
    always @(posedge clk) begin
        if(!reset) save_length <= 0;
        else begin
            if(start & !flag)       save_length <= 1;
            else if(start & flag)   save_length <= 0;
            else                    save_length <= save_length;
        end
    end
    
    always @(posedge clk) begin
        if(!reset) flag <= 0;
        else begin
            if(load_data | load_length)         flag <= 0;
            else if(save_length)                flag <= 1;
            else                                flag <= flag;
        end
    end
    
    always @(posedge clk) begin
        if(!reset)                  BLOCK_SIZE <= 0;
        else begin
            if(sha_256)             BLOCK_SIZE <= 512;
            else if(sha_384)        BLOCK_SIZE <= 1024;
            else if(sha_512)        BLOCK_SIZE <= 1024;
            else if(sha_512_256)    BLOCK_SIZE <= 1024;
            else                    BLOCK_SIZE <= BLOCK_SIZE;
        end
    
    end
    
    always @(posedge clk) begin
                if(!reset) LENGTH_BLOCK <= 0;
                else begin
                    if(load_length)                         LENGTH_BLOCK <= LENGTH;
                    else if(start & save_length & !flag)    LENGTH_BLOCK <= LENGTH_BLOCK - BLOCK_SIZE;
                    else                                    LENGTH_BLOCK <= LENGTH_BLOCK;
                end
     end
     
     wire [2:0] control_pad;
     wire [7:0] width;
     assign width = (mode_sha2) ? 64 : 32;
     assign LENGTH_CURRENT = LENGTH_BLOCK - (ad_in * width);
     
     assign control_pad[0] = ((LENGTH_BLOCK + 2*width)   < BLOCK_SIZE) ? 1 : 0;
     assign control_pad[1] = (LENGTH_CURRENT             < width)      ? 1 : 0;
     assign control_pad[2] = (LENGTH_CURRENT             < 0)          ? 1 : 0; 
            
     wire [2:0] condition;
     assign condition[0] = control_pad[0] & (ad_in == 4'b1110); // OUTPUT LENGTH 1
     assign condition[1] = control_pad[0] & (ad_in == 4'b1111); // OUTPUT LENGTH 2
     assign condition[2] = control_pad[1];
            
     always @* begin
        if      (condition[0]) data_out_reg = (mode_sha2) ? LENGTH[2*64-1:64]   : LENGTH[63:32];
        else if (condition[1]) data_out_reg = (mode_sha2) ? LENGTH[63:0]        : LENGTH[31:0];
        else if (condition[2]) data_out_reg = data_in + (1'b1 << (width - 1 - LENGTH_CURRENT));
        else                   data_out_reg = data_in;
     end 
    
    always @(posedge clk) begin
        if(!reset)              LENGTH <= 0;
        else begin
            if(load_length & ad_in[0])         LENGTH[63:0]         <= data_in;
            else if(load_length & !ad_in[0])   LENGTH[2*64-1:64]    <= (mode_sha2) ? data_in : 32'h000000000;
            else                               LENGTH               <= LENGTH;
        end
    end
    
    
    
endmodule
