--/**
--  * @file roc.vhd
--  * @brief VHDL code for Configurable 4-stage ring_oscillator for TRNG4R_2.0
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
-- roc.vhd - VHDL code for Configurable 4-stage ring_oscillator for TRNG4R_2.0
-- santiago@imse-cnm.csic.es (21/07/2023)
--

library ieee;
use ieee.std_logic_1164.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity roc is
    port(enx : in  std_logic;
         eny : in  std_logic;
         cnf : in  std_logic_vector(6 downto 0);
         ro  : out std_logic_vector(1 downto 0));        
end entity;

architecture FPGA of roc is
 
    signal w00, w10, w20, w30 :	std_logic;
    signal w01, w11, w21, w31 :	std_logic;
   
   	attribute ALLOW_COMBINATORIAL_LOOPS : string;  
    attribute DONT_TOUCH : string;
  
    attribute BEL  : string;
    attribute RLOC : string;

    attribute ALLOW_COMBINATORIAL_LOOPS of w00 : signal is "TRUE";       
    attribute DONT_TOUCH of w00 : signal is "TRUE"; 
    attribute DONT_TOUCH of w10 : signal is "TRUE"; 
    attribute DONT_TOUCH of w20 : signal is "TRUE"; 	
    attribute DONT_TOUCH of w30 : signal is "TRUE"; 	

    attribute ALLOW_COMBINATORIAL_LOOPS of w01 : signal is "TRUE";       
    attribute DONT_TOUCH of w01 : signal is "TRUE"; 
    attribute DONT_TOUCH of w11 : signal is "TRUE"; 
    attribute DONT_TOUCH of w21 : signal is "TRUE"; 	
    attribute DONT_TOUCH of w31 : signal is "TRUE"; 	

    attribute BEL  of and0  : label is "A5LUT"; 
    attribute BEL  of inv10 : label is "A6LUT"; 
    attribute BEL  of inv20 : label is "B6LUT"; 
    attribute BEL  of inv30 : label is "B6LUT"; 
    
    attribute RLOC of and0  : label is "X0Y0"; 
    attribute RLOC of inv10 : label is "X1Y0"; 
    attribute RLOC of inv20 : label is "X0Y0";
    attribute RLOC of inv30 : label is "X1Y0"; 

    attribute BEL  of and1  : label is "C5LUT"; 
    attribute BEL  of inv11 : label is "C6LUT"; 
    attribute BEL  of inv21 : label is "D6LUT"; 
    attribute BEL  of inv31 : label is "D6LUT"; 
    
    attribute RLOC of and1  : label is "X0Y0"; 
    attribute RLOC of inv11 : label is "X1Y0"; 
    attribute RLOC of inv21 : label is "X0Y0";
    attribute RLOC of inv31 : label is "X1Y0"; 

begin  
   
--  RO_0
	and0 : LUT5
		generic map (INIT => X"CA000000") 
		port map ( O => w00, I4 => eny, I3 => enx, I2 => cnf(6), I1 => w30, I0 => w30);	
	inv10 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w10, I5 => cnf(5), I4 => cnf(4), I3 => w00, I2 => w00, I1 => w00, I0 => w00);		
	inv20 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w20, I5 => cnf(3), I4 => cnf(2), I3 => w10, I2 => w10, I1 => w10, I0 => w10);
	inv30 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w30, I5 => cnf(1), I4 => cnf(0), I3 => w20, I2 => w20, I1 => w20, I0 => w20);

--  RO_1
	and1 : LUT5
		generic map (INIT => X"CA000000") 
		port map ( O => w01, I4 => eny, I3 => enx, I2 => cnf(6), I1 => w31, I0 => w31);		
	inv11 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w11, I5 => cnf(5), I4 => cnf(4), I3 => w01, I2 => w01, I1 => w01, I0 => w01);		
	inv21 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w21, I5 => cnf(3), I4 => cnf(2), I3 => w11, I2 => w11, I1 => w11, I0 => w11);
	inv31 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w31, I5 => cnf(1), I4 => cnf(0), I3 => w21, I2 => w21, I1 => w21, I0 => w21);

 	ro(0) <= w00;
 	ro(1) <= w01;
   
end FPGA;
