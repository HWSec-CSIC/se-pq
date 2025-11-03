`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 11/07/2025
// Design Name: roc_bxt.v
// Module Name: roc_bxt
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_2.0 Bit Extractor
//
// Additional Comment:
//
//      Original VHDL by santiago@imse-cnm.csic.es
//
////////////////////////////////////////////////////////////////////////////////////

module roc_bxt #(
                 parameter Nbc = 14                 //-- Maximum Number of bits of Counters
                 ) 
                 (
                  input  wire           rst,        //-- Reset
                  input  wire           str,        //-- Start
                  // input  wire [Nbc-1:0] sel_nbc,    //-- Select Bits of the Counter
                  input  wire           ro1,        //-- RO1 clk
                  input  wire           ro2,        //-- RO2 clk
                  output reg            busy,       //-- Busy output signal
                  output reg  [Nbc-1:0] rdata       //-- Output data
                  );

    //-- Wires to connect the two roc_cnt instances
    wire [Nbc-1:0] counter_1;
    wire [Nbc-1:0] counter_2;
    wire           full_1;
    wire           full_2;
    wire           nfull_1;
    wire           nfull_2;
    wire           full;

    //-- Invert the 'full' signals to use as counter enables
    assign nfull_1 = ~full_1;
    assign nfull_2 = ~full_2;

    //-- Instantiate the first counter. It runs as long as the second counter is not full.
    roc_cnt #(
              .Nbc(Nbc)
              ) 
              COUNTER_1 
              (
               .clk(ro1),
               .rst(rst),
               // .sel_nbc(sel_nbc),
               .count_en(nfull_2),
               .counter(counter_1),
               .full(full_1)
               );

    //-- Instantiate the second counter. It runs as long as the first counter is not full.
    roc_cnt #(
              .Nbc(Nbc)
              ) 
              COUNTER_2
              (
               .clk(ro2),
               .rst(rst),
               // .sel_nbc(sel_nbc),
               .count_en(nfull_1),
               .counter(counter_2),
               .full(full_2)
               );
               
    //-- The race is complete if either counter is full
    assign full = full_1 | full_2;
               
    //-- Generate the 'busy' signal.
    always @(posedge str or posedge rst or posedge full) begin
        if (rst == 1'b1 || full == 1'b1) begin
            busy <= 1'b0;
        end
        else begin // This branch is only taken on posedge str
            busy <= 1'b1;
        end
    end

    //-- Generate the output data based on which counter finished first.
    always @(*) begin
        if (full) begin
            if (full_1) begin
                rdata = counter_2;
            end
            else begin
                rdata = counter_1;
            end
        end
        else begin
            rdata = 0;
        end
    end

endmodule
