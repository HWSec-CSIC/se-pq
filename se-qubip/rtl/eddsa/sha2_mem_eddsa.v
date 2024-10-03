/**
  * @file sha2_mem_eddsa.v
  * @brief RAM Memory Module
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/

module mem_RAM_eddsa  # 
  (
    parameter SIZE = 64,
    parameter WIDTH = 32
  )( 
    input wire clk,
    input wire en_write,
    input wire en_read,
    input wire [clog2(SIZE-1)-1:0] addr_write,
    input wire [clog2(SIZE-1)-1:0] addr_read,
    input wire [WIDTH-1:0] data_in,
    output wire  [WIDTH-1:0] data_out
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
/*
module mem_ROM_k  # 
  (
    parameter SIZE = 64,
    parameter WIDTH = 32
  )( 
    input clk,
    input enable,
    input [clog2(SIZE-1)-1:0] addr,
    output [WIDTH-1:0] data
  );

	(*rom_style = "block" *) reg [WIDTH-1:0] Mem;
	
	assign data = Mem;
	
	always @(posedge clk) begin
        if(enable)
            case(addr) 
              6'b000000: Mem <= 32'h428a2f98 ; // 0
		      6'b000001: Mem <= 32'h71374491 ; 
		      6'b000010: Mem <= 32'hb5c0fbcf ;
		      6'b000011: Mem <= 32'he9b5dba5 ;
		      6'b000100: Mem <= 32'h3956c25b ;
		      6'b000101: Mem <= 32'h59f111f1 ;
		      6'b000110: Mem <= 32'h923f82a4 ;
		      6'b000111: Mem <= 32'hab1c5ed5 ; // 7
		      6'b001000: Mem <= 32'hd807aa98 ;
		      6'b001001: Mem <= 32'h12835b01 ;
		      6'b001010: Mem <= 32'h243185be ;
		      6'b001011: Mem <= 32'h550c7dc3 ;
		      6'b001100: Mem <= 32'h72be5d74 ;
		      6'b001101: Mem <= 32'h80deb1fe ;
		      6'b001110: Mem <= 32'h9bdc06a7 ;
		      6'b001111: Mem <= 32'hc19bf174 ; // 15
              6'b010000: Mem <= 32'he49b69c1 ;
		      6'b010001: Mem <= 32'hefbe4786 ;
		      6'b010010: Mem <= 32'h0fc19dc6 ;
		      6'b010011: Mem <= 32'h240ca1cc ;
		      6'b010100: Mem <= 32'h2de92c6f ;
		      6'b010101: Mem <= 32'h4a7484aa ;
		      6'b010110: Mem <= 32'h5cb0a9dc ;
		      6'b010111: Mem <= 32'h76f988da ;
		      6'b011000: Mem <= 32'h983e5152 ;
		      6'b011001: Mem <= 32'ha831c66d ;
		      6'b011010: Mem <= 32'hb00327c8 ;
		      6'b011011: Mem <= 32'hbf597fc7 ;
		      6'b011100: Mem <= 32'hc6e00bf3 ;
		      6'b011101: Mem <= 32'hd5a79147 ;
		      6'b011110: Mem <= 32'h06ca6351 ;
		      6'b011111: Mem <= 32'h14292967 ;
              6'b100000: Mem <= 32'h27b70a85 ;
		      6'b100001: Mem <= 32'h2e1b2138 ;
		      6'b100010: Mem <= 32'h4d2c6dfc ;
		      6'b100011: Mem <= 32'h53380d13 ;
		      6'b100100: Mem <= 32'h650a7354 ;
		      6'b100101: Mem <= 32'h766a0abb ;
		      6'b100110: Mem <= 32'h81c2c92e ;
		      6'b100111: Mem <= 32'h92722c85 ;
		      6'b101000: Mem <= 32'ha2bfe8a1 ;
		      6'b101001: Mem <= 32'ha81a664b ;
		      6'b101010: Mem <= 32'hc24b8b70 ;
		      6'b101011: Mem <= 32'hc76c51a3 ;
		      6'b101100: Mem <= 32'hd192e819 ;
		      6'b101101: Mem <= 32'hd6990624 ;
		      6'b101110: Mem <= 32'hf40e3585 ;
		      6'b101111: Mem <= 32'h106aa070 ;
              6'b110000: Mem <= 32'h19a4c116 ;
		      6'b110001: Mem <= 32'h1e376c08 ;
		      6'b110010: Mem <= 32'h2748774c ;
		      6'b110011: Mem <= 32'h34b0bcb5 ;
		      6'b110100: Mem <= 32'h391c0cb3 ;
		      6'b110101: Mem <= 32'h4ed8aa4a ;
		      6'b110110: Mem <= 32'h5b9cca4f ;
		      6'b110111: Mem <= 32'h682e6ff3 ;
		      6'b111000: Mem <= 32'h748f82ee ;
		      6'b111001: Mem <= 32'h78a5636f ;
		      6'b111010: Mem <= 32'h84c87814 ;
		      6'b111011: Mem <= 32'h8cc70208 ;
		      6'b111100: Mem <= 32'h90befffa ;
		      6'b111101: Mem <= 32'ha4506ceb ;
		      6'b111110: Mem <= 32'hbef9a3f7 ;
		      6'b111111: Mem <= 32'hc67178f2 ;
            endcase
    end	
  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule
*/
module mem_ROM_k_256_eddsa  # 
  (
    parameter SIZE = 64,
    parameter WIDTH = 32
  )( 
    input wire clk,
    input wire enable,
    input wire [clog2(SIZE-1)-1:0] addr,
    output wire [WIDTH-1:0] data
  );
    
    reg [WIDTH-1:0] data_reg;
 	reg [WIDTH-1:0] Mem [SIZE-1:0];
	
	always @(posedge clk) 
	begin
		//if(enable)   data_reg <= Mem[addr];
	end
	
    //assign data = data_reg;
	assign data = Mem[addr];
	
	initial begin
	         Mem [6'b000000] <= 32'h428a2f98 ; // 0
		     Mem [6'b000001] <= 32'h71374491 ; 
		     Mem [6'b000010] <= 32'hb5c0fbcf ;
		     Mem [6'b000011] <= 32'he9b5dba5 ;
		     Mem [6'b000100] <= 32'h3956c25b ;
		     Mem [6'b000101] <= 32'h59f111f1 ;
		     Mem [6'b000110] <= 32'h923f82a4 ;
		     Mem [6'b000111] <= 32'hab1c5ed5 ; // 7
		     Mem [6'b001000] <= 32'hd807aa98 ;
		     Mem [6'b001001] <= 32'h12835b01 ;
		     Mem [6'b001010] <= 32'h243185be ;
		     Mem [6'b001011] <= 32'h550c7dc3 ;
		     Mem [6'b001100] <= 32'h72be5d74 ;
		     Mem [6'b001101] <= 32'h80deb1fe ;
		     Mem [6'b001110] <= 32'h9bdc06a7 ;
		     Mem [6'b001111] <= 32'hc19bf174 ; // 15
             Mem [6'b010000] <= 32'he49b69c1 ;
		     Mem [6'b010001] <= 32'hefbe4786 ;
		     Mem [6'b010010] <= 32'h0fc19dc6 ;
		     Mem [6'b010011] <= 32'h240ca1cc ;
		     Mem [6'b010100] <= 32'h2de92c6f ;
		     Mem [6'b010101] <= 32'h4a7484aa ;
		     Mem [6'b010110] <= 32'h5cb0a9dc ;
		     Mem [6'b010111] <= 32'h76f988da ;
		     Mem [6'b011000] <= 32'h983e5152 ;
		     Mem [6'b011001] <= 32'ha831c66d ;
		     Mem [6'b011010] <= 32'hb00327c8 ;
		     Mem [6'b011011] <= 32'hbf597fc7 ;
		     Mem [6'b011100] <= 32'hc6e00bf3 ;
		     Mem [6'b011101] <= 32'hd5a79147 ;
		     Mem [6'b011110] <= 32'h06ca6351 ;
		     Mem [6'b011111] <= 32'h14292967 ;
             Mem [6'b100000] <= 32'h27b70a85 ;
		     Mem [6'b100001] <= 32'h2e1b2138 ;
		     Mem [6'b100010] <= 32'h4d2c6dfc ;
		     Mem [6'b100011] <= 32'h53380d13 ;
		     Mem [6'b100100] <= 32'h650a7354 ;
		     Mem [6'b100101] <= 32'h766a0abb ;
		     Mem [6'b100110] <= 32'h81c2c92e ;
		     Mem [6'b100111] <= 32'h92722c85 ;
		     Mem [6'b101000] <= 32'ha2bfe8a1 ;
		     Mem [6'b101001] <= 32'ha81a664b ;
		     Mem [6'b101010] <= 32'hc24b8b70 ;
		     Mem [6'b101011] <= 32'hc76c51a3 ;
		     Mem [6'b101100] <= 32'hd192e819 ;
		     Mem [6'b101101] <= 32'hd6990624 ;
		     Mem [6'b101110] <= 32'hf40e3585 ;
		     Mem [6'b101111] <= 32'h106aa070 ;
             Mem [6'b110000] <= 32'h19a4c116 ;
		     Mem [6'b110001] <= 32'h1e376c08 ;
		     Mem [6'b110010] <= 32'h2748774c ;
		     Mem [6'b110011] <= 32'h34b0bcb5 ;
		     Mem [6'b110100] <= 32'h391c0cb3 ;
		     Mem [6'b110101] <= 32'h4ed8aa4a ;
		     Mem [6'b110110] <= 32'h5b9cca4f ;
		     Mem [6'b110111] <= 32'h682e6ff3 ;
		     Mem [6'b111000] <= 32'h748f82ee ;
		     Mem [6'b111001] <= 32'h78a5636f ;
		     Mem [6'b111010] <= 32'h84c87814 ;
		     Mem [6'b111011] <= 32'h8cc70208 ;
		     Mem [6'b111100] <= 32'h90befffa ;
		     Mem [6'b111101] <= 32'ha4506ceb ;
		     Mem [6'b111110] <= 32'hbef9a3f7 ;
		     Mem [6'b111111] <= 32'hc67178f2 ;
	end

  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule

module mem_ROM_k_512_eddsa  # 
  (
    parameter SIZE = 80,
    parameter WIDTH = 64
  )( 
    input wire clk,
    input wire enable,
    input wire [clog2(SIZE-1)-1:0] addr,
    output wire [WIDTH-1:0] data
  );
    
    reg [WIDTH-1:0] data_reg;
 	reg [WIDTH-1:0] Mem [SIZE-1:0];
	
	always @(posedge clk) 
	begin
		//if(enable)   data_reg <= Mem[addr];
	end
	
    //assign data = data_reg;
	assign data = Mem[addr];
	
	initial begin
	         Mem [7'b0000000] <= 64'h428a2f98_d728ae22 ; // 0
		     Mem [7'b0000001] <= 64'h71374491_23ef65cd ; 
		     Mem [7'b0000010] <= 64'hb5c0fbcf_ec4d3b2f ;
		     Mem [7'b0000011] <= 64'he9b5dba5_8189dbbc ;
		     Mem [7'b0000100] <= 64'h3956c25b_f348b538 ;
		     Mem [7'b0000101] <= 64'h59f111f1_b605d019 ;
		     Mem [7'b0000110] <= 64'h923f82a4_af194f9b ;
		     Mem [7'b0000111] <= 64'hab1c5ed5_da6d8118 ; // 7
		     Mem [7'b0001000] <= 64'hd807aa98_a3030242 ;
		     Mem [7'b0001001] <= 64'h12835b01_45706fbe ;
		     Mem [7'b0001010] <= 64'h243185be_4ee4b28c ;
		     Mem [7'b0001011] <= 64'h550c7dc3_d5ffb4e2 ;
		     Mem [7'b0001100] <= 64'h72be5d74_f27b896f ;
		     Mem [7'b0001101] <= 64'h80deb1fe_3b1696b1 ;
		     Mem [7'b0001110] <= 64'h9bdc06a7_25c71235 ;
		     Mem [7'b0001111] <= 64'hc19bf174_cf692694 ; // 15
             Mem [7'b0010000] <= 64'he49b69c1_9ef14ad2 ;
		     Mem [7'b0010001] <= 64'hefbe4786_384f25e3 ;
		     Mem [7'b0010010] <= 64'h0fc19dc6_8b8cd5b5 ;
		     Mem [7'b0010011] <= 64'h240ca1cc_77ac9c65 ;
		     Mem [7'b0010100] <= 64'h2de92c6f_592b0275 ;
		     Mem [7'b0010101] <= 64'h4a7484aa_6ea6e483 ;
		     Mem [7'b0010110] <= 64'h5cb0a9dc_bd41fbd4 ;
		     Mem [7'b0010111] <= 64'h76f988da_831153b5 ;
		     Mem [7'b0011000] <= 64'h983e5152_ee66dfab ;
		     Mem [7'b0011001] <= 64'ha831c66d_2db43210 ;
		     Mem [7'b0011010] <= 64'hb00327c8_98fb213f ;
		     Mem [7'b0011011] <= 64'hbf597fc7_beef0ee4 ;
		     Mem [7'b0011100] <= 64'hc6e00bf3_3da88fc2 ;
		     Mem [7'b0011101] <= 64'hd5a79147_930aa725 ;
		     Mem [7'b0011110] <= 64'h06ca6351_e003826f ;
		     Mem [7'b0011111] <= 64'h14292967_0a0e6e70 ;
             Mem [7'b0100000] <= 64'h27b70a85_46d22ffc ;
		     Mem [7'b0100001] <= 64'h2e1b2138_5c26c926 ;
		     Mem [7'b0100010] <= 64'h4d2c6dfc_5ac42aed ;
		     Mem [7'b0100011] <= 64'h53380d13_9d95b3df ;
		     Mem [7'b0100100] <= 64'h650a7354_8baf63de ;
		     Mem [7'b0100101] <= 64'h766a0abb_3c77b2a8 ;
		     Mem [7'b0100110] <= 64'h81c2c92e_47edaee6 ;
		     Mem [7'b0100111] <= 64'h92722c85_1482353b ;
		     Mem [7'b0101000] <= 64'ha2bfe8a1_4cf10364 ;
		     Mem [7'b0101001] <= 64'ha81a664b_bc423001 ;
		     Mem [7'b0101010] <= 64'hc24b8b70_d0f89791 ;
		     Mem [7'b0101011] <= 64'hc76c51a3_0654be30 ;
		     Mem [7'b0101100] <= 64'hd192e819_d6ef5218 ;
		     Mem [7'b0101101] <= 64'hd6990624_5565a910 ;
		     Mem [7'b0101110] <= 64'hf40e3585_5771202a ;
		     Mem [7'b0101111] <= 64'h106aa070_32bbd1b8 ;
             Mem [7'b0110000] <= 64'h19a4c116_b8d2d0c8 ;
		     Mem [7'b0110001] <= 64'h1e376c08_5141ab53 ;
		     Mem [7'b0110010] <= 64'h2748774c_df8eeb99 ;
		     Mem [7'b0110011] <= 64'h34b0bcb5_e19b48a8 ;
		     Mem [7'b0110100] <= 64'h391c0cb3_c5c95a63 ;
		     Mem [7'b0110101] <= 64'h4ed8aa4a_e3418acb ;
		     Mem [7'b0110110] <= 64'h5b9cca4f_7763e373 ;
		     Mem [7'b0110111] <= 64'h682e6ff3_d6b2b8a3 ;
		     Mem [7'b0111000] <= 64'h748f82ee_5defb2fc ;
		     Mem [7'b0111001] <= 64'h78a5636f_43172f60 ;
		     Mem [7'b0111010] <= 64'h84c87814_a1f0ab72 ;
		     Mem [7'b0111011] <= 64'h8cc70208_1a6439ec ;
		     Mem [7'b0111100] <= 64'h90befffa_23631e28 ;
		     Mem [7'b0111101] <= 64'ha4506ceb_de82bde9 ;
		     Mem [7'b0111110] <= 64'hbef9a3f7_b2c67915 ;
		     Mem [7'b0111111] <= 64'hc67178f2_e372532b ;
		     Mem [7'b1000000] <= 64'hca273ece_ea26619c ; // 0
		     Mem [7'b1000001] <= 64'hd186b8c7_21c0c207 ; 
		     Mem [7'b1000010] <= 64'heada7dd6_cde0eb1e ;
		     Mem [7'b1000011] <= 64'hf57d4f7f_ee6ed178 ;
		     Mem [7'b1000100] <= 64'h06f067aa_72176fba ;
		     Mem [7'b1000101] <= 64'h0a637dc5_a2c898a6 ;
		     Mem [7'b1000110] <= 64'h113f9804_bef90dae ;
		     Mem [7'b1000111] <= 64'h1b710b35_131c471b ; // 7
		     Mem [7'b1001000] <= 64'h28db77f5_23047d84 ;
		     Mem [7'b1001001] <= 64'h32caab7b_40c72493 ;
		     Mem [7'b1001010] <= 64'h3c9ebe0a_15c9bebc ;
		     Mem [7'b1001011] <= 64'h431d67c4_9c100d4c ;
		     Mem [7'b1001100] <= 64'h4cc5d4be_cb3e42b6 ;
		     Mem [7'b1001101] <= 64'h597f299c_fc657e2a ;
		     Mem [7'b1001110] <= 64'h5fcb6fab_3ad6faec ;
		     Mem [7'b1001111] <= 64'h6c44198c_4a475817 ; // 15
	end

  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule