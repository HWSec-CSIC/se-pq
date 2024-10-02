/**
  * @file EdDSA.v
  * @brief EDSA25519 Cryptocore
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
// Create Date: 02/04/2024
// Design Name: EdDSA.v
// Module Name: EdDSA
// Project Name: EDSA25519 Cryptocore
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		EdDSA25519 Cryptocore
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module EdDSA #(
               localparam BIT_LENGTH = 256,
               localparam WIDTH      = 64,
               localparam SIZE_BLOCK = 1024
               )
               (
				//-- Clock and Reset Signals
				input wire clk,					
				input wire rst,
				//-- Valid Block send for hash. For each new valid block it must change from (1,0) to (0,1)
				input wire [1:0] block_valid,           			
				//-- Operation Select (0 = IDLE | 1 = KEY_GEN | 2 = SIGNING | 3 = VERIFICATION)
				input wire [1:0] sel,
                //-- Private Key
				input wire [BIT_LENGTH-1:0] private,
				//-- Public Key
				input wire [BIT_LENGTH-1:0] public,
				//-- Message
				input wire [SIZE_BLOCK-1:0] message,
				input wire [WIDTH-1:0] len_message,
				//-- Signature for Verification
				input wire [2*BIT_LENGTH-1:0] sig_ver,
				//-- Signature & Public Key
				output reg [2*BIT_LENGTH-1:0] sig_pub,
				//-- Error & Valid. (verify) ? Valid : Error
				output reg error,
				output reg valid,
				//-- Ready to receive new Block for Hash
				output reg block_ready
				);
    
    
    //------------------------------------------------------------------------------------------------
	//-- Parameters             
	//------------------------------------------------------------------------------------------------
    
    //-- SHA2-512 Parameters
    localparam MAX_H        = 8;
    localparam MODE         = 512;
    localparam T            = 0;
    localparam OUTPUT_SIZE  = MODE;
    
    //-- Prime Field Size p = 2**255-19
	localparam P       = 256'h7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
	//-- Curve Constant d
	localparam D       = 256'h52036cee_2b6ffe73_8cc74079_7779e898_00700a4d_4141d8ab_75eb4dca_135978a3;
	//-- K = 2d
	localparam K       = 256'h2406d9dc_56dffce7_198e80f2_eef3d130_00e0149a_8283b156_ebd69b94_26b2f159;
	//-- Base Coordinates
	localparam G_X     = 256'h216936d3_cd6e53fe_c0a4e231_fdd6dc5c_692cc760_9525a7b2_c9562d60_8f25d51a;
	localparam G_Y     = 256'h66666666_66666666_66666666_66666666_66666666_66666666_66666666_66666658;
	localparam G_Z     = 256'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001;
	localparam G_T     = 256'h67875f0f_d78b7665_66ea4e8e_64abe37d_20f09f80_775152f5_6dde8ab3_a5b7dda3;
	//-- Prime Order of the Base Point
	localparam L       = 256'h10000000_00000000_00000000_00000000_14def9de_a2f79cd6_5812631a_5cf5d3ed;
	//-- Square Root of -1 [2^((p-1)/4)]
	localparam SQRT_1  = 256'h2b832480_4fc1df0b_2b4d0099_3dfbd7a7_2f431806_ad2fe478_c4ee1b27_4a0ea0b0;
	//-- (P-5)/8
	localparam P_58    = 256'h0fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_fffffffd;
    
    
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------

	//-- Operation Counter
	reg [5:0] op_counter;
	//-- Change Endianness
	reg [2*BIT_LENGTH-1:0] ch_endian;
	
	wire [BIT_LENGTH-1:0] changed_endian_256;
	assign changed_endian_256 = {ch_endian[7:0], ch_endian[15:8], ch_endian[23:16], ch_endian[31:24], ch_endian[39:32], ch_endian[47:40], ch_endian[55:48], ch_endian[63:56], ch_endian[71:64], ch_endian[79:72], ch_endian[87:80], ch_endian[95:88],
                             ch_endian[103:96], ch_endian[111:104], ch_endian[119:112], ch_endian[127:120], ch_endian[135:128], ch_endian[143:136], ch_endian[151:144], ch_endian[159:152], ch_endian[167:160], ch_endian[175:168], 
                             ch_endian[183:176], ch_endian[191:184], ch_endian[199:192], ch_endian[207:200], ch_endian[215:208], ch_endian[223:216], ch_endian[231:224], ch_endian[239:232], ch_endian[247:240], ch_endian[255:248]};
	
    wire [2*BIT_LENGTH-1:0] changed_endian_512;  
    assign changed_endian_512 = {ch_endian[7:0], ch_endian[15:8], ch_endian[23:16], ch_endian[31:24], ch_endian[39:32], ch_endian[47:40], ch_endian[55:48], ch_endian[63:56], ch_endian[71:64], ch_endian[79:72], ch_endian[87:80], ch_endian[95:88],
                                 ch_endian[103:96], ch_endian[111:104], ch_endian[119:112], ch_endian[127:120], ch_endian[135:128], ch_endian[143:136], ch_endian[151:144], ch_endian[159:152], ch_endian[167:160], ch_endian[175:168], 
                                 ch_endian[183:176], ch_endian[191:184], ch_endian[199:192], ch_endian[207:200], ch_endian[215:208], ch_endian[223:216], ch_endian[231:224], ch_endian[239:232], ch_endian[247:240], ch_endian[255:248],
                                 ch_endian[263:256], ch_endian[271:264], ch_endian[279:272], ch_endian[287:280], ch_endian[295:288], ch_endian[303:296], ch_endian[311:304], ch_endian[319:312], ch_endian[327:320], ch_endian[335:328],
                                 ch_endian[343:336], ch_endian[351:344], ch_endian[359:352], ch_endian[367:360], ch_endian[375:368], ch_endian[383:376], ch_endian[391:384],ch_endian[399:392], ch_endian[407:400],ch_endian[415:408], 
                                 ch_endian[423:416], ch_endian[431:424], ch_endian[439:432], ch_endian[447:440], ch_endian[455:448], ch_endian[463:456],ch_endian[471:464],ch_endian[479:472], ch_endian[487:480], ch_endian[495:488],
                                 ch_endian[503:496], ch_endian[511:504]};
    
    
    //--------------------------------------
	//-- EdDSA Accelerator          
	//--------------------------------------
    
	reg  [3:0] sel_op;
	//-- Operands Value
	reg  [BIT_LENGTH-1:0] P0;
	reg  [BIT_LENGTH-1:0] Q0;
	reg  [BIT_LENGTH-1:0] P1;
	reg  [BIT_LENGTH-1:0] Q1;
	reg  [BIT_LENGTH-1:0] P2;
	reg  [BIT_LENGTH-1:0] Q2;
	reg  [BIT_LENGTH-1:0] P3;
	reg  [BIT_LENGTH-1:0] Q3;
	//-- Scalars
	reg  [BIT_LENGTH-1:0] S1;
	reg  [BIT_LENGTH-1:0] S2;
	//-- Results
	wire [BIT_LENGTH-1:0] R0;
	wire [BIT_LENGTH-1:0] R1;
	wire [BIT_LENGTH-1:0] R2;
	wire [BIT_LENGTH-1:0] R3;
	wire [BIT_LENGTH-1:0] W0;
	wire [BIT_LENGTH-1:0] W1;
	wire [BIT_LENGTH-1:0] W2;
	wire [BIT_LENGTH-1:0] W3;
	
	wire valid_op;
	wire error_op;
	
	EdDSA_Acc ACCELERATOR(
				          .clk(clk),
				          .rst(rst),
				          .sel(sel_op),
				          .P0(P0),
				          .Q0(Q0),
				          .P1(P1),
				          .Q1(Q1),
				          .P2(P2),
				          .Q2(Q2),
				          .P3(P3),
				          .Q3(Q3),
				          .S1(S1),
				          .S2(S2),
				          .R0(R0),
				          .R1(R1),
				          .R2(R2),
				          .R3(R3),
				          .W0(W0),
				          .W1(W1),
				          .W2(W2),
				          .W3(W3),
				          .valid(valid_op),
				          .error(error_op)
				          ); 
	
	
	//--------------------------------------
	//-- SHA2-512         
	//--------------------------------------
	
    reg  rst_H;
	reg  [3:0] control;
	reg  [4:0] addr;
	reg  [WIDTH-1:0] data_in;
	wire [WIDTH-1:0] data_out;
	wire valid_H;
	
	sha2_xl_eddsa #(
                    .WIDTH(WIDTH),
                    .MODE(MODE),
                    .T(T)
                    )
                    SHA_512
                    (
                     .i_clk(clk), 
                     .i_rst(rst_H), 
                     .i_data_in(data_in), 
                     .i_add(addr), 
                     .i_control(control), 
                     .o_data_out(data_out), 
                     .o_end_op(valid_H)
                     );
    
    reg  [SIZE_BLOCK-1:0] w_data_in;
	reg  [WIDTH-1:0] length;
	reg  [3:0] hash_op_counter;
	wire [WIDTH-1:0] length_h;
	wire [WIDTH-1:0] hash_blocks;
	reg  [WIDTH-1:0] remain_blocks;
	reg  init_block;
    reg  last_block;
    reg  [MODE-1:0] hash;
    
    always @(*) begin
        if (rst)
            w_data_in <= 0;
        else if (sel == 1)
            w_data_in <= {private, 768'h0};
        else if (sel == 2 && op_counter == 1)
            w_data_in <= {private, 768'h0};
        else if (sel == 2 && op_counter == 4 && init_block)
            w_data_in <= {Q2, message[SIZE_BLOCK-1:BIT_LENGTH]};
        else if (sel == 2 && op_counter == 4 && !init_block)
            w_data_in <= message;
        else if (sel == 2 && op_counter == 11 && init_block)
            w_data_in <= {sig_pub[2*BIT_LENGTH-1:BIT_LENGTH], public, message[SIZE_BLOCK-1:2*BIT_LENGTH]};
        else if (sel == 2 && op_counter == 11 && !init_block)
            w_data_in <= message;
        else if (sel == 3 && op_counter == 2 && init_block)
            w_data_in <= {sig_ver[2*BIT_LENGTH-1:BIT_LENGTH], public, message[SIZE_BLOCK-1:2*BIT_LENGTH]};
        else if (sel == 3 && op_counter == 2 && !init_block)
            w_data_in <= message;
        else
            w_data_in <= 0;
    end
    
    /*
    always @(*) begin
        if (rst)
            w_data_in <= 0;
        else if (sel == 1 || (sel == 2 && op_counter == 1))
            w_data_in <= {private, 768'h0};
        *//*
        else if (sel == 2 && op_counter == 1)
            w_data_in <= {private, 768'h0};
        */
        
        /*
        else if (sel == 2 && op_counter == 4 && init_block)
            w_data_in <= {Q2, message[SIZE_BLOCK-1:BIT_LENGTH]};
        
        else if (((sel == 2 && op_counter == 4) || (sel == 2 && op_counter == 11) || (sel == 3 && op_counter == 2)) && !init_block)
            w_data_in <= message;
        
        else if (((sel == 2 && op_counter == 11) || (sel == 3 && op_counter == 2)) && init_block)
            w_data_in <= {sig_pub[2*BIT_LENGTH-1:BIT_LENGTH], public, message[SIZE_BLOCK-1:2*BIT_LENGTH]};
        */
        
        /*    
        else if (sel == 2 && op_counter == 11 && !init_block)
            w_data_in <= message;
        */
        /*
        else if (sel == 3 && op_counter == 2 && init_block)
            w_data_in <= {sig_ver[2*BIT_LENGTH-1:BIT_LENGTH], public, message[SIZE_BLOCK-1:2*BIT_LENGTH]};
        */
        /*
        else if (sel == 3 && op_counter == 2 && !init_block)
            w_data_in <= message;
        */   
        /*
        else
            w_data_in <= 0;
    end
    */
    
    assign length_h     = length + {WIDTH, 1'b0} ; 
    assign hash_blocks  = {10'b0, length_h[WIDTH-1:10]} + 1;            //-- Divide by 1024 = 2**10
    
    reg odd_block;

	
	//-------------------------------------------
	//-- Logic Controller               
	//-------------------------------------------	
	
	localparam IDLE        = 0;
	localparam GEN_KEY     = 1;
	localparam SIGN        = 2;
	localparam VERIFY      = 3;
	localparam HASH        = 4;
	localparam DATA_BLOCK  = 5;
	localparam WAIT_OP     = 6;
	localparam END         = 7;
	
	reg [2:0] state;
	
	always @(posedge clk) begin
	   if (rst) begin
            sel_op  <= 0;
            
            P0 <= 0;
            Q0 <= 0;
            P1 <= 0;
            Q1 <= 0;
            P2 <= 0;
            Q2 <= 0;
            P3 <= 0;
            Q3 <= 0;
               
            S1 <= 0;
            S2 <= 0;
            
            ch_endian <= 0;
            
            rst_H   <= 0;
            control <= 1;
            addr    <= 0;
            data_in <= 0;
            
            hash            <= 0;
            length          <= 0;
            hash_op_counter <= 0;
            remain_blocks   <= 0;
            init_block      <= 0;
            last_block      <= 0;
            odd_block       <= 0;
            
            op_counter <= 0;
            
            sig_pub     <= 0;
            error       <= 0;
            valid       <= 0;
            block_ready <= 0;
            
            state <= IDLE;
       end
       else if (error_op) begin
            error <= 1;
       end
       else begin
            case (state) 
            
            //-------------------------------------------
	        //-- IDLE STATE     
            //-------------------------------------------
            
            (IDLE): begin
                control   <= 0;
		        addr      <= 0; 
		        data_in   <= 0;
                
                if (sel == 1) 
                    state <= GEN_KEY;
                else if (sel == 2)
                    state <= SIGN;
                else if (sel == 3)
                    state <= VERIFY;
            end
            
            
            //-------------------------------------------
	        //-- PUBLIC KEY GENERATION   
            //-------------------------------------------
            
            (GEN_KEY): begin 
                op_counter <= op_counter + 1;
                
                case (op_counter)
                (6'd0): begin
                    hash_op_counter <= 0;
                    length          <= 256;
                    last_block      <= 1;
                    state           <= HASH;
                end
                (6'd1): ch_endian <= {256'h0, hash[MODE-1:BIT_LENGTH]};
                (6'd2): S1 <= {3'b01, changed_endian_256[BIT_LENGTH-3:3], 3'b000};
                (6'd3): begin
                    P0 <= G_X;
                    P1 <= G_Y;
                    P2 <= G_Z;
                    P3 <= G_T;
                    
                    sel_op <= 4;
                    state  <= WAIT_OP;
                end
                (6'd4): begin
                    P0 <= R0;
                    P1 <= R1;
                    P2 <= R2;
                
                    sel_op  <= 9;
                    state   <= WAIT_OP;
                end
                (6'd5): ch_endian <= {256'h0, R0};
                (6'd6): begin
                    sig_pub <= changed_endian_256;
                    valid   <= 1;
                    state   <= END;
                end
                endcase 
             end
             
             
             //-------------------------------------------
	         //-- SIGNING   
             //-------------------------------------------
             
             (SIGN): begin 
                op_counter <= op_counter + 1;
                
                case (op_counter)
                (6'd0): begin
                    hash_op_counter <= 0;
                    length          <= 256;
                    last_block      <= 1;
                    state           <= HASH;
                end
                (6'd1): ch_endian <= {256'h0, hash[MODE-1:BIT_LENGTH]};
                (6'd2): begin
                    Q1      <= {3'b01, changed_endian_256[BIT_LENGTH-3:3], 3'b000};  //-- s
                    Q2      <= hash[BIT_LENGTH-1:0];                                 //-- prefix
                    length  <= len_message + 256;
                end
                (6'd3): begin  
                    init_block <= 1;
                    
                    if (hash_blocks == 1)
                        last_block <= 1;
                    else 
                        last_block <= 0;
                    
                    odd_block       <= 0;    
                    remain_blocks   <= hash_blocks;
                    state           <= HASH;
                end
                (6'd4): ch_endian <= hash;
                (6'd5): begin
                    P0 <= changed_endian_512[MODE-1:BIT_LENGTH];
                    Q0 <= changed_endian_512[BIT_LENGTH-1:0]; 
                    
                    sel_op  <= 3;
                    state   <= WAIT_OP;
                end
                (6'd6): begin
                    S1 <= R0;                                                   //-- r
                    
                    P0 <= G_X;
                    P1 <= G_Y;
                    P2 <= G_Z;
                    P3 <= G_T;
                    
                    sel_op <= 4;
                    state  <= WAIT_OP;
                end
                (6'd7): begin
                    P0 <= R0;
                    P1 <= R1;
                    P2 <= R2;
                
                    sel_op <= 9;
                    state <= WAIT_OP;
                end
                (6'd8): ch_endian <= {256'h0, R0};
                (6'd9): begin
                    sig_pub[2*BIT_LENGTH-1:BIT_LENGTH] <= changed_endian_256;       //-- R
                    length                             <= len_message + 512;
                end
                (6'd10): begin
                    init_block  <= 1;
                    
                    if (hash_blocks == 1)
                        last_block <= 1;
                    else 
                        last_block <= 0;
                      
                    remain_blocks   <= hash_blocks;
                    
                    if (hash_blocks > 1) begin
                        odd_block       <= ~odd_block;
                        block_ready     <= 1;
                        state           <= DATA_BLOCK;
                    end
                    else 
                        state <= HASH;
                end
                (6'd11): ch_endian <= hash;
                (6'd12): begin
                    P0 <= changed_endian_512[MODE-1:BIT_LENGTH];
                    Q0 <= changed_endian_512[BIT_LENGTH-1:0]; 
                    
                    sel_op <= 3;
                    state  <= WAIT_OP;
                end
                (6'd13): begin
                    P0 <= R0;                                                   //-- k
                    Q0 <= Q1;
                    
                    sel_op <= 6;
                    state  <= WAIT_OP;
                end
                (6'd14): begin
                    P0 <= R1;
                    Q0 <= R0;
                    
                    sel_op <= 3;
                    state  <= WAIT_OP;
                end
                (6'd15): begin
                    P0 <= R0;
                    Q0 <= S1;
                    
                    sel_op <= 7;
                    state  <= WAIT_OP;
                end 
                (6'd16): begin
                    P0 <= 0;
                    Q0 <= R0;
                    
                    sel_op <= 3;
                    state  <= WAIT_OP;
                end
                (6'd17): ch_endian <= {256'h0, R0};
                (6'd18): begin
                    sig_pub[BIT_LENGTH-1:0] = changed_endian_256;                               //-- S
                    valid   <= 1;
                    state   <= END;
                end

                endcase 
             end
             
             
             //-------------------------------------------
	         //-- VERIFICATION  
             //-------------------------------------------
             
             (VERIFY): begin 
                op_counter <= op_counter + 1;
                
                case (op_counter)
                (6'd0): begin
                    sig_pub <= sig_ver;
                
                    hash_op_counter <= 0;
                    length          <= len_message + 512;
                end
                (6'd1): begin
                    init_block <= 1;
                    
                    if (hash_blocks == 1)
                        last_block <= 1;
                    else 
                        last_block <= 0;
                    
                    odd_block       <= 0;    
                    remain_blocks   <= hash_blocks;
                    state           <= HASH;
                end
                (6'd2): ch_endian <= hash;
                (6'd3): begin
                    P0 <= changed_endian_512[MODE-1:BIT_LENGTH];
                    Q0 <= changed_endian_512[BIT_LENGTH-1:0]; 
                    
                    sel_op <= 3;
                    state  <= WAIT_OP;
                end
                (6'd4): begin
                    S2        <= R0;   //-- k
                    ch_endian <= {256'h0, sig_ver[BIT_LENGTH-1:0]};
                end
                (6'd5): begin
                    S1     <= changed_endian_256;   //-- s
                    
                    P1     <= public;
                    sel_op <= 10;
                    state  <= WAIT_OP;
                end
                (6'd6): begin
                    //-- Point K
                    P0 <= G_X;
                    P1 <= G_Y;
                    P2 <= G_Z;
                    P3 <= G_T;
                    //-- Base Point G
                    Q0 <= R0;
                    Q1 <= R1;
                    Q2 <= R2;
                    Q3 <= R3;
                    //-- Double Point Multiplication
                    sel_op <= 5;
                    state  <= WAIT_OP;
                end
                (6'd7): begin
                    //-- Store [k]K 
                    Q0 <= W0;
                    Q1 <= W1;
                    Q2 <= W2;
                    Q3 <= W3;
                    //-- Store Y
                    S1          <= R0;
                    ch_endian   <= {R1, R2};
                    //-- Decompress R
                    P1      <= sig_ver[2*BIT_LENGTH-1:BIT_LENGTH];
                    sel_op  <= 10;
                    state   <= WAIT_OP;
                end
                (6'd8): begin
                    //-- dec(R)
                    P0 <= R0;
                    P1 <= R1;
                    P2 <= R2;
                    P3 <= R3;
                    //-- dec(R) + [k]K
                    sel_op <= 2;
                    state  <= WAIT_OP; 
                end
                (6'd9): begin
                    //-- Point Equal (Comparison)
                    P0 <= R0;
                    P1 <= R1;
                    P2 <= R2;
                    Q0 <= S1;
                    {Q1, Q2} <= ch_endian;
                    
                    sel_op <= 8;
                    state  <= WAIT_OP; 
                end
                (6'd10): begin
                    if (R0[0])
                        valid <= 1;
                    else 
                        error <= 1;
                    state <= END;
                end
                
                endcase 
             end
             
             
             //-------------------------------------------
	         //-- SHA-512 HASH    
             //-------------------------------------------
             
             (HASH): begin
                if ((hash_op_counter != 9) && (hash_op_counter != 10) && (hash_op_counter != 13))
                    hash_op_counter <= hash_op_counter + 1;
                
                case(hash_op_counter)
                //-- INITIALIZATION
                (4'd0): begin   //-- Reset
                    rst_H   <= 0;
                    control <= 0;  
                end 
                (4'd1): begin   //-- Reset
                    rst_H   <= 1;
                    control <= 1;  
                end 
                (4'd2): control <= 0;
                (4'd3): begin           //-- Load Padding
                    control <= 8;
                    addr    <= 0;
                end
                (4'd4): begin
                    data_in <= length >> WIDTH;
                    addr    <= 1;
                end
                (4'd5): data_in <= length;
                //-- LOAD & OPERATION
                (4'd7): begin
                    control <= 2;       //-- Load
                    addr    <= 0;
                end
                (4'd8): data_in <= w_data_in[SIZE_BLOCK-1-WIDTH*addr-:WIDTH];
                (4'd9): begin
                    if (addr < SIZE_BLOCK/WIDTH-1) begin
                        addr            <= addr + 1;
                        hash_op_counter <= 8;
                    end
                    else begin
                        control <= 4;   //-- Start
                        hash_op_counter <= hash_op_counter + 1;
                    end
                end
                //-- WAIT
                (4'd10): begin
                    if (valid_H && last_block) begin
                        hash_op_counter <= hash_op_counter + 1;
                        addr            <= 0;
                    end
                    else if (valid_H) begin
                        hash_op_counter <= 7;
                        init_block      <= 0;
                        remain_blocks   <= remain_blocks - 1;
                        odd_block       <= ~odd_block;
                        block_ready     <= 1;
                        state           <= DATA_BLOCK;
                    end
                end
                //-- READ HASH 
                (4'd12): begin
                    addr                            <= addr + 1;
                    hash[OUTPUT_SIZE-1-64*addr-:64] <= data_out;
                end
                (4'd13): begin
                    if (addr < OUTPUT_SIZE/WIDTH) begin
                        hash_op_counter <= 12;
                    end
                    else if (sel == 1) begin
                        hash_op_counter <= 0;
                        state           <= GEN_KEY;
                    end
                    else if (sel == 2) begin
                        hash_op_counter <= 0;
                        state           <= SIGN;
                    end
                    else begin
                        hash_op_counter <= 0;
                        state           <= VERIFY;
                    end
                end
                endcase
             end
             
             (DATA_BLOCK): begin
                if (remain_blocks == 1)
                    last_block <= 1;
                
                if (odd_block && (block_valid == 2'b10)) begin
                    block_ready <= 0;
                    state       <= HASH;
                end
                else if (!odd_block && (block_valid == 2'b01)) begin
                    block_ready <= 0;
                    state       <= HASH;
                end 
             end
             
             (WAIT_OP): begin
                // sel_op  <= 0;
                
                if (valid_op && (sel == 1)) begin
                    state <= GEN_KEY;
                    sel_op  <= 0;
                end
                else if (valid_op && (sel == 2)) begin
                    state <= SIGN;
                    sel_op  <= 0;
                end
                else if (valid_op) begin
                    state <= VERIFY;
                    sel_op  <= 0;
                end
             end
            
             endcase
            
        end
    end
    
endmodule
