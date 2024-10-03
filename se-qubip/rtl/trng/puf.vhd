--/**
--  * @file puf.vhd
--  * @brief PUF Top Module
--  *
--  * @section License
--  *
--  * Secure Element for QUBIP Project
--  *
--  * This Secure Element repository for QUBIP Project is subject to the
--  * BSD 3-Clause License below.
--  *
--  * Copyright (c) 2024,
--  *         Eros Camacho-Ruiz
--  *         Pablo Navarro-Torrero
--  *         Pau Ortega-Castro
--  *         Apurba Karmakar
--  *         Macarena C. Martínez-Rodríguez
--  *         Piedad Brox
--  *
--  * All rights reserved.
--  *
--  * This Secure Element was developed by Instituto de Microelectrónica de
--  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
--  * European Union under the Horizon Europe framework programme
--  * [grant agreement no. 101119746].
--  *
--  * -----------------------------------------------------------------------
--  *
--  * Redistribution and use in source and binary forms, with or without
--  * modification, are permitted provided that the following conditions are met:
--  *
--  * 1. Redistributions of source code must retain the above copyright notice, this
--  *    list of conditions and the following disclaimer.
--  *
--  * 2. Redistributions in binary form must reproduce the above copyright notice,
--  *    this list of conditions and the following disclaimer in the documentation
--  *    and/or other materials provided with the distribution.
--  *
--  * 3. Neither the name of the copyright holder nor the names of its
--  *    contributors may be used to endorse or promote products derived from
--  *    this software without specific prior written permission.
--  *
--  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
--  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
--  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
--  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
--  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
--  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
--  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
--  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--  *
--  *
--  *
--  *
--  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
--  * @version 1.0
--  **/

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use WORK.puf_pkg.all;

entity puf is
	generic(
        Nx  : integer := 4; 	   	-- Number of columns of CLBs  (Must be a power of two!)
        Ny  : integer := 8;	        -- Number of rows of CLBs
        Xo  : integer := 6;		    -- ROQ_bank Position X           
        Yo  : integer := 15;		-- ROQ_bank Position Y           
        Bpc : integer := 64; 	   	-- Operation(4)/Characterization(32)
        Dbw : integer := 64; 	   	-- AXI4-Lite Data Bus Width
        Mnc : integer := 256; 	   	-- Maximum number of comparisons
        Nbc : integer := 14);		-- Number of bits of counters    
	port (
		clock    : in  std_logic;	                                                -- Clock
		reset    : in  std_logic;	                                                -- Reset
		puf_str  : in  std_logic;	                                                -- PUF_Start
        BG       : in boolean;                                                      -- Binary/Gray code																							 
        SD       : in boolean;                                                      -- Same/Different location LUTs																							 
		cnfa     : in  std_logic_vector(1 downto 0);	                            -- And gate selection for ROs 
		n_cmps   : in  std_logic_vector(clog2(Mnc) downto 0);	                    -- Number of comparations (<= N� ROs)
		puf_addr : in  std_logic_vector(clog2(Mnc*Bpc/Dbw-1) downto 0);	            -- PUF Read Address
		puf_addw : out std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);	            -- PUF Write Address
		puf_end  : out std_logic;									                -- PUF_end signal
		puf_out  : out std_logic_vector(Dbw-1 downto 0));				            -- PUF Output data
end entity;

