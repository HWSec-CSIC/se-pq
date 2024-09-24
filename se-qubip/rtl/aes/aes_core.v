//======================================================================
// Rewrite by:
// Apurba Karmakar
//Instituto de Microelectrónica de Sevilla (IMSE-CNM)
// apurba@imse-cnm.csic.es
//
//======================================================================

//======================================================================
//
// aes_core.v
// ----------
// The AES core. This core supports key size of 128, and 256 bits.
// Most of the functionality is within the submodules.
//
//
// 
// Copyright (c) 2013, 2014, Secworks Sweden AB
// All rights reserved.

//======================================================================

// `default_nettype none

module aes_core(
                input wire            clk,
                input wire            reset_n,
                input wire            ecb_cbc, // 0 -> ecb mode, 1 -> cbc mode
                input wire            encdec,
                input wire            start,
   //             input wire            init,
  //              input wire            next,
                output wire           ready,
                input wire  [127 : 0] iv,
                input wire [255 : 0]  key,
                input wire            keylen,

                input wire [127 : 0]  block,
                output wire [127 : 0] result,
                output wire           result_valid,
                output wire           key_valid
               );


  wire [127 : 0] plaintext;
  wire [127:0] xor_result;
  wire [127:0] result_reg ;
  wire [127:0] xor_output;
  
  reg init_reg;
  wire init;
  
  wire next;
  reg next_reg;
  
  //wire [127 : 0] iv =  128'h000102030405060708090a0b0c0d0e0f;
  assign xor_result = iv ^ block;
  assign plaintext = ((ecb_cbc == 1'b1) && (encdec == 1'b1)) ? xor_result: block;
  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE  = 2'h0;
  localparam CTRL_INIT  = 2'h1;
  localparam CTRL_NEXT  = 2'h2;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [1 : 0] aes_core_ctrl_reg;
  reg [1 : 0] aes_core_ctrl_new;
  reg         aes_core_ctrl_we;

  reg         result_valid_reg;
  reg         result_valid_new;
  reg         result_valid_we;
  
  wire         result_done_flag;
  reg         result_done;

  reg         ready_reg;
  reg         ready_new;
  reg         ready_we;
  //reg            next;

  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg            init_state;

  wire [127 : 0] round_key;
  wire           key_ready;

  reg            enc_next;
  wire [3 : 0]   enc_round_nr;
  wire [127 : 0] enc_new_block;
  wire           enc_ready;
  wire [31 : 0]  enc_sboxw;

  reg            dec_next;
  wire [3 : 0]   dec_round_nr;
  wire [127 : 0] dec_new_block;
  wire           dec_ready;

  reg [127 : 0]  muxed_new_block;
  reg [3 : 0]    muxed_round_nr;
  reg            muxed_ready;

  wire [31 : 0]  keymem_sboxw;

         


/* verilator lint_off UNOPTFLAT */
  reg [31 : 0]   muxed_sboxw;
  wire [31 : 0]  new_sboxw;
/* verilator lint_on UNOPTFLAT */


  //----------------------------------------------------------------
  // Instantiations.
  //----------------------------------------------------------------
  aes_encipher_block enc_block(
                               .clk(clk),
                               .reset_n(reset_n),

                               .next(enc_next),

                               .keylen(keylen),
                               .round(enc_round_nr),
                               .round_key(round_key),

                               .sboxw(enc_sboxw),
                               .new_sboxw(new_sboxw),

                               .block(plaintext),
                               .new_block(enc_new_block),
                               .ready(enc_ready)
                              );


  aes_decipher_block dec_block(
                               .clk(clk),
                               .reset_n(reset_n),

                               .next(dec_next),

                               .keylen(keylen),
                               .round(dec_round_nr),
                               .round_key(round_key),

                               .block(plaintext),
                               .new_block(dec_new_block),
                               .ready(dec_ready)
                              );


  aes_key_mem keymem(
                     .clk(clk),
                     .reset_n(reset_n),

                     .key(key),
                     .keylen(keylen),
                     .init(init),

                     .round(muxed_round_nr),
                     .round_key(round_key),
                     .ready(key_ready),

                     .sboxw(keymem_sboxw),
                     .new_sboxw(new_sboxw)
                    );


  aes_sbox sbox_inst(.sboxw(muxed_sboxw), .new_sboxw(new_sboxw));


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign key_valid = key_ready;
  
  assign ready        = ready_reg;
  
