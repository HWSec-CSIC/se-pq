/**
  * @file acc.v
  * @brief ACC
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

module acc #(
    parameter WIDTH = 32
    )(
    input           clk,
    input           rst,
    input           load,
    input           read,
    input           end_op_ntt,
    input   [1:0]   mode_acc,
    output          end_op,
    output  [7:0]   ad_ntt,
    input   [7:0]   ad_out,
    input   [15:0]  r_in,
    output  [15:0]  r_out
    );
    
    
    // ---- Control signals ---- //
    wire acc;
    wire first_acc;
    
    assign acc          = mode_acc[1]; // 0 -> NO ACC, 1 -> ACC
    assign first_acc    = !mode_acc[0]; // 0 -> FIRST_ACC, 1 -> NORMAL ACC
    
    // ---- Addresses signals ---- //
    wire [7:0] ad_r_ctl;
    wire [7:0] ad_r;
    wire [7:0] ad_w;
    
    assign ad_ntt   = ad_r;
    assign ad_r     = (read) ? ad_out : ad_r_ctl;
    
    // ---- Enable Signals ---- //
    wire en_write;
    wire en_read;
    
    // ---- Data signals ---- //
    wire [15:0] data_in;
    wire [15:0] data_out;
    wire [15:0] data_BR;
    
    assign r_out = data_out;
    
    assign data_in = (first_acc) ? r_in : ( (red) ? data_BR : (r_in + data_out));
   
    RAM #(.SIZE(256) ,.WIDTH(16))
    RAM 
    (.clk(clk), .en_write(en_write), .en_read(1), 
    .addr_write(ad_w), .addr_read(ad_r),
    .data_in(data_in), .data_out(data_out));
   
    control_acc control_add 
    (   .clk(clk), .rst(rst), .load(load), .acc(acc), .en_write(en_write),
        .end_op_ntt(end_op_ntt), .red(red),
        .ad_r(ad_r_ctl), .ad_w(ad_w), .end_op(end_op));

        
    barret_reduce_pipe barret_reduce(.clk(clk), .a(data_out), .t(data_BR));
  
endmodule

module control_acc (
    input clk,
    input rst,
    input load,
    input acc,
    input end_op_ntt,
    output [7:0] ad_w,
    output [7:0] ad_r,
    output red,
    output end_op,
    output en_write
    );
    
    //--*** STATE declaration **--//
	localparam IDLE            = 3'b000; // 0
	localparam READ_NTT        = 3'b001; // 1
	localparam END_READ        = 3'b010; // 2
	localparam REDUCE          = 3'b101; // 5
	localparam END_OP          = 3'b110; // 6
	
	//--*** STATE register **--//
	reg [2:0] current_state;
	reg [2:0] next_state;
	
	//--*** STATE signals **--//
	assign end_op = (current_state == END_OP) ? 1 : 0;
	
	//--*** STATE assignations **--//
	
	//--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst)    
			     current_state <= IDLE;
			else
			     current_state <= next_state;
		end
		
    reg update_done;
    always @(posedge clk) begin
        if(!rst)                                    update_done <= 0;
        else if (current_state == END_READ)         update_done <= 1;
        else                                        update_done <= 0;
    end
    
    reg end_counter;
    reg red_reg;
    reg en_wr;
    reg ns;
    reg [1:0] pipe;
    
    assign red      = red_reg;
    assign en_write = (red) ? (en_wr & pipe == 2'b10) : (en_wr & ns);
		
	//--*** STATE Transition **--//
	always @*
		begin
			case (current_state)
				IDLE:
				    if (end_op_ntt & acc)	
						next_state = READ_NTT;
				    else
				        next_state = IDLE;
			    READ_NTT:
					if (end_counter)
						next_state = END_READ;
					else
						next_state = READ_NTT;
				END_READ:
				    if (update_done)
						next_state = REDUCE;
					else
						next_state = END_READ;
				REDUCE:
				    if (end_counter & pipe == 2'b10)
						next_state = END_OP;
					else
						next_state = REDUCE;
				END_OP:
					if (load)
						next_state = IDLE;
					else
						next_state = END_OP;
				default:
					next_state = IDLE;
			endcase 		
		end 
	
	//--*** STATE Signals **--//
	always @( current_state)
		begin
			case (current_state)
				IDLE:
				    begin
				        en_wr   = 0;
				        red_reg = 0;
				    end
				READ_NTT:
				    begin
				        en_wr   = 1;
				        red_reg = 0;
				    end
				END_READ:
				    begin
				        en_wr   = 0;
				        red_reg = 0;
				    end
				REDUCE:
				    begin
				        en_wr   = 1;
				        red_reg = 1;
				    end
				END_OP:
				    begin
				        en_wr   = 0;
				        red_reg = 0;
				    end
				default:
				    begin
				        en_wr   = 0;
				        red_reg = 0;
				    end
			endcase
	   end
    
    reg [7:0] counter;
    
    assign ad_w     = counter;
    assign ad_r     = counter;
    
    always @(posedge clk) begin
        if(!rst | load) ns <= 0;
        else            ns <= ns + 1;
    end
    
    always @(posedge clk) begin
        if(!rst | load) pipe <= 0;
        else begin
            if(current_state == REDUCE & pipe < 2'b10)  pipe <= pipe + 1;
            else                                        pipe <= 0;
        end     
    end
    
    always @(posedge clk) begin
		  if(!rst)                                                          counter <= 0;  
		  else begin
		      if( current_state == IDLE | 
		          current_state == END_READ)                                   counter <= 0;
              else if (current_state == READ_NTT    & ns)                      counter <= counter + 1;
              else if (current_state == REDUCE      & pipe == 2'b10)           counter <= counter + 1;
              else                                                             counter <= counter;
		  end
    end
    
    always @(posedge clk) begin
        if(!rst)                                                end_counter <= 0;
        else begin
            if( current_state == IDLE | 
		          current_state == END_READ)                    end_counter <= 0;
            else begin
                if      (counter == 8'hFF)                      end_counter <= 1;
                else                                            end_counter <= end_counter;
            end
        end
    
    end

endmodule