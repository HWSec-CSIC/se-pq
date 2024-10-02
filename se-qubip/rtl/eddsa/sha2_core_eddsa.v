/**
  * @file sha2_core_eddsa.v
  * @brief SHA2 Core Module
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

module sha2_core_eddsa #(
    parameter WIDTH = 64,
    parameter MODE = 512,
    parameter T = 0,
    parameter OUTPUT_SIZE = MODE
    )(
    input wire                       clk,
    input wire                       rst,
    input wire                       load,
    input wire                       start,
    output  wire                    end_op,
    input wire  [WIDTH-1:0]         data_in,
    output wire [(8*WIDTH - 1): 0]  H_out
    );
    
    
    // mem k signals
    reg [6:0] addr_k;
    reg  end_op_reg;
    
    assign end_op = end_op_reg;
    
    // sha2_round signals
    wire    [WIDTH-1:0] a_in;
    wire    [WIDTH-1:0] b_in;
    wire    [WIDTH-1:0] c_in;
    wire    [WIDTH-1:0] d_in;
    wire    [WIDTH-1:0] e_in;
    wire    [WIDTH-1:0] f_in;
    wire    [WIDTH-1:0] g_in;
    wire    [WIDTH-1:0] h_in;
    
    wire    [WIDTH-1:0] a_out;
    wire    [WIDTH-1:0] b_out;
    wire    [WIDTH-1:0] c_out;
    wire    [WIDTH-1:0] d_out;
    wire    [WIDTH-1:0] e_out;
    wire    [WIDTH-1:0] f_out;
    wire    [WIDTH-1:0] g_out;
    wire    [WIDTH-1:0] h_out;
    
    wire    [WIDTH-1:0] W;
    reg     [WIDTH-1:0] W_clk;
    wire    [WIDTH-1:0] K;
    
    // H REG signals
    generate 
        if(MODE == 224 & T == 0) begin: INI
            localparam a_0 = 32'hc1059ed8;
            localparam b_0 = 32'h367cd507;
            localparam c_0 = 32'h3070dd17;
            localparam d_0 = 32'hf70e5939;
            localparam e_0 = 32'hffc00b31;
            localparam f_0 = 32'h68581511;
            localparam g_0 = 32'h64f98fa7;
            localparam h_0 = 32'hbefa4fa4;
        end
        else if(MODE == 256 & T == 0) begin: INI
            localparam a_0 = 32'h6a09e667;
            localparam b_0 = 32'hbb67ae85;
            localparam c_0 = 32'h3c6ef372;
            localparam d_0 = 32'ha54ff53a;
            localparam e_0 = 32'h510e527f;
            localparam f_0 = 32'h9b05688c;
            localparam g_0 = 32'h1f83d9ab;
            localparam h_0 = 32'h5be0cd19;
        end
        else if(MODE == 384 & T == 0) begin: INI
            localparam a_0 = 64'hcbbb9d5d_c1059ed8;
            localparam b_0 = 64'h629a292a_367cd507;
            localparam c_0 = 64'h9159015a_3070dd17;
            localparam d_0 = 64'h152fecd8_f70e5939;
            localparam e_0 = 64'h67332667_ffc00b31;
            localparam f_0 = 64'h8eb44a87_68581511;
            localparam g_0 = 64'hdb0c2e0d_64f98fa7;
            localparam h_0 = 64'h47b5481d_befa4fa4;
        end
        else if(MODE == 512 & T == 0) begin: INI
            localparam a_0 = 64'h6a09e667_f3bcc908;
            localparam b_0 = 64'hbb67ae85_84caa73b;
            localparam c_0 = 64'h3c6ef372_fe94f82b;
            localparam d_0 = 64'ha54ff53a_5f1d36f1;
            localparam e_0 = 64'h510e527f_ade682d1;
            localparam f_0 = 64'h9b05688c_2b3e6c1f;
            localparam g_0 = 64'h1f83d9ab_fb41bd6b;
            localparam h_0 = 64'h5be0cd19_137e2179;
        end
        else if(MODE == 512 & T == 224) begin: INI
            localparam a_0 = 64'h8c3d37c8_19544da2;
            localparam b_0 = 64'h73e19966_89dcd4d6;
            localparam c_0 = 64'h1dfab7ae_32ff9c82;
            localparam d_0 = 64'h679dd514_582f9fcf;
            localparam e_0 = 64'h0f6d2b69_7bd44da8;
            localparam f_0 = 64'h77e36f73_04c48942;
            localparam g_0 = 64'h3f9d85a8_6a1d36c8;
            localparam h_0 = 64'h1112e6ad_91d692a1;
        end
        else if(MODE == 512 & T == 256) begin: INI
            localparam a_0 = 64'h22312194_fc2bf72c;
            localparam b_0 = 64'h9f555fa3_c84c64c2;
            localparam c_0 = 64'h2393b86b_6f53b151;
            localparam d_0 = 64'h96387719_5940eabd;
            localparam e_0 = 64'h96283ee2_a88effe3;
            localparam f_0 = 64'hbe5e1e25_53863992;
            localparam g_0 = 64'h2b0199fc_2c85b8aa;
            localparam h_0 = 64'h0eb72ddc_81c52ca2;
        end
        else begin: INI
            localparam a_0 = 32'h6a09e667;
            localparam b_0 = 32'hbb67ae85;
            localparam c_0 = 32'h3c6ef372;
            localparam d_0 = 32'ha54ff53a;
            localparam e_0 = 32'h510e527f;
            localparam f_0 = 32'h9b05688c;
            localparam g_0 = 32'h1f83d9ab;
            localparam h_0 = 32'h5be0cd19;
        end
    endgenerate
    
    reg [(8*WIDTH - 1): 0] H;
    
    assign a_in = H[8*WIDTH-1:7*WIDTH];
    assign b_in = H[7*WIDTH-1:6*WIDTH];
    assign c_in = H[6*WIDTH-1:5*WIDTH];
    assign d_in = H[5*WIDTH-1:4*WIDTH];
    assign e_in = H[4*WIDTH-1:3*WIDTH];
    assign f_in = H[3*WIDTH-1:2*WIDTH];
    assign g_in = H[2*WIDTH-1:1*WIDTH];
    assign h_in = H[1*WIDTH-1:0*WIDTH];
    
    // H_ini signals
    reg save_h;
    reg [(8*WIDTH - 1): 0] H_ini;
    assign H_out = H_ini;
    
    wire    [WIDTH-1:0] a_sum;
    wire    [WIDTH-1:0] b_sum;
    wire    [WIDTH-1:0] c_sum;
    wire    [WIDTH-1:0] d_sum;
    wire    [WIDTH-1:0] e_sum;
    wire    [WIDTH-1:0] f_sum;
    wire    [WIDTH-1:0] g_sum;
    wire    [WIDTH-1:0] h_sum;
    
    wire    [WIDTH-1:0] a_ini;
    wire    [WIDTH-1:0] b_ini;
    wire    [WIDTH-1:0] c_ini;
    wire    [WIDTH-1:0] d_ini;
    wire    [WIDTH-1:0] e_ini;
    wire    [WIDTH-1:0] f_ini;
    wire    [WIDTH-1:0] g_ini;
    wire    [WIDTH-1:0] h_ini;
    
    assign a_ini = H_ini[8*WIDTH-1:7*WIDTH];
    assign b_ini = H_ini[7*WIDTH-1:6*WIDTH];
    assign c_ini = H_ini[6*WIDTH-1:5*WIDTH];
    assign d_ini = H_ini[5*WIDTH-1:4*WIDTH];
    assign e_ini = H_ini[4*WIDTH-1:3*WIDTH];
    assign f_ini = H_ini[3*WIDTH-1:2*WIDTH];
    assign g_ini = H_ini[2*WIDTH-1:1*WIDTH];
    assign h_ini = H_ini[1*WIDTH-1:0*WIDTH];
    
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
    
    always @(posedge clk) begin
        if(!rst)    H_ini <= {INI.a_0,INI.b_0,INI.c_0,INI.d_0,INI.e_0,INI.f_0,INI.g_0,INI.h_0};
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
    
    generate 
        if(MODE == 224 | MODE == 256) begin
            mem_ROM_k_256_eddsa mem_ROM_k_eddsa (.clk(clk), .enable(1), .addr(addr_k), .data(K));
            localparam MAX_K = 64;
            
            always @(posedge clk) begin
                if(!rst) end_op_reg <= 0;
                else begin
                    if(addr_k == MAX_K - 2)     end_op_reg <= 1;
                    else if (load)              end_op_reg <= 0;
                    else                        end_op_reg <= end_op_reg;
                end
            end  
        end
        
        else if(MODE == 384 | MODE == 512) begin
            mem_ROM_k_512_eddsa mem_ROM_k_eddsa (.clk(clk), .enable(1), .addr(addr_k), .data(K));
            localparam MAX_K = 80;
   
            
            always @(posedge clk) begin
                if(!rst) end_op_reg <= 0;
                else begin
                    if(addr_k == MAX_K - 2)     end_op_reg <= 1;
                    else if (load)              end_op_reg <= 0;
                    else                        end_op_reg <= end_op_reg;
                end
            end  
        end
        else begin
            mem_ROM_k_256_eddsa mem_ROM_k_eddsa (.clk(clk), .enable(1), .addr(addr_k), .data(K));
            localparam MAX_K = 64;
            
            
            always @(posedge clk) begin
                if(!rst) end_op_reg <= 0;
                else begin
                    if(addr_k == MAX_K - 2)     end_op_reg <= 1;
                    else if (load)              end_op_reg <= 0;
                    else                        end_op_reg <= end_op_reg;
                end
            end  
        end
    endgenerate
    
    sha2_message_schedule_eddsa #(.WIDTH(WIDTH), .MODE(MODE))
    sha2_message_schedule_eddsa ( .clk(clk), .rst(rst), .load(load), .start(start & !end_op_reg), 
                            .data_in(data_in), .data_out(W));
    
    sha2_round_eddsa  #(.WIDTH(WIDTH), .MODE(MODE))
    sha2_round_eddsa (.a(a_in),       .b(b_in),       .c(c_in),       .d(d_in),       .e(e_in),       .f(f_in),       .g(g_in),       .h(h_in),
                .a_out(a_out),  .b_out(b_out),  .c_out(c_out),  .d_out(d_out),  .e_out(e_out),  .f_out(f_out),  .g_out(g_out),  .h_out(h_out),
                .W(W), .K(K));
    
    always @(posedge clk) begin
        if(!rst) addr_k <= 0;
        else begin
            if(start & !end_op_reg) addr_k <= addr_k + 1;
            else if(load)           addr_k <= 0;
            else                    addr_k <= addr_k;
        end
    end  
    
endmodule    
/*
module sha2_core_probe#(
    parameter WIDTH = 32
    )(
    input                   clk,
    input                   rst,
    input                   load,
    input                   start,
    output                  end_op,
    input   [WIDTH-1:0]     data_in,
    output  [(8*32 - 1): 0] H_out,
    output  [31:0]          probe1,
    output  [31:0]          probe2,
    output  [31:0]          probe3,
    output  [31:0]          probe4
    );
    
    
    // mem k signals
    reg [5:0] addr_k;
    reg  end_op_reg;
    
    assign end_op = end_op_reg;
    
    // sha2_round signals
    wire    [WIDTH-1:0] a_in;
    wire    [WIDTH-1:0] b_in;
    wire    [WIDTH-1:0] c_in;
    wire    [WIDTH-1:0] d_in;
    wire    [WIDTH-1:0] e_in;
    wire    [WIDTH-1:0] f_in;
    wire    [WIDTH-1:0] g_in;
    wire    [WIDTH-1:0] h_in;
    
    wire    [WIDTH-1:0] a_out;
    wire    [WIDTH-1:0] b_out;
    wire    [WIDTH-1:0] c_out;
    wire    [WIDTH-1:0] d_out;
    wire    [WIDTH-1:0] e_out;
    wire    [WIDTH-1:0] f_out;
    wire    [WIDTH-1:0] g_out;
    wire    [WIDTH-1:0] h_out;
    
    wire    [WIDTH-1:0] W;
    reg     [WIDTH-1:0] W_clk;
    wire    [WIDTH-1:0] K;
    
    assign probe1 = a_in;
    assign probe2 = W_clk;
    assign probe3 = K;
    assign probe4 = a_out;
    
    // H REG signals
    
    localparam a_0 = 32'h6a09e667;
    localparam b_0 = 32'hbb67ae85;
    localparam c_0 = 32'h3c6ef372;
    localparam d_0 = 32'ha54ff53a;
    localparam e_0 = 32'h510e527f;
    localparam f_0 = 32'h9b05688c;
    localparam g_0 = 32'h1f83d9ab;
    localparam h_0 = 32'h5be0cd19;
    
    reg [(8*32 - 1): 0] H;
    
    assign a_in = H[8*32-1:7*32];
    assign b_in = H[7*32-1:6*32];
    assign c_in = H[6*32-1:5*32];
    assign d_in = H[5*32-1:4*32];
    assign e_in = H[4*32-1:3*32];
    assign f_in = H[3*32-1:2*32];
    assign g_in = H[2*32-1:1*32];
    assign h_in = H[1*32-1:0*32];
    
    // H_ini signals
    reg save_h;
    reg [(8*32 - 1): 0] H_ini;
    assign H_out = H_ini;
    
    wire    [WIDTH-1:0] a_sum;
    wire    [WIDTH-1:0] b_sum;
    wire    [WIDTH-1:0] c_sum;
    wire    [WIDTH-1:0] d_sum;
    wire    [WIDTH-1:0] e_sum;
    wire    [WIDTH-1:0] f_sum;
    wire    [WIDTH-1:0] g_sum;
    wire    [WIDTH-1:0] h_sum;
    
    wire    [WIDTH-1:0] a_ini;
    wire    [WIDTH-1:0] b_ini;
    wire    [WIDTH-1:0] c_ini;
    wire    [WIDTH-1:0] d_ini;
    wire    [WIDTH-1:0] e_ini;
    wire    [WIDTH-1:0] f_ini;
    wire    [WIDTH-1:0] g_ini;
    wire    [WIDTH-1:0] h_ini;
    
    assign a_ini = H_ini[8*32-1:7*32];
    assign b_ini = H_ini[7*32-1:6*32];
    assign c_ini = H_ini[6*32-1:5*32];
    assign d_ini = H_ini[5*32-1:4*32];
    assign e_ini = H_ini[4*32-1:3*32];
    assign f_ini = H_ini[3*32-1:2*32];
    assign g_ini = H_ini[2*32-1:1*32];
    assign h_ini = H_ini[1*32-1:0*32];
    
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
                     if(!end_op_reg) H <= {a_out,b_out,c_out,d_out,e_out,f_out,g_out,h_out};
                     else            H <= H;
                end
        end
    end
    
    always @(posedge clk) begin
        if(!rst)    H_ini <= {a_0,b_0,c_0,d_0,e_0,f_0,g_0,h_0};
        else begin
                if(end_op_reg & save_h)  H_ini <= {a_sum,b_sum,c_sum,d_sum,e_sum,f_sum,g_sum,h_sum};
                else                     H_ini <= H_ini;
        end
    end
    
    always @(posedge clk) begin
        if(!rst) save_h <= 0;
        else begin
            if(load) save_h <= 1;
            else if (end_op_reg) save_h <= 0;
            else save_h <= save_h;
        end
    
    end
    
    
    mem_ROM_k_2 mem_ROM_k (.clk(clk), .enable(1), .addr(addr_k), .data(K));
    
    sha2_message_schedule
    sha2_message_schedule ( .clk(clk), .rst(rst), .load(load), .start(start & !end_op_reg), 
                            .data_in(data_in), .data_out(W));
    
    sha2_round 
    sha2_round (.a(a_in),       .b(b_in),       .c(c_in),       .d(d_in),       .e(e_in),       .f(f_in),       .g(g_in),       .h(h_in),
                .a_out(a_out),  .b_out(b_out),  .c_out(c_out),  .d_out(d_out),  .e_out(e_out),  .f_out(f_out),  .g_out(g_out),  .h_out(h_out),
                .W(W_clk), .K(K));
    
    always @(posedge clk) W_clk <= W;
    
    always @(posedge clk) begin
        if(!rst) addr_k <= 0;
        else begin
            if(start & !end_op_reg) addr_k <= addr_k + 1;
            else if(load)           addr_k <= 0;
            else                    addr_k <= addr_k;
        end
    end
    
    always @(posedge clk) begin
        if(!rst) end_op_reg <= 0;
        else begin
            if(addr_k == 62)    end_op_reg <= 1;
            else if (load)      end_op_reg <= 0;
            else                end_op_reg <= end_op_reg;
        end
    end    
    
endmodule
*/