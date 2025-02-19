/**
  * @file XOF_PRF_SHA3.v
  * @brief XOF_PRF_SHA3 Module
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


module XOF_PRF_SHA3 #(
    parameter COUNTER = 1,
    parameter RATE_SHAKE_128 = 168,
    parameter RATE_SHAKE_256 = 136
    )(
    input               clk,
    input               rst,
    input               load_seed,
    input   [3:0]       x,
    input   [3:0]       y, 
    input   [7:0]       control,
    input   [15:0]      data_in,
    input   [7:0]       add,
    output  [15:0]      data_out,
    output              end_op
    );
    
    localparam N_BLOCK = 4;
    
    // wire [63:0] REG_IN_XOF_PRF [24:0];
    
    // --- Control Signals --- //
    wire [3:0] sel_alg;
    wire sha3_512;
    wire sha3_256;
    wire shake128;
    wire shake256;
    wire ntt_xof;
    wire prf_eta1_3;
    wire prf_eta1_2;
    wire prf_eta2;
    
    assign sel_alg = control[7:4];
    assign sha3_512     = (sel_alg[2:0] == 3'b000) ? 1 : 0;
    assign sha3_256     = (sel_alg[2:0] == 3'b001) ? 1 : 0;
    assign shake128     = (sel_alg[2:0] == 3'b010) ? 1 : 0;
    assign shake256     = (sel_alg[2:0] == 3'b011) ? 1 : 0;
    assign ntt_xof      = (sel_alg[2:0] == 3'b100) ? 1 : 0;
    assign prf_eta1_3   = (sel_alg[2:0] == 3'b101) ? 1 : 0;
    assign prf_eta1_2   = (sel_alg[2:0] == 3'b110) ? 1 : 0;
    assign prf_eta2     = (sel_alg[2:0] == 3'b111) ? 1 : 0;
    
    wire load_16;
    assign load_16 = sel_alg[3];
    
    wire std_alg;
    wire ext_alg;
    wire ntt_alg;
    wire prf_alg;
    assign std_alg = (sha3_512 | sha3_256 | shake128 | shake256) ? 1 : 0;
    assign ext_alg = !std_alg;
    assign ntt_alg = (ntt_xof) ? 1 : 0;
    assign prf_alg = (prf_eta1_3 | prf_eta1_2 | prf_eta2) ? 1 : 0;
    
    wire [3:0] operation;
    wire reset;
    wire load;
    wire load_length;
    wire start;
    wire read;
    
    assign operation    = control[3:0];
    assign reset        = (operation == 4'b0000) ? 1 : 0; 
    assign load         = (operation == 4'b0001) ? 1 : 0; 
    assign start        = (operation == 4'b0010) ? 1 : 0; 
    assign read         = (operation == 4'b0011) ? 1 : 0; 
    
    assign load_length  = (operation[3] | operation[2]) ? 1 : 0;
    
    localparam KYBER_SYMBYTES                = 32;
    localparam KYBER_SYMBYTES_2              = 64;
    
    localparam KYBER_RANDOMNESS              = 33;
    
    localparam KYBER_PUBLICKEYBYTES_512     = 800;
    localparam KYBER_PUBLICKEYBYTES_768     = 1184;
    localparam KYBER_PUBLICKEYBYTES_1024    = 1568;
    
    localparam KYBER_CIPHERTEXTBYTES_512    = 768 + 32;
    localparam KYBER_CIPHERTEXTBYTES_768    = 1088 + 32;
    localparam KYBER_CIPHERTEXTBYTES_1024   = 1568 + 32;
    
    localparam BLOCK_SIZE_128 = 1344 / 8;
    localparam BLOCK_SIZE_256 = 1088 / 8;
    localparam BLOCK_SIZE_512 = 576 / 8;
    
    reg [63:0] data_length;
    always @* begin
        if(sha3_512) begin
                    if(operation == 4'b0100) data_length = (KYBER_SYMBYTES)               % BLOCK_SIZE_512;
            else    if(operation == 4'b0101) data_length = (KYBER_SYMBYTES_2)             % BLOCK_SIZE_512;
            else    if(operation == 4'b0110) data_length = (KYBER_PUBLICKEYBYTES_512)     % BLOCK_SIZE_512;
            else    if(operation == 4'b0111) data_length = (KYBER_PUBLICKEYBYTES_768)     % BLOCK_SIZE_512;
            else    if(operation == 4'b1000) data_length = (KYBER_PUBLICKEYBYTES_1024)    % BLOCK_SIZE_512;
            else    if(operation == 4'b1001) data_length = (KYBER_CIPHERTEXTBYTES_512)    % BLOCK_SIZE_512;
            else    if(operation == 4'b1010) data_length = (KYBER_CIPHERTEXTBYTES_768)    % BLOCK_SIZE_512;
            else    if(operation == 4'b1011) data_length = (KYBER_CIPHERTEXTBYTES_1024)   % BLOCK_SIZE_512;
            else    if(operation == 4'b1100) data_length = (KYBER_RANDOMNESS)             % BLOCK_SIZE_512;
            else                             data_length = 0;
        end
        else if(sha3_256 | shake256) begin
                    if(operation == 4'b0100) data_length = (KYBER_SYMBYTES)               % BLOCK_SIZE_256;
            else    if(operation == 4'b0101) data_length = (KYBER_SYMBYTES_2)             % BLOCK_SIZE_256;
            else    if(operation == 4'b0110) data_length = (KYBER_PUBLICKEYBYTES_512)     % BLOCK_SIZE_256;
            else    if(operation == 4'b0111) data_length = (KYBER_PUBLICKEYBYTES_768)     % BLOCK_SIZE_256;
            else    if(operation == 4'b1000) data_length = (KYBER_PUBLICKEYBYTES_1024)    % BLOCK_SIZE_256;
            else    if(operation == 4'b1001) data_length = (KYBER_CIPHERTEXTBYTES_512)    % BLOCK_SIZE_256;
            else    if(operation == 4'b1010) data_length = (KYBER_CIPHERTEXTBYTES_768)    % BLOCK_SIZE_256;
            else    if(operation == 4'b1011) data_length = (KYBER_CIPHERTEXTBYTES_1024)   % BLOCK_SIZE_256;
            else    if(operation == 4'b1100) data_length = (KYBER_RANDOMNESS)             % BLOCK_SIZE_256;
            else                             data_length = 0;
        end
        else if(shake128) begin
                    if(operation == 4'b0100) data_length = (KYBER_SYMBYTES)               % BLOCK_SIZE_128;
            else    if(operation == 4'b0101) data_length = (KYBER_SYMBYTES_2)             % BLOCK_SIZE_128;
            else    if(operation == 4'b0110) data_length = (KYBER_PUBLICKEYBYTES_512)     % BLOCK_SIZE_128;
            else    if(operation == 4'b0111) data_length = (KYBER_PUBLICKEYBYTES_768)     % BLOCK_SIZE_128;
            else    if(operation == 4'b1000) data_length = (KYBER_PUBLICKEYBYTES_1024)    % BLOCK_SIZE_128;
            else    if(operation == 4'b1001) data_length = (KYBER_CIPHERTEXTBYTES_512)    % BLOCK_SIZE_128;
            else    if(operation == 4'b1010) data_length = (KYBER_CIPHERTEXTBYTES_768)    % BLOCK_SIZE_128;
            else    if(operation == 4'b1011) data_length = (KYBER_CIPHERTEXTBYTES_1024)   % BLOCK_SIZE_128;
            else    if(operation == 4'b1100) data_length = (KYBER_RANDOMNESS)             % BLOCK_SIZE_128;
            else                             data_length = 0;
        end
        else 
            data_length = 0;
    end
    
    // ---- Add signals --- //
    wire [7:0] add_xof_prf;
    wire [7:0] ctl_xof_prf;
    
    // ---- Data signals ---- //
    
    reg     [15:0]      REG_DATA_IN [3:0];
    wire    [63:0]      REG_IN;
    
    always @(posedge clk) begin
        if(!(rst & !reset) & !load_seed) begin 
            REG_DATA_IN[0]          <= 0;
            REG_DATA_IN[1]          <= 0;
            REG_DATA_IN[2]          <= 0;
            REG_DATA_IN[3]          <= 0;
        end 
        else begin
            if(load_seed) begin 
                        if(add[7:2] < 4)                    REG_DATA_IN[add[1:0]]   <= data_in;
                else    if(add[7:2] == 4 & add[1:0] == 0)   REG_DATA_IN[add[1:0]]   <= {{4'h00,y},{4'h00,x}};
                else                                        REG_DATA_IN[add[1:0]]   <= 16'h0000;
            end 
            else if (load_16) begin
                        REG_DATA_IN[add[1:0]]   <= data_in;
            end
            else if(load) begin
                if(!add[0])                 REG_DATA_IN[add[2:1]]   <= {8'h00, data_in[7:0]};
                else                        REG_DATA_IN[add[2:1]]   <= {data_in[7:0], REG_DATA_IN[add[2:1]][7:0]};
            end                  
            else                            begin 
            REG_DATA_IN[0]          <= REG_DATA_IN[0];
            REG_DATA_IN[1]          <= REG_DATA_IN[1];
            REG_DATA_IN[2]          <= REG_DATA_IN[2];
            REG_DATA_IN[3]          <= REG_DATA_IN[3];
            end 
        end
    end
    
    genvar i;
    generate 
        for(i = 0; i < 4; i = i + 1) begin
            assign REG_IN[(16*(i+1) - 1):(16*i)] = REG_DATA_IN[i];
        end
    endgenerate
    
    wire [63:0] data_in_xof_prf;
    
    RAM #(.SIZE(25) ,.WIDTH(64))
    REG_IN_XOF_PRF 
    (.clk(clk), .en_write(load_seed), .en_read(1), 
    .addr_write({2'b00,add[7:2]}), .addr_read(add_xof_prf),
    .data_in(REG_IN), .data_out(data_in_xof_prf));
    
    // ---- SHA-3 definition ---- //
    wire    [63:0]  data_in_sha3;
    reg     [63:0]  data_in_sha3_reg;
    reg     [7:0]   add_sha3;
    reg     [7:0]   control_sha3;
    wire    [63:0]  data_out_sha3;
    wire            end_op_sha3;
    
    // assign data_in_sha3 = (load_seed & std_alg) ? REG_IN : data_in_sha3_reg;
    
    sha3_shake_keccak #(
    .COUNTER(COUNTER)
    )
    sha3_shake_keccak
    (
    .i_clk(clk),
    .i_rst(rst & !reset),                // rst & !reset
    .i_data_in(data_in_sha3),
    .i_add(add_sha3),
    .i_control(control_sha3),
    .o_data_out(data_out_sha3),
    .o_end_op(end_op_sha3)
    );
    
    always @(posedge clk) begin
        if(std_alg) begin
            if(load_length) data_in_sha3_reg <= data_length;
            else            data_in_sha3_reg <= REG_IN;         
        end
        else begin
            if(load_length) begin // load_length
                if(ntt_alg) data_in_sha3_reg <= ((KYBER_SYMBYTES+2)) % BLOCK_SIZE_256;
                else        data_in_sha3_reg <= ((KYBER_SYMBYTES+1)) % BLOCK_SIZE_256;
            end
            else begin
                data_in_sha3_reg <= data_in_xof_prf;
            end
        end
    end
    
    wire [1:0] op;
    wire [1:0] al;
    
    assign op = (start)     ? 2'b11 : ( (load_length)   ?  2'b01 : ( (load)     ? 2'b10 : 2'b00) ); // 00
    assign al = (shake128)  ? 2'b00 : ( (shake256)      ?  2'b01 : ( (sha3_256) ? 2'b10 : 2'b11) );
    
    wire         load_alg;
    wire [15:0]  add_alg;
    
    reg [3:0] seed_add;
    always @(posedge clk) begin
        if(!rst | reset)                                                seed_add <= 0;
        else if(load_length) begin
                    if(operation == 4'b0110 | operation == 4'b1001)     seed_add <= 11;
            else    if(operation == 4'b0111 | operation == 4'b1010)     seed_add <= 8;
            else    if(operation == 4'b1000 | operation == 4'b1011)     seed_add <= 5;
            else    if(operation == 4'b0101)                            seed_add <= 4;
            else                                                        seed_add <= seed_add;
        end
        else                                    seed_add <= seed_add;
    end
    
    assign data_in_sha3 = (load_length) ? data_in_sha3_reg : REG_IN;
    
    always @(posedge clk) begin
        if(!rst | reset)        add_sha3 <= 0;
        else begin
            if(ext_alg) begin
                if(load_alg)    add_sha3 <= add_alg[10:3];
                else            add_sha3 <= {4'b000,add[7:2]}; // add_sha3 <= add_xof_prf;
            end
            else begin
                if(load_seed) begin
                    add_sha3 <= {4'b000,add[7:2]} + seed_add;
                end
                else begin
                    if(load & !load_16)              add_sha3 <= {4'b000,add[7:3]};
                    else                             add_sha3 <= {4'b000,add[7:2]};
                end
            end              
        end
    end
    
    always @* begin
        if(!rst | reset)        control_sha3 <= {al,op}; // 0
        else begin
            if(ext_alg)         control_sha3 <= ctl_xof_prf[3:0];
            else                control_sha3 <= {al,op};
        end
    end
    
    
    // ---- NTT_XOF definition ---- //
    wire                                    load_sample_ntt;
    wire                                    start_sample_ntt;
    wire                                    read_sample_ntt;
    wire [7:0]                              in_sample_ntt;
    wire [7:0]                              add_sample_ntt;
    wire [15:0]                             data_out_sample_ntt;
    wire                                    end_op_sample_ntt;
    
    wire [3:0] ctl_xof;
    assign ctl_xof = ctl_xof_prf[7:4];
    
    wire reset_sample_ntt;
    assign reset_sample_ntt     = (ctl_xof[0])? 1 : 0;
    assign load_sample_ntt      = (ctl_xof[1])? 1 : 0;
    assign start_sample_ntt     = (ctl_xof[2])? 1 : 0;
    assign read_sample_ntt      = (ctl_xof[3])? 1 : 0;
    
    // assign add_sample_ntt = (read_sample_ntt) ? add : add_xof_prf;
    
    wire [15:0]  nblock;
    
    sample_ntt 
    sample_ntt
    (
    .clk(clk),
    .rst(rst & !reset & !reset_sample_ntt),
    .load(load_sample_ntt),
    .start(start_sample_ntt),
    .read(read_sample_ntt),
    .in_shake(in_sample_ntt),
    .add_in(add_alg + nblock),
    .add_out(add),
    .data_out(data_out_sample_ntt),
    .end_op(end_op_sample_ntt)
    );
    
    // ---- CBD_PRF definition ---- //
    wire                                    load_sample_cbd;
    wire                                    start_sample_cbd;
    wire                                    read_sample_cbd;
    wire [7:0]                              in_sample_cbd;
    wire [7:0]                              add_sample_cbd;
    wire [15:0]                             data_out_sample_cbd;
    wire                                    end_op_sample_cbd;
    
    wire [1:0] eta;
    assign eta = (prf_eta1_2 | prf_eta2) ? 2'b10 : 2'b11;
    
    wire reset_sample_cbd;
    assign reset_sample_cbd     = (ctl_xof[0])? 1 : 0;
    assign load_sample_cbd      = (ctl_xof[1])? 1 : 0;
    assign start_sample_cbd     = (ctl_xof[2])? 1 : 0;
    assign read_sample_cbd      = (ctl_xof[3])? 1 : 0;
    
    sample_cbd
    sample_cbd
    (
    .clk(clk),
    .rst(rst & !reset & !reset_sample_cbd),
    .load(load_sample_cbd),
    .start(start_sample_cbd),
    .read(read_sample_cbd),
    .eta(eta),
    .in_shake(in_sample_cbd),
    .add_in(add_alg + nblock),
    .add_out(add),
    .data_out(data_out_sample_cbd),
    .end_op(end_op_sample_cbd)
    );
    
    
    // --- Control module --- //
    wire        end_op_xof_prf;
    
    CONTROL_XOR_PRF_2
    CONTROL_XOR_PRF_2 (
        .clk(clk),
        .rst(rst),
        .control(control),
        .add_alg(add_alg),
        .add_xof_prf(add_xof_prf),
        .nblock(nblock),
        .load_alg(load_alg),
        .ctl_xof_prf(ctl_xof_prf),
        .end_op_sha3(end_op_sha3),
        .end_op_xof_prf(end_op_xof_prf)
    );
    
    
    // --- REG XOF_PRF --- //
    /*
    reg [63:0] REG_XOF_PRF [83:0];
    wire [64*86-1:0] DATA_XOF_PRF;
    generate 
        for(i = 0; i < 84; i = i + 1) begin
            assign DATA_XOF_PRF[(64*(i+1) - 1):(64*i)] = REG_XOF_PRF[i];
        end
    endgenerate
    
    always @(posedge clk) begin
        if(!rst) REG_XOF_PRF[0] <= 0;
        else begin
            if(load_alg) REG_XOF_PRF[add_alg + nblock] <= data_out_sha3;
            else  REG_XOF_PRF[0] <= REG_XOF_PRF[0];           
        end
    end
    */
    assign in_sample_ntt = data_out_sha3 >> (8 * add_alg[2:0]);
    assign in_sample_cbd = data_out_sha3 >> (8 * add_alg[2:0]);
    
    // --- out signals --- //
    wire [15:0] out_sha3 [3:0];
    generate 
        for(i = 0; i < 4; i = i + 1) begin
            assign out_sha3[i] = data_out_sha3[(16*(i+1) - 1):(16*i)];
        end
    endgenerate
    
    assign end_op_xof_prf = ( (ntt_alg) ? end_op_sample_ntt : end_op_sample_cbd);
    
    assign data_out = (std_alg) ? (out_sha3[add[1:0]]) : ( (ntt_alg) ? data_out_sample_ntt : data_out_sample_cbd);
    assign end_op   = (std_alg) ? (end_op_sha3) : end_op_xof_prf;
    
    
