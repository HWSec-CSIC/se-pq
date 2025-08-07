/**
  * @file aes_itf.v
  * @brief AES Interface for SE-QUBIP
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
// Design Name: aes_itf.v
// Module Name: aes_itf
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES Interface for SE-QUBIP
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module aes_itf #(
                 parameter  SWAP_ENDIANNESS     = 0,
                 localparam WIDTH               = 64,
                 localparam IN_REG              = 11,
                 localparam OUT_REG             = 4
                 )
                 ( 
                  input  wire clk,                                    //-- Clock Signal
                  input  wire i_rst,                                  //-- Reset Signal                              
                  input  wire [4:0] control,                          //-- Control Signal: {rst_mul, read, load, rst_itf, rst} 
                  input  wire [WIDTH-1:0] address,                    //-- Address
                  input  wire [WIDTH-1:0] data_in,                    //-- Data Input
                  output reg  [WIDTH-1:0] data_out,                   //-- Data Output
                  output wire end_op                                  //-- End Operation Signal
                  );

    //--------------------------------------
	//-- Change I/O Endianness
	//--------------------------------------
	
	integer i;
	
	reg  [WIDTH-1:0] data_in_swap;
	wire [WIDTH-1:0] data_out_swap;
	
	generate if (SWAP_ENDIANNESS) begin
	   always @(*) begin  
           for (i = 0; i < 8; i = i + 1) begin 
               data_in_swap[(7-i)*8+:8]    = data_in[i*8+:8];
               data_out[(7-i)*8+:8]        = data_out_swap[i*8+:8];
           end
       end
    end
    else begin
	   always @(*) begin  
           data_in_swap = data_in;
           data_out     = data_out_swap;
       end
    end
    endgenerate  


    //--------------------------------------
	//-- Wires & Registers
	//--------------------------------------
    
    //-- Control Signals
    wire rst;
    wire rst_itf;
    wire load;
    wire read;
    wire rst_mul;
    
    assign rst      = control[0] | !i_rst;
    assign rst_itf  = control[1] | !i_rst;
    assign load     = control[2];
    assign read     = control[3];
    assign rst_mul  = control[4] | !i_rst;
    
    //-- Sipo Input
    wire [IN_REG*WIDTH-1:0] data_aes_in;
    //-- Piso input
    wire [OUT_REG*WIDTH-1:0] data_aes_out;
    
    //-- AES Inputs
	wire enc;
	wire [1:0] aes_len;
	wire [4*WIDTH-1:0] key;
	wire [2*WIDTH-1:0] plaintext;
	
	assign enc			= data_aes_in[0];
	assign aes_len 		= data_aes_in[2:1];
    assign key	  		= data_aes_in[5*WIDTH-1:WIDTH];
    assign plaintext 	= data_aes_in[7*WIDTH-1:5*WIDTH];
    
    //-- EdDSA Outputs
	wire [2*WIDTH-1:0] ciphertext;
	wire valid;
	
	assign data_aes_out[2*WIDTH-1:0] = ciphertext;

    //-- GALOIS MUL Inputs
    wire [2*WIDTH-1:0] X;
    wire [2*WIDTH-1:0] Y;

    assign X = data_aes_in[9*WIDTH-1:7*WIDTH];
    assign Y = data_aes_in[11*WIDTH-1:9*WIDTH];

    //-- GALOIS MUL Outputs
    wire [2*WIDTH-1:0] Z;
    wire valid_mul;

    assign data_aes_out[4*WIDTH-1:2*WIDTH] = Z;

    
    //--------------------------------------
	//-- SIPO          
	//--------------------------------------
    
    sipo #(.R_DATA_WIDTH(WIDTH), .N_REG(IN_REG)) SIPO (
	                                                   .clk(clk),
	                                                   .rst(rst_itf),
	                                                   .load(load),
						                               .addr(address[31:0]),
						                               .din(data_in_swap),
						                               .dout(data_aes_in)
						                               ); 
                                                      

    //--------------------------------------
	//-- AES                        
	//--------------------------------------
         
	aes_core AES(
				 .clk(clk),
				 .rst(rst),
				 .enc(enc),
				 .aes_len(aes_len),
				 .key(key),
				 .plaintext(plaintext),
				 .ciphertext(ciphertext),
				 .valid(valid)
				 ); 

    
    //--------------------------------------
	//-- Galois Multiplier                       
	//--------------------------------------
    
    galois_mul GALOIS_MUL(
                          .clk(clk),
                          .rst(rst_mul),
                          .X(X),
                          .Y(Y),
                          .Z(Z),
                          .valid(valid_mul)
                          );
    
    //--------------------------------------
	//-- PISO              
	//--------------------------------------
    
    piso #(.R_DATA_WIDTH(WIDTH), .N_REG(OUT_REG)) PISO(
						                               .clk(clk),
						                               .read(read),
						                               .addr(address[63:32]),
						                               .din(data_aes_out),
						                               .dout(data_out_swap)
						                               );
    
    
    assign end_op = valid | valid_mul;


endmodule
