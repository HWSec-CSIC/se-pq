/**
  * @file mem_zetas.v
  * @brief mem_zetas
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

`timescale 1ns / 1ps

module mem_zetas #(
    parameter DATA_WIDTH    =   16,
    parameter ADDR_WIDTH    =   7
    )(
    input clk,
    input [(ADDR_WIDTH-1):0] addr_zeta, 
	output [(DATA_WIDTH-1):0] data_out_zeta
    );
    
    ROM_zetas ROM_zetas (.clk(clk), .addr(addr_zeta), .data_out(data_out_zeta));
endmodule

module ROM_zetas #(
    parameter DATA_WIDTH    =   16, 
    parameter ADDR_WIDTH    =   7
    )(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output [(DATA_WIDTH-1):0] data_out
);
 
	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] Mem [2**ADDR_WIDTH-1:0];
    
    reg [(DATA_WIDTH-1):0] reg_out;
 
	always @ (posedge clk)
	begin
		reg_out <= Mem[addr];
	end
	
	assign data_out = reg_out;
	
	initial
	begin
		Mem[0] <= 2285;
		Mem[1] <= 2571;
		Mem[2] <= 2970;
		Mem[3] <= 1812;
		Mem[4] <= 1493;
		Mem[5] <= 1422;
		Mem[6] <= 287;
		Mem[7] <= 202;
		Mem[8] <= 3158;
		Mem[9] <= 622;
		Mem[10] <= 1577;
		Mem[11] <= 182;
		Mem[12] <= 962;
		Mem[13] <= 2127;
		Mem[14] <= 1855;
		Mem[15] <= 1468;
		Mem[16] <= 573;
		Mem[17] <= 2004;
		Mem[18] <= 264;
		Mem[19] <= 383;   
		Mem[20] <= 2500;
		Mem[21] <= 1458;
		Mem[22] <= 1727;
		Mem[23] <= 3199;
		Mem[24] <= 2648;
		Mem[25] <= 1017;
		Mem[26] <= 732;
		Mem[27] <= 608;
		Mem[28] <= 1787;
		Mem[29] <= 411;  
        Mem[30] <= 3124; 
		Mem[31] <= 1758;
		Mem[32] <= 1223;
		Mem[33] <= 652;
		Mem[34] <= 2777;
		Mem[35] <= 1015;
		Mem[36] <= 2036;
		Mem[37] <= 1491;
		Mem[38] <= 3047;
		Mem[39] <= 1785; 
        Mem[40] <= 516; 
		Mem[41] <= 3321;
		Mem[42] <= 3009;
		Mem[43] <= 2663;
		Mem[44] <= 1711;
		Mem[45] <= 2167;
		Mem[46] <= 126;
		Mem[47] <= 1469;
		Mem[48] <= 2476;
		Mem[49] <= 3239; 
		Mem[50] <= 3058;
		Mem[51] <= 830;
		Mem[52] <= 107;
		Mem[53] <= 1908;
		Mem[54] <= 3082;
		Mem[55] <= 2378;
		Mem[56] <= 2931;
		Mem[57] <= 961;
		Mem[58] <= 1821;
		Mem[59] <= 2604; 
		Mem[60] <= 448;
		Mem[61] <= 2264;
		Mem[62] <= 677;
		Mem[63] <= 2054;
		Mem[64] <= 2226;
		Mem[65] <= 430;
		Mem[66] <= 555;
		Mem[67] <= 843;
		Mem[68] <= 2078;
		Mem[69] <= 871;
		Mem[70] <= 1550;
		Mem[71] <= 105;
		Mem[72] <= 422;
		Mem[73] <= 587;
		Mem[74] <= 177;
		Mem[75] <= 3094;
		Mem[76] <= 3038;
		Mem[77] <= 2869;
		Mem[78] <= 1574;
		Mem[79] <= 1653;	
        Mem[80] <= 3083;
		Mem[81] <= 778;
		Mem[82] <= 1159;
		Mem[83] <= 3182;
		Mem[84] <= 2552;
		Mem[85] <= 1483;
		Mem[86] <= 2727;
		Mem[87] <= 1119;
		Mem[88] <= 1739;
		Mem[89] <= 644;		
		Mem[90] <= 2457;
		Mem[91] <= 349;
		Mem[92] <= 418;
		Mem[93] <= 329;
		Mem[94] <= 3173;
		Mem[95] <= 3254;
		Mem[96] <= 817;
		Mem[97] <= 1097;
		Mem[98] <= 603;
		Mem[99] <= 610;  
		Mem[100] <= 1322;
		Mem[101] <= 2044;
		Mem[102] <= 1864;
		Mem[103] <= 384;
		Mem[104] <= 2114;
		Mem[105] <= 3193;
		Mem[106] <= 1218;
		Mem[107] <= 1994;
		Mem[108] <= 2455;
		Mem[109] <= 220; 
		Mem[110] <= 2142;
		Mem[111] <= 1670;
		Mem[112] <= 2144;
		Mem[113] <= 1799;
		Mem[114] <= 2051;
		Mem[115] <= 794;
		Mem[116] <= 1819;
		Mem[117] <= 2475;
		Mem[118] <= 2459;
		Mem[119] <= 478; 
		Mem[120] <= 3221;
		Mem[121] <= 3021;
		Mem[122] <= 996;
		Mem[123] <= 991;
		Mem[124] <= 958;
		Mem[125] <= 1869;
		Mem[126] <= 1522;
		Mem[127] <= 1628;
	end
 endmodule
 