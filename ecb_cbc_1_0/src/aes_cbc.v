
/*

module aes_cbc (

    input wire clk,
    input wire reset_n,
    input wire encdec,
    input wire init_core,
    input wire keylen,
    input wire start,
    input wire [127:0] iv, // Initialization Vector
    input wire [255:0] key, // 256-bit Key
    input wire [127:0] plaintext, // Plaintext block
   // input reg [7:0] block_idx, // Block index
    output reg [127:0] ciphertext, // Ciphertext block
    output reg done
);
 parameter n = 4; // Number of blocks

    // State encoding
    localparam IDLE = 3'b000,
               LOAD = 3'b001,
               DELAY = 3'b010,
      
               ENC = 3'b011,
               DONE = 3'b100;

    reg [1:0] current_state, next_state;
    reg [7:0] block_idx; 
    reg [127:0] aes_input;
   wire [127:0] xor_result;
    wire [127:0] aes_output;
    wire aes_done;
    reg [127:0] iv_reg;
    reg start_aes;
    //integer block_counter;
    wire ready_core;
    reg [4:0] delay_counter; 
    
    aes_core aes_core (
    
        .encdec(encdec),
        .init(init_core),
        //.next(next),
        .keylen(keylen),
        
        .clk(clk),
        .reset_n(reset_n),
        .next(start_aes),
        .ready(ready_core),
        .key(key),
        .block(aes_input),
        .result(aes_output),
        .result_valid(aes_done)
    );
assign xor_result = (block_idx == 0)? (iv ^ plaintext) : (iv_reg ^ plaintext);
  
    
 assign xor_result = (block_idx == 0)? (iv ^ plaintext) : (iv_reg ^ plaintext);
     
 always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= IDLE;
            done <= 0;
            block_idx <= 0;
            iv_reg <= iv;
            start_aes <= 0;
            delay_counter <= 0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD;
                end else begin
                    next_state = IDLE;
                end
            end
            LOAD: begin
                next_state = DELAY;
            end
            DELAY: begin
                if (delay_counter == 5'd17) begin
                    next_state = ENC;
                end else begin
                    next_state = DELAY;
                end
            end
            ENC: begin
                if (aes_done) begin
                    if (block_idx == n-1) begin
                        next_state = DONE;
                    end else begin
                        next_state = LOAD;
                    end
                end else begin
                    next_state = ENC;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            aes_input <= 0;
           // xor_result <= 0;
            delay_counter <= 0;
            
        end else begin
            case (current_state)
                LOAD: begin
                    //if (block_idx == 0) begin
                        //xor_result <= iv ^ plaintext[block_idx];
                    //end else begin
                        //xor_result <= iv_reg ^ plaintext[block_idx];
                    //end
                    aes_input <= xor_result;
                    delay_counter <= 0; // Reset delay counter for next delay period
                    start_aes <= 0; 
                end
                DELAY: begin
                    if (delay_counter < 5'd17) begin
                        delay_counter <= delay_counter + 1;
                    end else begin
                        start_aes <= 1; // Start AES after 10 clock cycles delay
                    end
                        aes_input <= xor_result;
               
                end
                ENC: begin
                    if (aes_done) begin
                        ciphertext[block_idx] <= aes_output;
                        iv_reg <= aes_output;
                        //block_idx <= block_idx + 1;
                        start_aes <= 0;
                        delay_counter <= 0; // Reset delay counter for next block
                        if (block_idx == n-1) begin
                            done <= 1;
                        end
                    end
                end
                DONE: begin
                    done <= 0;
                end
            endcase
            
        end
    end


     always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            block_idx <= 0;
            end
        else if(aes_done ==1) begin
            block_idx <= block_idx + 1;
        end else begin
            block_idx <= block_idx;
        end
    end

endmodule

*/

/* always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= IDLE;
            done <= 0;
            ciphertext <= 0;
            iv_reg <= iv;
            start_aes <= 0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD;
                end else begin
                    next_state = IDLE;
                end
            end
            LOAD: begin
                next_state = DELAY;
            end
                        DELAY: begin
                if (delay_counter == 5'd17) begin
                    next_state = ENC;
                end else begin
                    next_state = DELAY;
                end
            end
            ENC: begin
                if (aes_done) begin
                    next_state = DONE;
                end else begin
                    next_state = ENC;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge reset_n) begin
        if (reset_n) begin
            aes_input <= 0;
            //xor_result <= 0;
        end else if (current_state == LOAD) begin
            //xor_result <= iv_reg ^ plaintext;
            aes_input <= xor_result;
            start_aes <= 0;
         end else if (current_state == LOAD) begin
            if (delay_counter < 5'd17) begin
                        delay_counter <= delay_counter + 1;
                    end else begin
                        start_aes <= 1; // Start AES after 10 clock cycles delay
                    end
                        aes_input <= xor_result;
            
        end else if (current_state == ENC && aes_done) begin
            ciphertext <= aes_output;
            iv_reg <= aes_output;
            block_idx <= block_idx + 1;
          
            start_aes <= 0;
            if (block_idx == n-1) begin
                done <= 1;
            end
        end else if (current_state == DONE) begin
            done <= 0;
        end
    end

endmodule */


  




module aes_cbc (


    input wire            encdec,
    input wire            init,
    input wire            keylen,
    input wire clk,
    input wire reset_n,
    input wire next,
    //input wire [127:0] iv, // Initialization Vector
    input wire [255:0] key, // 256-bit Key
    input wire [127:0] plaintext, // Single plaintext block
    output reg [127:0] ciphertext, // Single ciphertext block
    output wire done
);
  
wire ready_core;
wire [127:0] xor_result;
wire [127:0]result;
wire done_reg;
wire [127:0] iv = 128'h000102030405060708090a0b0c0d0e0f;
    aes_core aes_core (
    
        .encdec(encdec),
        .init( init),
        .keylen(keylen),       
        .clk(clk),
        .reset_n(reset_n),
        .next(next),
        .ready(ready_core),
        .key(key),
        .block(xor_result),
        .result(result),
        .result_valid(done_reg)
    );
assign  xor_result = iv ^ plaintext;
assign done = done_reg;
  
  always @ (posedge clk or negedge reset_n)
    begin: regult_done
      if (!reset_n)
        begin
          ciphertext  <= 1'b0;
          //done <= 1'b0;
        end
      else
        begin
             ciphertext  <= result;
             //done <=done;
          end       
        end
endmodule







