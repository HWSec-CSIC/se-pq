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


module sha2_message_schedule_eddsa #(
    parameter WIDTH = 32,
    parameter MODE = 256
    )(
    input wire           clk,
    input wire           rst,
    input wire           load,
    input wire           start,
    input wire   [WIDTH-1:0]  data_in,
    output wire [WIDTH-1:0]  data_out
    );
    
    reg [WIDTH-1:0] MEM [15:0];
    wire [WIDTH-1:0] data_au;
    
    au_weight_eddsa #(.WIDTH(WIDTH), .MODE(MODE)) 
    AU_WEIGHT_eddsa (
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

module au_weight_eddsa #
    (
    parameter WIDTH = 32,
    parameter MODE = 256
    )(
    input wire [WIDTH-1:0] data_in_1,
    input wire [WIDTH-1:0] data_in_2,
    input wire [WIDTH-1:0] data_in_3,
    input wire [WIDTH-1:0] data_in_4,
    output wire [WIDTH-1:0] data_out
    );
    
    wire [WIDTH-1:0] out_1; // t - 16
    wire [WIDTH-1:0] out_2; // t - 15
    wire [WIDTH-1:0] out_3; // t - 7
    wire [WIDTH-1:0] out_4; // t - 2
    wire [WIDTH-1:0] out_au;
    
    generate 
        if(MODE == 224 | MODE == 256) begin
            assign out_1 = data_in_1;
            sigma_0_eddsa #(.SIZE(WIDTH)) s0_eddsa (.x(data_in_2), .out(out_2));
            assign out_3 = data_in_3;
            sigma_1_eddsa #(.SIZE(WIDTH)) s1_eddsa (.x(data_in_4), .out(out_4));
            assign out_au = out_1 + out_2 + out_3 + out_4;
        end
        else if(MODE == 384 | MODE == 512) begin
            assign out_1 = data_in_1;
            sigma_0_512_eddsa #(.SIZE(WIDTH)) s0_eddsa (.x(data_in_2), .out(out_2));
            assign out_3 = data_in_3;
            sigma_1_512_eddsa #(.SIZE(WIDTH)) s1_eddsa (.x(data_in_4), .out(out_4));
            assign out_au = out_1 + out_2 + out_3 + out_4;
        end
    endgenerate
    
    assign data_out = out_au;
    
endmodule

module sigma_0_eddsa #(
   parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(7),.SIZE(SIZE)) RTOT_7_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(18),.SIZE(SIZE)) RTOT_18_eddsa (.x(x), .out(out_2));  
    assign out_3 = x >> 3;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module sigma_1_eddsa #(
   parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(17),.SIZE(SIZE)) RTOT_17_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(19),.SIZE(SIZE)) RTOT_19_eddsa (.x(x), .out(out_2));  
    assign out_3 = x >> 10;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module sigma_0_512_eddsa #(
   parameter SIZE = 64
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(1),.SIZE(SIZE)) RTOT_1_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(8),.SIZE(SIZE)) RTOT_8_eddsa (.x(x), .out(out_2));  
    assign out_3 = x >> 7;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module sigma_1_512_eddsa #(
   parameter SIZE = 64
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(19),.SIZE(SIZE)) RTOT_19_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(61),.SIZE(SIZE)) RTOT_61_eddsa (.x(x), .out(out_2));  
    assign out_3 = x >> 6;
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_0_eddsa #(
   parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(2),.SIZE(SIZE)) RTOT_2_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(13),.SIZE(SIZE)) RTOT_13_eddsa (.x(x), .out(out_2));
    RTOR_eddsa #(.ROT(22),.SIZE(SIZE)) RTOT_22_eddsa (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_1_eddsa #(
   parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(6),.SIZE(SIZE)) RTOT_6_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(11),.SIZE(SIZE)) RTOT_11_eddsa (.x(x), .out(out_2));
    RTOR_eddsa #(.ROT(25),.SIZE(SIZE)) RTOT_25_eddsa (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_0_512_eddsa #(
   parameter SIZE = 64
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(28),.SIZE(SIZE)) RTOT_28_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(34),.SIZE(SIZE)) RTOT_34_eddsa (.x(x), .out(out_2));
    RTOR_eddsa #(.ROT(39),.SIZE(SIZE)) RTOT_39_eddsa (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module eps_1_512_eddsa #(
   parameter SIZE = 64
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );

    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    wire [SIZE-1:0] out_3;
    
    RTOR_eddsa #(.ROT(14),.SIZE(SIZE)) RTOT_14_eddsa (.x(x), .out(out_1));   
    RTOR_eddsa #(.ROT(18),.SIZE(SIZE)) RTOT_18_eddsa (.x(x), .out(out_2));
    RTOR_eddsa #(.ROT(41),.SIZE(SIZE)) RTOT_41_eddsa (.x(x), .out(out_3));    
    assign out = out_1 ^ out_2 ^ out_3;   
     
endmodule

module RTOR_eddsa # (
    parameter ROT = 7,
    parameter SIZE = 32
    )(
    input wire [SIZE-1:0] x,
    output wire [SIZE-1:0] out
    );
    
    wire [SIZE-1:0] out_1;
    wire [SIZE-1:0] out_2;
    
    assign out_1 = x >> ROT;
    assign out_2 = x[ROT-1:0];
    assign out = {out_2[ROT-1:0],out_1[SIZE-1-ROT:0]};
    
endmodule 