`timescale 1ns / 1ps

module poly_ntt_acc #(
    parameter WIDTH = 32
    )(
    input                 clk,
    input                 rst,
    input   [7:0]         control,
    output                end_op,
    input   [7:0]         add,
    input   [WIDTH-1:0]   r_in,
    output  [15:0]        r_out
    );
    
    // ------------- Control signal ---------------------- //
    // < 7 6 5 4        >< 3 2 1 0        >
    // < -- sel[3:0] -- >< -- op <3:0> -- > //  
    
    // | SEL  | bin     | Description    |
    // |------|---------|----------------|
    // | 0    | 4'b0000 | NTT            |
    // | 1    | 4'b0001 | INTT           |
    // | 2    | 4'b0010 | MULT FIRST ACC |
    // | 3    | 4'b0011 | MULT ACC       |
    // | 4    | 4'b0100 | ADD            |     
    // | 5    | 4'b0101 | SUB            |
    // | A    | 4'b1010 | MULT FIRST ACC MR |
    // | B    | 4'b1011 | MULT ACC MR       |
    
    
    // --- Control signals --- //
    wire            reset_ntt;
    wire            load_ntt;
    wire            start_ntt;
    wire            read_ntt;
    wire    [2:0]   sel;
    
    wire            reset_acc;
    wire    [1:0]   mode_acc; // 00 -> NO ACC, 10 -> FIRST ACC, 11 -> ACC
    wire            red_MR;
    
    assign reset_ntt    = !(!control[1] & !control[0]) & rst;   // XX00 -> RESET
    assign load_ntt     = !control[1] &  control[0];            // XX01 -> LOAD_NTT
    assign start_ntt    =  control[1] & !control[0];            // XX10 -> START_NTT
    assign read_ntt     =  control[1] &  control[0];            // XX11 -> READ_NTT
    
    assign reset_acc    = reset_ntt;
    assign sel          = control[7:4]; 
    assign mode_acc     = control[5:4]; 
    assign red_MR       = control[7]; 
    
    // --- Addresses signals --- //
    wire [7:0] ad_in_ntt;
    wire [7:0] ad_out_ntt;
    wire [7:0] ad_ntt;
    wire [7:0] ad_out_acc;
    
    assign ad_in_ntt    = add;
    assign ad_out_ntt   = (mode_acc[1]) ? ad_ntt : add;
    assign ad_out_acc   = add;
    
    // --- Data signals --- //
    wire [WIDTH-1:0]    r_in_ntt;
    wire [15:0]         r_out_ntt;
    wire [15:0]         r_in_acc;
    wire [15:0]         r_out_acc;
    wire [15:0]         r_out_MR;
    
    assign r_in_ntt = r_in;
    assign r_in_acc = r_out_ntt;
    assign r_out = (mode_acc[1]) ? ( (red_MR) ? r_out_MR : r_out_acc ) : r_out_ntt; 
    
    // --- End op signals --- //
    wire end_op_ntt;
    wire end_op_acc;
    
    assign end_op = (mode_acc[1]) ? end_op_acc : end_op_ntt;  
    
    poly_ntt poly_ntt
    (   .clk(clk), .rst(reset_ntt), 
        .load(load_ntt), .start(start_ntt), .read(read_ntt), .end_op(end_op_ntt),
        .ad_in(ad_in_ntt), .ad_out(ad_out_ntt), .r_in(r_in_ntt), .r_out(r_out_ntt), .sel(sel));
        
    acc acc_module
    (   .clk(clk), .rst(reset_acc), .load(load_ntt), .read(read_ntt),
        .end_op_ntt(end_op_ntt), .mode_acc(mode_acc), .end_op(end_op_acc),
        .ad_ntt(ad_ntt), .ad_out(ad_out_acc), .r_in(r_in_acc), .r_out(r_out_acc));
    
    // to mont
    localparam f = 1353;
    wire [31:0] in_MR;
    assign in_MR = {{16{r_out_acc[15]}}, r_out_acc} * f;
    montgomery_reduce MR (.a(in_MR), .t(r_out_MR));
  
endmodule