endmodule

module sample_ntt #(
    parameter Q = 3329,
    parameter RATE_SHAKE_128 = 168
    )(
    input   clk,
    input   rst,
    input   load,
    input   start,
    input   read,
    input   [7:0]           in_shake,
    input   [15:0]          add_in,
    input   [7:0]           add_out,     
    output  [15:0]          data_out,
    output                  end_op
    );
    
    
    reg end_op_reg;
    
    wire ns;
    reg [1:0] control_cycle;
    
    assign ns = control_cycle[0];
    
    always @(posedge clk) begin
        if(!rst)    control_cycle <= 0;
        else        control_cycle <= control_cycle + 1;
    end
   
    
    // --- RAM Memories --- //
    wire [7:0]  add_ram_out_1;
    wire [7:0]  add_ram_out_2;
    wire cond_1;
    wire cond_2;
    wire [15:0] d1;
    wire [15:0] d2;
    wire [15:0] dou_ram_out;
   
    
    RAM_dual_write #(.SIZE(256) ,.WIDTH(16))
    REG_OUT 
    (.clk(clk), .enable_1(start & cond_1 & !end_op_reg), .enable_2(start & cond_2 & !end_op_reg), 
    .addr_1(add_ram_out_1), .addr_2(add_ram_out_2),
    .data_in_1(d1), .data_in_2(d2),
    .data_out_1(dou_ram_out), .data_out_2());

    
    // --- RAM IN Mem --- //
    wire [15:0]  add_w_ram_in_0;
    wire [15:0]  add_r_ram_in_0;
    wire [7:0] din_ram_in_0;
    wire [7:0] dou_ram_in_0;
    
    RAM #(.SIZE(4*RATE_SHAKE_128) ,.WIDTH(8))
    REG_IN_0 
    (.clk(clk), .en_write(load), .en_read(1), 
    .addr_write(add_w_ram_in_0), .addr_read(add_r_ram_in_0),
    .data_in(din_ram_in_0), .data_out(dou_ram_in_0));
    
    wire [15:0]  add_w_ram_in_1;
    wire [15:0]  add_r_ram_in_1;
    wire [7:0] din_ram_in_1;
    wire [7:0] dou_ram_in_1;
    
    RAM #(.SIZE(4*RATE_SHAKE_128) ,.WIDTH(8))
    REG_IN_1 
    (.clk(clk), .en_write(load), .en_read(1), 
    .addr_write(add_w_ram_in_1), .addr_read(add_r_ram_in_1),
    .data_in(din_ram_in_1), .data_out(dou_ram_in_1));
    
    wire [15:0]  add_w_ram_in_2;
    wire [15:0]  add_r_ram_in_2;
    wire [7:0] din_ram_in_2;
    wire [7:0] dou_ram_in_2;
    
    RAM #(.SIZE(4*RATE_SHAKE_128) ,.WIDTH(8))
    REG_IN_2 
    (.clk(clk), .en_write(load), .en_read(1), 
    .addr_write(add_w_ram_in_2), .addr_read(add_r_ram_in_2),
    .data_in(din_ram_in_2), .data_out(dou_ram_in_2));
    
    assign add_w_ram_in_0 = add_in;
    assign add_w_ram_in_1 = add_in;
    assign add_w_ram_in_2 = add_in;
    
    // wire [7:0] desp;
    // assign desp = in_shake >> (add_in*8);
    assign din_ram_in_0 = in_shake;
    assign din_ram_in_1 = in_shake;
    assign din_ram_in_2 = in_shake;
    
    assign data_out = dou_ram_out;

    
    reg [15:0] pos;
    reg [7:0] j;
    
    assign add_ram_out_1    = (read) ? add_out : j;
    assign add_ram_out_2    = (cond_2 & cond_1) ? (j+1) : j;
    
    assign add_r_ram_in_0 = pos + 0;
    assign add_r_ram_in_1 = pos + 1;
    assign add_r_ram_in_2 = pos + 2;
    
    
    always @(posedge clk) begin
        if(!rst) pos <= 0;
        else begin
            if(start & !end_op_reg & ns)                pos <= pos + 3;
            else if(read)                               pos <= 0;
            else                                        pos <= pos; 
        end
    end
    
    assign end_op = end_op_reg;
    
    wire cond_OR;
    wire cond_XOR;
    wire cond_AND;
    assign cond_OR  = cond_1 | cond_2;
    assign cond_XOR = cond_1 ^ cond_2;
    assign cond_AND = cond_1 & cond_2;
    
    always @(posedge clk) begin
        if(!rst)                                                    end_op_reg <= 0;
        else begin
            if(ns) begin
                if(load)                                                end_op_reg <= 0;
                else if(start & j == 254 & cond_AND == 1)    end_op_reg <= 1;
                else if(start & j == 255 & cond_OR == 1)     end_op_reg <= 1;
                else                                                    end_op_reg <= 0;
            end
            else                                                        end_op_reg <= end_op_reg;
        end
    end
 
    always @(posedge clk) begin
        if(!rst)                                j <= 0;
        else begin
            if(start & !end_op_reg) begin 
                if(j <= 255 & ns) begin
                    if(cond_1 ^ cond_2)         j <= j + 1;
                    else if(cond_1 & cond_2)    j <= j + 2;
                    else                        j <= j;
                end   
                else                            j <= j;
            end
            else if(load | read)                j <= 0;
            else                                j <= j;          
        end
    end
    
    assign d1 = ((dou_ram_in_0 >> 0) + (dou_ram_in_1 << 8)) & 16'h0FFF;
    assign d2 = ((dou_ram_in_1 >> 4) + (dou_ram_in_2 << 4)) & 16'h0FFF;
    
    assign cond_1 = (d1 < Q) ? 1 : 0;
    assign cond_2 = (d2 < Q) ? ( ((j > 254) & cond_1) ? 0 : 1 ) : 0;

