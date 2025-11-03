/**
  * @file  reduce.v
  * @brief Montgomery reduction
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

module montgomery_reduce #(
    parameter QINV = 62209,
    parameter KYBER_Q = 3329
    )(
    input [31:0] a,
    output [15:0] t
    );
    
    wire [15:0] u;
    wire [31:0] t1;
    wire [15:0] t2;
    
    assign u = a[15:0]*QINV;
    assign t1 = {{16{u[15]}},u}*KYBER_Q;
    assign t2 = a[31:16] - t1[31:16];
    
    assign t = t2;
    
endmodule


module barret_reduce_pipe #(
    parameter KYBER_Q = 3329,
    parameter v = ((1 << 26) + (KYBER_Q/2))/KYBER_Q
    )(
    input clk,
    input [15:0] a,
    output [15:0] t
    );
    
    wire    [31:0] t1;
    wire     [31:0] t2;
    
    reg [31:0] mult;
    wire [31:0] a32;
    reg [31:0] a32_reg;
    assign a32 = {{16{a[15]}},a};
    always @(posedge clk) a32_reg <= a32;
    
    always @(posedge clk) mult <= v*a32;
    //assign t1 = {{26{mult[31]}},mult[31:26]};
    assign t1 = (mult + (1'b1 << 25));
    
    assign t2 = {{26{t1[31]}},t1[31:26]}*KYBER_Q;
    
    assign t = a32_reg - t2;
    
endmodule