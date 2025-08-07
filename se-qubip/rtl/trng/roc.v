`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 11/07/2025
// Design Name: roc.v
// Module Name: roc
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_2.0 Ring_Oscillator Bank
//
// Additional Comment:
//
//      Original VHDL by santiago@imse-cnm.csic.es
//
////////////////////////////////////////////////////////////////////////////////////

module roc (
            input  wire       enx,      //-- Enable X
            input  wire       eny,      //-- Enable Y
            input  wire [7:0] cnf,      //-- Configuration Selection
            output wire [1:0] ro        //-- RO Output
            );

       // Internal wires for the two ring oscillators
       (* ALLOW_COMBINATORIAL_LOOPS = "TRUE", DONT_TOUCH = "TRUE" *)
       wire w00, w10, w20, w30;
       
       (* ALLOW_COMBINATORIAL_LOOPS = "TRUE", DONT_TOUCH = "TRUE" *)
       wire w01, w11, w21, w31;
       
       //--  RO_0
       //-- Each LUT forms one stage of the ring oscillator.
       //-- The feedback loop is from w30 back to the input of and0.
       (* BEL = "A6LUT", RLOC = "X0Y0" *)
       LUT6 #(
              .INIT(64'hA000C000C000A000)
              ) 
              and0
              (
               .O(w00), 
               .I5(cnf[7]), 
               .I4(cnf[6]), 
               .I3(eny), 
               .I2(enx), 
               .I1(w30), 
               .I0(w30)
               );

       (* BEL = "A6LUT", RLOC = "X1Y0" *)
       LUT6 #(
              .INIT(64'h555533330F0F00FF)
              ) 
              inv10
              (
               .O(w10), 
               .I5(cnf[5]), 
               .I4(cnf[4]), 
               .I3(w00), 
               .I2(w00), 
               .I1(w00), 
               .I0(w00)
               );

       (* BEL = "B6LUT", RLOC = "X0Y0" *)
       LUT6 #(
              .INIT(64'h555533330F0F00FF)
              ) 
              inv20 
              (
               .O(w20), 
               .I5(cnf[3]), 
               .I4(cnf[2]), 
               .I3(w10), 
               .I2(w10), 
               .I1(w10), 
               .I0(w10)
               );

       (* BEL = "B6LUT", RLOC = "X1Y0" *)
       LUT6 #(
              .INIT(64'h555533330F0F00FF)
              ) 
              inv30 
              (
               .O(w30), 
               .I5(cnf[1]), 
               .I4(cnf[0]), 
               .I3(w20), 
               .I2(w20), 
               .I1(w20), 
               .I0(w20)
               );


       //--  RO_1
       //-- Each LUT forms one stage of the ring oscillator.
       // --The feedback loop is from w31 back to the input of and1.
       (* BEL = "C6LUT", RLOC = "X0Y0" *)
       LUT6 #(
              .INIT(64'hA000C000C000A000)
              ) 
              and1 
              (
               .O(w01), 
               .I5(cnf[7]), 
               .I4(cnf[6]), 
               .I3(eny), 
               .I2(enx), 
               .I1(w31), 
               .I0(w31)
               );

       (* BEL = "C6LUT", RLOC = "X1Y0" *)
       LUT6 #(
              .INIT(64'h555533330F0F00FF)
              ) 
              inv11 
              (
               .O(w11), 
               .I5(cnf[5]), 
               .I4(cnf[4]), 
               .I3(w01), 
               .I2(w01), 
               .I1(w01), 
               .I0(w01)
               );

       (* BEL = "D6LUT", RLOC = "X0Y0" *)
       LUT6 #(
              .INIT(64'h555533330F0F00FF)
              ) 
              inv21 
              (
               .O(w21), 
               .I5(cnf[3]), 
               .I4(cnf[2]), 
               .I3(w11), 
               .I2(w11), 
               .I1(w11), 
               .I0(w11)
               );

       (* BEL = "D6LUT", RLOC = "X1Y0" *)
       LUT6 #(
              .INIT(64'h555533330F0F00FF)
              ) 
              inv31 
              (
              .O(w31), 
              .I5(cnf[1]), 
              .I4(cnf[0]), 
              .I3(w21), 
              .I2(w21), 
              .I1(w21), 
              .I0(w21)
              );

       // Assign the outputs of the first stage of each RO
       assign ro[0] = w00;
       assign ro[1] = w01;

endmodule
