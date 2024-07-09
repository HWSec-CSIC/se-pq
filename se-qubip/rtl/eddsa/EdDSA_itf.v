`default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 21/06/2024
// Design Name: EdDSA_itf.v
// Module Name: EdDSA_itf
// Project Name: RSA Accelerator
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Verilog code for top level EdDSA25519 design
//
////////////////////////////////////////////////////////////////////////////////////


module EdDSA_itf #(
                  localparam BIT_LENGTH = 256,
                  localparam WIDTH      = 64,
                  localparam SIZE_BLOCK = 1024,
                  localparam IN_REG     = 34,
                  localparam OUT_REG    = 9
                  )
                  (
                   input  wire clk,                                    //-- Clock Signal
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
    
    assign rst      = control[0];
    assign rst_itf  = control[1];
    assign load     = control[2];
    assign read     = control[3];
    
    //-- Sipo Input
    wire [IN_REG*WIDTH-1:0] data_eddsa_in;
    //-- Piso input
    wire [OUT_REG*WIDTH-1:0] data_eddsa_out;
    
    //-- EdDSA Inputs
	wire [1:0] block_valid;
	wire [1:0] sel;
	wire [BIT_LENGTH-1:0] private;
	wire [BIT_LENGTH-1:0] public;
	wire [SIZE_BLOCK-1:0] message;
	wire [WIDTH-1:0] len_message;
	wire [2*BIT_LENGTH-1:0] sig_ver;
    
    assign block_valid  = data_eddsa_in[1:0];
    assign sel          = data_eddsa_in[3:2];
    assign private      = data_eddsa_in[BIT_LENGTH+WIDTH-1:WIDTH];
    assign public       = data_eddsa_in[2*BIT_LENGTH+WIDTH-1:BIT_LENGTH+WIDTH];
    assign message      = data_eddsa_in[SIZE_BLOCK+2*BIT_LENGTH+WIDTH-1:2*BIT_LENGTH+WIDTH];
    assign len_message  = data_eddsa_in[SIZE_BLOCK+2*BIT_LENGTH+2*WIDTH-1:SIZE_BLOCK+2*BIT_LENGTH+WIDTH];
    assign sig_ver      = data_eddsa_in[SIZE_BLOCK+4*BIT_LENGTH+2*WIDTH-1:SIZE_BLOCK+2*BIT_LENGTH+2*WIDTH];
    
    //-- EdDSA Outputs
	wire [2*BIT_LENGTH-1:0] sig_pub;
	wire valid;
	wire error;
	wire block_ready;
	
	assign data_eddsa_out = {sig_pub, 61'b0, block_ready, error, valid};
    
    
    //--------------------------------------
	//-- SIPO          
	//--------------------------------------
    
    sipo #(.R_DATA_WIDTH(WIDTH), .N_REG(IN_REG)) SIPO (
	                                                   .clk(clk),
	                                                   .rst(rst_itf),
	                                                   .load(load),
						                               .addr(address),
						                               .din(data_in),
						                               .dout(data_eddsa_in)
						                               ); 
                                                      

    //--------------------------------------
	//-- EdDSA25519 Cryptocore                           
	//--------------------------------------
    
    EdDSA EdDSA(
			    .clk(clk),
			    .rst(rst),
			    .block_valid(block_valid),
			    .sel(sel),
			    .private(private),
			    .public(public),
			    .message(message),
			    .len_message(len_message),
			    .sig_ver(sig_ver),
			    .sig_pub(sig_pub),
			    .valid(valid),
			    .error(error),
			    .block_ready(block_ready)
			    );  
    
    
    //--------------------------------------
	//-- PISO              
	//--------------------------------------
    
    piso #(.R_DATA_WIDTH(WIDTH), .N_REG(OUT_REG)) PISO(
						                               .clk(clk),
						                               .read(read),
						                               .addr(address),
						                               .din(data_eddsa_out),
						                               .dout(data_out)
						                               );
    
    
    assign end_op = valid;
    


endmodule
