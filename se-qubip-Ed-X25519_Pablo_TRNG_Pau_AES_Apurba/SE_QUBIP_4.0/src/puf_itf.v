// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 21/06/2024
// Design Name: puf_itf.v
// Module Name: puf_itf
// Project Name: PUF
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Verilog code for top level PUF design
//
////////////////////////////////////////////////////////////////////////////////////


module puf_itf #(
                  localparam WIDTH      = 64,
                  localparam IN_REG     = 1,
                  localparam OUT_REG    = 2,
                  localparam Bpc        = 4, 	   	
                  localparam Mnc        = 4096	   	
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
    
    assign rst      = control[0] | !i_rst;
    assign rst_itf  = control[1] | !i_rst;
    assign load     = control[2];
    assign read     = control[3];
    
    //-- Sipo Input
    wire [IN_REG*WIDTH-1:0] data_puf_in;
    //-- Piso input
    wire [OUT_REG*WIDTH-1:0] data_puf_out;
    
    //-- PUF Inputs    
    wire puf_str;
    wire BG;																	 
    wire SD;																					 
    wire [1:0] cnfa;   
    wire [$clog2(Mnc): 0] n_cmps;
    wire [$clog2((Mnc*Bpc)/WIDTH-1):0] puf_addr;

    assign puf_str   = data_puf_in[0];
    assign BG        = data_puf_in[1];
    assign SD        = data_puf_in[2];
    assign cnfa      = data_puf_in[4:3];
    assign n_cmps    = data_puf_in[17:5];
    assign puf_addr  = data_puf_in[25:18];
    
    //-- puf Outputs
    wire [$clog2(Mnc*Bpc/WIDTH) : 0] puf_addw;	            
    wire puf_end;									                
    wire [WIDTH-1:0] puf_out;				            
    
	assign data_puf_out = {55'b0, puf_addw, puf_out};
    
    
    //--------------------------------------
	//-- SIPO          
	//--------------------------------------
    
    sipo #(.R_DATA_WIDTH(WIDTH), .N_REG(IN_REG)) SIPO (
	                                                   .clk(clk),
	                                                   .rst(rst_itf),
	                                                   .load(load),
						                               .addr(address),
						                               .din(data_in),
						                               .dout(data_puf_in)
						                               ); 
                                                      

    //--------------------------------------
	//-- PUF TRNG                           
	//--------------------------------------
    
    PUF puf(
			.clock(clk),
			.reset(rst),
			.puf_str(puf_str),
			.BG(BG),
			.SD(SD),
			.cnfa(cnfa),
			.n_cmps(n_cmps),
			.puf_addr(puf_addr),
			.puf_addw(puf_addw),
			.puf_end(puf_end),
			.puf_out(puf_out)
			);  
    
    
    //--------------------------------------
	//-- PISO              
	//--------------------------------------
    
    piso #(.R_DATA_WIDTH(WIDTH), .N_REG(OUT_REG)) PISO(
						                               .clk(clk),
						                               .read(read),
						                               .addr(address),
						                               .din(data_puf_out),
						                               .dout(data_out)
						                               );
    
    
    assign end_op = puf_end;
   

endmodule
