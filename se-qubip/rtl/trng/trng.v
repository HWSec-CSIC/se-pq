`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 14/07/2025
// Design Name: trng.v
// Module Name: trng
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_3.0 Top File
//
// Additional Comment:
//
//      Original VHDL by santiago@imse-cnm.csic.es. Modified to include
//      multiple TRNG Units with multiple RO banks.
//
////////////////////////////////////////////////////////////////////////////////////

module trng #(
              parameter TRNG_SIM    = 0,                    //-- Simulation?
              parameter TRNG_UNITS  = 4,                    //-- Number of TRNG Units
              parameter BANK_UNITS  = 8,                    //-- Number of RO Banks per TRNG Unit
              parameter TRNG_SIZE   = 262144,               //-- TRNG memory size (bits)
              parameter BLOCK_SIZE  = 32,                   //-- TRNG output size (bits)
              parameter CG_TYPE     = 1,                    //-- Challenge Generator Type: Counter(1), LFSR(2)
              parameter Dbw         = 32,                   //-- AXI4-Lite Data Bus Width
              parameter Bpc         = 4,                    //-- Operation(2/4)/Characterization(32)
              parameter Nbc         = 5                     //-- Number of bits of counters
              ) 
              (
               input  wire                  clock,          //-- AXI Clock
               input  wire                  reset,          //-- TRNG Reset
               input  wire                  SD,             //-- Same/Different location LUTs (1 for Same, 0 for Different)
               input  wire                  trng_ren,       //-- TRNG Read Enable
               input  wire                  trng_read,      //-- TRNG Read
               output wire                  trng_valid,     //-- TRNG Valid signal
               output wire                  trng_full,      //-- TRNG Full signal
               output wire [ADDR_WIDTH-1:0] trng_occp,      //-- TRNG Occupation (registers)
               output wire [ADDR_WIDTH-1:0] trng_wadd,      //-- TRNG Write Address
               output wire [ADDR_WIDTH-1:0] trng_radd,      //-- TRNG Read Address
               output wire [Dbw-1:0]        trng_out        //-- TRNG Output data
               );

    //------------------------------------------------------------------
    // Local Parameters and Wires/Regs
    //------------------------------------------------------------------
    localparam MEM_DEPTH  = TRNG_SIZE / Dbw;
    localparam ADDR_WIDTH = $clog2(MEM_DEPTH);
    
    //------------------------------------------------------------------
    // Module Instantiations
    //------------------------------------------------------------------

    //-- 1. TRNG Units
    genvar i;

    wire [TRNG_UNITS-1:0]   data_valid;
    wire [Dbw-1:0]          data_out    [0:TRNG_UNITS-1];
    wire [TRNG_UNITS-1:0]   data_ready;
    
    wire [Dbw-1:0]          trng_in;
    wire                    trng_write;

    generate for (i = 0; i < TRNG_UNITS; i = i + 1) begin : TRNG_UNIT
        trng_unit #(
                    .TRNG_SIM(TRNG_SIM),
                    .BANK_UNITS(BANK_UNITS),
                    .CG_TYPE(CG_TYPE),
                    .Dbw(Dbw), 
                    .Bpc(Bpc),
                    .Nbc(Nbc)
                    ) 
                    TRNG_UNIT
                    (
                     .clock(clock),
                     .reset(reset), 
                     // .sel_nbc(sel_nbc),
                     .SD(SD),
                     .data_ready(data_valid[i]),
                     .data_out(data_out[i]),
                     .data_valid(data_ready[i]) 
                     );
    end

    if (TRNG_UNITS > 1) begin : MULTIPLE_TRNG   // Round Robin Arbiter Based

        reg  [TRNG_UNITS-1:0]           trng_counter;
        reg  [$clog2(TRNG_UNITS)-1:0]   shift_counter;
        
        always @(posedge clock) begin
            if (reset) begin
                trng_counter    <= 1;
                shift_counter   <= 0;
            end
            else begin  
                // Shift Register Counter
                if (trng_counter[TRNG_UNITS-1]) trng_counter <= 1;
                else                            trng_counter <= {trng_counter[TRNG_UNITS-2:0], 1'b0};

                shift_counter <= shift_counter + 1;
            end
        end

        assign trng_in      = data_out[shift_counter];
        assign data_valid   = data_ready & trng_counter;
        assign trng_write   = |data_valid;
    end

    else begin : ONE_TRNG
        assign trng_in      = data_out[0];
        assign data_valid   = data_ready;
        assign trng_write   = data_valid;
    end
    endgenerate
    

    //-- 2. TRNG Memory
    trng_mem #(
               .TRNG_SIZE(TRNG_SIZE),
               .BLOCK_SIZE(BLOCK_SIZE),
               .Dbw(Dbw)
               ) 
               TRNG_MEM
               (
                .clk(clock),
                .reset(reset), 
                .write(trng_write),
                .read(trng_read),
                .ren(trng_ren),
                .trng_in(trng_in),
                .trng_wadd(trng_wadd),
                .trng_radd(trng_radd),
                .trng_out(trng_out),
                .trng_occp(trng_occp),
                .trng_valid(trng_valid)
                );

    //-- This Circular FIFO never fulls it overwrites previous values
    assign trng_full = 0;

endmodule