endmodule

module sample_cbd #(
    parameter Q = 3329,
    parameter RATE_SHAKE_256 = 136,
    parameter ETA_MAX = 3
    )(
    input   clk,
    input   rst,
    input   load,
    input   start,
    input   read,
    input   [1:0]           eta,
    input   [7:0]           in_shake,
    input   [15:0]          add_in,
    input   [7:0]           add_out,
    output  [15:0]          data_out,
    output                  end_op
    );
    
    
    // --- RAM IN Mem --- //
    wire [15:0]  add_w_ram_in;
    wire [15:0]  add_r_ram_in;
    wire [7:0] din_ram_in;
    wire [7:0] dout;
    
    RAM #(.SIZE(3*136) ,.WIDTH(8))
    REG_IN 
    (.clk(clk), .en_write(load), .en_read(1), 
    .addr_write(add_w_ram_in), .addr_read(add_r_ram_in),
    .data_in(in_shake), .data_out(dout));
    
    assign add_w_ram_in = add_in;
    
    wire ns;
    reg [1:0] control_cycle;
    
    assign ns = control_cycle[0];
    
    always @(posedge clk) begin
        if(!rst)    control_cycle <= 0;
        else        control_cycle <= control_cycle + 1;
    end
    
    wire [7:0]  add_w_ram;
    wire [7:0]  add_r_ram;
    wire [15:0] din_ram;
    wire [15:0] dou_ram;
    wire en_wr;
    
    RAM #(.SIZE(256) ,.WIDTH(16))
    REG_OUT 
    (.clk(clk), .en_write(en_wr), .en_read(1), 
    .addr_write(add_w_ram), .addr_read(add_r_ram),
    .data_in(din_ram), .data_out(dou_ram));
    
    assign data_out = dou_ram;
    
    reg end_op_reg;
    reg [7:0] i;
    wire [15:0] value_d;
    wire [15:0] value_br;
    wire last; 
    reg [7:0] counter_last;
    reg [1:0] pipe_reg;
    
    assign add_w_ram    = (last) ? counter_last : i;
    assign add_r_ram    = (read) ? add_out : ( last ? counter_last : i);
    assign din_ram      = (last) ? value_br : value_d;
    assign en_wr        = (last) ? (pipe_reg == 2'b10) : start;
    
    assign last = end_op_reg;

    reg [1:0] op;
    reg [3:0] counter;
    
    always @(posedge clk) begin
        if(!rst) counter <= 0;
        else begin
            if(start & !end_op_reg) begin 
                if(op == 0 & ns)            counter <= counter + 1;
                else if(op == 1 & ns)       counter <= 0;
                else if(op == 2 & ns)       counter <= counter + 1; 
                else if(op == 3)            counter <= 0; 
                else                        counter <= counter;
            end
            else if(load | read)    counter <= 0;
            else                    counter <= counter;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst) op <= 0;
        else begin
            if(start & !end_op_reg) begin 
                        if(op == 0 & ns & counter == 4'b0010)   op <= 1; // load data reg_in
                else    if(op == 1 & ns)                        op <= 2; // ciclo estabilizacion
                else    if(op == 2 & ns) begin
                                    if(eta == 2'b11 & counter == 4'b0010)       op <= 3;
                            else    if(eta == 2'b10 & counter == 4'b0100)       op <= 3;
                            else                                                op <= op;
                end
                else    if(op == 3)                                             op <= 0; // Update add
            end
            else if(load | read)    op <= 0;
            else                    op <= op;          
        end
    end
    
    reg [15:0] add_op_reg;
    assign add_r_ram_in = add_op_reg;
    
    always @(posedge clk) begin
        if(!rst)            add_op_reg <= 0;
        else begin
            if(ns & start & !end_op_reg) begin 
                if(op == 0)                         add_op_reg <= add_op_reg + 1;
                else                                add_op_reg <= add_op_reg;
            end
            else if(load | read)    add_op_reg <= 0;
            else                    add_op_reg <= add_op_reg;          
        end
    end
    
    
    always @(posedge clk) begin
        if(!rst) i <= 0;
        else begin
            if(start & !end_op_reg) begin 
                if(i <= 255 & !ns & (op == 2'b10 | op == 2'b11))           i <= i + 1;
                else                                                                    i <= i;
            end
            else if(load | read)    i <= 0;
            else                    i <= i;          
        end
    end
    
    reg end_op_last;
    
    assign end_op = end_op_reg & end_op_last;
  
    always @(posedge clk) begin
        if(!rst)                        end_op_reg <= 0;
        else begin
            if(load)                            end_op_reg <= 0;
            else if(start & i == 255 & !ns)     end_op_reg <= 1;
            else                                end_op_reg <= end_op_reg;
        
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                    end_op_last <= 0;
        else begin
            if(load)                                                    end_op_last <= 0;
            else if(start & counter_last == 255 & pipe_reg == 2'b10)    end_op_last <= 1;
            else                                                        end_op_last <= end_op_last;
        
        end
    end
    
    
    
    always @(posedge clk) begin
        if(!rst)                                                        counter_last <= 0;
        else begin
            if(load)                                                    counter_last <= 0;
            else if(end_op_reg & !end_op_last & pipe_reg == 2'b10)      counter_last <= counter_last + 1;
            else                                                        counter_last <= counter_last;
        
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                                        pipe_reg <= 0;
        else begin
            if(load)                                                    pipe_reg <= 0;
            else if(end_op_reg & !end_op_last & pipe_reg < 2'b10)       pipe_reg <= pipe_reg + 1;
            else                                                        pipe_reg <= 0;
        
        end
    end
    
    wire [31:0] x;
    wire [31:0] y;
    
    wire [23:0] reg_in;
    /*
    always @(posedge clk) begin
        if(!rst) reg_in <= 0;
        else begin
            if((op == 0 | op == 1)) begin
                case(counter[1:0])
                    2'b00: reg_in       <= (reg_in & 24'hFFFF00) + (dout << 0);
                    2'b01: reg_in       <= (reg_in & 24'hFF00FF) + (dout << 8);
                    2'b10: reg_in       <= (reg_in & 24'h00FFFF) + (dout << 16);
                    default: reg_in     <= reg_in;
                endcase            
            end            
            else    if(op == 2 & ns) begin
                        if(eta == 2'b11)    reg_in <= reg_in >> 6;
                        else                reg_in <= reg_in >> 4;
            end  
            else                            reg_in <= reg_in;
        end
    end
    */
    REG_IN_MOD 
    REG_IN_MOD (.clk(clk), .rst(rst), .op(op), .counter(counter[1:0]), .ns(ns), .eta(eta),
                .dout(dout), .reg_in_out(reg_in));    
    
    assign x = (eta == 2'b11) ? (reg_in[0] + reg_in[1] + reg_in[2]) : (reg_in[0] + reg_in[1]);
    assign y = (eta == 2'b11) ? (reg_in[3] + reg_in[4] + reg_in[5]) : (reg_in[2] + reg_in[3]);
    
    wire [31:0] a_prev;
    assign a_prev = x - y;
    assign value_d = a_prev;
    // assign value_d = (x - y) % Q;
    
    
    barret_reduce_pipe BR (.clk(clk), .a(dou_ram), .t(value_br));

endmodule

module REG_IN_MOD (
    input clk,
    input rst,
    input [1:0] op,
    input [1:0] counter,
    input ns,
    input [1:0] eta,
    input [7:0] dout,
    output [23:0] reg_in_out
);

    (* keep_hierarchy = "yes" *) reg [23:0] reg_in ;
    assign reg_in_out = reg_in;
    
    wire [23:0] dout_prev;
    assign dout_prev = {16'h0000, dout};
    
    always @(posedge clk) begin
        if(!rst) reg_in <= 0;
        else begin
            if((op == 0 | op == 1)) begin
                case(counter)
                    2'b00: reg_in       <= (reg_in & 24'hFFFF00) + (dout_prev << 0);
                    2'b01: reg_in       <= (reg_in & 24'hFF00FF) + (dout_prev << 8);
                    2'b10: reg_in       <= (reg_in & 24'h00FFFF) + (dout_prev << 16);
                    default: reg_in     <= reg_in;
                endcase            
            end            
            else    if(op == 2 & ns) begin
                        if(eta == 2'b11)    reg_in <= reg_in >> 6;
                        else                reg_in <= reg_in >> 4;
            end  
            else                            reg_in <= reg_in;
        end
    end

endmodule

module CONTROL_XOR_PRF_2 (
        input clk,
        input rst,
        input  [7:0]    control,
        output [15:0]   add_alg,
        output [7:0]    add_xof_prf,
        output [15:0]   nblock,
        output          load_alg,
        output [7:0]    ctl_xof_prf,
        input           end_op_sha3,
        input           end_op_xof_prf
    );
    
    localparam N_BLOCK = 4;
    
    // --- Control Signals --- //
    wire [3:0] sel_alg;
    wire sha3_512;
    wire sha3_256;
    wire shake128;
    wire shake256;
    wire ntt_xof;
    wire prf_eta1_3;
    wire prf_eta1_2;
    wire prf_eta2;
    
    assign sel_alg = control[7:4];
    assign sha3_512     = (sel_alg == 4'b0000) ? 1 : 0;
    assign sha3_256     = (sel_alg == 4'b0001) ? 1 : 0;
    assign shake128     = (sel_alg == 4'b0010) ? 1 : 0;
    assign shake256     = (sel_alg == 4'b0011) ? 1 : 0;
    assign ntt_xof      = (sel_alg == 4'b0100) ? 1 : 0;
    assign prf_eta1_3   = (sel_alg == 4'b0101) ? 1 : 0;
    assign prf_eta1_2   = (sel_alg == 4'b0110) ? 1 : 0;
    assign prf_eta2     = (sel_alg == 4'b0111) ? 1 : 0;
    
    wire std_alg;
    wire ext_alg;
    wire ntt_alg;
    wire prf_alg;
    assign std_alg = (sha3_512 | sha3_256 | shake128 | shake256) ? 1 : 0;
    assign ext_alg = !std_alg;
    assign ntt_alg = (ntt_xof) ? 1 : 0;
    assign prf_alg = (prf_eta1_3 | prf_eta1_2 | prf_eta2) ? 1 : 0;
    
    wire [3:0] operation;
    wire reset;
    wire load;
    wire load_length;
    wire start;
    wire read;
    
    assign operation    = control[3:0];
    assign reset        = (operation == 4'b0000) ? 1 : 0; 
    assign load         = (operation == 4'b0001) ? 1 : 0; 
    assign start        = (operation == 4'b0010) ? 1 : 0; 
    assign read         = (operation == 4'b0011) ? 1 : 0; 
    
    assign load_length  = (operation[3] | operation[2]) ? 1 : 0;
    
    
    // Define states
    reg [3:0] state, next_state;
    parameter IDLE              = 4'h0;
    parameter LOAD_SHA3         = 4'h1;
    parameter START_SHA3        = 4'h2;
    parameter READ_SHA3         = 4'h3;
    parameter START_SHAKE       = 4'h4;
    parameter READ_SHAKE        = 4'h5;
    parameter START_XOF_PRF     = 4'h6;
    parameter END_OP            = 4'h7;
    parameter UPDATE_BLOCK      = 4'h8;
    parameter LOAD_LENGTH       = 4'h9;
    parameter LOAD_XOF_PRF      = 4'hA;
    parameter END_BLOCK         = 4'hB;
    
    // --- Control signals --- //
    wire           ns;
	reg    [1:0]   counter_cycles;
	
	assign ns      = (counter_cycles[0] == 1'b1)   ? 1 : 0;
	always @(posedge clk) begin
	   if(!rst)    counter_cycles <= 0;
	   else        counter_cycles <= counter_cycles + 1;
	end
	
	wire end_load;
	wire end_read;
	
	wire end_block;
	
    reg [15:0]   add_alg_reg;
    reg [7:0]    add_xof_prf_reg;
    reg [15:0]   nblock_add_reg;
    reg [7:0]    nblock_reg;
    reg          load_alg_reg;
    reg [7:0]    ctl_xof_prf_reg;
    
    assign end_load = (add_xof_prf_reg == (25 - 1)) ? 1 : 0;
	assign end_read = (ntt_alg) ? ( (add_alg_reg == (8*21 - 1)) ? 1 : 0 ) :  ( (add_alg_reg == (8*17 - 1)) ? 1 : 0 );
	assign add_alg     = add_alg_reg;
	assign add_xof_prf = add_xof_prf_reg;
	assign nblock      = nblock_add_reg;
	assign load_alg    = load_alg_reg;
	assign ctl_xof_prf = ctl_xof_prf_reg;
	
	assign end_block = (ntt_alg) ? ((nblock_reg == (N_BLOCK - 1)) ? 1 : 0) : 1;
	
    // Synchronous logic
    always @(posedge clk) begin
        if (!rst | reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Combinational logic
    always @* begin
        case (state)
            IDLE: begin
                if (end_op_sha3 & ext_alg & ns) next_state = READ_SHA3;
                else                            next_state = IDLE;
            end
            READ_SHA3: begin
                if (end_read & ns)              next_state = UPDATE_BLOCK;
                else                            next_state = READ_SHA3;
            end
            UPDATE_BLOCK: begin
                if(ns)  next_state = START_SHAKE;
                else    next_state = UPDATE_BLOCK;
            end
            START_SHAKE: begin
                if (end_op_sha3 & ns)   next_state = READ_SHAKE;
                else                    next_state = START_SHAKE;
            end
            READ_SHAKE: begin
                if (end_read & ns)  next_state = END_BLOCK;
                else                next_state = READ_SHAKE;
            end
            END_BLOCK: begin
                if (end_block & ns)         next_state = LOAD_XOF_PRF;
                else if (!end_block & ns)   next_state = UPDATE_BLOCK;
                else                        next_state = END_BLOCK;
            end
            LOAD_XOF_PRF: begin
                if (ns)     next_state = START_XOF_PRF;
                else        next_state = LOAD_XOF_PRF;
            end
            START_XOF_PRF: begin
                if (end_op_xof_prf & ns)    next_state = END_OP;
                else                        next_state = START_XOF_PRF;
            end
            END_OP: begin
                if (reset)  next_state = IDLE;
                else        next_state = END_OP;
            end
        endcase
    end

    // Output logic
    always @(posedge clk) begin
        if(state == IDLE) add_xof_prf_reg <= 0;
        else begin
            if(state == LOAD_SHA3 & ns & !end_load) add_xof_prf_reg <= add_xof_prf_reg + 1;
            else                                    add_xof_prf_reg <= add_xof_prf_reg;
        end
    end
    
    always @(posedge clk) begin
        if( state == IDLE | state == START_SHAKE | state == UPDATE_BLOCK ) 
                                                add_alg_reg <= 0;
        else begin
            if(load_alg_reg & ns & !end_read)   add_alg_reg <= add_alg_reg + 1;
            else                                add_alg_reg <= add_alg_reg;
        end
    end
    
    always @(posedge clk) begin
        if(state == IDLE) nblock_add_reg <= 0;
        else begin
            if(ns & state == UPDATE_BLOCK) nblock_add_reg <= (ntt_alg) ? 21*8*nblock_reg : 17*8*nblock_reg;
            else                      nblock_add_reg <= nblock_add_reg;
        end
    end
    
    always @(posedge clk) begin
        if(state == IDLE) nblock_reg <= 0;
        else begin
            if(!ns & state == UPDATE_BLOCK)  nblock_reg <= nblock_reg + 1;
            else                       nblock_reg <= nblock_reg;
        end
    end
    
    always @(posedge clk) begin
        if(state == IDLE) load_alg_reg <= 0;
        else begin
            if(ns & (state == READ_SHA3 | state == READ_SHAKE))     load_alg_reg <= 1;
            else                                                    load_alg_reg <= load_alg_reg;
        end
    end
    
    wire [1:0] op;
    wire [1:0] al;
    
    assign op = (start)                 ? 2'b11 : ( (load_length)               ?  2'b01 : ( (load)     ? 2'b10 : 2'b00) ); // 00
    assign al = (shake128 | ntt_alg)    ? 2'b00 : ( (shake256 | !ntt_alg)       ?  2'b01 : ( (sha3_256) ? 2'b10 : 2'b11) );
    
    
    // Output assignment
    always @* begin
        case (state)
            IDLE: begin
                if(ntt_alg) ctl_xof_prf_reg = {al,op}; // 0000
                else        ctl_xof_prf_reg = {al,op};
            end
            READ_SHA3: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b0010,4'b0011};
                else        ctl_xof_prf_reg = {4'b0010,4'b0111};
            end
            UPDATE_BLOCK: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b0001,4'b0001};
                else        ctl_xof_prf_reg = {4'b0001,4'b0101};
            end
            START_SHAKE: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b0001,4'b0011};
                else        ctl_xof_prf_reg = {4'b0001,4'b0111};
            end
            READ_SHAKE: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b0010,4'b0011};
                else        ctl_xof_prf_reg = {4'b0010,4'b0111};
            end
            END_BLOCK: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b0001,4'b0011};
                else        ctl_xof_prf_reg = {4'b0001,4'b0111};
            end
            LOAD_XOF_PRF: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b0010,4'b0011};
                else        ctl_xof_prf_reg = {4'b0010,4'b0111};
            end
            START_XOF_PRF: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b0100,4'b0011};
                else        ctl_xof_prf_reg = {4'b0100,4'b0111};
            end
            END_OP: begin
                if(ntt_alg) ctl_xof_prf_reg = {4'b1000,4'b0011};
                else        ctl_xof_prf_reg = {4'b1000,4'b0111};
            end
            default: begin
                if(ntt_alg) ctl_xof_prf_reg = {al,op};
                else        ctl_xof_prf_reg = {al,op};
            end
        endcase
    end
    
endmodule