`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2024 11:47:06
// Design Name: 
// Module Name: SE_QUBIP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SE_QUBIP #(
    parameter IMP_SHA3      = 1,
    parameter IMP_SHA2      = 1,
    parameter IMP_EDDSA     = 1,
    parameter IMP_X25519    = 1,
    parameter IMP_TRNG      = 1,
    parameter IMP_AES      = 1
    )(
    input  wire i_clk,
    input  wire i_rst,
    input  wire [63:0] i_data_in,
    input  wire [63:0] i_add,
    input  wire [63:0] i_control,
    output wire [63:0] o_data_out,
    output wire o_end_op
    );
    
    // --- ADDRESS Definition --- //
    localparam ADDRESS_SHA2     = 32'h0000_0020;
    localparam ADDRESS_SHA3     = 32'h0000_0030;
    localparam ADDRESS_EDDSA    = 32'h0000_0040;
    localparam ADDRESS_X25519   = 32'h0000_0050;
    localparam ADDRESS_TRNG     = 32'h0000_0060;
    localparam ADDRESS_AES      = 32'h0000_0070;
    
    // --- Signal Definition --- //
    // ------------------------- //
    wire [31:0] address_module;
    wire [31:0] control_module;
    assign address_module = i_control[63:32];
    assign control_module = i_control[31:00];
    
    // ------------------------- //
    wire sel_sha2;
    wire sel_sha3;
    wire sel_eddsa;
    wire sel_x25519;
    wire sel_trng;
    wire sel_aes;
    
    assign sel_sha2     = (address_module == ADDRESS_SHA2)      ? 1 : 0;
    assign sel_sha3     = (address_module == ADDRESS_SHA3)      ? 1 : 0;
    assign sel_eddsa    = (address_module == ADDRESS_EDDSA)     ? 1 : 0;
    assign sel_x25519   = (address_module == ADDRESS_X25519)    ? 1 : 0;
    assign sel_trng     = (address_module == ADDRESS_TRNG)      ? 1 : 0;
    assign sel_aes     = (address_module == ADDRESS_AES)      ? 1 : 0;
    
    // ------------------------- //
    wire [63:0] o_data_out_sha2;
    wire [63:0] o_data_out_sha3;
    wire [63:0] o_data_out_eddsa;
    wire [63:0] o_data_out_x25519;
    wire [63:0] o_data_out_trng;
    wire [63:0] o_data_out_aes;
    reg  [63:0] o_data_out_reg;
    
    always @* begin
                if(sel_sha2)    o_data_out_reg = o_data_out_sha2;
        else    if(sel_sha3)    o_data_out_reg = o_data_out_sha3;
        else    if(sel_eddsa)   o_data_out_reg = o_data_out_eddsa;
        else    if(sel_x25519)  o_data_out_reg = o_data_out_x25519;
        else    if(sel_trng)    o_data_out_reg = o_data_out_trng;
        else    if(sel_aes)     o_data_out_reg = o_data_out_aes;
        else                    o_data_out_reg = 64'hFFFF_FFFF_FFFF_FFFF;
    end
    
    assign o_data_out = o_data_out_reg;
    
    // ------------------------- //
    wire o_end_op_sha2;
    wire o_end_op_sha3;
    wire o_end_op_eddsa;
    wire o_end_op_x25519;
    wire o_end_op_trng;
    wire o_end_op_aes;
    reg  o_end_op_reg;
    
    always @* begin
                if(sel_sha2)    o_end_op_reg = o_end_op_sha2;
        else    if(sel_sha3)    o_end_op_reg = o_end_op_sha3;
        else    if(sel_eddsa)   o_end_op_reg = o_end_op_eddsa;
        else    if(sel_x25519)  o_end_op_reg = o_end_op_x25519;
        else    if(sel_trng)    o_end_op_reg = o_end_op_trng;
        else    if(sel_aes)     o_end_op_reg = o_end_op_aes;
        else                    o_end_op_reg = 1'b1;
    end
    
    assign o_end_op = o_end_op_reg;
    
    // --- SHA3 DEFINITION --- //
    generate 
        if(IMP_SHA3) begin
        
            sha3_compact_xl
            sha3_compact_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_sha3),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_sha3),
                .o_end_op(o_end_op_sha3)
            );
            
        end
        else begin
            dummy_module
            sha3_compact_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_sha3),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_sha3),
                .o_end_op(o_end_op_sha3)
            );
        
        end
        
    endgenerate
    
    // --- SHA2 DEFINITION --- //
    generate 
        if(IMP_SHA2) begin
        
            sha2_xl
            sha2_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_sha2),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_sha2),
                .o_end_op(o_end_op_sha2)
            );
            
        end
        else begin
            dummy_module
            sha2_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_sha2),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_sha2),
                .o_end_op(o_end_op_sha2)
            );
        
        end
        
    endgenerate
    
    // --- EDDSA25519 DEFINITION --- //
    generate 
        if(IMP_EDDSA) begin
        
            EdDSA_itf
            eddsa_xl
            (
                .clk(i_clk),
                .i_rst(i_rst & sel_eddsa),
                .data_in(i_data_in),
                .address(i_add),
                .control(control_module[3:0]),
                .data_out(o_data_out_eddsa),
                .end_op(o_end_op_eddsa)
            );
            
        end
        else begin
            dummy_module
            eddsa_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_eddsa),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_eddsa),
                .o_end_op(o_end_op_eddsa)
            );
        
        end
        
    endgenerate
        
    // --- X25519 DEFINITION --- //
    generate 
        if(IMP_X25519) begin
        
            X25519_itf
            x25519_xl
            (
                .clk(i_clk),
                .i_rst(i_rst & sel_x25519),
                .data_in(i_data_in),
                .address(i_add),
                .control(control_module[3:0]),
                .data_out(o_data_out_x25519),
                .end_op(o_end_op_x25519)
            );
            
        end
        else begin
            dummy_module
            x25519_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_x25519),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_x25519),
                .o_end_op(o_end_op_x25519)
            );
        
        end
        
    endgenerate
    
     // --- PUF DEFINITION --- //
    generate 
        if(IMP_TRNG) begin
        
            puf_itf
            trng_xl
            (
                .clk(i_clk),
                .i_rst(i_rst & sel_trng),
                .data_in(i_data_in),
                .address(i_add),
                .control(control_module[3:0]),
                .data_out(o_data_out_trng),
                .end_op(o_end_op_trng)
            );
            
        end
        else begin
            dummy_module
            puf_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_trng),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_trng),
                .o_end_op(o_end_op_trng)
            );
        
        end
        
    endgenerate


 generate 
        if(IMP_AES) begin
        
            aes_itf
            aes_xl
            (
                .clk(i_clk),
                .i_rst(i_rst & sel_aes),
                .data_in(i_data_in),
                .address(i_add),
                .control(control_module[3:0]),
                .data_out(o_data_out_aes),
                .end_op(o_end_op_aes)
            );
            
        end
        else begin
            dummy_module
            aes_xl
            (
                .i_clk(i_clk),
                .i_rst(i_rst & sel_aes),
                .i_data_in(i_data_in),
                .i_add(i_add),
                .i_control(control_module),
                .o_data_out(o_data_out_aes),
                .o_end_op(o_end_op_aes)
            );
        
        end
        
    endgenerate

endmodule