architecture FPGA of puf is

    component puf_ctrl is
	  generic(
        Dbw : integer;              -- AXI4-Lite Data Bus Width
        Bpc : integer;              -- Operation(4)/Characterization(32)
        Mnc : integer; 	   	        -- Maximum number of comparisons
        Nx  : integer;              -- Number of columns of CLBs 
        Ny  : integer);             -- Number of rows of CLBs
	  port (
		clock    : in std_logic;                                              -- System Clock
		reset    : in std_logic;                                              -- System Reset
		n_cmps   : in  std_logic_vector(clog2(Mnc) downto 0);           -- Number of Comparisons 
		puf_str  : in std_logic;                                              -- PUF Start 
		cmp_end  : in std_logic;                                              -- Comparison End 
		sel_inc  : out std_logic;                                             -- Challenge Selection Clock
		cmp_rst  : out std_logic;                                             -- Comparison Reset 
		cmp_str  : out std_logic;                                             -- Comparison Start 
		cmp_cap  : out std_logic;                                             -- Comparison Capture Data
		puf_ldr  : out std_logic;                                             -- PUF Load Register 
		puf_wa   : out std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);   -- PUF Wtrite Address
		puf_end  : out std_logic);                                            -- PUF End operation
    end component;

    component roc_chl is
	  generic(
        Nx  : integer; 	                                            -- Number of columns of CLBs 
        Ny  : integer);	                                            -- Number of rows of CLBs
	  port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        cnf1   : out std_logic_vector(5 downto 0);
        cnf2   : out std_logic_vector(5 downto 0));  
    end component;
    
	component roc_bnk
	  generic(
        Nx  : integer; 	                                            -- Number of columns of CLBs 
        Ny  : integer);                                             -- Number of rows of CLBs
	  port (
        enx  : in  std_logic;
        eny  : in  std_logic;
        cnf1 : in  std_logic_vector(6 downto 0);
        cnf2 : in  std_logic_vector(6 downto 0);
		ro   : out std_logic_vector((2*Nx*Ny)-1 downto 0));		
	end component;

    component roc_bxt is
	  generic(
        Nbc : integer);											    -- Number of bits of counters
	  port (
		BG       : in boolean;  	                                -- Binary/Gray code
		rst      : in std_logic;	                                -- Reset
		str      : in std_logic;	                                -- Start
		ro1      : in std_logic;	                                -- RO1 clk
		ro2      : in std_logic;	                                -- RO2 clk		
		full1    : out std_logic;									-- RO1 full signal
		full2    : out std_logic;									-- RO2 full signal
		busy     : out std_logic;									-- Busy output signal
		rdata    : out std_logic_vector(Nbc-1 downto 0));			-- Output data
    end component;
    
    component puf_mem is
	generic(
        Dbw : integer; 	  	                                                -- AXI4-Lite Data Bus Width
        Bpc : integer; 	   	                                                -- Operation(4)/Characterization(32)
        Mnc : integer; 	   	                                                -- Maximum number of comparisons
        Nx  : integer;                                           	        -- Number of columns of CLBs 
        Ny  : integer);                                         	        -- Number of rows of CLBs
	port (
		clk_w   : in std_logic;                                             -- Clock for Write operations
		clk_r   : in std_logic;                                             -- Clock for Read operations
		clk_sr  : in std_logic;                                             -- Clock for Shift Register
		reset   : in std_logic;                                             -- Global Reset
		cmp_out : in std_logic_vector(Bpc-1 downto 0);                      -- Comparison Output
		puf_wa  : in std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);         -- PUF Write Address (max: ROs*4/32) --- Char
		puf_ra  : in std_logic_vector(clog2(Mnc*Bpc/Dbw-1) downto 0);       -- PUF Read Address (max: ROs*4/32)  --- Char
		puf_out : out std_logic_vector(Dbw-1 downto 0));                    -- PUF Output (for puf_rra)
    end component;  
    
	attribute KEEP_HIERARCHY : string;
	attribute RLOC_ORIGIN    : string;

    attribute KEEP_HIERARCHY of robk  : label is "TRUE";
    attribute RLOC_ORIGIN of robk : label is 
                "X" & integer'image(integer(Xo)) & "Y" & integer'image(integer(Yo));
	   
    signal sel_inc   : std_logic; 

	signal s_cnf1    : std_logic_vector(6 downto 0);
	signal s_cnf2    : std_logic_vector(6 downto 0);

	signal en_x      : std_logic_vector(2*Nx-1 downto 0);
    signal en_y      : std_logic_vector(Ny-1 downto 0);    
	signal ro_0  : std_logic;
    signal ro_1  : std_logic;
    signal ro_2  : std_logic;
    signal ro_3  : std_logic;
    signal ro_4  : std_logic;
    signal ro_5  : std_logic;
    signal ro_6  : std_logic;
    signal ro_7  : std_logic;
    signal ro_8  : std_logic;
    signal ro_9  : std_logic;
    signal ro_10 : std_logic;
    signal ro_11 : std_logic;
    signal ro_12 : std_logic;
    signal ro_13 : std_logic;
    signal ro_14 : std_logic;
    signal ro_15 : std_logic;
    signal ro_16 : std_logic;
    signal ro_17 : std_logic;
    signal ro_18 : std_logic;
    signal ro_19 : std_logic;
    signal ro_20 : std_logic;
    signal ro_21 : std_logic;
    signal ro_22 : std_logic;
    signal ro_23 : std_logic;
    signal ro_24 : std_logic;
    signal ro_25 : std_logic;
    signal ro_26 : std_logic;
    signal ro_27 : std_logic;
    signal ro_28 : std_logic;
    signal ro_29 : std_logic;
    signal ro_30 : std_logic;
    signal ro_31 : std_logic;
    signal ro_32 : std_logic;
    signal ro_33 : std_logic;
    signal ro_34 : std_logic;
    signal ro_35 : std_logic;
    signal ro_36 : std_logic;
    signal ro_37 : std_logic;
    signal ro_38 : std_logic;
    signal ro_39 : std_logic;
    signal ro_40 : std_logic;
    signal ro_41 : std_logic;
    signal ro_42 : std_logic;
    signal ro_43 : std_logic;
    signal ro_44 : std_logic;
    signal ro_45 : std_logic;
    signal ro_46 : std_logic;
    signal ro_47 : std_logic;
    signal ro_48 : std_logic;
    signal ro_49 : std_logic;
    signal ro_50 : std_logic;
    signal ro_51 : std_logic;
    signal ro_52 : std_logic;
    signal ro_53 : std_logic;
    signal ro_54 : std_logic;
    signal ro_55 : std_logic;
    signal ro_56 : std_logic;
    signal ro_57 : std_logic;
    signal ro_58 : std_logic;
    signal ro_59 : std_logic;
    signal ro_60 : std_logic;
    signal ro_61 : std_logic;
    signal ro_62 : std_logic;
    signal ro_63 : std_logic;
	signal ro_b      : std_logic_vector(2*Nx*Ny-1 downto 0);	
	signal en_ro     : std_logic;

	signal rdata1    : std_logic_vector(Nbc-1 downto 0);
	signal rdata2    : std_logic_vector(Nbc-1 downto 0);
	signal rdata3    : std_logic_vector(Nbc-1 downto 0);
	signal rdata4    : std_logic_vector(Nbc-1 downto 0);
	signal rdata5    : std_logic_vector(Nbc-1 downto 0);
	signal rdata6    : std_logic_vector(Nbc-1 downto 0);
	signal rdata7    : std_logic_vector(Nbc-1 downto 0);
	signal rdata8    : std_logic_vector(Nbc-1 downto 0);
	signal rdata9    : std_logic_vector(Nbc-1 downto 0);
	signal rdata10    : std_logic_vector(Nbc-1 downto 0);
	signal rdata11    : std_logic_vector(Nbc-1 downto 0);
	signal rdata12    : std_logic_vector(Nbc-1 downto 0);
	signal rdata13    : std_logic_vector(Nbc-1 downto 0);
	signal rdata14    : std_logic_vector(Nbc-1 downto 0);
	signal rdata15    : std_logic_vector(Nbc-1 downto 0);
	signal rdata16    : std_logic_vector(Nbc-1 downto 0);
	signal rdata17    : std_logic_vector(Nbc-1 downto 0);
	signal rdata18    : std_logic_vector(Nbc-1 downto 0);
	signal rdata19    : std_logic_vector(Nbc-1 downto 0);
	signal rdata20    : std_logic_vector(Nbc-1 downto 0);
	signal rdata21    : std_logic_vector(Nbc-1 downto 0);
	signal rdata22    : std_logic_vector(Nbc-1 downto 0);
	signal rdata23    : std_logic_vector(Nbc-1 downto 0);
	signal rdata24    : std_logic_vector(Nbc-1 downto 0);
	signal rdata25    : std_logic_vector(Nbc-1 downto 0);
	signal rdata26    : std_logic_vector(Nbc-1 downto 0);
	signal rdata27    : std_logic_vector(Nbc-1 downto 0);
	signal rdata28    : std_logic_vector(Nbc-1 downto 0);
	signal rdata29    : std_logic_vector(Nbc-1 downto 0);
	signal rdata30    : std_logic_vector(Nbc-1 downto 0);
	signal rdata31    : std_logic_vector(Nbc-1 downto 0);
	signal rdata32    : std_logic_vector(Nbc-1 downto 0);
	signal full      : std_logic_vector(Bpc-1 downto 0);
	signal busy      : std_logic;
	signal s_busy_1  : std_logic;
	signal s_busy_2  : std_logic;
	signal s_busy_3  : std_logic;
	signal s_busy_4  : std_logic;
	signal s_busy_5  : std_logic;
	signal s_busy_6  : std_logic;
	signal s_busy_7  : std_logic;
	signal s_busy_8  : std_logic;
	signal s_busy_9  : std_logic;
	signal s_busy_10  : std_logic;
	signal s_busy_11  : std_logic;
	signal s_busy_12  : std_logic;
	signal s_busy_13  : std_logic;
	signal s_busy_14  : std_logic;
	signal s_busy_15  : std_logic;
	signal s_busy_16  : std_logic;
	signal s_busy_17  : std_logic;
	signal s_busy_18  : std_logic;
	signal s_busy_19  : std_logic;
	signal s_busy_20  : std_logic;
	signal s_busy_21  : std_logic;
	signal s_busy_22  : std_logic;
	signal s_busy_23  : std_logic;
	signal s_busy_24  : std_logic;
	signal s_busy_25  : std_logic;
	signal s_busy_26  : std_logic;
	signal s_busy_27  : std_logic;
	signal s_busy_28  : std_logic;
	signal s_busy_29  : std_logic;
	signal s_busy_30  : std_logic;
	signal s_busy_31  : std_logic;
	signal s_busy_32  : std_logic;
	
	signal cmp_rst   : std_logic;
	signal cmp_str   : std_logic;
	signal cmp_end   : std_logic;
	signal cmp_cap   : std_logic;
	
	signal puf_wa    : std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);
	signal puf_ldr   : std_logic;
 	signal cmp_out   : std_logic_vector(Bpc-1 downto 0);  
 	    	
