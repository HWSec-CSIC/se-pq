////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 24/11/2025
// Design Name: scp03.v
// Module Name: scp03
// Project Name: SCP-03 for SE-QUBIP
// Target Devices: ZCU104
// Tool Versions: HWSEC-OSS Framework
// Description: 
//		
//		SCP-03 Top Interface
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module scp03 #(
                parameter [1:0] AES_LEN     = 2'd3,
                parameter [255:0] KEY_ENC   = 256'h000102030405060708090A0B0C0D0E0F_1011121314151617_18191A1B1C1D1E1F,
                parameter [255:0] KEY_MAC   = 256'h202122232425262728292A2B2C2D2E2F_3031323334353637_38393A3B3C3D3E3F
                )
                (
                 input wire         clk,
                 input wire         rst,
                 input wire [127:0] trng_in,
                 output reg         trng_valid,

                 // --- I2C Interface (Host) ---
                 input wire [63:0]  i2c_data_in,        // Payload
                 input wire [7:0]   i2c_cmd_in,         // Command Opcode
                 input wire         i2c_wr_strobe,      // Pulse on write

                 // --- Readback Interface (Host) ---
                 input wire         read_req,           // Pulse to read next 64-bit word
                 output reg [63:0]  data_out,
                 output reg         data_out_valid,
                 
                 // --- Status Interface ---
                 output reg [7:0]   status_reg,         // [0]=Busy, [1]=DataReady, [2]=Auth, [7]=Error

                 // --- SE Interface (Layer 3) ---
                 output reg [7:0]   se_wr_addr,
                 output reg [63:0]  se_data_out,
                 output reg         se_wr_valid,
                 
                 // Encrypted input (Secure Read) 
                 output reg  [7:0]  se_rd_addr,  
                 input  wire [63:0] se_data_in ,
                 output reg         se_rd_valid  
                 );
 
    //----------------------------------------------------------------
    // 1. Constants & State Machine
    //----------------------------------------------------------------
    
    // Commands
    localparam CMD_INIT_UPDATE      = 8'h01;
    localparam CMD_EXT_AUTH         = 8'h02;
    localparam CMD_LOAD_BUF         = 8'h10; // Load 64 bits into buffer
    localparam CMD_UNWRAP           = 8'h11; // Secure Write (MAC+Decrypt)
    localparam CMD_WRAP             = 8'h12; // Secure Read (Encrypt+RMAC)

    // Key Contexts
    localparam CTX_STATIC_ENC       = 2'd0;
    localparam CTX_STATIC_MAC       = 2'd1;
    localparam CTX_SESSION_MAC      = 2'd2;
    localparam CTX_SESSION_RMAC     = 2'd3;

    // FSM States
    localparam S_IDLE               = 5'd0;
    localparam S_KDF_WAIT           = 5'd1;
    localparam S_DONE_READ          = 5'd2;
    
    // Handshake
    localparam S_AUTH_CHECK_CRYPT   = 5'd3; 
    localparam S_AUTH_FEED_CHAIN    = 5'd4; // Feed 16 bytes 0x00
    localparam S_AUTH_FEED_DATA_1   = 5'd5; // Header + Crypt Part 1
    localparam S_AUTH_FEED_DATA_2   = 5'd6; // Crypt Part 2 + Padding
    localparam S_AUTH_WAIT_RES      = 5'd7; // Check MAC
    
    // Unwrap (Secure Write) 
    localparam S_UNW_CALC_IV        = 5'd8; 
    localparam S_UNW_VERIFY_MAC_1   = 5'd9; 
    localparam S_UNW_VERIFY_MAC_2   = 5'd10; 
    localparam S_UNW_VERIFY_MAC_3   = 5'd11;
    localparam S_UNW_DECRYPT        = 5'd12; 

    // Wrap (Secure Read)
    localparam S_WRP_CAPTURE        = 5'd13; // Capture data from SE
    localparam S_WRP_CALC_IV        = 5'd14; // Calc R-Encryption IV
    localparam S_WRP_ENCRYPT        = 5'd15; // Encrypt Data
    localparam S_WRP_SIGN_1         = 5'd16; // Sign: Chain
    localparam S_WRP_SIGN_2         = 5'd17; // Sign: Ciphertext
    localparam S_WRP_SIGN_3         = 5'd18; // Sign: SW + Pad
    
    localparam S_ERROR              = 5'd31;

    reg [4:0] state;

    //----------------------------------------------------------------
    // 2. Internal Memory & Registers
    //----------------------------------------------------------------
    // Buffer Usage Map (4 x 64-bit)
    //
    // CMD_INIT_UPDATE (Handshake Start)
    // Input (Host Writes):
    //   buffer[0]: Host Challenge [127:64]
    //   buffer[1]: Host Challenge [63:0]
    // Output (Host Reads):
    //   buffer[0]: Card Challenge [127:64]
    //   buffer[1]: Card Challenge [63:0]
    //   buffer[2]: Card Cryptogram [127:64]
    //   buffer[3]: Card Cryptogram [63:0]
    //
    // CMD_EXT_AUTH (Handshake Finish)
    // Input (Host Writes):
    //   buffer[0]: Host Cryptogram [127:64]
    //   buffer[1]: Host Cryptogram [63:0]
    //   buffer[2]: C-MAC [127:64]
    //   buffer[3]: C-MAC [63:0]
    //
    // CMD_UNWRAP (Secure Write)
    // Input (Host Writes):
    //   buffer[0]: Encrypted Payload [127:64]
    //   buffer[1]: Encrypted Payload [63:0]
    //   buffer[2]: C-MAC [127:64]
    //   buffer[3]: C-MAC [63:0]
    //
    // CMD_WRAP (Secure Read)
    // Output (Host Reads):
    //   buffer[0]: Encrypted Response [127:64]
    //   buffer[1]: Encrypted Response [63:0]
    //   buffer[2]: R-MAC [127:64]
    //   buffer[3]: R-MAC [63:0]

    reg [63:0]  buffer [0:3];
    reg [2:0]   buf_wr_ptr;
    reg [2:0]   buf_rd_ptr;
    reg [63:0]  se_data_plain;

    // Session State
    reg [127:0]  session_ctr;      // Session Counter (starts at 1)
    reg [127:0]  mac_chain_val;    // MAC Chaining Value (starts at 0)
    reg [127:0]  aes_iv_reg;       // Calculated IV for CBC
    reg          is_auth;

    reg [127:0]  host_challenge;
    reg [127:0]  card_challenge; 

    //----------------------------------------------------------------
    // 3. KDF Instance & Interconnects
    //----------------------------------------------------------------
    reg             kdf_rst;
    reg             kdf_start;
    wire            kdf_done;
    
    // KDF -> AES Mux Signals
    wire            k_start, k_upd, k_mode, k_sel_op, k_last;
    wire [1:0]      k_sub_sel;
    wire [31:0]     k_len;
    wire [255:0]    k_key;
    wire [127:0]    k_iv;
    wire [127:0]    k_din;
    wire            k_valid;

    // KDF Resutls
    wire [255:0]    s_enc, s_mac, s_rmac;
    wire [127:0]    card_cryptogram, host_cryptogram;
      
    scp03_kdf scp03_kdf (
                         .clk                   (clk), 
                         .rst                   (kdf_rst), 
                         .start                 (kdf_start),
                         .aes_len               (AES_LEN), 
                         .static_key_enc        (KEY_ENC), 
                         .static_key_mac        (KEY_MAC),
                         .host_challenge        (host_challenge), 
                         .card_challenge        (card_challenge),
                         
                         // AES Control (Mux Inputs)
                         .crypto_start          (k_start), 
                         .crypto_key_update     (k_upd), 
                         .crypto_subkey_sel     (k_sub_sel),
                         .crypto_mode           (k_mode), 
                         .crypto_sel_op         (k_sel_op), 
                         .crypto_last_blk       (k_last),
                         .crypto_data_len       (k_len), 
                         .crypto_key            (k_key), 
                         .crypto_iv             (k_iv),
                         .crypto_data_in        (k_din), 
                         .crypto_valid          (k_valid),
                         
                         // Feedback from Engine
                         .crypto_ready          (aes_ready), 
                         .crypto_result         (aes_dout), 
                         .crypto_result_valid   (aes_dout_valid),
                         
                         // Results
                         .s_enc                 (s_enc), 
                         .s_mac                 (s_mac), 
                         .s_rmac                (s_rmac),
                         .card_cryptogram       (card_cryptogram), 
                         .host_cryptogram       (host_cryptogram),
                         .done                  (kdf_done)
                         );

    //----------------------------------------------------------------
    // 4. AES Engine & Multiplexer
    //----------------------------------------------------------------
    // FSM Control Signals
    reg             aes_rst;
    reg             f_start, f_upd;
    reg [1:0]       f_sub_sel;
    reg             f_mode, f_sel_op, f_last;
    reg [31:0]      f_len;
    reg [255:0]     f_key;
    reg [127:0]     f_iv;
    reg [127:0]     f_din;
    reg             f_din_valid;
    
    wire            aes_ready;
    wire [127:0]    aes_dout;
    wire            aes_dout_valid;
    
    // Mux Logic: If State is KDF related, let KDF control. Else FSM.
    wire use_kdf = (state == S_KDF_WAIT);

    scp03_aes scp03_aes (
                         .clk               (clk), 
                         .rst               (aes_rst),
                         .start             (use_kdf ? k_start      : f_start),
                         .key_update        (use_kdf ? k_upd        : f_upd),
                         .subkey_sel        (use_kdf ? k_sub_sel    : f_sub_sel),
                         .mode              (use_kdf ? k_mode       : f_mode),
                         .sel_op            (use_kdf ? k_sel_op     : f_sel_op),
                         .last_block_partial(use_kdf ? k_last       : f_last),
                         .data_len          (use_kdf ? k_len        : f_len),
                         .aes_len           (AES_LEN),
                         .key               (use_kdf ? k_key        : f_key),
                         .iv                (use_kdf ? k_iv         : f_iv),
                         .data_in           (use_kdf ? k_din        : f_din),
                         .data_in_valid     (use_kdf ? k_valid      : f_din_valid),
                         .data_in_ready     (aes_ready),
                         .data_out          (aes_dout),
                         .data_out_valid    (aes_dout_valid)
                         );

    //----------------------------------------------------------------
    // 5. Main Logic FSM
    //----------------------------------------------------------------
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) buffer[i] <= 0;
            buf_wr_ptr      <= 0;
            buf_rd_ptr      <= 0;
            se_data_plain   <= 0;

            session_ctr     <= 1;
            mac_chain_val   <= 0;
            aes_iv_reg      <= 0;
            is_auth         <= 0;
            
            host_challenge  <= 0;
            card_challenge  <= 0;

            kdf_rst         <= 1;
            kdf_start       <= 0;
            
            aes_rst         <= 1;
            f_start         <= 0; 
            f_upd           <= 0; 
            f_sub_sel       <= 0;
            f_mode          <= 0;
            f_sel_op        <= 0;
            f_last          <= 0;
            f_len           <= 0;
            f_key           <= 0;
            f_iv            <= 0;
            f_din           <= 0;
            f_din_valid     <= 0;

            trng_valid      <= 0;
            data_out        <= 0;
            data_out_valid  <= 0;
            status_reg      <= 0;

            se_wr_addr      <= 0;
            se_data_out     <= 0;
            se_wr_valid     <= 0;
            se_rd_addr      <= 0;
            se_rd_valid     <= 0;

            state           <= S_IDLE;
        end 
        else begin
            // Default Pulse Clearing
            kdf_start       <= 0;
            f_start         <= 0;
            f_upd           <= 0;
            se_wr_valid     <= 0;
            se_rd_valid     <= 0;
            data_out_valid  <= 0;

            // Status Register Logic
            status_reg[0] <= (state != S_IDLE && state != S_DONE_READ); // Busy
            status_reg[1] <= (state == S_DONE_READ);                    // Data Avail
            status_reg[2] <= (is_auth);                                 // Authenticated
            status_reg[7] <= (state == S_ERROR);                        // Error

            case (state)
                
                //----------------------------------------------------
                // IDLE: Command Interpretation
                //----------------------------------------------------
                S_IDLE: begin
                    if (i2c_wr_strobe) begin
                        case (i2c_cmd_in)
                            // --- 1. Load Data Buffer ---
                            // Always allowed (Data staging)
                            CMD_LOAD_BUF: begin
                                buffer[buf_wr_ptr]  <= i2c_data_in;
                                buf_wr_ptr          <= buf_wr_ptr + 1;
                            end

                            // --- 2. Handshake Start ---
                            // Always allowed (Resets session)
                            // Expects Host to have loaded 128-bit Host Challenge (buffer[0], buffer[1])
                            CMD_INIT_UPDATE: begin
                                host_challenge  <= {buffer[0], buffer[1]}; // Save Host Challenge
                                card_challenge  <= trng_in;
                                trng_valid      <= 1;
                                
                                // Reset Session State
                                session_ctr     <= 1;
                                mac_chain_val   <= 0;
                                is_auth         <= 0;
                                
                                kdf_rst         <= 1;
                                aes_rst         <= 1;

                                state           <= S_KDF_WAIT;
                            end

                            // --- 3. External Authenticate ---
                            // Always allowed (Completes handshake)
                            CMD_EXT_AUTH: begin
                                buf_wr_ptr <= 0; 
                                // Host sends HostCryptogram (128b) + MAC (128b).
                                // buffer[0,1] = HostCrypt, buffer[2,3] = MAC.
                                // 1. Verify Cryptogram locally
                                if ({buffer[0], buffer[1]} == host_cryptogram) begin
                                    // Correct! Now Verify C-MAC.
                                    state <= S_AUTH_CHECK_CRYPT;
                                end 
                                else begin
                                    state <= S_ERROR;
                                end
                            end

                            // --- 4. Unwrap (Secure Write) ---
                            // CRITICAL: Must be Authenticated!
                            CMD_UNWRAP: begin
                                if (is_auth) begin
                                    buf_wr_ptr <= 0;
                                    // Prepare AES for ICV Calculation (Encrypt session_ctr)
                                    f_key           <= s_enc;         // S-ENC
                                    f_sub_sel       <= 0; 
                                    f_upd           <= 0; // No subkey needed for CBC
                                    f_mode          <= 0; // CBC (used as ECB here IV=0)
                                    f_sel_op        <= 0; // Encrypt
                                    f_len           <= 1; // 1 Block
                                    f_iv            <= 0; // IV=0

                                    f_start         <= 1;
                                    state           <= S_UNW_CALC_IV;
                                end
                            end

                            // --- 5. Wrap (Secure Read) ---
                            // CRITICAL: Must be Authenticated!
                            CMD_WRAP: begin
                                if (is_auth) begin
                                    // 1. Set Address to SE
                                    se_rd_addr      <= i2c_data_in[63:56];
                                    // 2. Wait for Data
                                    state           <= S_WRP_CAPTURE;
                                end
                            end
                        endcase
                    end
                end

                //--------------------------------
                // KDF Wait State
                //--------------------------------
                S_KDF_WAIT: begin
                    trng_valid  <= 0;
                    kdf_rst     <= 0;
                    aes_rst     <= 0;
                    kdf_start   <= 1;
                    if (kdf_done) begin
                        // Prepare readout: Card Challenge + Card Cryptogram
                        buffer[0]   <= card_challenge[127:64];
                        buffer[1]   <= card_challenge[63:0];
                        buffer[2]   <= card_cryptogram[127:64];
                        buffer[3]   <= card_cryptogram[63:0];
                        buf_wr_ptr  <= 4; 
                        state       <= S_DONE_READ;
                    end
                end

                //----------------------------------------------------
                // EXT AUTH: Verify MAC 128-bit
                // Data to Sign: Chain(16) || Header(5)+Crypt(11) || Crypt(5)+Pad(11)
                //----------------------------------------------------
                S_AUTH_CHECK_CRYPT: begin
                    // Setup AES for CMAC
                    f_key           <= s_mac;
                    f_sub_sel       <= CTX_SESSION_MAC;
                    f_upd           <= 0; 
                    f_mode          <= 1; // CMAC
                    f_sel_op        <= 0; // Generate
                    f_iv            <= 0; // IV is 0 for the engine input
                    f_len           <= 3; // Blocks: Chain(00) + Header/CryptHigh + CryptLow/Pad
                    
                    f_start         <= 1; 
                    state           <= S_AUTH_FEED_CHAIN;
                end

                // 1. Feed Initial Chain (16 bytes 0x00)
                S_AUTH_FEED_CHAIN: begin
                    f_start <= 0;
                    if (aes_ready) begin
                        f_din       <= 0; // Explicit Chain Block
                        f_last      <= 0;
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            state       <= S_AUTH_FEED_DATA_1;
                        end
                    end
                end
                
                // Block 2: Header + Top 11 bytes of Cryptogram
                // Header: 84 82 33 00 20 (assuming Lc=0x20)
                // Cryptogram High: buffer[0] (8 bytes)
                // Cryptogram Low Top: buffer[1][63:40] (3 bytes)
                // Total Data: 5 + 8 + 3 = 16 Bytes
                S_AUTH_FEED_DATA_1: begin
                    if (aes_ready) begin
                        f_din       <= {40'h8482330020, buffer[0], buffer[1][63:40]};
                        f_last      <= 0;
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            state       <= S_AUTH_FEED_DATA_2;
                        end
                    end
                end

                // Block 3: Remaining 5 bytes of Cryptogram + Padding
                // Cryptogram Low Rem: buffer[1][39:0] (5 bytes)
                // Padding: 80 + 00s (11 bytes)
                S_AUTH_FEED_DATA_2: begin
                    if (aes_ready) begin
                        f_din       <= {buffer[1][39:0], 8'h80, 80'd0};
                        f_last      <= 0; // Full block (using K1)
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            state       <= S_AUTH_WAIT_RES;
                        end
                    end
                end

                S_AUTH_WAIT_RES: begin
                    if (aes_dout_valid) begin
                        // Verify full 128-bit MAC against buffer[2], buffer[3]
                        if (aes_dout == {buffer[2], buffer[3]}) begin
                           is_auth        <= 1;
                           mac_chain_val  <= aes_dout; // Store Full 16B CMAC as Chain
                           state          <= S_IDLE;
                        end 
                        else begin
                           state <= S_ERROR;
                        end
                    end
                end

                //----------------------------------------------------
                // UNWRAP States (Calculates ICV, Verifies MAC, Decrypts)
                //----------------------------------------------------
                // 1. Calculate ICV (Encrypt Session Counter)
                S_UNW_CALC_IV: begin
                    f_start <= 0;
                    // Feed session_ctr
                    if (aes_ready) begin
                        f_din       <= session_ctr;
                        f_din_valid <= 1;
                        if (f_din_valid) f_din_valid <= 0;
                    end
                    
                    if (aes_dout_valid) begin
                        aes_iv_reg      <= aes_dout; // Store ICV
                        
                        // Setup for MAC Verification
                        f_key           <= s_mac;
                        f_sub_sel       <= CTX_SESSION_MAC; // Context 2
                        f_upd           <= 0; 
                        f_mode          <= 1; // CMAC
                        f_sel_op        <= 0; // Generate
                        f_iv            <= 0; // IV is 0
                        f_len           <= 3; // Chain + (Head/CipherHigh) + (CipherLow/Pad)
                        
                        f_start         <= 1;
                        state           <= S_UNW_VERIFY_MAC_1;
                    end
                end
                
                // 2. Feed Chain (16 bytes)
                S_UNW_VERIFY_MAC_1: begin
                    f_start <= 0;
                    if (aes_ready) begin
                        f_din       <= mac_chain_val; // Block 1: Chain
                        
                        f_last      <= 0; // Not last
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            state   <= S_UNW_VERIFY_MAC_2;
                        end
                    end
                end

                // 3. Feed Header + CipherHigh
                // Header: 84 E2 00 00 20 (5 Bytes)
                // CipherHigh: buffer[0] (8 bytes)
                // CipherMid : buffer[1][63:40] (3 bytes)
                S_UNW_VERIFY_MAC_2: begin
                    if (aes_ready) begin
                        f_din       <= {40'h84E2000020, buffer[0], buffer[1][63:40]}; // Block 2
                        f_last      <= 0;
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            state       <= S_UNW_VERIFY_MAC_3;
                        end
                    end
                end

                // 4. Feed CipherLow + Padding
                // CipherRem: buffer[1][39:0] (5 bytes)
                // Padding:   0x80 00... (11 bytes)
                // Total: 16 bytes
                S_UNW_VERIFY_MAC_3: begin
                    if (aes_ready) begin
                        f_din       <= {buffer[1][39:0], 8'h80, 80'd0}; // Block 3
                        f_last      <= 1; // Last block (Partial -> use K2)
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            // Wait for result
                        end
                    end
                    
                    if (aes_dout_valid) begin
                        // Verify 128-bit MAC against buffer[2], buffer[3]
                        if (aes_dout == {buffer[2], buffer[3]}) begin
                            mac_chain_val <= aes_dout; // Update Chain
                            
                            // Setup Decryption
                            f_key       <= s_enc;
                            f_mode      <= 0; // CBC
                            f_sel_op    <= 1; // Decrypt
                            f_last      <= 0;
                            f_iv        <= aes_iv_reg; // From Step 1
                            f_len       <= 1; // 1 Block (128 bits of data)
                            f_start     <= 1;
                            
                            state       <= S_UNW_DECRYPT;
                        end 
                        else begin
                            state       <= S_ERROR;
                        end
                    end
                end

                S_UNW_DECRYPT: begin
                    f_start <= 0;
                    if (aes_ready) begin
                        f_din       <= {buffer[0], buffer[1]};
                        f_din_valid <= 1;
                        if (f_din_valid) f_din_valid <= 0;
                    end
                    
                    if (aes_dout_valid) begin
                        // Plaintext is [Addr(1B)] [Data(8B)] [Padding(7B)]
                        // Output to SE
                        se_wr_addr      <= aes_dout[127:120];
                        se_data_out     <= aes_dout[119:56];
                        se_wr_valid     <= 1;
                        
                        session_ctr     <= session_ctr + 1;
                        buf_wr_ptr      <= 0; // Reset buffer
                        
                        state           <= S_IDLE;
                    end
                end

                //-------------------------------------------------------
                // WRAP States
                //-------------------------------------------------------
                // 1. Capture Data from SE
                S_WRP_CAPTURE: begin
                    se_data_plain   <= se_data_in;
                    se_rd_valid     <= 1;
                    
                    // Start IV Calculation (Encrypt Counter)
                    // SCP-03 Rule: MSB of counter set to 1 (0x80) for Response IV
                    f_din           <= {1'b1, session_ctr[126:0]}; 
                    
                    f_key           <= s_enc;        
                    f_upd           <= 0; 
                    f_mode          <= 0; // CBC (ECB)
                    f_sel_op        <= 0; // Encrypt
                    f_len           <= 1; 
                    f_iv            <= 0; 
                    f_start         <= 1;
                    
                    state           <= S_WRP_CALC_IV;
                end

                // 2. Store IV, Start Encryption
                S_WRP_CALC_IV: begin
                    f_start     <= 0;
                    se_rd_valid <= 0;
                    // Feed counter
                    if (aes_ready) begin
                         f_din_valid <= 1;
                         if (f_din_valid) f_din_valid <= 0;
                    end
                    
                    if (aes_dout_valid) begin
                        aes_iv_reg <= aes_dout; // Response IV
                        
                        // Setup Encryption of Payload
                        // Data: se_data_plain (64b)
                        // Pad: 80 00... (64b)
                        // Total: 128b (1 Block)
                        f_key           <= s_enc;
                        f_mode          <= 0; // CBC
                        f_sel_op        <= 0; // Encrypt
                        f_iv            <= aes_dout; // Use computed IV
                        f_len           <= 1; 
                        f_start         <= 1;
                        
                        state           <= S_WRP_ENCRYPT;
                    end
                end

                // 3. Perform Encryption, Store Ciphertext
                S_WRP_ENCRYPT: begin
                    f_start <= 0;
                    if (aes_ready) begin
                        // Encrypt {Data, Padding}
                        f_din       <= {se_data_plain, 8'h80, 56'd0};
                        f_din_valid <= 1;
                        if (f_din_valid) f_din_valid <= 0;
                    end

                    if (aes_dout_valid) begin
                        // Store Ciphertext [128 bits] in Buffer
                        buffer[0] <= aes_dout[127:64]; // High
                        buffer[1] <= aes_dout[63:0];   // Low
                        
                        buf_wr_ptr <= 2;
                        
                        // Setup Signing (R-MAC)
                        // Key: S-RMAC (Context 3)
                        // IV: mac_chain_val (From previous command)
                        // Data: Chain(16) + Cipher(16) + SW_Pad(16)
                        f_key           <= s_rmac;
                        f_sub_sel       <= CTX_SESSION_RMAC; 
                        f_upd           <= 0;
                        f_mode          <= 1; // CMAC
                        f_sel_op        <= 0; // Generate
                        f_iv            <= 0; // Feed Chain as data
                        f_len           <= 3; 
                        f_start         <= 1;
                        
                        state           <= S_WRP_SIGN_1;
                    end
                end

                // 4. R-MAC Step 1: Feed Chain
                S_WRP_SIGN_1: begin
                    f_start <= 0;
                    if (aes_ready) begin
                        f_din       <= mac_chain_val;
                        f_last      <= 0;
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            state       <= S_WRP_SIGN_2;
                        end
                    end
                end

                // 5. R-MAC Step 2: Feed Ciphertext
                S_WRP_SIGN_2: begin
                    if (aes_ready) begin
                        f_din       <= {buffer[0], buffer[1]};
                        f_last      <= 0;
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            state       <= S_WRP_SIGN_3;
                        end
                    end
                end

                // 6. R-MAC Step 3: Feed SW + Padding
                S_WRP_SIGN_3: begin
                    if (aes_ready) begin
                        // Status Word 9000 + Pad 80...
                        // 16'h9000 (2B) + 8'h80 (1B) + 13B zeros
                        f_din       <= {16'h9000, 8'h80, 104'd0};
                        f_last      <= 1; // Partial Block -> K2
                        f_din_valid <= 1;
                        if (f_din_valid) begin
                            f_din_valid <= 0;
                            // Wait
                        end
                    end
                    
                    if (aes_dout_valid) begin
                        // R-MAC calculated.
                        // Store Top 64 bits in buffer[2].
                        buffer[2]   <= aes_dout[127:64];
                        buffer[3]   <= aes_dout[63:0];
                        buf_wr_ptr  <= 4;

                        f_last      <= 0;
                        
                        // Increment Counter
                        session_ctr <= session_ctr + 1;
                        
                        // Setup Readout
                        state       <= S_DONE_READ;
                    end
                end

                //----------------------------------------------------
                // Readout (Shared for Handshake responses)
                //----------------------------------------------------
                S_DONE_READ: begin
                    data_out_valid <= 1;
                    data_out       <= buffer[buf_rd_ptr];
                    if (read_req) begin
                        buf_rd_ptr <= buf_rd_ptr + 1;
                        if (buf_rd_ptr == (buf_wr_ptr - 1)) begin
                            buf_wr_ptr  <= 0;
                            buf_rd_ptr  <= 0;
                            state       <= S_IDLE; // Read 4 words (0,1,2,3)
                        end
                    end
                end
                
                //----------------------------------------------------
                // Error Trap
                //----------------------------------------------------
                S_ERROR: begin
                    // Stuck here until Reset
                    // Host detects via status_reg[7]
                end
            endcase
        end
    end

endmodule
