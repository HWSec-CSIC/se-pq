/**
  * @file aes_core_tb.v
  * @brief AES Core TESTBENCH
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
// Create Date: 20/09/2024
// Design Name: aes_core_tb.v
// Module Name: aes_core_tb
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES core TESTBENCH
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module aes_core_tb();
	
	//---------------------------------
	//-- Simulation time
	//---------------------------------
	
	parameter DURATION = 1000;
	
	initial
	begin
		#(DURATION) $display("End of simulation");
		$finish;
	end	
	
	
	//--------------------------------------
	//-- Parameters
	//--------------------------------------
	
	localparam [1:0] AES_128 = 2'b01;
	localparam [1:0] AES_192 = 2'b10;
	localparam [1:0] AES_256 = 2'b11;
	
	
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------
		
	reg  clk;
	reg  rst;
	reg  enc;
	reg  [1:0] aes_len;
	reg  [255:0] key;
	reg  [127:0] plaintext;
	wire [127:0] ciphertext;
	wire valid;
	   
			
	//--------------------------------------
	//-- AES Key Schedule Instance
	//--------------------------------------
	
	aes_core DUT(
				 .clk(clk),
				 .rst(rst),
				 .enc(enc),
				 .aes_len(aes_len),
				 .key(key),
				 .plaintext(plaintext),
				 .ciphertext(ciphertext),
				 .valid(valid)
				 ); 
	
	
	//---------------------------------
	//-- Test Values
	//---------------------------------
	
	initial begin
		clk = 0;
		rst = 1;
        enc = 1;
        
        
		aes_len 	= AES_128;
		// key 		= {128'h2b7e151628aed2a6abf7158809cf4f3c, 128'h0};
		key 		= {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
		// plaintext   = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
		
		/*
		aes_len 	= AES_192;
        key         = {192'h000102030405060708090a0b0c0d0e0f1011121314151617, 64'h0};
		plaintext   = 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
		*/
		/*
		aes_len 	= AES_256;
        key         = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        plaintext   = 128'h8ea2b7ca516745bfeafc49904b496089; //-- Ciphertext
		*/
		// plaintext 	= 128'h3243f6a8885a308d313198a2e0370734;
		plaintext 	= 128'h00112233445566778899aabbccddeeff;
		
		/*
		#10
		rst			= 0;
		*/
	end
	
	always #0.5 clk = !clk;
	
	reg [3:0] counter = 4'b0;
	reg [5:0] test_success = 6'b000000;
	
	always @(posedge clk) begin
        
       rst <= 0;
        
	   if (valid && !rst) begin
	       counter <= counter + 1;
	       rst     <= 1;
	       
	       case(counter)
	       
	       (4'd0): begin
	           if (ciphertext == 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
	               test_success[0] <= 1;
	               $display("\nTest 1: PASS!");
	           end
	           else 
	               $display("\nTest 1: FAIL!");
	               
	           aes_len <= AES_192;
	           key     <= {192'h000102030405060708090a0b0c0d0e0f1011121314151617, 64'h0};
	       end
	       
	       (4'd1): begin
               if (ciphertext == 128'hdda97ca4864cdfe06eaf70a0ec0d7191) begin
                   test_success[1] <= 1;
                   $display("\nTest 2: PASS!");
               end
               else 
                   $display("\nTest 2: FAIL!");
                   
               aes_len <= AES_256;
               key     <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
           end
           
	       (4'd2): begin
               if (ciphertext == 128'h8ea2b7ca516745bfeafc49904b496089) begin
                   test_success[2] <= 1;
                   $display("\nTest 3: PASS!");
               end
               else 
                   $display("\nTest 3: FAIL!");
               
               enc          <= 0;
                   
               aes_len      <= AES_128;
               key          <= {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
               plaintext    <= 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
           end  
           
	       (4'd3): begin
               if (ciphertext == 128'h00112233445566778899aabbccddeeff) begin
                   test_success[3] <= 1;
                   $display("\nTest 4: PASS!");
               end
               else 
                   $display("\nTest 4: FAIL!");

               aes_len      <= AES_192;
               key          <= {192'h000102030405060708090a0b0c0d0e0f1011121314151617, 64'h0};
               plaintext    <= 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
           end                    
	       
	       (4'd4): begin
               if (ciphertext == 128'h00112233445566778899aabbccddeeff) begin
                   test_success[4] <= 1;
                   $display("\nTest 5: PASS!");
               end
               else 
                   $display("\nTest 5: FAIL!");

               aes_len      <= AES_256;
               key          <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
               plaintext    <= 128'h8ea2b7ca516745bfeafc49904b496089;
           end
           
	       (4'd5): begin
               if (ciphertext == 128'h00112233445566778899aabbccddeeff) begin
                   test_success[5] <= 1;
                   $display("\nTest 6: PASS!");
               end
               else 
                   $display("\nTest 6: FAIL!");
           end           	       
	       
	       endcase
	       
	       //$display("\nCiphertext = 0x%032h\n", ciphertext);
	       //$finish;
	   end
	   
	   else if (counter == 6) begin
	       if (&test_success)
              $display("\n\nPASS!\n\n");
           else
              $display("\n\nFAIL!\n\n");
              
           $finish;
	   end
	   
	end
endmodule
