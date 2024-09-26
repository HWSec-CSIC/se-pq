// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 22/02/2024
// Design Name: add_sub.v
// Module Name: add_sub
// Project Name: EDSA25519 ECC Accelerator
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Adder/Subtractor Module with reduction mod p = 2**255-19
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module add_sub #(parameter BIT_LENGTH = 256)(
                                             input  wire clk,                    //-- Clock Signal
                                             input  wire rst,                    //-- Reset Signal
                                             input  wire mode,                   //-- Mode (0): Add | (1): Sub
                                             input  wire [BIT_LENGTH-1:0] A,     //-- Input A
                                             input  wire [BIT_LENGTH-1:0] B,     //-- Input B
                                             output wire [BIT_LENGTH-1:0] C      //-- Output C
                                             );
    
    
    //--------------------------------------
	//-- Parameters             
	//--------------------------------------

	localparam P = 256'h7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
	
	
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------
    
    reg [BIT_LENGTH-1:0] C_0;
    wire sub_comp;
    wire add_comp;
    
    
    //--------------------------------------
	//-- Addition/Subtraction       
	//--------------------------------------
    
    assign sub_comp = (A > B)   ? 1 : 0;
    assign add_comp = (P > C_0) ? 1 : 0;

    
    //--------------------------------------
	//-- Addition/Subtraction       
	//--------------------------------------
	
    always @(posedge clk) begin
        if (rst) 
            C_0 <= 0;
        else if (mode && sub_comp)
            C_0 <= A - B;
        else if (mode && !sub_comp)
            C_0 <= P - (B - A);
        else 
            C_0 <= A + B;
    end
    /*
    always @(posedge clk) begin
        if (rst) 
            C <= 0;
        else if (add_comp)
            C <= C_0;
        else
            C <= C_0 - P;
    end
    */
    assign C = (add_comp) ? C_0 : (C_0 - P);
    
    
endmodule
