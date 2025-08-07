////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 25/06/2025
// Design Name: picoram.v
// Module Name: picoram
// Project Name: picoSoC SE-QUBIP Implementation
// Target Devices: ZCU104
// Tool Versions: Vivado 2024.1.2
// Description: 
//		
//    A structural, synthesizable, dual-port RAM subsystem specifically for the
//    PicoSoC. It is constructed by generating a memory-banked architecture
//    from smaller 'genram' primitives. This design explicitly decodes the
//    address to select one of many memory banks, improving scalability and
//    clarifying the hardware structure for the synthesis tools.
//		
// Additional Comment:
//
//                      Memory Layout example: for 256 kiB of size we have to split into 16x4096x4x8(9) bit RAM memories
//
//      //=====================================================RAM DISTRIBUTION=========================================================//                                                                                                                            //
//      //  0x3FFFF  ^                                                      0x3BFFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_63|    |RAM_62|    |RAM_61|    |RAM_60|                 |  |RAM_59|    |RAM_58|    |RAM_57|    |RAM_56|    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x3C000  v     |-----------|------------|-----------|           0x38000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      //  Addresses                  RAM #15[31:0]                        Addresses                   RAM #14[31:0]                   //
//      // ============================================================================================================================ //
//      //  0x37FFF  ^                                                      0x33FFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_55|    |RAM_54|    |RAM_53|    |RAM_52|                 |  |RAM_51|    |RAM_50|    |RAM_49|    |RAM_48|    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x34000  v     |-----------|------------|-----------|           0x30000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      //  Addresses                   RAM #13[31:0]                       Addresses                   RAM #12[31:0]                   //
//      // ============================================================================================================================ //
//      //  0x2FFFF  ^                                                      0x2BFFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_47|    |RAM_46|    |RAM_45|    |RAM_44|                 |  |RAM_43|    |RAM_42|    |RAM_41|    |RAM_40|    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x2C000  v     |-----------|------------|-----------|           0x28000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      //   Addresses                  RAM #11[31:0]                       Addresses                   RAM #10[31:0]                   //
//      // ============================================================================================================================ //
//      //  0x27FFF  ^                                                      0x23FFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_39|    |RAM_38|    |RAM_37|    |RAM_36|                 |  |RAM_35|    |RAM_34|    |RAM_33|    |RAM_32|    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x24000  v     |-----------|------------|-----------|           0x20000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      // Addresses                     RAM #9[31:0]                       Addresses                    RAM #8[31:0]                   //
//      // ============================================================================================================================ //
//      //  0x1FFFF  ^                                                      0x1BFFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_31|    |RAM_30|    |RAM_29|    |RAM_28|                 |  |RAM_27|    |RAM_26|    |RAM_25|    |RAM_24|    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x1C000  v     |-----------|------------|-----------|           0x18000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      //  Addresses                    RAM #7[31:0]                       Addresses                    RAM #6[31:0]                   //
//      // ============================================================================================================================ //
//      //  0x17FFF  ^                                                      0x13FFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_23|    |RAM_22|    |RAM_21|    |RAM_20|                 |  |RAM_19|    |RAM_18|    |RAM_17|    |RAM_16|    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x14000  v     |-----------|------------|-----------|           0x10000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      //  Addresses                    RAM #5[31:0]                       Addresses                    RAM #4[31:0]                   //
//      // ============================================================================================================================ //
//      //  0x0FFFF  ^                                                      0x0BFFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_15|    |RAM_14|    |RAM_13|    |RAM_12|                 |  |RAM_11|    |RAM_10|    |RAM_9 |    |RAM_8 |    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x0C000  v     |-----------|------------|-----------|           0x08000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      //  Addresses                    RAM #3[31:0]                       Addresses                    RAM #2[31:0]                   //
//      // ============================================================================================================================ //
//      //  0x07FFF  ^                                                      0x03FFF  ^                                                  //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //           |  |RAM_7 |    |RAM_6 |    |RAM_5 |    |RAM_4 |                 |  |RAM_3 |    |RAM_2 |    |RAM_1 |    |RAM_0 |    //  
//      //           |  ========    ========    ========    ========                 |  ========    ========    ========    ========    //  
//      //  0x04000  v     |-----------|------------|-----------|           0x00000  v     |-----------|------------|-----------|       //  
//      //                                    |                                                               |                         //  
//      // Addresses                     RAM #1[31:0]                       Addresses                    RAM #0[31:0]                   //                                                                                                                              //
//      //==============================================================================================================================//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module picoram #(
                parameter  integer WORDS        = 65536,                            //-- Total Capacity in WORDS (WORD = 32 bits)
                localparam integer BYTES        = WORDS * 4,                        //-- Total Capacity in BYTES
                localparam integer AW           = $clog2(WORDS),                    //-- Total Address Width
                localparam integer DW           = 32,                               //-- Total Data Width
                localparam integer BRAM_BYTES   = 4096,                             //-- Bytes per BLOCK RAM 
                localparam integer AW_BRAM      = $clog2(BRAM_BYTES),               //-- Address Width of each BLOCK RAM (RAM_j) and each BRAM Bank
                localparam integer DW_BRAM      = 8,                                //-- Data Width of each BLOCK RAM (RAM_j)       
                localparam integer RAM_SLICES   = DW / DW_BRAM,                     //-- Number of 8-bit RAMs in parallel to form a 32-bit WORD (RAM_j)
                localparam integer NUM_BANKS    = BYTES / (BRAM_BYTES*RAM_SLICES)   //-- Number of BRAM banks (RAM #i)
                )
                (                                
                input  wire clk,                        //-- Clock Signal
                input  wire [RAM_SLICES-1:0] wr_en_A,   //-- Enable Byte Write PORT A
                input  wire [RAM_SLICES-1:0] wr_en_B,   //-- Enable Byte Write PORT B
                input  wire [AW-1:0] addr_A,            //-- Address PORT A
                input  wire [AW-1:0] addr_B,            //-- Address PORT B
                input  wire [DW-1:0] data_in_A,         //-- Write Data PORT A
                input  wire [DW-1:0] data_in_B,         //-- Write Data PORT B
                output reg  [DW-1:0] data_out_A,        //-- Read  Data PORT A
                output reg  [DW-1:0] data_out_B         //-- Read  Data PORT B
                );  

    //-- Structural RAM Generation 
    genvar i;   // Bank iterator (RAM #i)
    genvar j;   // Slice iterator (RAM_j)

    //-- RAM Generation Loop
    wire [NUM_BANKS-1:0] bank_select_A;
    wire [NUM_BANKS-1:0] bank_select_B;

    wire [DW-1:0] bank_data_out_A [NUM_BANKS-1:0];
    wire [DW-1:0] bank_data_out_B [NUM_BANKS-1:0];

    generate for(i = 0; i < NUM_BANKS; i = i + 1) begin: BANK_GEN
        assign bank_select_A[i] = (addr_A[AW-1:AW_BRAM] == i);
        assign bank_select_B[i] = (addr_B[AW-1:AW_BRAM] == i);

        for(j = 0; j < RAM_SLICES; j = j + 1) begin: SLICE_GEN 
            genram #(
	                .AW(AW_BRAM), 
	                .DW(DW_BRAM),
	                .INIT(0)
	                )
	                RAM_SLICE
	                (
		    	     .clk_A(clk),
		    	     .clk_B(clk),
		    	     .wr_A(bank_select_A[i] & wr_en_A[j]),
		    	     .wr_B(bank_select_B[i] & wr_en_B[j]),
		    	     .addr_A(addr_A[AW_BRAM-1:0]),
		    	     .addr_B(addr_B[AW_BRAM-1:0]),      
		    	     .data_in_A(data_in_A[DW_BRAM*j+:DW_BRAM]),
		    	     .data_in_B(data_in_B[DW_BRAM*j+:DW_BRAM]),
		    	     .data_out_A(bank_data_out_A[i][DW_BRAM*j+:DW_BRAM]),
		    	     .data_out_B(bank_data_out_B[i][DW_BRAM*j+:DW_BRAM])
		    	     );
        end
    end
    endgenerate

    //-- Register and Multiplex the RAM output
    reg [$clog2(NUM_BANKS):0] k;

    always @(*) begin
        data_out_A = 0;
        data_out_B = 0;
        for (k = 0; k < NUM_BANKS; k = k + 1) begin
            if (bank_select_A[k]) data_out_A = bank_data_out_A[k];
            if (bank_select_B[k]) data_out_B = bank_data_out_B[k];
        end
    end 
        
endmodule
