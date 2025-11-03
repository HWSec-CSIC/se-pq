`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 14/07/2025
// Design Name: trng_unit.v
// Module Name: trng_unit
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions:
// Description: 
//		
//		Verilog code for TRNGR5_4.0 TRNG Unit
//
// Additional Comment:
//
//      Each bank_unit is comprised by 4 ROs, 2 challenges comparison. The outputs
//      of the bank units fill a 32/64-bits shift register. 
//
////////////////////////////////////////////////////////////////////////////////////

module trng_unit #(
                    parameter TRNG_SIM      = 0,                //-- Simulation?
                    parameter BANK_UNITS    = 1,                //-- Number of RO Banks per TRNG Unit
                    parameter CG_TYPE       = 1,                //-- Challenge Generator Type: Counter(1), LFSR(2)
                    parameter Dbw           = 32,               //-- AXI4-Lite Data Bus Width (32/64)
                    parameter Bpc           = 4,                //-- Operation(4)/Characterization(32)
                    parameter Nbc           = 14                //-- Maximum Number of bits of Counters
                    ) 
                    (
                    input  wire             clock,              //-- AXI Clock
                    input  wire             reset,              //-- TRNG Reset
                    // input  wire [Nbc-1:0]   sel_nbc,            //-- Select Bits of the Counter
                    input  wire             SD,                 //-- Same/Different location LUTs (1 for Same, 0 for Different)
                    input  wire             data_ready,         //-- Ready Signal 
                    output wire [Dbw-1:0]   data_out,           //-- Output Data
                    output wire             data_valid          //-- Valid signal
                    );

    genvar i;

    //------------------------------------------------------------------
    // Local Parameters and Wires/Regs
    //------------------------------------------------------------------
    // Wires connecting the main controller
    wire cmp_inc  [0:BANK_UNITS-1];
    wire cmp_rst  [0:BANK_UNITS-1];
    wire cmp_str  [0:BANK_UNITS-1];
    wire cmp_cap  [0:BANK_UNITS-1];

    // Wires for challenge generation
    wire [7:0] cnf1 [0:BANK_UNITS-1];
    wire [7:0] cnf2 [0:BANK_UNITS-1];

    // Wires for the Ring Oscillator bank and bit extractors
    wire [3:0]      ro_b        [0:BANK_UNITS-1];
    wire            ro_0        [0:BANK_UNITS-1]; 
    wire            ro_1        [0:BANK_UNITS-1];
    wire            ro_2        [0:BANK_UNITS-1];
    wire            ro_3        [0:BANK_UNITS-1];
    wire            en_ro       [0:BANK_UNITS-1];
    wire [Nbc-1:0]  rdata1      [0:BANK_UNITS-1];
    wire [Nbc-1:0]  rdata2      [0:BANK_UNITS-1];
    wire            busy_1      [0:BANK_UNITS-1];
    wire            busy_2      [0:BANK_UNITS-1];
    wire            busy        [0:BANK_UNITS-1];
    wire            cmp_end     [0:BANK_UNITS-1];

    // Wire for the final comparison output to memory
    reg  [Bpc-1:0] cmp_out [0:BANK_UNITS-1];
    
    // ** BUG NOTE **
    // The original VHDL declares signals 'full1' and 'full3' but never drives them.
    // This translation replicates that behavior. In synthesis, these will be tied to '0'.
    wire full1 [0:BANK_UNITS-1];
    wire full3 [0:BANK_UNITS-1];
    
    // Shifter Input and write signal
    wire [Bpc-1:0]  shift_in;
    wire            en_sr;

    generate for (i = 0; i < BANK_UNITS; i = i + 1) begin : BANK_UNIT

        //------------------------------------------------------------------
        // Module Instantiations
        //------------------------------------------------------------------

        // 1. Main Controller
        trng_ctrl TRNG_CONTROL (
                                .clock(clock), 
                                .reset(reset), 
                                .cmp_end(cmp_end[i]), 
                                .cmp_inc(cmp_inc[i]), 
                                .cmp_rst(cmp_rst[i]), 
                                .cmp_str(cmp_str[i]), 
                                .cmp_cap(cmp_cap[i])
                                );

        // 2. Challenge Generator (Counter or LFSR)
        roc_chl #(
                  .CG_TYPE(CG_TYPE)
                  ) 
                  CHALLENGE_GEN 
                  (
                   .clk(cmp_inc[i]), 
                   .reset(reset), 
                   .cnf1(cnf1[i]), 
                   .cnf2(cnf2[i])
                   );

        // 3. Ring Oscillator Bank
        if (!TRNG_SIM) begin
            (* KEEP_HIERARCHY = "TRUE" *)
            roc_bnk RO_BANK (
                             .enx(en_ro[i]), 
                             .eny(en_ro[i]), 
                             .cnf1(cnf1[i]), 
                             .cnf2(cnf2[i]), 
                             .ro(ro_b[i])
                             );
        end
        else begin
            roc_sim RO_BANK_SIM (
                                 .clk(clock),
                                 .ro(ro_b[i])
                                 );
        end

        // 4. Bit Extractor Race Circuits (two instances)
        roc_bxt #(
                  .Nbc(Nbc)
                  )
                  RO_BXT_1 
                  (
                   .rst(cmp_rst[i]), 
                   .str(cmp_str[i]),
                   // .sel_nbc(sel_nbc), 
                   .ro1(ro_0[i]), 
                   .ro2(ro_1[i]),
                   .busy(busy_1[i]), 
                   .rdata(rdata1[i])
                   );

        roc_bxt #(
                  .Nbc(Nbc)
                  ) 
                  RO_BXT_2
                  (
                   .rst(cmp_rst[i]), 
                   .str(cmp_str[i]),
                   // .sel_nbc(sel_nbc), 
                   .ro1(ro_2[i]), 
                   .ro2(ro_3[i]),
                   .busy(busy_2[i]), 
                   .rdata(rdata2[i])
                   );

        //------------------------------------------------------------------
        // Interconnect Logic
        //------------------------------------------------------------------
        // Multiplexers to select RO outputs based on SD (Same/Different) input
        // ro_b wiring: (y=1): ro_b[3], ro_b[2]; (y=0): ro_b[1], ro_b[0]
        assign ro_0[i] = ro_b[i][0];
        assign ro_1[i] = SD ? ro_b[i][2] : ro_b[i][3];
        assign ro_2[i] = SD ? ro_b[i][1] : ro_b[i][2];
        assign ro_3[i] = SD ? ro_b[i][3] : ro_b[i][1];

        // Busy logic for enabling ROs and signaling end of comparison
        assign busy[i]    = busy_1[i] | busy_2[i];
        assign en_ro[i]   = busy[i];
        assign cmp_end[i] = ~busy[i];

        //------------------------------------------------------------------
        // Capture comparison output logic (driven by cmp_cap pulse)
        //------------------------------------------------------------------
        // Operation mode: capture 2 LSBs from each bit extractor
        if (Bpc == 4) begin : OP_4
            always @(posedge cmp_cap[i]) begin
                cmp_out[i][3]   <= rdata2[i][1]; // bit 1(2)
                cmp_out[i][2]   <= rdata2[i][0]; // bit 0(2)
                cmp_out[i][1]   <= rdata1[i][1]; // bit 1(1)
                cmp_out[i][0]   <= rdata1[i][0]; // bit 0(1)
            end
        end
        else if (Bpc == 2) begin : OP_2
            always @(posedge cmp_cap[i]) begin
                cmp_out[i][1]   <= rdata2[i][0]; // bit 0(2)
                cmp_out[i][0]   <= rdata1[i][0]; // bit 0(1)
            end
        end
        // Characterization mode: capture full counter values
        else if (Bpc == 32) begin : CH
            always @(posedge cmp_cap[i]) begin
                cmp_out[i][31:Nbc+17]       <= 0;
                cmp_out[i][Nbc+16]          <= full1[i];    // Note: 'full1' is undriven
                cmp_out[i][Nbc+15:16]       <= rdata1[i];
                cmp_out[i][15:Nbc+1]        <= 0;
                cmp_out[i][Nbc]             <= full3[i];    // Note: 'full3' is undriven
                cmp_out[i][Nbc-1:0]         <= rdata2[i];
            end
        end
    end
    endgenerate


    //------------------------------------------------------------------
    // TRNG SHIFT REGISTER
    //------------------------------------------------------------------

    generate 
        if (BANK_UNITS > 1) begin : MULTIPLE_BANK   // Round Robin Arbiter Based
            
            reg [BANK_UNITS-1:0] cmp_valid;
            reg [BANK_UNITS-1:0] bank_counter;
            reg [$clog2(BANK_UNITS)-1:0] shift_counter;

            always @(posedge clock) begin
                if (reset) begin
                    bank_counter    <= 1;
                    shift_counter   <= 0;
                end
                else begin  
                    // Shift Register Counter
                    if (bank_counter[BANK_UNITS-1]) bank_counter <= 1;
                    else                            bank_counter <= {bank_counter[BANK_UNITS-2:0], 1'b0};

                    shift_counter <= shift_counter + 1;
                end
            end

            for (i = 0; i < BANK_UNITS; i = i + 1) begin
                always @(posedge clock) begin
                    if (reset)
                        cmp_valid[i] <= 0;
                    else if (cmp_cap[i])
                        cmp_valid[i] <= 1;
                    else if (bank_counter[i])
                        cmp_valid[i] <= 0;
                end
            end

            assign shift_in = cmp_out[shift_counter];
            assign en_sr    = |(bank_counter & cmp_valid);
        end
        else begin : ONE_BANK
            assign shift_in = cmp_out[0];
            assign en_sr    = cmp_cap[0];
        end
    endgenerate 

    trng_shift #(
                .Dbw(Dbw), 
                .Bpc(Bpc)
                ) 
                TRNG_SHIFT
                (
                 .clock(clock),
                 .reset(reset), 
                 .en_sr(en_sr), 
                 .shift_ready(data_ready),
                 .shift_in(shift_in), 
                 .shift_out(data_out),
                 .shift_valid(data_valid)
                 );


endmodule
