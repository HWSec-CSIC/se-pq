/**
  * @file aes_mixcolumns_equiv.v
  * @brief AES Inverse MixColumns Sublayer
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
// Create Date: 26/09/2024
// Design Name: aes_mixcolumns_equiv.v
// Module Name: aes_mixcolumns_equiv
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES Inverse MixColumns Sublayer based on:
//
//		https://ieeexplore.ieee.org/abstract/document/1465666
//      https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.197.pdf
//
// Additional Comment:
//
//		Only includes inverted mode as it it is used for the equivalent inverse cipher
//
////////////////////////////////////////////////////////////////////////////////////


module aes_mixcolumns_equiv(
							input  wire [31:0] vector_in,		//-- Input Data
							output wire [31:0] vector_out		//-- Output Data
							);
  
    
    //------------------------------------------------------------------------------------------------
	//-- MixColumns Sublayer    
	//------------------------------------------------------------------------------------------------
	
	wire [7:0] B3, B2, B1, B0;
	wire [7:0] C3, C2, C1, C0;
	
	assign B3 = vector_in[31:24];
	assign B2 = vector_in[23:16];
	assign B1 = vector_in[15:8];
	assign B0 = vector_in[7:0];
	
	//-- Matrix Product Generators
	wire [7:0] x09_3, x09_2, x09_1, x09_0;
	wire [7:0] x0B_3, x0B_2, x0B_1, x0B_0;
	wire [7:0] x0D_3, x0D_2, x0D_1, x0D_0;
	wire [7:0] x0E_3, x0E_2, x0E_1, x0E_0;
	
	aes_matprod_gen_equiv product_generator_3(
										      .vec_in(B3),
										      .x09(x09_3),
										      .x0B(x0B_3),
										      .x0D(x0D_3),
										      .x0E(x0E_3)
										      );
	
	aes_matprod_gen_equiv product_generator_2(
										      .vec_in(B2),
										      .x09(x09_2),
										      .x0B(x0B_2),
										      .x0D(x0D_2),
										      .x0E(x0E_2)
										      );
	
	aes_matprod_gen_equiv product_generator_1(
										      .vec_in(B1),
										      .x09(x09_1),
										      .x0B(x0B_1),
										      .x0D(x0D_1),
										      .x0E(x0E_1)
										      );
										
	aes_matprod_gen_equiv product_generator_0(
										      .vec_in(B0),
										      .x09(x09_0),
										      .x0B(x0B_0),
										      .x0D(x0D_0),
										      .x0E(x0E_0)
										      );
									
	
	assign C3 = x0E_3 ^ x0B_2 ^ x0D_1 ^ x09_0;
	assign C2 = x09_3 ^ x0E_2 ^ x0B_1 ^ x0D_0;
	assign C1 = x0D_3 ^ x09_2 ^ x0E_1 ^ x0B_0;
	assign C0 = x0B_3 ^ x0D_2 ^ x09_1 ^ x0E_0;

	assign vector_out = {C3, C2, C1, C0};

	
endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-- Matrix Product Generator
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module aes_matprod_gen_equiv(
					         input  wire [7:0] vec_in,	//-- Vector Element Input a
					         output wire [7:0] x09,		//-- a*09
					         output wire [7:0] x0B,		//-- a*0B
					         output wire [7:0] x0D,   	//-- a*0D
					         output wire [7:0] x0E    	//-- a*0E
					         );
	
	
	//-- Multiplication by constant polynomial x^n:
	wire [7:0] x01;
	wire [7:0] x02;
	wire [7:0] x04;
	wire [7:0] x08;
	
	aes_x2n_equiv x2n(
				      .vec_in(vec_in),
				      .x01(x01),
				      .x02(x02),
				      .x04(x04),
				      .x08(x08)
				      );
	
	assign x09 = x01 ^ x08;
	assign x0B = x02 ^ x09;
	assign x0D = x04 ^ x09;
	assign x0E = x02 ^ x04 ^ x08;


endmodule	


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-- Multiplication by constant polynomial x^n: a*x^n, 0 <= n <= 3  ({ a*01, a*02, a*04, a*08})
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module aes_x2n_equiv(
			         input  wire [7:0] vec_in,
			         output wire [7:0] x01,
			         output wire [7:0] x02,
			         output wire [7:0] x04,
			         output wire [7:0] x08
			         );
	
	
	//-- Identity Multiplication
	assign x01 = vec_in;
	
	//-- Multiplication by x
	aes_x2_equiv x2_1(
				      .x2_in(vec_in),
				      .x2_out(x02)
				      );
	
	//-- Multiplication by x^2
	aes_x2_equiv x2_2(
				      .x2_in(x02),
				      .x2_out(x04)
				      );
	
	//-- Multiplication by x^3
	aes_x2_equiv x2_3(
				      .x2_in(x04),
				      .x2_out(x08)
				      );

endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-- Multiplication by constant polynomial x: a*x (a*02)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module aes_x2_equiv(
			        input  wire [7:0] x2_in,
			        output wire [7:0] x2_out
			        );
			  
	assign x2_out = {x2_in[6], x2_in[5], x2_in[4], x2_in[3] ^ x2_in[7], x2_in[2] ^ x2_in[7], x2_in[1], x2_in[0] ^ x2_in[7], x2_in[7]};


endmodule

