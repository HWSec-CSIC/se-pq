/**
  * @file  sha2_padding_eddsa.v
  * @brief Padding Data Module
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

module sha2_padding_eddsa #(
    parameter WIDTH = 32,
    parameter MODE = 256
    )(
    input wire                  clk,
    input wire                  rst,
    input wire [3:0]            control,
    input wire [4:0]            ad_in,
    input wire [WIDTH-1:0]      data_in,
    output wire [WIDTH-1:0]     data_out
    );
    
    reg     [2*WIDTH-1:0] LENGTH;
    reg     [2*WIDTH-1:0] LENGTH_BLOCK;
    wire    [2*WIDTH-1:0] LENGTH_CURRENT;
    
    assign LENGTH_CURRENT = LENGTH_BLOCK - (ad_in * WIDTH);
    
    wire reset;
    wire load;
    wire start;
    assign reset    = ~control[0] & rst;
    assign load     =  control[1];
    assign start    =  control[2];
    
    wire load_length;
    assign load_length = control[3];
    
    reg  [WIDTH-1:0]     data_out_reg;
    assign data_out = data_out_reg;
    
    reg save_length;
    reg flag;
    
    always @(posedge clk) begin
        if(!reset) save_length <= 0;
        else begin
            if(start & !flag)       save_length <= 1;
            else if(start & flag)   save_length <= 0;
            else                    save_length <= save_length;
        end
    end
    
    always @(posedge clk) begin
        if(!reset) flag <= 0;
        else begin
            if(load)                flag <= 0;
            else if(save_length)    flag <= 1;
            else                    flag <= flag;
        end
    end
    
    generate
        if(MODE == 224 | MODE == 256) begin
            localparam BLOCK_SIZE = 512;
            
            always @(posedge clk) begin
                if(!reset) LENGTH_BLOCK <= 0;
                else begin
                    if(load_length)                         LENGTH_BLOCK <= LENGTH;
                    else if(start & save_length & !flag)    LENGTH_BLOCK <= LENGTH_BLOCK - BLOCK_SIZE;
                    else                                    LENGTH_BLOCK <= LENGTH_BLOCK;
                end
            end
            
            wire [2:0] control_pad;
            assign control_pad[0] = ((LENGTH_BLOCK + 2*WIDTH)   < BLOCK_SIZE) ? 1 : 0;
            assign control_pad[1] = (LENGTH_CURRENT             < WIDTH)      ? 1 : 0;
            assign control_pad[2] = (LENGTH_CURRENT             < 0)          ? 1 : 0; 
            
            wire [2:0] condition;
            assign condition[0] = control_pad[0] & (ad_in == 4'b1110); // OUTPUT LENGTH 1
            assign condition[1] = control_pad[0] & (ad_in == 4'b1111); // OUTPUT LENGTH 2
            assign condition[2] = control_pad[1];
            
            always @* begin
                if      (condition[0]) data_out_reg = LENGTH[2*WIDTH-1:WIDTH];
                else if (condition[1]) data_out_reg = LENGTH[WIDTH-1:0];
                else if (condition[2]) data_out_reg = data_in + (1'b1 << (WIDTH - 1 - LENGTH_CURRENT));
                else                   data_out_reg = data_in;
            end
            
        end
        else if(MODE == 384 | MODE == 512) begin
            localparam BLOCK_SIZE = 1024;

            always @(posedge clk) begin
                if(!reset) LENGTH_BLOCK <= 0;
                else begin
                    if(load_length)                         LENGTH_BLOCK <= LENGTH;
                    else if(start & save_length & !flag)    LENGTH_BLOCK <= LENGTH_BLOCK - BLOCK_SIZE;
                    else                                    LENGTH_BLOCK <= LENGTH_BLOCK;
                end
            end
            
            wire [2:0] control_pad;
            assign control_pad[0] = ((LENGTH_BLOCK + 2*WIDTH)   < BLOCK_SIZE) ? 1 : 0;
            assign control_pad[1] = (LENGTH_CURRENT             < WIDTH)      ? 1 : 0;
            assign control_pad[2] = (LENGTH_CURRENT             < 0)          ? 1 : 0; 
            
            wire [2:0] condition;
            assign condition[0] = control_pad[0] & (ad_in == 4'b1110); // OUTPUT LENGTH 1
            assign condition[1] = control_pad[0] & (ad_in == 4'b1111); // OUTPUT LENGTH 2
            assign condition[2] = control_pad[1];
            
            always @* begin
                if      (condition[0]) data_out_reg = LENGTH[2*WIDTH-1:WIDTH];
                else if (condition[1]) data_out_reg = LENGTH[WIDTH-1:0];
                else if (condition[2]) data_out_reg = data_in + (1'b1 << (WIDTH - 1 - LENGTH_CURRENT));
                else                   data_out_reg = data_in;
            end
            
        end
        else begin
            localparam BLOCK_SIZE = 512;
            
            always @(posedge clk) begin
                if(!reset) LENGTH_BLOCK <= 0;
                else begin
                    if(load_length)                         LENGTH_BLOCK <= LENGTH;
                    else if(start & save_length & !flag)    LENGTH_BLOCK <= LENGTH_BLOCK - BLOCK_SIZE;
                    else                                    LENGTH_BLOCK <= LENGTH_BLOCK;
                end
            end
            
            wire [2:0] control_pad;
            assign control_pad[0] = ((LENGTH_BLOCK + 2*WIDTH)   < BLOCK_SIZE) ? 1 : 0;
            assign control_pad[1] = (LENGTH_CURRENT             < WIDTH)      ? 1 : 0;
            assign control_pad[2] = (LENGTH_CURRENT             < 0)          ? 1 : 0; 
            
            wire [2:0] condition;
            assign condition[0] = control_pad[0] & (ad_in == 4'b1110); // OUTPUT LENGTH 1
            assign condition[1] = control_pad[0] & (ad_in == 4'b1111); // OUTPUT LENGTH 2
            assign condition[2] = control_pad[1];
            
            always @* begin
                if      (condition[0]) data_out_reg = LENGTH[2*WIDTH-1:WIDTH];
                else if (condition[1]) data_out_reg = LENGTH[WIDTH-1:0];
                else if (condition[2]) data_out_reg = data_in + (1'b1 << (WIDTH - 1 - LENGTH_CURRENT));
                else                   data_out_reg = data_in;
            end            
        end
  
    endgenerate
    
    always @(posedge clk) begin
        if(!reset)              LENGTH <= 0;
        else begin
            if(load_length & ad_in[0])         LENGTH[WIDTH-1:0]       <= data_in;
            else if(load_length & !ad_in[0])   LENGTH[2*WIDTH-1:WIDTH] <= data_in;
            else                               LENGTH                  <= LENGTH;
        end
    end
    
    
endmodule
