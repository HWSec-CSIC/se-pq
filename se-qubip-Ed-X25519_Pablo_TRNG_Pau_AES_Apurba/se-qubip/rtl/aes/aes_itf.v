// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Apurba Karmakar
// 
// Create Date: 26/08/2024
// Design Name: aes_itf.v
// Module Name: aes_itf
// Project Name: AES_ECB_CBC Accelerator
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Verilog code for top level AES_ECB_CBC design
//
////////////////////////////////////////////////////////////////////////////////////


module aes_itf #(
                  localparam BIT_LENGTH = 256,
                  localparam WIDTH      = 64,
                  localparam SIZE_BLOCK = 128,
                  localparam IN_REG     = 9,
                  localparam OUT_REG    = 3
                  )
                  (
                   input  wire clk,                                    //-- Clock Signal
                   input  wire i_rst,                                  //-- Reset Signal 
                   input  wire [3:0] control,                          //-- Control Signal: {read, load, rst_itf, rst} 
                   input  wire [WIDTH-1:0] address,                    //-- Address
                   input  wire [WIDTH-1:0] data_in,                    //-- Data Input
                   output wire [WIDTH-1:0] data_out,                   //-- Data Output
                   output wire end_op                                  //-- End Operation Signal
                   );

    
    //--------------------------------------
	//-- Wires & Registers
	//--------------------------------------
    
    //-- Control Signals
    wire rst;
    wire rst_itf;
    wire load;
    wire read;
    
    assign rst      = control[0] & i_rst;
    assign rst_itf  = control[1] | !i_rst;
    assign load     = control[2];
    assign read     = control[3];
    
    //-- Sipo Input
    wire [IN_REG*WIDTH-1:0] data_aes_in;
    //-- Piso input
    wire [OUT_REG*WIDTH-1:0] data_aes_out; //data_aes_out[191:0]
    
    //-- AES Inputs
	wire  ecb_cbc;
	wire  encdec;
	wire  keylen;
	wire  init;
	wire  next;
	
	
	
	wire [BIT_LENGTH-1:0] key;
	
	wire [SIZE_BLOCK-1:0] block;
	wire [SIZE_BLOCK-1:0] iv;	
	

    
    assign ecb_cbc  	= data_aes_in[0];
    assign encdec       = data_aes_in[1];
    assign keylen       = data_aes_in[2];
    assign init       	= data_aes_in[3];
    assign next       	= data_aes_in[4];			//4:0 is used out of 63:0 of data_aes_in
    
    assign key      	= data_aes_in[BIT_LENGTH+WIDTH-1:WIDTH];   //data_aes_in [319:64]
    
    assign iv       	= data_aes_in[SIZE_BLOCK+BIT_LENGTH+WIDTH-1:BIT_LENGTH+WIDTH];	//data_aes_in [447:320]
    
    assign block      = data_aes_in[2*SIZE_BLOCK+BIT_LENGTH+WIDTH-1:SIZE_BLOCK+BIT_LENGTH+WIDTH];	// data_aes_in [575:448]

    
    //-- AES Outputs
    
	wire [SIZE_BLOCK-1:0] result;
	wire result_valid;
	wire ready;
	
	
	assign data_aes_out = {result, 62'b0, ready, result_valid};
    
    
    //--------------------------------------
	//-- SIPO          
	//--------------------------------------
    
    sipo #(.R_DATA_WIDTH(WIDTH), .N_REG(IN_REG)) SIPO (
	                                                   .clk(clk),
	                                                   .rst(rst_itf),
	                                                   .load(load),
						                               .addr(address),
						                               .din(data_in),
						                               .dout(data_aes_in)
						                               ); 
                                                      

    //--------------------------------------
	//-- AES Cryptocore                           
	//--------------------------------------
    
    aes_core aes_core(
			    //input control signals
			    .clk(clk),
			    .reset_n(rst),
			    .ecb_cbc(ecb_cbc),
			    .encdec(encdec),
			    .init(init),
			    .next(next),
			    .keylen(keylen),
			    
			    //inputs
			    .key(key),
			    .iv(iv),
			    .block(block),
			    
			      //outputs
			    .ready(ready),
			    .result_valid(result_valid),
			    .result(result)
			    );  
    
        
    
    //--------------------------------------
	//-- PISO              
	//--------------------------------------
    
    piso #(.R_DATA_WIDTH(WIDTH), .N_REG(OUT_REG)) PISO(
						                               .clk(clk),
						                               .read(read),
						                               .addr(address),
						                               .din(data_aes_out),
						                               .dout(data_out)
						                               );
    
    
    assign end_op = result_valid;
    


endmodule

