/**
  * @file aes_keyschedule.v
  * @brief AES Key Schedule
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

// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 20/09/2024
// Design Name: aes_keyschedule.v
// Module Name: aes_keyschedule
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES Key Schedule
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module aes_keyschedule(
					   input wire clk,						//-- Clock Signal
					   input wire rst,						//-- Active HIGH Reset 
					   input wire inv,						//-- Invert Key Schedule
					   input wire [1:0] aes_len,			//-- 128/192/256 (1,2,3)
					   input wire [255:0] key,				//-- Key
					   input wire [15:0] subkey_req,		//-- Subkey Requested 
					   output reg [127:0] subkey,			//-- Subkey
					   output reg [15:0] subkey_idx			//-- Subkey Index
					   );
	
	
	//------------------------------------------------------------------------------------------------
	//-- AES Key Length
	//------------------------------------------------------------------------------------------------
	
	localparam [1:0] AES_128 = 2'b01;
	localparam [1:0] AES_192 = 2'b10;
	localparam [1:0] AES_256 = 2'b11;
	
	
	//------------------------------------------------------------------------------------------------
	//-- Round Constants
	//------------------------------------------------------------------------------------------------
	
	localparam [79:0] ROUND_CONST = {8'b0000_0001,		//-- RC[1]
									 8'b0000_0010,		//-- RC[2]
									 8'b0000_0100,		//-- RC[3]
									 8'b0000_1000,     	//-- RC[4]
									 8'b0001_0000,     	//-- RC[5]
									 8'b0010_0000,     	//-- RC[6]
									 8'b0100_0000,     	//-- RC[7]
									 8'b1000_0000,     	//-- RC[8]
									 8'b0001_1011,     	//-- RC[9]
									 8'b0011_0110	   	//-- RC[10]
									 };
									 
	wire [7:0] RC [0:15];
	
	assign RC[1]  = ROUND_CONST[79:72];
	assign RC[2]  = ROUND_CONST[71:64];
	assign RC[3]  = ROUND_CONST[63:56];
	assign RC[4]  = ROUND_CONST[55:48];
	assign RC[5]  = ROUND_CONST[47:40];
	assign RC[6]  = ROUND_CONST[39:32];
	assign RC[7]  = ROUND_CONST[31:24];
	assign RC[8]  = ROUND_CONST[23:16];
	assign RC[9]  = ROUND_CONST[15:8];
	assign RC[10] = ROUND_CONST[7:0];
	//-- Used for Inversion
	assign RC[0]  = 8'b0;
	assign RC[11] = 8'b0;
	assign RC[12] = 8'b0;
	assign RC[13] = 8'b0;
	assign RC[14] = 8'b0;
	assign RC[15] = 8'b0;
	
	//------------------------------------------------------------------------------------------------
	//-- Wires & Registers
	//------------------------------------------------------------------------------------------------
	
	//-- Next Subkey for AES-192-256
	reg [127:0] next_subkey;
	
	//-- Round Constant Wire and Counter
	reg  [3:0] RC_counter;
	wire [7:0] RC_w;
	assign RC_w = RC[RC_counter];
	
	//-- State of the Words of the Subkey Generation
	reg  [255:0] W_in;
	wire [255:0] W_out;
	
	//-- First Subkey and Second Subkey generated signal for AES-192-256
	reg first_subkey;
	reg second_subkey;
	
	//-- Subkey Requesting (Request is valid?)
	wire req_valid;
	//-- If at least one of the bits on the same position is set on both then 1 otherwise 0
	assign req_valid = |(subkey_req & subkey_idx);
	
	
	//------------------------------------------------------------------------------------------------
	//-- Key Schedule Round Instance
	//------------------------------------------------------------------------------------------------
	
	aes_keyround key_round(
						   .clk(clk),
						   .rst(rst),
						   .inv(inv),
						   .aes_len(aes_len),
						   .RC(RC_w),
						   .W_in(W_in),
						   .W_out(W_out)
						   );
	
	
	//------------------------------------------------------------------------------------------------
	//-- Logic Controller
	//------------------------------------------------------------------------------------------------
	
	always @(*) begin
		//-- Reset Condition
		if (rst)
			subkey = key[255:128];
		//-- AES-128
		else if (aes_len == AES_128)
			subkey = W_in[255:128];
		//-- AES-192
		else if (aes_len == AES_192 && first_subkey && !inv)
			subkey = W_in[255:128];
		else if (aes_len == AES_192 && second_subkey && !inv)
			subkey = next_subkey;
		else if (aes_len == AES_192 && !inv)
			subkey = W_in[191:64];
		else if (aes_len == AES_192 && first_subkey)
            subkey = W_in[255:128];
        else if (aes_len == AES_192 && second_subkey)
            subkey = W_in[191:64];
        else if (aes_len == AES_192)
            subkey = next_subkey;
		//-- AES-256
		else if (/*aes_len == AES_256 &&*/ first_subkey && !inv)
			subkey = W_in[255:128];
		else if (/*aes_len == AES_256 &&*/ !inv)
			subkey = W_in[127:0];
		else if (/*aes_len == AES_256 &&*/ first_subkey)
			subkey = W_in[127:0];
		else/* if (aes_len == AES_256)*/
			subkey = W_in[255:128];
		//-- Else Condition
		/*
		else 
			subkey = key;*/
	end
	
	always @(posedge clk) begin
		//-- Reset Condition
		if (rst) begin
			subkey_idx 		<= 16'b0000000000000001;
			next_subkey		<= 128'h0;
			RC_counter	  	<= 4'b1;
			W_in		  	<= key;
			first_subkey	<= 1'b1;	
			second_subkey	<= 1'b0;
		end
		
		//-- AES-128
		else if (aes_len == AES_128 && req_valid) begin
			//-- Feedback for the next Round
			W_in <= W_out;
			//-- Increment/Decrement RC Counters
			if (!inv && (RC_counter < 10))
                 RC_counter <= RC_counter + 1;
            else if (inv)
                 RC_counter <= RC_counter - 1;
		end
		
		//-- AES-192
		//-- 1st Subkey
		else if (aes_len == AES_192 && req_valid && first_subkey) begin
			//-- Feedback for the next Round
			W_in			<= W_out;
			//-- Increment/Decrement RC Counter
			if (!inv && (RC_counter < 8))
                 RC_counter <= RC_counter + 1;
            else if (inv)
                 RC_counter <= RC_counter - 1;
			//-- 1st and 2nd Subkey Signals
			first_subkey	<= 1'b0;
			second_subkey	<= 1'b1;
			//-- Store 2nd Subkey
			if (!inv) next_subkey <= {W_in[127:64], W_out[255:192]};
			
		end
		//-- 2nd Subkey
		else if (aes_len == AES_192 && req_valid && second_subkey) begin
			//-- 2nd Subkey Signal
			second_subkey <= 1'b0;
			if (inv) next_subkey <= {W_out[127:64], W_in[255:192]};
		end
		//-- 3rd Subkey
		else if (aes_len == AES_192 && req_valid) begin
			//-- Feedback for the next Round
			W_in <= W_out;
			//-- Increment/Decrement RC Counter
			if (!inv  && (RC_counter < 8))
                 RC_counter <= RC_counter + 1;
            else if (inv)
                 RC_counter <= RC_counter - 1;
			//-- 2nd Subkey Signal
			first_subkey <= 1'b1;
		end
		
		//-- AES-256
		//-- 1st Subkey
		else if (aes_len == AES_256 && req_valid && first_subkey) begin
			//-- 1st Subkey Signal
			first_subkey <= 1'b0;
		end
		//-- 2nd Subkey 
		else if (aes_len == AES_256 && req_valid) begin
			//-- Feedback for the next Round
			W_in <= W_out;
			//-- Increment/Decrement RC Counter
			if (!inv && (RC_counter < 7))
			     RC_counter	<= RC_counter + 1;
			else if (inv)
			     RC_counter	<= RC_counter - 1;
			//-- 1st Subkey Signal
			first_subkey <= 1'b1;
		end
	   
	   //-- If Request Signal is valid shift Subkey Index
	    if (!rst && req_valid && !inv) 
            subkey_idx <= {subkey_idx[14:0], 1'b0};
		//-- If inv then shift in the opposite direction
		else if (!rst && req_valid)
			subkey_idx <= {1'b0, subkey_idx[15:1]};
			
	end
	
	
endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-- Key Schedule Round
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module aes_keyround(
					input  wire clk,
					input  wire rst, 
					input  wire inv,
					input  wire [1:0] aes_len,
					input  wire [7:0] RC,
					input  wire [255:0] W_in,
					output wire [255:0] W_out
					);
	
	
	//-- AES Key Length
	localparam [1:0] AES_128 = 2'b01;
	localparam [1:0] AES_192 = 2'b10;
	localparam [1:0] AES_256 = 2'b11;
	
	//-- Words Separation
	wire [31:0] W0, W1, W2, W3, W4, W5, W6, W7;				//-- Input Words
	reg  [31:0] W8, W9, W10, W11, W12, W13, W14, W15;		//-- Output Words
	
	assign W0 = W_in[255:224];
	assign W1 = W_in[223:192];
	assign W2 = W_in[191:160];
	assign W3 = W_in[159:128];
	assign W4 = W_in[127:96];
	assign W5 = W_in[95:64];
	assign W6 = W_in[63:32];
	assign W7 = W_in[31:0];
	
	//-- G-Function
	wire [31:0] g_out;
	reg [31:0] g_in;
	
	always @(*) begin
		if (!inv && aes_len == AES_128)
			g_in = W3;
		else if (!inv && aes_len == AES_192)
			g_in = W5;
		else if (!inv)
			g_in = W7;
		else if (aes_len == AES_128)
			g_in = W11;
		else if (aes_len == AES_192)
			g_in = W13;
		else 
			g_in = W15;
	end
	
	// Revisit the registers for timing issues
	
	aes_gfun G_Function(
						.RC(RC),
						.word_in(g_in), 
						.word_out(g_out)
						);
	
	//-- H-Function
	reg  [31:0] h_in;
	wire [31:0] h_out;
	
	always @(posedge clk) begin
		if (rst)
			h_in <= 32'h0;
		else if (!inv)
			h_in <= W11;
		else
			h_in <= W3;
	end
	
	aes_hfun H_Function(
						.word_in(h_in), 
						.word_out(h_out)
						);
	
	//-- Words Output
	always @(*) begin
		if (!inv) begin
			W8  = W0  ^ g_out;
			W9  = W8  ^ W1;
			W10 = W9  ^ W2;
			W11 = W10 ^ W3;
			W12 = (aes_len == AES_192) ? (W11 ^ W4) : (h_out ^ W4);
			W13 = W12 ^ W5;
			W14 = W13 ^ W6;
			W15 = W14 ^ W7;
		end
		else begin
			W15 = W7 ^ W6;
			W14 = W6 ^ W5;
			W13 = W5 ^ W4;
			W12 = (aes_len == AES_192) ? (W4 ^ W3) : (h_out ^ W4);
			W11 = W3 ^ W2;
			W10 = W2 ^ W1;
			W9  = W1 ^ W0;
			W8  = W0 ^ g_out;		
		end
	end

	assign W_out = {W8, W9, W10, W11, W12, W13, W14, W15};
	

endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-- G-Function
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module aes_gfun(
				input  wire [7:0] RC,			//-- Round Coefficients
				input  wire [31:0] word_in,
				output wire [31:0] word_out
				);
	
	//-- Word Input Rotation
	wire [7:0] V3, V2, V1, V0;
	
	assign V3 = word_in[23:16];
	assign V2 = word_in[15:8];
	assign V1 = word_in[7:0];
	assign V0 = word_in[31:24];
	
	//-- 4 sboxes
	wire [7:0] S3, S2, S1, S0;
	
	aes_sbox sbox_3(
					.enc(1'b1),
					.sbox_in(V3),
					.sbox_out(S3)
					);

	aes_sbox sbox_2(
					.enc(1'b1),
					.sbox_in(V2),
					.sbox_out(S2)
					);
	
	aes_sbox sbox_1(
					.enc(1'b1),
					.sbox_in(V1),
					.sbox_out(S1)
					);
					
	aes_sbox sbox_0(
					.enc(1'b1),
					.sbox_in(V0),
					.sbox_out(S0)
					);

	//-- Word Output
	assign word_out = {S3 ^ RC, S2, S1, S0};


endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-- H-Function
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module aes_hfun(	
				input  wire [31:0] word_in,
				output wire [31:0] word_out
				);
	
	//-- Word Input
	wire [7:0] V3, V2, V1, V0;
	
	assign V3 = word_in[31:24];
	assign V2 = word_in[23:16];
	assign V1 = word_in[15:8];
	assign V0 = word_in[7:0];
	
	//-- 4 sboxes
	wire [7:0] S3, S2, S1, S0;
	
	aes_sbox sbox_3(
					.enc(1'b1),
					.sbox_in(V3),
					.sbox_out(S3)
					);

	aes_sbox sbox_2(
					.enc(1'b1),
					.sbox_in(V2),
					.sbox_out(S2)
					);
	
	aes_sbox sbox_1(
					.enc(1'b1),
					.sbox_in(V1),
					.sbox_out(S1)
					);
					
	aes_sbox sbox_0(
					.enc(1'b1),
					.sbox_in(V0),
					.sbox_out(S0)
					);

	//-- Word Output
	assign word_out = {S3, S2, S1, S0};


endmodule
