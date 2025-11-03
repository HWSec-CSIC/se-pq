/**
  * @file  theta.v
  * @brief THETA Module
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

module theta(
    input   [1599:0] S,
    output  [1599:0] S_o
    );
    
    wire [63:0]     bc      [0:4];
    wire [63:0]     t       [0:4];
    wire [63:0]     sum     [0:24];
    wire [63:0]     S_in    [0:24];
    wire [63:0]     S_out   [0:24];
    
    genvar i;
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_in[i] = S[((i+1)*64-1):i*64];
    end
    endgenerate
    
    generate
    for (i = 0; i < 5; i = i + 1) begin
        assign  bc[i] =  S_in[i] ^ S_in[i + 5] ^ S_in[i + 10] ^ S_in[i + 15] ^ S_in[i + 20]; 
//        XOR_array XOR_array_1 (.a(S_in[i]),         .b(S_in[i + 5]),  .z(S_xor[i]));
//        XOR_array XOR_array_2 (.a(S_xor[i]),        .b(S_in[i + 10]), .z(S_xor[i + 5])); 
//        XOR_array XOR_array_3 (.a(S_xor[i + 5]),    .b(S_in[i + 15]), .z(S_xor[i + 10]));  
//        XOR_array XOR_array_4 (.a(S_xor[i + 10]),   .b(S_in[i + 20]), .z(bc[i])); 
    end
    endgenerate
    
    genvar j;
    generate
    for (i = 0; i < 5; i = i + 1) begin
        assign  t[i] = bc[(i+4) % 5] ^ SHA3_ROTL64(bc[(i + 1) % 5], 1);  
        //XOR_array XOR_array_5 (.a(bc[(i + 4) % 5]), .b(SHA3_ROTL64(bc[(i + 1) % 5], 1)), .z(t[i])); 
        for(j = 0; j < 25; j = j + 5) begin 
            assign sum[j+i] = S_in[j + i] ^ t[i];
            assign S_out[j + i] = sum[j+i][63:0];
        end
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_o[((i+1)*64-1):i*64] = S_out[i];
    end
    endgenerate
    
    
function [0:63] SHA3_ROTL64 ( input [0:63] x, input [0:63] y);
    begin
	SHA3_ROTL64 = (x << y) | ((x) >> (64 - y));
	end
endfunction

endmodule