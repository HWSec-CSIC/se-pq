/**
  * @file ByteDecodeEncode.v
  * @brief Byte Decode Encode module
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


module ByteEncDec (
    input           clk,
    input           rst,
    input   [7:0]   control,
    input   [15:0]  data_in,
    input   [15:0]  add,
    output  [15:0]  data_out,
    output          end_op 
    );
    
    wire [3:0] d;
    assign d = control[7:4];
    
    wire sel_enc_dec        = (control[2] == 1'b0) ? 1 : 0; // sel_enc_dec = 1 : ENC, sel_enc_dec = 0 : DEC,
    wire sel_comp_decomp    = (control[3] == 1'b1) ? 1 : 0; // 0 : no, 1: yes,
    
    wire reset;
    wire load;
    wire start;
    wire read;
    
    assign reset    =   !control[1] & !control[0]; 
    assign load     =   !control[1] &  control[0];        
    assign start    =    control[1] & !control[0];      
    assign read     =    control[1] &  control[0]; 
    
    wire load_16; 
    reg load_16_reg;
    assign load_16 = load_16_reg;
    
    always @(posedge clk) begin
        if(!rst | reset)             load_16_reg <= 0;
        else begin
            if (!sel_enc_dec & read) load_16_reg <= 1;
            else                     load_16_reg <= load_16_reg;
        end
    end    
    
    wire [15:0] data_out_dec;
    wire [7:0] data_out_enc;
    
    assign data_out = (sel_enc_dec) ? {8'h00, data_out_enc} : data_out_dec;
    
    wire end_op_dec;
    wire end_op_enc;
    
    assign end_op = (sel_enc_dec) ? end_op_enc : end_op_dec;
    
    ByteEncode 
    ByteEncode (
        .clk(clk),
        .rst(rst & !reset),
        .load(load),
        .start(start),
        .read(read),
        .sel_comp_decomp(sel_comp_decomp),
        .d(d),
        .data_in(data_in),
        .add(add),
        .data_out(data_out_enc),
        .end_op(end_op_enc)
    );
    
    ByteDecode
    ByteDecode (
        .clk(clk),
        .rst(rst & !reset),
        .load(load),
        .start(start),
        .load_16(load_16),
        .sel_comp_decomp(sel_comp_decomp),
        .d(d),
        .data_in(data_in),
        .add(add),
        .data_out(data_out_dec),
        .end_op(end_op_dec)
    );
    
endmodule

module ByteDecode #(
    parameter Q = 3329
    )(
    input           clk,
    input           rst,
    input           load,
    input           start,
    input           read,
    input           sel_comp_decomp,
    input           load_16,
    input   [3:0]   d,
    input   [15:0]  data_in,
    input   [15:0]  add,
    output  [15:0]  data_out,
    output          end_op
    );
    
    reg    [15:0]     REG_IN;
    // reg     [7:0]       DECO        [384-1:0];
    // reg     [15:0]      RES         [256-1:0];
    
    wire    [15:0] data_deco;
    reg     [15:0] add_deco;
    
    RAM #(.SIZE(384) ,.WIDTH(16))
    RAM_DECO 
    (.clk(clk), .en_write(load), .en_read(1), 
    .addr_write(add), .addr_read(add_deco),
    .data_in(data_in), .data_out(data_deco));
    
    wire    [15:0] data_res;
    reg     [15:0] data_au;
    wire    [15:0] add_reg;
    reg     [7:0]  l;
    reg     [7:0]  add_res;
    reg en_w_res;
    
    always @(posedge clk) add_res <= l;
    
    RAM #(.SIZE(256) ,.WIDTH(16))
    RAM_RES 
    (.clk(clk), .en_write(en_w_res), .en_read(1), 
    .addr_write(add_res), .addr_read(add),
    .data_in(data_au), .data_out(data_res));
    
    reg                 end_op_reg;
    assign  end_op = end_op_reg;
    
    // ---- DECO RAM operation --- //
    reg [3:0] counter;
    reg [1:0] update_deco;
    
    reg [1:0] update_deco_reg;
    always @(posedge clk) update_deco_reg <= update_deco;
    
    always @(posedge clk) begin
        if(!rst) counter <= 0;
        else begin
            if(start & !end_op_reg) begin
                if(update_deco == 2'b00)    counter <= counter + 1;
                else                        counter <= 0;
            end
            else                            counter <= 0;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                            update_deco <= 2'b00;
        else begin
                 if(load_16  & counter == 4'b1111)   update_deco <= 2'b01;
            else if(!load_16 & counter == 4'b0111)   update_deco <= 2'b01; 
            else if(update_deco == 2'b01)           update_deco <= 2'b10;  
            else if(update_deco == 2'b10)           update_deco <= 2'b11;   
            else                                    update_deco <= 2'b00;   
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                            add_deco <= 0;
        else begin
            if(update_deco == 2'b01)        add_deco <= add_deco + 1;   
            else                            add_deco <= add_deco;   
        end
    end
    
    reg [15:0] reg_data_deco;
    always @(posedge clk) begin
        if(!rst)                reg_data_deco <= 0;
        else begin
            if(counter == 0 & add_deco < 384)       reg_data_deco <= data_deco;
            else                                    reg_data_deco <= reg_data_deco >> 1;        
        end
    end
    
    // -- Operation --- //
    
    reg [3:0] j;
    reg en_j;

    always @(posedge clk) begin
        if(!rst) j <= 0;
        else begin
            if(start & !end_op_reg & en_j & update_deco_reg == 2'b00) begin 
                if(j < (d-1))   j <= j + 1;    
                else            j <= 0;
            end
            else if(load)           j <= 0;
            else                    j <= j;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst) l <= 0;
        else begin
            if(start & !end_op_reg & en_j) begin 
                if(l <= 255) begin 
                    if(d == 1)  begin                        
                        if(update_deco_reg == 2'b00)    l <= l + 1;
                        else                            l <= l;
                    end 
                    else begin
                        if(j == (d-1) & update_deco_reg == 2'b00)                       l <= l + 1;
                        else                                                            l <= l;
                    end
                end
                else                            l <= 0;
            end
            else if(load)           l <= 0;
            else                    l <= l;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                            end_op_reg <= 0;
        else begin
            if(load)                                        end_op_reg <= 0;
            else if(start & l == 255 & j == (d-1))          end_op_reg <= 1;
            else                                            end_op_reg <= end_op_reg;
        
        end
    end
    
    always @(posedge clk) begin
        if(!rst | load)                                                         en_j <= 0;
        else begin
                    if(load_16  & add_deco == 1 & update_deco[1] == 1'b0)        en_j <= 1;
            else    if(!load_16 & add_deco == 2 & update_deco[1] == 1'b0)        en_j <= 1;
            else                                                                 en_j <= en_j;               
        end
    end
    
    always @(posedge clk) en_w_res <= en_j & !end_op_reg;
    
    // --- RES RAM operation --- //
    
    always @(posedge clk) begin
        if(!rst) data_au <= 0;
        else begin
            if(start) begin 
                        if(j == 0)                      data_au <= REG_IN[0];
                else    if(update_deco_reg == 2'b00)    data_au <= (REG_IN[0] << j) + data_au;
                else                                    data_au <= data_au;
            end
            else if(load)           data_au <= 0;
            else                    data_au <= data_au;          
        end
    end
    
    assign add_reg = l*d + j;
    
    /*
    always @(posedge clk) begin
        if(!rst) DECO[0] <= 0;
        else begin
            if(load) DECO[add]  <= data_in;
            else     DECO[0]    <= DECO[0];   
        end
    end
    */
    
    reg [15:0] mod;
    always @* begin
                if (d == 1)     mod = 16'h0001;
        else    if (d == 2)     mod = 16'h0003;
        else    if (d == 3)     mod = 16'h0007;
        else    if (d == 4)     mod = 16'h000F;
        else    if (d == 5)     mod = 16'h001F;
        else    if (d == 6)     mod = 16'h003F;
        else    if (d == 7)     mod = 16'h007F;
        else    if (d == 8)     mod = 16'h00FF;
        else    if (d == 9)     mod = 16'h01FF;
        else    if (d == 10)    mod = 16'h03FF;
        else    if (d == 11)    mod = 16'h07FF;
        else    if (d == 12)    mod = 16'h0FFF; // not - standard
        else                    mod = 16'h0001;
    end
    
    wire [15:0] data_out_res;
    assign data_out_res = data_res & mod;
    
    genvar gen_i; 
    generate
        for(gen_i = 0; gen_i < 16; gen_i = gen_i + 1) begin
            if(gen_i == 15) begin
                always @(posedge clk) begin
                    if(!rst | load)                           REG_IN[gen_i] <= 0;
                    else begin
                        if(update_deco_reg == 2'b00)          REG_IN[gen_i] <= reg_data_deco[0];
                        else                                  REG_IN[gen_i] <= REG_IN[gen_i];
                    end
                    
                end
            end
            else begin
                always @(posedge clk) begin
                    if(!rst | load)                     REG_IN[gen_i] <= 0;
                    else begin
                        if(update_deco_reg == 2'b00)    REG_IN[gen_i] <= REG_IN[gen_i+1];
                        else                            REG_IN[gen_i] <= REG_IN[gen_i];
                    end
                end
            end
        end
    endgenerate
    
    wire [15:0] data_out_decomp;
    
    decompress decompress (.d(d), .data_in(data_out_res), .data_out(data_out_decomp));
    
    assign data_out = (sel_comp_decomp) ? data_out_decomp : data_out_res;
    
endmodule

/*
module ByteDecode #(
    parameter Q = 3329
    )(
    input           clk,
    input           rst,
    input           load,
    input           start,
    input           read,
    input           sel_comp_decomp,
    input   [3:0]   d,
    input   [7:0]   data_in,
    input   [15:0]  add,
    output  [15:0]  data_out,
    output          end_op
    );
    
    reg    [15:0]     REG_IN;
    // reg     [7:0]       DECO        [384-1:0];
    // reg     [15:0]      RES         [256-1:0];
    
    wire    [7:0] data_deco;
    reg     [15:0] add_deco;
    
    RAM #(.SIZE(384) ,.WIDTH(8))
    RAM_DECO 
    (.clk(clk), .en_write(load), .en_read(1), 
    .addr_write(add), .addr_read(add_deco),
    .data_in(data_in), .data_out(data_deco));
    
    wire [15:0] data_res;
    reg [15:0] data_au;
    wire [15:0] add_reg;
    reg [7:0] l;
    reg [7:0] add_res;
    reg en_w_res;
    
    always @(posedge clk) add_res <= l;
    
    RAM #(.SIZE(256) ,.WIDTH(16))
    RAM_RES 
    (.clk(clk), .en_write(en_w_res), .en_read(1), 
    .addr_write(add_res), .addr_read(add),
    .data_in(data_au), .data_out(data_res));
    
    reg                 end_op_reg;
    assign  end_op = end_op_reg;
    
    // ---- DECO RAM operation --- //
    reg [2:0] counter;
    reg [1:0] update_deco;
    
    reg [1:0] update_deco_reg;
    always @(posedge clk) update_deco_reg <= update_deco;
    
    always @(posedge clk) begin
        if(!rst) counter <= 0;
        else begin
            if(start & !end_op_reg) begin
                if(update_deco == 2'b00)    counter <= counter + 1;
                else                        counter <= 0;
            end
            else                            counter <= 0;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                            update_deco <= 2'b00;
        else begin
            if(counter == 3'b111)           update_deco <= 2'b01; 
            else if(update_deco == 2'b01)   update_deco <= 2'b10;  
            else if(update_deco == 2'b10)   update_deco <= 2'b11;   
            else                            update_deco <= 2'b00;   
        end
    end
    
    always @(posedge clk) begin
        if(!rst | read) add_deco <= 0;
        else begin
            if(update_deco == 2'b01)        add_deco <= add_deco + 1;   
            else                            add_deco <= add_deco;   
        end
    end
    
    reg [7:0] reg_data_deco;
    always @(posedge clk) begin
        if(!rst)                reg_data_deco <= 0;
        else begin
            if(counter == 0 & add_deco < 384)       reg_data_deco <= data_deco;
            else                                    reg_data_deco <= reg_data_deco >> 1;        
        end
    end
    
    // -- Operation --- //
    
    reg [3:0] j;
    reg en_j;

    always @(posedge clk) begin
        if(!rst) j <= 0;
        else begin
            if(start & !end_op_reg & en_j & update_deco_reg == 2'b00) begin 
                if(j < (d-1))   j <= j + 1;    
                else            j <= 0;
            end
            else if(load | read)    j <= 0;
            else                    j <= j;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst) l <= 0;
        else begin
            if(start & !end_op_reg & en_j) begin 
                if(l <= 255) begin 
                    if(d == 1)  begin                        
                        if(update_deco_reg == 2'b00)    l <= l + 1;
                        else                            l <= l;
                    end 
                    else begin
                        if(j == (d-1) & update_deco_reg == 2'b00)                       l <= l + 1;
                        else                                                            l <= l;
                    end
                end
                else                            l <= 0;
            end
            else if(load | read)    l <= 0;
            else                    l <= l;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                            end_op_reg <= 0;
        else begin
            if(load)                                        end_op_reg <= 0;
            else if(start & l == 255 & j == (d-1))          end_op_reg <= 1;
            else                                            end_op_reg <= end_op_reg;
        
        end
    end
    
    always @(posedge clk) begin
        if(!rst | load | read)                              en_j <= 0;
        else begin
            if(add_deco == 2 & update_deco[1] == 1'b0)      en_j <= 1;
            else                                            en_j <= en_j;               
        end
    end
    
    always @(posedge clk) en_w_res <= en_j & !end_op_reg;
    
    // --- RES RAM operation --- //
    
    always @(posedge clk) begin
        if(!rst) data_au <= 0;
        else begin
            if(start) begin 
                        if(j == 0)                      data_au <= REG_IN[0];
                else    if(update_deco_reg == 2'b00)    data_au <= (REG_IN[0] << j) + data_au;
                else                                    data_au <= data_au;
            end
            else if(load | read)    data_au <= 0;
            else                    data_au <= data_au;          
        end
    end
    
    assign add_reg = l*d + j;
    
    /*
    always @(posedge clk) begin
        if(!rst) DECO[0] <= 0;
        else begin
            if(load) DECO[add]  <= data_in;
            else     DECO[0]    <= DECO[0];   
        end
    end
    */
    
    /*
    reg [15:0] mod;
    always @* begin
                if (d == 1)     mod = 16'h0001;
        else    if (d == 2)     mod = 16'h0003;
        else    if (d == 3)     mod = 16'h0007;
        else    if (d == 4)     mod = 16'h000F;
        else    if (d == 5)     mod = 16'h001F;
        else    if (d == 6)     mod = 16'h003F;
        else    if (d == 7)     mod = 16'h007F;
        else    if (d == 8)     mod = 16'h00FF;
        else    if (d == 9)     mod = 16'h01FF;
        else    if (d == 10)    mod = 16'h03FF;
        else    if (d == 11)    mod = 16'h07FF;
        else    if (d == 12)    mod = 16'h0FFF; // not - standard
        else                    mod = 16'h0001;
    end
    
    wire [15:0] data_out_res;
    assign data_out_res = data_res & mod;
    
    genvar gen_i; 
    generate
        for(gen_i = 0; gen_i < 16; gen_i = gen_i + 1) begin
            if(gen_i == 15) begin
                always @(posedge clk) begin
                    if(!rst | load | read)                    REG_IN[gen_i] <= 0;
                    else begin
                        if(update_deco_reg == 2'b00)          REG_IN[gen_i] <= reg_data_deco[0];
                        else                                  REG_IN[gen_i] <= REG_IN[gen_i];
                    end
                    
                end
            end
            else begin
                always @(posedge clk) begin
                    if(!rst | load | read)              REG_IN[gen_i] <= 0;
                    else begin
                        if(update_deco_reg == 2'b00)    REG_IN[gen_i] <= REG_IN[gen_i+1];
                        else                            REG_IN[gen_i] <= REG_IN[gen_i];
                    end
                end
            end
        end
    endgenerate
    
    wire [15:0] data_out_decomp;
    
    decompress decompress (.d(d), .data_in(data_out_res), .data_out(data_out_decomp));
    
    assign data_out = (sel_comp_decomp) ? data_out_decomp : data_out_res;
    
endmodule
*/

module ByteEncode #(
    parameter Q = 3329
    )(
    input           clk,
    input           rst,
    input           load,
    input           start,
    input           read,
    input           sel_comp_decomp,
    input   [3:0]   d,
    input   [15:0]  data_in,
    input   [15:0]  add,
    output  [7:0]   data_out,
    output          end_op
    );
    
    wire [15:0] data_out_comp;
    
    compress compress (.clk(clk), .d(d), .data_in(data_in), .data_out(data_out_comp));
    //compress_2 compress_2 (.clk(clk), .d(d), .data_in(data_in), .data_out());
    
    reg [7:0] add_pipe;
    always @(posedge clk) add_pipe <= add[7:0];
    
    reg ns;
    
    always @(posedge clk) begin
        if(!rst)    ns <= 0;
        else        ns <= ns + 1;
    end
    
    wire    [15:0] data_wire;
    wire    [15:0] data_deco;
    
    reg [1:0] state; 
    
    reg [7:0]   add_data_au;
    reg [15:0]  add_write_res;
    
    assign data_deco = (sel_comp_decomp) ? data_out_comp : data_in;
    
    RAM #(.SIZE(256) ,.WIDTH(16))
    RAM_DECO 
    (.clk(clk), .en_write(load), .en_read(1), 
    .addr_write(add_pipe), .addr_read(add_data_au),
    .data_in(data_deco), .data_out(data_wire));
    
    reg     [15:0]  data_au;
    reg             en_w_res;
        
    RAM #(.SIZE(32*12) ,.WIDTH(8))
    RAM_RES
    (.clk(clk), .en_write(en_w_res), .en_read(1), 
    .addr_write(add_write_res), .addr_read(add),
    .data_in(RES_B[7:0]), .data_out(data_out));
  
    reg end_op_ini_counter;
    reg end_op_add_au;
    reg end_op_reg;
    
    always @(posedge clk) begin
        if(!rst)                                    state <= 0;
        else begin
             if(state == 2'b00 & start)                 state <= 2'b01; // load_16
        else if(state == 2'b01 & end_op_ini_counter)    state <= 2'b10; // end_16 - start counter
        else if(state == 2'b10 & end_op_reg)            state <= 2'b11;
        else if(state == 2'b11 & read)                  state <= 2'b00;
        else                                            state <= state;
        end 
    
    end

    assign  end_op = end_op_reg;
    
    
    always @* begin
                if(d == 1)  data_au   = data_wire & 16'h0001;
        else    if(d == 2)  data_au   = data_wire & 16'h0003;
        else    if(d == 3)  data_au   = data_wire & 16'h0007;
        else    if(d == 4)  data_au   = data_wire & 16'h000F;
        else    if(d == 5)  data_au   = data_wire & 16'h001F;
        else    if(d == 6)  data_au   = data_wire & 16'h003F;
        else    if(d == 7)  data_au   = data_wire & 16'h007F;
        else    if(d == 8)  data_au   = data_wire & 16'h00FF;
        else    if(d == 9)  data_au   = data_wire & 16'h01FF;
        else    if(d == 10) data_au   = data_wire & 16'h03FF;
        else    if(d == 11) data_au   = data_wire & 16'h07FF;
        else    if(d == 12) data_au   = (data_wire + ({16{data_wire[15]}} & Q)) & 16'h0FFF;
        else                data_au   = data_wire;
    end
    
    
    always @(posedge clk) begin
        if(!rst)                                                            end_op_reg <= 0;
        else begin
            if(load | read)                                                 end_op_reg <= 0;
            else if(state == 2'b10 & add_write_res == 32*12-1 & en_w_res)   end_op_reg <= 1;
            else                                                            end_op_reg <= end_op_reg;
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                            end_op_add_au <= 0;
        else begin
            if(load)                                        end_op_add_au <= 0;
            else if(state == 2'b01 & add_data_au == 255)    end_op_add_au <= 1;
            else                                            end_op_add_au <= 0;
        end
    end
    
    reg        cond_data_au;
    reg [3:0]   counter_in;
    wire        update_data;
    reg [1:0]   counter_update;
    assign update_data  = (counter_update   == 2'b11)   ? 1 : 0;
    
    always @(posedge clk) begin
        if(!rst)                                            cond_data_au <= 0;
        else begin
            if(load)                                        cond_data_au <= 0;
            else if(state == 2'b01 | state == 2'b10) begin 
                if(update_data)                                 cond_data_au <= 0;
                else if(counter_in == (d-1) | counter_in == d)  cond_data_au <= 1;
            end
            else                                            cond_data_au <= 0;
        end
    end

    always @(posedge clk) begin
        if(!rst | state == 2'b00)                       counter_in <= 0;
        else begin
            if((state == 2'b01 | state == 2'b10) & !end_op_add_au) begin 
                        if(counter_in <= (d-1))                 counter_in <= counter_in + 1;
                else    if(update_data)                         counter_in <= 0;
                else                                            counter_in <= counter_in;
            end
            else if(load | read)                counter_in <= 0;
            else                                counter_in <= counter_in;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst | state == 2'b00)                       counter_update <= 0;
        else begin
            if(counter_in == d) counter_update <= counter_update + 1;
            else                counter_update <= 0;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst | state == 2'b00)                       add_data_au <= 0;
        else begin
            if((state == 2'b01 | state == 2'b10) & !end_op_add_au) begin 
                if(add_data_au <= 255 & cond_data_au & counter_update == 0)     add_data_au <= add_data_au + 1;
                else                                                            add_data_au <= add_data_au;
            end
            else if(load | read)                add_data_au <= 0;
            else                                add_data_au <= add_data_au;          
        end
    end
    
    always @(posedge clk) begin
        if(!rst | state == 2'b00) add_write_res <= 0;
        else begin
            if((state == 2'b10 | state == 2'b01) & !end_op_reg) begin 
                if(add_write_res <= 32*12-1 & en_w_res)                     add_write_res <= add_write_res + 1;
                else                                                        add_write_res <= add_write_res;
            end
            else if(load | read)                                            add_write_res <= 0;
            else                                                            add_write_res <= add_write_res;          
        end
    end
    
    reg     [15:0]   RES_B;
    reg     [15:0]   data_in_res;
    reg     [3:0]    ini_counter;
    
    always @(posedge clk) begin
        if(!rst | state == 2'b00)                                       ini_counter <= 0;
        else begin
            if((state == 2'b01 | state == 2'b10) & !cond_data_au)       ini_counter <= ini_counter + 1;
            else                                                        ini_counter <= ini_counter;
        end
    end 
    
    always @(posedge clk) begin
        if(!rst)                                            end_op_ini_counter <= 0;
        else begin
            if(load)                                        end_op_ini_counter <= 0;
            else if(state == 2'b01 & ini_counter == 15)     end_op_ini_counter <= 1;
            else                                            end_op_ini_counter <= 0;
        end
    end
    
    always @(posedge clk) begin
        if(!rst) data_in_res <= 0;
        else begin
            if(state == 2'b00 | counter_in == d)        data_in_res <= data_au;
            else                                        data_in_res <= data_in_res >> 1;
        end
    end 
    
    always @(posedge clk) begin
        if(!rst) en_w_res <= 0;
        else begin
            if(d == 1) begin
                if(state == 2'b10 & !cond_data_au  & ini_counter[2:0]    == 7)       en_w_res <= 1;
                else                                                                 en_w_res <= 0;
            end
            else begin
                if(state == 2'b01         & ini_counter         == 15 & !cond_data_au)      en_w_res <= 1;
                else    if(state == 2'b10 & ini_counter[2:0]    == 7  & !cond_data_au)      en_w_res <= 1;
                else                                                                        en_w_res <= 0;
            end
        end
    end
    
    genvar gen_i; 
    generate
        for(gen_i = 0; gen_i < 16; gen_i = gen_i + 1) begin
            if(gen_i == 15) begin
                always @(posedge clk) begin
                    if(!rst | state == 2'b00)   RES_B[gen_i] <= 0;
                    else begin
                        if(!cond_data_au)       RES_B[gen_i] <= data_in_res[0];
                        else                    RES_B[gen_i] <= RES_B[gen_i];
                    end
                    
                end
            end
            else begin
                always @(posedge clk) begin
                    if(!rst | state == 2'b00)   RES_B[gen_i] <= 0;
                    else begin
                        if(!cond_data_au)       RES_B[gen_i] <= RES_B[gen_i+1];
                        else                    RES_B[gen_i] <= RES_B[gen_i];
                    end
                end
            end
        end
    endgenerate
    

    
endmodule

module compress #(
    parameter Q = 3329,
    parameter Q_2 = Q / 2,
    parameter QINV = 1290167
    )(
    input clk,
    input   [3:0]   d,
    input   [15:0]  data_in,
    output  [15:0]   data_out
);
    wire [15:0] val_1;
    assign val_1 = data_in[15] ? Q : 0; // {16{data_in[15]}}; // data_in >>> 15;
    /*
    wire [15:0] val_1_2;
    assign val_1_2 = {16{data_in[15]}}; // data_in >>> 15;
    wire [15:0] val_2;
    assign val_2 = val_1_2 & Q;
    */
    
    reg [31:0] op_1;
    always @(posedge clk) op_1 <= (((data_in + val_1) & 16'hFFFF ) << d) + Q_2;
    
    wire [63:0] op_2; 
    assign op_2 = (op_1 * QINV) >> 32;
    
    assign data_out = op_2[15:0];
    
    /*
    reg [15:0] mod;
    
    always @* begin
                if(d == 1)  mod   = op_1 << 1;
        else    if(d == 2)  mod   = op_1 << 2;
        else    if(d == 3)  mod   = op_1 << 3;
        else    if(d == 4)  mod   = op_1 << 4;
        else    if(d == 5)  mod   = op_1 << 5;
        else    if(d == 6)  mod   = op_1 << 6;
        else    if(d == 7)  mod   = op_1 << 7;
        else    if(d == 8)  mod   = op_1 << 8;
        else    if(d == 9)  mod   = op_1 << 9;
        else    if(d == 10) mod   = op_1 << 10;
        else    if(d == 11) mod   = op_1 << 11;
        else    if(d == 12) mod   = op_1 << 12;
        else                mod   = op_1 << 12;
    end
    
    assign op_2 = (mod + (Q / 2) ) / Q;
    */
    /*
    wire [15:0] test1;
    assign test1 = Q / 2;
    
    wire [15:0] test2;
    assign test2 = 1 / Q;
    */
    
    /*
    reg [15:0] mod;
    
    always @* begin
                if(d == 1)  mod   = 16'h0001 / Q;
        else    if(d == 2)  mod   = 16'h0003 / Q;
        else    if(d == 3)  mod   = 16'h0007 / Q;
        else    if(d == 4)  mod   = 16'h000F / Q;
        else    if(d == 5)  mod   = 16'h001F / Q;
        else    if(d == 6)  mod   = 16'h003F / Q;
        else    if(d == 7)  mod   = 16'h007F / Q;
        else    if(d == 8)  mod   = 16'h00FF / Q;
        else    if(d == 9)  mod   = 16'h01FF / Q;
        else    if(d == 10) mod   = 16'h03FF / Q;
        else    if(d == 11) mod   = 16'h07FF / Q;
        else    if(d == 12) mod   = 16'hFFFF;
        else                mod   = 16'hFFFF;
    end
    
    assign data_out = data_in * mod;
    */


endmodule


module decompress #(
    parameter Q = 3329
    )(
    input   [3:0]   d,
    input   [15:0]  data_in,
    output  [15:0]   data_out
);  
    assign data_out = ((data_in * Q) + (1 << (d-1))) >> d;


endmodule