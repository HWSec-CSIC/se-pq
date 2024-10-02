/**
  * @file X25519.v
  * @brief X25519 Cryptocore
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

// `default_nettype none

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 05/07/2024
// Design Name: X25519.v
// Module Name: X25519
// Project Name: X25519 Cryptocore
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		X25519 Cryptocore
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module X25519 #(
                parameter BIT_LENGTH = 256,
                parameter n_LEVEL    = 2                    //-- Recursion Levels           
                )
                (
				//-- Clock and Reset Signals
				input  wire clk,					
				input  wire rst,			
				//-- Scalar k
				input wire [BIT_LENGTH-1:0] scalar,
				//-- u-coordinate from Point P
				input wire [BIT_LENGTH-1:0] point_in,
				//-- u-coordinate from Point R = [k]P
				output reg [BIT_LENGTH-1:0] point_out,
				//-- Output is valid
				output reg valid
				);
  
    
    //------------------------------------------------------------------------------------------------
	//-- Parameters             
	//------------------------------------------------------------------------------------------------

	//-- Curve Parameter A24 = (A-2)/4
	localparam A24 = 256'd121665;
	

	//------------------------------------------------------------------------------------------------
	//-- Wires and Registers               
	//------------------------------------------------------------------------------------------------
	
	//-- Scalar and Point Decoded
	wire [BIT_LENGTH-1:0] scalar_dec;
	wire [BIT_LENGTH-1:0] point_dec;
	
	assign scalar_dec = {2'b01, scalar[5:0], scalar[15:8], scalar[23:16], scalar[31:24], scalar[39:32], scalar[47:40], scalar[55:48], scalar[63:56], scalar[71:64], scalar[79:72], scalar[87:80], scalar[95:88],
                               scalar[103:96], scalar[111:104], scalar[119:112], scalar[127:120], scalar[135:128], scalar[143:136], scalar[151:144], scalar[159:152], scalar[167:160], scalar[175:168], 
                               scalar[183:176], scalar[191:184], scalar[199:192], scalar[207:200], scalar[215:208], scalar[223:216], scalar[231:224], scalar[239:232], scalar[247:240], scalar[255:251], 3'b000};
    
    assign point_dec = {1'b0, point_in[6:0], point_in[15:8], point_in[23:16], point_in[31:24], point_in[39:32], point_in[47:40], point_in[55:48], point_in[63:56], point_in[71:64], point_in[79:72], point_in[87:80], point_in[95:88],
                               point_in[103:96], point_in[111:104], point_in[119:112], point_in[127:120], point_in[135:128], point_in[143:136], point_in[151:144], point_in[159:152], point_in[167:160], point_in[175:168], 
                               point_in[183:176], point_in[191:184], point_in[199:192], point_in[207:200], point_in[215:208], point_in[223:216], point_in[231:224], point_in[239:232], point_in[247:240], point_in[255:248]};
	
	//-- Point Coordinates
	reg [BIT_LENGTH-1:0] x_1;
	reg [BIT_LENGTH-1:0] x_2;
	reg [BIT_LENGTH-1:0] x_3;
	reg [BIT_LENGTH-1:0] z_2;
    reg [BIT_LENGTH-1:0] z_2_inv;
	reg [BIT_LENGTH-1:0] z_3;
	//-- Temporary Intermediate Values
	reg [BIT_LENGTH-1:0] temp_R1;
	reg [BIT_LENGTH-1:0] temp_R2;
	reg [BIT_LENGTH-1:0] temp_R3;
	reg [BIT_LENGTH-1:0] temp_R4;
	reg [BIT_LENGTH-1:0] temp_R5;

    //-- Scalar Bits & Ladder Counter
	reg [7:0] bit_counter;
	reg [4:0] ladder_counter;
	wire scalar_bit;
	
	assign scalar_bit = (bit_counter < 255) ? scalar_dec[bit_counter] : scalar_dec[0];
	
	//-- Conditional Swap
	reg swap;
	wire swap_xor;
	wire [BIT_LENGTH-1:0] cswap_x_2;
	wire [BIT_LENGTH-1:0] cswap_x_3;
	wire [BIT_LENGTH-1:0] cswap_z_2;
	wire [BIT_LENGTH-1:0] cswap_z_3;
	
	assign swap_xor = swap ^ scalar_bit;
	
	assign cswap_x_2 = (swap_xor) ? x_3 : x_2;
	assign cswap_x_3 = (swap_xor) ? x_2 : x_3;
	assign cswap_z_2 = (swap_xor) ? z_3 : z_2;
	assign cswap_z_3 = (swap_xor) ? z_2 : z_3;
	
    
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
	
	
	//--------------------------------------------------------------------------------------------------------------------
	//-- Addition Chains for Exponentiation
	//--------------------------------------------------------------------------------------------------------------------
	
	reg [8:0] chain_counter;
	reg chain_square;
	
	
	//--------------------------------------------------------------------------------------------------------------------
	//-- Logic Controller               
	//--------------------------------------------------------------------------------------------------------------------	
	
	localparam IDLE 				   = 0;
	//-- CONDITIONAL SWAP
	localparam CSWAP                   = 1;
	//-- SCALAR MULTIPLICATION
	localparam SCALAR_MUL              = 2;
	//-- INVERSION
	localparam INV_SELECT              = 3;
	localparam INVERSION               = 4;
	//-- FINAL MULTIPLICATION
	localparam LAST_MUL                = 5;
	//-- END
	localparam END  				   = 6;
	
	reg [2:0] state;
	
	always @(posedge clk) begin
		if (rst) begin
			x_1 <= point_dec;
			x_2 <= 1;
			x_3 <= point_dec;
			z_2 <= 0;
			z_3 <= 1;

            temp_R1 <= 0;
            temp_R2 <= 0;
            temp_R3 <= 0;
            temp_R4 <= 0;
            temp_R5 <= 0;
            
            bit_counter     <= 254;
            ladder_counter  <= 1;
            
            swap <= 0;  
			
			temp_A  <= 0;
			temp_B  <= 0;
			
            redux   <= 1;
            restart <= 1;
			
			chain_counter    <= 0;
			chain_square     <= 1;
			
			point_out    <= 0;
			valid        <= 0;
			state        <= IDLE;
		end
		else begin
		case (state)
		    
		    //-------------------------------------------
	        //-- IDLE STATE     
            //-------------------------------------------
		    
		    (IDLE): begin               
		       x_1 <= point_dec;
			   x_2 <= 1;
			   x_3 <= point_dec;
			   z_2 <= 0;
			   z_3 <= 1;  
		       
		       bit_counter    <= 254;
		       ladder_counter <= 1;
		       
		       swap <= 0;
		       
		       state <= CSWAP;
		    end
		    
		    
		    //-------------------------------------------
	        //-- CONDITIONAL SWAP
            //-------------------------------------------
		    
		    (CSWAP): begin
		       x_2 <= cswap_x_2;
		       x_3 <= cswap_x_3;
		       z_2 <= cswap_z_2;
		       z_3 <= cswap_z_3;
		       
		       swap <= scalar_bit;
		       
		       restart        <= 1;
		       ladder_counter <= 1;
		       
		       if (bit_counter < 255)
		          state <= SCALAR_MUL;
		       else 		          
		          state <= INV_SELECT;
		    end 
		    
		    
		    //-------------------------------------------
	        //-- SCALAR MULTIPLICATION
            //-------------------------------------------
		    
		    (SCALAR_MUL): begin
		      
		       ladder_counter <= ladder_counter + 1;
		       restart        <= 0;
		      
		       case (ladder_counter)
		           (1): begin
		               //-- R1 = X2 + Z2 (A)
		               add_sub_mode_1    <= 0;
		               add_sub_A_1       <= x_2;
		               add_sub_B_1       <= z_2;
		               //-- R2 = X2 - Z2 (B)		                
		               add_sub_mode_2    <= 1;
		               add_sub_A_2       <= x_2;
		               add_sub_B_2       <= z_2;
		           end
		           (2): begin
		               //-- R3 = X3 + Z3 (C)
		               add_sub_A_1       <= x_3;
		               add_sub_B_1       <= z_3;
		               //-- R4 = X3 - Z3 (D)		                
		               add_sub_A_2       <= x_3;
		               add_sub_B_2       <= z_3;
		           end
		           (3): begin
		               //-- R1 = R1 x R1 (AA)
		               temp_A            <= add_sub_C_1;
		               temp_B            <= add_sub_C_1;
		               //-- Store R1 and R2
		               temp_R1           <= add_sub_C_1;
		               temp_R2           <= add_sub_C_2;
		           end
		           (4): begin
		               //-- R2 x R2      (BB)
		               temp_A            <= temp_R2;
		               temp_B            <= temp_R2;
		               //-- Store R3 and R3
		               temp_R3           <= add_sub_C_1;
		               temp_R4           <= add_sub_C_2;
		           end
		           (5): begin
		               //-- R4 x R1       (DA)
		               temp_A            <= temp_R4;
		               temp_B            <= temp_R1;
		           end
		           (6): begin
		               //-- R3 x R2       (CB)
		               temp_A            <= temp_R3;
		               temp_B            <= temp_R2;
		           end
		           // (7): 
		           (8): begin
		               //-- Store R1 = R1 x R1    (AA)
		               temp_R1           <= temp_C; 
		           end
		           (9): begin
		               //-- X2 = R1 x temp_C      (X2 = AA x BB)
		               temp_A            <= temp_R1;
		               temp_B            <= temp_C;
		               //-- R5 = R1 - temp_C      (E = AA - BB)
		               add_sub_A_2       <= temp_R1;
		               add_sub_B_2       <= temp_C;
		           end
		           (10): begin
		               //-- Store R2 = R4 x R1    (R2 = DA)
		               temp_R2           <= temp_C;
		           end
		           (11): begin
		               //-- A24 x R5      (A24 x E)
		               temp_A            <= A24;
		               temp_B            <= add_sub_C_2;
		               //-- Store R5 = E  (R5 = E)
		               temp_R5           <= add_sub_C_2;
		               //-- R2 + temp_C   (DA + CB)
		               add_sub_A_1       <= temp_R2;
		               add_sub_B_1       <= temp_C;
		               //-- R2 - temp_C   (DA - CB)
		               add_sub_A_2       <= temp_R2;
		               add_sub_B_2       <= temp_C;
		           end
		           // (12):
		           (13): begin
		               //-- ((DA - CB) x (DA - CB))
		               temp_A            <= add_sub_C_2;
		               temp_B            <= add_sub_C_2;
		               //-- Store R3 = DA + CB
		               temp_R3           <= add_sub_C_1;
		           end
		           (14): begin
		               //-- R3 x R3       ((DA + CB) x (DA + CB))      
		               temp_A            <= temp_R3;
		               temp_B            <= temp_R3;
		               //-- Store X2 = AA x BB
		               x_2               <= temp_C;
		           end
		           // (15):
		           (16): begin
		               //-- R1 + (A24 x R5)   (AA + A24 x E)
		               add_sub_A_1       <= temp_R1;
		               add_sub_B_1       <= temp_C;
		           end
		           // (17):
		           (18): begin
		               //-- X1 x (DA - CB)^2
		               temp_A            <= x_1;
		               temp_B            <= temp_C;
		               //-- Store R3 = R1 + (A24 x R5) (AA + A24 x E)
		               temp_R3           <= add_sub_C_1;
		           end
		           (19): begin
		               //-- R5 x R3       (E x (AA + A24 x E))
		               temp_A            <= temp_R5;
		               temp_B            <= temp_R3;
		               //-- Store X3 = R3 x R3 (X3)
		               x_3               <= temp_C;
		           end
		           // (20):
		           // (21):
		           // (22):
		           (23): begin
		               //-- Store Z3 = X1 x (DA - CB)^2
		               z_3               <= temp_C;
		           end
		           (24): begin
		               //-- Store Z2 = R5 x R3    (Z2 = (E x (AA + A24 x E)))
		               z_2               <= temp_C;
		               z_2_inv           <= temp_C;
		               //-- Return to Conditional Swapping
		               bit_counter       <= bit_counter - 1;
		               if (bit_counter == 0)
		                  swap <= 0;
		                  
		               state             <= CSWAP;
		           end
		       endcase
		       
		    end 
		    
		    //-------------------------------------------
	        //-- MODULAR EXPONENTIATION     
            //-------------------------------------------
            
            (INV_SELECT): begin
               temp_A <= z_2_inv;
               
               if (chain_square)
		          temp_B <= z_2_inv; 
		       else begin
		          temp_B <= temp_R1;
                  chain_square <= 1;
               end
               
               restart  <= 0;
               state    <= INVERSION;
            end
            
            (INVERSION): begin
               if (MP_done) begin
                  restart         <= 1;
                  chain_counter   <= chain_counter + 1;
                  z_2_inv         <= temp_C;
               end 
               
               case (chain_counter)
               //-- Square 1 time and store _10
               (9'd0): temp_R2 <= temp_C;
               //-- Square 2 times and multiply by _1
               (9'd2): begin
                  temp_R1       <= z_2;     //-- z_2 saves initial state
                  chain_square  <= 0;
               end
               //-- Store _1001 and multiply by _10
               (9'd3): begin
                  temp_R3 <= temp_C;
                  temp_R1 <= temp_R2;
                  chain_square  <= 0;
               end
               //-- Store _1011
               (9'd4): temp_R4 <= temp_C;
               //-- Square 1 time and multiply by _1001
               (9'd5): begin
                  temp_R1       <= temp_R3;
                  chain_square  <= 0;
               end
               //-- Store x5
               (9'd6): temp_R2 <= temp_C;
               //-- Square 5 times and multiply by x5
               (9'd11): begin
                  temp_R1       <= temp_R2;
                  chain_square  <= 0;
               end
               //-- Store x10
               (9'd12): temp_R2 <= temp_C;
               //-- Square 10 times and multiply by x10
               (9'd22): begin
                  temp_R1       <= temp_R2;
                  chain_square  <= 0;
               end
               //-- Store x20
               (9'd23): temp_R3 <= temp_C;
               //-- Square 20 times and multiply by x20
               (9'd43): begin
                  temp_R1       <= temp_R3;
                  chain_square  <= 0;
               end
               //-- Store x40
               // (9'd44): temp_W7 <= temp_C;
               //-- Square 10 times and multiply by x10
               (9'd54): begin
                  temp_R1       <= temp_R2;
                  chain_square  <= 0;
               end
               //-- Store x50
               (9'd55): temp_R3 <= temp_C;
               //-- Square 50 times and multiply by x50
               (9'd105): begin
                  temp_R1       <= temp_R3;
                  chain_square  <= 0;
               end
               //-- Store x100
               (9'd106): temp_R2 <= temp_C;
               //-- Square 100 times and multiply by x100
               (9'd206): begin
                  temp_R1       <= temp_R2;
                  chain_square  <= 0;
               end
               //-- Square 50 times and multiply by x50
               (9'd257): begin
                  temp_R1       <= temp_R3;
                  chain_square  <= 0;
               end
               //-- Square 5 times and multiply by _1011 if Inversion
               (9'd263): begin 
                  temp_R1       <= temp_R4;
                  chain_square  <= 0;
               end
               //-- End exponentiation if Inversion
               // (9'd264):
               endcase 
               
               if (chain_counter == 264 && MP_done) begin
                  state <= LAST_MUL;
               end
               else if (MP_done) 
                  state <= INV_SELECT;
            end
	        
	        //-------------------------------------------
	        //-- FINAL MULTIPLICATION   
            //-------------------------------------------
		    
		    (LAST_MUL): begin
               restart <= 0;
            
               temp_A <= x_2;
               temp_B <= z_2_inv;
               
               if (MP_done) begin
                  point_out <= {temp_C[7:0], temp_C[15:8], temp_C[23:16], temp_C[31:24], temp_C[39:32], temp_C[47:40], temp_C[55:48], temp_C[63:56], temp_C[71:64], temp_C[79:72], temp_C[87:80], temp_C[95:88],
                                temp_C[103:96], temp_C[111:104], temp_C[119:112], temp_C[127:120], temp_C[135:128], temp_C[143:136], temp_C[151:144], temp_C[159:152], temp_C[167:160], temp_C[175:168], 
                                temp_C[183:176], temp_C[191:184], temp_C[199:192], temp_C[207:200], temp_C[215:208], temp_C[223:216], temp_C[231:224], temp_C[239:232], temp_C[247:240], temp_C[255:248]};
                  
                  valid <= 1;
			      state <= END;
               end
		    end
		    
		    
		    //-------------------------------------------
	        //-- END   
            //-------------------------------------------
		    
		    /*
		    (END): begin
              
		    end
		    */
		endcase
		end
	end
	
endmodule
