/**
  * @file sha2_xl.v
  * @brief SHA2 XL Module
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



module sha2_xl (
    input              i_clk,
    input              i_rst,
    input  [7:0]       i_control,
    input  [4:0]       i_add,
    input  [63:0]      i_data_in,
    output  [63:0]     o_data_out,
    output             o_end_op
    );
    
    assign reset        = !(!i_control[1] & !i_control[0]) & i_rst;   // XX00 -> RESET
    assign load_length  =   !i_control[1] &  i_control[0];            // XX01 -> LOAD_LENGTH   
    assign load_data    =    i_control[1] & !i_control[0];            // XX10 -> LOAD_DATA
    assign start        =    i_control[1] &  i_control[0];            // XX11 -> START
    
    assign sha_256      = !i_control[3] & !i_control[2]; // 00XX -> SHA_256
    assign sha_384      = !i_control[3] &  i_control[2]; // 01XX -> SHA_384
    assign sha_512      =  i_control[3] & !i_control[2]; // 10XX -> SHA_512
    assign sha_512_256  =  i_control[3] &  i_control[2]; // 11XX -> SHA_512_256
    
    // IO signals
    reg [63:0] data_out_reg;
    assign o_data_out = (sha_256) ? (data_out_reg & 32'hFFFFFFFF) : data_out_reg;
    
    // SHA2_Core signals
    wire load_sha2;
    wire start_sha2;
    wire end_op_sha2;
    wire [63:0] data_sha2;
    wire [8*64-1:0] H_out;
    
    // Mem Signals
    wire en_w;
    wire en_r;
    wire [4:0] ad_sha2;
    wire [63:0] data_in_pad;
    
    mem_RAM #(.SIZE(32), .WIDTH(64)) 
    mem_RAM (.clk(i_clk), .en_write(en_w), .en_read(en_r), 
             .addr_write(i_add), .addr_read(ad_sha2), .data_in(data_in_pad), .data_out(data_sha2));
             
    // Multiplexer out
    always @(posedge i_clk) begin
        if(!reset) data_out_reg <= 0;
        else begin  
            case(i_add) 
                5'b00000: data_out_reg <= H_out[8*64-1:7*64];
                5'b00001: data_out_reg <= H_out[7*64-1:6*64];
                5'b00010: data_out_reg <= H_out[6*64-1:5*64];
                5'b00011: data_out_reg <= H_out[5*64-1:4*64];
                5'b00100: data_out_reg <= H_out[4*64-1:3*64];
                5'b00101: data_out_reg <= H_out[3*64-1:2*64];
                5'b00110: data_out_reg <= H_out[2*64-1:1*64];
                5'b00111: data_out_reg <= H_out[1*64-1:0*64];
                default:  data_out_reg <= 0;
            endcase
        end
    
    end
    
    sha2_padding  sha2_padding
    (
        .clk(i_clk),
        .rst(i_rst),
        .control(i_control),
        .ad_in(i_add),
        .data_in(i_data_in),
        .data_out(data_in_pad)
    );
    
    wire [3:0] mode;
    assign mode = {sha_512_256, sha_512, sha_384, sha_256};
    
    sha2_core  sha2_core
    (
        .clk(i_clk), 
        .rst(reset),
        .mode(mode),
        .load(load_sha2),
        .start(start_sha2),
        .end_op(end_op_sha2),
        .data_in(data_sha2),
        .H_out(H_out)
    );
    
    control_sha2 control_sha2 (
        .clk(i_clk),
        .rst(i_rst),
        .control(i_control),
        .load_sha2(load_sha2),
        .start_sha2(start_sha2),
        .end_op_sha2(end_op_sha2),
        .ad_sha2(ad_sha2),
        .en_w(en_w),
        .en_r(en_r),
        .end_op(o_end_op)
    );
    

endmodule

module control_sha2 (
    input clk,
    input rst,
    input [3:0] control,
    output load_sha2,
    output start_sha2,
    input end_op_sha2,
    output end_op,
    output en_w,
    output en_r,
    output [4:0] ad_sha2
);

    reg reg_end_op;     assign end_op = reg_end_op;
    reg reg_en_w;       assign en_w = reg_en_w;
    reg reg_en_r;       assign en_r = reg_en_r;  
    reg reg_load_sha2;  assign load_sha2 = reg_load_sha2;
    reg reg_start_sha2;  assign start_sha2 = reg_start_sha2;
    
    
    reg end_count;

    assign reset        = !(!control[1] & !control[0]) & rst;   // XX00 -> RESET
    assign load_length  =   !control[1] &  control[0];            // XX01 -> LOAD_LENGTH   
    assign load_data    =    control[1] & !control[0];            // XX10 -> LOAD_DATA
    assign start        =    control[1] &  control[0];            // XX11 -> START
    
    assign sha_256      = !control[3] & !control[2]; // 00XX -> SHA_256
    assign sha_384      = !control[3] &  control[2]; // 01XX -> SHA_384
    assign sha_512      =  control[3] & !control[2]; // 10XX -> SHA_512
    assign sha_512_256  =  control[3] &  control[2]; // 11XX -> SHA_512_256
    
    reg [4:0] counter;
    assign ad_sha2 = counter;
    
    //--*** STATE declaration **--//
	localparam LOAD       = 2'b00; // 0
	localparam LOAD_SHA2  = 2'b01; // 0
	localparam START_SHA2 = 2'b10; // 1
	localparam END_OP     = 2'b11;
	
	//--*** STATE register **--//
	reg [1:0] current_state;
	reg [1:0] next_state;
	
	//--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!reset)    
			     current_state <= LOAD;
			else
			     current_state <= next_state;
		end
	
	//--*** STATE Transition **--//
	always @*
		begin
			case (current_state)
				LOAD:
				    if (start)	
						next_state = LOAD_SHA2;
				    else
				        next_state = LOAD;
			    LOAD_SHA2:
					if (end_count)
						next_state = START_SHA2;
					else
						next_state = LOAD_SHA2;
				START_SHA2:
					if (end_op_sha2)
						next_state = END_OP;
					else
						next_state = START_SHA2;
				END_OP:
					if (load_data | load_length)
						next_state = LOAD;
					else
						next_state = END_OP;
			endcase 		
		end 
		
    //--*** STATE Signals **--//
	always @(current_state)
		begin
			case (current_state)
				LOAD:
				    begin
				        reg_end_op      = 0;
                        reg_en_w        = 1;  
                        reg_en_r        = 1; 
                        reg_load_sha2   = 0; 
                        reg_start_sha2  = 0; 
				    end
				LOAD_SHA2:
				    begin
				        reg_end_op      = 0;
                        reg_en_w        = 0;  
                        reg_en_r        = 1; 
                        reg_load_sha2   = 1; 
                        reg_start_sha2  = 0;  
				    end
				START_SHA2:
				    begin
				        reg_end_op      = 0;
                        reg_en_w        = 0;  
                        reg_en_r        = 1;  
                        reg_load_sha2   = 0; 
                        reg_start_sha2  = 1; 
				    end
				END_OP:
				    begin
				        reg_end_op      = 1;
                        reg_en_w        = 0;  
                        reg_en_r        = 1; 
                        reg_load_sha2   = 0; 
                        reg_start_sha2  = 0; 
				    end
			endcase
	   end
	   
	   //--*** STATE Counter **--//
    
	always @(posedge clk) 
		begin
		  if(!reset) begin
		      counter     <= 0;
		  end  
		  else begin
		      if(load_data | load_length) counter <= 0;
		      else begin
                  if(reg_load_sha2) counter <= counter + 1;
                  else              counter <= counter;
              end
              
              if(load_data | load_length) end_count <= 0;
              else begin
                  if(counter == 15) end_count <= 1;
                  else              end_count <= end_count;
              end
              
		  end
		end
	  
endmodule
