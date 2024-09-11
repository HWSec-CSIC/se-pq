`default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 11/10/2023
// Design Name: genram.v
// Module Name: genram
// Project Name: RSA Accelerator
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Generic RAM module
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module genram #(        
                parameter AW = 6,   				            //-- Adress width
                parameter DW = 8,					            //-- Data witdh
                parameter INIT = 0,                             //-- Initialize Memory ?
                parameter ROMFILE = "Base_Point_Powers.mem"     //-- File to read
		        )  	                          
               (                                
                input  wire clk,                    //-- Clock Signal
                input  wire wr,                     //-- Write
                input  wire rd,                     //-- Read
                input  wire [AW-1:0] addr,          //-- Address
                input  wire [DW-1:0] data_in,       //-- Write Data 
                output reg  [DW-1:0] data_out       //-- Read Data
                );  

    //-- Calculate all possible memory instances
    localparam NPOS = 2 ** AW;
    
    //-- Memory
    reg [DW-1: 0] ram [0: NPOS-1];
    
    //-- Read and Write Memory
    always @(posedge clk) begin
        if (wr)
            ram[addr] <= data_in;
        
        if (rd)
            data_out <= ram[addr];
    end
    
    
    //-- Load in memory the file ROMFILE
    //-- Values must be in HEX
    generate if (INIT == 1) begin
        initial begin
          $readmemh(ROMFILE, ram);
        end
    end
    endgenerate
    
   //  assign data_out = ram[addr];
    
endmodule
