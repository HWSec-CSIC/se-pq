--/**
--  * @file  roc_bxt.vhd
--  * @brief ROC_BXT
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


entity roc_bxt is
	generic(
        Nbc : integer := 14);		-- Number of bits of counters
	port (
		BG    	 : in boolean;	                               		-- Binary/Gray code
		rst      : in std_logic;	                                -- Reset
		str      : in std_logic;	                                -- Start
		ro1      : in std_logic;	                                -- RO1 clk
		ro2      : in std_logic;	                                -- RO2 clk
		full1    : out std_logic;									-- RO1 full signal
		full2    : out std_logic;									-- RO2 full signal
		busy     : out std_logic;									-- Busy output signal
		rdata    : out std_logic_vector(Nbc-1 downto 0));			-- Output data
end entity;

architecture FPGA of roc_bxt is

	component roc_cnt
	  generic(
        Nbc : integer);	            -- Number of bits of counter
	  port (
		BG    	 : in boolean;
		clk      : in  std_logic;
		rst      : in  std_logic;
		count_en : in  std_logic;
		counter  : out std_logic_vector(Nbc-1 downto 0);
		full     : out std_logic );
	end component;

	
	signal cfull1    : std_logic;
	signal full_1    : std_logic;
	signal nfull_1   : std_logic;
	signal cfull2    : std_logic;
	signal full_2    : std_logic;
	signal nfull_2   : std_logic;
	signal full      : std_logic;
	signal counter_1 : std_logic_vector(Nbc-1 downto 0);
    signal counter_2 : std_logic_vector(Nbc-1 downto 0);
	signal rdata1    : std_logic_vector(Nbc-1 downto 0);
    
    	
begin	

    nfull_1 <= not full_1;
    nfull_2 <= not full_2;
    
    cnt1 : roc_cnt
		generic map(Nbc => Nbc)
		port map(BG => BG, clk => ro1, rst => rst, count_en => nfull_2, 
				 counter => counter_1, full => full_1);
				 
	cnt2 : roc_cnt
		generic map(Nbc => Nbc)
		port map(BG => BG, clk => ro2, rst => rst, count_en =>  nfull_1,
				 counter => counter_2, full => full_2);	
		
 	-- Generate enable signal for ROs
    process (str, full, rst)
      begin
        if (rising_edge(str)) then
            busy <= '1';
        end if;
        if (full='1' or rst='1') then
            busy <= '0';
        end if;
    end process;
  
	-- Generate output signals
	full     <= full_1 or full_2;	

	-- Output 0 if not (full1 or full2)
	-- Output counter_2 or counter_1 if (full1 or full2)    	
	rdata1 <= counter_2 when full_1='1' else counter_1;
	rdata <= rdata1 when full='1' else (others => '0');

 	-- Active first full signal
    process (rst, full_1, full_2)
      begin
        if (rst = '1') then
            full1 <= '0';
        elsif (rising_edge(full_1) and full_2='0') then
            full1 <= '1';
        end if;
        if rst = '1' then
            full2 <= '0';
        elsif (rising_edge(full_2) and full_1='0') then
            full2 <= '1';
        end if;
    end process;
		
end FPGA;
     