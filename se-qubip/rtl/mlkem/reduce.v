`timescale 1ns / 1ps

module montgomery_reduce #(
    parameter QINV = 62209,
    parameter KYBER_Q = 3329
    )(
    input [31:0] a,
    output [15:0] t
    );
    
    wire [15:0] u;
    wire [31:0] t1;
    wire [15:0] t2;
    
    assign u = a[15:0]*QINV;
    assign t1 = {{16{u[15]}},u}*KYBER_Q;
    assign t2 = a[31:16] - t1[31:16];
    
    assign t = t2;
    
endmodule


module barret_reduce_pipe #(
    parameter KYBER_Q = 3329,
    parameter v = ((1 << 26) + (KYBER_Q/2))/KYBER_Q
    )(
    input clk,
    input [15:0] a,
    output [15:0] t
    );
    
    wire    [31:0] t1;
    wire     [31:0] t2;
    
    reg [31:0] mult;
    wire [31:0] a32;
    reg [31:0] a32_reg;
    assign a32 = {{16{a[15]}},a};
    always @(posedge clk) a32_reg <= a32;
    
    always @(posedge clk) mult <= v*a32;
    //assign t1 = {{26{mult[31]}},mult[31:26]};
    assign t1 = (mult + (1'b1 << 25));
    
    assign t2 = {{26{t1[31]}},t1[31:26]}*KYBER_Q;
    
    assign t = a32_reg - t2;
    
endmodule