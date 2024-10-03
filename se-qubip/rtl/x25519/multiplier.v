/**
  * @file multiplier.v
  * @brief Multiplier Module
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
// Create Date: 22/02/2024
// Design Name: multiplier.v
// Module Name: multiplier
// Project Name: EDSA25519 ECC Accelerator
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		256x256 4-level Karatsuba Multiplier with reduction mod P = 2**255-19
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module multiplier #(
                    parameter BIT_LENGTH = 256,
                    parameter n_LEVEL = 2                   //-- Recursion Levels
                    ) 
                    (
				     input  wire clk,						//-- Clock Signal
				     input  wire rst,						//-- Active High Reset 
				     input  wire redux,                     //-- Reduction option
				     input  wire [BIT_LENGTH-1:0] A,		//-- Operand B
				     input  wire [BIT_LENGTH-1:0] B,		//-- Operand A
				     output wire [2*BIT_LENGTH-1:0] U,		//-- Output product A*B = U mod P or A*B = U
				     output reg  valid						//-- Output data valid
				     );	
	
	
	//--------------------------------------
	//-- Parameters            
	//--------------------------------------

	localparam P = 256'h7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
	
	
	//-------------------------------------------------------
	//-- 256x256 4-level Karatsuba Multiplier with reduction             
	//-------------------------------------------------------
	
	wire ready;
	
	wire [2*BIT_LENGTH-1:0] C;
	
	wire [131:0] C_387_hi;
	wire [254:0] C_387_lo;
	
	assign C_387_hi = C[386:255];
	assign C_387_lo = C[254:0];
	
	karatsuba #(.BIT_LENGTH(BIT_LENGTH), .n_LEVEL(n_LEVEL), .n_LEVEL_0(n_LEVEL)) karatsuba(
							                                                               .clk(clk),
							                                                               .rst(rst),
							                                                               .redux(redux),
							                                                               .A(A),
							                                                               .B(B),
							                                                               .C(C),
							                                                               .valid(ready)
							                                                               ); 
	
	//--------------------------------------------------------------
	//-- 2nd reduction: C_387 = C_hi*2^255 + C_lo = C_hi*19 + C_lo         
	//--------------------------------------------------------------
	
	reg [255:0] C_255;
	
	always @(*) begin
	
		if (rst) begin
			valid    <= 0;
			C_255    <= 0;
		end
		else if (ready)begin
		  	valid <= 1;
		  	// C_255 <= (C_387_hi << 4) + (C_387_hi << 1) + C_387_hi + C_387_lo;
		  	C_255 <= {C_387_hi, 4'h0} + {C_387_hi, 1'b0} + C_387_hi + C_387_lo;
		end   
		else begin
		    valid     <= 0;
		    C_255     <= 0;
		end
	
	end
		
	assign U = (redux == 0) ? C : ((C_255 >= P) ? (C_255 - P) : C_255);
	
endmodule
