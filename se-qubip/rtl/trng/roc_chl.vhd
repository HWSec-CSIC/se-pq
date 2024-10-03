--/**
--  * @file roc_chl.vhd
--  * @brief ROC CHL
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
use IEEE.numeric_std.all;
 
use WORK.puf_pkg.all;

entity roc_chl is
	generic(
        Nx  : integer := 2;              -- Number of columns of CLBs 
        Ny  : integer := 3);             -- Number of rows of true
    port(
		clk   : in  std_logic;
		reset : in  std_logic;
        cnf1   : out std_logic_vector(5 downto 0);
        cnf2   : out std_logic_vector(5 downto 0));
end entity;

architecture FPGA of roc_chl is
   
    signal s_cnf   :  std_logic_vector(11 downto 0);

begin

	Config: process (clk, reset)  
    begin
        if reset='1' then
            s_cnf <= (others => '1');
        elsif rising_edge(clk) then       
            s_cnf <=  s_cnf + 1;
        end if;
    end process;
    
    cnf1  <= s_cnf(5 downto 0);
    cnf2  <= s_cnf(11 downto 6);
    
end FPGA;
