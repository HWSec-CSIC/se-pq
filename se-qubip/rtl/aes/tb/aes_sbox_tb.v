/**
  * @file aes_sbox_tb.v
  * @brief AES Sbox TESTBENCH
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
  *         Macarena C. MartÃ­nez-RodrÃ­guez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de MicroelectrÃ³nica de
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

`default_nettype none
`define DUMPSTR(x) `"x.vcd`"
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 19/09/2024
// Design Name: aes_sbox_tb.v
// Module Name: aes_sbox_tb
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES sbox TESTBENCH
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module aes_sbox_tb();
	
	//---------------------------------
	//-- Simulation time
	//---------------------------------
	
	parameter DURATION = 100;
	
	initial
	begin
		#(DURATION) $display("End of simulation");
		$finish;
	end	
	
	
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------
		
	reg  enc;
	reg  [7:0] sbox_in;
	wire [7:0] sbox_out;
	   
			
	//--------------------------------------
	//-- AES sbox Instance
	//--------------------------------------
	
	aes_sbox DUT(
				 .enc(enc),
				 .sbox_in(sbox_in),
				 .sbox_out(sbox_out)
				 ); 
	
	
	//---------------------------------
	//-- Test Values
	//---------------------------------
	
	initial begin
		enc 	= 1'b1;
		sbox_in = 8'h00;
		#10
		sbox_in = 8'hAB;
		#10
		sbox_in = 8'h0D;
		#10
		sbox_in = 8'h8F;
		#10
		sbox_in = 8'h33;
		
		#10
		enc 	= 1'b0;
		sbox_in = 8'h00;
		#10
		sbox_in = 8'hAB;
		#10
		sbox_in = 8'h0D;
		#10
		sbox_in = 8'h8F;
		#10
		sbox_in = 8'h33;
	end
	
	
endmodule
