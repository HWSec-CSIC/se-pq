`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 21/07/2025
// Design Name: roc_sim.v
// Module Name: roc_sim
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_2.0 Ring_Oscillator Bank for SIMULATION
//
// Additional Comment:
//
//      Verilog code for a SIMULATED Ring_Oscillator Bank
//
////////////////////////////////////////////////////////////////////////////////////

module roc_sim (
                input  wire       clk,      //-- Clock Signal for Simulation
                output wire [3:0] ro        //-- Pairs of RO Output
                );

    reg [3:0] random_value;

    always @(posedge clk) random_value <= $random[3:0];
    
    assign ro[0] = random_value[0];
    assign ro[1] = random_value[1];
    assign ro[2] = random_value[2];
    assign ro[3] = random_value[3];

endmodule
