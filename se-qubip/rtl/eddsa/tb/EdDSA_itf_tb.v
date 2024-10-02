/**
  * @file EdDSA_itf_tb.v
  * @brief EdDSA_itf Test Bench
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

`default_nettype none
`define DUMPSTR(x) `"x.vcd`"
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 21/06/2024
// Design Name: EdDSA_itf_tb.v
// Module Name: EdDSA_itf_tb
// Project Name: EDSA25519 Cryptocore
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		EdDSA25519 Interface TESTBENCH
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module EdDSA_itf_tb();
	
	//---------------------------------
	//-- Simulation time
	//---------------------------------
	
	parameter DURATION = 100000;
	
	initial
	begin
		#(DURATION) $display("End of simulation");
		$finish;
	end	
	
	
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------
	
	localparam BIT_LENGTH = 256;
    localparam WIDTH      = 64;
    localparam SIZE_BLOCK = 1024;
	
	//-- Inputs
	reg  clk;		
	reg  [3:0] control;
	reg  [WIDTH-1:0] address;
	reg  [WIDTH-1:0] data_in;
	//-- Outputs
	wire [WIDTH-1:0] data_out;
	wire end_op;
	        
			
	//--------------------------------------
	//-- EdDSA Accelerator Instance
	//--------------------------------------
	
	EdDSA_itf DUT(
			      .clk(clk),
			      .control(control),
			      .address(address),
			      .data_in(data_in),
			      .data_out(data_out),
                  .end_op(end_op)
			      ); 
	
	
	    
	//---------------------------------
	//-- Test Values
	//---------------------------------
	
	initial begin
	
		clk = 0;
		
		control <= 4'b0011;
		address <= 0;
		data_in <= 0;
		
		//-- Reset Interface
		#1 
		control <= 4'b0111;
		// #1
		// control <= 4'b0001;
		
		//-- Load Select Operation
		#1
		control <= 4'b0101;
		data_in <= {60'b0, 4'b0100};
		// #1 
		// control <= 4'b0001;
		
		//-- Load Private Key
		#1
		// control <= 4'b0101;
		address <= 1;
		#1
		data_in <= 64'hfbc6216febc44546;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 2;
		#1
		data_in <= 64'hc670dbd3060cba67;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 3;
		#1
		data_in <= 64'h24a7be63041146eb;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 4;
		#1
		data_in <= 64'h78ae9effe6f245e9;
		
		// #1 
		// control <= 4'b0001;
		
		
        //-- Load Public Key
		#1
		// control <= 4'b0101;
		address <= 5;
		#1
		data_in <= 64'h2b5087b83ee3643d;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 6;
		#1
		data_in <= 64'he16d615260e1640b;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 7;
		#1
		data_in <= 64'hbe444a33d185cc54;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 8;
		#1
		data_in <= 64'hfbcfbfa40505d7f2;
		
		// #1 
		// control <= 4'b0001;
		
		//-- Load Message
		#1
		// control <= 4'b0101;
		address <= 24;
		#1
		data_in <= 64'h89010d8559720000;
		
		// #1 
		// control <= 4'b0001;
		
		//-- Load Message Length
		#1
		// control <= 4'b0101;
	    address <= 25;
	    #1	
		data_in <= 64'd48;
		
		// #1 
		// control <= 4'b0001;
		
		//-- Load Signature to Verify
		#1
		// control <= 4'b0101;
		address <= 26;
		#1
		data_in <= 64'h4d639518839d2300;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 27;
		#1
		data_in <= 64'h752194e4904d09c7;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 28;
		#1
		data_in <= 64'h248dbd8d16d14e99;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 29;
		#1
		data_in <= 64'h854b8f20cc6eecbb;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 30;
		#1
		data_in <= 64'h9d241830f7e5fa29;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 31;
		#1
		data_in <= 64'h40a5d9c91afd93b7;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 32;
		#1
		data_in <= 64'h468755ff636d5a3f;
		
		// #1 
		// control <= 4'b0001;
		#1
		// control <= 4'b0101;
		address <= 33;
		#1
		data_in <= 64'h6ed629fc1d9ce9e1;
		
		
		
		//-- Start Operation
		#1 
		control = 4'b0000;

	end
	
	reg [10:0] n_test = 1;
	real clk_time; 
	
	always @(posedge end_op) begin
		
		clk_time <= $time;
		
		#1
		$display("\nOperation %d at t = %d cycles:\n", n_test, clk_time);
		$display("SIG_PUB = 0x%h \n", DUT.sig_pub);
		control <= 4'b0001;
		address <= 0;
		
		//-- Reset and restart block_valid
		#1
		control <= 4'b0101;
		
		#1
		data_in <= {60'b0, 4'b0000};
		
		#1
		control <= 4'b0100;
		
		case (n_test)
			 (1): begin
			     data_in <= {60'b0, 4'b1000};
			 end
			 (2): begin
			     data_in <= {60'b0, 4'b1100};
			 end
			 (3): $finish;
		endcase
		
		n_test <= n_test + 1;
	
	end
	
	always @(posedge DUT.error) begin
	    clk_time <= $time;
		
		#1
		$display("\nOperation %d at t = %d cycles:\n", n_test, clk_time);
		$display("SIG_PUB = 0x%h \n", DUT.sig_pub);
		
		$finish;
	end
	
	always #0.5 clk = ~clk;
     
     
	
endmodule
