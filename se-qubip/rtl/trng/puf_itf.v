/**
  * @file  puf_itf.v
  * @brief PUF Interface
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


module puf_itf #(
                  localparam WIDTH      = 64,
                  localparam IN_REG     = 1,
                  localparam OUT_REG    = 2,
                  localparam Bpc       = 4, 	   	
                  localparam Mnc = 4096	   	
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
    wire [IN_REG*WIDTH-1:0] data_puf_in;
    //-- Piso input
    wire [OUT_REG*WIDTH-1:0] data_puf_out;
    
    //-- PUF Inputs
    
    wire puf_str ;
    wire     BG 	;																	 
    wire    SD      ;																					 
    wire [1:0] cnfa  ;   
    wire [$clog2(Mnc): 0] n_cmps  ;
    wire  [$clog2((Mnc*Bpc)/WIDTH-1) : 0] puf_addr ;

    
    
    
    assign puf_str   = data_puf_in[0];
    assign BG        = data_puf_in[1];
    assign SD        = data_puf_in[2];
    assign cnfa      = data_puf_in[4:3];
    assign n_cmps    = data_puf_in[17:5];
    assign puf_addr  = data_puf_in[25:18];
    
    //-- puf Outputs
    wire [$clog2(Mnc*Bpc/WIDTH) : 0] puf_addw;	            
    wire puf_end  ;									                
    wire [WIDTH-1 : 0] puf_out;				            
    
    
  
	
	assign data_puf_out = {puf_out ,55'b0, puf_addw};
    
    
    //--------------------------------------
	//-- SIPO          
	//--------------------------------------
    
    sipo #(.R_DATA_WIDTH(WIDTH), .N_REG(IN_REG)) SIPO (
	                                                   .clk(clk),
	                                                   .rst(rst_itf),
	                                                   .load(load),
						                               .addr(address),
						                               .din(data_in),
						                               .dout(data_puf_in)
						                               ); 
                                                      

    //--------------------------------------
	//-- EdDSA25519 Cryptocore                           
	//--------------------------------------
    
    PUF puf(
			    .clock(clk),
			    .reset(rst),
			    .puf_str(puf_str),
			    .BG(BG),
			    .SD(SD),
			    .cnfa(cnfa),
			    .n_cmps(n_cmps),
			    .puf_addr(puf_addr),
			    .puf_addw(puf_addw),
			    .puf_end(puf_end),
			    .puf_out(puf_out)
			    );  
    
    
    //--------------------------------------
	//-- PISO              
	//--------------------------------------
    
    piso #(.R_DATA_WIDTH(WIDTH), .N_REG(OUT_REG)) PISO(
						                               .clk(clk),
						                               .read(read),
						                               .addr(address),
						                               .din(data_puf_out),
						                               .dout(data_out)
						                               );
    
    
    assign end_op = puf_end;
    


endmodule
