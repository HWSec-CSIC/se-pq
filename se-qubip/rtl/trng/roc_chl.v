`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 11/07/2025
// Design Name: roc_bnk.v
// Module Name: roc_bnk
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_2.0 Challenge Generator
//
// Additional Comment:
//
//      Original VHDL by santiago@imse-cnm.csic.es
//
////////////////////////////////////////////////////////////////////////////////////


module roc_chl #(
                 parameter CG_TYPE = 1      //-- Challenge Generator Type: Counter(1), LFSR(2)
                 ) 
                 (
                  input  wire       clk,    //-- Clock Signal
                  input  wire       reset,  //-- Reset Active High
                  output wire [7:0] cnf1,   //-- Configuration Selection #1
                  output wire [7:0] cnf2    //-- Configuration Selection #2
                  );

    //-- Generate block to select between Counter and LFSR implementation
    generate
        //-- Implementation 1: Binary Counter
        if (CG_TYPE == 1) begin : CNT_gen
            reg [15:0] counter;

            always @(posedge clk) begin
                if (reset) begin
                    counter <= 16'hFFFF; 
                end
                else begin
                    counter <= counter + 1;
                end
            end
            
            assign cnf1 = counter[7:0];
            assign cnf2 = counter[15:8];
        end

        //-- Implementation 2: LFSR
        else if (CG_TYPE == 2) begin : LFSR_gen
            //-- Combinational logic for the feedback term. Polynome "1011010000000000" on lfsr(0..15) 
            //-- with feedback from lfsr[0] and taps at 1..15 corresponds to taps at 0, 2, 3, 5.
            reg  [15:0] lfsr;
            
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    lfsr <= 16'h0001;
                end
                else begin
                    // Right-shift the register, with feedback becoming the new MSB
                    lfsr <= {lfsr[5] ^ lfsr[3] ^ lfsr[2] ^ lfsr[0], lfsr[15:1]};
                end
            end
            
            assign cnf1 = lfsr[7:0];
            assign cnf2 = lfsr[15:8];
        end
    endgenerate
    
endmodule
