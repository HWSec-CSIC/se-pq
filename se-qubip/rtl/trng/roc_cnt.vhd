--/**
--  * @file roc_cnt.vhd
--  * @brief ROC Counter
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
use IEEE.std_logic_unsigned.ALL;

entity roc_cnt is
	generic(
        Nbc : integer := 4 );	-- Number of bits
	port (
		BG       : in boolean;
		clk      : in std_logic;
		rst      : in std_logic;
		count_en : in std_logic;
		full     : out std_logic;
		counter  : out std_logic_vector(Nbc-1 downto 0));
end roc_cnt;

architecture FPGA of roc_cnt is

	signal next_binary_count  : std_logic_vector (Nbc-1 downto 0);
	signal binary_count       : std_logic_vector (Nbc-1 downto 0);
	signal gray_count         : std_logic_vector (Nbc-1 downto 0);
    signal mask               : std_logic_vector (Nbc-2 downto 0);

begin

    mask(Nbc-2 downto 3) <= (others => '0');
    mask(2 downto 0) <= "100";
	
	next_binary_count <= binary_count + 1; 

	process (clk, rst, count_en)  
    begin
        if rst='1' then
			gray_count   <= (others => '0');
			binary_count <= (others => '0');
            full <= '0';       
        elsif (rising_edge(clk) and count_en='1')  then        
            binary_count <= next_binary_count;
            gray_count <= (('0' & next_binary_count(Nbc-1 downto 1)) XOR next_binary_count);
            if ( gray_count(Nbc-1)='1' and gray_count(Nbc-2 downto 0)= mask ) then
                full <= '1';           
            end if;
        end if;
    end process;
    
    counter <= binary_count when BG else gray_count;

end FPGA;
