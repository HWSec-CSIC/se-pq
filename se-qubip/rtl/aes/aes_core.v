/**
  * @file aes_core.v
  * @brief AES Core
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
// Design Name: aes_core.v
// Module Name: aes_core
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES Core
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module aes_core(
				input wire clk,						//-- Clock Signal
				input wire rst,						//-- Active HIGH Reset 
				input wire enc,						//-- Encrypt/Decrypt
				input wire [1:0] aes_len,			//-- 128/192/256 (1,2,3)
				input wire [255:0] key,				//-- Key
				input wire [127:0] plaintext,		//-- Plaintext
				output reg [127:0] ciphertext,		//-- Ciphertext
				output reg valid					//-- Valid Signal
				);
	
	
	//--------------------------------------
	//-- Parameters
	//--------------------------------------
	
	localparam [1:0] AES_128 = 2'b01;
	localparam [1:0] AES_192 = 2'b10;
	localparam [1:0] AES_256 = 2'b11;
	
	localparam AES_128_ROUNDS = 10;
	localparam AES_192_ROUNDS = 12;
	localparam AES_256_ROUNDS = 14;
	
	reg [4:0] aes_rounds;
	
	always @(*) begin
		if (aes_len == AES_128) 
			aes_rounds = AES_128_ROUNDS;
		else if (aes_len == AES_192)
			aes_rounds = AES_192_ROUNDS;
		else 
			aes_rounds = AES_256_ROUNDS;
	end
	
	//------------------------------------------------------------------------------------------------
	//-- Key Schedule
	//------------------------------------------------------------------------------------------------
	
	reg  inv;
	reg  [4:0] round;	
	reg  [15:0] subkey_req;
	wire [127:0] subkey;
	reg  [127:0] subkey_equiv;
	reg  [127:0] subkey_r;     //-- Register to short paths
	reg  [127:0] subkey_w;
	wire [15:0] subkey_idx;
	
	always @(posedge clk) subkey_r <= subkey;
    
    always @(*) begin
        if (enc || round == 5'd0 || round == aes_rounds)
            subkey_w <= subkey_r;
        else
            subkey_w <= subkey_equiv;
    end
    
	aes_keyschedule key_schedule(
								 .clk(clk),
								 .rst(rst),
								 .inv(inv),
								 .aes_len(aes_len),
								 .key(key),
								 .subkey_req(subkey_req),
								 .subkey(subkey),
								 .subkey_idx(subkey_idx)
								 ); 
	
	
	//------------------------------------------------------------------------------------------------
	//-- Key Addition Layer
	//------------------------------------------------------------------------------------------------
	
	reg  [127:0] keyadd_in;
	wire [127:0] keyadd_out;
	
	aes_keyaddition key_addition(
								 .subkey(subkey_w),
								 .state_in(keyadd_in),
								 .state_out(keyadd_out)
								 );
	
	
	//------------------------------------------------------------------------------------------------
	//-- Byte Substitution Layer
	//------------------------------------------------------------------------------------------------
	
	genvar i;
	
	reg  [127:0] sbox_in;
	wire [127:0] sbox_out;
	
	generate for (i = 0; i < 16; i = i + 1) begin
		aes_sbox sbox(
					  .enc(enc),
					  .sbox_in(sbox_in[(127-8*i):(120-8*i)]),
					  .sbox_out(sbox_out[(127-8*i):(120-8*i)])
					  );
	end
	endgenerate
	
	
	//------------------------------------------------------------------------------------------------
	//-- Diffusion Layer
	//------------------------------------------------------------------------------------------------
	
	//-- ShiftRows Sublayer
	reg [127:0] shift_in;
	wire [127:0] shift_out;

	aes_shiftrows shift_rows(
							 .enc(enc),
							 .state_in(shift_in),
							 .state_out(shift_out)
							 );

	//-- MixColumns Sublayer
	reg  [127:0] mixcol_in;
	wire [127:0] mixcol_out;

	generate for (i = 0; i < 4; i = i + 1) begin
		aes_mixcolumns mix_columns(
								   .enc(enc),
								   .vector_in(mixcol_in[(127-32*i):(96-32*i)]),
								   .vector_out(mixcol_out[(127-32*i):(96-32*i)])
								   );
	end
	endgenerate
	
	//-- MixColumns Sublayer for Equivalent Inverse Cipher
	reg  [127:0] mixcol_equiv_in;
    wire [127:0] mixcol_equiv_out;
   
    generate for (i = 0; i < 4; i = i + 1) begin
        aes_mixcolumns_equiv mix_columns_equiv(
                                               .vector_in(mixcol_equiv_in[(127-32*i):(96-32*i)]),
                                               .vector_out(mixcol_equiv_out[(127-32*i):(96-32*i)])
                                               );
    end
    endgenerate
	
	
	//------------------------------------------------------------------------------------------------
	//-- Logic Controller
	//------------------------------------------------------------------------------------------------
	
	reg [127:0] data;
	reg wait_one;
	
	//-- Control Modules I/O
	always @(*) begin
		mixcol_equiv_in   = subkey_r;
		subkey_equiv      = mixcol_equiv_out;  
		
		sbox_in 	      = data;
		shift_in 	      = sbox_out;
		mixcol_in 	      = shift_out;
		
		if ( (enc && round == 0) || (!enc && round == aes_rounds) )
		    keyadd_in = plaintext;
		else if ( (enc && round == aes_rounds) || (!enc && round == 0) )
		    keyadd_in = shift_out;
		else
		    keyadd_in = mixcol_out;
	end
	
	
	//-- FSM States
	localparam IDLE 	= 0;
	localparam ENCRYPT 	= 1;
	localparam INV_KEYS = 2;
	localparam LAST_KEY = 3;
	localparam DECRYPT	= 4;
	localparam END		= 5;
	
	reg [2:0] state;
	
	always @(posedge clk) begin
		
		if (rst) begin
			inv 		<= 1'b0;
			subkey_req 	<= 16'b0000000000000001;
			data 		<= plaintext;
			round		<= 5'b0;
			wait_one    <= 1'b0;
			ciphertext  <= 128'h0;
			valid       <= 1'b0;
			state 		<= IDLE;
		end
		
		else begin
			case (state)
			
			(IDLE): begin

				if (enc) begin
					subkey_req <= {subkey_req[14:0], 1'b0};
					state      <= ENCRYPT;
				end
				else begin
				    round      <= 5'b1;
					subkey_req <= {subkey_req[14:0], 1'b0};
					state      <= INV_KEYS;
				end
			end
				
			(ENCRYPT): begin
				subkey_req <= {subkey_req[14:0], 1'b0};
				round 	   <= round + 1;
				data       <= keyadd_out;
				
				if (round == aes_rounds) begin
				    ciphertext  <= keyadd_out;
				    valid       <= 1'b1;				    
				    state       <= END;
				end
			end
			
			(INV_KEYS): begin
			    subkey_req  <= {subkey_req[14:0], 1'b0};
                round       <= round + 1;
                
                if (aes_len == AES_256) wait_one <= 1;
                    
			    if (round == aes_rounds - 1) begin
                    inv     <= 1'b1;
                    state   <= LAST_KEY;
                end
			end
			
			(LAST_KEY): begin
			    subkey_req   <= {1'b0, subkey_req[15:1]};
			    wait_one     <= 1'b0;
			    
			    if (!wait_one) state <= DECRYPT;
			end
			
			(DECRYPT): begin
			    subkey_req   <= {1'b0, subkey_req[15:1]};
                round        <= round - 1;
                data         <= keyadd_out;
                
			    if (round == 5'b0) begin
                    ciphertext  <= keyadd_out;
                    valid       <= 1'b1;                    
                    state       <= END;
                end
			end

			endcase
		end
		
	end
	
	
	
	
	
endmodule
