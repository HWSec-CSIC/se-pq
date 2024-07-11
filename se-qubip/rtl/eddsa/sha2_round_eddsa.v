`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.07.2023 19:35:26
// Design Name: 
// Module Name: sha2_round
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


module sha2_round # (
    parameter WIDTH = 32,
    parameter MODE = 256
    )(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire [WIDTH-1:0] c,
    input wire [WIDTH-1:0] d,
    input wire [WIDTH-1:0] e,
    input wire [WIDTH-1:0] f,
    input wire [WIDTH-1:0] g,
    input wire [WIDTH-1:0] h,
    output wire [WIDTH-1:0] a_out,
    output wire [WIDTH-1:0] b_out,
    output wire [WIDTH-1:0] c_out,
    output wire [WIDTH-1:0] d_out,
    output wire [WIDTH-1:0] e_out,
    output wire [WIDTH-1:0] f_out,
    output wire [WIDTH-1:0] g_out,
    output wire [WIDTH-1:0] h_out,
    input wire [WIDTH-1:0] W,
    input wire [WIDTH-1:0] K
    );
    
    wire    [WIDTH-1:0] out_1; 
    wire    [WIDTH-1:0] out_2;
    wire    [WIDTH-1:0] out_3;
    wire    [WIDTH-1:0] out_4; 
    wire    [WIDTH-1:0] T1;
    wire    [WIDTH-1:0] T2;
    
    generate 
        if(MODE == 224 | MODE == 256) begin
            eps_1 #(.SIZE(WIDTH)) eps1 (.x(e), .out(out_1));
            Choice #(.SIZE(WIDTH)) Ch (.x(e), .y(f), .z(g), .out(out_2));
            eps_0 #(.SIZE(WIDTH)) eps0 (.x(a), .out(out_3));
            Majority #(.SIZE(WIDTH)) Mj (.x(a), .y(b), .z(c), .out(out_4));
        end
        else if(MODE == 384 | MODE == 512) begin
            eps_1_512 #(.SIZE(WIDTH)) eps1 (.x(e), .out(out_1));
            Choice #(.SIZE(WIDTH)) Ch (.x(e), .y(f), .z(g), .out(out_2));
            eps_0_512 #(.SIZE(WIDTH)) eps0 (.x(a), .out(out_3));
            Majority #(.SIZE(WIDTH)) Mj (.x(a), .y(b), .z(c), .out(out_4));
        end
    endgenerate
    
    assign T1 = out_1 + out_2 + h + W + K;
    assign T2 = out_3 + out_4;
    
    assign a_out = T1 + T2;
    assign b_out = a;
    assign c_out = b;
    assign d_out = c;
    assign e_out = d + T1;
    assign f_out = e;
    assign g_out = f;
    assign h_out = g;
    
endmodule

module Choice # (
    parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    input wire [SIZE-1:0] y,
    input wire [SIZE-1:0] z,
    output wire [SIZE-1:0] out
    );
    
    assign out = (x & y) ^ (~x & z);
endmodule

module Majority # (
    parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    input wire [SIZE-1:0] y,
    input wire [SIZE-1:0] z,
    output wire [SIZE-1:0] out
    );
    
    assign out = (x & y) ^ (x & z) ^ (y & z);
endmodule