--/**
--  * @file puf_ctrl.vhd
--  * @brief PUF Controller
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

entity puf_ctrl is
	generic(
        Dbw : integer := 64; 	   	                                      -- AXI4-Lite Data Bus Width
        Bpc : integer := 8; 	   	                                      -- Operation(4)/Characterization(32)
        Mnc : integer := 2048; 	   	                                      -- Maximum number of comparisons
        Nx  : integer := 2; 		                                      -- Number of columns of CLBs 
        Ny  : integer := 2);		                                      -- Number of rows of CLBs 15
	port (
		clock    : in std_logic;                                          -- System Clock
		reset    : in std_logic;                                          -- System Reset
		n_cmps   : in  std_logic_vector(clog2(Mnc) downto 0);             -- Number of Comparisons 
		puf_str  : in std_logic;                                          -- PUF Start 
		cmp_end  : in std_logic;                                          -- Comparison End 
		sel_inc  : out std_logic;                                         -- Challenge Selection Clock
		cmp_rst  : out std_logic;                                         -- Comparison Reset 
		cmp_str  : out std_logic;                                         -- Comparison Start 
		cmp_cap  : out std_logic;                                         -- Comparison Capture Data
		puf_ldr  : out std_logic;                                         -- PUF Load Register 
		puf_wa   : out std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);     -- PUF Wtrite Address
		puf_end  : out std_logic);                                        -- PUF End operation
end entity;

architecture FPGA of puf_ctrl is

	type state_t is (IDLE, CMP_INC, CMP_RESET, CMP_DLY, CMP_START, CMP_CYCLE, CMP_CAPTURE);
	signal state, next_state : state_t;
	
	signal s_cmp_end  : std_logic;
	signal s_cmp_rst  : std_logic;
	signal s_cmp_str  : std_logic;
	signal s_cmp_cap  : std_logic;
	signal s_sel_inc  : std_logic;
	signal regfull    : std_logic;
	signal s_puf_ldr  : std_logic;
	signal s_puf_end  : std_logic;
	signal done       : std_logic;
	signal countc     : std_logic_vector(clog2(Mnc) downto 0);
	signal ncmps      : std_logic_vector(clog2(Mnc) downto 0);
		
begin

    -- Generate s_cmp_end
	process (clock, reset)  
    begin
        if (reset='1') then
            s_cmp_end <= '0';
		elsif (rising_edge(clock)) then
            s_cmp_end <= cmp_end;
        end if;
    end process;
                    
   -- State of FSM
   process (clock, reset) 
   begin
		if (reset='1') then
			state <= IDLE;
		elsif (rising_edge(clock)) then
			state <= next_state; 
		end if;
	end process;

  	-- Generate cmp_rst, cmp_str, cmp_cap, sel_inc
	process(puf_str, s_cmp_end, s_puf_end, state)
	begin
		s_cmp_rst <= '0';
		s_cmp_str <= '0';
		s_cmp_cap <= '0';
		s_sel_inc <= '0';
		case(state) is
			when IDLE =>
				s_cmp_rst <= '0';
				s_cmp_str <= '0';
				s_cmp_cap <= '0';
				s_sel_inc <= '0';
				if(puf_str='1' and s_puf_end='0') then next_state <= CMP_INC;
				else next_state <= IDLE;
				end if;		
			when CMP_INC =>
				s_sel_inc <= '1';
				next_state <= CMP_RESET;
			when CMP_RESET =>
				s_cmp_rst <= '1';
				next_state <= CMP_DLY;
			when CMP_DLY =>
				s_cmp_rst <= '0';
				next_state <= CMP_START;
			when CMP_START =>
				s_cmp_str <= '1';
				next_state <= CMP_CYCLE;
			when CMP_CYCLE =>
				s_cmp_str <= '0';
				if(s_cmp_end='1') then next_state <= CMP_CAPTURE;
				else next_state <= CMP_CYCLE;
				end if;				
			when CMP_CAPTURE =>
				s_cmp_cap <= '1';
				next_state <= IDLE;
		    when others => 
				next_state <= IDLE;
		end case;
	end process;
	
	cmp_rst <= s_cmp_rst;	
	cmp_str <= s_cmp_str;	
	cmp_cap <= s_cmp_cap;	
	sel_inc <= s_sel_inc;	
		
    OP1 : if Bpc = 64 generate   -- OPERATION
        D32: if Dbw = 32  generate
    ncmps <= n_cmps when  n_cmps(2 downto 0) = "000" else  
             n_cmps(clog2(Mnc) downto 3) +1 & "000" ;   -- round to the next multiple of 8
        end generate D32;
        D64: if Dbw = 64  generate
    ncmps <= n_cmps when  n_cmps(3 downto 0) = "0000" else  
             n_cmps(clog2(Mnc) downto 4) +1 & "0000" ;   -- round to the next multiple of 16
        end generate D64;           
    end generate OP1;
    
    CH1 : if Bpc = 32 generate  -- CHARACTERIZATION
    ncmps <= n_cmps;
    end generate CH1;
   
  	-- Increment comparisons counter and generate regfull and puf_end
    --
    OP2 : if Bpc = 64 generate   -- OPERATION
	process (s_cmp_cap, reset)  
    begin
        if (reset='1') then
            countc <= (others => '0');
            regfull <= '0';      
            s_puf_end <= '0';
       elsif (rising_edge(s_cmp_cap)) then        
            if (countc < ncmps) then
                countc <= countc + 1;
            end if;
            regfull <= '1';
            if (countc = ncmps) then
                s_puf_end <= '1';
            end if;
        end if;
    end process; 
    puf_end <= s_puf_end;
    end generate OP2;
    --
    CH2 : if Bpc = 32 generate  -- CHARACTERIZATION
    --
    CH264 : if Dbw = 64 generate    
	process (s_cmp_cap, reset)  
    begin
        if (reset='1') then
            countc <= (others => '0');
            regfull <= '0';      
            s_puf_end <= '0';
        elsif (rising_edge(s_cmp_cap)) then        
            if (countc < ncmps) then
                countc <= countc + 1;
            end if;
            if (countc(0) = '1') then
                regfull <= '1';
            else
                regfull <= '0'; 
            end if;
            if (countc = ncmps) then
                s_puf_end <= '1';
            end if;
        end if;
    end process; 
    puf_end <= s_puf_end;
    end generate CH264;
    --
    CH232 : if Dbw = 32 generate    
	process (s_cmp_cap, reset)  
    begin
        if (reset='1') then
            countc <= (others => '0');
            regfull <= '0';      
            s_puf_end <= '0';
        elsif (rising_edge(s_cmp_cap)) then        
            if (countc < ncmps) then
                countc <= countc + 1;
            end if;
            regfull <= '1';
            if (countc = ncmps) then
                s_puf_end <= '1';
            end if;
        end if;
    end process; 
    puf_end <= s_puf_end;
    end generate CH232;
    --
    end generate CH2;
 
  	-- Generate puf_ldr
	process (clock, reset)  
    begin
        if (reset='1') then
            s_puf_ldr <= '0';
		elsif (rising_edge(clock)) then
            -- s_puf_ldr <= regfull and not s_cmp_end;
            s_puf_ldr <= regfull and not cmp_end;
        end if;
    end process;
    puf_ldr <= s_puf_ldr;
            
    -- Generate puf_wa
    --
    OP3 : if Bpc = 64 generate   -- OPERATION
	process (s_puf_ldr, reset)  
    begin
        if (reset='1') then
            puf_wa <= (others => '0');
		elsif (rising_edge(s_puf_ldr)) then
            puf_wa <= countc(clog2(Mnc) downto clog2(Dbw)-6);
        end if;
    end process;
    end generate OP3;
    --
    CH3 : if Bpc = 32 generate  -- CHARACTERIZATION
	process (s_puf_ldr, reset)  
    begin
        if (reset='1') then
            puf_wa <= (others => '0');
		elsif (rising_edge(s_puf_ldr)) then
            puf_wa <= countc(clog2(Mnc) downto clog2(Dbw)-5);  
        end if;
    end process;
    end generate CH3;
    		
end FPGA;
