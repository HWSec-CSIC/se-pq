/**
  * @file keccak.v
  * @brief KECCAK Module
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


module sha3_shake_keccak#(
    parameter COUNTER = 1,
    parameter LENGTH = 1600,
    parameter D_WIDTH = 64
    )(
    input                           i_clk,
    input                           i_rst,
    input   [D_WIDTH-1:0]           i_data_in,
    input   [7:0]                   i_add,
    input   [7:0]                   i_control,
    output  [D_WIDTH-1:0]           o_data_out,
    output                          o_end_op,
    output  [3:0]                   fsm_state
    );
    
    // --- In Signals --- //
    wire    [LENGTH - 1:0] P;
    
    // --- Out Signals --- //
    wire    [LENGTH - 1:0]      P_o;
    wire    [D_WIDTH - 1:0]     P_out [0:((LENGTH/D_WIDTH) - 1)];
    genvar i;
    generate 
        for (i = 0; i < (LENGTH/D_WIDTH); i = i + 1) begin
            assign P_out[i] = P_o[(((i+1)*D_WIDTH)-1):(i*D_WIDTH)];
        end
    endgenerate
    
    assign o_data_out = P_out[i_add];
    
    wire fin;
    reg end_op_reg;
    assign o_end_op = end_op_reg;
    always @(posedge i_clk) end_op_reg <= fin;
    
    // --- Control signals --- //
    wire reset;
    wire load_length;
    wire load_data;
    wire start;
    reg  padding;
    
    wire shake128;
    wire shake256;
    wire sha3_256;
    wire sha3_512;
    
    wire fsm_start_reset;
    wire fsm_load_length;
    wire fsm_load_data;
    wire fsm_start;
    wire fsm_en_shake;
    wire fsm_reset_round;
    
    wire [7:0] add_reset;
    
    
    /*
    wire shake;
    wire ini_shake;
    reg  reg_start;
    reg  en_shake;
    reg  save_shake;
    */
    
    assign reset        =   i_rst;   // XX00 -> RESET
    assign load_length  =   !i_control[1] &  i_control[0];            // XX01 -> LOAD_LENGTH   
    assign load_data    =    i_control[1] & !i_control[0];            // XX10 -> LOAD_DATA
    assign start        =    i_control[1] &  i_control[0];           // XX11 -> START
    
    assign shake128     = !i_control[3] & !i_control[2]; // 00XX -> SHAKE128
    assign shake256     = !i_control[3] &  i_control[2]; // 01XX -> SHAKE128
    assign sha3_256     =  i_control[3] & !i_control[2]; // 10XX -> SHA3_256
    assign sha3_512     =  i_control[3] &  i_control[2]; // 11XX -> SHA3_512
    // assign shake        = !i_control[3] & en_shake;    // 0XXX -> SHAKE
    
    /*
    always @(posedge i_clk) reg_start <= start;
    */
    
    always @(posedge i_clk) begin
        if(!reset) begin
            padding <= 0;
        end
        else begin
            if(fsm_load_length) padding <= 1;
            else if(fin)        padding <= 0;
            else                padding <= padding;
        end
    end
    
    /*
    always @(posedge i_clk) begin
        if(!i_rst | load_data) begin
            en_shake    <= 0;
            save_shake  <= 0;
        end
        else begin
            if(padding)             save_shake <= 1;
            else                    save_shake <= save_shake; 
            
            if(save_shake & fin)    en_shake <= 1;
            else                    en_shake <= en_shake;
        end
    end

    assign ini_shake  =  !reg_start & shake; // Power-up Detection  
    */
    
    
    
    // --- PARAMETERS --- //
    
    reg [D_WIDTH-1:0] PAD;
    reg [7:0] RATE;
    reg [7:0] LEN;
    
    always @(posedge i_clk) begin
        if(!reset) begin
            LEN     <= 0;
        end
        else begin
            if(fsm_load_length) LEN     <= i_data_in[7:0];
            else if(fsm_start)  LEN     <= 0;
            else                LEN     <= LEN;
        end
    end
    
    
    
    wire [7:0] pos_pad;
    assign pos_pad = (LEN - (LEN / (D_WIDTH/8))*8)*8; 
    
    always @* begin
        if(shake128) begin
            PAD     =   8'h1F << pos_pad;
            RATE    =   168; 
        end
        else if(shake256) begin
            PAD     =   8'h1F << pos_pad;
            RATE    =   136;
        end 
        else if(sha3_256) begin
            PAD     =   8'h06 << pos_pad;
            RATE    =   136;
        end 
        else begin
            PAD     =   8'h06 << pos_pad;
            RATE    =   72;
        end
    end
    
    
    fsm_sha3_shake_keccak FSM (
    .clk(i_clk), .reset(reset), .load_length(load_length), .load_data(load_data), .start(start), .end_op(end_op_reg), .fsm_state(fsm_state),
    .fsm_start_reset(fsm_start_reset), .add_reset(add_reset),
    .fsm_load_length(fsm_load_length), .fsm_load_data(fsm_load_data), .fsm_start(fsm_start), .fsm_en_shake(fsm_en_shake), .fsm_reset_round(fsm_reset_round)
    );
    
    // ini_shake only put round = 0, ONLY FUNCTION
    generate
        if(COUNTER) begin
            keccak_op_counter    keccak     
            (.clk(i_clk), .rst(reset), .S(P), .S_o(P_o), .reset_round(fsm_reset_round), .ini(fsm_start), 
            .shake(fsm_en_shake), .fin(fin));
        end
        else begin
            keccak_op    keccak     
            (.clk(i_clk), .rst(reset), .S(P), .S_o(P_o), .reset_round(fsm_reset_round), .ini(fsm_start), 
            .shake(fsm_en_shake), .fin(fin));
        end
    endgenerate
     
     pad_module pad_module     
     (.clk(i_clk), .rst(reset), 
     .fsm_start_reset(fsm_start_reset), .load(fsm_load_data), 
     .RATE(RATE), .LEN(LEN), .PAD(PAD),
     .padding(padding), .data_in(i_data_in), 
     .add(i_add), .add_reset(add_reset), .P(P));
     
     /*
     input_module_v2 input_module_v2     
     (.clk(i_clk), .rst(reset), .load(fsm_load_data), .RATE(RATE), .LEN(LEN), .PAD(PAD),
     .padding(padding), .data_in(i_data_in), .add(i_add), .P(P));
      */          
     
    // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction
    
    // ceil function 
    function integer ceil;
      input integer n;
      input integer b;
        for (ceil=0; n>0; ceil=ceil+1)
          n = n - b;
    endfunction
     
