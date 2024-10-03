/**
  * @file sha2_round_eddsa.v
  * @brief SHA2 EDDSA Round
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



module sha2_round_eddsa # (
    parameter WIDTH = 32,
    parameter MODE = 256
    )(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire [WIDTH-1:0] c,
    input wire [WIDTH-1:0] d,
    input wire [WIDTH-1:0] e,
    input wire [WIDTH-1:0] f,
    input wire [WIDTH-1:0] g,
    input wire [WIDTH-1:0] h,
    output wire [WIDTH-1:0] a_out,
    output wire [WIDTH-1:0] b_out,
    output wire [WIDTH-1:0] c_out,
    output wire [WIDTH-1:0] d_out,
    output wire [WIDTH-1:0] e_out,
    output wire [WIDTH-1:0] f_out,
    output wire [WIDTH-1:0] g_out,
    output wire [WIDTH-1:0] h_out,
    input wire [WIDTH-1:0] W,
    input wire [WIDTH-1:0] K
    );
    
    wire    [WIDTH-1:0] out_1; 
    wire    [WIDTH-1:0] out_2;
    wire    [WIDTH-1:0] out_3;
    wire    [WIDTH-1:0] out_4; 
    wire    [WIDTH-1:0] T1;
    wire    [WIDTH-1:0] T2;
    
    generate 
        if(MODE == 224 | MODE == 256) begin
            eps_1_eddsa #(.SIZE(WIDTH)) eps1_eddsa (.x(e), .out(out_1));
            Choice_eddsa #(.SIZE(WIDTH)) Ch_eddsa (.x(e), .y(f), .z(g), .out(out_2));
            eps_0_eddsa #(.SIZE(WIDTH)) eps0_eddsa (.x(a), .out(out_3));
            Majority_eddsa #(.SIZE(WIDTH)) Mj_eddsa (.x(a), .y(b), .z(c), .out(out_4));
        end
        else if(MODE == 384 | MODE == 512) begin
            eps_1_512_eddsa #(.SIZE(WIDTH)) eps1_eddsa (.x(e), .out(out_1));
            Choice_eddsa #(.SIZE(WIDTH)) Ch_eddsa (.x(e), .y(f), .z(g), .out(out_2));
            eps_0_512_eddsa #(.SIZE(WIDTH)) eps0_eddsa (.x(a), .out(out_3));
            Majority_eddsa #(.SIZE(WIDTH)) Mj_eddsa (.x(a), .y(b), .z(c), .out(out_4));
        end
    endgenerate
    
    assign T1 = out_1 + out_2 + h + W + K;
    assign T2 = out_3 + out_4;
    
    assign a_out = T1 + T2;
    assign b_out = a;
    assign c_out = b;
    assign d_out = c;
    assign e_out = d + T1;
    assign f_out = e;
    assign g_out = f;
    assign h_out = g;
    
endmodule

module Choice_eddsa # (
    parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    input wire [SIZE-1:0] y,
    input wire [SIZE-1:0] z,
    output wire [SIZE-1:0] out
    );
    
    assign out = (x & y) ^ (~x & z);
endmodule

module Majority_eddsa # (
    parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    input wire [SIZE-1:0] y,
    input wire [SIZE-1:0] z,
    output wire [SIZE-1:0] out
    );
    
    assign out = (x & y) ^ (x & z) ^ (y & z);
endmodule