//  assign result       = muxed_new_block;
  assign result_reg       = muxed_new_block;
  assign xor_output = iv ^ result_reg;
  assign result = ((ecb_cbc == 1'b1) && (encdec == 1'b0))? xor_output: result_reg;
  //assign result_valid = result_valid_reg;
  assign result_valid = result_done;
  assign result_done_flag = result_valid_reg;
  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      if (!reset_n)
        begin
          result_valid_reg  <= 1'b0;
          ready_reg         <= 1'b0;
          aes_core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (result_valid_we) begin
            result_valid_reg <= result_valid_new;
          end
          else begin
            result_valid_reg <= result_valid_reg;
          end

          if (ready_we) begin
            ready_reg <= ready_new;
          end
          else begin
            ready_reg <= ready_reg;
          end

          if (aes_core_ctrl_we) begin
            aes_core_ctrl_reg <= aes_core_ctrl_new;
          end
          else begin
            aes_core_ctrl_reg <= aes_core_ctrl_reg;
          end
        end
    end // reg_update

  always @ (posedge clk)
    begin: regult_done
      if (!reset_n)
        begin
          result_done  <= 1'b0;
        end
      else
        begin
          if (result_done_flag) begin
            result_done <= 1'b1;
          end
          else begin
            result_done <= 1'b0;
          end       
        end
    end // reg_update

    reg [3:0] count;  // 4-bit counter to count up to 15

    always @ (posedge clk ) begin
        if (!reset_n) begin
            init_reg <= 0;       
            count <= 0;      
        end else if (start && count < 15) begin
            init_reg <= 1;       
            count <= count + 1;
        end else begin
            init_reg <= 0;      
            count <= 0; 
        end
    end

assign init = init_reg;

    reg [3:0] count1, key_valid_count;       
    reg start_flag;           
    reg triggered;            

  /*  always @(posedge clk ) begin
        if (!reset_n) begin
            next_reg <= 0;    
            count1 <= 0;      
            start_flag <= 0;  
            triggered <= 0;   
        end else if (key_valid && !start_flag && !triggered) begin
            start_flag <= 1;  
            next_reg <= 1;   
            count1 <= 1;      
            triggered <= 1;  
        end else if (start_flag && count1 < 15) begin
            count1 <= count1 + 1;
        end else if (count1 == 15) begin
            next_reg <= 0;   
            start_flag <= 0;  
        end
    end */
    
    
    always @(posedge clk ) begin
    if (!reset_n) begin
        next_reg <= 0;    
        count1 <= 0;      
        start_flag <= 0;  
        triggered <= 0;   
        key_valid_count <= 0;  // New counter for key_valid duration
    end else if (key_valid && !start_flag && !triggered) begin
        if (key_valid_count < 5) begin
            key_valid_count <= key_valid_count + 1;  // Increment count if key_valid is high
        end else begin
            start_flag <= 1;  
            next_reg <= 1;   
            count1 <= 1;      
            triggered <= 1;  
            key_valid_count <= 0;  // Reset key_valid_count after starting
        end
    end else if (!key_valid) begin
        key_valid_count <= 0;  // Reset the counter if key_valid goes low
    end else if (start_flag && count1 < 15) begin
        count1 <= count1 + 1;
    end else if (count1 == 15) begin
        next_reg <= 0;   
        start_flag <= 0;  
    end
    else begin
         next_reg <= 0;    
        count1 <= 0;      
        start_flag <= 0;  
        triggered <= 0;   
        key_valid_count <= 0;  
        
    end
end


