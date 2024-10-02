/**
  * @file tb_sha3.v
  * @brief SHA3 Test bench Module
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

`timescale 1ns / 1ps



module tb_sha3(
    
    );
    
  parameter PERIOD = 10;
  parameter D_WIDTH = 64;
  
    // Declaraci�n de se�ales para conectar con el DUT (Device Under Test)
  reg                   clk;
  reg                   rst; 
  reg   [D_WIDTH-1:0]   data_in;
  reg   [7:0]           add;
  reg   [3:0]           control;
  wire  [D_WIDTH-1:0]   data_out;
  wire                  end_op;

  // Instanciaci�n del DUT
  sha3_xl sha3_xl (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .add(add),
    .control(control),
    .data_out(data_out),
    .end_op(end_op)
  );

  integer i;
  
    reg [D_WIDTH - 1:0] MEM_IN [0:24];
    reg [D_WIDTH - 1:0] LEN;
  // Bloque de inicializaci�n para las se�ales de prueba
  initial begin
    LEN = 64;
    MEM_IN[0] = 64'hb2cfa3f83ffa53af; 
    MEM_IN[1] = 0;
    MEM_IN[2] = 0;
    MEM_IN[3] = 0;
    MEM_IN[4] = 0;
    MEM_IN[5] = 0; 
    MEM_IN[6] = 0;
    MEM_IN[7] = 0;
    MEM_IN[8] = 0;
    MEM_IN[9] = 0;
    MEM_IN[10] = 0;
    MEM_IN[11] = 0;
    MEM_IN[12] = 0;
    MEM_IN[13] = 0;
    MEM_IN[14] = 0;
    MEM_IN[15] = 0; 
    MEM_IN[16] = 0;
    MEM_IN[17] = 0;
    MEM_IN[18] = 0;
    MEM_IN[19] = 0;
    MEM_IN[20] = 0;
    MEM_IN[21] = 0;
    MEM_IN[22] = 0;
    MEM_IN[23] = 0;
    MEM_IN[24] = 0;
       
    rst = 1; control = 4'b0100; add = 0; data_in = 0; #(10*PERIOD);
    rst = 0; control = 4'b0100; add = 0; data_in = 0; #(10*PERIOD);
    rst = 1; control = 4'b0100; add = 0; data_in = 0; #(10*PERIOD);
    rst = 1; control = 4'b0101; add = 0; data_in = LEN / 8; #(5*PERIOD); // Load length
    
    for (i = 0; i < 25; i = i + 1) begin
        rst = 1; control = 4'b0110; add = i; data_in = MEM_IN[i]; #(PERIOD); // Load add
        rst = 1; control = 4'b0110; add = i; data_in = MEM_IN[i]; #(PERIOD); // Load data
    end
    
    rst = 1; control = 4'b0111; add = 0; data_in = 0; #(PERIOD); // Load data

  end
  
  // Generaci�n de la se�al de reloj
  initial begin
    clk = 0;
    forever #(PERIOD) clk = ~clk; // Cambia el estado del reloj cada 5 unidades de tiempo
  end
endmodule
