// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 10/06/2025
// Design Name: galois_mul.v
// Module Name: galois_mul
// Project Name: Galois Multiplier for AES-GCM mode
// Target Devices: PYNQZ2
// Tool Versions: 
// Description: 
//		
//		Bit Serial Galois Multiplier for AES-GCM mode
//		
// Additional Comment:
//
////////////////////////////////////////////////////////////////////////////////////

module galois_mul(
				  input  wire clk,					//-- Clock Signal
				  input  wire rst,					//-- Active HIGH Reset
				  input  wire [127:0] X, 			//-- Input X
				  input  wire [127:0] Y, 			//-- Input Y
				  output reg  [127:0] Z,			//-- Output Z = X · Y
				  output reg  valid					//-- Valid Signal
				  );
	
	localparam [7:0] R = 8'b11100001; 

	reg [127:0] V, X_i;
	reg [6:0] bit_index;

	always @(posedge clk) begin
		if (rst) begin
			X_i 		<= X;
			V 			<= Y;
			Z			<= 0;
			bit_index 	<= 0;
			valid 		<= 0;
		end
		else if (!valid) begin
			//-- Z_{i+1} = (x_i[127]) ? Z_i ^ V_i : Z_i
			if (X_i[127]) 
				Z <= Z ^ V;
			//-- X_i = X_i << 1
			X_i <= {X_i[126:0], 1'b0};
			//-- V_{i+1} = (V_i[0]) ? (V_i >> 1) ^ R : (V_i >> 1)
			if (V[0]) 
				V <= {{1'b0, V[127:121]} ^ R, V[120:1]};
			else
				V <= {1'b0, V[127:1]};
			//-- Increase bit counter
			bit_index <= bit_index + 1;
			if (&bit_index) valid <= 1;
		end
	end
	
endmodule 

