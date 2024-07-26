`default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 2+/02/2024
// Design Name: sub_red512.v
// Module Name: sub_red512
// Project Name: EDSA25519 ECC Accelerator
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Subtractor and Comparator Module for reduction modulo L
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module sub_red512 #(parameter BIT_LENGTH = 256)(
                                                input  wire clk,                    //-- Clock Signal
                                                input  wire rst,                    //-- Reset Signal 
                                                input  wire [BIT_LENGTH-1:0] A,     //-- Input A
                                                input  wire [385:0] B,              //-- Input B
                                                output reg  [385:0] C,              //-- Output C
                                                output wire bigger,                 //-- A > B
                                                output wire equal,                  //-- A == B
                                                output wire smaller                 //-- A < B 
                                                );
    
    assign smaller = (B > A) ? 1 : 0;
    assign equal   = (B[BIT_LENGTH-1:0] == A) ? 1 : 0;
    assign bigger  = !smaller & !equal;
    
    always @(posedge clk) begin
        if (rst)
            C <= 0;
        else if (smaller)
            C <= B - A;
        else 
            C <= A - B;
    end
   
endmodule
