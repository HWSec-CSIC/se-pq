/**
  * @file X25519_itf.v
  * @brief Verilog code for top level X25519 design
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
// Create Date: 09/07/2024
// Design Name: X25519_itf.v
// Module Name: X25519_itf
// Project Name: X25519 Cryptocore
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Verilog code for top level X25519 design
//
////////////////////////////////////////////////////////////////////////////////////


module X25519_itf #(
                   localparam BIT_LENGTH = 256,
                   localparam WIDTH      = 64,
                   localparam IN_REG     = 8,
                   localparam OUT_REG    = 12
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
    
    assign rst      = control[0] | !i_rst;
    assign rst_itf  = control[1] | !i_rst;
    assign load     = control[2];
    assign read     = control[3];
    
    //-- Sipo Input
    wire [IN_REG*WIDTH-1:0] data_eddsa_in;
    //-- Piso input
    wire [OUT_REG*WIDTH-1:0] data_eddsa_out;
    
    //-- X25519 Inputs
	wire [BIT_LENGTH-1:0] scalar;
	wire [BIT_LENGTH-1:0] point_in;
	
    assign scalar   = data_eddsa_in[BIT_LENGTH-1:0];
    assign point_in = data_eddsa_in[2*BIT_LENGTH-1:BIT_LENGTH];
    
    //-- EdDSA Outputs
	wire [BIT_LENGTH-1:0] point_out;
	wire valid;
	
	assign data_eddsa_out = {data_eddsa_in, point_out};
    
    
    //--------------------------------------
	//-- SIPO          
	//--------------------------------------
    
    sipo #(.R_DATA_WIDTH(WIDTH), .N_REG(IN_REG)) SIPO (
	                                                   .clk(clk),
	                                                   .rst(rst_itf),
	                                                   .load(load),
						                               .addr(address),
						                               .din(data_in),
						                               .dout(data_eddsa_in)
						                               ); 
                                                      

    //--------------------------------------
	//-- X25519                           
	//--------------------------------------
        
    X25519 X25519(
                  .clk(clk),
                  .rst(rst),
                  .scalar(scalar),
                  .point_in(point_in),
                  .point_out(point_out),
                  .valid(valid)
                  );
    
    
    //--------------------------------------
	//-- PISO              
	//--------------------------------------
    
    piso #(.R_DATA_WIDTH(WIDTH), .N_REG(OUT_REG)) PISO(
						                               .clk(clk),
						                               .read(read),
						                               .addr(address),
						                               .din(data_eddsa_out),
						                               .dout(data_out)
						                               );
    
    
    assign end_op = valid;
    


endmodule