begin	

	pctrl: puf_ctrl
		generic map (Dbw => Dbw, Bpc => Bpc, Mnc => Mnc, Nx => Nx, Ny => Ny)
		port map (clock => clock, reset => reset, n_cmps => n_cmps, puf_str => puf_str,
		          cmp_end => cmp_end, sel_inc => sel_inc,
		          cmp_rst => cmp_rst, cmp_str => cmp_str, cmp_cap => cmp_cap,      		          
		          puf_ldr => puf_ldr,  puf_wa => puf_wa, puf_end => puf_end);      		          
          		          
	rochl: roc_chl
		generic map (Nx => Nx, Ny => Ny)
		port map (clk => sel_inc, reset => reset, cnf1 => s_cnf1(5 downto 0), cnf2 => s_cnf2(5 downto 0));

	s_cnf1(6) <= cnfa(0);	          		          
	s_cnf2(6) <= cnfa(1);	
	          		          
	robk: roc_bnk
		generic map (Nx => Nx, Ny => Ny)
		port map (enx => en_ro, eny => en_ro, cnf1 => s_cnf1, cnf2 => s_cnf2, ro => ro_b);
		
	
--	ro_signal_connection : for i in 0 to (Bpc/4)-1 generate
--	    ro_i*4 <= ro_b(i*4);
--        ro_i*4+1 <= ro_b(i*4+2) when SD else ro_b(i*4+3);
--        ro_i*4+2 <= ro_b(i*4+1) when SD else ro_b(i*4+2);
--        ro_i*4+3 <= ro_b(i*4+3) when SD else ro_b(i*4+1);
	
--	end generate ro_signal_connection;
	ro_0 <= ro_b(0);
	ro_1 <= ro_b(2) when SD else ro_b(3);
	ro_2 <= ro_b(1) when SD else ro_b(2);
	ro_3 <= ro_b(3) when SD else ro_b(1);
	
	ro_4 <= ro_b(4);
	ro_5 <= ro_b(6) when SD else ro_b(7);
	ro_6 <= ro_b(5) when SD else ro_b(6);
	ro_7 <= ro_b(7) when SD else ro_b(5);
	
	ro_8 <= ro_b(8);
	ro_9 <= ro_b(10) when SD else ro_b(11);
	ro_10 <= ro_b(9) when SD else ro_b(10);
	ro_11 <= ro_b(11) when SD else ro_b(9);
	
	ro_12 <= ro_b(12);
	ro_13 <= ro_b(14) when SD else ro_b(15);
	ro_14 <= ro_b(13) when SD else ro_b(14);
	ro_15 <= ro_b(15) when SD else ro_b(13);
	
	ro_16 <= ro_b(16);
	ro_17 <= ro_b(18) when SD else ro_b(19);
	ro_18 <= ro_b(17) when SD else ro_b(18);
	ro_19 <= ro_b(19) when SD else ro_b(17);
	
	ro_20 <= ro_b(20);
	ro_21 <= ro_b(22) when SD else ro_b(23);
	ro_22 <= ro_b(21) when SD else ro_b(22);
	ro_23 <= ro_b(23) when SD else ro_b(21);
	
	ro_24 <= ro_b(24);
	ro_25 <= ro_b(26) when SD else ro_b(27);
	ro_26 <= ro_b(25) when SD else ro_b(26);
	ro_27 <= ro_b(27) when SD else ro_b(25);
	
	ro_28 <= ro_b(28);
	ro_29 <= ro_b(30) when SD else ro_b(31);
	ro_30 <= ro_b(29) when SD else ro_b(30);
	ro_31 <= ro_b(31) when SD else ro_b(29);
	
	ro_32 <= ro_b(32);
	ro_33 <= ro_b(35) when SD else ro_b(34);
	ro_34 <= ro_b(33) when SD else ro_b(35);
	ro_35 <= ro_b(34) when SD else ro_b(33);
	
	ro_36 <= ro_b(36);
	ro_37 <= ro_b(39) when SD else ro_b(38);
	ro_38 <= ro_b(37) when SD else ro_b(39);
	ro_39 <= ro_b(38) when SD else ro_b(37);
	
	ro_40 <= ro_b(40);
	ro_41 <= ro_b(43) when SD else ro_b(42);
	ro_42 <= ro_b(41) when SD else ro_b(43);
	ro_43 <= ro_b(42) when SD else ro_b(41);
	
	ro_44 <= ro_b(44);
	ro_45 <= ro_b(47) when SD else ro_b(46);
	ro_46 <= ro_b(45) when SD else ro_b(47);
	ro_47 <= ro_b(46) when SD else ro_b(45);
	
	ro_48 <= ro_b(48);
	ro_49 <= ro_b(51) when SD else ro_b(50);
	ro_50 <= ro_b(49) when SD else ro_b(51);
	ro_51 <= ro_b(50) when SD else ro_b(49);
	
	ro_52 <= ro_b(52);
	ro_53 <= ro_b(55) when SD else ro_b(54);
	ro_54 <= ro_b(53) when SD else ro_b(55);
	ro_55 <= ro_b(54) when SD else ro_b(53);
	
	ro_56 <= ro_b(56);
	ro_57 <= ro_b(59) when SD else ro_b(58);
	ro_58 <= ro_b(57) when SD else ro_b(59);
	ro_59 <= ro_b(58) when SD else ro_b(57);
	
	ro_60 <= ro_b(60);
	ro_61 <= ro_b(63) when SD else ro_b(62);
	ro_62 <= ro_b(61) when SD else ro_b(63);
	ro_63 <= ro_b(62) when SD else ro_b(61);
	
    robxt_1 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_0, ro2 => ro_1,
				 full1 => full(0), full2 => full(1),
				 busy => s_busy_1, rdata => rdata1);
				 
    robxt_2 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_2, ro2 => ro_3,
				 full1 => full(2), full2 => full(3),
				 busy => s_busy_2, rdata => rdata2);
				 
    robxt_3 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_4, ro2 => ro_5,
				 full1 => full(4), full2 => full(5),
				 busy => s_busy_3, rdata => rdata3);
				 
    robxt_4 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_6, ro2 => ro_7,
				 full1 => full(6), full2 => full(7),
				 busy => s_busy_4, rdata => rdata4);
	
	robxt_5 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_8, ro2 => ro_9,
				 full1 => full(8), full2 => full(9),
				 busy => s_busy_5, rdata => rdata5);
				 
    robxt_6 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_10, ro2 => ro_11,
				 full1 => full(10), full2 => full(11),
				 busy => s_busy_6, rdata => rdata6);
				 
	robxt_7 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_12, ro2 => ro_13,
				 full1 => full(12), full2 => full(13),
				 busy => s_busy_7, rdata => rdata7);
				 
    robxt_8 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_14, ro2 => ro_15,
				 full1 => full(14), full2 => full(15),
				 busy => s_busy_8, rdata => rdata8);
				 
	robxt_9 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_16, ro2 => ro_17,
				 full1 => full(16), full2 => full(17),
				 busy => s_busy_9, rdata => rdata9);
				 
    robxt_10 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_18, ro2 => ro_19,
				 full1 => full(18), full2 => full(19),
				 busy => s_busy_10, rdata => rdata10);
				 
	robxt_11 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_20, ro2 => ro_21,
				 full1 => full(20), full2 => full(21),
				 busy => s_busy_11, rdata => rdata11);
				 
    robxt_12 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_22, ro2 => ro_23,
				 full1 => full(22), full2 => full(23),
				 busy => s_busy_12, rdata => rdata12);
				 
    robxt_13 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_24, ro2 => ro_25,
				 full1 => full(24), full2 => full(25),
				 busy => s_busy_13, rdata => rdata13);
				 
    robxt_14 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_26, ro2 => ro_27,
				 full1 => full(26), full2 => full(27),
				 busy => s_busy_14, rdata => rdata14);
	
	robxt_15 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_28, ro2 => ro_29,
				 full1 => full(28), full2 => full(29),
				 busy => s_busy_15, rdata => rdata15);
				 
    robxt_16 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_30, ro2 => ro_31,
				 full1 => full(30), full2 => full(31),
				 busy => s_busy_16, rdata => rdata16);
				 
	robxt_17 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_32, ro2 => ro_33,
				 full1 => full(32), full2 => full(33),
				 busy => s_busy_17, rdata => rdata17);
				 
    robxt_18 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_34, ro2 => ro_35,
				 full1 => full(34), full2 => full(35),
				 busy => s_busy_18, rdata => rdata18);
				 
	robxt_19 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_36, ro2 => ro_37,
				 full1 => full(36), full2 => full(37),
				 busy => s_busy_19, rdata => rdata19);
				 
    robxt_20 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_38, ro2 => ro_39,
				 full1 => full(38), full2 => full(39),
				 busy => s_busy_20, rdata => rdata20);
				 
    robxt_21 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_40, ro2 => ro_41,
				 full1 => full(40), full2 => full(41),
				 busy => s_busy_21, rdata => rdata21);
				 
    robxt_22 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_42, ro2 => ro_43,
				 full1 => full(42), full2 => full(43),
				 busy => s_busy_22, rdata => rdata22);
				 
    robxt_23 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_44, ro2 => ro_45,
				 full1 => full(44), full2 => full(45),
				 busy => s_busy_23, rdata => rdata23);
				 
    robxt_24 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_46, ro2 => ro_47,
				 full1 => full(46), full2 => full(47),
				 busy => s_busy_24, rdata => rdata24);
	
	robxt_25 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_48, ro2 => ro_49,
				 full1 => full(48), full2 => full(49),
				 busy => s_busy_25, rdata => rdata25);
				 
    robxt_26 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_50, ro2 => ro_51,
				 full1 => full(50), full2 => full(51),
				 busy => s_busy_26, rdata => rdata26);
				 
	robxt_27 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_52, ro2 => ro_53,
				 full1 => full(52), full2 => full(53),
				 busy => s_busy_27, rdata => rdata27);
				 
    robxt_28 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_54, ro2 => ro_55,
				 full1 => full(54), full2 => full(55),
				 busy => s_busy_28, rdata => rdata28);
				 
	robxt_29 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_56, ro2 => ro_57,
				 full1 => full(56), full2 => full(57),
				 busy => s_busy_29, rdata => rdata29);
	
	robxt_30 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_58, ro2 => ro_59,
				 full1 => full(58), full2 => full(59),
				 busy => s_busy_30, rdata => rdata30);
				 
    robxt_31 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_60, ro2 => ro_61,
				 full1 => full(60), full2 => full(61),
				 busy => s_busy_31, rdata => rdata31);
				 
	robxt_32 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_62, ro2 => ro_63,
				 full1 => full(62), full2 => full(63),
				 busy => s_busy_32, rdata => rdata32);

	busy    <= s_busy_1 or s_busy_2 or s_busy_3 or s_busy_5 or s_busy_6 or s_busy_7 or s_busy_8 or s_busy_9 or s_busy_10 or s_busy_11 or s_busy_12 or s_busy_13 or s_busy_14 or s_busy_15 
	           or s_busy_16 or s_busy_17 or s_busy_18 or s_busy_19 or s_busy_20 or s_busy_21 or s_busy_22 or s_busy_23 or s_busy_24 or s_busy_25 or s_busy_26 or s_busy_27 or s_busy_28 or s_busy_29
	           or s_busy_30 or s_busy_31 or s_busy_32;
	en_ro   <= busy;
	cmp_end <= not busy;
	
	pmem : puf_mem
		generic map (Dbw => Dbw, Bpc => Bpc, Mnc => Mnc, Nx => Nx, Ny => Ny)
		port map(clk_w => puf_ldr, clk_r => clock, clk_sr => busy, reset => reset, cmp_out => cmp_out, 
				 puf_wa => puf_wa, puf_ra => puf_addr, puf_out => puf_out);
 
    puf_addw <= puf_wa;
    
