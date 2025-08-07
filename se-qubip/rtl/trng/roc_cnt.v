`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 11/07/2025
// Design Name: roc_cnt.v
// Module Name: roc_cnt
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_2.0 Binary Counter
//
// Additional Comment:
//
//      Original VHDL by santiago@imse-cnm.csic.es. Added a sel_nbc signal
//      to allow dynamic reconfiguration of the number of bits of the counter.
//      This additional control must be included in the control register.
//
////////////////////////////////////////////////////////////////////////////////////

module roc_cnt #(
                 parameter Nbc = 14                     //-- Maximum Number of Bits of Counter
                 ) 
                 (
                  input  wire           clk,            //-- Clock Signal (RO)
                  input  wire           rst,            //-- Reset Active High
                  // input  wire [Nbc-1:0] sel_nbc,        //-- Select Bits of the Counter
                  input  wire           count_en,       //-- Count Enable
                  output reg            full,           //-- Full Signal
                  output reg  [Nbc-1:0] counter         //-- Counter Output
                  );

    localparam [Nbc-1:0] MASK = { {(Nbc-3){1'b1}}, 3'b100 };

    // wire [Nbc-1:0] mask = MASK & sel_nbc;
    
    //-- Counter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            full    <= 1'b0;
        end 
        else if (count_en) begin
            counter <= counter + 1;
            
            // The 'full' signal becomes '1' when the counter reaches the MASK value.
            // It is "sticky" and will not go low again until a reset.
            // The check uses the value of counter from *before* the increment
            if (counter == /* mask */ MASK) begin
                full <= 1'b1;
            end
        end
    end

endmodule
