`timescale 1ns / 1ps

module fqmult_pipe(
    input clk,
    input [15:0] a,
    input [15:0] b,
    output [15:0] t
    );
    
    reg  [31:0] mult;
    wire [31:0] a32;
    wire [31:0] b32;
    
    assign a32 = {{16{a[15]}},a};
    assign b32 = {{16{b[15]}},b};
    
    always @(posedge clk) mult <= a32*b32;
    
    montgomery_reduce MR (.a(mult), .t(t));
    
endmodule

module fqmult_zeta #(
    parameter ZETA_INV = 1441,
    parameter QINV = 62209,
    parameter KYBER_Q = 3329
    )(
    input [15:0] a,
    output [15:0] t
    );
    
    wire  [31:0] mult;
    wire [31:0] a32;
    
    assign a32 = {{16{a[15]}},a};
    assign mult = a32*ZETA_INV;

    montgomery_reduce MR (.a(mult), .t(t));
    
endmodule
