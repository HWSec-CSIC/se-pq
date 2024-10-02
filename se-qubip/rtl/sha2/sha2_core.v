/**
  * @file sha2_core.v
  * @brief SHA2 Core
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

module sha2_core (
    input                       clk,
    input                       rst,
    input   [3:0]               mode,                    
    input                       load,
    input                       start,
    output                      end_op,
    input   [63:0]              data_in,
    output  [(8*64 - 1): 0]     H_out
    );
    
    
    // mem k signals
    reg [6:0] addr_k;
    reg  end_op_reg;
    
    assign end_op = end_op_reg;
    
    // sha2_round signals
    wire    [63:0] a_in;
    wire    [63:0] b_in;
    wire    [63:0] c_in;
    wire    [63:0] d_in;
    wire    [63:0] e_in;
    wire    [63:0] f_in;
    wire    [63:0] g_in;
    wire    [63:0] h_in;

    wire    [63:0] a_out;
    wire    [63:0] b_out;
    wire    [63:0] c_out;
    wire    [63:0] d_out;
    wire    [63:0] e_out;
    wire    [63:0] f_out;
    wire    [63:0] g_out;
    wire    [63:0] h_out;

    wire    [63:0] W;
    wire    [31:0] K_256;
    wire    [63:0] K_512;
    
    wire sha_256;
    wire sha_384;
    wire sha_512;
    wire sha_512_256;
    
    assign sha_256     = mode[0];
    assign sha_384     = mode[1];
    assign sha_512     = mode[2];
    assign sha_512_256 = mode[3];
    
    
    // H REG signals
    localparam a_0_256 = 64'h00000000_6a09e667;
    localparam b_0_256 = 64'h00000000_bb67ae85;
    localparam c_0_256 = 64'h00000000_3c6ef372;
    localparam d_0_256 = 64'h00000000_a54ff53a;
    localparam e_0_256 = 64'h00000000_510e527f;
    localparam f_0_256 = 64'h00000000_9b05688c;
    localparam g_0_256 = 64'h00000000_1f83d9ab;
    localparam h_0_256 = 64'h00000000_5be0cd19;

    localparam a_0_384 = 64'hcbbb9d5d_c1059ed8;
    localparam b_0_384 = 64'h629a292a_367cd507;
    localparam c_0_384 = 64'h9159015a_3070dd17;
    localparam d_0_384 = 64'h152fecd8_f70e5939;
    localparam e_0_384 = 64'h67332667_ffc00b31;
    localparam f_0_384 = 64'h8eb44a87_68581511;
    localparam g_0_384 = 64'hdb0c2e0d_64f98fa7;
    localparam h_0_384 = 64'h47b5481d_befa4fa4;

    localparam a_0_512 = 64'h6a09e667_f3bcc908;
    localparam b_0_512 = 64'hbb67ae85_84caa73b;
    localparam c_0_512 = 64'h3c6ef372_fe94f82b;
    localparam d_0_512 = 64'ha54ff53a_5f1d36f1;
    localparam e_0_512 = 64'h510e527f_ade682d1;
    localparam f_0_512 = 64'h9b05688c_2b3e6c1f;
    localparam g_0_512 = 64'h1f83d9ab_fb41bd6b;
    localparam h_0_512 = 64'h5be0cd19_137e2179;
    
    localparam a_0_512_256 = 64'h22312194_fc2bf72c;
    localparam b_0_512_256 = 64'h9f555fa3_c84c64c2;
    localparam c_0_512_256 = 64'h2393b86b_6f53b151;
    localparam d_0_512_256 = 64'h96387719_5940eabd;
    localparam e_0_512_256 = 64'h96283ee2_a88effe3;
    localparam f_0_512_256 = 64'hbe5e1e25_53863992;
    localparam g_0_512_256 = 64'h2b0199fc_2c85b8aa;
    localparam h_0_512_256 = 64'h0eb72ddc_81c52ca2;

    reg [(8*64 - 1): 0] H;
    
    assign a_in = H[8*64-1:7*64];
    assign b_in = H[7*64-1:6*64];
    assign c_in = H[6*64-1:5*64];
    assign d_in = H[5*64-1:4*64];
    assign e_in = H[4*64-1:3*64];
    assign f_in = H[3*64-1:2*64];
    assign g_in = H[2*64-1:1*64];
    assign h_in = H[1*64-1:0*64];
    
    // H_ini signals
    reg save_h;
    reg [(8*64 - 1): 0] H_ini;
    assign H_out = H_ini;
    
    wire    [63:0] a_sum;
    wire    [63:0] b_sum;
    wire    [63:0] c_sum;
    wire    [63:0] d_sum;
    wire    [63:0] e_sum;
    wire    [63:0] f_sum;
    wire    [63:0] g_sum;
    wire    [63:0] h_sum;

    wire    [63:0] a_ini;
    wire    [63:0] b_ini;
    wire    [63:0] c_ini;
    wire    [63:0] d_ini;
    wire    [63:0] e_ini;
    wire    [63:0] f_ini;
    wire    [63:0] g_ini;
    wire    [63:0] h_ini;
    
    assign a_ini = H_ini[8*64-1:7*64];
    assign b_ini = H_ini[7*64-1:6*64];
    assign c_ini = H_ini[6*64-1:5*64];
    assign d_ini = H_ini[5*64-1:4*64];
    assign e_ini = H_ini[4*64-1:3*64];
    assign f_ini = H_ini[3*64-1:2*64];
    assign g_ini = H_ini[2*64-1:1*64];
    assign h_ini = H_ini[1*64-1:0*64];
    
    assign a_sum = a_ini + a_out;
    assign b_sum = b_ini + b_out;
    assign c_sum = c_ini + c_out;
    assign d_sum = d_ini + d_out;
    assign e_sum = e_ini + e_out;
    assign f_sum = f_ini + f_out;
    assign g_sum = g_ini + g_out;
    assign h_sum = h_ini + h_out;
    
    always @(posedge clk) begin
        if(!rst)    H <= 0;
        else begin
                if (load) H <= H_ini;
                else begin
                     if(start & !end_op_reg) H <= {a_out,b_out,c_out,d_out,e_out,f_out,g_out,h_out};
                     else            H <= H;
                end
        end
    end
    
    wire [(8*64 - 1): 0] H_ini_256;
    wire [(8*64 - 1): 0] H_ini_384;
    wire [(8*64 - 1): 0] H_ini_512;
    wire [(8*64 - 1): 0] H_ini_512_256;
    
    assign H_ini_256 = {a_0_256,b_0_256,c_0_256,d_0_256,e_0_256,f_0_256,g_0_256,h_0_256};
    assign H_ini_384 = {a_0_384,b_0_384,c_0_384,d_0_384,e_0_384,f_0_384,g_0_384,h_0_384};
    assign H_ini_512 = {a_0_512,b_0_512,c_0_512,d_0_512,e_0_512,f_0_512,g_0_512,h_0_512};
    assign H_ini_512_256 = {a_0_512_256,b_0_512_256,c_0_512_256,d_0_512_256,e_0_512_256,f_0_512_256,g_0_512_256,h_0_512_256};
        
    always @(posedge clk) begin
        if(!rst) begin
                    if(sha_256)        H_ini <= H_ini_256;
            else    if(sha_384)        H_ini <= H_ini_384;
            else    if(sha_512)        H_ini <= H_ini_512;
            else    if(sha_512_256)    H_ini <= H_ini_512_256;
            else                        H_ini <= {8*64{1'b0}};
        end
        else begin
                if(end_op_reg & save_h)  H_ini <= {a_sum,b_sum,c_sum,d_sum,e_sum,f_sum,g_sum,h_sum};
                else                     H_ini <= H_ini;
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                    save_h <= 0;
        else begin
            if(load)                save_h <= 1;
            else if (end_op_reg)    save_h <= 0;
            else                    save_h <= save_h;
        end
    end
    
    mem_ROM_k_256 mem_ROM_k_256 (.clk(clk), .enable(1), .addr(addr_k), .data(K_256));
    mem_ROM_k_512 mem_ROM_k_512 (.clk(clk), .enable(1), .addr(addr_k), .data(K_512));
    
    reg [7:0] MAX_K;
    
    always @(posedge clk) begin
        if(!rst) MAX_K <= 0;
        else begin
            if(sha_256)    MAX_K <= 64;
            else            MAX_K <= 80;
        end
    end
    
    always @(posedge clk) begin
        if(!rst) end_op_reg <= 0;
        else begin
            if(addr_k == MAX_K - 2)     end_op_reg <= 1;
            else if (load)              end_op_reg <= 0;
            else                        end_op_reg <= end_op_reg;
        end
    end  
    
    wire mode_sha2;
    assign mode_sha2 = (sha_256) ? 0 : 1;
    
    sha2_message_schedule
    sha2_message_schedule ( .clk(clk), .rst(rst), .load(load), .start(start & !end_op_reg), .mode_sha2(mode_sha2),
                            .data_in(data_in), .data_out(W));
    
    sha2_round 
    sha2_round (.a(a_in),       .b(b_in),       .c(c_in),       .d(d_in),       .e(e_in),       .f(f_in),       .g(g_in),       .h(h_in),
                .a_out(a_out),  .b_out(b_out),  .c_out(c_out),  .d_out(d_out),  .e_out(e_out),  .f_out(f_out),  .g_out(g_out),  .h_out(h_out),
                .W(W), .K_256(K_256), .K_512(K_512), .mode_sha2(mode_sha2));
    
    always @(posedge clk) begin
        if(!rst) addr_k <= 0;
        else begin
            if(start & !end_op_reg) addr_k <= addr_k + 1;
            else if(load)           addr_k <= 0;
            else                    addr_k <= addr_k;
        end
    end  
    
endmodule    
