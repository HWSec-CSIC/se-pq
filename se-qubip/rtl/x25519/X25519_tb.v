`default_nettype none
`define DUMPSTR(x) `"x.vcd`"
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 05/07/2024
// Design Name: X25519_tb.v
// Module Name: X25519_tb
// Project Name: EDSA25519 Cryptocore
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		X25519 Cryptocore TESTBENCH
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module X25519_tb();
	
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

	//-- Clock and Reset
	reg  clk;		
	reg  rst;
	//-- Inputs
	reg  [BIT_LENGTH-1:0] scalar;
	reg  [BIT_LENGTH-1:0] point_in;
	//-- Outputs
	wire [BIT_LENGTH-1:0] point_out;
	wire valid;
	        
			
	//--------------------------------------
	//-- EdDSA Accelerator Instance
	//--------------------------------------
	
	X25519 DUT(
			  .clk(clk),
			  .rst(rst),
			  .scalar(scalar),
			  .point_in(point_in),
			  .point_out(point_out),
			  .valid(valid)
			  ); 
	
	
	//---------------------------------
	//-- Test Values
	//---------------------------------
	
	initial begin
		clk = 0;
		
		rst       <= 1;
		scalar    <= 256'h77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a;
		point_in  <= 256'h0900000000000000000000000000000000000000000000000000000000000000;
		
		#1
		rst <= 0;       	
	end
	
	reg [10:0] n_test = 1;
	real clk_time; 
	
	always @(posedge valid) begin
		
		clk_time <= $time;
		
		#1
		$display("\nOperation %d at t = %d cycles:\n", n_test, clk_time);
		$display("POINT_OUT = 0x%h \n", point_out);
		
		#1
		rst <= 1;
		
		#1
		rst <= 0;
		
		case (n_test)
			 (1): begin
			     $finish;
			 end
			 
		endcase
		
		n_test <= n_test + 1;
	
	end
	
	always #0.5 clk = ~clk;
	
	
endmodule
