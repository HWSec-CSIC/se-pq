/**
  * @file rho_pi.v
  * @brief Rho Pi Module
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

module rho_pi(
    input   [1599:0] S,
    output  [1599:0] S_o
    );
    
    localparam [(8*24)-1:0] param_keccakf_rotc = {
    8'b0000_0001, // 1 - 0
    8'b0000_0011, // 3
    8'b0000_0110, // 6
    8'b0000_1010, // 10
    8'b0000_1111, // 15
    8'b0001_0101, // 21
    8'b0001_1100, // 28
    8'b0010_0100, // 36
    8'b0010_1101, // 45
    8'b0011_0111, // 55
    8'b0000_0010, // 2
    8'b0000_1110, // 14
    8'b0001_1011, // 27
    8'b0010_1001, // 41
    8'b0011_1000, // 56
    8'b0000_1000, // 8
    8'b0001_1001, // 25
    8'b0010_1011, // 43
    8'b0011_1110, // 62
    8'b0001_0010, // 18
    8'b0010_0111, // 39
    8'b0011_1101, // 61
    8'b0001_0100, // 20
    8'b0010_1100  // 44 - 23
    };
    
    localparam [(8*24)-1:0] param_keccakf_piln = {
    8'b0000_1010, // 10 - 0
    8'b0000_0111, // 7
    8'b0000_1011, // 11
    8'b0001_0001, // 17 
    8'b0001_0010, // 18
    8'b0000_0011, // 3
    8'b0000_0101, // 5
    8'b0001_0000, // 16
    8'b0000_1000, // 8
    8'b0001_0101, // 21
    8'b0001_1000, // 24
    8'b0000_0100, // 4
    8'b0000_1111, // 15
    8'b0001_0111, // 23
    8'b0001_0011, // 19
    8'b0000_1101, // 13
    8'b0000_1100, // 12
    8'b0000_0010, // 2
    8'b0001_0100, // 20
    8'b0000_1110, // 14
    8'b0001_0110, // 22
    8'b0000_1001, // 9
    8'b0000_0110, // 6
    8'b0000_0001  // 1 - 23
    };
    
    wire [63:0] bc      [0:23];
    wire [63:0] t       [0:23];
    wire [63:0] S_in    [0:24];
    wire [63:0] S_out   [0:24];
    
    genvar i;
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_in[i] = S[((i+1)*64-1):i*64];
    end
    endgenerate
    
    assign t[0] = S_in[1];
    assign S_out[0] = S_in[0];
    generate 
    for(i = 0; i < 24; i = i + 1) begin
            assign bc[i] = S_in[param_keccakf_piln[((24-i)*8-1):(24-i-1)*8]];
            assign S_out[param_keccakf_piln[((24-i)*8-1):(24-i-1)*8]] = SHA3_ROTL64(t[i], param_keccakf_rotc[((24-i)*8-1):(24-i-1)*8]);
            assign t[i+1] = bc[i];
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_o[((i+1)*64-1):i*64] = S_out[i];
    end
    endgenerate
    
    
    function [63:0] SHA3_ROTL64 ( input [63:0] x, input [63:0] y);
    begin
	SHA3_ROTL64 = ((x << y) | ((x) >> (64 - y)));
	end
    endfunction
    
endmodule
