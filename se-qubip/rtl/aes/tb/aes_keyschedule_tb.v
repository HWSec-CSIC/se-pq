`default_nettype none
`define DUMPSTR(x) `"x.vcd`"
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 20/09/2024
// Design Name: aes_keyschedule_tb.v
// Module Name: aes_keyschedule_tb
// Project Name: AES for SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		AES Key Schedule for AES-128/192/256 TESTBENCH
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module aes_keyschedule_tb();
	
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
	reg  inv;
	reg  [1:0] aes_len;
	reg  [255:0] key;
	reg  [15:0] subkey_req;
	wire [127:0] subkey;
	wire [15:0] subkey_idx;
	   
			
	//--------------------------------------
	//-- AES Key Schedule Instance
	//--------------------------------------
	
	aes_keyschedule DUT(
					    .clk(clk),
					    .rst(rst),
					    .inv(inv),
					    .aes_len(aes_len),
					    .key(key),
					    .subkey_req(subkey_req),
					    .subkey(subkey),
					    .subkey_idx(subkey_idx)
					    ); 
	
	
	//---------------------------------
	//-- Test Values
	//---------------------------------
	
	initial begin
		clk = 0;
		rst = 1;
        inv = 0;
        /*
		aes_len 	= AES_128;
		key 		= {128'h2b7e151628aed2a6abf7158809cf4f3c, 128'h0};
		*/
		/*
		aes_len 	= AES_192;
        //key         = {192'h8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b, 64'h0};
		key         = {192'h000102030405060708090a0b0c0d0e0f1011121314151617, 64'h0}; 
		*/
		
		aes_len 	= AES_256;
        key         = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
        
		subkey_req 	= 16'b0000000000000001;
		
		#10
		rst			= 0;
	end
	
	always #0.5 clk = !clk;
	
	reg [3:0] counter;
	
	always @(posedge clk) begin
		
		if (rst) begin
			subkey_req <= 16'b0000000000000001;
		    counter    <= 4'b0;
		end
		else if (!inv) begin
			subkey_req   <= {subkey_req[14:0], 1'b0};
			counter      <= counter + 1;
			$display("subkey_%0d\t -> W%0d\t = %08h\t | W%0d\t = %08h\t | W%0d\t = %08h\t | W%0d\t = %08h", counter, 4 * counter, subkey[127:96], 4 * counter + 1,  subkey[95:64], 4 * counter + 2, subkey[63:32], 4 * counter + 3, subkey[31:0]);
		    if ( (aes_len == AES_128 && counter == 4'd9) ||(aes_len == AES_192 && counter == 4'd11) || (aes_len == AES_256 && counter == 4'd13) ) begin
		      $display("\nINVERSION:\n");
		      if (aes_len == AES_256)
		          counter <= counter + 2;
		      else 
		          counter <= counter + 1;
		      inv <= 1;
		    end
		end
		else if (inv) begin
		    subkey_req   <= {1'b0, subkey_req[15:1]};
            counter      <= counter - 1;
            $display("subkey_%0d\t -> W%0d\t = %08h\t | W%0d\t = %08h\t | W%0d\t = %08h\t | W%0d\t = %08h", counter, 4 * counter, subkey[127:96], 4 * counter + 1,  subkey[95:64], 4 * counter + 2, subkey[63:32], 4 * counter + 3, subkey[31:0]);
		end
		
		// if ( (aes_len == AES_128 && counter == 10) || (aes_len == AES_192 && counter == 12) || (aes_len == AES_256 && counter == 14)  ) $finish;
		
		if (inv && (counter == 0)) $finish;
	
	end
	
	
	
endmodule