--  Capture comparison output   
    --
    OP: if Bpc = 64 generate             --  OPERATION
    process (cmp_cap)  
    begin
        if (rising_edge(cmp_cap)) then
            cmp_out(63) <= rdata32(1);              -- bit Nbc-1(2)
	        cmp_out(62) <= rdata32(0);              -- bit Nbc(2)
            cmp_out(61) <= rdata31(1);              -- bit Nbc-1(2)
	        cmp_out(60) <= rdata31(0);              -- bit Nbc(2)
            cmp_out(59) <= rdata30(1);              -- bit Nbc-1(2)
	        cmp_out(58) <= rdata30(0);              -- bit Nbc(2)
	        cmp_out(57) <= rdata29(1);              -- bit Nbc-1(2)
	        cmp_out(56) <= rdata29(0);              -- bit Nbc(2)
	        cmp_out(55) <= rdata28(1);              -- bit Nbc-1(2)
	        cmp_out(54) <= rdata28(0);              -- bit Nbc(2)
	        cmp_out(53) <= rdata27(1);              -- bit Nbc-1(2)
	        cmp_out(52) <= rdata27(0);              -- bit Nbc(2)
	        cmp_out(51) <= rdata26(1);              -- bit Nbc-1(2)
	        cmp_out(50) <= rdata26(0);              -- bit Nbc(2)
	        cmp_out(49) <= rdata25(1);              -- bit Nbc-1(2)
	        cmp_out(48) <= rdata25(0);              -- bit Nbc(2)
	        cmp_out(47) <= rdata24(1);              -- bit Nbc-1(2)
	        cmp_out(46) <= rdata24(0);              -- bit Nbc(2)
	        cmp_out(45) <= rdata23(1);              -- bit Nbc-1(2)
	        cmp_out(44) <= rdata23(0);              -- bit Nbc(2)
	        cmp_out(43) <= rdata22(1);              -- bit Nbc-1(2)
	        cmp_out(42) <= rdata22(0);              -- bit Nbc(2)
            cmp_out(41) <= rdata21(1);              -- bit Nbc-1(2)
	        cmp_out(40) <= rdata21(0);              -- bit Nbc(2)
            cmp_out(39) <= rdata20(1);              -- bit Nbc-1(2)
	        cmp_out(38) <= rdata20(0);              -- bit Nbc(2)
	        cmp_out(37) <= rdata19(1);              -- bit Nbc-1(2)
	        cmp_out(36) <= rdata19(0);              -- bit Nbc(2)
	        cmp_out(35) <= rdata18(1);              -- bit Nbc-1(2)
	        cmp_out(34) <= rdata18(0);              -- bit Nbc(2)
            cmp_out(33) <= rdata17(1);              -- bit Nbc-1(2)
	        cmp_out(32) <= rdata17(0);              -- bit Nbc(2)
	        
            cmp_out(31) <= rdata16(1);              -- bit Nbc-1(2)
	        cmp_out(30) <= rdata16(0);              -- bit Nbc(2)
	        cmp_out(29) <= rdata15(1);              -- bit Nbc-1(1)
	        cmp_out(28) <= rdata15(0);              -- bit Nbc(1) 
	        cmp_out(27) <= rdata14(1);              -- bit Nbc-1(2)
	        cmp_out(26) <= rdata14(0);              -- bit Nbc(2)
	        cmp_out(25) <= rdata13(1);              -- bit Nbc-1(1)
	        cmp_out(24) <= rdata13(0);              -- bit Nbc(1)
            cmp_out(23) <= rdata12(1);              -- bit Nbc-1(2)
	        cmp_out(22) <= rdata12(0);              -- bit Nbc(2)
	        cmp_out(21) <= rdata11(1);              -- bit Nbc-1(1)
	        cmp_out(20) <= rdata11(0);              -- bit Nbc(1) 
	        cmp_out(19) <= rdata10(1);              -- bit Nbc-1(2)
	        cmp_out(18) <= rdata10(0);              -- bit Nbc(2)
	        cmp_out(17) <= rdata9(1);              -- bit Nbc-1(1)
	        cmp_out(16) <= rdata9(0);              -- bit Nbc(1)
            cmp_out(15) <= rdata8(1);              -- bit Nbc-1(2)
	        cmp_out(14) <= rdata8(0);              -- bit Nbc(2)
	        cmp_out(13) <= rdata7(1);              -- bit Nbc-1(1)
	        cmp_out(12) <= rdata7(0);              -- bit Nbc(1) 
	        cmp_out(11) <= rdata6(1);              -- bit Nbc-1(2)
	        cmp_out(10) <= rdata6(0);              -- bit Nbc(2)
	        cmp_out(9) <= rdata5(1);              -- bit Nbc-1(1)
	        cmp_out(8) <= rdata5(0);              -- bit Nbc(1)
            cmp_out(7) <= rdata4(1);              -- bit Nbc-1(2)
	        cmp_out(6) <= rdata4(0);              -- bit Nbc(2)
	        cmp_out(5) <= rdata3(1);              -- bit Nbc-1(1)
	        cmp_out(4) <= rdata3(0);              -- bit Nbc(1) 
	        cmp_out(3) <= rdata2(1);              -- bit Nbc-1(2)
	        cmp_out(2) <= rdata2(0);              -- bit Nbc(2)
	        cmp_out(1) <= rdata1(1);              -- bit Nbc-1(1)
	        cmp_out(0) <= rdata1(0);              -- bit Nbc(1)
        end if;
    end process;	 
    end generate OP;
    --
--    CH: if Bpc = 32  generate               --  CHARACTERIZATION
--    process (cmp_cap)  
--    begin
--        if (rising_edge(cmp_cap)) then  
--            cmp_out(31 downto Nbc+17) <= (others => '0');          
--            cmp_out(Nbc+16) <= full1;               -- bit 0(1)
--	        cmp_out(Nbc+15 downto 16) <= rdata1;    -- bits (1)
--	        cmp_out(15 downto Nbc+1) <= (others => '0');
--            cmp_out(Nbc) <= full3;                  -- bit 0(2)
--	        cmp_out(Nbc-1 downto 0) <= rdata2;      -- bits (2)
--        end if;
--    end process;	 
--    end generate CH;

end FPGA;
