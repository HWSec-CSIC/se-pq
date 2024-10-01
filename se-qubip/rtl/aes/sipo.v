// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 18/10/2023
// Design Name: sipo.v
// Module Name: sipo
// Project Name: RSA Accelerator
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Verilog code for Serial Input Parallel Output interface
//		
// Additional Comment
//
//      Translation of VHDL file from santiago@imse-cnm.csic.es
//
////////////////////////////////////////////////////////////////////////////////////


module sipo #(
              parameter R_DATA_WIDTH = 32,
              parameter N_REG = 8,
              parameter N_REG_BITS = (N_REG == 1) ? 1 : $clog2(N_REG)
              )
             (
              input  wire clk,                                          //-- Clock Signal 
              input  wire rst,                                          //-- Reset Signal 
              input  wire load,                                         //-- Load Signal
              input  wire [N_REG_BITS-1:0] addr,                        //-- Address
              input  wire [R_DATA_WIDTH-1:0] din,                       //-- Parallel Input 
              output reg  [R_DATA_WIDTH*N_REG-1:0] dout                 //-- Serial Output
              );
    
    
    always @(posedge clk) begin
        if (rst)
            dout <= 0;
        else if (load)
            dout[R_DATA_WIDTH*addr+:R_DATA_WIDTH] <= din;
    end
    
endmodule
