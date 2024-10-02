/**
  * @file iota.v
  * @brief IOTA Module
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



module iota(
    input   [1599:0] S,
    output  [1599:0] S_o,
    input   [7:0] round
    );
    
    localparam [(64*24)-1:0] param_keccakf_rndc = {
    64'h0000_0000_0000_0001,
    64'h0000_0000_0000_8082, 
    64'h8000_0000_0000_808a, 
    64'h8000_0000_8000_8000, 
    64'h0000_0000_0000_808b, 
    64'h0000_0000_8000_0001, 
    64'h8000_0000_8000_8081, 
    64'h8000_0000_0000_8009, 
    64'h0000_0000_0000_008a, 
    64'h0000_0000_0000_0088, 
    64'h0000_0000_8000_8009, 
    64'h0000_0000_8000_000a, 
    64'h0000_0000_8000_808b, 
    64'h8000_0000_0000_008b, 
    64'h8000_0000_0000_8089, 
    64'h8000_0000_0000_8003, 
    64'h8000_0000_0000_8002, 
    64'h8000_0000_0000_0080, 
    64'h0000_0000_0000_800a, 
    64'h8000_0000_8000_000a, 
    64'h8000_0000_8000_8081, 
    64'h8000_0000_0000_8080, 
    64'h0000_0000_8000_0001, 
    64'h8000_0000_8000_8008  
    };
    
    wire [63:0] S_in    [0:24];
    wire [63:0] S_out   [0:24];
    reg  [63:0] S_round  ;
    wire [63:0] keccakf_rndc   [0:23];
    
    assign S_out[0] = S_in[0] ^ S_round;
    
    genvar i;
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_in[i] = S[((i+1)*64-1):i*64];
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        if(i != 0) assign S_out[i] = S_in[i];
        assign S_o[((i+1)*64-1):i*64] = S_out[i];
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 24; i = i + 1) begin
        assign keccakf_rndc[i] = param_keccakf_rndc[((24-i)*64-1):(24-i-1)*64];
    end
    endgenerate
    
    always @* begin
    
    case(round)
        0: S_round = keccakf_rndc[0];
        1: S_round = keccakf_rndc[1];
        2: S_round = keccakf_rndc[2];
        3: S_round = keccakf_rndc[3];
        4: S_round = keccakf_rndc[4];
        5: S_round = keccakf_rndc[5];
        6: S_round = keccakf_rndc[6];
        7: S_round = keccakf_rndc[7];
        8: S_round = keccakf_rndc[8];
        9: S_round = keccakf_rndc[9];
        10: S_round = keccakf_rndc[10];
        11: S_round = keccakf_rndc[11];
        12: S_round = keccakf_rndc[12];
        13: S_round = keccakf_rndc[13];
        14: S_round = keccakf_rndc[14];
        15: S_round = keccakf_rndc[15];
        16: S_round = keccakf_rndc[16];
        17: S_round = keccakf_rndc[17];
        18: S_round = keccakf_rndc[18];
        19: S_round = keccakf_rndc[19];
        20: S_round = keccakf_rndc[20];
        21: S_round = keccakf_rndc[21];
        22: S_round = keccakf_rndc[22];
        23: S_round = keccakf_rndc[23];
        default: S_round = keccakf_rndc[23];
    endcase
    
    end
    
    
endmodule
