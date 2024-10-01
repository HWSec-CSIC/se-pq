`timescale 1ns / 1ps

module AU_CORE(
    input               clk,
    input               rst,
    input    [47:0]     control,
    input    [31:0]     data_in,
    output   [15:0]     data_out,
    input    [15:0]     add,
    output              end_op
    // output   [7:0]      len_rg,
    // output              fail_rej_rg
    );
    
    wire [7:0] control_ntt;
    wire [7:0] control_sha3;
    wire [3:0] x;
    wire [3:0] y;
    wire [7:0] control_enc_dec;
    wire [7:0] state_au;
    
    assign control_ntt      =   control[07:00];
    assign control_sha3     =   control[15:08];
    assign x                =   control[19:16];
    assign y                =   control[23:20];
    assign control_enc_dec  =   control[31:24];
    assign state_au         =   control[47:40]; 

    assign reset_au                             = (state_au[7:4] == 4'h0)   ? 1 : 0;
    assign load_au                              = (state_au[7:4] == 4'h1)   ? 1 : 0;
    assign load_seed                            = (state_au[7:4] == 4'h2)   ? 1 : 0;
    assign start_au                             = (state_au[7:4] == 4'h3)   ? 1 : 0;
    assign read_au                              = (state_au[7:4] == 4'h4)   ? 1 : 0;
    assign reset_sha3                           = (state_au[7:4] == 4'h5)   ? 1 : 0;
    assign gen_random_0                         = (state_au[7:4] == 4'h6)   ? 1 : 0;
    assign gen_random_1                         = (state_au[7:4] == 4'h7)   ? 1 : 0;
    assign gen_random_2                         = (state_au[7:4] == 4'h8)   ? 1 : 0;
    assign end_program                          = (state_au[7:4] == 4'hF)   ? 1 : 0; 
    
    /*
    wire [255:0] seed;
    reg  [15:0] REG_SEED [15:0];
    
    genvar i;
    always @(posedge clk) begin
        if(!rst | reset_au)     REG_SEED[0] <= 0;
        else if(load_seed)      REG_SEED[add[3:0]] <= data_in;
        else                    REG_SEED[0] <= REG_SEED[0];
    end
    generate 
        for(i = 0; i < 16; i = i + 1) begin
            assign seed[(16*(i+1) - 1):(16*i)] = REG_SEED[i];
        end
    endgenerate
    */
    
     // --- NTT + INVNTT + ACC + ADD + SUB --- //
    
    wire  [31:0]          data_in_ntt;
    wire  [15:0]          data_out_ntt;
    wire  [7:0]           add_ntt;
    // wire  [7:0]           control_ntt;
    wire                  end_op_ntt;
   
     poly_ntt_acc poly_ntt_acc
     (  .clk(clk),              .rst(rst & !reset_au), 
        .r_in(data_in_ntt),      .add(add_ntt),
        .r_out(data_out_ntt),    .control(control_ntt),
        .end_op(end_op_ntt)
    );
    /*
    poly_ntt_acc_add_sub poly_ntt_acc_add_sub
     (  .clk(clk),              .rst(rst & !reset_au), 
        .r_in(data_in_ntt),      .add(add_ntt),
        .r_out(),    .control(control_ntt),
        .end_op()
    );
    */
    
    assign data_in_ntt  =   data_in;
    assign add_ntt      =   add[7:0];
    assign control_ntt  =   control[7:0];
    
    // --- SHA3 + XOF + PRF --- //
    
    wire  [15:0]          data_in_sha3;
    wire  [15:0]          data_out_sha3;
    wire  [7:0]           add_sha3;
    // wire  [7:0]           control_sha3;
    wire                  end_op_sha3;
    
    // wire [7:0]             x;
    // wire [7:0]             y;
    // assign x = control[19:16];
    // assign y = control[23:20];
   
     XOF_PRF_SHA3 XOF_PRF_SHA3
     (  .clk(clk),              .rst(rst & !reset_au), 
        .load_seed(load_seed),  .x(x), .y(y),  
        .data_in(data_in_sha3),      .add(add_sha3),
        .data_out(data_out_sha3),    .control(control_sha3),
        .end_op(end_op_sha3)
    );
    
    assign data_in_sha3  =   data_in;
    assign add_sha3      =   add[7:0];
    
    // BYTE ENCODE + DECODE //
    
    wire  [15:0]          data_in_enc_dec;
    wire  [15:0]          data_out_enc_dec;
    wire  [15:0]          add_enc_dec;
    // wire  [7:0]           control_enc_dec;
    wire                  end_op_enc_dec;
   
     ByteEncDec ByteEncDec
     (  .clk(clk),              .rst(rst & !reset_au), 
        .data_in(data_in_enc_dec),      .add(add_enc_dec),
        .data_out(data_out_enc_dec),    .control(control_enc_dec),
        .end_op(end_op_enc_dec)
    );
    
    assign data_in_enc_dec  =   data_in;
    assign add_enc_dec      =   add;
    
    // --- * GEN RANDOM * --- //
     
     wire   [15:0] rand_value;
     reg    [15:0] rand_value_reg;
     
     random_gen RND (.clk(clk), .rst(rst), .rand(rand_value));
     
     assign gen_random = gen_random_0 | gen_random_1;
     
     always @(posedge clk) begin
        if (!rst | reset_au)    rand_value_reg <= 0;
        else begin
            if(gen_random)          rand_value_reg <= rand_value;
            else if(gen_random_2)   rand_value_reg <= rand_value & 16'h00FF;
            else                    rand_value_reg <= rand_value_reg; 
        end 
     end
    
    
    // --- Common outputs --- //
    wire sel_ntt;
    assign sel_ntt      = (control_ntt      == 8'h00) ? 0 : 1;
    wire sel_sha3;
    assign sel_sha3     = (control_sha3     == 8'h00) ? 0 : 1;
    wire sel_enc_dec;
    assign sel_enc_dec   = (control_enc_dec == 8'h00) ? 0 : 1;
    
    reg [15:0] data_out_reg;
    always @* begin
                if(sel_ntt)         data_out_reg = data_out_ntt;
        else    if(sel_sha3)        data_out_reg = data_out_sha3;
        else    if(sel_enc_dec)     data_out_reg = data_out_enc_dec;
        else                        data_out_reg = rand_value_reg;
    end
    assign data_out     =   data_out_reg;
    
    
    reg end_op_reg;
    always @* begin
                if(sel_ntt)         end_op_reg = end_op_ntt;
        else    if(sel_sha3)        end_op_reg = end_op_sha3;
        else    if(sel_enc_dec)     end_op_reg = end_op_enc_dec;
        else                        end_op_reg = 1;
    end
    assign end_op     =   end_op_reg;
    
   
      
endmodule
