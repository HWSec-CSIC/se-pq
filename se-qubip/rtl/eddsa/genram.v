/**
  * @file genram.v
  * @brief Generic RAM Module
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
