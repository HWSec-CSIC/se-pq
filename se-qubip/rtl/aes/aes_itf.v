/**
  * @file aes_itf.v
  * @brief AES Interface HDL
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


module aes_itf #(
                  localparam BIT_LENGTH = 256,
                  localparam WIDTH      = 64,
                  localparam SIZE_BLOCK = 128,
                  localparam IN_REG     = 9,
                  localparam OUT_REG    = 3
                  )
                  (
                   input  wire clk,                                    //-- Clock Signal
                   input  wire i_rst,                                  //-- Reset Signal 
                   input  wire [3:0] control,                          //-- Control Signal: {read, load, rst_itf, rst} 
                   input  wire [WIDTH-1:0] address,                    //-- Address
                   input  wire [WIDTH-1:0] data_in,                    //-- Data Input
                   output wire [WIDTH-1:0] data_out,                   //-- Data Output
                   output wire end_op                                  //-- End Operation Signal
                   );

    
    //--------------------------------------
	//-- Wires & Registers
	//--------------------------------------
    
    //-- Control Signals
    wire rst;
    wire rst_itf;
    wire load;
    wire read;
    
    //assign rst      = control[0] | i_rst;
    assign rst      =  control[0] & i_rst;
    assign rst_itf  = control[1] | !i_rst;
    assign load     = control[2];
    assign read     = control[3];
    
    //-- Sipo Input
    wire [IN_REG*WIDTH-1:0] data_aes_in;
    //-- Piso input
    wire [OUT_REG*WIDTH-1:0] data_aes_out; //data_aes_out[191:0]
    
    //-- AES Inputs
	wire  ecb_cbc;
	wire  encdec;
	wire  keylen;
	wire start;
	//wire  init;
//	wire  next;
	
	
	
	wire [BIT_LENGTH-1:0] key;
	
	wire [SIZE_BLOCK-1:0] block;
	wire [SIZE_BLOCK-1:0] iv;	
	

    
    assign ecb_cbc  	= data_aes_in[0];
    assign encdec       = data_aes_in[1];
    assign keylen       = data_aes_in[2];
    assign start       	= data_aes_in[3];
    
    //assign init       	= data_aes_in[3];
   // assign next       	= data_aes_in[4];			//4:0 is used out of 63:0 of data_aes_in
    
    assign key      	= data_aes_in[BIT_LENGTH+WIDTH-1:WIDTH];   //data_aes_in [319:64]
    
    assign iv       	= data_aes_in[SIZE_BLOCK+BIT_LENGTH+WIDTH-1:BIT_LENGTH+WIDTH];	//data_aes_in [447:320]
    
    assign block      = data_aes_in[2*SIZE_BLOCK+BIT_LENGTH+WIDTH-1:SIZE_BLOCK+BIT_LENGTH+WIDTH];	// data_aes_in [575:448]

    
    //-- AES Outputs
    
	wire [SIZE_BLOCK-1:0] result;
	wire result_valid;
	wire ready;
	wire key_valid;
	
	//assign data_aes_out = {result, 61'b0,key_valid, ready, result_valid};
    assign data_aes_out = {result, 63'b0,result_valid};
    
    //--------------------------------------
	//-- SIPO          
	//--------------------------------------
    
    sipo #(.R_DATA_WIDTH(WIDTH), .N_REG(IN_REG)) SIPO (
	                                                   .clk(clk),
	                                                   .rst(rst_itf),
	                                                   .load(load),
						                               .addr(address),
						                               .din(data_in),
						                               .dout(data_aes_in)
						                               ); 
                                                      

    //--------------------------------------
	//-- AES Cryptocore                           
	//--------------------------------------
    
    aes_core aes_core(
			    //input control signals
			    .clk(clk),
			    .reset_n(rst),
			    .ecb_cbc(ecb_cbc),
			    .encdec(encdec),
			    .start(start),
			   // .init(init),
			   // .next(next),
			    .keylen(keylen),
			    
			    //inputs
			    .key(key),
			    .iv(iv),
			    .block(block),
			    
			      //outputs
			    .ready(ready),
			    .result_valid(result_valid),
			    .key_valid(key_valid),
			    .result(result)
			    );  
    
        
    
    //--------------------------------------
	//-- PISO              
	//--------------------------------------
    
    piso #(.R_DATA_WIDTH(WIDTH), .N_REG(OUT_REG)) PISO(
						                               .clk(clk),
						                               .read(read),
						                               .addr(address),
						                               .din(data_aes_out),
						                               .dout(data_out)
						                               );
    
    
    assign end_op = result_valid;
    


endmodule
