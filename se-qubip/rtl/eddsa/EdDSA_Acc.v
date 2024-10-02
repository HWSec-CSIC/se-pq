
/**
  * @file  EdDSA_Acc.v
  * @brief EDSA25519 ECC Accelerator
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
  
 ////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 22/02/2024
// Design Name: EdDSA_Acc.v
// Module Name: EdDSA_Acc
// Project Name: EDSA25519 ECC Accelerator
// Target Devices: PYNQ-Z1
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Modular Arithmetic Accelerator using 256x256 4-level Karatsuba Multiplier 
//      with reduction mod P = 2**255-19
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////
  
module EdDSA_Acc #(
                   parameter BIT_LENGTH = 256,
                   parameter n_LEVEL = 2,                   //-- Recursion Levels
                   parameter WINDOW_SIZE = 4                //-- k-ary Window Size             
                   )
                   (
				    //-- Clock and Reset Signals
				    input  wire clk,					
				    input  wire rst,			
				    //-- Operation Select 
				    input  wire [3:0] sel,
				    //-- Point P Coordinates
				    input  wire [BIT_LENGTH-1:0] P0,	
				    input  wire [BIT_LENGTH-1:0] P1,
				    input  wire [BIT_LENGTH-1:0] P2,
				    input  wire [BIT_LENGTH-1:0] P3,
                    //-- Point Q Coordinates
				    input  wire [BIT_LENGTH-1:0] Q0,	
				    input  wire [BIT_LENGTH-1:0] Q1,	
				    input  wire [BIT_LENGTH-1:0] Q2,	
				    input  wire [BIT_LENGTH-1:0] Q3,
				    //-- Scalars S1 and S2
				    input  wire [BIT_LENGTH-1:0] S1,    
				    input  wire [BIT_LENGTH-1:0] S2,    
				    //-- Resulting Point R Coordinates
				    output reg [BIT_LENGTH-1:0] R0,    
				    output reg [BIT_LENGTH-1:0] R1,
				    output reg [BIT_LENGTH-1:0] R2,
				    output reg [BIT_LENGTH-1:0] R3,
				    //-- Resulting Point W Coordinates
				    output reg [BIT_LENGTH-1:0] W0,    
				    output reg [BIT_LENGTH-1:0] W1,
				    output reg [BIT_LENGTH-1:0] W2,
				    output reg [BIT_LENGTH-1:0] W3,
				    //-- Output is valid
				    output reg valid,
				    //-- Output Error
				    output reg error
				    );
    
    
    //------------------------------------------------------------------------------------------------
	//-- Operations            
	//------------------------------------------------------------------------------------------------
    //--    Select     |    Description    |    Operation
    //------------------------------------------------------------------------------------------------
    //--      1        | Mod. Mul          |    R0 = P0 · Q0 (mod P)
    //--      2        | Point Add.        |    R  = P + Q
    //--      3        | Red. Mod L        |    R0 = {P0, Q0} (mod L)
    //--      4        | Point Mul.        |    R  = [S1]P  
    //--      5        | Double Point Mul. |    R  = [S1]P | W  = [S2]Q
    //--      6        | Multiplication    |    {R1,R0} = P0 · Q0
    //--      7        | Mod. Add.         |    R0 = P0 + Q0 (mod P)
    //--      8        | Point Equal       |    R0[0] = point_equal(P0, P1, P2, Q0, Q1, Q2) = {0,1}
    //--      9        | Point Compress    |    R0 = point_compress(P0, P1, P2)
    //--     10        | Point Decompress  |    R = point_decompress(P1)
    //------------------------------------------------------------------------------------------------
    
    
    //------------------------------------------------------------------------------------------------
	//-- Parameters             
	//------------------------------------------------------------------------------------------------
    
    //-- Prime Field Size p = 2**255-19
	localparam P       = 256'h7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
	// localparam P_INV   = 256'h7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffeb;
	//-- Curve Constant d
	localparam D       = 256'h52036cee_2b6ffe73_8cc74079_7779e898_00700a4d_4141d8ab_75eb4dca_135978a3;
	//-- K = 2d
	localparam K       = 256'h2406d9dc_56dffce7_198e80f2_eef3d130_00e0149a_8283b156_ebd69b94_26b2f159;
	//-- Prime Order of the Base Point
	localparam L       = 256'h10000000_00000000_00000000_00000000_14def9de_a2f79cd6_5812631a_5cf5d3ed;
	//-- Square Root of -1 [2^((p-1)/4)]
	localparam SQRT_1  = 256'h2b832480_4fc1df0b_2b4d0099_3dfbd7a7_2f431806_ad2fe478_c4ee1b27_4a0ea0b0;
	//-- (P-5)/8
	// localparam P_58    = 256'h0fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_fffffffd;
	
	
	//-- k-ary window Parameters
	localparam LOG2_BIT_LENGTH     = $clog2(BIT_LENGTH);
	localparam WINDOW_BLOCKS       = BIT_LENGTH/WINDOW_SIZE;
	localparam LOG2_WINDOW_BLOCKS  = $clog2(WINDOW_BLOCKS);
	

	//------------------------------------------------------------------------------------------------
	//-- Wires and Registers               
	//------------------------------------------------------------------------------------------------
	
	//-- Temporary registers
	//-- R = P + Q
	reg [BIT_LENGTH-1:0] temp_P0;
	reg [BIT_LENGTH-1:0] temp_P1;
	reg [BIT_LENGTH-1:0] temp_P2;
	reg [BIT_LENGTH-1:0] temp_P3;
	
	reg [BIT_LENGTH-1:0] temp_Q0;
	reg [BIT_LENGTH-1:0] temp_Q1;
	reg [BIT_LENGTH-1:0] temp_Q2;
	reg [BIT_LENGTH-1:0] temp_Q3;
	
	reg [BIT_LENGTH-1:0] temp_R1;
	reg [BIT_LENGTH-1:0] temp_R2;
	reg [BIT_LENGTH-1:0] temp_R3;
	reg [BIT_LENGTH-1:0] temp_R4;
	reg [BIT_LENGTH-1:0] temp_R5;
	reg [BIT_LENGTH-1:0] temp_R6;
	reg [BIT_LENGTH-1:0] temp_R7;
	reg [BIT_LENGTH-1:0] temp_R8;
	
	//-- W = U + V
	reg [BIT_LENGTH-1:0] temp_U0;
	reg [BIT_LENGTH-1:0] temp_U1;
	reg [BIT_LENGTH-1:0] temp_U2;
	reg [BIT_LENGTH-1:0] temp_U3;
	
	reg [BIT_LENGTH-1:0] temp_V0;
	reg [BIT_LENGTH-1:0] temp_V1;
	reg [BIT_LENGTH-1:0] temp_V2;
	reg [BIT_LENGTH-1:0] temp_V3;
	
	reg [BIT_LENGTH-1:0] temp_W1;
	reg [BIT_LENGTH-1:0] temp_W2;
	reg [BIT_LENGTH-1:0] temp_W3;
	reg [BIT_LENGTH-1:0] temp_W4;
	reg [BIT_LENGTH-1:0] temp_W5;
	reg [BIT_LENGTH-1:0] temp_W6;
	reg [BIT_LENGTH-1:0] temp_W7;
	reg [BIT_LENGTH-1:0] temp_W8;
	
	//-- Point Addition Operation Counter
	reg point_mul;
	reg double_mul;
	reg [4:0] add_counter;
    
    //-- Point Compress Signal
    reg compress;
    
    //-- Decompress Signals
    reg x_0;
    reg decompress;
    reg dec_minus_u;
    
    wire [BIT_LENGTH-1:0] P1_swap;
    assign P1_swap = {P1[7:0], P1[15:8], P1[23:16], P1[31:24], P1[39:32], P1[47:40], P1[55:48], P1[63:56], P1[71:64], P1[79:72], P1[87:80], P1[95:88], P1[103:96], P1[111:104], P1[119:112], P1[127:120], P1[135:128], 
                      P1[143:136], P1[151:144], P1[159:152], P1[167:160], P1[175:168], P1[183:176], P1[191:184], P1[199:192], P1[207:200], P1[215:208], P1[223:216], P1[231:224], P1[239:232], P1[247:240], P1[255:248]};    
    
    
    //------------------------------------------------------------------------------------------------
	//-- Karatsuba Multiplier               
	//------------------------------------------------------------------------------------------------
	
	reg  [BIT_LENGTH-1:0] temp_A;
	reg  [BIT_LENGTH-1:0] temp_B;
	wire [2*BIT_LENGTH-1:0] temp_C;
	
	reg restart;
	reg redux;
	
	wire MP_done;
	
	multiplier #(
				.BIT_LENGTH(BIT_LENGTH),
				.n_LEVEL(n_LEVEL)
				) 
				karatsuba_multiplier
				(
				.clk(clk),
				.rst(restart),
				.redux(redux),
				.A(temp_A),
				.B(temp_B),
				.U(temp_C),
				.valid(MP_done)
				);
    
    
    //------------------------------------------------------------------------------------------------
	//-- Adder/Subtractor x2           
	//------------------------------------------------------------------------------------------------
    
    reg  add_sub_mode_1;
    reg  [BIT_LENGTH-1:0] add_sub_A_1;
    reg  [BIT_LENGTH-1:0] add_sub_B_1;
    wire [BIT_LENGTH-1:0] add_sub_C_1;
    
    reg  add_sub_mode_2;
    reg  [BIT_LENGTH-1:0] add_sub_A_2;
    reg  [BIT_LENGTH-1:0] add_sub_B_2;
    wire [BIT_LENGTH-1:0] add_sub_C_2;
    
    add_sub #(
			  .BIT_LENGTH(BIT_LENGTH)
			  ) 
			  add_sub_1
			  (
			   .clk(clk),
			   .rst(rst),
			   .mode(add_sub_mode_1),
               .A(add_sub_A_1),
               .B(add_sub_B_1),
               .C(add_sub_C_1)
			   );
			   
    add_sub #(
			  .BIT_LENGTH(BIT_LENGTH)
			  ) 
			  add_sub_2
			  (
			   .clk(clk),
			   .rst(rst),
			   .mode(add_sub_mode_2),
               .A(add_sub_A_2),
               .B(add_sub_B_2),
               .C(add_sub_C_2)
			   );
    
    
    //-----------------------------------------------------------------------------------------------------
	//-- 512-bit Modulo L reduction calculations              
	//-----------------------------------------------------------------------------------------------------

    reg  [BIT_LENGTH-1:0] red_A;
    reg  [385:0] red_B;
    wire [385:0] red_C;
    wire smaller;
    wire equal;
    wire bigger;
    
    reg [4:0] red_state;
    
    reg [2:0] red_sign;     //-- Sign Operation Counter for Underflow Condition
    wire final_sign;
    
    assign final_sign = red_sign[2] ^ red_sign[1] ^ red_sign[0];
	
	sub_red512 sub_red512(
	                      .clk(clk),
	                      .rst(rst),
	                      .A(red_A),
	                      .B(red_B),
	                      .C(red_C),
	                      .smaller(smaller),
	                      .equal(equal),
	                      .bigger(bigger)
	                      );

    
    //--------------------------------------------------------------------------------------------------------------------
	//-- Double/Single Scalar Multiplication with k-ary window (w = 4)  
	//--------------------------------------------------------------------------------------------------------------------

	reg pre_calc;
	reg [2:0] bit_counter;
	reg init_block;
	reg [LOG2_WINDOW_BLOCKS:0] window_block;
	
	
	reg  wr_1;
	reg  rd_1;
	
	reg  [WINDOW_SIZE-1:0] window_counter_1;
	wire [4*BIT_LENGTH-1:0] data_out_ecc_1;      
	
	genram #(
	         .AW(WINDOW_SIZE), 
	         .DW(4*BIT_LENGTH),
	         .INIT(1),
	         .ROMFILE("Base_Point_Powers.mem")
	         )
	         RAM_ECC_1
	         (
			  .clk(clk),
			  .wr(wr_1),
			  .rd(rd_1),
			  .addr(window_counter_1),
			  .data_in({R0, R1, R2, R3}),
			  .data_out(data_out_ecc_1)
			  );
	
	reg  wr_2;
	reg  rd_2;
	reg  [WINDOW_SIZE-1:0] window_counter_2;
	wire [4*BIT_LENGTH-1:0] data_out_ecc_2;     
	
	genram #(
	         .AW(WINDOW_SIZE), 
	         .DW(4*BIT_LENGTH)
	         ) 
	         RAM_ECC_2
	         (
			  .clk(clk),
			  .wr(wr_2),
			  .rd(rd_2),
			  .addr(window_counter_2),
			  .data_in({W0, W1, W2, W3}),
			  .data_out(data_out_ecc_2)
			  );
	
	wire [WINDOW_SIZE-1:0] bit_window_1;
	wire [WINDOW_SIZE-1:0] bit_window_2;
	
	assign bit_window_1 = S1[BIT_LENGTH-1-window_block*WINDOW_SIZE-:WINDOW_SIZE];
	assign bit_window_2 = S2[BIT_LENGTH-1-window_block*WINDOW_SIZE-:WINDOW_SIZE];
	
	
	//--------------------------------------------------------------------------------------------------------------------
	//-- Addition Chains for Exponentiation
	//--------------------------------------------------------------------------------------------------------------------
	
	reg [8:0] chain_counter;
	reg chain_square;
	
	
	//--------------------------------------------------------------------------------------------------------------------
	//-- Logic Controller               
	//--------------------------------------------------------------------------------------------------------------------	
	
	localparam IDLE 				   = 0;
	//-- MODULAR MULTIPLICATION 	   		
	localparam MOD_MUL			       = 1;	     //-- Single Modular Multiplication
	//-- MODULAR EXPONENTIATION
	localparam EXP_WAIT                = 2;      //-- Wait till multiplication finish
	localparam EXP_SELECT              = 3;      //-- Select if chain_square or multiply
	//-- POINT ADDITION
	localparam POINT_ADD		       = 4;	     //-- Point Addition
	//-- SINGLE/DOUBLE POINT MULTIPLICATION
	localparam INIT_PRE_POINT_MUL      = 5;     
	localparam PRE_POINT_MUL           = 6;
	localparam INIT_POINT_MUL          = 7;
	localparam POINT_MUL               = 8;      //-- Point Multiplication
	//-- 512-BIT MODULO L REDUCTION
	localparam RED_512                 = 9;     //-- Reduction Mod L
	//-- MULTIPLICATION
	localparam MUL                     = 10;     //-- Multiplication
	//-- MODULAR ADDITION
	localparam ADD                     = 11;     //-- Addition mod PP
	//-- POINT EQUAL
	localparam POINT_EQUAL             = 12;
	//-- POINT COMPRESS
	localparam POINT_COMPRESS          = 13;
	//-- POINT DECOMPRESS
	localparam RECOVER_X               = 14;
	localparam POINT_DECOMPRESS        = 15;
	//-- END
	localparam END  				   = 16;
	
	reg [4:0] state;
	reg [5:0] op_counter;
	
	always @(posedge clk) begin
		if (rst) begin
			R0      <= 0;
			R1      <= 0;
			R2      <= 0;
			R3      <= 0;
			
			W0      <= 0;
			W1      <= 0;
			W2      <= 0;
			W3      <= 0;       
			
			temp_P0 <= 0;
            temp_P1 <= 0;
            temp_P2 <= 0;
            temp_P3 <= 0;
            temp_Q0 <= 0;
            temp_Q1 <= 0;
            temp_Q2 <= 0;
            temp_Q3 <= 0;
			
			temp_R1 <= 0;
            temp_R2 <= 0;
            temp_R3 <= 0;
            temp_R4 <= 0;
            temp_R5 <= 0;
            temp_R6 <= 0;
            temp_R7 <= 0;
            temp_R8 <= 0;
            
            temp_U0 <= 0;
            temp_U1 <= 0;
            temp_U2 <= 0;
            temp_U3 <= 0;
            temp_V0 <= 0;
            temp_V1 <= 0;
            temp_V2 <= 0;
            temp_V3 <= 0;
            
            temp_W1 <= 0;
            temp_W2 <= 0;
            temp_W3 <= 0;
            temp_W4 <= 0;
            temp_W5 <= 0;
            temp_W6 <= 0;
            temp_W7 <= 0;
            temp_W8 <= 0;
			
			temp_A  <= 0;
			temp_B  <= 0;
			
            redux   <= 1;
            restart <= 1;
            
            point_mul   <= 0;
            add_counter <= 0;
            
            compress    <= 0;
            decompress  <= 0;
            dec_minus_u <= 0;
	        
	        red_A      <= 0;
	        red_B      <= 0;
	        red_state  <= 0;
	        red_sign   <= 0;
	        
	        double_mul <= 0;

			wr_1             <= 0;
			rd_1             <= 0;
			wr_2             <= 0;
			rd_2             <= 0;
			window_counter_1 <= 0;
			window_counter_2 <= 0;
			pre_calc         <= 0;

			bit_counter      <= 0;
			window_block     <= 0;
			
			init_block       <= 1;
			
			chain_counter    <= 0;
			chain_square     <= 1;
			
			op_counter   <= 0;
			error        <= 0;
			valid        <= 0;
			state        <= IDLE;
		end
		else begin
		case (state)
		    
		    //-------------------------------------------
	        //-- IDLE STATE     
            //-------------------------------------------
		    
		    (IDLE): begin               
		       temp_P0 <= P0;
               temp_P1 <= P1;
               temp_P2 <= P2;
               temp_P3 <= P3;
               
               temp_U0 <= Q0;
               temp_U1 <= Q1;
               temp_U2 <= Q2;
               temp_U3 <= Q3;  
		       
		       case (sel)
		       
		       (4'd1): begin
		           temp_A  <= P0;
		           temp_B  <= Q0;
		           redux   <= 1;
		           restart <= 0;
		           state   <= MOD_MUL;
		       end
		       (4'd2): begin
                   temp_Q0 <= Q0;
                   temp_Q1 <= Q1;
                   temp_Q2 <= Q2;
                   temp_Q3 <= Q3;
               
		           point_mul   <= 0;
		           add_counter <= 1;
		           redux       <= 1;
		           state       <= POINT_ADD;
		       end
		       (4'd3): begin
		           temp_A     <= P0;
		           temp_B     <= L[127:0];
		           restart    <= 0;
		           redux      <= 0;
		           red_state  <= 0;
		           red_sign   <= 0;
		           state      <= RED_512;
		       end
		       (4'd4): begin
		           /*
		           R0 <= 0;
		           R1 <= 1;
		           R2 <= 1;
		           R3 <= 0;
		           
		           wr_1 <= 1;
		           */
		           
		           rd_1       <= 1;
		           
		           point_mul  <= 1;
		           pre_calc   <= 0;
		           redux      <= 1;
		           state      <= INIT_POINT_MUL;
		       end
		       (4'd5): begin
		          R0 <= 0;
		          R1 <= 1;
		          R2 <= 1;
		          R3 <= 0;
		          
		          W0 <= 0;
                  W1 <= 1;
                  W2 <= 1;
                  W3 <= 0;
		          
		          wr_1 <= 1;
		          wr_2 <= 1;
		          
		          double_mul  <= 1;
		          pre_calc    <= 1;
		          redux       <= 1;
		          state       <= INIT_PRE_POINT_MUL;
		       end
		       (4'd6): begin
		           temp_A  <= P0;
		           temp_B  <= Q0;
		           redux   <= 0;
		           restart <= 0;
		           state   <= MUL;
		       end
		       (4'd7): begin
		           add_sub_A_1    <= P0;
		           add_sub_B_1    <= Q0;
		           add_sub_mode_1 <= 0;
		           op_counter     <= 0;
		           state          <= ADD;
		       end
		       (4'd8): begin
		          temp_A  <= P0;
		          temp_B  <= Q2;
		          redux   <= 1;
		          restart <= 0;
		          
		          op_counter  <= 0;
		          state       <= POINT_EQUAL;
		       end	
		       (4'd9): begin
		          R0          <= P2;
		          temp_P0     <= P2;
                  redux       <= 1;
		          compress    <= 1;
		     
		          op_counter  <= 0;
		          state       <= EXP_SELECT;// EXP_ZERO;
		       end		       
		       (4'd10): begin
		          x_0     <= P1_swap[BIT_LENGTH-1];
		          R1      <= {1'b0, P1_swap[BIT_LENGTH-2:0]};
		          
		          add_sub_mode_1  <= 1;
		          redux           <= 1;
		          decompress      <= 1;
		          dec_minus_u     <= 0;
		          restart         <= 0;
		          
		          op_counter  <= 0;
		          state       <= RECOVER_X;
		       end

		       endcase
		       
		    end
		    
		    //-------------------------------------------
	        //-- MODULAR MULTIPLICATION     
            //-------------------------------------------
		    
		    (MOD_MUL): begin
		       if (MP_done) begin
		          R0    <= temp_C;
		          valid <= 1;
		          state <= END;
		       end
		    end 
		    
		    //-------------------------------------------
	        //-- MODULAR EXPONENTIATION     
            //-------------------------------------------
            
            (EXP_SELECT): begin
               temp_A <= R0;
               
               if (chain_square)
		          temp_B <= R0; 
		       else begin
		          temp_B <= temp_P1;
                  chain_square <= 1;
               end
               
               restart  <= 0;
               state    <= EXP_WAIT;
            end
            
            (EXP_WAIT): begin
               if (MP_done) begin
                  restart         <= 1;
                  chain_counter   <= chain_counter + 1;
                  R0              <= temp_C;
               end 
               
               case (chain_counter)
               //-- Square 1 time and store _10
               (9'd0): temp_W1 <= temp_C;
               //-- Square 2 times and multiply by _1
               (9'd2): begin
                  temp_P1       <= temp_P0;     //-- temp_P0 saves initial state
                  chain_square  <= 0;
               end
               //-- Store _1001 and multiply by _10
               (9'd3): begin
                  temp_W2 <= temp_C;
                  temp_P1 <= temp_W1;
                  chain_square  <= 0;
               end
               //-- Store _1011
               (9'd4): temp_W3 <= temp_C;
               //-- Square 1 time and multiply by _1001
               (9'd5): begin
                  temp_P1       <= temp_W2;
                  chain_square  <= 0;
               end
               //-- Store x5
               (9'd6): temp_W4 <= temp_C;
               //-- Square 5 times and multiply by x5
               (9'd11): begin
                  temp_P1       <= temp_W4;
                  chain_square  <= 0;
               end
               //-- Store x10
               (9'd12): temp_W5 <= temp_C;
               //-- Square 10 times and multiply by x10
               (9'd22): begin
                  temp_P1       <= temp_W5;
                  chain_square  <= 0;
               end
               //-- Store x20
               (9'd23): temp_W6 <= temp_C;
               //-- Square 20 times and multiply by x20
               (9'd43): begin
                  temp_P1       <= temp_W6;
                  chain_square  <= 0;
               end
               //-- Store x40
               (9'd44): temp_W7 <= temp_C;
               //-- Square 10 times and multiply by x10
               (9'd54): begin
                  temp_P1       <= temp_W5;
                  chain_square  <= 0;
               end
               //-- Store x50
               (9'd55): temp_W8 <= temp_C;
               //-- Square 50 times and multiply by x50
               (9'd105): begin
                  temp_P1       <= temp_W8;
                  chain_square  <= 0;
               end
               //-- Store x100
               (9'd106): temp_Q0 <= temp_C;
               //-- Square 100 times and multiply by x100
               (9'd206): begin
                  temp_P1       <= temp_Q0;
                  chain_square  <= 0;
               end
               //-- Square 50 times and multiply by x50
               (9'd257): begin
                  temp_P1       <= temp_W8;
                  chain_square  <= 0;
               end
               
               //-- Square 2 times and multiply by _1 if Decompression
               (9'd260): begin
                  if (decompress) begin
                     temp_P1        <= temp_P0;
                     chain_square   <= 0;
                  end
               end
               //-- End exponentiation if Decompression
               // (9'd261):
               //-- Square 5 times and multiply by _1011 if Inversion
               (9'd263): begin 
                  temp_P1       <= temp_W3;
                  chain_square  <= 0;
               end
               //-- End exponentiation if Inversion
               // (9'd264):
               endcase 
               
               if (chain_counter == 261 && decompress && MP_done)
                  state <= RECOVER_X;
               else if (chain_counter == 264 && compress && MP_done)
                  state <= POINT_COMPRESS;
               else if (chain_counter == 264 && MP_done) begin
                  valid <= 1;
                  state <= END;
               end
               else if (MP_done) 
                  state <= EXP_SELECT;
            end
            
            
		    //-------------------------------------------
	        //-- POINT ADDITION     
            //-------------------------------------------
		    
		    (POINT_ADD): begin
		        
		       add_counter    <= add_counter + 1;
		       restart        <= 0;
		       
		       case (add_counter)
		           (1): begin
		               //-- R1 = Y1 - X1
		               add_sub_mode_1    <= 1;
		               add_sub_A_1       <= temp_P1;
		               add_sub_B_1       <= temp_P0;
		               //-- R2 = Y2 - X2		                
		               add_sub_mode_2    <= 1;
		               add_sub_A_2       <= temp_Q1;
		               add_sub_B_2       <= temp_Q0;
		               //-- R7 = T1 x T2
		               temp_A            <= temp_P3;
		               temp_B            <= temp_Q3;
		           end
		           (2): begin
		               //-- R3 = Y1 + X1
		               add_sub_mode_1    <= 0;
		               add_sub_A_1       <= temp_P1;
		               add_sub_B_1       <= temp_P0;
		               //-- R4 = Y2 + X2		                
		               add_sub_mode_2    <= 0;
		               add_sub_A_2       <= temp_Q1;
		               add_sub_B_2       <= temp_Q0;
		               //-- R8 = Z1 x Z2
		               temp_A            <= temp_P2;
		               temp_B            <= temp_Q2;
		           end
		           (3): begin
		               //-- R5 = R1 x R2
		               temp_A            <= add_sub_C_1;
		               temp_B            <= add_sub_C_2;
		               //-- Store R1 and R2
		               temp_R1           <= add_sub_C_1;
		               temp_R2           <= add_sub_C_2;
		               
		               //-- W1 = Y1 - X1
		               add_sub_mode_1    <= 1;
		               add_sub_A_1       <= temp_U1;
		               add_sub_B_1       <= temp_U0;
		               //-- W2 = Y2 - X2		                
		               add_sub_mode_2    <= 1;
		               add_sub_A_2       <= temp_V1;
		               add_sub_B_2       <= temp_V0;
		           end
		           (4): begin
		               //-- R6 = R3 x R4
		               temp_A            <= add_sub_C_1;
		               temp_B            <= add_sub_C_2;
		               //-- Store R3 and R4
		               temp_R3           <= add_sub_C_1;
		               temp_R4           <= add_sub_C_2;
		               //-- W3 = Y1 + X1
		               add_sub_mode_1    <= 0;
		               add_sub_A_1       <= temp_U1;
		               add_sub_B_1       <= temp_U0;
		               //-- W4 = Y2 + X2		                
		               add_sub_mode_2    <= 0;
		               add_sub_A_2       <= temp_V1;
		               add_sub_B_2       <= temp_V0;
		           end
		           (5): begin
		               //-- W7 = T1 x T2
		               temp_A            <= temp_U3;
		               temp_B            <= temp_V3;
		               //-- Store W1 and W2
		               temp_W1           <= add_sub_C_1;
		               temp_W2           <= add_sub_C_2;
		           end
		           (6): begin
		               //-- R7 = K x R7
		               temp_A            <= K;
		               temp_B            <= temp_C;
		               //-- Store R7
		               temp_R7           <= temp_C;
		               //-- Store W3 and W4
		               temp_W3           <= add_sub_C_1;
		               temp_W4           <= add_sub_C_2;
		           end
		           (7): begin
		               //-- R8 = 2 x R8 = R8 + R8 
		               add_sub_mode_2    <= 0;
		               add_sub_A_2       <= temp_C;
		               add_sub_B_2       <= temp_C;
		               //-- Store R8
		               temp_R8           <= temp_C;
		               //-- W8 = Z1 x Z1
		               temp_A            <= temp_U2;
		               temp_B            <= temp_V2;
		           end
		           (8): begin
		               //-- Store R5
		               temp_R5           <= temp_C;
		               //-- W5 = W1 x W2
		               temp_A            <= temp_W1;
		               temp_B            <= temp_W2;
		           end
		           (9): begin
		               //-- R1 = R6 - R5
		               add_sub_mode_1    <= 1;
		               add_sub_A_1       <= temp_C;
		               add_sub_B_1       <= temp_R5;
		               //-- R4 = R6 + R5		                
		               add_sub_A_2       <= temp_C;
		               add_sub_B_2       <= temp_R5;
		               //-- Store R6 and R8
		               temp_R6           <= temp_C;
		               temp_R8           <= add_sub_C_2;
		               //-- W6 = W3 x W4
		               temp_A            <= temp_W3;
		               temp_B            <= temp_W4;
		           end
		           (10): begin
		               //-- W7 = K x W7
		               temp_A            <= K;
		               temp_B            <= temp_C;
		               //-- Store R7
		               temp_W7           <= temp_C;
		           end
                   (11): begin
                       //-- T3 = R1 x R4		                
		               temp_A            <= add_sub_C_1;
		               temp_B            <= add_sub_C_2;
		               //-- R2 = R8 - R7
		               add_sub_A_1       <= temp_R8;
		               add_sub_B_1       <= temp_C;
		               //-- R3 = R8 + R7
                       add_sub_A_2       <= temp_R8;
		               add_sub_B_2       <= temp_C;
		               //-- Store R1, R4 and R7
		               temp_R1           <= add_sub_C_1;
		               temp_R4           <= add_sub_C_2;
		               temp_R7           <= temp_C;
		               //-- Store R7 and R8
		               temp_R7           <= temp_C;
		               temp_R8           <= add_sub_C_2;
		           end
		           (12): begin
		              //-- W8 = 2 x W8 = W8 + W8 
		               add_sub_A_2       <= temp_C;
		               add_sub_B_2       <= temp_C;
		               //-- Store W8
		               temp_W8           <= temp_C;
		           end
                   (13): begin
		               //-- X3 = R1 x R2
		               temp_A            <= temp_R1;
		               temp_B            <= add_sub_C_1;
		               //-- Store R2 and R3
		               temp_R2           <= add_sub_C_1;
		               temp_R3           <= add_sub_C_2;
		               //-- Store W5
		               temp_W5           <= temp_C;
		           end
		           (14): begin
		               //-- Y3 = R3 x R4
		               temp_A            <= temp_R3;
		               temp_B            <= temp_R4;
		               //-- W1 = W6 - W5
		               add_sub_mode_1    <= 1;
		               add_sub_A_1       <= temp_C;
		               add_sub_B_1       <= temp_W5;
		               //-- W4 = W6 + W5		                
		               add_sub_A_2       <= temp_C;
		               add_sub_B_2       <= temp_W5;
		               //-- Store W6 and W8
		               temp_W6           <= temp_C;
		               temp_W8           <= add_sub_C_2;
		           end
		           (15): begin
		               //-- Z3 = R2 x R3
		               temp_A            <= temp_R2;
		               temp_B            <= temp_R3;
		               //-- W2 = W8 - W7
		               add_sub_A_1       <= temp_W8;
		               add_sub_B_1       <= temp_C;
		               //-- W3 = W8 + W7
                       add_sub_A_2       <= temp_W8;
		               add_sub_B_2       <= temp_C;
		               //-- Store W7
		               temp_W7           <= temp_C;
		           end
		           (16): begin
		               //-- FINAL VALUE T3
		               R3             <= temp_C;
		               //-- T3 = W1 x W4		                
		               temp_A            <= add_sub_C_1;
		               temp_B            <= add_sub_C_2;
		               //-- Store W1 and W4
		               temp_W1           <= add_sub_C_1;
		               temp_W4           <= add_sub_C_2;
		           end
		           (17): begin
		               //-- X3 = W1 x W2
		               temp_A            <= temp_W1;
		               temp_B            <= add_sub_C_1;
		               //-- Store W2 and W3
		               temp_W2           <= add_sub_C_1;
		               temp_W3           <= add_sub_C_2;
		           end
                   (18): begin
		               //-- FINAL VALUE X3
		               R0                <= temp_C;
		               //-- Y3 = W3 x W4
		               temp_A            <= temp_W3;
		               temp_B            <= temp_W4;
		           end		            
                   (19): begin
		               //-- FINAL VALUE Y3
		               R1                <= temp_C;
		               //-- Z3 = W2 x W3
		               temp_A            <= temp_W2;
		               temp_B            <= temp_W3;
		           end		
                   
		           (20): begin
		               //-- FINAL VALUE Z3
		               R2                <= temp_C;
                       
                       if (point_mul && pre_calc) begin
                          state <= PRE_POINT_MUL;
                          wr_1  <= 1;
                       end
                       else if (point_mul) begin
                          state <= POINT_MUL;
                       end
                       else if (!point_mul && !double_mul) begin
		                  valid <= 1;
		                  state <= END;
		               end
		           end
		           
		           (21): begin
		               //-- FINAL VALUE T3
		               W3 <= temp_C;
		           end
		           
		           (22): begin
		               //-- FINAL VALUE X3
		               W0 <= temp_C;
		           end
		           
		           (23): begin
		               //-- FINAL VALUE Y3
		               W1 <= temp_C;
		           end
		           
		           (24): begin
		               //-- FINAL VALUE Z3
		               W2 <= temp_C;
                       
                       if (pre_calc) begin
                          wr_1  <= 1;
                          wr_2  <= 1;
                          state <= PRE_POINT_MUL;
                       end
                       else 
                          state <= POINT_MUL;
		           end
		           
		       endcase
		    end
		    
		    
		    //-------------------------------------------
	        //-- SINGLE/DOUBLE POINT MULTIPLICATION     
            //-------------------------------------------
            
            (INIT_PRE_POINT_MUL): begin
                R0 <= P0;
                R1 <= P1;
                R2 <= P2;
                R3 <= P3;
                
                W0 <= Q0;
                W1 <= Q1;
                W2 <= Q2;
                W3 <= Q3;
                
                window_counter_1 <= 1;
			    window_counter_2 <= 1;
            
                state <= PRE_POINT_MUL;
            end
            
            (PRE_POINT_MUL): begin
                temp_Q0 <= R0;
                temp_Q1 <= R1;
                temp_Q2 <= R2;
                temp_Q3 <= R3;
                
                temp_V0 <= W0;
                temp_V1 <= W1;
                temp_V2 <= W2;
                temp_V3 <= W3;
                
                wr_1 <= 0;
                wr_2 <= 0;
                
                if (window_counter_1 < 2**WINDOW_SIZE - 1) begin
                    window_counter_1  <= window_counter_1 + 1;
                    window_counter_2  <= window_counter_2 + 1;
                    state             <= POINT_ADD; 
                end
                else begin
                    rd_1        <= 1;
                    rd_2        <= 1;
                    pre_calc    <= 0;
                    state       <= INIT_POINT_MUL;
                end
                
                add_counter <= 0;
            end
            
            (INIT_POINT_MUL): begin
                R0 <= 0;                  
	            R1 <= 1;                  
	            R2 <= 1;                  
	            R3 <= 0;           
                
                W0 <= 0;                  
	            W1 <= 1;                 
	            W2 <= 1;                 
	            W3 <= 0;
                
                state <= POINT_MUL;
            end
            
            (POINT_MUL): begin
		       add_counter <= 0;
		       
		       window_counter_1 <= bit_window_1;
               window_counter_2 <= bit_window_2;
		       
		       temp_P0 <= R0;
	           temp_P1 <= R1;
	           temp_P2 <= R2;
	           temp_P3 <= R3;
	           
	           temp_U0 <= W0;
	           temp_U1 <= W1;
	           temp_U2 <= W2;
	           temp_U3 <= W3;
		       
		       if (bit_counter < WINDOW_SIZE) begin
                  temp_Q0 <= R0;                 
	              temp_Q1 <= R1;                 
	              temp_Q2 <= R2;                 
	              temp_Q3 <= R3;
		       end
		       else begin
	              temp_Q0 <= data_out_ecc_1[4*BIT_LENGTH-1:3*BIT_LENGTH];                  
	              temp_Q1 <= data_out_ecc_1[3*BIT_LENGTH-1:2*BIT_LENGTH];                  
	              temp_Q2 <= data_out_ecc_1[2*BIT_LENGTH-1:BIT_LENGTH];                    
	              temp_Q3 <= data_out_ecc_1[BIT_LENGTH-1:0];              
		       end
		       /*
		       else if (bit_window_1 != 0) begin
	              temp_Q0 <= data_out_ecc_1[4*BIT_LENGTH-1:3*BIT_LENGTH];                  
	              temp_Q1 <= data_out_ecc_1[3*BIT_LENGTH-1:2*BIT_LENGTH];                  
	              temp_Q2 <= data_out_ecc_1[2*BIT_LENGTH-1:BIT_LENGTH];                    
	              temp_Q3 <= data_out_ecc_1[BIT_LENGTH-1:0];              
		       end
		       else begin
		          temp_Q0 <= 0;
		          temp_Q1 <= 1;
		          temp_Q2 <= 1;
		          temp_Q3 <= 0;
		       end
		       */
		       if (bit_counter < WINDOW_SIZE) begin
	              temp_V0 <= W0;                 
	              temp_V1 <= W1;                 
	              temp_V2 <= W2;                 
	              temp_V3 <= W3;
		       end
		       else begin
	              temp_V0 <= data_out_ecc_2[4*BIT_LENGTH-1:3*BIT_LENGTH];                  
	              temp_V1 <= data_out_ecc_2[3*BIT_LENGTH-1:2*BIT_LENGTH];                  
	              temp_V2 <= data_out_ecc_2[2*BIT_LENGTH-1:BIT_LENGTH];                    
	              temp_V3 <= data_out_ecc_2[BIT_LENGTH-1:0];              
		       end
		       /*
		       else if (bit_window_2 != 0) begin
	              temp_V0 <= data_out_ecc_2[4*BIT_LENGTH-1:3*BIT_LENGTH];                  
	              temp_V1 <= data_out_ecc_2[3*BIT_LENGTH-1:2*BIT_LENGTH];                  
	              temp_V2 <= data_out_ecc_2[2*BIT_LENGTH-1:BIT_LENGTH];                    
	              temp_V3 <= data_out_ecc_2[BIT_LENGTH-1:0];              
		       end
		       else begin
		          temp_V0 <= 0;
		          temp_V1 <= 1;
		          temp_V2 <= 1;
		          temp_V3 <= 0;
		       end
		       */
		       
		       if (bit_counter < WINDOW_SIZE) 
		          bit_counter <= bit_counter + 1;
		       else begin
		          window_block    <= window_block + 1;
		          init_block      <= 0;
		          bit_counter     <= 0;
               end

               if (window_block == WINDOW_BLOCKS && !init_block) begin
                  valid <= 1;
                  state <= END;
               end
               else 
                  state <= POINT_ADD;
		    end           
           
           
	        //-------------------------------------------
	        //-- REDUCTION MOD L     
            //-------------------------------------------
	        
	        (RED_512): begin           
                case (red_state) 
	               (0): begin
	                   if (MP_done) begin
                            red_A       <= Q0;
                            red_B       <= {temp_C[380:0], 4'h0};
                            restart     <= 1;
                            red_state   <= 1;
                       end
	               end
	               (2): begin
	                   temp_A      <= red_C[385:252];
	                   restart     <= 0;
	                   red_sign[0] <= smaller;
	                   red_state   <= 3;
	               end
	               (3): begin
	                   if (MP_done) begin
                            red_A       <= red_C[251:0];
                            red_B       <= temp_C[259:0];
                            restart     <= 1;
                            red_state   <= 4;
                       end
	               end
	               (5): begin
	                   temp_A      <= red_C[259:252];
	                   restart     <= 0;
	                   red_sign[1] <= smaller;
	                   red_state   <= 6;
	               end
	               (6): begin
	                   if (MP_done) begin
                            red_A       <= red_C[251:0];
                            red_B       <= temp_C[134:0];
                            restart     <= 1;
                            red_state   <= 7;
                       end
	               end
	               (8): begin
	                   R0          <= red_C;
	                   red_sign[2] <= smaller;
	                   red_state   <= 9;
	               end
	               (9): begin
	                   //-- red_512 = (red_512_neg) ? ((red_512_minus_2 > L) ? (2*L - red_512_minus_2) : (L - red_512_minus_2)) : ((red_512_minus_2 > L) ? (red_512_minus_2 - L) : red_512_minus_2);
	                   red_A       <= L;
	                   red_B       <= R0;
                       red_state   <= 10;
	               end
	               (11): begin
	                   if (final_sign && smaller) begin   
	                       red_A       <= {L, 1'b0};
	                       red_B       <= R0;
	                       red_state   <= 12;
	                   end
	                   else if (final_sign && !smaller) begin
	                       R0      <= red_C;
	                       valid   <= 1;
	                       state   <= END;
	                   end
	                   else if (!final_sign && smaller) begin
	                       red_A       <= R0;
	                       red_B       <= L;
	                       red_state   <= 12;
	                   end 
	                   else begin              //-- (red_512_minus_2 > L) ? (red_512_minus_2 - L) : red_512_minus_2
	                       valid <= 1;
	                       state <= END;
	                   end
	               end
	               (13): begin
	                   R0      <= red_C;
	                   valid   <= 1;
	                   state   <= END;
	               end
	               
	               default: red_state <= red_state + 1;
	           endcase 
	        end
		    
		    
		    //-------------------------------------------
	        //-- MULTIPLICATION     
            //-------------------------------------------
		    
		    (MUL): begin
		       if (MP_done) begin
		          {R1,R0} <= temp_C;
		          valid   <= 1;
		          state   <= END;
		       end
		    end
		    
		    
		    //-------------------------------------------
	        //-- ADDITION
            //-------------------------------------------
		    
		    (ADD): begin
		       op_counter <= op_counter + 1;
		       
		       if (op_counter == 1) begin
		          R0     <= add_sub_C_1;
		          valid  <= 1;
		          state  <= END;
		       end
		    end
		    
		    
		    //-------------------------------------------
	        //-- POINT EQUAL
            //-------------------------------------------
		    
		    (POINT_EQUAL): begin
		      op_counter <= op_counter + 1;
		      
		       case(op_counter)
		       (5'd0): begin
		          temp_A <= Q0;
		          temp_B <= P2;
		       end
		       (5'd1): begin
		          temp_A <= P1;
		          temp_B <= Q2;
		       end
		       (5'd2): begin
		          temp_A <= Q1;
		          temp_B <= P2;
		       end
		       (5'd4): begin
		          temp_R1 <= temp_C;
		       end
		       (5'd5): begin
		          temp_R2 <= temp_C;
		       end
		       (5'd6): begin
		          temp_R3 <= temp_C;
		          red_A   <= temp_R1;
		          red_B   <= temp_R2;
		       end
		       (6'd7): begin
		          temp_R4 <= temp_C;
		          R0[0]   <= equal;
		       end
		       (6'd7): begin
		          red_A <= temp_R3;
		          red_B <= temp_R4;
		       end
		       (6'd8): begin
		          R0[0] <= equal & R0[0];
		          valid <= 1;
		          state <= END;
		       end
		       
		       endcase
		    end
		    
		    
		    //-------------------------------------------
	        //-- POINT COMPRESS
            //-------------------------------------------
		    
		    (POINT_COMPRESS): begin
		       op_counter <= op_counter + 1;
		       restart    <= 0;
		       
		       if (op_counter == 0) begin
		           temp_A <= P0;
		           temp_B <= R0;
		       end
		       else if (op_counter == 1) begin
		           temp_A <= P1;
		           temp_B <= R0;
		       end
		       else if (op_counter == 5) begin
		           R0 <= temp_C; 
		       end
		       else if (op_counter == 6) begin
		           R0 <= {R0[0], temp_C[BIT_LENGTH-2:0]};
		           if (R0[BIT_LENGTH-1]) 
		               error <= 1;
		           else 
		               valid <= 1;
		               
		           state <= END;
		       end
		    end
		    
		    
		    //-------------------------------------------
	        //-- POINT DECOMPRESS
            //-------------------------------------------
		    
		    (RECOVER_X): begin
		       op_counter <= op_counter + 1;
		     
		       case(op_counter)
		       //-- y*y
		       (6'd0): begin
		          red_A <= R1;
		          red_B <= P;
		          
		          temp_A <= R1;
		          temp_B <= R1;
		       end
		       (6'd1): begin
		          if (bigger) begin
		              error <= 1;
		              state <= END;
		          end
		       end
		       //-- d*y*y | u = y*y-1
		       (6'd5): begin
		          add_sub_A_1 <= temp_C;
		          add_sub_B_1 <= 1;
		          
		          temp_A <= temp_C;
		          temp_B <= D;
		       end
		       //-- Store R1 = u | -u 
		       (6'd7): begin
		          temp_R1 <= add_sub_C_1;
		          
		          add_sub_A_1 <= P;
		          add_sub_B_1 <= add_sub_C_1;
		       end
		       //-- Store R2 = -u
		       (6'd9): begin
		          temp_R2 <= add_sub_C_1;
		       end
		       //-- v = d*y*y+1
		       (6'd10): begin
		          add_sub_A_1     <= temp_C;
		          add_sub_B_1     <= 1;
		          add_sub_mode_1  <= 0; 
		       end
		       //-- Store R3 = v | v^2 = v*v
		       (6'd12): begin
		          temp_R3        <= add_sub_C_1;
		          add_sub_mode_1 <= 1;
		          
		          temp_A <= add_sub_C_1;
		          temp_B <= add_sub_C_1;
		       end
		       //-- v^3 = v^2*v
		       (6'd17): begin
		          temp_A <= temp_C;
		          temp_B <= temp_R3;
		       end
		       //-- Store R4 = v^3 | u*v^3
		       (6'd22): begin
		          temp_R4 <= temp_C;
		          
		          temp_A <= temp_C;
		          temp_B <= temp_R1;
		       end
		       //-- Store R4 = u*v^3 | u*v^6 = u*^v^3+v^3
		       (6'd27): begin
		          temp_R4 <= temp_C;
		       
		          temp_A <= temp_C;
		          temp_B <= temp_R4;
		       end
		       //-- u*v^7 = u*v^6*v
		       (6'd32): begin
		          temp_A <= temp_C;
		          temp_B <= temp_R3;
		       end
		       //-- Store u*v^7 and send to EXP
		       (6'd37): begin
		          R0      <= temp_C;
		          temp_P0 <= temp_C;
		          restart <= 1;
		          state   <= EXP_SELECT;  
		       end
		       //-- Compute square root candidate x = (u * v^3) * (u * v^7) ^ ((p-5)/8)
		       (6'd38): begin
		          temp_A <= temp_R4;
		          temp_B <= R0;
		          
		          restart <= 0;
		       end
		       //-- Store R0 = x | x^2 = x*x
		       (6'd43): begin
		          R0     <= temp_C;
		          
		          temp_A <= temp_C;
		          temp_B <= temp_C;
		       end
		       //-- v*x^2
		       (6'd48): begin
		          temp_A <= temp_C;
		          temp_B <= temp_R3;
		       end
		       //-- Store R5 = v*x^2 | Compare v*x^2 == -u
		       (6'd53): begin
		          temp_R5 <= temp_C;
		          
		          red_A <= temp_C;
		          red_B <= temp_R2;
		       end
		       //-- Check comparison
		       (6'd54): begin
		          if (equal) begin //-- x = x * 2^((p-1)/4)
		              temp_A <= R0;
		              temp_B <= SQRT_1;
		              
		              dec_minus_u <= 1;
		          end
		          else begin //-- Compare v*x^2 == u
		              red_A <= temp_R5;
		              red_B <= temp_R1;
		          end
		       end
		       //-- Check comparison II
		       (6'd55): begin
		          if (!equal && !dec_minus_u) begin //-- ERROR
		              error <= 1;
		              state <= END;
		          end
		          else if (equal && (R0[0] != x_0)) begin //-- x = P - x
		              add_sub_A_1 <= P;
		              add_sub_B_1 <= R0;
		          end
		          else if (equal && !dec_minus_u) begin
		              restart <= 1;
		              state   <= POINT_DECOMPRESS;
		          end
		       end
		       (6'd57): begin
		          if (!dec_minus_u) begin 
		              R0      <= add_sub_C_1;
		              restart <= 1;
		              state   <= POINT_DECOMPRESS;
		          end
		       end
		       //-- If v*x^2 == -u then store new x
		       (6'd59): begin
		          if (temp_C[0] != x_0) begin //-- x = P - x
		              add_sub_A_1 <= P;
		              add_sub_B_1 <= temp_C;
		          end
		          else begin
		              R0      <= temp_C;
		              restart <= 1;
		              state   <= POINT_DECOMPRESS;
		          end
		       end
		       (6'd61): begin
		          R0      <= add_sub_C_1;
		          restart <= 1;
		          state   <= POINT_DECOMPRESS;
		       end
		       
		       endcase
		    end
		    
	        (POINT_DECOMPRESS): begin
	           R2 <= 1;
	           
	           temp_A  <= R0;
	           temp_B  <= R1;    
	              
	           restart <= 0;
	            
	           if (MP_done) begin
	               R3      <= temp_C;
	               valid   <= 1;
	               state   <= END;
	           end
	        end
	        
		    
		    //-------------------------------------------
	        //-- END   
            //-------------------------------------------
		    
		    (END): begin
               redux   <= 1;
               restart <= 1;
           
               point_mul    <= 0;
               double_mul   <= 0;
               add_counter  <= 0;
            
               compress    <= 0;
               decompress  <= 0;
               dec_minus_u <= 0;
	        
	           red_A      <= 0;
	           red_B      <= 0;
	           red_state  <= 0;
	           red_sign   <= 0;
	        
			   wr_1             <= 0;
			   rd_1             <= 0;
			   wr_2             <= 0;
			   rd_2             <= 0;
			   
			   window_counter_1 <= 0;
			   window_counter_2 <= 0;
			   
			   pre_calc         <= 0;
			   bit_counter      <= 0;
			   init_block       <= 1;
			   window_block     <= 0;
			   
			   chain_counter    <= 0;
			   chain_square     <= 1;
			   
			   error   <= 0;
			   valid   <= 0;
			   state   <= IDLE;
		    end
		    
		endcase
		end
	end
	
endmodule
