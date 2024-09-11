`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.07.2023 19:51:52
// Design Name: 
// Module Name: sha2_mem
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


module sha2_message_schedule (
    input           clk,
    input           rst,
    input           load,
    input           start,
    input           mode_sha2,  // 0: sha_256, 1: sha_384, sha_512, sha_512/256
    input   [63:0]  data_in,
    output  [63:0]  data_out
    );
    
    reg [63:0] MEM [15:0];
    wire [63:0] data_au;
    
    au_weight 
    AU_WEIGHT (
        .mode_sha2(mode_sha2),
        .data_in_1(MEM[0]), .data_in_2(MEM[1]),
        .data_in_3(MEM[9]), .data_in_4(MEM[14]),
        .data_out(data_au)
    );
   
    assign data_out = MEM[0];
    
    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin
        
        if(i == 15) begin
            always @(posedge clk) begin
                if (!rst) MEM[i] <= 0;
                else begin
                    if(load)       MEM[15]      <= data_in;
                    else if(start) MEM[15]      <= data_au;
                    else            MEM[i]      <= MEM[i];
                end
            end
        end
        else begin
            always @(posedge clk) begin
                if (!rst) MEM[i] <= 0;
                else begin
                    if(load | start)        MEM[i]      <= MEM[i+1];
                    else                    MEM[i]      <= MEM[i];
                end
            end
        end
        end
    endgenerate
endmodule

module au_weight
    (
    input        mode_sha2, // 0: sha_256, 1: sha_384, sha_512, sha_512/256
    input [63:0] data_in_1,
    input [63:0] data_in_2,
    input [63:0] data_in_3,
    input [63:0] data_in_4,
    output [63:0] data_out
    );
    
    wire [31:0] out_1_256; // t - 16
    wire [31:0] out_2_256; // t - 15
    wire [31:0] out_3_256; // t - 7
    wire [31:0] out_4_256; // t - 2
    wire [31:0] out_au_256;
    
    wire [63:0] out_1_512; // t - 16
    wire [63:0] out_2_512; // t - 15
    wire [63:0] out_3_512; // t - 7
    wire [63:0] out_4_512; // t - 2
    wire [63:0] out_au_512;
    
    assign out_1_256 = data_in_1[31:0];
    sigma_0 #(.SIZE(32)) s0_256 (.x(data_in_2[31:0]), .out(out_2_256));
    assign out_3_256 = data_in_3[31:0];
    sigma_1 #(.SIZE(32)) s1_256 (.x(data_in_4[31:0]), .out(out_4_256));
    assign out_au_256 = out_1_256 + out_2_256 + out_3_256 + out_4_256;
    
    assign out_1_512 = data_in_1;
    sigma_0_512 #(.SIZE(64)) s0_512 (.x(data_in_2), .out(out_2_512));
    assign out_3_512 = data_in_3;
    sigma_1_512 #(.SIZE(64)) s1_512 (.x(data_in_4), .out(out_4_512));
    assign out_au_512 = out_1_512 + out_2_512 + out_3_512 + out_4_512;
    
    assign data_out = (mode_sha2) ? out_au_512 : {32'h00000000,out_au_256};
    
endmodule

module sigma_0 #(
   parameter SIZE = 32
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(7),.SIZE(SIZE)) RTOT_7 (.x(x), .out(out_1));   
    RTOR #(.ROT(18),.SIZE(SIZE)) RTOT_18 (.x(x), .out(out_2));  
    assign out_3 = x >> 3;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module sigma_1 #(
   parameter SIZE = 32
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(17),.SIZE(SIZE)) RTOT_17 (.x(x), .out(out_1));   
    RTOR #(.ROT(19),.SIZE(SIZE)) RTOT_19 (.x(x), .out(out_2));  
    assign out_3 = x >> 10;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module sigma_0_512 #(
   parameter SIZE = 64
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(1),.SIZE(SIZE)) RTOT_1 (.x(x), .out(out_1));   
    RTOR #(.ROT(8),.SIZE(SIZE)) RTOT_8 (.x(x), .out(out_2));  
    assign out_3 = x >> 7;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module sigma_1_512 #(
   parameter SIZE = 64
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(19),.SIZE(SIZE)) RTOT_19 (.x(x), .out(out_1));   
    RTOR #(.ROT(61),.SIZE(SIZE)) RTOT_61 (.x(x), .out(out_2));  
    assign out_3 = x >> 6;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_0 #(
   parameter SIZE = 32
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(2),.SIZE(SIZE)) RTOT_2 (.x(x), .out(out_1));   
    RTOR #(.ROT(13),.SIZE(SIZE)) RTOT_13 (.x(x), .out(out_2));
    RTOR #(.ROT(22),.SIZE(SIZE)) RTOT_22 (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_1 #(
   parameter SIZE = 32
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(6),.SIZE(SIZE)) RTOT_6 (.x(x), .out(out_1));   
    RTOR #(.ROT(11),.SIZE(SIZE)) RTOT_11 (.x(x), .out(out_2));
    RTOR #(.ROT(25),.SIZE(SIZE)) RTOT_25 (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_0_512 #(
   parameter SIZE = 64
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(28),.SIZE(SIZE)) RTOT_28 (.x(x), .out(out_1));   
    RTOR #(.ROT(34),.SIZE(SIZE)) RTOT_34 (.x(x), .out(out_2));
    RTOR #(.ROT(39),.SIZE(SIZE)) RTOT_39 (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_1_512 #(
   parameter SIZE = 64
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR #(.ROT(14),.SIZE(SIZE)) RTOT_14 (.x(x), .out(out_1));   
    RTOR #(.ROT(18),.SIZE(SIZE)) RTOT_18 (.x(x), .out(out_2));
    RTOR #(.ROT(41),.SIZE(SIZE)) RTOT_41 (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module RTOR # (
    parameter ROT = 7,
    parameter SIZE = 32
    )(
    input [SIZE-1:0] x,
    output [SIZE-1:0] out
    );
    
    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    
    assign out_1 = x >> ROT;
    assign out_2 = x[ROT-1:0];
    assign out = {out_2[ROT-1:0],out_1[SIZE-1-ROT:0]};
    
endmodule 