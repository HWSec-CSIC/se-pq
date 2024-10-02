/**
  * @file sha2_xl_eddsa.v
  * @brief SHA2 XL EDDSA Module
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


module sha2_xl_eddsa#(
    parameter WIDTH = 64,
    parameter MODE  = 512,
    parameter T = 256,
    parameter OUTPUT_SIZE = MODE
    )(
    input wire                   i_clk,
    input wire                   i_rst,
    input wire  [3:0]            i_control,
    input wire  [4:0]            i_add,
    input wire [WIDTH-1:0]      i_data_in,
    output wire [WIDTH-1:0]     o_data_out,
    output wire                 o_end_op
    );
    
    // IO signals
    wire reset = ~i_control[0] & i_rst;
    reg [WIDTH-1:0] data_out_reg;
    assign o_data_out = data_out_reg;
    
    // SHA2_Core signals
    wire load_sha2;
    wire start_sha2;
    wire end_op_sha2;
    wire [WIDTH-1:0] data_sha2;
    wire [8*WIDTH-1:0] H_out;
    
    // Mem Signals
    wire en_w;
    wire en_r;
    wire [4:0] ad_sha2;
    wire [WIDTH-1:0] data_in_pad;
    
    mem_RAM_eddsa #(.SIZE(32), .WIDTH(WIDTH)) 
    mem_RAM_eddsa (.clk(i_clk), .en_write(en_w), .en_read(en_r), 
             .addr_write(i_add), .addr_read(ad_sha2), .data_in(data_in_pad), .data_out(data_sha2));
             
    // Multiplexer out
    always @(posedge i_clk) begin
        if(!i_rst) data_out_reg <= 0;
        else begin  
            case(i_add) 
                5'b00000: data_out_reg <= H_out[8*WIDTH-1:7*WIDTH];
                5'b00001: data_out_reg <= H_out[7*WIDTH-1:6*WIDTH];
                5'b00010: data_out_reg <= H_out[6*WIDTH-1:5*WIDTH];
                5'b00011: data_out_reg <= H_out[5*WIDTH-1:4*WIDTH];
                5'b00100: data_out_reg <= H_out[4*WIDTH-1:3*WIDTH];
                5'b00101: data_out_reg <= H_out[3*WIDTH-1:2*WIDTH];
                5'b00110: data_out_reg <= H_out[2*WIDTH-1:1*WIDTH];
                5'b00111: data_out_reg <= H_out[1*WIDTH-1:0*WIDTH];
                default:  data_out_reg <= 0;
            endcase
        end
    
    end
    
    sha2_padding_eddsa #(
    .WIDTH(WIDTH),
    .MODE(MODE)
    ) 
    sha2_padding_eddsa
    (
        .clk(i_clk),
        .rst(i_rst),
        .control(i_control),
        .ad_in(i_add),
        .data_in(i_data_in),
        .data_out(data_in_pad)
    );
    
    sha2_core_eddsa  #(
    .WIDTH(WIDTH),
    .MODE(MODE),
    .T(T),
    .OUTPUT_SIZE(OUTPUT_SIZE)
    ) 
    sha2_core_eddsa
    (
        .clk(i_clk), 
        .rst(reset),
        .load(load_sha2),
        .start(start_sha2),
        .end_op(end_op_sha2),
        .data_in(data_sha2),
        .H_out(H_out)
    );
    
    control_sha2_eddsa control_sha2_eddsa (
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

module control_sha2_eddsa (
    input wire clk,
    input wire rst,
    input wire [3:0] control,
    output wire load_sha2,
    output wire start_sha2,
    input wire end_op_sha2,
    output wire end_op,
    output wire en_w,
    output wire en_r,
    output wire [4:0] ad_sha2
);

    reg reg_end_op;     assign end_op = reg_end_op;
    reg reg_en_w;       assign en_w = reg_en_w;
    reg reg_en_r;       assign en_r = reg_en_r;  
    reg reg_load_sha2;  assign load_sha2 = reg_load_sha2;
    reg reg_start_sha2;  assign start_sha2 = reg_start_sha2;
    
    
    reg end_count;

    wire load;
    wire start;
    
    assign load = control[1];
    assign start = control[2];
    
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
			if (!rst)    
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
					if (load)
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
		  if(!rst) begin
		      counter     <= 0;
		  end  
		  else begin
		      if(load) counter <= 0;
		      else begin
                  if(reg_load_sha2) counter <= counter + 1;
                  else              counter <= counter;
              end
              
              if(load) end_count <= 0;
              else begin
                  if(counter == 15) end_count <= 1;
                  else              end_count <= end_count;
              end
              
		  end
		end
	  
endmodule