assign next =next_reg;

  /*  
    always @*
    begin : next_operation
      if (key_ready)
        begin
          next = 1'b1;
        end
      else
        begin
          next = 1'b0;
        end
    end // sbox_mux

    */
    
  //----------------------------------------------------------------
  // sbox_mux
  //
  // Controls which of the encipher datapath or the key memory
  // that gets access to the sbox.
  //----------------------------------------------------------------
  always @*
    begin : sbox_mux
      if (init_state)
        begin
          muxed_sboxw = keymem_sboxw;
        end
      else
        begin
          muxed_sboxw = enc_sboxw;
        end
    end // sbox_mux


  //----------------------------------------------------------------
  // encdex_mux
  //
  // Controls which of the datapaths that get the next signal, have
  // access to the memory as well as the block processing result.
  //----------------------------------------------------------------
  always @*
    begin : encdec_mux
      enc_next = 1'b0;
      dec_next = 1'b0;

      if (encdec)
        begin
          // Encipher operations
         
          enc_next        = next;
          dec_next        = dec_next;
          muxed_round_nr  = enc_round_nr;
          muxed_new_block = enc_new_block;
          muxed_ready     = enc_ready;
        end
      else
        begin
          // Decipher operations
          enc_next        = enc_next;
          dec_next        = next;
          muxed_round_nr  = dec_round_nr;
          muxed_new_block = dec_new_block;
          muxed_ready     = dec_ready;
        end
    end // encdec_mux


  //----------------------------------------------------------------
  // aes_core_ctrl
  //
  // Control FSM for aes core. Basically tracks if we are in
  // key init, encipher or decipher modes and connects the
  // different submodules to shared resources and interface ports.
  //----------------------------------------------------------------
  always @*
    begin : aes_core_ctrl
      init_state        = 1'b0;
      ready_new         = 1'b0;
      ready_we          = 1'b0;
      result_valid_new  = 1'b0;
      result_valid_we   = 1'b0;
      aes_core_ctrl_new = CTRL_IDLE;
      aes_core_ctrl_we  = 1'b0;

      case (aes_core_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                init_state        = 1'b1;
                ready_new         = 1'b0;
                ready_we          = 1'b1;
                result_valid_new  = 1'b0;
                result_valid_we   = 1'b1;
                aes_core_ctrl_new = CTRL_INIT;
                aes_core_ctrl_we  = 1'b1;
              end
            else if (next)
              begin
                init_state        = 1'b0;
                ready_new         = 1'b0;
                ready_we          = 1'b1;
                result_valid_new  = 1'b0;
                result_valid_we   = 1'b1;
                aes_core_ctrl_new = CTRL_NEXT;
                aes_core_ctrl_we  = 1'b1;
              end
              else begin 
                init_state        = init_state;
                ready_new         = ready_new;
                ready_we          = ready_we;
                result_valid_new  = result_valid_new;
                result_valid_we   = result_valid_we;
                aes_core_ctrl_new = aes_core_ctrl_new;
                aes_core_ctrl_we  = aes_core_ctrl_we;
              
              
              end
          end

        CTRL_INIT:
          begin
            init_state = 1'b1;

            if (key_ready)
              begin
                ready_new         = 1'b1;
                ready_we          = 1'b1;
                aes_core_ctrl_new = CTRL_IDLE;
                aes_core_ctrl_we  = 1'b1;
                result_valid_new  = result_valid_new;
                result_valid_we   = result_valid_we;
              end
              
              else begin
                ready_new         = ready_new;
                ready_we          = ready_we;
                result_valid_new  = result_valid_new;
                result_valid_we   = result_valid_we;
                aes_core_ctrl_new = aes_core_ctrl_new;
                aes_core_ctrl_we  = aes_core_ctrl_we;
              
              end
          end

        CTRL_NEXT:
          begin
            init_state = 1'b0;

            if (muxed_ready)
              begin
                ready_new         = 1'b1;
                ready_we          = 1'b1;
                result_valid_new  = 1'b1;
                result_valid_we   = 1'b1;
                aes_core_ctrl_new = CTRL_IDLE;
                //aes_core_ctrl_new = CTRL_NEXT;
                aes_core_ctrl_we  = 1'b1;
             end
             else begin
             
                ready_new         = ready_new;
                ready_we          = ready_we;
                result_valid_new  = result_valid_new;
                result_valid_we   = result_valid_we;
                aes_core_ctrl_new = aes_core_ctrl_new;
                aes_core_ctrl_we  = aes_core_ctrl_we;
              
              end
          end

        default:
          begin
      init_state        = 1'b0;
      ready_new         = 1'b0;
      ready_we          = 1'b0;
      result_valid_new  = 1'b0;
      result_valid_we   = 1'b0;
      aes_core_ctrl_new = CTRL_IDLE;
      aes_core_ctrl_we  = 1'b0;
          end
      endcase // case (aes_core_ctrl_reg)

    end // aes_core_ctrl
endmodule // aes_core

//======================================================================
// EOF aes_core.v
//======================================================================
