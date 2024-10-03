--/**
--  * @file roc_bnk.vhd
--  * @brief VHDL code for TRNGR4_2.0 Ring_Oscillator Bank
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

--
-- roc_bnk.vhd - VHDL code for TRNGR4_2.0 Ring_Oscillator Bank
-- santiago@imse-cnm.csic.es (21/07/2023)
--

library IEEE;
use IEEE.std_logic_1164.all;

entity roc_bnk is
	generic(
        Nx : integer := 1;	        -- Number of columns of CLBs 
        Ny : integer := 2);	        -- Number of rows of CLBs
	port (
        enx  : in  std_logic;
        eny  : in  std_logic;
        cnf1 : in  std_logic_vector(6 downto 0);
        cnf2 : in  std_logic_vector(6 downto 0);
		ro   : out std_logic_vector((2*Nx*Ny)-1 downto 0));		
end entity;

architecture FPGA of roc_bnk is  

	component roc
	port(
		enx : in  std_logic;
        eny : in  std_logic;
        cnf : in  std_logic_vector(6 downto 0);
        ro  : out std_logic_vector(1 downto 0));
	end component;

	attribute KEEP_HIERARCHY : string;
	attribute RLOC_ORIGIN : string;
	attribute RLOC : string;

begin	

  bnky: for y in 0 to Ny-1 generate  
      bnkx: for x in 0 to Nx-1 generate
      
          y2:   if(y = (y/2)*2) generate  -- even rows
                    attribute KEEP_HIERARCHY of p : label is "TRUE";
                    attribute RLOC of p : label is 
                        "X" & integer'image(integer(x*2)) & "Y" & integer'image(integer(y));
                begin
          p:    roc 
                    port map(
                        enx => enx, 
                        eny => eny, 
                        cnf => cnf2, 
				        ro  => ro(2*x+2*y*Nx+1 downto 2*x+2*y*Nx));
                end generate y2;
              
          y1:   if(y /= (y/2)*2) generate  -- odd rows
                    attribute KEEP_HIERARCHY of p : label is "TRUE";
                    attribute RLOC of p : label is 
                        "X" & integer'image(integer((Nx-x-1)*2)) & "Y" & integer'image(integer(y));
                begin
          p:    roc 
                    port map(
                        enx => enx, 
                        eny => eny, 
                        cnf => cnf1, 
				        ro  => ro(2*x+2*y*Nx+1 downto 2*x+2*y*Nx));
                end generate y1;  
                         
            end generate bnkx;
        end generate bnky;

end FPGA;