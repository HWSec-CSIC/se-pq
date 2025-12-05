////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 24/11/2025
// Design Name: scp03_aes.v
// Module Name: scp03_aes
// Project Name: SCP-03 for SE-QUBIP
// Target Devices: ZCU104
// Tool Versions: HWSEC-OSS Framework
// Description: 
//		
//      AES Wrapper with Multi-Context Subkey Caching for SCP-03.
//      Supports 4 Contexts:
//        0: Static ENC (for KDF)
//        1: Static MAC (for KDF)
//        2: Session S-MAC (for C-MAC/Cryptograms)
//        3: Session S-RMAC (for R-MAC)
//
// Additional Comment:
//
////////////////////////////////////////////////////////////////////////////////////


module scp03_aes(
                 input wire clk,
                 input wire rst,

                 // Control Interface
                 input wire start,                  //-- Pulse to start a new encryption/MAC session (resets IV/Chain)
                 input wire key_update,             //-- Pulse to invalidate subkeys for current 'subkey_sel'
                 input wire [1:0] subkey_sel,       //-- Select Key Context (00: KEY-ENC, 01: KEY-MAC, 10: S-MAC, 11: S-RMAC) 
                 input wire mode,                   //-- 0: CBC, 1: CMAC
                 input wire sel_op,                 //-- CBC: 0=Encrypt, 1=Decrypt | CMAC: 0=Generate
                 input wire last_block_partial,     //-- CMAC: 0 = Full block (XOR K1), 1 = Padded block (XOR K2)
                 input wire [31:0] data_len,        //-- Number of 128-bit blocks to process in this session
                 input wire [1:0] aes_len,          //-- 128/192/256
                 input wire [255:0] key,            //-- Session Key
                 input wire [127:0] iv,             //-- Initialization Vector (for CBC) or Starting Chain (for CMAC)

                 // Data Interface
                 input wire [127:0] data_in,        //-- Input Data
                 input wire data_in_valid,          //-- Handshake: Data is valid on line
                 output reg data_in_ready,          //-- Handshake: Ready to accept new data

                 output reg [127:0] data_out,       //-- Output Data / MAC
                 output reg data_out_valid          //-- Result valid pulse
                 );

    //----------------------------------------------------------------
    // Parameters & Constants
    //----------------------------------------------------------------
    localparam OP_CBC  = 1'b0;
    localparam OP_CMAC = 1'b1;
    // R_b constant for 128-bit block size (RFC 4493)
    localparam RB_CONST = 128'h00000000000000000000000000000087; 

    // FSM States
    localparam S_IDLE          = 4'd0;
    localparam S_GEN_L         = 4'd1; // Subkey Gen: AES(0)
    localparam S_CALC_SUBK     = 4'd2; // Subkey Gen: Shift/XOR
    localparam S_WAIT_DATA     = 4'd3; // Waiting for data_in_valid
    localparam S_PREPARE_BLOCK = 4'd4; // XORing inputs (IV, K1/K2)
    localparam S_PROCESS_AES   = 4'd5; // Running AES Core
    localparam S_OUTPUT        = 4'd6; // Output result

    reg [3:0] state;

    //----------------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------------
    // Persistent Subkey Storage (4 Contexts)
    reg [127:0] K1 [3:0];
    reg [127:0] K2 [3:0];
    reg [3:0]   key_derived;    // Bitmask: 1 = Valid, 0 = Invalid

    // Operation State
    reg [31:0]  blocks_remaining;       // Counter for data_len
    reg [127:0] chain_reg;              // Holds IV or running CBC/MAC chain
    reg [127:0] current_input;          // Latch data_in
    wire [127:0] mix_input;             // Base Logic: Plaintext XOR Chain(IV)

    assign mix_input = current_input ^ chain_reg;

    // AES Core Interconnects
    reg core_rst;
    reg core_enc;
    reg [255:0] core_key;
    reg [127:0] core_pt;
    wire [127:0] core_ct;
    wire core_valid;

    //----------------------------------------------------------------
    // AES Core Instantiation
    //----------------------------------------------------------------
    aes_core aes_core (
                       .clk        (clk),
                       .rst        (core_rst),
                       .enc        (core_enc),
                       .aes_len    (aes_len),
                       .key        (core_key),
                       .plaintext  (core_pt),
                       .ciphertext (core_ct),
                       .valid      (core_valid)
                       );

    //----------------------------------------------------------------
    // Main State Machine
    //----------------------------------------------------------------
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            state               <= S_IDLE;
            data_out            <= 0;
            data_out_valid      <= 0;
            data_in_ready       <= 0;
            
            for(i=0; i<4; i=i+1) begin
                K1[i]           <= 0;
                K2[i]           <= 0;
            end
            key_derived         <= 0;
            
            chain_reg           <= 0;
            blocks_remaining    <= 0;
            current_input       <= 0;
            
            core_rst            <= 1;
            core_enc            <= 0;
            core_key            <= 0;
            core_pt             <= 0;
        end 
        else begin
            // Default signals
            data_out_valid <= 0;
            data_in_ready  <= 0;

            case (state)
                //------------------------------------------------------------
                // IDLE: Wait for start command
                //------------------------------------------------------------
                S_IDLE: begin
                    if (start) begin
                        // Latch request params to preserve them
                        blocks_remaining    <= data_len;
                        // Load Initial IV/Chain
                        if (mode == OP_CMAC)
                            chain_reg <= 128'd0;
                        else
                            chain_reg <= iv;
                        // Check if we need to generate subkeys for CMAC
                        if ((mode == OP_CMAC) && (!key_derived[subkey_sel] || key_update)) begin
                            // Start Subkey Generation
                            core_key        <= key;
                            core_pt         <= 0;      // Encrypt Zero block
                            core_enc        <= 1;      // Always Encrypt for K1/K2
                            state           <= S_GEN_L;
                        end 
                        else begin
                            // Ready for data immediately
                            state           <= S_WAIT_DATA;
                        end
                    end
                end

                //------------------------------------------------------------
                // SUBKEY GENERATION (One-time execution per reset)
                //------------------------------------------------------------
                S_GEN_L: begin
                    core_rst <= 0;
                    // Wait for AES(0)
                    if (core_valid) begin
                        // Derive K1
                        if (core_ct[127] == 0)
                            K1[subkey_sel] <= {core_ct[126:0], 1'b0};
                        else
                            K1[subkey_sel] <= {core_ct[126:0], 1'b0} ^ RB_CONST;
                        core_rst    <= 1;
                        state       <= S_CALC_SUBK;
                    end
                end

                S_CALC_SUBK: begin
                    // Calculate K2 based on K1
                    if (K1[subkey_sel][127] == 1'b0)
                        K2[subkey_sel] <= {K1[subkey_sel][126:0], 1'b0};
                    else
                        K2[subkey_sel] <= {K1[subkey_sel][126:0], 1'b0} ^ RB_CONST;
                    key_derived[subkey_sel] <= 1'b1;
                    state                   <= S_WAIT_DATA;
                end

                //------------------------------------------------------------
                // DATA PROCESSING LOOP
                //------------------------------------------------------------
                S_WAIT_DATA: begin
                    // Check if operation is finished
                    if (blocks_remaining == 0) begin
                        state <= S_IDLE;
                    end 
                    else begin
                        // Signal we are ready
                        data_in_ready <= 1;
                        
                        if (data_in_valid) begin
                            current_input       <= data_in;
                            blocks_remaining    <= blocks_remaining - 1;
                            data_in_ready       <= 0; // Ack
                            state               <= S_PREPARE_BLOCK;
                        end
                    end
                end

                S_PREPARE_BLOCK: begin
                    core_key <= key; // Ensure key is set

                    if (mode == OP_CBC && sel_op == 1) begin
                        //-----------------------------
                        // CBC DECRYPT
                        //-----------------------------
                        // Input to Core is Ciphertext
                        core_enc <= 0; 
                        core_pt  <= current_input;
                    end 
                    else begin
                        //-----------------------------
                        // CBC ENCRYPT or CMAC
                        //-----------------------------
                        core_enc <= 1;

                        // CMAC Last Block Handling
                        if (mode == OP_CMAC && blocks_remaining == 0) begin
                            if (last_block_partial)
                                core_pt <= mix_input ^ K2[subkey_sel]; // Partial block (padded externally)
                            else
                                core_pt <= mix_input ^ K1[subkey_sel]; // Full block
                        end
                        else begin
                            core_pt <= mix_input;
                        end
                    end
                    state <= S_PROCESS_AES;
                end

                S_PROCESS_AES: begin
                    core_rst <= 0;
                    if (core_valid) begin
                        state <= S_OUTPUT;
                    end
                end

                S_OUTPUT: begin
                    core_rst <= 1;
                    if (mode == OP_CBC) begin
                        if (sel_op == 1) begin
                            // CBC Decrypt Result: AES_OUT XOR IV(Chain)
                            data_out    <= core_ct ^ chain_reg;
                            // Next IV is the Ciphertext (which is current_input)
                            chain_reg   <= current_input;
                        end 
                        else begin
                            // CBC Encrypt Result: AES_OUT
                            data_out    <= core_ct;
                            // Next IV is the Ciphertext (AES_OUT)
                            chain_reg   <= core_ct;
                        end
                        data_out_valid  <= 1;
                        state           <= S_WAIT_DATA;
                    end 
                    else begin
                        // CMAC Mode
                        // Chain becomes the AES output (running MAC)
                        chain_reg <= core_ct;
                        
                        // Only output if it's the last block
                        if (blocks_remaining == 0) begin
                            data_out       <= core_ct;
                            data_out_valid <= 1;
                            state          <= S_IDLE;
                        end 
                        else begin
                            // Don't output intermediate MACs, just get next block
                            state <= S_WAIT_DATA;
                        end
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
