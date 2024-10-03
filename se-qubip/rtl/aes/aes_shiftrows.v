/**
  * @file aes_shiftrows.v
  * @brief AES ShiftRows Sublayer  
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
// Create Date: 19/09/2024
// Design Name: aes_shiftrows.v
// Module Name: aes_shiftrows
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES ShiftRows Sublayer  
//
// Additional Comment
//
//		Encrypt:
//
//			State:						New State:	
//                          	   
//		B0	B4	B8	B12 	 |		B0	B4	B8	B12
//		B1	B5 	B9	B13 	 |   	B5	B9 	B13	B1
//		B2	B6	B10	B14 	 |   	B10	B14	B2	B6
//		B3	B7	B11	B15		 |   	B15	B3	B7	B11
//
//		state_in  = {B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10,B11,B12,B13,B14,B15}
//		state_out = {B0,B5,B10,B15,B4,B9,B14,B3,B8,B13,B2,B7,B12,B1,B6,B11}
//
//
//		Decrypt:
//
//			State:						New State:	
//                          	   
//		B0	B4	B8	B12 	 |		B0	B4	B8	B12
//		B1	B5 	B9	B13 	 |   	B13	B1 	B5	B9
//		B2	B6	B10	B14 	 |   	B10	B14	B2	B6
//		B3	B7	B11	B15		 |   	B7	B11	B15	B3
//
//		state_in  = {B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10,B11,B12,B13,B14,B15}
//		state_out = {B0,B13,B10,B7,B4,B1,B14,B11,B8,B5,B2,B15,B12,B9,B6,B3}
//
//
////////////////////////////////////////////////////////////////////////////////////


module aes_shiftrows(
					 input  wire enc,					//-- Encryption -> 1 | Decryption -> 0 
					 input  wire [127:0] state_in,		//-- Input Data
					 output wire [127:0] state_out		//-- Output Data
					 );
	
	
	//------------------------------------------------------------------------------------------------
	//-- Subdivide I/O in byte blocks
	//------------------------------------------------------------------------------------------------
    
	wire [7:0] B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, B10, B11, B12, B13, B14, B15;
	
	assign B0   = state_in[127:120];
	assign B1   = state_in[119:112];
	assign B2   = state_in[111:104];
	assign B3   = state_in[103:96];
	assign B4   = state_in[95:88];
	assign B5   = state_in[87:80];
	assign B6   = state_in[79:72];
	assign B7   = state_in[71:64];
	assign B8   = state_in[63:56];
	assign B9   = state_in[55:48];
	assign B10  = state_in[47:40];
	assign B11  = state_in[39:32];
	assign B12  = state_in[31:24];
	assign B13  = state_in[23:16];
	assign B14  = state_in[15:8];
	assign B15  = state_in[7:0];
	
	
    //------------------------------------------------------------------------------------------------
	//-- ShiftRows Sublayer    
	//------------------------------------------------------------------------------------------------
	
	assign state_out = (enc) ? {B0,B5,B10,B15,B4,B9,B14,B3,B8,B13,B2,B7,B12,B1,B6,B11}
								
								:
								
							   {B0,B13,B10,B7,B4,B1,B14,B11,B8,B5,B2,B15,B12,B9,B6,B3};
								 
	
endmodule
