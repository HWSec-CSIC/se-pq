--
-- puf_ctrl.vhd - VHDL code for PUF4R5_2.1 controller
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

use WORK.puf_pkg.all;

entity puf_ctrl_r5 is
	generic(
        Dbw : integer := 32; 	   	                                      -- AXI4-Lite Data Bus Width
        Bpc : integer := 4; 	   	                                      -- Operation(4)/Characterization(32)
        Nx  : integer := 4; 		                                      -- Number of columns of CLBs 
        Ny  : integer := 4);		                                      -- Number of rows of CLBs 15
	port (
		clock    : in std_logic;                                          -- System Clock
		reset    : in std_logic;                                          -- System Reset
		n_cmps   : in  std_logic_vector(clog2(512*Nx*Ny) downto 0);       -- Number of Comparisons 
		puf_str  : in std_logic;                                          -- PUF Start 
		cmp_end  : in std_logic;                                          -- Comparison End 
		sel_mask : in std_logic;                                          -- Challenge Selection Mask 
		sel_inc  : out std_logic;                                         -- Challenge Selection Clock
		cmp_rst  : out std_logic;                                         -- Comparison Reset 
		cmp_str  : out std_logic;                                         -- Comparison Start 
		cmp_cap  : out std_logic;                                         -- Comparison Capture Data
		puf_ldr  : out std_logic;                                         -- PUF Load Register 
		puf_wa   : out std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw) downto 0);   -- PUF Wtrite Address
		puf_end  : out std_logic);                                        -- PUF End operation
end entity;

architecture FPGA of puf_ctrl_r5 is

	type state_t is (IDLE, CMP_CHECK, CMP_INC, CMP_RESET, CMP_DLY, CMP_START, CMP_CYCLE, CMP_CAPTURE);
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
	signal countc     : std_logic_vector(clog2(512*Nx*Ny) downto 0);
	signal ncmps      : std_logic_vector(clog2(512*Nx*Ny) downto 0);
		
begin

    -- Generate s_cmp_end
--	process (clock, reset)  
--    begin
--        if (reset='1') then
--            s_cmp_end <= '0';
--		elsif (rising_edge(clock)) then
--            s_cmp_end <= cmp_end;
--        end if;
--    end process;
	process (clock, reset)  
    begin
        if (rising_edge(clock)) then 
            if (reset='1') then
                s_cmp_end <= '0';
		    else
                s_cmp_end <= cmp_end;
            end if;    
        end if;
    end process;
                    
   -- State of FSM
--   process (clock, reset) 
--   begin
--		if (reset='1') then
--			state <= IDLE;
--		elsif (rising_edge(clock)) then
--			state <= next_state; 
--		end if;
--	end process;
   process (clock, reset) 
   begin
         if (rising_edge(clock)) then 
		    if (reset='1') then
               state <= IDLE;
            else
			   state <= next_state; 
			end if;
		end if;
	end process;

  	-- Generate cmp_rst, cmp_str, cmp_cap, sel_inc
	process(puf_str, sel_mask, s_cmp_end, s_puf_end, state)
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
				next_state <= CMP_CHECK;
			when CMP_CHECK =>
				s_sel_inc <= '0';    
			    if (sel_mask = '1') then
			        next_state <= CMP_INC;
				else
				    next_state <= CMP_RESET;
				end if; 
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
		
    OP1 : if Bpc = 4 generate   -- OPERATION
        D32: if Dbw = 32  generate
    ncmps <= n_cmps when  n_cmps(2 downto 0) = "000" else  
             n_cmps(clog2(512*Nx*Ny) downto 3) +1 & "000" ;   -- round to the next multiple of 8
        end generate D32;
        D64: if Dbw = 64  generate
    ncmps <= n_cmps when  n_cmps(3 downto 0) = "0000" else  
             n_cmps(clog2(512*Nx*Ny) downto 4) +1 & "0000" ;   -- round to the next multiple of 16
        end generate D64;           
    end generate OP1;
    
    CH1 : if Bpc = 32 generate  -- CHARACTERIZATION
    ncmps <= n_cmps;
    end generate CH1;
   
  	-- Increment comparisons counter and generate regfull and puf_end
    --
    OP2 : if Bpc = 4 generate   -- OPERATION
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
            if (countc(clog2(Dbw)-3 downto 0) = (Dbw/4)-1) then
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
--	process (clock, reset)  
--    begin
--        if (reset='1') then
--            s_puf_ldr <= '0';
--		elsif (rising_edge(clock)) then
--            s_puf_ldr <= regfull and not cmp_end;
--        end if;
--    end process;
	process (clock, reset)  
    begin
        if (rising_edge(clock)) then
            if (reset='1') then
                s_puf_ldr <= '0';
            else
                s_puf_ldr <= regfull and not cmp_end;
            end if;
        end if;
    end process;
    puf_ldr <= s_puf_ldr;
            
    -- Generate puf_wa
    --
    OP3 : if Bpc = 4 generate   -- OPERATION
	process (s_puf_ldr, reset)  
    begin
        if (reset='1') then
            puf_wa <= (others => '0');
		elsif (rising_edge(s_puf_ldr)) then
            puf_wa <= countc(clog2(512*Nx*Ny) downto clog2(Dbw)-2);
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
            puf_wa <= countc(clog2(512*Nx*Ny) downto clog2(Dbw)-5);  
        end if;
    end process;
    end generate CH3;
    		
end FPGA;
