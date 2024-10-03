--/**
--  * @file puf_mem.vhd
--  * @brief PUF Memory 
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

entity puf_mem is
	generic(
        Dbw : integer := 32; 	   	                                          -- AXI4-Lite Data Bus Width
        Bpc : integer := 4; 	   	                                          -- Operation(4)/Characterization(32)
        Mnc : integer := 4096; 	   	                                          -- Maximum number of comparisons
        Nx  : integer := 1;                                                   -- Number of columns of CLBs 
        Ny  : integer := 2);                                                  -- Number of rows of CLBs
	port (
		clk_w   : in std_logic;                                               -- Clock for Write operations
		clk_r   : in std_logic;                                               -- Clock for Read operations
		clk_sr  : in std_logic;                                               -- Clock for Shift Register
		reset   : in std_logic;                                               -- Global Reset
		cmp_out : in std_logic_vector(Bpc-1 downto 0);                        -- Comparison Output  
		puf_wa  : in std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);           -- PUF Write Address (max: ROs*8 -- ROs)
		puf_ra  : in std_logic_vector(clog2(Mnc*Bpc/Dbw-1) downto 0);         -- PUF Read Address (max: ROs*8 -- ROs)
		puf_out : out std_logic_vector(Dbw-1 downto 0));                      -- PUF Output (for puf_rra)
end entity;

architecture FPGA of puf_mem is
 
    type ram_type is array(Mnc*Bpc/Dbw-1 downto 0) of std_logic_vector (Dbw-1 downto 0);
    signal puf_memory  : ram_type;

    signal puf_reg_in   : std_logic_vector(Dbw-1 downto 0);  
    signal puf_reg_out  : std_logic_vector(Dbw-1 downto 0);  
   
begin

  	-- Encapsulate PUF output in 32/64-bit registers  
  	-- 
    OP1: if Bpc = 64 generate                         -- OPERATION
    process (clk_sr, reset)
    begin
        if (reset='1') then
            puf_reg_in <= (others => '0');
        elsif (rising_edge(clk_sr)) then
            puf_reg_in <= cmp_out;
        end if;
    end process;
    end generate OP1;
    --
    CH1: if Bpc = 32 generate                        -- CHARACTERIZATION
    --
    CH164: if Dbw = 64 generate                      -- 64-bit AXI
    process (clk_sr, reset)
    begin
        if (reset='1') then
            puf_reg_in <= (others => '0');
        elsif (rising_edge(clk_sr)) then
            puf_reg_in <= puf_reg_in(31 downto 0) & cmp_out;
        end if;
    end process;
    end generate CH164;    
    --
    CH132: if Dbw = 32 generate                      -- 32-bit AXI
    puf_reg_in <= cmp_out;
    end generate CH132;    
    --
    end generate CH1;    
         
    -- Write PUF register    
    --
    OP2: if Bpc = 64 generate                         -- OPERATION
    process(clk_w)
    begin
        if(rising_edge(clk_w)) then
            puf_memory(to_integer(unsigned(puf_wa))) <= puf_reg_in;
        end if;
    end process;  
    end generate OP2;
    --
    CH2: if Bpc = 32 generate                        -- CHARACTERIZATION
    process(clk_sr)
    begin
        if(rising_edge(clk_sr)) then
            puf_memory(to_integer(unsigned(puf_wa))) <= puf_reg_in;
        end if;
    end process;  
    end generate CH2;    

    -- Read PUF register
    process(clk_r)
    begin
        if (rising_edge(clk_r)) then
            puf_reg_out <= puf_memory(to_integer(unsigned(puf_ra)));
        end if;
    end process; 
     
    puf_out <= puf_reg_out;
       	
end FPGA;
