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
    parameter IMP_SHA3 = 1,
    parameter IMP_SHA2 = 1
    )(
    input                           i_clk,
    input                           i_rst,
    input   [63:0]                  i_data_in,
    input   [63:0]                  i_add,
    input   [63:0]                  i_control,
    output  [63:0]                  o_data_out,
    output                          o_end_op
    );
    
    // --- ADDRESS Definition --- //
    localparam ADDRESS_SHA2 = 32'h0000_0020;
    localparam ADDRESS_SHA3 = 32'h0000_0030;
    
    // --- Signal Definition --- //
    // ------------------------- //
    wire [31:0] address_module;
    wire [31:0] control_module;
    assign address_module = i_control[63:32];
    assign control_module = i_control[31:00];
    
    // ------------------------- //
    wire sel_sha2;
    wire sel_sha3;
    assign sel_sha2 = (address_module == ADDRESS_SHA2) ? 1 : 0;
    assign sel_sha3 = (address_module == ADDRESS_SHA3) ? 1 : 0;
    
    // ------------------------- //
    wire [63:0] o_data_out_sha2;
    wire [63:0] o_data_out_sha3;
    reg  [63:0] o_data_out_reg;
    
    always @* begin
                if(sel_sha2)    o_data_out_reg = o_data_out_sha2;
        else    if(sel_sha3)    o_data_out_reg = o_data_out_sha3;
        else                    o_data_out_reg = 64'hFFFF_FFFF_FFFF_FFFF;
    end
    
    assign o_data_out = o_data_out_reg;
    
    // ------------------------- //
    wire o_end_op_sha2;
    wire o_end_op_sha3;
    reg  o_end_op_reg;
    
    always @* begin
                if(sel_sha2)    o_end_op_reg = o_end_op_sha2;
        else    if(sel_sha3)    o_end_op_reg = o_end_op_sha3;
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

endmodule
