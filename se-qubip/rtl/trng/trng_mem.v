`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 11/07/2025
// Design Name: trng_mem.v
// Module Name: trng_mem
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_2.0 RAM Memory
//
// Additional Comment:
//
//      Original VHDL by santiago@imse-cnm.csic.es. Modified circular FIFO never
//      fulls to keep the ROs working, overwriting previous values, wr addr is
//      no required, it is automatically updated.
//
////////////////////////////////////////////////////////////////////////////////////

module trng_mem #(
                  parameter TRNG_SIZE  = 512,                   //-- TRNG memory size (bits)
                  parameter BLOCK_SIZE = 128,                   //-- TRNG output size (bits)
                  parameter Dbw        = 32                     //-- AXI4-Lite Data Bus Width (32/64 bits)
                  ) 
                  (
                  input  wire                   clk,            //-- AXI Clock
                  input  wire                   reset,          //-- Global Reset
                  input  wire                   write,          //-- Write operation
                  input  wire                   read,           //-- Read operation
                  input  wire                   ren,            //-- Read Enable
                  input  wire [Dbw-1:0]         trng_in,        //-- TRNG Unit Output
                  output wire [ADDR_WIDTH-1:0]  trng_wadd,      //-- TRNG Write Address
                  output wire [ADDR_WIDTH-1:0]  trng_radd,      //-- TRNG Read Address
                  output reg  [Dbw-1:0]         trng_out,       //-- TRNG Output
                  output wire [ADDR_WIDTH-1:0]  trng_occp,      //-- TRNG Occupation
                  output reg                    trng_valid      //-- TRNG Valid
                  );

    //-- Calculate memory depth and address width
    localparam MEM_DEPTH = TRNG_SIZE / Dbw;
    localparam ADDR_WIDTH = $clog2(MEM_DEPTH);

    //-- Memory array declaration with attribute to infer Block RAM
    (* ram_style = "block" *)
    reg [Dbw-1:0] trng_memory [MEM_DEPTH-1:0];

    //======================================================================
    // WRITE/READ LOGIC
    //======================================================================

    //-- Pointers and occupancy counter
    reg [ADDR_WIDTH-1:0] w_ptr, r_ptr;
    reg [ADDR_WIDTH:0]   count_reg; // Counter needs one more bit than address

    //-- Internal signals for control
    wire do_write;
    wire do_read;
    wire is_full;
    wire is_empty;

    // --- Control Logic ---
    assign is_full  = (count_reg == MEM_DEPTH - 1);
    assign is_empty = (count_reg == 0);

    // A write happens if 'write' is asserted. We don't stop for 'full' because we overwrite.
    assign do_write = write;
    // A read happens if 'read' and 'ren' are asserted AND the FIFO is not empty.
    assign do_read  = read && ren && !is_empty;

    // --- Memory Write Logic ---
    always @(posedge clk) begin
        if (do_write) begin
            trng_memory[w_ptr] <= trng_in;
        end
        if (do_read) begin
            trng_out <= trng_memory[r_ptr];
        end
    end
    
    // --- Pointer and Counter Update Logic ---
    always @(posedge clk) begin
        if (reset) begin
            w_ptr     <= 0;
            r_ptr     <= 0;
            count_reg <= 0;
        end else begin
            case ({do_write, do_read})
                2'b00:; // No change
                2'b01: begin // Read only
                    r_ptr     <= r_ptr + 1;
                    count_reg <= count_reg - 1;
                end
                2'b10: begin // Write only
                    w_ptr     <= w_ptr + 1;
                    // If full, a write is an overwrite, so count doesn't increase.
                    // Otherwise, it increases.
                    if (!is_full) begin
                        count_reg <= count_reg + 1;
                    end else begin
                        // This is the overwrite case: w_ptr moves and r_ptr must also move.
                        r_ptr <= r_ptr + 1;
                    end
                end
                2'b11: begin // Simultaneous read and write (no net change in count)
                    w_ptr <= w_ptr + 1;
                    r_ptr <= r_ptr + 1;
                end
            endcase
        end
    end

    // --- Status and Output Assignments ---
    assign trng_wadd = w_ptr;
    assign trng_radd = r_ptr;
    assign trng_occp = count_reg; // Direct from register, no complex calculation

    // The valid signal should be registered for stable output
    always @(posedge clk) begin
        if (reset) begin
            trng_valid <= 1'b0;
        end else begin
            // Update valid based on the count at the beginning of the cycle
            trng_valid <= (count_reg > (BLOCK_SIZE / Dbw));
        end
    end

endmodule
