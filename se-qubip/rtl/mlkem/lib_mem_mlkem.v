`timescale 1ns / 1ps

module RAM  # 
  (
    parameter SIZE = 64,
    parameter WIDTH = 32
  )( 
    input clk,
    input en_write,
    input en_read,
    input [clog2(SIZE-1)-1:0] addr_write,
    input [clog2(SIZE-1)-1:0] addr_read,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
  );

 
	reg [WIDTH-1:0] Mem [SIZE-1:0];
	reg [WIDTH-1:0] out_reg;

 	always @(posedge clk) 
	begin
        if(en_write)  Mem[addr_write] <= data_in;
	end
	
	always @(posedge clk) 
	begin
		if(en_read)   out_reg <= Mem[addr_read];
	end
	
    assign data_out = out_reg;
    
    genvar i;
        generate 
         for(i = 0; i < SIZE; i = i+1) begin
            initial Mem[i] = 0;
         end
        endgenerate
    
    
	
  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule

module RAM_dual_write  # 
  (
    parameter integer SIZE = 51200 / 32,
    parameter WIDTH = 32
  )( 
    input clk,
    input enable_1,
    input enable_2,
    input [clog2(SIZE-1)-1:0] addr_1,
    input [clog2(SIZE-1)-1:0] addr_2,
    input [WIDTH-1:0] data_in_1,
    input [WIDTH-1:0] data_in_2,
    output [WIDTH-1:0] data_out_1,
    output [WIDTH-1:0] data_out_2
  );
      
	reg [WIDTH-1:0] Mem [SIZE-1:0];
	reg [WIDTH-1:0] out_reg_1;
	reg [WIDTH-1:0] out_reg_2;
	
 	always @(posedge clk) 
	begin
        if(enable_1) Mem[addr_1] <= data_in_1;
        out_reg_1 <= Mem[addr_1];
	end
    assign data_out_1 = out_reg_1 ;
    
    always @(posedge clk) 
	begin
        if(enable_2) Mem[addr_2] <= data_in_2;
        out_reg_2 <= Mem[addr_2];
	end
    assign data_out_2 = out_reg_2 ;
    
    genvar i;
        generate 
         for(i = 0; i < SIZE; i = i+1) begin
            initial Mem[i] = 0;
         end
        endgenerate

  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction
    
    function integer ceiling;
        input integer n;
        ceiling = n;
    endfunction

endmodule

module ROM_ADD 
#(parameter DATA_WIDTH=64, parameter ADDR_WIDTH=10)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output [(DATA_WIDTH-1):0] q
);
    
    reg [(DATA_WIDTH-1):0] q_reg;
    
	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom [0:2**ADDR_WIDTH-1];
 
	initial
	begin
		$readmemb("ROM_ADD.mem", rom);
	end
 
	always @ (posedge clk)
	begin
		q_reg <= rom[addr];
	end
	
	assign q = q_reg;
 
endmodule

module PROGRAM_ROM  #(
parameter DATA_WIDTH=80, 
parameter ADDR_WIDTH=10,
parameter K = 2,
parameter GEN = 0,
parameter ENC = 0,
parameter DEC = 0)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output [(DATA_WIDTH-1):0] q
);
    
    reg [(DATA_WIDTH-1):0] q_reg;
    
	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom [0:2**ADDR_WIDTH-1];
 
    generate
        if(K == 2) begin
                    if(GEN == 1 & ENC == 0 & DEC == 0) initial begin $readmemh("PROGRAM_ROM_GEN_K_2.mem", rom); end 
            else    if(GEN == 0 & ENC == 1 & DEC == 0) initial begin $readmemh("PROGRAM_ROM_ENC_K_2.mem", rom); end 
            else    if(GEN == 0 & ENC == 0 & DEC == 1) initial begin $readmemh("PROGRAM_ROM_DEC_K_2.mem", rom); end 
            else                                       initial begin $readmemh("PROGRAM_ROM_GEN_K_2.mem", rom); end
        end
        else if(K == 3) begin
                    if(GEN == 1 & ENC == 0 & DEC == 0) initial begin $readmemh("PROGRAM_ROM_GEN_K_3.mem", rom); end 
            else    if(GEN == 0 & ENC == 1 & DEC == 0) initial begin $readmemh("PROGRAM_ROM_ENC_K_3.mem", rom); end 
            else    if(GEN == 0 & ENC == 0 & DEC == 1) initial begin $readmemh("PROGRAM_ROM_DEC_K_3.mem", rom); end 
            else                                       initial begin $readmemh("PROGRAM_ROM_GEN_K_3.mem", rom); end
        end
        else if(K == 4) begin
                    if(GEN == 1 & ENC == 0 & DEC == 0) initial begin $readmemh("PROGRAM_ROM_GEN_K_4.mem", rom); end 
            else    if(GEN == 0 & ENC == 1 & DEC == 0) initial begin $readmemh("PROGRAM_ROM_ENC_K_4.mem", rom); end 
            else    if(GEN == 0 & ENC == 0 & DEC == 1) initial begin $readmemh("PROGRAM_ROM_DEC_K_4.mem", rom); end 
            else                                       initial begin $readmemh("PROGRAM_ROM_GEN_K_4.mem", rom); end
        end
	endgenerate
 
	always @ (posedge clk)
	begin
		q_reg <= rom[addr];
	end
	
	assign q = q_reg;
 
endmodule