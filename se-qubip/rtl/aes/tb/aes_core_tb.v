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
        enc = 0;
        
        /*
		aes_len 	= AES_128;
		// key 		= {128'h2b7e151628aed2a6abf7158809cf4f3c, 128'h0};
		key 		= {128'h000102030405060708090a0b0c0d0e0f, 128'h0};
		plaintext   = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
		*/
		/*
		aes_len 	= AES_192;
        key         = {192'h000102030405060708090a0b0c0d0e0f1011121314151617, 64'h0};
		plaintext   = 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
		*/
		
		aes_len 	= AES_256;
        key         = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        plaintext   = 128'h8ea2b7ca516745bfeafc49904b496089; //-- Ciphertext
		
		// plaintext 	= 128'h3243f6a8885a308d313198a2e0370734;
		// plaintext 	= 128'h00112233445566778899aabbccddeeff;
		
		
		#10
		rst			= 0;
	end
	
	always #5 clk = !clk;
	
	always @(posedge clk) begin
	   if (valid) begin
	       $display("\nCiphertext = 0x%032h\n", ciphertext);
	       $finish;
	   end
	end
endmodule
