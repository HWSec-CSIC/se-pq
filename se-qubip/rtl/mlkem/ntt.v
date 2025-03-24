/**
  * @file ntt.v
  * @brief NTT Module
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



`timescale 1ns / 1ps

module poly_ntt #(
    parameter ZETA_INV = 1441,
    parameter QINV = 62209,
    parameter WIDTH = 32
    )(
    input clk,
    input rst,
    input load,
    input start,
    input read,
    input [2:0] sel,
    output end_op,
    input [7:0] ad_in,
    input [7:0] ad_out,
    input [WIDTH-1:0] r_in,
    output [15:0] r_out
    );
    
    // | SEL  | bin    | Description    |
    // |------|--------|----------------|
    // | 0    | 3'b000 | NTT            |
    // | 1    | 3'b001 | INTT           |
    // | 2    | 3'b010 | MULT           |
    // | 3    | 3'b011 | MULT_ACC       |
    // | 4    | 3'b100 | ADD (A+B)      |
    // | 5    | 3'b101 | SUB (B-A)      |
    
    // ---- Control signals ---- //
    wire ntt;
    wire intt;
    wire mult;
    wire mult_first;
    wire mult_acc;
    wire ops;
    wire add;
    wire sub;
    
    assign ntt          =  !sel[2] & !sel[1] & !sel[0]; 
    assign intt         =  !sel[2] & !sel[1] &  sel[0]; 
    assign mult_first   =  !sel[2] &  sel[1] & !sel[0]; 
    assign mult_acc     =  !sel[2] &  sel[1] &  sel[0]; 
    assign add          =   sel[2] & !sel[1] & !sel[0];
    assign sub          =   sel[2] & !sel[1] &  sel[0];
    assign mult         =   mult_first | mult_acc;
    assign ops          =   add | sub;
    
    // ---- Addresses signals ---- //
    wire [7:0] ad_1, ad_2;
    wire [7:0] ad_rj, ad_rjlen;
    wire [7:0] ad_inout;
    
    assign ad_inout = (load) ?              ad_in : ad_out;
    assign ad_1     = (start & !end_op) ?   ad_rj : ad_inout;
    assign ad_2     = ad_rjlen;
    
    // ---- Data signals ---- //
    wire [WIDTH-1:0] in_rj, in_rjlen;
    wire [WIDTH-1:0] rj, rjlen;
    wire [WIDTH-1:0] rj_out, rjlen_out;
    wire en_w;
        
    wire [6:0] addr_zeta;
    wire [15:0] zeta;
    
    wire [15:0] r_out_prev;
    
    // ---- Modules instantiation ---- //
    
    mem_zetas mem_zetas (.clk(clk), .addr_zeta(addr_zeta), .data_out_zeta(zeta));
    
    
    RAM_dual_write #(.SIZE(256), .WIDTH(WIDTH)) RAM_data
    (.clk(clk), 
    .enable_1(load | en_w),     .enable_2(en_w & !ops & !last), 
    .addr_1(ad_1),              .addr_2(ad_2), 
    .data_in_1(in_rj),          .data_in_2(in_rjlen),
    .data_out_1(rj),            .data_out_2(rjlen));

    NTT_core NTT_core(
    .clk(clk),      .rst(rst),
    .sel(sel),      .pwm_cycle(pwm_cycle),
    .minus_zeta(ad_rj[1]), // 0, no; 2, yes; 4, no; 6, yes
    .rj(rj),            .rjlen(rjlen), 
    .rj_out(rj_out),    .rjlen_out(rjlen_out), 
    .zeta(zeta)
    );
    
    control_ntt control_ntt (
    .rst(rst), .clk(clk), .load(load), .start(start), .sel(sel),
    .en_write(en_w), .pwm_cycle(pwm_cycle), .last(last),
    .addr_zeta(addr_zeta), .ad_rj(ad_rj), .ad_rjlen(ad_rjlen),
    .end_op(end_op));
    
    // ---- Data Asignation ---- //
    wire [15:0] r_out_last;
    assign in_rj            = (load) ? r_in : ( last ? r_out_last : rj_out);
    assign in_rjlen         =  rjlen_out; 
    
    // ---- Out Asignation ---- //
    wire [15:0] r_out_ntt;
    wire [15:0] r_out_invntt;
    assign r_out_prev    = rj[15:0]; 
    
    barret_reduce_pipe barret_reduce(.clk(clk), .a(r_out_prev), .t(r_out_ntt));
    fqmult_zeta fqmult_last (.a(r_out_prev), .t(r_out_invntt));
    
    assign r_out_last = (intt) ? r_out_invntt : r_out_ntt;
    
    assign r_out = rj[15:0]; 
    
    // assign r_out = r_out_last; 
    

endmodule

module control_ntt(
    input rst,
    input clk,
    input load,
    input start,
    input [2:0] sel,
    output en_write,
    output pwm_cycle,
    output last,
    output end_op,
    output [6:0] addr_zeta,
    output [7:0] ad_rj,
    output [7:0] ad_rjlen
);
    // --- control signals --- //
    wire ntt;
    wire intt;
    wire mult;
    wire mult_first;
    wire mult_acc;
    wire ops;
    wire add;
    wire sub;
    wire non_ntt;
    
    assign ntt          =  !sel[2] & !sel[1] & !sel[0]; 
    assign intt         =  !sel[2] & !sel[1] &  sel[0]; 
    assign mult_first   =  !sel[2] &  sel[1] & !sel[0]; 
    assign mult_acc     =  !sel[2] &  sel[1] &  sel[0]; 
    assign add          =   sel[2] & !sel[1] & !sel[0];
    assign sub          =   sel[2] & !sel[1] &  sel[0];
    assign mult         =   mult_first | mult_acc;
    assign ops          =   add | sub;
    assign non_ntt      =   mult | ops; 
    
    //--*** STATE declaration **--//
	localparam IDLE            = 4'b0000; // 0
	localparam LOAD            = 4'b0001; // 1
	localparam OPER_LOAD_IN    = 4'b0010; // 2
	localparam OPER            = 4'b0100; // 3
	localparam OPER_PWM_0      = 4'b0101; // 4
	localparam OPER_PWM_1      = 4'b0110; // 5
	localparam UPDATE_COUNTER  = 4'b0011; // 6
	localparam END_OP          = 4'b0111; // 7
	localparam LAST_OP         = 4'b1000; // 8
	localparam LAST_OP_IDLE    = 4'b1001; // 9
	
	//--*** STATE register **--//
	reg [3:0] current_state;
	reg [3:0] next_state;
	
	//--*** STATE signals **--//
	reg en_wr;
	reg pwm;
	reg reg_last;
	reg [9:0] counter;
	wire end_counter;
	reg [7:0] counter_last;
	wire end_counter_last;
	wire [7:0] j;
	wire [7:0] k;
	wire [7:0] len;
	reg [1:0] pipe_last;
	
	assign en_write = (last) ? en_wr & & (pipe_last == 2'b10) : en_wr;
	assign pwm_cycle = pwm;
	assign last = reg_last;
	
	assign end_op = (current_state == END_OP) ? 1 : 0;
	assign en_par = (current_state == OPER)   ? 1 : 0;
	assign en_imp = (current_state == OPER)   ? 1 : 0;
	
	//--*** STATE assignations **--//
	assign addr_zeta   = k;
    assign ad_rj       = (reg_last) ? counter_last : j;
    assign ad_rjlen    = j + len;
	
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
        else if (current_state == UPDATE_COUNTER)   update_done <= 1;
        else                                        update_done <= 0;
    end
    
    reg end_pipe;
    always @(posedge clk) begin
        if(!rst)                                    end_pipe <= 0;
        else if (current_state == OPER)             end_pipe <= 1;
        else if (   current_state == OPER_PWM_0 |
                    current_state == OPER_PWM_1)    end_pipe <= end_pipe + 1;
        else                                        end_pipe <= 0;
    end
    
    always @(posedge clk) begin
        if(!rst)                                                    pipe_last <= 0;
        else if (current_state == LAST_OP & pipe_last < 2'b10)      pipe_last <= pipe_last + 1;
        else                                                        pipe_last <= 0;
    end
    
	//--*** STATE Transition **--//
	always @*
		begin
			case (current_state)
				IDLE:
				    if (load)	
						next_state = LOAD;
				    else
				        next_state = IDLE;
			    LOAD:
					if (start)
						next_state = OPER_LOAD_IN;
					else
						next_state = LOAD;
				OPER_LOAD_IN:
				    if (mult)
						next_state = OPER_PWM_0;
					else
						next_state = OPER;
				OPER:
				    if(!end_pipe) 
				        next_state = OPER;
				    else begin
                        if (end_counter)
                            next_state = LAST_OP_IDLE;
                        else
                            next_state = UPDATE_COUNTER;
				    end
			    OPER_PWM_0:
			        if(!end_pipe)
			            next_state = OPER_PWM_0;
			        else
				        next_state = OPER_PWM_1;
				OPER_PWM_1:
				    if(!end_pipe)
				        next_state = OPER_PWM_1;
				    else begin
                        if (end_counter)
                            next_state = LAST_OP_IDLE;
                        else
                            next_state = UPDATE_COUNTER;
				    end
				UPDATE_COUNTER:
				    if (update_done)
						next_state = OPER_LOAD_IN;
					else
						next_state = UPDATE_COUNTER;
			    LAST_OP_IDLE:
			         next_state = LAST_OP;
				LAST_OP:
				    if (end_counter_last)
						next_state = END_OP;
					else
						next_state = LAST_OP;
				END_OP:
					if (load)
						next_state = LOAD;
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
				        pwm     = 0;
				        reg_last = 0;
				    end
				LOAD:
				    begin
				        en_wr   = 0;
				        pwm     = 0;
				        reg_last = 0;
				    end
				OPER_LOAD_IN:
				    begin
				        en_wr   = 0;
				        pwm     = 0;
				        reg_last = 0;
				    end
				OPER:
				    begin
				        en_wr   = 1;
				        pwm     = 0;
				        reg_last = 0;
				    end
				OPER_PWM_0:
				    begin
				        en_wr   = 0;
				        pwm     = 0;
				        reg_last = 0;
				    end
				OPER_PWM_1:
				    begin
				        en_wr   = 1;
				        pwm     = 1;
				        reg_last = 0;
				    end
				UPDATE_COUNTER:
				    begin
				        en_wr   = 0;
				        pwm     = 0;
				        reg_last = 0;
				    end
				LAST_OP_IDLE:
				    begin
				        en_wr   = 0;
				        pwm     = 0;
				        reg_last = 1;
				    end
				LAST_OP:
				    begin
				        en_wr   = 1;
				        pwm     = 0;
				        reg_last = 1;
				    end
				END_OP:
				    begin
				        en_wr   = 0;
				        pwm     = 0;
				        reg_last = 0;
				    end
				default:
				    begin
				        en_wr   = 0;
				        pwm     = 0;
				    end
			endcase
	   end
	
		
    //--*** STATE Counter **--//
    // reg [1:0]   counter_pwm;
    // reg         counter_ops;
    //assign end_counter = (sel[1]) ? ((counter == 10'b0010000000) ? 1 : 0) : ((counter == 10'b1101111111) ? 1 : 0);
    reg reg_end_counter;
    reg reg_end_counter_last;
    
    wire flag_end_counter_ntt;
    wire flag_end_counter_pwm;
    wire flag_end_counter_ops;
    assign flag_end_counter_ntt = (counter == 10'b1101111111) ? 1 : 0; // 895 (896)
    assign flag_end_counter_pwm = (counter == 10'b0001111111) ? 1 : 0; // 127 (128)
    assign flag_end_counter_ops = (counter == 10'b0011111111) ? 1 : 0; // 255 (256)
    
    
    always @(posedge clk) begin
        if(!rst)                                                reg_end_counter <= 0;
        else begin
            if(load)                                            reg_end_counter <= 0;
            else begin
                if      (mult & !ops & flag_end_counter_pwm)    reg_end_counter <= 1;
                else if(!mult & !ops & flag_end_counter_ntt)    reg_end_counter <= 1;
                else if(!mult &  ops & flag_end_counter_ops)    reg_end_counter <= 1;
                else                                            reg_end_counter <= reg_end_counter;
            end
        end
    
    end
    
    assign end_counter = reg_end_counter;
    
    always @(posedge clk) begin
        if(!rst)                                                reg_end_counter_last <= 0;
        else begin
            if(load)                                            reg_end_counter_last <= 0;
            else begin
                if      (counter_last == 8'hFF & pipe_last == 2'b10)    reg_end_counter_last <= 1;
                else                                                    reg_end_counter_last <= reg_end_counter_last;
            end
        end
    
    end
    
    assign end_counter_last = reg_end_counter_last;
    
    
	always @(posedge clk) begin
		  if(!rst)                                                          counter <= 0;  
		  else begin
		      if(current_state == LOAD)                                     counter <= 0;
              else if (current_state == UPDATE_COUNTER & !update_done)      counter <= counter + 1;
              else                                                          counter <= counter;
		  end
    end
    
    always @(posedge clk) begin
		  if(!rst)                                                          counter_last <= 0;  
		  else begin
		      if(current_state == LOAD)                                     counter_last <= 0;
              else if (current_state == LAST_OP & pipe_last == 2'b10)       counter_last <= counter_last + 1;
              else                                                          counter_last <= counter_last;
		  end
    end
    
    // --- * ROM DATA * --- //
    wire [63:0] out_rom; // [k_pwm,pwm,k_invntt,len_invntt,j_invntt,k_ntt,len_ntt,j_ntt]
    ROM_ADD ROM_ADD (.clk(clk), .addr(counter), .q(out_rom));
    
    assign k    = (non_ntt) ? out_rom[63:56]                                    : ((intt) ? out_rom[47:40] : out_rom[23:16]); // sel[0] = 1 invntt
    assign len  = (non_ntt) ? 8'h01                                             : ((intt) ? out_rom[39:32] : out_rom[15:08]);
    assign j    = (non_ntt) ? ( (ops) ? out_rom[55:48] : out_rom[55:48] << 1 )  : ((intt) ? out_rom[31:24] : out_rom[07:00]);
    
endmodule

module NTT_core(
    input clk,
    input rst,
    input pwm_cycle,
    input minus_zeta,
    input   [31:0] rj,
    input   [31:0] rjlen,
    input   [15:0] zeta,
    output  [31:0] rj_out,
    output  [31:0] rjlen_out,
    input   [2:0] sel
    );
    
    wire ntt;
    wire intt;
    wire mult;
    wire mult_first;
    wire mult_acc;
    wire ops;
    wire add;
    wire sub;
    
    assign ntt          =  !sel[2] & !sel[1] & !sel[0]; 
    assign intt         =  !sel[2] & !sel[1] &  sel[0]; 
    assign mult_first   =  !sel[2] &  sel[1] & !sel[0]; 
    assign mult_acc     =  !sel[2] &  sel[1] &  sel[0]; 
    assign add          =   sel[2] & !sel[1] & !sel[0];
    assign sub          =   sel[2] & !sel[1] &  sel[0];
    assign mult         =   mult_first | mult_acc;
    assign ops          =   add | sub;
    
    reg [3:0] mux_sel; //[add3,sub3,add2,sub2,add1,sub1,add0,sub0];
    
    always @* begin
        case(sel)
            3'b000: mux_sel = 4'b1100; // NTT
            3'b001: mux_sel = 4'b0011; // INTT
            3'b010: mux_sel = 4'b0000; // PWM_0-cycle
            3'b011: mux_sel = 4'b0000; // PWM_1-cycle
            3'b100: mux_sel = 4'b0001; // ADD
            3'b101: mux_sel = 4'b0010; // SUB
        endcase
    end
    
    // NTT, INVNTT, ADD, SUB
    wire [15:0] a_ntt, b_ntt;
    wire [15:0] zeta_ntt; 
    wire [15:0] c_ntt, d_ntt; 

    // NTT_cell_v2 NTT_cell (.a(a_ntt), .b(b_ntt), .zeta(zeta_ntt), .c(c_ntt), .d(d_ntt), .mux_sel(mux_sel));
    // NTT_cell NTT_cell (.clk(clk), .a(a_ntt), .b(b_ntt), .zeta(zeta_ntt), .c(c_ntt), .d(d_ntt), .mux_sel(mux_sel));
    
    NTT_cell_2 NTT_cell_2 (.clk(clk), .invntt(intt), .a(a_ntt), .b(b_ntt), .zeta(zeta_ntt), .c(c_ntt), .d(d_ntt), .mux_sel(mux_sel));
    
    
    assign a_ntt = rj[15:00];
    assign b_ntt = (mult | ops) ? rj[31:16] : rjlen[15:00];
    assign zeta_ntt = zeta;
    
    // PWM (basemul)
    wire [15:0] a0_pwm, a1_pwm;
    wire [15:0] b0_pwm, b1_pwm;
    wire [15:0] zeta_pwm; 
    wire [15:0] r0_pwm, r1_pwm; 
    
    PWM_cell PWM_cell (  .clk(clk), .rst(rst), .a0(a0_pwm), .a1(a1_pwm), .b0(b0_pwm), .b1(b1_pwm), 
                            .zeta(zeta_pwm), .h0(r0_pwm), .h1(r1_pwm), .sel(pwm_cycle));
    
    assign a0_pwm = rj[15:00];
    assign b0_pwm = rj[31:16];
    assign a1_pwm = rjlen[15:00];
    assign b1_pwm = rjlen[31:16];
    assign zeta_pwm = (minus_zeta) ? -zeta : zeta;
    
    // out signals
    assign rj_out       = (mult) ? r0_pwm : c_ntt;
    assign rjlen_out    = (mult) ? r1_pwm : d_ntt;

endmodule

module NTT_cell(
    input clk,
    input [15:0] a,
    input [15:0] b,
    input [15:0] zeta,
    output [15:0] c,
    output [15:0] d,
    input [3:0] mux_sel //[add2,sub2,add0,sub0];

    );
    
    wire [15:0] mux_add0; 
    wire [15:0] mux_add2;
    wire [15:0] mux_sub0;
    wire [15:0] mux_sub2;
    
    wire [15:0] xor_zeta;
    
    // fqmult fqmult (.a(zeta), .b(mux_sub0), .t(xor_zeta));
    fqmult_pipe fqmult (.clk(clk), .a(zeta), .b(mux_sub0), .t(xor_zeta));
    
    assign mux_add0 = (mux_sel[0]) ? (a + b) : a;
    assign mux_sub0 = (mux_sel[1]) ? (b - a) : b;
    assign mux_add2 = (mux_sel[2]) ? (mux_add0 + xor_zeta) : mux_add0;
    assign mux_sub2 = (mux_sel[3]) ? (mux_add0 - xor_zeta) : xor_zeta;
    
    assign c = (mux_sel[1] & !mux_sel[0]) ? mux_sub0 : mux_add2;
    assign d = mux_sub2;

endmodule

module NTT_cell_2(
    input clk,
    input invntt,
    input [15:0] a,
    input [15:0] b,
    input [15:0] zeta,
    output [15:0] c,
    output [15:0] d,
    input [3:0] mux_sel //[add2,sub2,add0,sub0];

    );
    
    wire [15:0] mux_add0; 
    wire [15:0] mux_add2;
    wire [15:0] mux_sub0;
    wire [15:0] mux_sub2;
    
    wire [15:0] mux_add0_2;
    wire [15:0] br;
    
    wire [15:0] xor_zeta;
    
    // fqmult fqmult (.a(zeta), .b(mux_sub0), .t(xor_zeta));
    fqmult_pipe fqmult (.clk(clk), .a(zeta), .b(mux_sub0), .t(xor_zeta));
    
    assign mux_add0 = (mux_sel[0]) ? (a + b) : a;
    assign mux_sub0 = (mux_sel[1]) ? (b - a) : b;
    assign mux_add2 = (mux_sel[2]) ? (mux_add0 + xor_zeta) : mux_add0_2;
    assign mux_sub2 = (mux_sel[3]) ? (mux_add0 - xor_zeta) : xor_zeta;
    
    assign c = (mux_sel[1] & !mux_sel[0]) ? mux_sub0 : mux_add2;
    assign d = mux_sub2;
    
    assign mux_add0_2 = (invntt) ? br : mux_add0; 
    
    barret_reduce_pipe barret_reduce(.clk(clk), .a(mux_add0), .t(br));
    
endmodule

module PWM_cell(
    input clk,
    input rst,
    input [15:0] a0,
    input [15:0] a1,
    input [15:0] b0,
    input [15:0] b1,
    input [15:0] zeta,
    output [15:0] h0,
    output [15:0] h1,
    input sel
    );

    reg [15:0] s0;
    reg [15:0] m0;
    reg [15:0] s1;
    reg [15:0] m1;
    
    wire [15:0] in_a0;
    wire [15:0] in_b0;
    wire [15:0] in_a1;
    wire [15:0] in_b1;
    wire [15:0] m0_wire;
    wire [15:0] m1_wire;
    
    
    // fqmult fqmult0 (.a(in_a0), .b(in_b0), .t(m0_wire));
    // fqmult fqmult1 (.a(in_a1), .b(in_b1), .t(m1_wire));
    
    fqmult_pipe fqmult0 (.clk(clk), .a(in_a0), .b(in_b0), .t(m0_wire));
    fqmult_pipe fqmult1 (.clk(clk), .a(in_a1), .b(in_b1), .t(m1_wire));
    
    assign in_a0 = (sel) ? s0    : a0;
    assign in_b0 = (sel) ? s1    : b0;
    assign in_a1 = (sel) ? m1    : a1;
    assign in_b1 = (sel) ? zeta  : b1;
    
    assign h0 = m0 + m1_wire;
    assign h1 = m0_wire - m0 - m1;
    
    always @(posedge clk) begin
        if(!rst) begin
            s0 <= 0;
            m0 <= 0;
            s1 <= 0;
            m1 <= 0;
        end
        else begin
            if(!sel) s0 <= (a0 + a1);
            else             s0 <= s0; 
            
            if(!sel) m0 <= m0_wire;
            else             m0 <= m0;    
            
            if(!sel) s1 <= (b0 + b1);
            else             s1 <= s1; 
            
            if(!sel) m1 <= m1_wire;
            else             m1 <= m1; 
            
        end
    end


endmodule


