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


module sha2_round (
    input               mode_sha2,  // 0: sha_256, 1: sha_384, sha_512, sha_512/256
    input [63:0]   a,
    input [63:0]   b,
    input [63:0]   c,
    input [63:0]   d,
    input [63:0]   e,
    input [63:0]   f,
    input [63:0]   g,
    input [63:0]   h,
    output [63:0]  a_out,
    output [63:0]  b_out,
    output [63:0]  c_out,
    output [63:0]  d_out,
    output [63:0]  e_out,
    output [63:0]  f_out,
    output [63:0]  g_out,
    output [63:0]  h_out,
    input [63:0]   W,
    input [31:0]   K_256,
    input [63:0]   K_512
    );
    
    wire    [31:0] out_1_256; // t - 16
    wire    [31:0] out_2_256; // t - 15
    wire    [31:0] out_3_256; // t - 7
    wire    [31:0] out_4_256; // t - 2
    wire    [31:0] T1_256;
    wire    [31:0] T2_256;
    
    wire    [63:0] out_1_512; // t - 16
    wire    [63:0] out_2_512; // t - 15
    wire    [63:0] out_3_512; // t - 7
    wire    [63:0] out_4_512; // t - 2
    wire    [63:0] T1_512;
    wire    [63:0] T2_512;
    
    eps_1       #(.SIZE(32)) eps1_256    (.x(e[31:0]), .out(out_1_256));
    Choice      #(.SIZE(32)) Ch_256      (.x(e[31:0]), .y(f[31:0]), .z(g[31:0]), .out(out_2_256));
    eps_0       #(.SIZE(32)) eps0_256    (.x(a[31:0]), .out(out_3_256));
    Majority    #(.SIZE(32)) Mj_256      (.x(a[31:0]), .y(b[31:0]), .z(c[31:0]), .out(out_4_256));
    
    eps_1_512   #(.SIZE(64)) eps1_512    (.x(e), .out(out_1_512));
    Choice      #(.SIZE(64)) Ch_512      (.x(e), .y(f), .z(g), .out(out_2_512));
    eps_0_512   #(.SIZE(64)) eps0_512    (.x(a), .out(out_3_512));
    Majority    #(.SIZE(64)) Mj_512      (.x(a), .y(b), .z(c), .out(out_4_512));
    
    assign T1_256 = out_1_256 + out_2_256 + h[31:0] + W[31:0] + K_256;
    assign T2_256 = out_3_256 + out_4_256;
    
    assign T1_512 = out_1_512 + out_2_512 + h + W + K_512;
    assign T2_512 = out_3_512 + out_4_512;
    
    assign a_out = (mode_sha2) ? T1_512 + T2_512 : T1_256 + T2_256;
    assign b_out = (mode_sha2) ? a : {32'h00000000,a[31:0]};
    assign c_out = (mode_sha2) ? b : {32'h00000000,b[31:0]};
    assign d_out = (mode_sha2) ? c : {32'h00000000,c[31:0]};
    assign e_out = (mode_sha2) ? d + T1_512 : d[31:0] + T1_256;
    assign f_out = (mode_sha2) ? e : {32'h00000000,e[31:0]};
    assign g_out = (mode_sha2) ? f : {32'h00000000,f[31:0]};
    assign h_out = (mode_sha2) ? g : {32'h00000000,g[31:0]};
    
endmodule

module Choice # (
    parameter SIZE = 32
    )(
    input [SIZE-1:0] x,
    input [SIZE-1:0] y,
    input [SIZE-1:0] z,
    output [SIZE-1:0] out
    );
    
    assign out = (x & y) ^ (~x & z);
endmodule

module Majority # (
    parameter SIZE = 32
    )(
    input [SIZE-1:0] x,
    input [SIZE-1:0] y,
    input [SIZE-1:0] z,
    output [SIZE-1:0] out
    );
    
    assign out = (x & y) ^ (x & z) ^ (y & z);
endmodule
