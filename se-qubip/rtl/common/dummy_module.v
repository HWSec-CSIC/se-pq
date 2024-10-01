`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2024 12:00:21
// Design Name: 
// Module Name: dummy_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dummy_module(
    input                           i_clk,
    input                           i_rst,
    input   [63:0]                  i_data_in,
    input   [63:0]                  i_add,
    input   [31:0]                  i_control,
    output  [63:0]                  o_data_out,
    output                          o_end_op
    );
    
    assign o_end_op = 1'b1;
    assign o_data_out = 64'hFFFF_FFFF_FFFF_FFFF;
    
endmodule
