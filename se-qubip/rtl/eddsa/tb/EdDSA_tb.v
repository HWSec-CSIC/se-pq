/**
  * @file EdDSA_tb.v
  * @brief EdDSA Test Bench
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

`default_nettype none
`define DUMPSTR(x) `"x.vcd`"
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 05/04/2024
// Design Name: EdDSA.v
// Module Name: EdDSA
// Project Name: EDSA25519 Cryptocore
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		EdDSA25519 Cryptocore TESTBENCH
//		
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////

module EdDSA_tb();
	
	//---------------------------------
	//-- Simulation time
	//---------------------------------
	
	parameter DURATION = 100000;
	
	initial
	begin
		#(DURATION) $display("End of simulation");
		$finish;
	end	
	
	
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------
	
	localparam BIT_LENGTH = 256;
    localparam WIDTH      = 64;
    localparam SIZE_BLOCK = 1024;
	
	//-- Clock, Reset and Select
	reg  clk;		
	reg  rst;
	reg  [1:0] block_valid;
	reg  [1:0] sel;
	//-- Inputs
	reg  [BIT_LENGTH-1:0] private;
	reg  [BIT_LENGTH-1:0] public;
	reg  [SIZE_BLOCK-1:0] message;
	reg  [WIDTH-1:0] len_message;
	reg  [2*BIT_LENGTH-1:0] sig_ver;
	//-- Outputs
	wire [2*BIT_LENGTH-1:0] sig_pub;
	wire valid;
	wire error;
	wire block_ready;
	        
			
	//--------------------------------------
	//-- EdDSA Accelerator Instance
	//--------------------------------------
	
	EdDSA DUT(
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
	
	
	    
	//---------------------------------
	//-- Test Values
	//---------------------------------
	
	initial begin
	
		clk = 0;
		
		rst            <= 1;
		block_valid    <= 0;
		sel            <= 0;
		
		private        <= 0;
	    public         <= 0;
	    message        <= 0;
	    len_message    <= 0;
	    sig_ver        <= 0;
		
		#1
		rst     <= 0;
		sel     <= 1;
       //  private <= 256'h9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60;
        private <= 256'hf5e5767cf153319517630f226876b86c8160cc583bc013744c6bf255f5cc0ee5;
        	
	end
	
	reg [10:0] n_test = 1;
	real clk_time; 
	
	always @(posedge valid) begin
		
		clk_time <= $time;
		
		#1
		$display("\nOperation %d at t = %d cycles:\n", n_test, clk_time);
		$display("SIG_PUB = 0x%h \n", sig_pub);
		
		#1
		rst           <= 1;
		block_valid   <= 0;
		
		#1
		rst <= 0;
		
		case (n_test)
			 (1): begin
			     sel <= 2;
			     
			     // public      <= 256'hd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a;
			     public      <= 256'h278117fc144c72340f67d0f2316e8386ceffbf2b2428c9c51fef7c597f1d426e;
			     message     <= {768'h08b8b2b733424243760fe426a4b54908632110a66c2f6591eabd3345e3e4eb98fa6e264bf09efe12ee50f8f54e9f77b1e355f6c50544e23fb1433ddf73be84d879de7c0046dc4996d9e773f4bc9efe5738829adb26c81b37c93a1b270b20329d, 256'h0};
			     len_message <= 8184;
			 end
			 (2): begin
			     sel <= 3;
			     
			     public      <= 256'h278117fc144c72340f67d0f2316e8386ceffbf2b2428c9c51fef7c597f1d426e;
			     message     <= {768'h08b8b2b733424243760fe426a4b54908632110a66c2f6591eabd3345e3e4eb98fa6e264bf09efe12ee50f8f54e9f77b1e355f6c50544e23fb1433ddf73be84d879de7c0046dc4996d9e773f4bc9efe5738829adb26c81b37c93a1b270b20329d, 256'h0};
			     len_message <= 8184;
			     sig_ver     <= 512'h0aab4c900501b3e24d7cdf4663326a3a87df5e4843b2cbdb67cbf6e460fec350aa5371b1508f9f4528ecea23c436d94b5e8fcd4f681e30a6ac00a9704a188a03;
			 end
			 (3): begin
			     sel         <= 1;
			     
			     private     <= 256'h78ae9effe6f245e924a7be63041146ebc670dbd3060cba67fbc6216febc44546;
			     public      <= 256'hfbcfbfa40505d7f2be444a33d185cc54e16d615260e1640b2b5087b83ee3643d;
			     message     <= {48'h89010d855972, 976'h0};
			     len_message <= 64'd48;
			     sig_ver     <= 512'h6ed629fc1d9ce9e1468755ff636d5a3f40a5d9c91afd93b79d241830f7e5fa29854b8f20cc6eecbb248dbd8d16d14e99752194e4904d09c74d639518839d2300;
			 end
			 (4): begin
			     sel <= 2;
			 end
			 (5): begin
			     sel <= 3;
			 end
			 (6): begin
			     sel         <= 1;
			     
			     private     <= 256'h3022975f298c0ad5ddbe90954f20e63ae0c0d2704cf13c221f5b3720af4dba32;
			     public      <= 256'hb845bce38e26ab027b8247463d437a71bbddca2a2381d81fad4c297df9140bd5;
			     message     <= {640'h9aa19a595d989378cdc06891887ef5f9c246e5f83c0b658710673e4e7db760c76354c4f5d1e90db04a23b4fb434c69384593d010e312b11d299c9f97482de887cecfe82ea723bca79a1bd64d03ef19ee, 384'h0};
			     len_message <= 64'd640;
			     sig_ver     <= 512'hae14a860fad0051b3eb72b3721a82f7b9546b2867261e2b7b638979e2561bdeb89b600768f82450a66c8b0481283fa21cb6c53bde350effb68a7d1114bfdb203;
			 end
			 (7): begin
			     message     <= {640'h9aa19a595d989378cdc06891887ef5f9c246e5f83c0b658710673e4e7db760c76354c4f5d1e90db04a23b4fb434c69384593d010e312b11d299c9f97482de887cecfe82ea723bca79a1bd64d03ef19ee, 384'h0};
			     sel <= 2;
			 end
			 (8): begin
			     message     <= {640'h9aa19a595d989378cdc06891887ef5f9c246e5f83c0b658710673e4e7db760c76354c4f5d1e90db04a23b4fb434c69384593d010e312b11d299c9f97482de887cecfe82ea723bca79a1bd64d03ef19ee, 384'h0};
			     sel <= 3;
			 end
			 (9): $finish;
		endcase
		
		n_test <= n_test + 1;
	
	end
	
	always @(posedge error) begin
	    clk_time <= $time;
		
		#1
		$display("\nOperation %d at t = %d cycles:\n", n_test, clk_time);
		$display("SIG_PUB = 0x%h \n", sig_pub);
		
		$finish;
	end
	
	always #0.5 clk = ~clk;
	
	reg [1023:0] M [0:29];
     
     initial begin
        M[0] = 1024'h658675fc6ea534e0810a4432826bf58c941efb65d57a338bbd2e26640f89ffbc1a858efcb8550ee3a5e1998bd177e93a7363c344fe6b199ee5d02e82d522c4feba15452f80288a821a579116ec6dad2b3b310da903401aa62100ab5d1a36553e06203b33890cc9b832f79ef80560ccb9a39ce767967ed628c6ad573cb116dbef;           
        M[1] = 1024'hefd75499da96bd68a8a97b928a8bbc103b6621fcde2beca1231d206be6cd9ec7aff6f6c94fcd7204ed3455c68c83f4a41da4af2b74ef5c53f1d8ac70bdcb7ed185ce81bd84359d44254d95629e9855a94a7c1958d1f8ada5d0532ed8a5aa3fb2d17ba70eb6248e594e1a2297acbbb39d502f1a8c6eb6f1ce22b3de1a1f40cc24;           
        M[2] = 1024'h554119a831a9aad6079cad88425de6bde1a9187ebb6092cf67bf2b13fd65f27088d78b7e883c8759d2c4f5c65adb7553878ad575f9fad878e80a0c9ba63bcbcc2732e69485bbc9c90bfbd62481d9089beccf80cfe2df16a2cf65bd92dd597b0707e0917af48bbb75fed413d238f5555a7a569d80c3414a8d0859dc65a46128ba;        
        M[3] = 1024'hb27af87a71314f318c782b23ebfe808b82b0ce26401d2e22f04d83d1255dc51addd3b75a2b1ae0784504df543af8969be3ea7082ff7fc9888c144da2af58429ec96031dbcad3dad9af0dcbaaaf268cb8fcffead94f3c7ca495e056a9b47acdb751fb73e666c6c655ade8297297d07ad1ba5e43f1bca32301651339e22904cc8c;        
        M[4] = 1024'h42f58c30c04aafdb038dda0847dd988dcda6f3bfd15c4b4c4525004aa06eeff8ca61783aacec57fb3d1f92b0fe2fd1a85f6724517b65e614ad6808d6f6ee34dff7310fdc82aebfd904b01e1dc54b2927094b2db68d6f903b68401adebf5a7e08d78ff4ef5d63653a65040cf9bfd4aca7984a74d37145986780fc0b16ac451649;        
        M[5] = 1024'hde6188a7dbdf191f64b5fc5e2ab47b57f7f7276cd419c17a3ca8e1b939ae49e488acba6b965610b5480109c8b17b80e1b7b750dfc7598d5d5011fd2dcc5600a32ef5b52a1ecc820e308aa342721aac0943bf6686b64b2579376504ccc493d97e6aed3fb0f9cd71a43dd497f01f17c0e2cb3797aa2a2f256656168e6c496afc5f;        
        M[6] = 1024'hb93246f6b1116398a346f1a641f3b041e989f7914f90cc2c7fff357876e506b50d334ba77c225bc307ba537152f3f1610e4eafe595f6d9d90d11faa933a15ef1369546868a7f3a45a96768d40fd9d03412c091c6315cf4fde7cb68606937380db2eaaa707b4c4185c32eddcdd306705e4dc1ffc872eeee475a64dfac86aba41c;        
        M[7] = 1024'h0618983f8741c5ef68d3a101e8a3b8cac60c905c15fc910840b94c00a0b9d0_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;                                                                                                                                                                                                         
        
        M[8] = 1024'h08b8b2b733424243760fe426a4b54908632110a66c2f6591eabd3345e3e4eb98fa6e264bf09efe12ee50f8f54e9f77b1e355f6c50544e23fb1433ddf73be84d8_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;            
        
        M[9] = 1024'h79de7c0046dc4996d9e773f4bc9efe5738829adb26c81b37c93a1b270b20329d658675fc6ea534e0810a4432826bf58c941efb65d57a338bbd2e26640f89ffbc1a858efcb8550ee3a5e1998bd177e93a7363c344fe6b199ee5d02e82d522c4feba15452f80288a821a579116ec6dad2b3b310da903401aa62100ab5d1a36553e;    
        M[10] = 1024'h06203b33890cc9b832f79ef80560ccb9a39ce767967ed628c6ad573cb116dbefefd75499da96bd68a8a97b928a8bbc103b6621fcde2beca1231d206be6cd9ec7aff6f6c94fcd7204ed3455c68c83f4a41da4af2b74ef5c53f1d8ac70bdcb7ed185ce81bd84359d44254d95629e9855a94a7c1958d1f8ada5d0532ed8a5aa3fb2;    
        M[11] = 1024'hd17ba70eb6248e594e1a2297acbbb39d502f1a8c6eb6f1ce22b3de1a1f40cc24554119a831a9aad6079cad88425de6bde1a9187ebb6092cf67bf2b13fd65f27088d78b7e883c8759d2c4f5c65adb7553878ad575f9fad878e80a0c9ba63bcbcc2732e69485bbc9c90bfbd62481d9089beccf80cfe2df16a2cf65bd92dd597b07;    
        M[12] = 1024'h07e0917af48bbb75fed413d238f5555a7a569d80c3414a8d0859dc65a46128bab27af87a71314f318c782b23ebfe808b82b0ce26401d2e22f04d83d1255dc51addd3b75a2b1ae0784504df543af8969be3ea7082ff7fc9888c144da2af58429ec96031dbcad3dad9af0dcbaaaf268cb8fcffead94f3c7ca495e056a9b47acdb7;    
        M[13] = 1024'h51fb73e666c6c655ade8297297d07ad1ba5e43f1bca32301651339e22904cc8c42f58c30c04aafdb038dda0847dd988dcda6f3bfd15c4b4c4525004aa06eeff8ca61783aacec57fb3d1f92b0fe2fd1a85f6724517b65e614ad6808d6f6ee34dff7310fdc82aebfd904b01e1dc54b2927094b2db68d6f903b68401adebf5a7e08;    
        M[14] = 1024'hd78ff4ef5d63653a65040cf9bfd4aca7984a74d37145986780fc0b16ac451649de6188a7dbdf191f64b5fc5e2ab47b57f7f7276cd419c17a3ca8e1b939ae49e488acba6b965610b5480109c8b17b80e1b7b750dfc7598d5d5011fd2dcc5600a32ef5b52a1ecc820e308aa342721aac0943bf6686b64b2579376504ccc493d97e;    
        M[15] = 1024'h6aed3fb0f9cd71a43dd497f01f17c0e2cb3797aa2a2f256656168e6c496afc5fb93246f6b1116398a346f1a641f3b041e989f7914f90cc2c7fff357876e506b50d334ba77c225bc307ba537152f3f1610e4eafe595f6d9d90d11faa933a15ef1369546868a7f3a45a96768d40fd9d03412c091c6315cf4fde7cb68606937380d;    
        M[16] = 1024'hb2eaaa707b4c4185c32eddcdd306705e4dc1ffc872eeee475a64dfac86aba41c0618983f8741c5ef68d3a101e8a3b8cac60c905c15fc910840b94c00a0b9d0_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;                                                                                                                                                  
     
        M[17] = 1024'h79de7c0046dc4996d9e773f4bc9efe5738829adb26c81b37c93a1b270b20329d658675fc6ea534e0810a4432826bf58c941efb65d57a338bbd2e26640f89ffbc1a858efcb8550ee3a5e1998bd177e93a7363c344fe6b199ee5d02e82d522c4feba15452f80288a821a579116ec6dad2b3b310da903401aa62100ab5d1a36553e;    
        M[18] = 1024'h06203b33890cc9b832f79ef80560ccb9a39ce767967ed628c6ad573cb116dbefefd75499da96bd68a8a97b928a8bbc103b6621fcde2beca1231d206be6cd9ec7aff6f6c94fcd7204ed3455c68c83f4a41da4af2b74ef5c53f1d8ac70bdcb7ed185ce81bd84359d44254d95629e9855a94a7c1958d1f8ada5d0532ed8a5aa3fb2;    
        M[19] = 1024'hd17ba70eb6248e594e1a2297acbbb39d502f1a8c6eb6f1ce22b3de1a1f40cc24554119a831a9aad6079cad88425de6bde1a9187ebb6092cf67bf2b13fd65f27088d78b7e883c8759d2c4f5c65adb7553878ad575f9fad878e80a0c9ba63bcbcc2732e69485bbc9c90bfbd62481d9089beccf80cfe2df16a2cf65bd92dd597b07;    
        M[20] = 1024'h07e0917af48bbb75fed413d238f5555a7a569d80c3414a8d0859dc65a46128bab27af87a71314f318c782b23ebfe808b82b0ce26401d2e22f04d83d1255dc51addd3b75a2b1ae0784504df543af8969be3ea7082ff7fc9888c144da2af58429ec96031dbcad3dad9af0dcbaaaf268cb8fcffead94f3c7ca495e056a9b47acdb7;    
        M[21] = 1024'h51fb73e666c6c655ade8297297d07ad1ba5e43f1bca32301651339e22904cc8c42f58c30c04aafdb038dda0847dd988dcda6f3bfd15c4b4c4525004aa06eeff8ca61783aacec57fb3d1f92b0fe2fd1a85f6724517b65e614ad6808d6f6ee34dff7310fdc82aebfd904b01e1dc54b2927094b2db68d6f903b68401adebf5a7e08;    
        M[22] = 1024'hd78ff4ef5d63653a65040cf9bfd4aca7984a74d37145986780fc0b16ac451649de6188a7dbdf191f64b5fc5e2ab47b57f7f7276cd419c17a3ca8e1b939ae49e488acba6b965610b5480109c8b17b80e1b7b750dfc7598d5d5011fd2dcc5600a32ef5b52a1ecc820e308aa342721aac0943bf6686b64b2579376504ccc493d97e;    
        M[23] = 1024'h6aed3fb0f9cd71a43dd497f01f17c0e2cb3797aa2a2f256656168e6c496afc5fb93246f6b1116398a346f1a641f3b041e989f7914f90cc2c7fff357876e506b50d334ba77c225bc307ba537152f3f1610e4eafe595f6d9d90d11faa933a15ef1369546868a7f3a45a96768d40fd9d03412c091c6315cf4fde7cb68606937380d;    
        M[24] = 1024'hb2eaaa707b4c4185c32eddcdd306705e4dc1ffc872eeee475a64dfac86aba41c0618983f8741c5ef68d3a101e8a3b8cac60c905c15fc910840b94c00a0b9d0_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        
        // M[25] = {640'h9aa19a595d989378cdc06891887ef5f9c246e5f83c0b658710673e4e7db760c76354c4f5d1e90db04a23b4fb434c69384593d010e312b11d299c9f97482de887cecfe82ea723bca79a1bd64d03ef19ee, 384'h0};
        M[25] = 1024'h0;
        
        M[26] = {640'h9aa19a595d989378cdc06891887ef5f9c246e5f83c0b658710673e4e7db760c76354c4f5d1e90db04a23b4fb434c69384593d010e312b11d299c9f97482de887cecfe82ea723bca79a1bd64d03ef19ee, 384'h0};
        M[27] = {128'hcecfe82ea723bca79a1bd64d03ef19ee, 896'h0};
        
        //M[28] = {640'h9aa19a595d989378cdc06891887ef5f9c246e5f83c0b658710673e4e7db760c76354c4f5d1e90db04a23b4fb434c69384593d010e312b11d299c9f97482de887cecfe82ea723bca79a1bd64d03ef19ee, 384'h0};
        M[28] = {128'hcecfe82ea723bca79a1bd64d03ef19ee, 896'h0};
        
     end
     
     reg [WIDTH-1:0] block_counter = 0;
     
     always @(posedge block_ready) begin
        
        block_counter   <= block_counter + 1;
        message         <= M[block_counter];
        
        if (block_valid == 2'b00)
            block_valid <= 2'b10;
        else if (block_valid == 2'b10)
            block_valid <= 2'b01;
        else
            block_valid <= 2'b10;
        /*
        if (!block_counter[0] && sel == 2)
            block_valid <= 2'b10;
        else if (sel == 2)
            block_valid <= 2'b01;
        else if (!block_counter[0] && sel == 3)
            block_valid <= 2'b01;
        else
            block_valid <= 2'b10;
        */
     end
     
     
	
endmodule
