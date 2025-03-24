`timescale 1ns / 1ps

module TOP_MLKEM #(
    parameter COUNTERMEASURES = 0
    )(
    input           clk,
    input           rst,
    input   [7:0]   control,
    input   [63:0]  data_in,
    input   [15:0]  add,
    output  [63:0]  data_out,
    output  [1:0]   end_op
    );
    
    wire [7:0]   control_core;
    wire [15:0]  data_in_core;
    wire [15:0]  add_core;
    wire [15:0]  data_out_core;
    wire [1:0]   end_op_core;
    
    wire [7:0]   control_core_input;
    wire [7:0]   control_core_output;
    wire [15:0]  add_core_input;
    wire [15:0]  add_core_output;
    
    wire end_op_out;
    
    assign control_core = (end_op_core[0]) ? control_core_output : control_core_input;
    assign add_core     = (end_op_core[0]) ? add_core_output : add_core_input;
    
    CORE_MLKEM #(
    .COUNTERMEASURES(COUNTERMEASURES)
    ) CORE_MLKEM (
        .clk(clk),
        .rst(rst),
        .fixed(),
        .control(control_core),
        .data_in(data_in_core),
        .add(add_core),
        .data_out(data_out_core),
        .end_op(end_op_core)
    );
   
    // --- INPUT MODULE --- //
    INPUT_MODULE INPUT_MODULE (
        .clk(clk),
        .rst(rst),
        .control(control),
        .control_core(control_core_input),
        .data_in(data_in),
        .add(add),
        .data_in_core(data_in_core),
        .add_in(add_core_input)
    );
    
    // --- OUTPUT MODULE --- //
    
    OUTPUT_MODULE OUTPUT_MODULE (
        .clk(clk),
        .rst(rst),
        .din(data_out_core),
        .add(add),
        .start(end_op_core[0]),
        .control(control),
        .add_ram(add_core_output),
        .dout(data_out),
        .control_core(control_core_output),
        .end_op(end_op_out)
    );
    
    assign end_op = (end_op_out) ? end_op_core : 2'b00;
    
    
    
endmodule
