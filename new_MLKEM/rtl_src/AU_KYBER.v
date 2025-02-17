/**
  * @file AU_KYBER.v
  * @brief AU KYBER Core Module
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

module AU_CORE #(
    parameter COUNTER = 1
    )(
    input               clk,
    input               rst,
    input               fixed,
    input    [47:0]     control,
    input    [31:0]     data_in,
    output   [15:0]     data_out,
    input    [15:0]     add,
    output              end_op,
    output              check_ct
    );
    
    wire [7:0] control_ntt;
    wire [7:0] control_sha3;
    wire [3:0] x;
    wire [3:0] y;
    wire [7:0] control_enc_dec;
    wire [7:0] state_au;
    
    assign control_ntt      =   control[07:00];
    assign control_sha3     =   control[15:08];
    assign x                =   control[19:16];
    assign y                =   control[23:20];
    assign control_enc_dec  =   control[31:24];
    assign state_au         =   control[47:40]; 

    assign reset_au                             = (state_au[7:4] == 4'h0)   ? 1 : 0;
    assign load_au                              = (state_au[7:4] == 4'h1)   ? 1 : 0;
    assign load_seed                            = (state_au[7:4] == 4'h2)   ? 1 : 0;
    assign start_au                             = (state_au[7:4] == 4'h3)   ? 1 : 0;
    assign read_au                              = (state_au[7:4] == 4'h4)   ? 1 : 0;
    assign reset_sha3                           = (state_au[7:4] == 4'h5)   ? 1 : 0;
    assign load_ct                              = (state_au[7:4] == 4'h6)   ? 1 : 0;
    assign comp_ct                              = (state_au[7:4] == 4'h7)   ? 1 : 0;
    assign end_program                          = (state_au[7:4] == 4'hF)   ? 1 : 0; 
    
    
     // --- NTT + INVNTT + ACC + ADD + SUB --- //
    
    wire  [31:0]          data_in_ntt;
    wire  [15:0]          data_out_ntt;
    wire  [7:0]           add_ntt;
    // wire  [7:0]           control_ntt;
    wire                  end_op_ntt;
   
     poly_ntt_acc poly_ntt_acc
     (  .clk(clk),              .rst(rst & !reset_au), 
        .r_in(data_in_ntt),      .add(add_ntt),
        .r_out(data_out_ntt),    .control(control_ntt),
        .end_op(end_op_ntt)
    );
    
    assign data_in_ntt  =   data_in;
    assign add_ntt      =   add[7:0];
    assign control_ntt  =   control[7:0];
    
    // --- SHA3 + XOF + PRF --- //
    
    wire  [15:0]          data_in_sha3;
    wire  [15:0]          data_out_sha3;
    wire  [7:0]           add_sha3;
    wire                  end_op_sha3;
   
     XOF_PRF_SHA3 #(
     .COUNTER(COUNTER)
     )
     XOF_PRF_SHA3
     (  .clk(clk),              .rst(rst & !reset_au), 
        .load_seed(load_seed),  .x(x), .y(y),  
        .data_in(data_in_sha3),      .add(add_sha3),
        .data_out(data_out_sha3),    .control(control_sha3),
        .end_op(end_op_sha3)
    );
    
    assign data_in_sha3  =   data_in;
    assign add_sha3      =   add[7:0];
    
    // BYTE ENCODE + DECODE //
    
    wire  [15:0]          data_in_enc_dec;
    wire  [15:0]          data_out_enc_dec;
    wire  [15:0]          add_enc_dec;
    wire                  end_op_enc_dec;
   
     ByteEncDec ByteEncDec
     (  .clk(clk),              .rst(rst & !reset_au), 
        .data_in(data_in_enc_dec),      .add(add_enc_dec),
        .data_out(data_out_enc_dec),    .control(control_enc_dec),
        .end_op(end_op_enc_dec)
    );
    
    assign data_in_enc_dec  =   data_in;
    assign add_enc_dec      =   add;
    
    // --- 8 to 16 --- //
    
    wire [15:0] data_out_8_16;
    
    X_to_Y #(.X(8), .Y(16)) 
    adap_8_to_16 (
        .clk(clk),
        .rst(rst & !reset_au),
        .enable(load_au),
        .data_in(data_in),
        .add(add),
        .data_out(data_out_8_16)
    );
    
    // --- CHECK_CT --- //
    CHECK_CT
    CHECK_CT (
        .clk(clk),
        .rst(rst & !reset_au),
        .enable(load_ct),
        .enable_comp(comp_ct),
        .data_in(data_in),
        .add_in(add),
        .check_ct(check_ct)
    );
    
    // --- Common outputs --- //
    wire sel_ntt;
    assign sel_ntt      = (control_ntt      == 8'h00) ? 0 : 1;
    wire sel_sha3;
    assign sel_sha3     = (control_sha3     == 8'h00) ? 0 : 1;
    wire sel_enc_dec;
    assign sel_enc_dec   = (control_enc_dec == 8'h00) ? 0 : 1;
    
    reg [15:0] data_out_reg;
    always @* begin
                if(sel_ntt)         data_out_reg = data_out_ntt;
        else    if(sel_sha3)        data_out_reg = data_out_sha3;
        else    if(sel_enc_dec)     data_out_reg = data_out_enc_dec;
        else                        data_out_reg = data_out_8_16;
    end
    assign data_out     =   data_out_reg;
    
    
    reg end_op_reg;
    always @* begin
                if(sel_ntt)         end_op_reg = end_op_ntt;
        else    if(sel_sha3)        end_op_reg = end_op_sha3;
        else    if(sel_enc_dec)     end_op_reg = end_op_enc_dec;
        else                        end_op_reg = 1;
    end
    assign end_op     =   end_op_reg;
    
   
      
endmodule


module X_to_Y #(
    parameter X = 8,
    parameter Y = 16
)(
    input clk,
    input rst,
    input enable,
    input [X-1:0] data_in,
    input [15:0] add,
    output [Y-1:0] data_out
);
    generate
        if(X == 8 & Y == 16) begin
        
        reg [15:0] reg_in;
        
        RAM #(.SIZE(256) ,.WIDTH(Y))
        RAM 
        (.clk(clk), .en_write(enable), .en_read(1), 
        .addr_write(add >> 1), .addr_read(add),
        .data_in(reg_in), .data_out(data_out));
        /*
        always @(posedge clk) begin
            if(!rst) reg_in <= 0;
            else begin
                if(!add_in[0])  reg_in[07:00] <= data_in;
                else            reg_in[15:08] <= data_in;
            end
        end
        */
         always @* begin
                if(!add[0])  reg_in[07:00] = data_in;
                else         reg_in[15:08] = data_in;
        end
        end
    endgenerate
endmodule

module CHECK_CT 
(
    input clk,
    input rst,
    input enable,
    input enable_comp,
    input [7:0] data_in,
    input [15:0] add_in,
    output check_ct
);
    
    reg check_ct_reg;
    assign check_ct = check_ct_reg;
    
    wire [7:0] data_out;
    RAM #(.SIZE(1600) ,.WIDTH(8))
        RAM 
        (.clk(clk), .en_write(enable), .en_read(1), 
        .addr_write(add_in), .addr_read(add_in),
        .data_in(data_in), .data_out(data_out));
    
    reg start;
    
    always @(posedge clk) begin
        if(!rst | !start) check_ct_reg <= 0;
        else begin
            if((data_out ^ data_in) == 8'h0)  check_ct_reg <= check_ct_reg;
            else                              check_ct_reg <= 1;
        end 
    
    end
    
    always @(posedge clk) begin
        if(!rst | !enable_comp) start <= 0;
        else begin
            if(add_in == 0)     start <= 1;
            else                start <= 0;
        end 
    end
    
endmodule