endmodule

module fsm_sha3_shake_keccak(
    input clk,  // Clock input
    input reset, // Reset input
    input load_length,
    input load_data,
    input start,
    input end_op,
    output [3:0] fsm_state,
    output [7:0] add_reset,
    output reg fsm_reset,
    output reg fsm_start_reset,
    output reg fsm_load_length,
    output reg fsm_load_data,
    output reg fsm_start,
    output reg fsm_en_shake,
    output reg fsm_reset_round
);

    // Define states
    parameter RESET                 = 4'b0000; // 0
    parameter IDLE                  = 4'b0001; // 1
    parameter LOAD_DATA             = 4'b0010; // 2
    parameter LOAD_DATA_SHAKE       = 4'b0110; // 6
    parameter START                 = 4'b0011; // 3
    parameter END                   = 4'b0100; // 4
    parameter LOAD_LENGTH           = 4'b0101; // 5
    parameter START_SHAKE           = 4'b0111; // 7
    parameter END_SHAKE             = 4'b1000; // 8
    parameter IDLE_SHAKE            = 4'b1001; // 9
    parameter LOAD_LENGTH_STANDBY   = 4'b1010; // 9
    
    reg fsm_shake;
    reg [7:0] fsm_add;
    assign add_reset = fsm_add;
    
    always @(posedge clk) begin
        if(!reset)          fsm_en_shake <= 0;
        else begin
            if(fsm_shake)   fsm_en_shake <= 1;
            else            fsm_en_shake <= fsm_en_shake; 
        end
    end
    
    always @(posedge clk) begin
        if(!reset)          fsm_add <= 0;
        else begin
            if(fsm_start_reset) fsm_add <= fsm_add + 1;
            else                fsm_add <= fsm_add;
        end
    end
    
    reg end_reset;
    
    always @(posedge clk) begin
        if(!reset)                  end_reset <= 0;
        else begin
            if(fsm_add == 7'h18 - 1)    end_reset <= 1; // 24
            else                        end_reset <= end_reset;
        end
    end
    
    // Define state register
    reg [3:0] current_state, next_state;
    
    assign fsm_state = current_state;
    
    // State transition and output logic
    always @(posedge clk) begin
        if (!reset) current_state <= RESET; // Reset to initial state
        else        current_state <= next_state; // Update current state
    end
    
    // Next state and output assignment logic
    always @(*) begin
        case (current_state)
            RESET: begin
                if(end_reset)   next_state = IDLE; // Transition to next state
                else            next_state = RESET;
            end
            IDLE: begin
                if(load_data)           next_state = LOAD_DATA; // Transition to next state
                else if (load_length)   next_state = LOAD_LENGTH;
                else                    next_state = IDLE;
            end
            LOAD_DATA: begin
                if (start)     next_state = START;
                else           next_state = LOAD_DATA;
            end
            START: begin
                if(end_op)      next_state = END; // Transition to next state
                else            next_state = START;
            end
            END: begin
                if(load_data | load_length)     next_state = IDLE; // Transition to next state
                else                            next_state = END;
            end
            LOAD_LENGTH: begin
                if(load_data)   next_state = LOAD_DATA_SHAKE; // Transition to next state
                else            next_state = LOAD_LENGTH_STANDBY;
            end
            LOAD_LENGTH_STANDBY: begin
                if(load_data)   next_state = LOAD_DATA_SHAKE; // Transition to next state
                else            next_state = LOAD_LENGTH_STANDBY;
            end
            LOAD_DATA_SHAKE: begin
                if (start)     next_state = START_SHAKE;
                else           next_state = LOAD_DATA_SHAKE;
            end
            START_SHAKE: begin
                if(end_op)      next_state = END_SHAKE; // Transition to next state
                else            next_state = START_SHAKE;
            end
            END_SHAKE: begin
                if(load_length)     next_state = IDLE_SHAKE; // Transition to next state
                else                next_state = END_SHAKE;
            end
            IDLE_SHAKE: begin
                if(start)           next_state = START_SHAKE; // Transition to next state
                else if (!reset)    next_state = RESET;
                else                next_state = IDLE_SHAKE;
            end
            
            default: begin
                next_state = RESET; // Default to initial state
            end
        endcase
    end
    
    // Output assignment
    always @(current_state) begin
        case (current_state)
            RESET: begin
                fsm_reset       = 0;
                fsm_start_reset = 1;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 1;
            end
            IDLE: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 1;
            end
            LOAD_DATA: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 1;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 1;
            end
            LOAD_DATA_SHAKE: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 1;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 1;
            end
            START: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 1;
                fsm_shake       = 0;
                fsm_reset_round = 0;
            end
            END: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 0;
            end
            LOAD_LENGTH: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 1;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 1;
            end
            LOAD_LENGTH_STANDBY: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 1;
            end
            START_SHAKE: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 1;
                fsm_shake       = 0;
                fsm_reset_round = 0;
            end
            END_SHAKE: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 1;
                fsm_reset_round = 0;
            end
            IDLE_SHAKE: begin
                fsm_reset       = 1;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 1;
                fsm_reset_round = 1;
            end
            default: begin
                fsm_reset       = 0;
                fsm_start_reset = 0;
                fsm_load_data   = 0;
                fsm_load_length = 0;
                fsm_start       = 0;
                fsm_shake       = 0;
                fsm_reset_round = 0;
            end
        endcase
    end

endmodule

module pad_module#(
    parameter LENGTH = 1600,
    parameter D_WIDTH = 64
    )(
    input                               clk,
    input                               rst,
    input                               load,
    input                               padding,
    input                               fsm_start_reset,
    input   [7:0]                       add_reset,
    input   [7:0]                       RATE,
    input   [D_WIDTH-1:0]               PAD,
    input   [7:0]                       LEN,
    input   [D_WIDTH-1:0]               data_in,
    input   [7:0]                       add,
    output  [LENGTH-1:0]                P
    );
    
    // --- P generation --- //
    reg [D_WIDTH-1:0] P_reg [0:(LENGTH/D_WIDTH)-1];
    genvar i;
    generate
        for(i = 0; i < (LENGTH/D_WIDTH); i = i + 1) begin
        assign P[((i+1)*D_WIDTH - 1):(i*D_WIDTH)] = P_reg[i];
        end
    endgenerate
    
    wire [7:0] add_len; 
    wire [7:0] add_rate;
    assign add_len = LEN / 8;
    assign add_rate = RATE / 8 - 1;
    
    always @(posedge clk) begin
        if(load) begin
            if(padding) begin
                if      (add == add_rate && add != add_len)   P_reg[add] <= (8'h80 << 56) + data_in;
                else if (add == add_rate && add == add_len)   P_reg[add] <= (8'h80 << 56) + data_in + PAD;
                else if (add != add_rate && add == add_len)   P_reg[add] <= data_in + PAD;
                else                                          P_reg[add] <= data_in;
            end
            else                                              P_reg[add] <= data_in;            
        end
        else begin
            if(fsm_start_reset)                               P_reg[add_reset] <= 0;
            else                                              P_reg[add]        <= P_reg[add];
        end         
    
    end 
endmodule

module keccak_op #(
    parameter LENGTH = 1600
    )
    (
    input                           clk,
    input                           rst,
    input                           shake,
    input   [LENGTH - 1:0]          S,
    output  [LENGTH - 1:0]          S_o,
    input                           reset_round,
    input                           ini,
    output                          fin
    );
    
    wire    [7:0]               round;
    wire    [7:0]               round_keccak;
    reg     [7:0]               round_clk;
    wire    [LENGTH - 1:0]      S_o_au;
    wire    [LENGTH - 1:0]      S_input;
    wire    [LENGTH - 1:0]      S_in;
    reg                         ope_clk;
    
    reg  [1599:0] S_REG;
    
    assign S_o      = S_REG;
    
    assign S_input  = (ope_clk | shake) ? S_o_au : (S ^ S_REG);
    assign S_in     = S_REG;
    
    assign round_keccak = (shake) ? round : round_clk; 
    
    keccak_op_au   keccak_op_au   (.S(S_in), .S_o(S_o_au),  .round(round_clk));
    
    wire    [63:0]  M_out [0:(LENGTH/64)-1];
    genvar i;
    generate            
    for (i = 0; i < (LENGTH/64); i = i + 1) begin
        assign M_out[i] = S_o[(((i+1)*64)-1):(i*64)];
    end
    endgenerate
    
    
    always @(posedge clk) begin
                    if(!rst) begin 
                        S_REG    <= 0;
                    end
                    else begin
                        if(!shake) begin 
                            if(ope | ope_clk)    S_REG <= S_input;
                            else                 S_REG <= S_REG;
                        end
                        else begin
                            if(ope_clk)         S_REG <= S_input;
                            else                S_REG <= S_REG;
                        end
                    end
                        
                    round_clk <= round;
                    ope_clk <= ope;
     end
    

    keccak_op_ctl keccak_op_ctl (.clk(clk), .rst(rst), .reset_round(reset_round), .ini(ini),  .fin(fin), .ope(ope), .round(round));
   
    
endmodule

module keccak_op_ctl(
    input               clk,
    input               rst,
    input               reset_round,
    input               ini,
    output              fin,
    output  reg         ope,
    output  reg [7:0]   round 
    );
    	  
    always @(posedge clk) begin
        if(!rst) begin
            ope     <= 0;
        end
        else begin
            if      (fin)   ope <= 0;
            else if (ini)   ope <= 1;
            else            ope <= ope;
        end
    end
   
    always @(posedge clk) begin
        if(!rst) begin
            round     <= 0;
        end
        else begin
            if      (reset_round)   round <= 0;
            else if (ope)           round <= round + 1;
            else                    round <= round;
        end			  
    end

    //assign round_shift = round >> 2;
    //assign fin = (round_shift == 8'b00010111) ? 1 : 0; //23
    assign fin = (round >= 8'b00010111) ? 1 : 0; //23
    //assign fin = 0;    
endmodule

module keccak_op_counter #(
    parameter LENGTH = 1600
    )
    (
    input                           clk,
    input                           rst,
    input                           shake,
    input   [LENGTH - 1:0]          S,
    output  [LENGTH - 1:0]          S_o,
    input                           reset_round,
    input                           ini,
    output                          fin
    );
    
    wire    [7:0]               round;
    wire    [7:0]               round_keccak;
    reg     [7:0]               round_clk;
    wire    [LENGTH - 1:0]      S_o_au;
    wire    [LENGTH - 1:0]      S_input;
    wire    [LENGTH - 1:0]      S_in;
    reg                         ope_clk;
    
    reg  [1599:0] S_REG;
    
    assign S_o      = S_REG;
    
    assign S_input  = (ope_clk | shake) ? S_o_au : (S ^ S_REG);
    assign S_in     = S_REG;
    
    assign round_keccak = (shake) ? round : round_clk; 
    
    keccak_op_au   keccak_op_au   (.S(S_in), .S_o(S_o_au),  .round(round_clk));
    
    wire    [63:0]  M_out [0:(LENGTH/64)-1];
    genvar i;
    generate            
    for (i = 0; i < (LENGTH/64); i = i + 1) begin
        assign M_out[i] = S_o[(((i+1)*64)-1):(i*64)];
    end
    endgenerate
    
    
    always @(posedge clk) begin
                    if(rst & reset_round & !shake & !ini) begin // !rst
                        S_REG    <= 0;
                    end
                    else begin
                        if(!shake) begin 
                            if(ope | ope_clk)    S_REG <= S_input;
                            else                 S_REG <= S_REG;
                        end
                        else begin
                            if(ope_clk)         S_REG <= S_input;
                            else                S_REG <= S_REG;
                        end
                    end
                        
                    round_clk <= round;
                    ope_clk <= ope;
     end
    

    keccak_op_ctl_counter keccak_op_ctl_counter (.clk(clk), .rst(rst), .reset_round(reset_round), .ini(ini),  .fin(fin), .ope(ope), .round(round));
   
endmodule

module keccak_op_ctl_counter(
    input               clk,
    input               rst,
    input               reset_round,
    input               ini,
    output  reg         fin,
    output  reg         ope,
    output  reg [7:0]   round 
    );
    
    /*
    always @(posedge clk) begin
        if(!rst) begin
            ope     <= 0;
        end
        else begin
            if      (fin)   ope <= 0;
            else if (ini)   ope <= 1;
            else            ope <= ope;
        end
    end
    */
    /*
    always @(posedge clk) begin
        if(!rst) begin
            round     <= 0;
        end
        else begin
            if      (reset_round)   round <= 0;
            else if (ope)           round <= round + 1;
            else                    round <= round;
        end
    end
    */
    always @(posedge clk) begin
        if(rst) begin
            if      (reset_round)   ope <= 0;
            else if (fin)           ope <= 0;
            else if (ini)           ope <= 1;
            else                    ope <= ope;
        end
        else ope <= 1;
    end
    
    always @(posedge clk) begin
        if(rst) begin // normal operation
            if      (reset_round)   round <= 0;
            else if (ope)           round <= round + 1;
            else                    round <= round;
        end
        else round  <= (round + 1) & 8'h0F; // countermeasure
    end
    
    always @(posedge clk) begin
        if(rst) begin // normal operation
           if(reset_round)                  fin <= 0;
           else if (round == 8'b00010110)   fin <= 1; // 22
           else                             fin <= fin;
        end
        else fin <= 0; // countermeasure
    end
    
    /*
    //assign round_shift = round >> 2;
    //assign fin = (round_shift == 8'b00010111) ? 1 : 0; //23
    assign fin = (round >= 8'b00010111) ? 1 : 0; //23
    //assign fin = 0;
    */
endmodule

module keccak_op_au(
    input   [1599:0]    S,
    output  [1599:0]    S_o,
    input   [7:0]       round
    );
    
    wire [1599:0] S_theta;
    wire [1599:0] S_rho_pi;
    wire [1599:0] S_chi;
    
    theta_op   theta   (.S(S),         .S_o(S_theta));
    rho_pi_op  rho_pi  (.S(S_theta),   .S_o(S_rho_pi));
    chi_op     chi     (.S(S_rho_pi),  .S_o(S_chi));
    iota_op    iota    (.S(S_chi),     .S_o(S_o),      .round(round));
    
endmodule

module chi_op(
    input   [1599:0] S,
    output  [1599:0] S_o
    );
    
    wire [63:0] bc      [0:4][0:4];
    wire [63:0] bc2     [0:24];
    wire [63:0] S_in    [0:24];
    wire [63:0] S_out   [0:24];
    
    genvar i;
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_in[i] = S[((i+1)*64-1):i*64];
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_o[((i+1)*64-1):i*64] = S_out[i];
    end
    endgenerate
    
    genvar j;
    generate
        for( j = 0; j < 25; j = j + 5) begin
            for (i = 0; i < 5; i = i + 1) begin
                assign bc[j/5][i] = S_in[j+i];
            end
            for (i = 0; i < 5; i = i + 1) begin
                assign bc2[j + i] = (~bc[j/5][(i + 1)%5] & bc[j/5][(i + 2) % 5]); 
                assign S_out[j + i] = S_in[j + i] ^ bc2[j + i];
            end
        end
    
    endgenerate 
    
endmodule

module iota_op(
    input   [1599:0] S,
    output  [1599:0] S_o,
    input   [7:0] round
    );
    
    localparam [(64*24)-1:0] param_keccakf_rndc = {
    64'h0000_0000_0000_0001,
    64'h0000_0000_0000_8082, 
    64'h8000_0000_0000_808a, 
    64'h8000_0000_8000_8000, 
    64'h0000_0000_0000_808b, 
    64'h0000_0000_8000_0001, 
    64'h8000_0000_8000_8081, 
    64'h8000_0000_0000_8009, 
    64'h0000_0000_0000_008a, 
    64'h0000_0000_0000_0088, 
    64'h0000_0000_8000_8009, 
    64'h0000_0000_8000_000a, 
    64'h0000_0000_8000_808b, 
    64'h8000_0000_0000_008b, 
    64'h8000_0000_0000_8089, 
    64'h8000_0000_0000_8003, 
    64'h8000_0000_0000_8002, 
    64'h8000_0000_0000_0080, 
    64'h0000_0000_0000_800a, 
    64'h8000_0000_8000_000a, 
    64'h8000_0000_8000_8081, 
    64'h8000_0000_0000_8080, 
    64'h0000_0000_8000_0001, 
    64'h8000_0000_8000_8008  
    };
    
    wire [63:0] S_in    [0:24];
    wire [63:0] S_out   [0:24];
    reg  [63:0] S_round  ;
    wire [63:0] keccakf_rndc   [0:23];
    
    assign S_out[0] = S_in[0] ^ S_round;
    
    genvar i;
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_in[i] = S[((i+1)*64-1):i*64];
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        if(i != 0) assign S_out[i] = S_in[i];
        assign S_o[((i+1)*64-1):i*64] = S_out[i];
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 24; i = i + 1) begin
        assign keccakf_rndc[i] = param_keccakf_rndc[((24-i)*64-1):(24-i-1)*64];
    end
    endgenerate
    
    always @* begin
    
    case(round)
        0: S_round = keccakf_rndc[0];
        1: S_round = keccakf_rndc[1];
        2: S_round = keccakf_rndc[2];
        3: S_round = keccakf_rndc[3];
        4: S_round = keccakf_rndc[4];
        5: S_round = keccakf_rndc[5];
        6: S_round = keccakf_rndc[6];
        7: S_round = keccakf_rndc[7];
        8: S_round = keccakf_rndc[8];
        9: S_round = keccakf_rndc[9];
        10: S_round = keccakf_rndc[10];
        11: S_round = keccakf_rndc[11];
        12: S_round = keccakf_rndc[12];
        13: S_round = keccakf_rndc[13];
        14: S_round = keccakf_rndc[14];
        15: S_round = keccakf_rndc[15];
        16: S_round = keccakf_rndc[16];
        17: S_round = keccakf_rndc[17];
        18: S_round = keccakf_rndc[18];
        19: S_round = keccakf_rndc[19];
        20: S_round = keccakf_rndc[20];
        21: S_round = keccakf_rndc[21];
        22: S_round = keccakf_rndc[22];
        23: S_round = keccakf_rndc[23];
        default: S_round = keccakf_rndc[23];
    endcase
    
    end
    
    
endmodule

module rho_pi_op(
    input   [1599:0] S,
    output  [1599:0] S_o
    );
    
    localparam [(8*24)-1:0] param_keccakf_rotc = {
    8'b0000_0001, // 1 - 0
    8'b0000_0011, // 3
    8'b0000_0110, // 6
    8'b0000_1010, // 10
    8'b0000_1111, // 15
    8'b0001_0101, // 21
    8'b0001_1100, // 28
    8'b0010_0100, // 36
    8'b0010_1101, // 45
    8'b0011_0111, // 55
    8'b0000_0010, // 2
    8'b0000_1110, // 14
    8'b0001_1011, // 27
    8'b0010_1001, // 41
    8'b0011_1000, // 56
    8'b0000_1000, // 8
    8'b0001_1001, // 25
    8'b0010_1011, // 43
    8'b0011_1110, // 62
    8'b0001_0010, // 18
    8'b0010_0111, // 39
    8'b0011_1101, // 61
    8'b0001_0100, // 20
    8'b0010_1100  // 44 - 23
    };
    
    localparam [(8*24)-1:0] param_keccakf_piln = {
    8'b0000_1010, // 10 - 0
    8'b0000_0111, // 7
    8'b0000_1011, // 11
    8'b0001_0001, // 17 
    8'b0001_0010, // 18
    8'b0000_0011, // 3
    8'b0000_0101, // 5
    8'b0001_0000, // 16
    8'b0000_1000, // 8
    8'b0001_0101, // 21
    8'b0001_1000, // 24
    8'b0000_0100, // 4
    8'b0000_1111, // 15
    8'b0001_0111, // 23
    8'b0001_0011, // 19
    8'b0000_1101, // 13
    8'b0000_1100, // 12
    8'b0000_0010, // 2
    8'b0001_0100, // 20
    8'b0000_1110, // 14
    8'b0001_0110, // 22
    8'b0000_1001, // 9
    8'b0000_0110, // 6
    8'b0000_0001  // 1 - 23
    };
    
    wire [63:0] bc      [0:23];
    wire [63:0] t       [0:23];
    wire [63:0] S_in    [0:24];
    wire [63:0] S_out   [0:24];
    
    genvar i;
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_in[i] = S[((i+1)*64-1):i*64];
    end
    endgenerate
    
    assign t[0] = S_in[1];
    assign S_out[0] = S_in[0];
    generate 
    for(i = 0; i < 24; i = i + 1) begin
            assign bc[i] = S_in[param_keccakf_piln[((24-i)*8-1):(24-i-1)*8]];
            assign S_out[param_keccakf_piln[((24-i)*8-1):(24-i-1)*8]] = SHA3_ROTL64(t[i], param_keccakf_rotc[((24-i)*8-1):(24-i-1)*8]);
            assign t[i+1] = bc[i];
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_o[((i+1)*64-1):i*64] = S_out[i];
    end
    endgenerate
    
    
    function [63:0] SHA3_ROTL64 ( input [63:0] x, input [63:0] y);
    begin
	SHA3_ROTL64 = ((x << y) | ((x) >> (64 - y)));
	end
    endfunction
    
endmodule

module theta_op(
    input   [1599:0] S,
    output  [1599:0] S_o
    );
    
    wire [63:0]     bc      [0:4];
    wire [63:0]     t       [0:4];
    wire [63:0]     sum     [0:24];
    wire [63:0]     S_in    [0:24];
    wire [63:0]     S_out   [0:24];
    
    genvar i;
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_in[i] = S[((i+1)*64-1):i*64];
    end
    endgenerate
    
    generate
    for (i = 0; i < 5; i = i + 1) begin
        assign  bc[i] =  S_in[i] ^ S_in[i + 5] ^ S_in[i + 10] ^ S_in[i + 15] ^ S_in[i + 20]; 
    end
    endgenerate
    
    genvar j;
    generate
    for (i = 0; i < 5; i = i + 1) begin
        assign  t[i] = bc[(i+4) % 5] ^ SHA3_ROTL64(bc[(i + 1) % 5], 1);  
        for(j = 0; j < 25; j = j + 5) begin 
            assign sum[j+i] = S_in[j + i] ^ t[i];
            assign S_out[j + i] = sum[j+i][63:0];
        end
    end
    endgenerate
    
    generate 
    for ( i = 0; i < 25; i = i + 1) begin
        assign S_o[((i+1)*64-1):i*64] = S_out[i];
    end
    endgenerate
    
    
    function [0:63] SHA3_ROTL64 ( input [0:63] x, input [0:63] y);
        begin
        SHA3_ROTL64 = (x << y) | ((x) >> (64 - y));
        end
    endfunction

endmodule