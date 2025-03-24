/**
  * @file CORE_MLKEM.v
  * @brief MLKEM Core
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
  * @version 2.0
  **/

`timescale 1ns / 1ps

module CORE_MLKEM #(
    parameter COUNTERMEASURES = 0
    )(
    input           clk,
    input           rst,
    input           fixed,
    input   [7:0]   control,
    input   [15:0]  data_in,
    input   [15:0]  add,
    output  [15:0]  data_out,
    output  [1:0]   end_op
    );
    // -- Control signals -- //
    wire [3:0] op;
    assign op = control[3:0];
   
    wire reset;
    wire load_coins;
    wire load_sk;
    wire read_sk;
    wire load_pk;
    wire read_pk;
    wire load_ct;
    wire read_ct;
    wire load_ss;
    wire read_ss;
    wire load_hek;
    wire read_hek;
    wire load_ps;
    wire read_ps;
    wire start;
    
    assign reset        = (op == 4'b0001) ? 1 : 0;
    assign load_coins   = (op == 4'b0010) ? 1 : 0;
    assign load_sk      = (op == 4'b0011) ? 1 : 0;
    assign read_sk      = (op == 4'b0100) ? 1 : 0;
    assign load_pk      = (op == 4'b0101) ? 1 : 0;
    assign read_pk      = (op == 4'b0110) ? 1 : 0;
    assign load_ct      = (op == 4'b0111) ? 1 : 0;
    assign read_ct      = (op == 4'b1000) ? 1 : 0;
    assign load_ss      = (op == 4'b1001) ? 1 : 0;
    assign read_ss      = (op == 4'b1010) ? 1 : 0;
    assign load_hek     = (op == 4'b1011) ? 1 : 0;
    assign read_hek     = (op == 4'b1100) ? 1 : 0;
    assign load_ps      = (op == 4'b1101) ? 1 : 0;
    assign read_ps      = (op == 4'b1110) ? 1 : 0;
    assign start        = (op == 4'b1111) ? 1 : 0;
    
    wire load_data; 
    assign load_data = load_sk | load_pk | load_ct | load_ss | load_coins | load_hek | load_ps;
    wire read_data;
    assign read_data = read_sk | read_pk | read_ct | read_ss | read_hek | read_ps;
    
    wire [15:0] data_in_dmu;
    wire load_fifo;
    
    // -- Mode signals -- //
    wire [3:0] mode;
    assign mode = control[7:4];
    
    wire k_2;
    wire k_3;
    wire k_4;
    wire gen_keys;
    wire encap;
    wire decap;
    
    assign k_2          = (mode[1:0] == 2'b01) ? 1 : 0;
    assign k_3          = (mode[1:0] == 2'b10) ? 1 : 0;
    assign k_4          = (mode[1:0] == 2'b11) ? 1 : 0;
    assign gen_keys     = (mode[3:2] == 2'b01) ? 1 : 0;
    assign encap        = (mode[3:2] == 2'b10) ? 1 : 0;
    assign decap        = (mode[3:2] == 2'b11) ? 1 : 0;
    
    // --- AU CORE --- //
    wire [47:0] control_core;
    wire [31:0] data_in_core;
    wire [15:0] data_out_core;
    wire [15:0] add_core;
    wire        end_op_core; 
    
    AU_CORE #(
        .COUNTER(COUNTERMEASURES)
    )   
    AU_CORE
    (   .clk(clk), .rst(rst), .fixed(fixed),
        .control(control_core),
        .data_in(data_in_core),
        .data_out(data_out_core),
        .add(add_core),
        .end_op(end_op_core),
        .check_ct(check_ct)
     );
    
    // --- MEM CORE --- // 
    wire  [15:0]  data_in_0;
    wire  [15:0]  data_in_1;
    wire  [15:0]  data_in_2;
    wire  [15:0]  data_out_0;
    wire  [15:0]  data_out_1;
    wire  [15:0]  data_out_2;
    wire  [15:0]  add_0;
    wire  [15:0]  add_1;
    wire  [15:0]  add_2;
    wire          en_w_0;
    wire          en_w_1;
    wire          en_w_2;
    
    MEM_CORE MEM_CORE (
    .clk(clk),
    .data_in_0(data_in_0), 
    .data_in_1(data_in_1), 
    .data_in_2(data_in_2), 
    .data_out_0(data_out_0),
    .data_out_1(data_out_1),
    .data_out_2(data_out_2),
    .add_0(add_0),     
    .add_1(add_1),     
    .add_2(add_2),     
    .en_w_0(en_w_0),    
    .en_w_1(en_w_1),    
    .en_w_2(en_w_2)    
    );
    
    // --- CONTROL CORE --- //
    wire [7:0] deco_concat;
    wire end_op_control;
    
    wire [2:0] en_w;
    assign en_w_0 = en_w[0];
    assign en_w_1 = en_w[1];
    assign en_w_2 = en_w[2];
    
    CONTROL_CORE  CONTROL_CORE
    (
    .clk(clk), .rst(rst),
    .control(control),
    .add(add),
    .end_op_au(end_op_core),
    .deco_concat(deco_concat),
    .control_core(control_core),
    .add_core(add_core),
    .add_0(add_0),
    .add_1(add_1),
    .add_2(add_2),
    .en_w(en_w),
    .end_op(end_op_control)
    );
    
    reg [1:0] end_op_reg;
    always @* begin
                if(end_op_control &  check_ct)  end_op_reg = 2'b01; // Bad End
        else    if(end_op_control & !check_ct)  end_op_reg = 2'b11; // Good End
        else                                    end_op_reg = 2'b00; // Not end
    end
    assign end_op = end_op_reg;
    
    // --- DMU CORE  --- //
    DMU_CORE DMU_CORE (
    .deco_concat(deco_concat),
    .load_data_in(load_data),
    .data_in(data_in),
    .data_in_0(data_in_0), 
    .data_in_1(data_in_1), 
    .data_in_2(data_in_2), 
    .data_in_core(data_in_core),
    .data_out_core(data_out_core),
    .data_out_0(data_out_0),
    .data_out_1(data_out_1),
    .data_out_2(data_out_2)  
    );
    
    reg [15:0] data_out_reg;
    
    always @* begin
        if(read_pk | (read_sk & !gen_keys) | read_ps)                           data_out_reg = data_out_1;
        else if(read_ct | read_ss | (read_sk & gen_keys) | read_hek)            data_out_reg = data_out_2;
        else                                                                    data_out_reg = data_out_0; 
    
    end
    assign data_out = data_out_reg;


endmodule

module CONTROL_CORE (
    input           clk,
    input           rst,
    input   [7:0]   control,
    input   [15:0]  add,
    input           end_op_au,
    output  [47:0]  control_core,
    output  [7:0]   deco_concat,
    output  [15:0]  add_core,
    output  [15:0]  add_0,
    output  [15:0]  add_1,
    output  [15:0]  add_2,
    output  [2:0]   en_w,
    output          end_op
);
    // -- Control signals -- //
    wire [3:0] op;
    assign op = control[3:0];
   
    wire reset;
    wire load_coins;
    wire load_sk;
    wire read_sk;
    wire load_pk;
    wire read_pk;
    wire load_ct;
    wire read_ct;
    wire load_ss;
    wire read_ss;
    wire load_hek;
    wire read_hek;
    wire load_ps;
    wire read_ps;
    wire start;
    
    assign reset        = (op == 4'b0001) ? 1 : 0;
    assign load_coins   = (op == 4'b0010) ? 1 : 0;
    assign load_sk      = (op == 4'b0011) ? 1 : 0;
    assign read_sk      = (op == 4'b0100) ? 1 : 0;
    assign load_pk      = (op == 4'b0101) ? 1 : 0;
    assign read_pk      = (op == 4'b0110) ? 1 : 0;
    assign load_ct      = (op == 4'b0111) ? 1 : 0;
    assign read_ct      = (op == 4'b1000) ? 1 : 0;
    assign load_ss      = (op == 4'b1001) ? 1 : 0;
    assign read_ss      = (op == 4'b1010) ? 1 : 0;
    assign load_hek     = (op == 4'b1011) ? 1 : 0;
    assign read_hek     = (op == 4'b1100) ? 1 : 0;
    assign load_ps      = (op == 4'b1101) ? 1 : 0;
    assign read_ps      = (op == 4'b1110) ? 1 : 0;
    assign start        = (op == 4'b1111) ? 1 : 0;
    
    wire load_data; 
    assign load_data = load_sk | load_pk | load_ct | load_ss | load_coins | load_hek | load_ps;
    wire read_data;
    assign read_data = read_sk | read_pk | read_ct | read_ss | read_hek | read_ps | end_op;
    
    // -- Mode signals -- //
    wire [3:0] mode;
    assign mode = control[7:4];
    
    wire k_2;
    wire k_3;
    wire k_4;
    wire gen_keys;
    wire encap;
    wire decap;
    
    assign k_2          = (mode[1:0] == 2'b01) ? 1 : 0;
    assign k_3          = (mode[1:0] == 2'b10) ? 1 : 0;
    assign k_4          = (mode[1:0] == 2'b11) ? 1 : 0;
    assign gen_keys     = (mode[3:2] == 2'b01) ? 1 : 0;
    assign encap        = (mode[3:2] == 2'b10) ? 1 : 0;
    assign decap        = (mode[3:2] == 2'b11) ? 1 : 0;
    
    // --- mem signals --- //    
    wire [7:0] concaten;
    wire [15:0] ini_add0;
    wire [15:0] ini_add1;
    wire [15:0] ini_add2;
    reg  [15:0] reg_add0;
    reg  [15:0] reg_add1;
    reg  [15:0] reg_add2;
    
    assign add_0 = (load_data | read_data | end_op) ? (ini_add0 + add) : (reg_add0);
    assign add_1 = (load_data | read_data | end_op) ? (ini_add1 + add) : (reg_add1);
    assign add_2 = (load_data | read_data | end_op) ? (ini_add2 + add) : (reg_add2);
    
    assign deco_concat = concaten;
    
    wire    en_w0;
    wire    en_w1;
    wire    en_w2;
    assign  en_w    = {en_w2,en_w1,en_w0};
    
    // ---- AU signals ---- //
    wire [7:0] control_ntt;
    wire [7:0] control_sha3;
    wire [3:0] x;
    wire [3:0] y;
    wire [7:0] control_ed;
    wire [7:0] state_au;
    
    assign control_core = {state_au,8'h00,control_ed,y,x,control_sha3,control_ntt};
    
    wire reset_au;
    wire load_au;
    wire load_seed;
    wire start_au;
    wire read_au;
    wire end_program;
    wire reset_sha3;
    wire load_au_ct;
    wire comp_ct;
    reg save_ss;
    reg save_coins;
    
    always @(posedge clk) begin
        if(!rst | end_op | reset)   save_ss <= 0;
        else begin
            if(load_ss)             save_ss <= 1;
            else                    save_ss <= save_ss;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | end_op | reset)   save_coins <= 0;
        else begin
            if(load_coins)          save_coins <= 1;
            else                    save_coins <= save_coins;
        end
    end
    
    //--*** STATE declaration **--//
	localparam IDLE                = 8'h00; 
	localparam LOAD_DATA           = 8'h01;
	localparam START               = 8'h04; 
	localparam READ                = 8'h05; 
	localparam LOAD_INSTRUCTION    = 8'h10; 
	localparam LOAD_INI_ADD        = 8'h11; 
	localparam LOAD_ADD_COUNT      = 8'h12; 
	localparam LOAD_END            = 8'h13; 
	localparam START_OP            = 8'h20;
	localparam END_OP_AU           = 8'h2F;
	localparam READ_INI_ADD        = 8'h31; 
	localparam READ_ADD_COUNT      = 8'h32; 
	localparam READ_END            = 8'h33;
	localparam UPDATE_INSTRUCTION  = 8'hF0;
	localparam END_OP              = 8'hFF;
	
	//--*** STATE register **--//
	reg [7:0] current_state;
	reg [7:0] next_state;
	
	//--*** STATE signals **--//
	wire           ns;
	wire           fs;
	reg    [15:0]   counter_add;
	reg    [15:0]   counter_ins;
	reg    [1:0]   counter_cycles;
	wire           end_counter;
	wire           end_random;
	
	assign ns          = (counter_cycles[0] == 1'b1)                           ? 1 : 0;
	assign fs          = (counter_cycles == 0)                                 ? 1 : 0;
	assign end_op      = (current_state == END_OP | current_state == READ)     ? 1 : 0;
	assign add_core    = counter_add;
	
	//--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst | reset)    
			     current_state <= IDLE;
			else
			     current_state <= next_state;
		end
		
	//--*** STATE Transition **--//
	always @*
		begin
			case (current_state)
				IDLE:
				   if (load_data | start)
				      next_state = LOAD_DATA;
				   else
				      next_state = IDLE;
				LOAD_DATA:
				   if (start)
				      next_state = START;
				   else
				      next_state = LOAD_DATA;
				START:
				    if(ns)  
				        next_state = LOAD_INSTRUCTION; //LOAD_INSTRUCTION
				    else    
				        next_state = START;
			    LOAD_INSTRUCTION:
					if (ns) begin
					   if      (   load_au | load_seed | reset_sha3 | 
					               load_au_ct | comp_ct)                           next_state = LOAD_INI_ADD;
					   else if (start_au)                                          next_state = START_OP;
					   else if (read_au)                                           next_state = READ_INI_ADD;
					   else if (end_program)                                       next_state = END_OP;
					   else                                                        next_state = UPDATE_INSTRUCTION;
					end
					else                                                           next_state = LOAD_INSTRUCTION;
				LOAD_INI_ADD:
				    if (ns)
						next_state = LOAD_ADD_COUNT;
					else
						next_state = LOAD_INI_ADD;
				LOAD_ADD_COUNT:
					if (ns & end_counter)
						next_state = LOAD_END;
					else
						next_state = LOAD_ADD_COUNT;
				LOAD_END:
					if (ns)
						next_state = UPDATE_INSTRUCTION;
					else
						next_state = LOAD_END;
				START_OP:
					if (ns & end_op_au)
						next_state = END_OP_AU;
					else
						next_state = START_OP;
				END_OP_AU:
					if (ns)
						next_state = UPDATE_INSTRUCTION;
					else
						next_state = END_OP_AU;
			    READ_INI_ADD:
				    if (ns)
						next_state = READ_ADD_COUNT;
					else
						next_state = READ_INI_ADD;
				READ_ADD_COUNT:
					if (ns & end_counter)
						next_state = READ_END;
					else
						next_state = READ_ADD_COUNT;
				READ_END:
					if (ns)
						next_state = UPDATE_INSTRUCTION;
					else
						next_state = READ_END;
				UPDATE_INSTRUCTION:
					if (ns)
						next_state = LOAD_INSTRUCTION;
					else
						next_state = UPDATE_INSTRUCTION;
				END_OP:
				    if (read_data)
				        next_state = READ;
				    else
					    next_state = END_OP;
			    READ:
			        if (reset)
				        next_state = IDLE;
				    else
					    next_state = READ;
				default:
					next_state = IDLE;
			endcase 		
		end 
	
	//--*** STATE Signals **--//
	wire load_ram0;
	wire load_ram1;
	wire load_ram2;
	assign load_ram0 = load_ct;
	assign load_ram1 = (gen_keys) ? (load_coins)   : (load_pk | load_coins | load_ps);
	assign load_ram2 = (gen_keys) ? (load_ss)      : (load_sk | load_ss | load_hek);
	assign en_w0 = (((current_state == READ_ADD_COUNT) & (concaten[7:4] == 4'h0)) | load_ram0 ) ? 1 : 0;
	assign en_w1 = (((current_state == READ_ADD_COUNT) & (concaten[7:4] == 4'h1)) | load_ram1 ) ? 1 : 0;
	assign en_w2 = (((current_state == READ_ADD_COUNT) & (concaten[7:4] == 4'h2)) | load_ram2 ) ? 1 : 0;

    //--*** STATE Counter **--//
    wire param_256;
    wire param_KYBER_KEY_0;
    wire param_KYBER_KEY_1;
    wire param_KYBER_KEY_2;
    wire param_KYBER_KEY_3;
    wire param_KYBER_CIPHERTEXT_0;
    wire param_KYBER_CIPHERTEXT_1;
    wire param_KYBER_CIPHERTEXT_2;
    wire param_KYBER_CIPHERTEXT_3;
    wire param_KYBER_CIPHERTEXT_128;
    wire param_SEED;
    wire param_32;
    
    assign reset_au                             = (state_au[7:4] == 4'h0) ? 1 : 0;
    assign load_au                              = (state_au[7:4] == 4'h1) ? 1 : 0;
    assign load_seed                            = (state_au[7:4] == 4'h2) ? 1 : 0;
    assign start_au                             = (state_au[7:4] == 4'h3) ? 1 : 0;
    assign read_au                              = (state_au[7:4] == 4'h4) ? 1 : 0;
    assign reset_sha3                           = (state_au[7:4] == 4'h5) ? 1 : 0;
    assign load_au_ct                           = (state_au[7:4] == 4'h6) ? 1 : 0;
    assign comp_ct                              = (state_au[7:4] == 4'h7) ? 1 : 0;
    assign do_nothing                           = (state_au[7:4] == 4'h9) ? 1 : 0;
    assign end_program                          = (state_au[7:4] == 4'hF) ? 1 : 0; 
    
    assign param_256                            = (state_au[3:0] == 4'h0) ? 1 : 0;
    assign param_SEED                           = (state_au[3:0] == 4'h1) ? 1 : 0;
    assign param_32                             = (state_au[3:0] == 4'h2) ? 1 : 0;
    assign param_KYBER_KEY_0                    = (state_au[3:0] == 4'h3) ? 1 : 0; // 0 - 383
    assign param_KYBER_KEY_1                    = (state_au[3:0] == 4'h4) ? 1 : 0; // 384 - 767
    assign param_KYBER_KEY_2                    = (state_au[3:0] == 4'h5) ? 1 : 0; // 768 - 1151
    assign param_KYBER_KEY_3                    = (state_au[3:0] == 4'h6) ? 1 : 0; // 1152 - 1535
    assign param_KYBER_CIPHERTEXT_0             = (state_au[3:0] == 4'h7) ? 1 : 0; // 0 - 319 ..    0 - 351
    assign param_KYBER_CIPHERTEXT_1             = (state_au[3:0] == 4'h8) ? 1 : 0; // 320 - 639 .. 352 - 703
    assign param_KYBER_CIPHERTEXT_2             = (state_au[3:0] == 4'h9) ? 1 : 0; // 640 - 959 .. 704 - 1055
    assign param_KYBER_CIPHERTEXT_3             = (state_au[3:0] == 4'hA) ? 1 : 0; // 1056 - 1407
    assign param_KYBER_CIPHERTEXT_128           = (state_au[3:0] == 4'hB) ? 1 : 0; // +128
    assign param_128                            = (state_au[3:0] == 4'hC) ? 1 : 0;
    assign param_NOISE                          = (state_au[3:0] == 4'hD) ? 1 : 0;
    assign param_HEK                            = (state_au[3:0] == 4'hE) ? 1 : 0;
    assign param_NOISE_2                        = (state_au[3:0] == 4'hF) ? 1 : 0;

    
    localparam KYBER_PUBLICKEYBYTES_512     = 800 - 32;
    localparam KYBER_PUBLICKEYBYTES_768     = 1184 - 32;
    localparam KYBER_PUBLICKEYBYTES_1024    = 1568 - 32;
    
    localparam KYBER_CIPHERTEXTBYTES_512    = 768;
    localparam KYBER_CIPHERTEXTBYTES_768    = 1088;
    localparam KYBER_CIPHERTEXTBYTES_1024   = 1568;
    
    localparam KYBER_256                    = 256;
    
    reg [15:0] val_counter;
    always @* begin
                if(param_256)                           val_counter = 256;
        else    if(load_au_ct | comp_ct) begin
                        if(k_2)                         val_counter = KYBER_CIPHERTEXTBYTES_512;
                else    if(k_3)                         val_counter = KYBER_CIPHERTEXTBYTES_768;
                else                                    val_counter = KYBER_CIPHERTEXTBYTES_1024;
        end
        else    if( param_KYBER_KEY_0 | 
                    param_KYBER_KEY_1 |
                    param_KYBER_KEY_2 | 
                    param_KYBER_KEY_3)                  val_counter = 384;
        else    if( param_KYBER_CIPHERTEXT_0 | 
                    param_KYBER_CIPHERTEXT_1 |
                    param_KYBER_CIPHERTEXT_2 | 
                    param_KYBER_CIPHERTEXT_3) begin
                        if(k_4)                         val_counter = 352;
                        else                            val_counter = 320;
                    end           
        else    if(param_KYBER_CIPHERTEXT_128) begin
                        if(k_4)                         val_counter = 160;
                        else                            val_counter = 128;
                    end                                    
        else    if(param_SEED)                          val_counter = 16;
        else    if(param_32  | param_NOISE | param_NOISE_2)             val_counter = 32;
        else    if(param_128)                           val_counter = 128;
        else    if(param_HEK)                           val_counter = 136;
        else                                            val_counter = 256;                 
    end
    
    assign end_counter  = (counter_add == (val_counter - 1)) ? 1 : 0;
    
    always @(posedge clk) begin
        if(!rst | reset) begin
            reg_add0 <= 0;
            reg_add1 <= 0;
            reg_add2 <= 0;
        end
        else begin
            if(current_state == LOAD_INI_ADD | current_state == READ_INI_ADD) begin
                reg_add0 <= ini_add0;
                reg_add1 <= ini_add1;
                reg_add2 <= ini_add2;  
            end
            else if((ns & !end_counter) & (current_state == LOAD_ADD_COUNT | current_state == READ_ADD_COUNT)) begin
                reg_add0 <= reg_add0 + 1;
                reg_add1 <= reg_add1 + 1;
                reg_add2 <= reg_add2 + 1; 
            end
            else begin
                reg_add0 <= reg_add0;
                reg_add1 <= reg_add1;
                reg_add2 <= reg_add2; 
            end
        end
    end
    
    always @(posedge clk) begin
        if(!rst | reset) counter_add <= 0;
        else begin
            if(current_state == LOAD_INI_ADD | current_state == READ_INI_ADD) 
                counter_add <= 0;
            else if((ns & !end_counter) & (current_state == LOAD_ADD_COUNT | current_state == READ_ADD_COUNT))
                counter_add <= counter_add + 1;
            else
                counter_add <= counter_add;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | reset | load_data) counter_ins <= 0;
        else begin
            if(ns & (current_state == UPDATE_INSTRUCTION)) 
                counter_ins <= counter_ins + 1;
            else
                counter_ins <= counter_ins;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | reset)    counter_cycles <= 0;
        else                counter_cycles <= counter_cycles + 1;
    end
    
    reg [3:0] hek_counter;
    always @(posedge clk) begin
        if(!rst | reset)    hek_counter <= 0;
        else begin
        if(ns & param_HEK & (current_state == UPDATE_INSTRUCTION) & !do_nothing) 
                hek_counter <= hek_counter + 1;
            else
                hek_counter <= hek_counter;
        end
    end
    
    // --- * ROM DATA * --- //
    reg [79:0] out_rom; 
    
    wire [79:0] out_rom_gen_k_2;
    PROGRAM_ROM         #(.GEN(1), .ENC(0), .DEC(0), .K(2)) 
    PROGRAM_ROM_GEN_K_2  (.clk(clk), .addr(counter_ins), .q(out_rom_gen_k_2));
    
    wire [79:0] out_rom_gen_k_3;
    PROGRAM_ROM         #(.GEN(1), .ENC(0), .DEC(0), .K(3)) 
    PROGRAM_ROM_GEN_K_3  (.clk(clk), .addr(counter_ins), .q(out_rom_gen_k_3));
    
    wire [79:0] out_rom_gen_k_4;
    PROGRAM_ROM         #(.GEN(1), .ENC(0), .DEC(0), .K(4)) 
    PROGRAM_ROM_GEN_K_4  (.clk(clk), .addr(counter_ins), .q(out_rom_gen_k_4));
    
    wire [79:0] out_rom_enc_k_2;
    PROGRAM_ROM         #(.GEN(0), .ENC(1), .DEC(0), .K(2)) 
    PROGRAM_ROM_ENC_K_2  (.clk(clk), .addr(counter_ins), .q(out_rom_enc_k_2));
    
    wire [79:0] out_rom_enc_k_3;
    PROGRAM_ROM         #(.GEN(0), .ENC(1), .DEC(0), .K(3)) 
    PROGRAM_ROM_ENC_K_3  (.clk(clk), .addr(counter_ins), .q(out_rom_enc_k_3));
    
    wire [79:0] out_rom_enc_k_4;
    PROGRAM_ROM         #(.GEN(0), .ENC(1), .DEC(0), .K(4)) 
    PROGRAM_ROM_ENC_K_4  (.clk(clk), .addr(counter_ins), .q(out_rom_enc_k_4));
    
    wire [79:0] out_rom_dec_k_2;
    PROGRAM_ROM         #(.GEN(0), .ENC(0), .DEC(1), .K(2)) 
    PROGRAM_ROM_DEC_K_2  (.clk(clk), .addr(counter_ins), .q(out_rom_dec_k_2));
    
    wire [79:0] out_rom_dec_k_3;
    PROGRAM_ROM         #(.GEN(0), .ENC(0), .DEC(1), .K(3)) 
    PROGRAM_ROM_DEC_K_3  (.clk(clk), .addr(counter_ins), .q(out_rom_dec_k_3));
    
    wire [79:0] out_rom_dec_k_4;
    PROGRAM_ROM         #(.GEN(0), .ENC(0), .DEC(1), .K(4)) 
    PROGRAM_ROM_DEC_K_4  (.clk(clk), .addr(counter_ins), .q(out_rom_dec_k_4));
    
    always @* begin
        if(k_2) begin
                    if (gen_keys)    out_rom = out_rom_gen_k_2;
            else    if (encap)       out_rom = out_rom_enc_k_2;
            else    if (decap)       out_rom = out_rom_dec_k_2;
            else                     out_rom = out_rom_gen_k_2;
        end
        else if(k_3) begin
                    if (gen_keys)    out_rom = out_rom_gen_k_3;
            else    if (encap)       out_rom = out_rom_enc_k_3;
            else    if (decap)       out_rom = out_rom_dec_k_3;
            else                     out_rom = out_rom_gen_k_3;
        end
        else if(k_4) begin
                    if (gen_keys)    out_rom = out_rom_gen_k_4;
            else    if (encap)       out_rom = out_rom_enc_k_4;
            else    if (decap)       out_rom = out_rom_dec_k_4;
            else                     out_rom = out_rom_gen_k_4;
        end
        else                         out_rom = out_rom_gen_k_2;
    end

    
    reg [15:0] ini_add_2_reg;
    reg [15:0] ini_add_1_reg;
    reg [15:0] ini_add_0_reg;
    
    always @* begin
                if((gen_keys | decap) & (load_sk | read_sk)) ini_add_2_reg = 16'h0900;
        else    if(read_ct)                                  ini_add_2_reg = 16'h0900;
        else    if(load_ss | read_ss)                        ini_add_2_reg = 16'h1000;
        else    if(load_hek | read_hek)                      ini_add_2_reg = 16'h0F00;
        else    if(param_KYBER_KEY_0)                        ini_add_2_reg = 16'h0900;
        else    if(param_KYBER_KEY_1)                        ini_add_2_reg = 16'h0A80;
        else    if(param_KYBER_KEY_2)                        ini_add_2_reg = 16'h0C00;
        else    if(param_KYBER_KEY_3)                        ini_add_2_reg = 16'h0D80;
        else    if(param_KYBER_CIPHERTEXT_0)                 ini_add_2_reg = 16'h0900;
        else    if(param_KYBER_CIPHERTEXT_1) begin
                if(k_4)                                      ini_add_2_reg = 16'h0A60; //352
                else                                         ini_add_2_reg = 16'h0A40; //320
        end               
        else    if(param_KYBER_CIPHERTEXT_2) begin
                if(k_4)                                      ini_add_2_reg = 16'h0BC0; //704
                else                                         ini_add_2_reg = 16'h0B80; //640
        end               
        else    if(param_KYBER_CIPHERTEXT_3) begin
                if(k_4)                                      ini_add_2_reg = 16'h0D20; //1056
                else                                         ini_add_2_reg = 16'h0CC0; //960
        end 
        else    if(param_KYBER_CIPHERTEXT_128) begin
                     if(k_2)                                 ini_add_2_reg = 16'h0B80; //640
                else if(k_3)                                 ini_add_2_reg = 16'h0CC0; //960
                else                                         ini_add_2_reg = 16'h0E80; //1408
        end                  
        else                                                 ini_add_2_reg = (out_rom[15:08] << 8);
    end
    
    always @* begin
                if(load_pk | load_sk | read_pk | read_sk)   ini_add_1_reg = 16'h0900;
        else    if(load_ps | read_ps)                       ini_add_1_reg = 16'h0F00;
        else    if(load_coins)                              ini_add_1_reg = 16'h1000;
        else    if(param_KYBER_KEY_0)                       ini_add_1_reg = 16'h0900;
        else    if(param_KYBER_KEY_1)                       ini_add_1_reg = 16'h0A80;
        else    if(param_KYBER_KEY_2)                       ini_add_1_reg = 16'h0C00;
        else    if(param_KYBER_KEY_3)                       ini_add_1_reg = 16'h0D80;
        else    if(param_NOISE)                             ini_add_1_reg = 16'h0FF0;
        else    if(param_NOISE_2)                           ini_add_1_reg = 16'h0EF0;
        else    if(param_HEK)                               ini_add_1_reg = 16'h0900 + hek_counter*136;
        else                                                ini_add_1_reg = (out_rom[23:16] << 8);
    end
    
     always @* begin
                if(load_ct)                                  ini_add_0_reg = 16'h0900;
        else    if(param_KYBER_CIPHERTEXT_0)                 ini_add_0_reg = 16'h0900;
        else    if(param_KYBER_CIPHERTEXT_1) begin                   
                if(k_4)                                      ini_add_0_reg = 16'h0A60; //352
                else                                         ini_add_0_reg = 16'h0A40; //320
        end                                                          
        else    if(param_KYBER_CIPHERTEXT_2) begin                   
                if(k_4)                                      ini_add_0_reg = 16'h0BC0; //704
                else                                         ini_add_0_reg = 16'h0B80; //640
        end                                                          
        else    if(param_KYBER_CIPHERTEXT_3) begin                   
                if(k_4)                                      ini_add_0_reg = 16'h0D20; //1056
                else                                         ini_add_0_reg = 16'h0CC0; //960
        end                                                          
        else    if(param_KYBER_CIPHERTEXT_128) begin                 
                     if(k_2)                                 ini_add_0_reg = 16'h0B80; //640
                else if(k_3)                                 ini_add_0_reg = 16'h0CC0; //960
                else                                         ini_add_0_reg = 16'h0E80; //1408
        end 
        else    if(param_HEK)                                ini_add_0_reg = 16'h0900 + hek_counter*136;
        else                                                 ini_add_0_reg = out_rom[31:24] << 8;
    end
    
    assign concaten     =   out_rom[07:00];
    assign ini_add2     =   ini_add_2_reg;
    assign ini_add1     =   ini_add_1_reg;
    assign ini_add0     =   ini_add_0_reg;
    assign control_ntt  =   out_rom[39:32];
    assign control_sha3 =   out_rom[47:40];
    assign x            =   out_rom[51:48];
    assign y            =   out_rom[55:52];
    assign control_ed   =   out_rom[63:56];
    assign state_au     =   out_rom[79:72]; 
     
    
    // < ------------------------- PROGRAM_ROM <31:0> ------------------------------ >
    // < [23:0] >< -- NTTOP [7:0] -- >< ------------ RAM ADDRESSES [31:0] ------------- >
    // < ------ >< CODE_NTT | OP_NTT >< ADD_RAM0 >< ADD_RAM1 >< ADD_RAM2 >< CONCAT MODE >
    
    //  | CODE_NTT  ||   MODE           || OP_NTT  ||   OPERATION   ||
    //  | --------  ||  -------------   || ------  ||  ---------    ||
    //  |   0       ||   NTT            ||   0     ||   RESET       ||
    //  |   1       ||   INTT           ||   1     ||   LOAD        ||
    //  |   2       ||   MULT_FIRST_ACC ||   2     ||   START       ||
    //  |   3       ||   MULT_ACC       ||   3     ||   READ        ||
    //  |   4       ||   ADD            ||      
    //  |   5       ||   SUB            ||
    
    //  | -- ADD -- || --- RAM0 --- || --- RAM 1 --- || --- RAM 2 --- | 
    //  |   0x00    ||      v       ||      epp      ||      k        |
    //  |   0x10    ||  a[0].vec[0] ||   ep.vec[0]   ||    b.vec[0]   |
    //  |   0x20    ||  a[0].vec[1] ||   ep.vec[1]   ||    b.vec[1]   |
    //  |   0x30    ||  a[1].vec[0] ||   sp.vec[0]   ||  pkpv.vec[0]  |
    //  |   0x40    ||  a[1].vec[1] ||   sp.vec[1]   ||  pkpv.vec[1]  |
    
    //  CONCATENATE MODE
    //  | CODE  ||  DEST    ||  CONCAT 1 <31:16>    ||  CONCAT 0 <15:00>    ||
    //  | ----  ||  -----   ||  -----------------   ||  ----------------    ||
    //  |  00   ||  RAM0    ||  0000                ||  RAM0                ||
    //  |  10   ||  RAM1    ||  0000                ||  RAM1                ||
    //  |  20   ||  RAM2    ||  0000                ||  RAM2                ||
    //  | ----- || -------- || -------------------  || -------------------  ||
    //  |  01   ||  RAM0    ||  RAM0                ||  RAM0                ||
    //  |  02   ||  RAM0    ||  RAM0                ||  RAM1                ||
    //  |  03   ||  RAM0    ||  RAM0                ||  RAM2                ||
    //  |  04   ||  RAM0    ||  RAM1                ||  RAM0                ||
    //  |  05   ||  RAM0    ||  RAM1                ||  RAM1                ||
    //  |  06   ||  RAM0    ||  RAM1                ||  RAM2                ||
    //  |  07   ||  RAM0    ||  RAM2                ||  RAM0                ||
    //  |  08   ||  RAM0    ||  RAM2                ||  RAM1                ||
    //  |  09   ||  RAM0    ||  RAM2                ||  RAM2                ||
    //  | ----- || -------- || -------------------  || -------------------  ||
    //  |  11   ||  RAM1    ||  RAM0                ||  RAM0                ||
    //  |  12   ||  RAM1    ||  RAM0                ||  RAM1                ||
    //  |  13   ||  RAM1    ||  RAM0                ||  RAM2                ||
    //  |  14   ||  RAM1    ||  RAM1                ||  RAM0                ||
    //  |  15   ||  RAM1    ||  RAM1                ||  RAM1                ||
    //  |  16   ||  RAM1    ||  RAM1                ||  RAM2                ||
    //  |  17   ||  RAM1    ||  RAM2                ||  RAM0                ||
    //  |  18   ||  RAM1    ||  RAM2                ||  RAM1                ||
    //  |  19   ||  RAM1    ||  RAM2                ||  RAM2                ||
    //  | ----- || -------- || -------------------  || -------------------  ||
    //  |  21   ||  RAM2    ||  RAM0                ||  RAM0                ||
    //  |  22   ||  RAM2    ||  RAM0                ||  RAM1                ||
    //  |  23   ||  RAM2    ||  RAM0                ||  RAM2                ||
    //  |  24   ||  RAM2    ||  RAM1                ||  RAM0                ||
    //  |  25   ||  RAM2    ||  RAM1                ||  RAM1                ||
    //  |  26   ||  RAM2    ||  RAM1                ||  RAM2                ||
    //  |  27   ||  RAM2    ||  RAM2                ||  RAM0                ||
    //  |  28   ||  RAM2    ||  RAM2                ||  RAM1                ||
    //  |  29   ||  RAM2    ||  RAM2                ||  RAM2                ||



endmodule

module MEM_CORE (
    input           clk,
    input   [15:0]  data_in_0,
    input   [15:0]  data_in_1,
    input   [15:0]  data_in_2,
    output  [15:0]  data_out_0,
    output  [15:0]  data_out_1,
    output  [15:0]  data_out_2,
    input   [15:0]  add_0,
    input   [15:0]  add_1,
    input   [15:0]  add_2,
    input           en_w_0,
    input           en_w_1,
    input           en_w_2
);

    RAM #(.SIZE(256*18) ,.WIDTH(16))
    RAM_0 
    (.clk(clk), .en_write(en_w_0), .en_read(1), 
    .addr_write(add_0), .addr_read(add_0),
    .data_in(data_in_0), .data_out(data_out_0));
    
    RAM #(.SIZE(256*18) ,.WIDTH(16))
    RAM_1 
    (.clk(clk), .en_write(en_w_1), .en_read(1), 
    .addr_write(add_1), .addr_read(add_1),
    .data_in(data_in_1), .data_out(data_out_1));
    
    RAM #(.SIZE(256*18) ,.WIDTH(16))
    RAM_2 
    (.clk(clk), .en_write(en_w_2), .en_read(1), 
    .addr_write(add_2), .addr_read(add_2),
    .data_in(data_in_2), .data_out(data_out_2));


endmodule

module DMU_CORE (
    input   wire    [7:0]   deco_concat,
    input                   load_data_in,
    input   wire    [15:0]  data_in,
    input   wire    [15:0]  data_out_0,
    input   wire    [15:0]  data_out_1,
    input   wire    [15:0]  data_out_2,
    output  reg     [31:0]  data_in_core,
    input   wire    [15:0]  data_out_core,
    output  wire    [15:0]  data_in_0,
    output  wire    [15:0]  data_in_1,
    output  wire    [15:0]  data_in_2
    );
    
    
    // No needed to select the data since the en_w is activated following the CODE
    assign data_in_0 = (load_data_in) ? data_in : data_out_core;
    assign data_in_1 = (load_data_in) ? data_in : data_out_core;
    assign data_in_2 = (load_data_in) ? data_in : data_out_core;
    
    always @* begin
        case(deco_concat[3:0])
            4'h0:   begin
                        case(deco_concat[7:4])
                            4'h0: data_in_core = {16'h0000, data_out_0};
                            4'h1: data_in_core = {16'h0000, data_out_1};
                            4'h2: data_in_core = {16'h0000, data_out_2};
                         default: data_in_core = {16'h0000, data_out_0};   
                        endcase
                    end
            4'h1:  data_in_core = {data_out_0, data_out_0};
            4'h2:  data_in_core = {data_out_0, data_out_1};
            4'h3:  data_in_core = {data_out_0, data_out_2};
            4'h4:  data_in_core = {data_out_1, data_out_0};
            4'h5:  data_in_core = {data_out_1, data_out_1};
            4'h6:  data_in_core = {data_out_1, data_out_2};
            4'h7:  data_in_core = {data_out_2, data_out_0};
            4'h8:  data_in_core = {data_out_2, data_out_1};
            4'h9:  data_in_core = {data_out_2, data_out_2};
         default:  data_in_core = {16'h0000, data_out_0};   
        endcase
    
    end
    
    //  CONCATENATE MODE
    //  | CODE  ||  DEST    ||  CONCAT 1 <31:16>    ||  CONCAT 0 <15:00>    ||
    //  | ----  ||  -----   ||  -----------------   ||  ----------------    ||
    //  |  00   ||  RAM0    ||  0000                ||  RAM0                ||
    //  |  10   ||  RAM1    ||  0000                ||  RAM1                ||
    //  |  20   ||  RAM2    ||  0000                ||  RAM2                ||
    //  | ----- || -------- || -------------------  || -------------------  ||
    //  |  01   ||  RAM0    ||  RAM0                ||  RAM0                ||
    //  |  02   ||  RAM0    ||  RAM0                ||  RAM1                ||
    //  |  03   ||  RAM0    ||  RAM0                ||  RAM2                ||
    //  |  04   ||  RAM0    ||  RAM1                ||  RAM0                ||
    //  |  05   ||  RAM0    ||  RAM1                ||  RAM1                ||
    //  |  06   ||  RAM0    ||  RAM1                ||  RAM2                ||
    //  |  07   ||  RAM0    ||  RAM2                ||  RAM0                ||
    //  |  08   ||  RAM0    ||  RAM2                ||  RAM1                ||
    //  |  09   ||  RAM0    ||  RAM2                ||  RAM2                ||
    //  | ----- || -------- || -------------------  || -------------------  ||
    //  |  11   ||  RAM1    ||  RAM0                ||  RAM0                ||
    //  |  12   ||  RAM1    ||  RAM0                ||  RAM1                ||
    //  |  13   ||  RAM1    ||  RAM0                ||  RAM2                ||
    //  |  14   ||  RAM1    ||  RAM1                ||  RAM0                ||
    //  |  15   ||  RAM1    ||  RAM1                ||  RAM1                ||
    //  |  16   ||  RAM1    ||  RAM1                ||  RAM2                ||
    //  |  17   ||  RAM1    ||  RAM2                ||  RAM0                ||
    //  |  18   ||  RAM1    ||  RAM2                ||  RAM1                ||
    //  |  19   ||  RAM1    ||  RAM2                ||  RAM2                ||
    //  | ----- || -------- || -------------------  || -------------------  ||
    //  |  21   ||  RAM2    ||  RAM0                ||  RAM0                ||
    //  |  22   ||  RAM2    ||  RAM0                ||  RAM1                ||
    //  |  23   ||  RAM2    ||  RAM0                ||  RAM2                ||
    //  |  24   ||  RAM2    ||  RAM1                ||  RAM0                ||
    //  |  25   ||  RAM2    ||  RAM1                ||  RAM1                ||
    //  |  26   ||  RAM2    ||  RAM1                ||  RAM2                ||
    //  |  27   ||  RAM2    ||  RAM2                ||  RAM0                ||
    //  |  28   ||  RAM2    ||  RAM2                ||  RAM1                ||
    //  |  29   ||  RAM2    ||  RAM2                ||  RAM2                ||
    
    
endmodule
