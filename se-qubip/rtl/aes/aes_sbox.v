/**
  * @file aes_sbox.v
  * @brief AES sbox
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
// Design Name: aes_sbox.v
// Module Name: aes_sbox
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES sbox based on:
//
//		https://ieeexplore.ieee.org/abstract/document/10479622
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module aes_sbox (
				 input  wire enc,				//-- Encryption -> 1 | Decryption -> 0 
				 input  wire [7:0] sbox_in,		//-- Input Data
				 output wire [7:0] sbox_out		//-- Output Data
				 );
  
    
    //------------------------------------------------------------------------------------------------
	//-- Inverse Affine Transformation        
	//------------------------------------------------------------------------------------------------
	
	//-- Affine Inverse Output
	wire [7:0] aff_inv_out;
	
	assign aff_inv_out = {
						  sbox_in[6] ^ sbox_in[4] ^ sbox_in[1],
						  sbox_in[5] ^ sbox_in[3] ^ sbox_in[0],
						  sbox_in[7] ^ sbox_in[4] ^ sbox_in[2],
						  sbox_in[6] ^ sbox_in[3] ^ sbox_in[1],
						  sbox_in[5] ^ sbox_in[2] ^ sbox_in[0],
					      sbox_in[7] ^ sbox_in[4] ^ sbox_in[1] ^ 1'b1,
					      sbox_in[6] ^ sbox_in[3] ^ sbox_in[0],
					      sbox_in[7] ^ sbox_in[5] ^ sbox_in[2] ^ 1'b1
																     };
	
	
	//------------------------------------------------------------------------------------------------
	//-- Inversion GF(2^8)        
	//------------------------------------------------------------------------------------------------
	
	//-- Inversion Input
	wire [7:0] inv_in;
	
	//-- Multiplexer
	// assign inv_in = (enc) ? sbox_in : aff_inv_out;
	genvar i;
	
	generate for (i = 0; i < 8; i = i + 1) begin
	   MUXF8 MUXF8_inv_in(
                          .O(inv_in[i]),        // Output of MUX to general routing
                          .I0(aff_inv_out[i]),  // Input (tie to MUXF7 L/LO out)
                          .I1(sbox_in[i]),      // Input (tie to MUXF7 L/LO out)
                          .S(enc)               // Input select to MUX
                          );
    end 
    endgenerate
	
	//-- 256x8 bits inversion ROM
	// wire [7:0] inv_ROM [0:255];
    /*
    assign inv_ROM[8'h00] = 8'h00;
    assign inv_ROM[8'h01] = 8'h01;
    assign inv_ROM[8'h02] = 8'h8D;
    assign inv_ROM[8'h03] = 8'hF6;
    assign inv_ROM[8'h04] = 8'hCB;
    assign inv_ROM[8'h05] = 8'h52;
    assign inv_ROM[8'h06] = 8'h7B;
    assign inv_ROM[8'h07] = 8'hD1;
    assign inv_ROM[8'h08] = 8'hE8;
    assign inv_ROM[8'h09] = 8'h4F;
    assign inv_ROM[8'h0A] = 8'h29;
    assign inv_ROM[8'h0B] = 8'hC0;
    assign inv_ROM[8'h0C] = 8'hB0;
    assign inv_ROM[8'h0D] = 8'hE1;
    assign inv_ROM[8'h0E] = 8'hE5;
    assign inv_ROM[8'h0F] = 8'hC7;
    assign inv_ROM[8'h10] = 8'h74;
    assign inv_ROM[8'h11] = 8'hB4;
    assign inv_ROM[8'h12] = 8'hAA;
    assign inv_ROM[8'h13] = 8'h4B;
    assign inv_ROM[8'h14] = 8'h99;
    assign inv_ROM[8'h15] = 8'h2B;
    assign inv_ROM[8'h16] = 8'h60;
    assign inv_ROM[8'h17] = 8'h5F;
    assign inv_ROM[8'h18] = 8'h58;
    assign inv_ROM[8'h19] = 8'h3F;
    assign inv_ROM[8'h1A] = 8'hFD;
    assign inv_ROM[8'h1B] = 8'hCC;
    assign inv_ROM[8'h1C] = 8'hFF;
    assign inv_ROM[8'h1D] = 8'h40;
    assign inv_ROM[8'h1E] = 8'hEE;
    assign inv_ROM[8'h1F] = 8'hB2;
    assign inv_ROM[8'h20] = 8'h3A;
    assign inv_ROM[8'h21] = 8'h6E;
    assign inv_ROM[8'h22] = 8'h5A;
    assign inv_ROM[8'h23] = 8'hF1;
    assign inv_ROM[8'h24] = 8'h55;
    assign inv_ROM[8'h25] = 8'h4D;
    assign inv_ROM[8'h26] = 8'hA8;
    assign inv_ROM[8'h27] = 8'hC9;
    assign inv_ROM[8'h28] = 8'hC1;
    assign inv_ROM[8'h29] = 8'h0A;
    assign inv_ROM[8'h2A] = 8'h98;
    assign inv_ROM[8'h2B] = 8'h15;
    assign inv_ROM[8'h2C] = 8'h30;
    assign inv_ROM[8'h2D] = 8'h44;
    assign inv_ROM[8'h2E] = 8'hA2;
    assign inv_ROM[8'h2F] = 8'hC2;
    assign inv_ROM[8'h30] = 8'h2C;
    assign inv_ROM[8'h31] = 8'h45;
    assign inv_ROM[8'h32] = 8'h92;
    assign inv_ROM[8'h33] = 8'h6C;
    assign inv_ROM[8'h34] = 8'hF3;
    assign inv_ROM[8'h35] = 8'h39;
    assign inv_ROM[8'h36] = 8'h66;
    assign inv_ROM[8'h37] = 8'h42;
    assign inv_ROM[8'h38] = 8'hF2;
    assign inv_ROM[8'h39] = 8'h35;
    assign inv_ROM[8'h3A] = 8'h20;
    assign inv_ROM[8'h3B] = 8'h6F;
    assign inv_ROM[8'h3C] = 8'h77;
    assign inv_ROM[8'h3D] = 8'hBB;
    assign inv_ROM[8'h3E] = 8'h59;
    assign inv_ROM[8'h3F] = 8'h19;
    assign inv_ROM[8'h40] = 8'h1D;
    assign inv_ROM[8'h41] = 8'hFE;
    assign inv_ROM[8'h42] = 8'h37;
    assign inv_ROM[8'h43] = 8'h67;
    assign inv_ROM[8'h44] = 8'h2D;
    assign inv_ROM[8'h45] = 8'h31;
    assign inv_ROM[8'h46] = 8'hF5;
    assign inv_ROM[8'h47] = 8'h69;
    assign inv_ROM[8'h48] = 8'hA7;
    assign inv_ROM[8'h49] = 8'h64;
    assign inv_ROM[8'h4A] = 8'hAB;
    assign inv_ROM[8'h4B] = 8'h13;
    assign inv_ROM[8'h4C] = 8'h54;
    assign inv_ROM[8'h4D] = 8'h25;
    assign inv_ROM[8'h4E] = 8'hE9;
    assign inv_ROM[8'h4F] = 8'h09;
    assign inv_ROM[8'h50] = 8'hED;
    assign inv_ROM[8'h51] = 8'h5C;
    assign inv_ROM[8'h52] = 8'h05;
    assign inv_ROM[8'h53] = 8'hCA;
    assign inv_ROM[8'h54] = 8'h4C;
    assign inv_ROM[8'h55] = 8'h24;
    assign inv_ROM[8'h56] = 8'h87;
    assign inv_ROM[8'h57] = 8'hBF;
    assign inv_ROM[8'h58] = 8'h18;
    assign inv_ROM[8'h59] = 8'h3E;
    assign inv_ROM[8'h5A] = 8'h22;
    assign inv_ROM[8'h5B] = 8'hF0;
    assign inv_ROM[8'h5C] = 8'h51;
    assign inv_ROM[8'h5D] = 8'hEC;
    assign inv_ROM[8'h5E] = 8'h61;
    assign inv_ROM[8'h5F] = 8'h17;
    assign inv_ROM[8'h60] = 8'h16;
    assign inv_ROM[8'h61] = 8'h5E;
    assign inv_ROM[8'h62] = 8'hAF;
    assign inv_ROM[8'h63] = 8'hD3;
    assign inv_ROM[8'h64] = 8'h49;
    assign inv_ROM[8'h65] = 8'hA6;
    assign inv_ROM[8'h66] = 8'h36;
    assign inv_ROM[8'h67] = 8'h43;
    assign inv_ROM[8'h68] = 8'hF4;
    assign inv_ROM[8'h69] = 8'h47;
    assign inv_ROM[8'h6A] = 8'h91;
    assign inv_ROM[8'h6B] = 8'hDF;
    assign inv_ROM[8'h6C] = 8'h33;
    assign inv_ROM[8'h6D] = 8'h93;
    assign inv_ROM[8'h6E] = 8'h21;
    assign inv_ROM[8'h6F] = 8'h3B;
    assign inv_ROM[8'h70] = 8'h79;
    assign inv_ROM[8'h71] = 8'hB7;
    assign inv_ROM[8'h72] = 8'h97;
    assign inv_ROM[8'h73] = 8'h85;
    assign inv_ROM[8'h74] = 8'h10;
    assign inv_ROM[8'h75] = 8'hB5;
    assign inv_ROM[8'h76] = 8'hBA;
    assign inv_ROM[8'h77] = 8'h3C;
    assign inv_ROM[8'h78] = 8'hB6;
    assign inv_ROM[8'h79] = 8'h70;
    assign inv_ROM[8'h7A] = 8'hD0;
    assign inv_ROM[8'h7B] = 8'h06;
    assign inv_ROM[8'h7C] = 8'hA1;
    assign inv_ROM[8'h7D] = 8'hFA;
    assign inv_ROM[8'h7E] = 8'h81;
    assign inv_ROM[8'h7F] = 8'h82;
    assign inv_ROM[8'h80] = 8'h83;
    assign inv_ROM[8'h81] = 8'h7E;
    assign inv_ROM[8'h82] = 8'h7F;
    assign inv_ROM[8'h83] = 8'h80;
    assign inv_ROM[8'h84] = 8'h96;
    assign inv_ROM[8'h85] = 8'h73;
    assign inv_ROM[8'h86] = 8'hBE;
    assign inv_ROM[8'h87] = 8'h56;
    assign inv_ROM[8'h88] = 8'h9B;
    assign inv_ROM[8'h89] = 8'h9E;
    assign inv_ROM[8'h8A] = 8'h95;
    assign inv_ROM[8'h8B] = 8'hD9;
    assign inv_ROM[8'h8C] = 8'hF7;
    assign inv_ROM[8'h8D] = 8'h02;
    assign inv_ROM[8'h8E] = 8'hB9;
    assign inv_ROM[8'h8F] = 8'hA4;
    assign inv_ROM[8'h90] = 8'hDE;
    assign inv_ROM[8'h91] = 8'h6A;
    assign inv_ROM[8'h92] = 8'h32;
    assign inv_ROM[8'h93] = 8'h6D;
    assign inv_ROM[8'h94] = 8'hD8;
    assign inv_ROM[8'h95] = 8'h8A;
    assign inv_ROM[8'h96] = 8'h84;
    assign inv_ROM[8'h97] = 8'h72;
    assign inv_ROM[8'h98] = 8'h2A;
    assign inv_ROM[8'h99] = 8'h14;
    assign inv_ROM[8'h9A] = 8'h9F;
    assign inv_ROM[8'h9B] = 8'h88;
    assign inv_ROM[8'h9C] = 8'hF9;
    assign inv_ROM[8'h9D] = 8'hDC;
    assign inv_ROM[8'h9E] = 8'h89;
    assign inv_ROM[8'h9F] = 8'h9A;
    assign inv_ROM[8'hA0] = 8'hFB;
    assign inv_ROM[8'hA1] = 8'h7C;
    assign inv_ROM[8'hA2] = 8'h2E;
    assign inv_ROM[8'hA3] = 8'hC3;
    assign inv_ROM[8'hA4] = 8'h8F;
    assign inv_ROM[8'hA5] = 8'hB8;
    assign inv_ROM[8'hA6] = 8'h65;
    assign inv_ROM[8'hA7] = 8'h48;
    assign inv_ROM[8'hA8] = 8'h26;
    assign inv_ROM[8'hA9] = 8'hC8;
    assign inv_ROM[8'hAA] = 8'h12;
    assign inv_ROM[8'hAB] = 8'h4A;
    assign inv_ROM[8'hAC] = 8'hCE;
    assign inv_ROM[8'hAD] = 8'hE7;
    assign inv_ROM[8'hAE] = 8'hD2;
    assign inv_ROM[8'hAF] = 8'h62;
    assign inv_ROM[8'hB0] = 8'h0C;
    assign inv_ROM[8'hB1] = 8'hE0;
    assign inv_ROM[8'hB2] = 8'h1F;
    assign inv_ROM[8'hB3] = 8'hEF;
    assign inv_ROM[8'hB4] = 8'h11;
    assign inv_ROM[8'hB5] = 8'h75;
    assign inv_ROM[8'hB6] = 8'h78;
    assign inv_ROM[8'hB7] = 8'h71;
    assign inv_ROM[8'hB8] = 8'hA5;
    assign inv_ROM[8'hB9] = 8'h8E;
    assign inv_ROM[8'hBA] = 8'h76;
    assign inv_ROM[8'hBB] = 8'h3D;
    assign inv_ROM[8'hBC] = 8'hBD;
    assign inv_ROM[8'hBD] = 8'hBC;
    assign inv_ROM[8'hBE] = 8'h86;
    assign inv_ROM[8'hBF] = 8'h57;
    assign inv_ROM[8'hC0] = 8'h0B;
    assign inv_ROM[8'hC1] = 8'h28;
    assign inv_ROM[8'hC2] = 8'h2F;
    assign inv_ROM[8'hC3] = 8'hA3;
    assign inv_ROM[8'hC4] = 8'hDA;
    assign inv_ROM[8'hC5] = 8'hD4;
    assign inv_ROM[8'hC6] = 8'hE4;
    assign inv_ROM[8'hC7] = 8'h0F;
    assign inv_ROM[8'hC8] = 8'hA9;
    assign inv_ROM[8'hC9] = 8'h27;
    assign inv_ROM[8'hCA] = 8'h53;
    assign inv_ROM[8'hCB] = 8'h04;
    assign inv_ROM[8'hCC] = 8'h1B;
    assign inv_ROM[8'hCD] = 8'hFC;
    assign inv_ROM[8'hCE] = 8'hAC;
    assign inv_ROM[8'hCF] = 8'hE6;
    assign inv_ROM[8'hD0] = 8'h7A;
    assign inv_ROM[8'hD1] = 8'h07;
    assign inv_ROM[8'hD2] = 8'hAE;
    assign inv_ROM[8'hD3] = 8'h63;
    assign inv_ROM[8'hD4] = 8'hC5;
    assign inv_ROM[8'hD5] = 8'hDB;
    assign inv_ROM[8'hD6] = 8'hE2;
    assign inv_ROM[8'hD7] = 8'hEA;
    assign inv_ROM[8'hD8] = 8'h94;
    assign inv_ROM[8'hD9] = 8'h8B;
    assign inv_ROM[8'hDA] = 8'hC4;
    assign inv_ROM[8'hDB] = 8'hD5;
    assign inv_ROM[8'hDC] = 8'h9D;
    assign inv_ROM[8'hDD] = 8'hF8;
    assign inv_ROM[8'hDE] = 8'h90;
    assign inv_ROM[8'hDF] = 8'h6B;
    assign inv_ROM[8'hE0] = 8'hB1;
    assign inv_ROM[8'hE1] = 8'h0D;
    assign inv_ROM[8'hE2] = 8'hD6;
    assign inv_ROM[8'hE3] = 8'hEB;
    assign inv_ROM[8'hE4] = 8'hC6;
    assign inv_ROM[8'hE5] = 8'h0E;
    assign inv_ROM[8'hE6] = 8'hCF;
    assign inv_ROM[8'hE7] = 8'hAD;
    assign inv_ROM[8'hE8] = 8'h08;
    assign inv_ROM[8'hE9] = 8'h4E;
    assign inv_ROM[8'hEA] = 8'hD7;
    assign inv_ROM[8'hEB] = 8'hE3;
    assign inv_ROM[8'hEC] = 8'h5D;
    assign inv_ROM[8'hED] = 8'h50;
    assign inv_ROM[8'hEE] = 8'h1E;
    assign inv_ROM[8'hEF] = 8'hB3;
    assign inv_ROM[8'hF0] = 8'h5B;
    assign inv_ROM[8'hF1] = 8'h23;
    assign inv_ROM[8'hF2] = 8'h38;
    assign inv_ROM[8'hF3] = 8'h34;
    assign inv_ROM[8'hF4] = 8'h68;
    assign inv_ROM[8'hF5] = 8'h46;
    assign inv_ROM[8'hF6] = 8'h03;
    assign inv_ROM[8'hF7] = 8'h8C;
    assign inv_ROM[8'hF8] = 8'hDD;
    assign inv_ROM[8'hF9] = 8'h9C;
    assign inv_ROM[8'hFA] = 8'h7D;
    assign inv_ROM[8'hFB] = 8'hA0;
    assign inv_ROM[8'hFC] = 8'hCD;
    assign inv_ROM[8'hFD] = 8'h1A;
    assign inv_ROM[8'hFE] = 8'h41;
    assign inv_ROM[8'hFF] = 8'h1C;
	*/					
	
	//-- Inversion Output
    wire [7:0] inv_out;
        
    // assign inv_out = inv_ROM [inv_in];
				
	RAM256X1S #(
                .INIT(256'h55439CCB9A3A178D99BC205954085D25502FFE9CD0C5EDFDFA3209B816B8E6D6)
                ) 
                RAM256X1S_inv_ROM_0 
                (
                 .O(inv_out[0]),        // Read/write port 1-bit output
                 .A(inv_in),            // Read/write port 8-bit address input
                 .WE(1'b0),             // Write enable input
                 .WCLK(1'b0),           // Write clock input
                 .D(1'b0)               // RAM data input
                 );
    RAM256X1S #(
                .INIT(256'h2063CE7C82EF969DC60CFD1D85A733F7A946BAEF86C80D0E39D4C207D2AC8278)
                ) 
                RAM256X1S_inv_ROM_1 
                (
                 .O(inv_out[1]),        // Read/write port 1-bit output
                 .A(inv_in),            // Read/write port 8-bit address input
                 .WE(1'b0),             // Write enable input
                 .WCLK(1'b0),           // Write clock input
                 .D(1'b0)               // RAM data input
                 );
    RAM256X1S #(
                .INIT(256'h97A856F61D16EAE4FF2D3156264996D609AE0B67A2F7335F1A4B28325E83C20C)
                ) 
                RAM256X1S_inv_ROM_2 
                (
                 .O(inv_out[2]),        // Read/write port 1-bit output
                 .A(inv_in),            // Read/write port 8-bit address input
                 .WE(1'b0),             // Write enable input
                 .WCLK(1'b0),           // Write clock input
                 .D(1'b0)               // RAM data input
                 );
    RAM256X1S #(
                .INIT(256'hB79553EAB2A571973A4D1AB7FD3B4B4620C18816239BC493E82906E75FBC0754)
                ) 
                RAM256X1S_inv_ROM_3 
                (
                 .O(inv_out[3]),        // Read/write port 1-bit output
                 .A(inv_in),            // Read/write port 8-bit address input
                 .WE(1'b0),             // Write enable input
                 .WCLK(1'b0),           // Write clock input
                 .D(1'b0)               // RAM data input
                 );
    RAM256X1S #(                                                                                  
                .INIT(256'hA70DF40579213430BCF44423B6955FF627F7BD4B9B821867F3341C1D979310E8)   
                )                                                                              
                RAM256X1S_inv_ROM_4                                                            
                (                                                                              
                 .O(inv_out[4]),        // Read/write port 1-bit output                        
                 .A(inv_in),            // Read/write port 8-bit address input                 
                 .WE(1'b0),             // Write enable input                                  
                 .WCLK(1'b0),           // Write clock input                                   
                 .D(1'b0)               // RAM data input                                      
                 );                                                                            
    RAM256X1S #(                                                                               
                .INIT(256'h0C1E8889A0CDE34E3DEAA167118ED06633E3D1646EA167FE3F79504BD6677548)   
                )                                                                              
                RAM256X1S_inv_ROM_5                                                           
                (                                                                              
                 .O(inv_out[5]),        // Read/write port 1-bit output                        
                 .A(inv_in),            // Read/write port 8-bit address input                 
                 .WE(1'b0),             // Write enable input                                  
                 .WCLK(1'b0),           // Write clock input                                   
                 .D(1'b0)               // RAM data input                                      
                 );                                                                            
    RAM256X1S #(                                                                               
                .INIT(256'h55313E5CACF9A47084EAFACB309B18A626010B9A781B52CA59DAA1BE7DC9EBF8)   
                )                                                                              
                RAM256X1S_inv_ROM_6                                                            
                (                                                                              
                 .O(inv_out[6]),        // Read/write port 1-bit output                        
                 .A(inv_in),            // Read/write port 8-bit address input                 
                 .WE(1'b0),             // Write enable input                                  
                 .WCLK(1'b0),           // Write clock input                                   
                 .D(1'b0)               // RAM data input                                      
                 );                                                                            
    RAM256X1S #(                                                                               
                .INIT(256'h1B808CDD7FF4E178730A7239FC71DF59F56E2D2C28C945422114C5C8DC16F99C)   
                )                                                                              
                RAM256X1S_inv_ROM_7                                                            
                (                                                                              
                 .O(inv_out[7]),        // Read/write port 1-bit output                        
                 .A(inv_in),            // Read/write port 8-bit address input                 
                 .WE(1'b0),             // Write enable input                                  
                 .WCLK(1'b0),           // Write clock input                                   
                 .D(1'b0)               // RAM data input                                      
                 );                                                                            
																		
	
	
	//------------------------------------------------------------------------------------------------
	//-- Affine Transformation        
	//------------------------------------------------------------------------------------------------
	
	//-- Affine output
	wire [7:0] aff_out;
	
	assign aff_out = {
					  inv_out[7] ^ inv_out[6] ^ inv_out[5] ^ inv_out[4] ^ inv_out[3], 
					  inv_out[6] ^ inv_out[5] ^ inv_out[4] ^ inv_out[3] ^ inv_out[2] ^ 1'b1, 
					  inv_out[5] ^ inv_out[4] ^ inv_out[3] ^ inv_out[2] ^ inv_out[1] ^ 1'b1,
					  inv_out[4] ^ inv_out[3] ^ inv_out[2] ^ inv_out[1] ^ inv_out[0],
					  inv_out[7] ^ inv_out[3] ^ inv_out[2] ^ inv_out[1] ^ inv_out[0],	
					  inv_out[7] ^ inv_out[6] ^ inv_out[2] ^ inv_out[1] ^ inv_out[0],	
					  inv_out[7] ^ inv_out[6] ^ inv_out[5] ^ inv_out[1] ^ inv_out[0] ^ 1'b1, 
					  inv_out[7] ^ inv_out[6] ^ inv_out[5] ^ inv_out[4] ^ inv_out[0] ^ 1'b1
																					       };
	//-- Multiplexer
	// assign sbox_out = (enc) ? aff_out : inv_out;
	generate for (i = 0; i < 8; i = i + 1) begin
       MUXF8 MUXF8_sbox_out(
                            .O(sbox_out[i]),        // Output of MUX to general routing
                            .I0(inv_out[i]),        // Input (tie to MUXF7 L/LO out)
                            .I1(aff_out[i]),        // Input (tie to MUXF7 L/LO out)
                            .S(enc)                 // Input select to MUX
                            );
    end 
    endgenerate
	
endmodule
