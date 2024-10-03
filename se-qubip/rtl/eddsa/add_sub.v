/**
  * @file add_sub.v
  * @brief ADD-SUB Module
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/

// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 22/02/2024
// Design Name: add_sub.v
// Module Name: add_sub
// Project Name: EDSA25519 ECC Accelerator
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Adder/Subtractor Module with reduction mod p = 2**255-19
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module add_sub #(parameter BIT_LENGTH = 256)(
                                             input  wire clk,                    //-- Clock Signal
                                             input  wire rst,                    //-- Reset Signal
                                             input  wire mode,                   //-- Mode (0): Add | (1): Sub
                                             input  wire [BIT_LENGTH-1:0] A,     //-- Input A
                                             input  wire [BIT_LENGTH-1:0] B,     //-- Input B
                                             output wire [BIT_LENGTH-1:0] C      //-- Output C
                                             );
    
    
    //--------------------------------------
	//-- Parameters             
	//--------------------------------------

	localparam P = 256'h7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
	
	
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------
    
    reg [BIT_LENGTH-1:0] C_0;
    wire sub_comp;
    wire add_comp;
    
    
    //--------------------------------------
	//-- Addition/Subtraction       
	//--------------------------------------
    
    assign sub_comp = (A > B)   ? 1 : 0;
    assign add_comp = (P > C_0) ? 1 : 0;

    
    //--------------------------------------
	//-- Addition/Subtraction       
	//--------------------------------------
	
    always @(posedge clk) begin
        if (rst) 
            C_0 <= 0;
        else if (mode && sub_comp)
            C_0 <= A - B;
        else if (mode && !sub_comp)
            C_0 <= P - (B - A);
        else 
            C_0 <= A + B;
    end
    /*
    always @(posedge clk) begin
        if (rst) 
            C <= 0;
        else if (add_comp)
            C <= C_0;
        else
            C <= C_0 - P;
    end
    */
    assign C = (add_comp) ? C_0 : (C_0 - P);
    
    
endmodule
