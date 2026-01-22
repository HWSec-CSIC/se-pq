////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 25/11/2025
// Design Name: scp03_kdf.v
// Module Name: scp03_kdf.v
// Project Name: SCP-03 for SE-QUBIP
// Target Devices: ZCU104
// Tool Versions: HWSEC-OSS Framework
// Description: 
//
//      Implements SCP-03 KDF (NIST SP 800-108 Counter Mode) using CMAC.
//      Derives Session Keys (S-ENC, S-MAC, S-RMAC) from Static Keys.
//      Supports AES-128, AES-192, and AES-256.
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module scp03_kdf(
                 input wire clk,
                 input wire rst,
                 input wire start,
                 
                 // Configuration
                 input wire [1:0]       aes_len,            // 1: 128-bit, 2: 192-bit, 3: 256-bit
                 input wire [255:0]     static_key_enc,     // Static K-ENC
                 input wire [255:0]     static_key_mac,     // Static K-MAC
                 input wire [127:0]     host_challenge,
                 input wire [127:0]     card_challenge,
                 
                 // Interface to scp03_aes Module
                 output reg             crypto_start,
                 output reg             crypto_key_update,  // Pulse to force subkey regen
                 output reg [1:0]       crypto_subkey_sel,  // 0:K-ENC, 1:K-MAC, 2:S-MAC, 3:S-RMAC
                 output wire            crypto_mode,        // Always 1 (CMAC)
                 output wire            crypto_sel_op,      // Always 0 (Generate)
                 output wire            crypto_last_blk,    // Always 0 (Full blocks, XOR K1)
                 output wire [31:0]     crypto_data_len,    // Always 3 blocks (48 bytes)
                 output reg [255:0]     crypto_key, 
                 output reg [127:0]     crypto_iv,          // Always 0 for KDF CMAC start
                 output reg [127:0]     crypto_data_in,
                 output reg             crypto_valid,
                 input  wire            crypto_ready,
                 input  wire [127:0]    crypto_result,
                 input  wire            crypto_result_valid,
                 
                 // Output Session Keys
                 output reg [255:0]     s_enc,
                 output reg [255:0]     s_mac,
                 output reg [255:0]     s_rmac,
                 output reg [127:0]     card_cryptogram,
                 output reg [127:0]     host_cryptogram,
                 output reg             done
                 );

    //----------------------------------------------------------------
    // Constants (SCP-03 Table 4-1)
    //----------------------------------------------------------------
    localparam CONST_CARD_CRYPT = 8'h00;
    localparam CONST_HOST_CRYPT = 8'h01;
    localparam CONST_ENC        = 8'h04;
    localparam CONST_MAC        = 8'h06;
    localparam CONST_RMAC       = 8'h07;

    localparam AES_128          = 2'b01;
    localparam AES_192          = 2'b10;
    localparam AES_256          = 2'b11;

    // Key Contexts for scp03_aes
    localparam CTX_STATIC_ENC   = 2'd0;
    localparam CTX_STATIC_MAC   = 2'd1;
    localparam CTX_SESSION_MAC  = 2'd2;
    // Context 3 (S-RMAC) is not used inside KDF logic, but used later in protocol

    assign crypto_mode      = 1; // Always CMAC
    assign crypto_sel_op    = 0; // Always Generate
    assign crypto_last_blk  = 0; // Always Full Block (48 bytes input)
    assign crypto_data_len  = 3; // Always 3 blocks (Label + HostChal + CardChal)

    //----------------------------------------------------------------
    // FSM States
    //----------------------------------------------------------------
    localparam S_IDLE               = 4'd0;

    // Key Derivation Phases    
    localparam S_LOAD_ENC_1         = 4'd1; // First 128 bits
    localparam S_LOAD_ENC_2         = 4'd2; // Remaining bits (64 for 192, 128 for 256)
    localparam S_LOAD_MAC_1         = 4'd3;
    localparam S_LOAD_MAC_2         = 4'd4;
    localparam S_LOAD_RMAC_1        = 4'd5;
    localparam S_LOAD_RMAC_2        = 4'd6;
    
    // Cryptograms Generation Phase
    localparam S_LOAD_CARD_CRYPT    = 4'd7;
    localparam S_LOAD_HOST_CRYPT    = 4'd8;

    localparam S_WAIT_RES           = 4'd9; // Wait for Crypto Engine
    localparam S_DONE               = 4'd10;

    reg [3:0] state;
    reg [3:0] next_state_after_wait; 

    //----------------------------------------------------------------
    // Data Construction
    //----------------------------------------------------------------
    reg [7:0]  current_constant;
    reg [7:0]  counter_i;
    reg [15:0] length_L;

    // Determine L logic modified to support 64-bit output for cryptograms
    // We use a separate signal or logic inside the state machine to override L
    reg override_L_128; 
    
    // Determine L based on aes_len
    always @(*) begin
        if (override_L_128) begin
            length_L = 16'h0080; // 128 bits for Cryptograms
        end 
        else begin
            case (aes_len)
                AES_128: length_L = 16'h0080;
                AES_192: length_L = 16'h00C0;
                AES_256: length_L = 16'h0100;
                default: length_L = 16'h0080;
            endcase
        end
    end

    // Block 1 Construction (16 Bytes)
    // SCP-03 Format: Label(11x00 || Const) || Sep(00) || L || i
    wire [127:0] block_1 = {
                            88'd0,              // Bytes 0-10:  Label Padding (11 bytes)
                            current_constant,   // Byte 11:     Label Constant
                            8'h00,              // Byte 12:     Separator
                            length_L,           // Bytes 13-14: Length L
                            counter_i           // Byte 15:     Counter i
                            };

    // Data Feeding Counter
    reg [1:0] block_idx; // 0=Block1, 1=HostChal, 2=CardChal

    //----------------------------------------------------------------
    // Main Logic
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            crypto_start            <= 0;
            crypto_key_update       <= 0; // Init
            crypto_subkey_sel       <= 0; // Init
            crypto_key              <= 0;
            crypto_iv               <= 0; // Always 0
            crypto_data_in          <= 0;
            crypto_valid            <= 0;
            
            current_constant        <= 0;
            counter_i               <= 0;
            override_L_128          <= 0;
            block_idx               <= 0;

            s_enc                   <= 0; 
            s_mac                   <= 0; 
            s_rmac                  <= 0;
            card_cryptogram         <= 0;
            host_cryptogram         <= 0;
            done                    <= 0;
            
            state                   <= S_IDLE;
            next_state_after_wait   <= S_IDLE;
        end 
        else begin
            case (state)
                S_IDLE: begin
                    done                <= 0;
                    override_L_128      <= 0;   // Default to Key Length
                    crypto_key_update   <= 0;
                    if (start) state    <= S_LOAD_ENC_1;
                end

                //----------------------------------------------------------
                // S-ENC DERIVATION
                // Key: Static ENC (Context 0)
                //----------------------------------------------------------
                S_LOAD_ENC_1: begin
                    crypto_key              <= static_key_enc;
                    crypto_subkey_sel       <= CTX_STATIC_ENC; 
                    crypto_key_update       <= 1; // New Key Loaded
                    
                    current_constant        <= CONST_ENC;
                    counter_i               <= 8'h01;
                    crypto_start            <= 1;
                    block_idx               <= 0; 
                    
                    // If AES-128, we are done after this. Else we need part 2.
                    if (aes_len == AES_128) next_state_after_wait <= S_LOAD_MAC_1;
                    else                    next_state_after_wait <= S_LOAD_ENC_2;
                    
                    state                   <= S_WAIT_RES;
                end

                S_LOAD_ENC_2: begin
                    // Key and Constant remain the same
                    counter_i               <= 8'h02;
                    crypto_start            <= 1;
                    
                    block_idx               <= 0;

                    next_state_after_wait   <= S_LOAD_MAC_1;
                    state                   <= S_WAIT_RES;
                end

                //----------------------------------------------------------
                // S-MAC DERIVATION
                // Key: Static MAC (Context 1)
                //----------------------------------------------------------
                S_LOAD_MAC_1: begin
                    crypto_key              <= static_key_mac;
                    crypto_subkey_sel       <= CTX_STATIC_MAC;
                    crypto_key_update       <= 1; // New Key Loaded

                    current_constant        <= CONST_MAC;
                    counter_i               <= 8'h01;
                    crypto_start            <= 1;
                    block_idx               <= 0;
                    
                    if (aes_len == AES_128) next_state_after_wait <= S_LOAD_RMAC_1;
                    else                    next_state_after_wait <= S_LOAD_MAC_2;
                        
                    state                   <= S_WAIT_RES;
                end
                
                S_LOAD_MAC_2: begin
                    counter_i               <= 8'h02;
                    crypto_start            <= 1;
                    
                    block_idx               <= 0;

                    next_state_after_wait   <= S_LOAD_RMAC_1;
                    state                   <= S_WAIT_RES;
                end

                //----------------------------------------------------------
                // S-RMAC DERIVATION
                // Key: Static MAC (Context 1) - Reused!
                //----------------------------------------------------------
                S_LOAD_RMAC_1: begin
                    crypto_key              <= static_key_mac;
                    crypto_subkey_sel       <= CTX_STATIC_MAC;
                    crypto_key_update       <= 0;               // NO Key Update here (Same as S-MAC derivation)

                    current_constant        <= CONST_RMAC;
                    counter_i               <= 8'h01;
                    crypto_start            <= 1;
                    block_idx               <= 0;

                    if (aes_len == AES_128) next_state_after_wait <= S_LOAD_CARD_CRYPT;
                    else                    next_state_after_wait <= S_LOAD_RMAC_2;
                        
                    state                   <= S_WAIT_RES;
                end

                S_LOAD_RMAC_2: begin
                    counter_i               <= 8'h02;
                    crypto_start            <= 1;

                    block_idx               <= 0;

                    next_state_after_wait   <= S_LOAD_CARD_CRYPT;
                    state                   <= S_WAIT_RES;
                end

                //---------------------------------------------------------
                // CARD CRYPTOGRAM GENERATION
                // Key: Session S-MAC (Context 2)
                //---------------------------------------------------------
                S_LOAD_CARD_CRYPT: begin
                    crypto_key              <= s_mac; // Use the DERIVED Session MAC Key
                    crypto_subkey_sel       <= CTX_SESSION_MAC;
                    crypto_key_update       <= 1; // New Key Loaded

                    current_constant        <= CONST_CARD_CRYPT;
                    counter_i               <= 8'h01;
                    override_L_128          <= 1;     // Force L=64 bits

                    crypto_start            <= 1;
                    block_idx               <= 0;
                    
                    next_state_after_wait   <= S_LOAD_HOST_CRYPT;
                    state                   <= S_WAIT_RES;
                end

                //---------------------------------------------------------
                // HOST CRYPTOGRAM GENERATION
                // Key: Session S-MAC (Context 2) - Reused!
                //---------------------------------------------------------
                S_LOAD_HOST_CRYPT: begin
                    crypto_key              <= s_mac; // Use S-MAC
                    crypto_subkey_sel       <= CTX_SESSION_MAC;
                    crypto_key_update       <= 0; // No Update

                    current_constant        <= CONST_HOST_CRYPT;
                    counter_i               <= 8'h01;
                    override_L_128          <= 1;     // Force L=64 bits

                    crypto_start            <= 1;
                    block_idx               <= 0;
                    
                    next_state_after_wait   <= S_DONE;
                    state                   <= S_WAIT_RES;
                end

                //----------------------------------------------------------
                // DRIVE CRYPTO ENGINE
                //----------------------------------------------------------
                S_WAIT_RES: begin
                    crypto_start      <= 0; // Clear pulse
                    crypto_key_update <= 0; // Clear pulse

                    // Feed Data Logic
                    if (crypto_ready & !crypto_valid) begin
                        crypto_valid <= 1;
                        if (block_idx == 0) begin
                            crypto_data_in  <= block_1; 
                            block_idx       <= 1;
                        end 
                        else if (block_idx == 1) begin
                            crypto_data_in  <= host_challenge; // Block 2: Host Challenge (128-bit)
                            block_idx       <= 2;
                        end
                        else if (block_idx == 2) begin
                            crypto_data_in  <= card_challenge; // Block 3: Card Challenge (128-bit)
                            block_idx       <= 3; // Done feeding
                        end
                    end 
                    else begin
                        crypto_valid <= 0;
                    end

                    // Capture Result
                    if (crypto_result_valid) begin
                        
                        // Logic to route result to correct register slice
                        // based on where we are going next
                        
                        // --- S-ENC Capture ---
                        if (next_state_after_wait == S_LOAD_MAC_1 && aes_len == AES_128)
                            s_enc[255:128] <= crypto_result; // 128-bit Full
                        else if (next_state_after_wait == S_LOAD_ENC_2)
                            s_enc[255:128] <= crypto_result; // 192/256 High bits (i=1)
                        else if (next_state_after_wait == S_LOAD_MAC_1) begin 
                            // Second Iteration (i=2)
                            if (aes_len == AES_192) 
                                // For 192, we need 64 bits. Take MSBs of result.
                                s_enc[127:64] <= crypto_result[127:64]; 
                            else // AES_256
                                s_enc[127:0] <= crypto_result;
                        end
                        
                        // --- S-MAC Capture ---
                        else if (next_state_after_wait == S_LOAD_RMAC_1 && aes_len == AES_128)
                            s_mac[255:128] <= crypto_result;
                        else if (next_state_after_wait == S_LOAD_MAC_2)
                            s_mac[255:128] <= crypto_result;
                        else if (next_state_after_wait == S_LOAD_RMAC_1) begin
                            if (aes_len == AES_192) 
                                s_mac[127:64] <= crypto_result[127:64];
                            else 
                                s_mac[127:0] <= crypto_result;
                        end

                        // --- S-RMAC Capture ---
                        else if (next_state_after_wait == S_LOAD_CARD_CRYPT  && aes_len == AES_128)
                            s_rmac[255:128] <= crypto_result;
                        else if (next_state_after_wait == S_LOAD_RMAC_2)
                            s_rmac[255:128] <= crypto_result;
                        else if (next_state_after_wait == S_LOAD_CARD_CRYPT ) begin
                            if (aes_len == AES_192) 
                                s_rmac[127:64] <= crypto_result[127:64];
                            else 
                                s_rmac[127:0] <= crypto_result;
                        end

                        // --- CRYPTOGRAMS Capture
                        else if (next_state_after_wait == S_LOAD_HOST_CRYPT) begin
                            card_cryptogram <= crypto_result; // Full 128 bits
                        end
                        else if (next_state_after_wait == S_DONE && override_L_128) begin
                            host_cryptogram <= crypto_result; // Full 128 bits
                        end

                        state <= next_state_after_wait;
                    end
                end

                S_DONE: begin
                    done            <= 1;
                    override_L_128  <= 0; // Reset
                    if (!start) state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
