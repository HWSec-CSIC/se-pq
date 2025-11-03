////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 25/06/2025
// Design Name: genram.v
// Module Name: genram
// Project Name: picoSoC SE-QUBIP Implementation
// Target Devices: ZCU104
// Tool Versions: Vivado 2024.1.2
// Description: 
//		
//    Generic, synthesizable, true dual-port RAM primitive.
//    This module is intended to be instantiated multiple times to build a larger
//    memory subsystem. It uses a write-first memory access scheme.
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module genram #(        
                parameter AW = 6,   				//-- Adress width
                parameter DW = 8,					//-- Data witdh
                parameter INIT = 0,                 //-- Initialize Memory ?
                parameter ROMFILE = "ROM.mem"       //-- File to read
		        )  	                          
               (                                
                input  wire clk_A,                  //-- Clock Signal PORT A
                input  wire clk_B,                  //-- Clock Signal PORT B
                input  wire wr_A,                   //-- Enable Write Address PORT A
                input  wire wr_B,                   //-- Enable Write Address PORT B
                input  wire [AW-1:0] addr_A,        //-- Address PORT A
                input  wire [AW-1:0] addr_B,        //-- Address PORT B
                input  wire [DW-1:0] data_in_A,     //-- Write Data PORT A
                input  wire [DW-1:0] data_in_B,     //-- Write Data PORT B
                output reg  [DW-1:0] data_out_A,    //-- Read Data PORT A
                output reg  [DW-1:0] data_out_B     //-- Read Data PORT B
                );  

    //-- Calculate the number of memory locations based on address width
    localparam NPOS = 2 ** AW;
    
    //-- Memory Definition
    reg [DW-1:0] ram [NPOS-1:0];
    
    //-- Port A Logic
    always @(posedge clk_A) begin
        data_out_A <= ram[addr_A];
        if (wr_A) begin
            ram[addr_A] <= data_in_A;
        end
    end
    
    //-- Port B Logic
    always @(posedge clk_B) begin
        data_out_B <= ram[addr_B];
        if (wr_B) begin
            ram[addr_B] <= data_in_B;
        end
    end
    
    //-- Optional Memory Initialization
    //-- Values of ROM.mem must be in HEX
    generate if (INIT == 1) begin
        initial begin
          $readmemh(ROMFILE, ram);
        end
    end
    endgenerate
        
endmodule
