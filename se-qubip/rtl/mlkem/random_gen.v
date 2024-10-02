/**
  * @file random_gen.v
  * @brief Random Number Generator
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

// https://onlinelibrary.wiley.com/doi/10.1155/2012/219028
// https://d1wqtxts1xzle7.cloudfront.net/3468961/xapp210-libre.pdf?1390833615=&response-content-disposition=inline%3B+filename%3DLinear_feedback_shift_registers_in_virte.pdf&Expires=1721820396&Signature=ZRHx2ekQ-B4LGjK8ANN-~0jRzT0yqhbmtQ1DZUUqjPNkGk3cZrWKgMmbuk~xxMkw1vCgCch1I1aWa7MpB3UudMHwqct2MhCphwk9VBr-2SJEcX9FCKwuA7MNBSgjYL65qTr9f2bZ0G2nRPapOTR3L-YJiPTL8tH8xUN~m4hlk5CUhwjB6Gzju4XERt7iWcJRgc8uMa49AE8KmzuRUPDiN6S2-nSpExxUoGmt1mv-fVhrmBJHB0ZOHkq1fzd3Ukyaig65xftAEtNcHkSIwEK3OIIuGYC680LurDu802L559esilyf3aJ-S8nSU3dD00XbqnrlfIKtsdsW0CA-GAIp4w__&Key-Pair-Id=APKAJLOHF5GGSLRBV4ZA
// 
module random_gen #(
    parameter LFSR_N = 17,
    parameter SEED_LFSR = 128'h5149fc7f_2ee4ce28_9689fea9_adff284c,
    parameter SEED_CASR = 128'h6ce7bb42_4bb2e05f_88a74b4a_70e6e72d
    )(
    input clk,
    input rst,
    output [15:0] rand
    );
    
    wire [15:0] rand_lfsr;
    wire [15:0] rand_casr;
    
    assign rand = rand_lfsr ^ rand_casr;
    // assign rand = 16'h5555;
    
    genvar i;
    generate 
        for(i = 0; i < 16; i = i + 1) begin
            if(LFSR_N == 5) begin
            lfsr_5 #(.SEED(SEED_LFSR * i)) LFSR 
            (   .clk(clk), .rst(rst), .rand(rand_lfsr[i]));
            end
            else begin
            lfsr_17 #(.SEED(SEED_LFSR * i)) LFSR 
            (   .clk(clk), .rst(rst), .rand(rand_lfsr[i]));
            end
        end
    endgenerate
    
    casr_random_21 #(.SEED(SEED_CASR)) CASR 
    (.clk(clk), .rst(rst), .casr_out(rand_casr));
    
    
    // assign rand = 16'h5555;
    
    
endmodule

module lfsr_17 #(
    parameter [16:0] SEED = 17'h00000
)( 
    input clk,
    input rst,
    output rand
);

    reg     [16:0] reg_lfsr;
    
    assign rand = reg_lfsr[16];
    
    
    genvar i;
    generate 
    for (i = 0; i < 17; i = i + 1) begin
        if(i != 0) begin
            always @(posedge clk) begin
                if(!rst)    reg_lfsr[i] <= SEED[i];
                else        reg_lfsr[i] <= reg_lfsr[i-1];
            end       
        end
        else begin
            always @(posedge clk) begin
                if(!rst)    reg_lfsr[0] <= SEED[0];
                else        reg_lfsr[0] <= !(reg_lfsr[16] ^ reg_lfsr[13]);
            end  
        end
    end
    
    endgenerate

endmodule

module lfsr_5 #(
    parameter [4:0] SEED = 5'h00
)( 
    input clk,
    input rst,
    output rand
);

    reg     [4:0] reg_lfsr;
    
    assign rand = reg_lfsr[4];
    
    
    genvar i;
    generate 
    for (i = 0; i < 5; i = i + 1) begin
        if(i != 0) begin
            always @(posedge clk) begin
                if(!rst)    reg_lfsr[i] <= SEED[i];
                else        reg_lfsr[i] <= reg_lfsr[i-1];
            end       
        end
        else begin
            always @(posedge clk) begin
                if(!rst)    reg_lfsr[0] <= SEED[0];
                else        reg_lfsr[0] <= !(reg_lfsr[4] ^ reg_lfsr[2]);
            end  
        end
    end
    
    endgenerate

endmodule


module casr_random_21 #(
    parameter [20:0] SEED = 21'h0000_0000
    )(
    input clk,
    input rst,
    output [15:0] casr_out
    );
    
    reg     [20:0] reg_casr;
    wire    [20:0] wire_casr;
    
    assign casr_out = reg_casr[15:0];

    genvar i;
    generate 
    for (i = 0; i < 21; i = i + 1) begin
        always @(posedge clk) begin
            if(!rst)    reg_casr[i] <= SEED[i];
            else        reg_casr[i] <= wire_casr[i];
        end       
    end
    
    for (i = 0; i < 21; i = i + 1) begin
                if(i == 10)     assign wire_casr[10]    = reg_casr[9] ^ reg_casr[10] ^ reg_casr[11];
        else    if(i == 0)      assign wire_casr[0]     = reg_casr[15] ^ reg_casr[1];     // CA-90
        else                    assign wire_casr[i]     = reg_casr[i-1];      
    end
    endgenerate
    
endmodule