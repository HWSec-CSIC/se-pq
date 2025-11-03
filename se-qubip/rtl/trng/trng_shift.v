`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 14/07/2025
// Design Name: trng_shift.v
// Module Name: trng_shift
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_4.0 Shift Register
//
// Additional Comment:
//
////////////////////////////////////////////////////////////////////////////////////

module trng_shift #(
                    parameter Dbw = 32,                     //-- AXI4-Lite Data Bus Width (32/64 bits)
                    parameter Bpc = 4                       //-- Bits per comparison: Operation(4)
                    ) 
                    (
                    input  wire             clock,            //-- Global Clock  
                    input  wire             reset,          //-- Global Reset+
                    input  wire             en_sr,          //-- Enable Shift Register
                    input  wire             shift_ready,    //-- Shift Ready
                    input  wire [Bpc-1:0]   shift_in,       //-- Shift Register Input
                    output reg  [Dbw-1:0]   shift_out,      //-- Shift Register Output
                    output reg              shift_valid     //-- Shift Valid
                    );

    //======================================================================
    // WRITE LOGIC - Conditioned by Bpc and Dbw
    //======================================================================
    generate
        // --- OPERATION MODE (Bpc = 4) ---
        reg [$clog2(Dbw/Bpc)-1:0] shift_counter;
        if (Bpc == 4 || Bpc == 2) begin : OP_MODE
            // Shift register to assemble a full word from Bpc-bit chunks
            always @(posedge clock) begin
                if (reset) begin
                    shift_counter   <= 0;
                    shift_out       <= 0;
                    shift_valid     <= 0;
                end
                else if (en_sr) begin
                    shift_counter   <= shift_counter + 1;
                    shift_out       <= {shift_out[Dbw-Bpc-1:0], shift_in};    // Shift left by Bpc and add new bits
                    if (&shift_counter) begin
                        shift_valid <= 1;
                    end
                    else if (shift_ready) begin
                        shift_valid <= 0;
                    end
                end
                else if (shift_ready) begin
                    shift_valid <= 0;
                end
            end
        end

        // --- CHARACTERIZATION MODE (Bpc = 32) ---
        else if (Bpc == 32) begin : CH_MODE
           
            // Case: 64-bit Data Width
            if (Dbw == 64) begin : CH164

                // Shift register to assemble 64-bit word from two 32-bit chunks
                always @(posedge clock) begin
                    if (reset) begin
                        shift_out <= 0;
                    end
                    else if (en_sr) begin
                        shift_out <= {shift_out[31:0], shift_in};
                        if (shift_ready)
                            shift_valid <= 0;
                        else 
                            shift_valid <= 1;
                    end
                    else if (shift_ready) begin
                         shift_valid <= 0;
                    end
                end
            end
            // Case: 32-bit Data Width
            else if (Dbw == 32) begin : CH132
                // In this mode, the input word directly matches the memory width.
                // No intermediate register is needed.
                always @(posedge clock) begin
                    if (reset) begin
                        shift_out <= 0;
                    end
                    else if (en_sr) begin
                        shift_out    <= shift_in;
                        if (shift_ready)
                            shift_valid <= 0;
                        else 
                            shift_valid <= 1;
                    end
                    else if (shift_ready) begin
                         shift_valid <= 0;
                    end
               end
           end
        end
    endgenerate

endmodule
