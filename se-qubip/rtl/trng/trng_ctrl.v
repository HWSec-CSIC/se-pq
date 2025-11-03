`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 14/07/2025
// Design Name: trng_ctrl.v
// Module Name: trng_ctrl
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_3.0 Controller
//
// Additional Comment:
//
//      Original VHDL by santiago@imse-cnm.csic.es. trng_ldr removed, the count
//      is now managed by trng_shift.v
//
////////////////////////////////////////////////////////////////////////////////////

module trng_ctrl (
                  input  wire clock,                  //-- System Clock
                  input  wire reset,                  //-- System Reset
                  input  wire cmp_end,                //-- Comparison End
                  output reg  cmp_inc,                //-- Comparison Increment
                  output reg  cmp_rst,                //-- Comparison Reset
                  output reg  cmp_str,                //-- Comparison Start
                  output reg  cmp_cap                 //-- Comparison Capture
                  );

    //------------------------------------------------------------------
    // Local Parameters and Wires/Regs
    //------------------------------------------------------------------
    // FSM state encoding
    localparam [2:0] IDLE        = 3'b000;
    localparam [2:0] CMP_INCR    = 3'b001;
    localparam [2:0] CMP_RESET   = 3'b010;
    localparam [2:0] CMP_DLY     = 3'b011;
    localparam [2:0] CMP_START   = 3'b100;
    localparam [2:0] CMP_CYCLE   = 3'b101;
    localparam [2:0] CMP_CAPTURE = 3'b110;

    // FSM state registers
    reg [2:0] state, next_state;

    // Internal signals
    reg  s_cmp_end;
    
    //------------------------------------------------------------------
    // Input Synchronizer
    //------------------------------------------------------------------
    // Synchronize the cmp_end signal to the local clock domain
    always @(posedge clock) begin
        s_cmp_end <= cmp_end;
    end

    //------------------------------------------------------------------
    // FSM Logic
    //------------------------------------------------------------------
    // FSM state register
    always @(posedge clock) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM next state and output logic (combinatorial)
    always @(*) begin
        // Default assignments to prevent latches
        next_state  = IDLE;
        cmp_inc     = 1'b0;
        cmp_rst     = 1'b0;
        cmp_str     = 1'b0;
        cmp_cap     = 1'b0;

        case (state)
            IDLE: begin
                if (~reset)
                    next_state = CMP_INCR;
                else
                    next_state = IDLE;
            end
            CMP_INCR: begin
                cmp_inc     = 1'b1;
                next_state  = CMP_RESET;
            end
            CMP_RESET: begin
                cmp_rst     = 1'b1;
                next_state = CMP_DLY;
            end
            CMP_DLY: begin
                next_state = CMP_START;
            end
            CMP_START: begin
                cmp_str     = 1'b1;
                next_state  = CMP_CYCLE;
            end
            CMP_CYCLE: begin
                if (s_cmp_end)
                    next_state = CMP_CAPTURE;
                else
                    next_state = CMP_CYCLE;
            end
            CMP_CAPTURE: begin
                cmp_cap     = 1'b1;
                next_state  = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule
