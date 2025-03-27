--
-- chl_mem.vhd - VHDL code for PUF4R5_2.1 Challenges Mask Memory
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use WORK.puf_pkg.all;

entity chl_mem_r5 is
	generic(
        Dbw : integer := 32; 	  	                                  	          -- AXI4-Lite Data Bus Width
        Nx  : integer := 4;                                           	          -- Number of columns of CLBs 
        Ny  : integer := 4);                                          	          -- Number of rows of CLBs
	port (
        clock    : in  std_logic;                                     	          -- System Clock
        reset    : in  std_logic;                                     	          -- System Reset
		mem_ctrl : in  std_logic_vector(1 downto 0);                  	          -- Challenges Memory Control
		mem_wadd : in  std_logic_vector(clog2((512*Nx*Ny+Dbw-1)/Dbw)-1 downto 0); -- Challenges Memory Write Address
		mem_wdat : in  std_logic_vector(Dbw-1 downto 0);                          -- Challenges Memory Write Data
		chl_sel1 : in  std_logic_vector(clog2(512*Nx*Ny-1) downto 0);   	      -- Challenges Memory Read Address
	sel_mask : out std_logic); 									  	              -- Delete Challenge
end entity;

architecture FPGA of chl_mem_r5 is
 
    type ram_type is array ((512*Nx*Ny+Dbw-1)/Dbw downto 0) of std_logic_vector (Dbw-1 downto 0);
    signal chl_memory : ram_type;
	
 	signal s_mem_wclock : std_logic;
    signal s_mem_wadd   : std_logic_vector(clog2((512*Nx*Ny+Dbw-1)/Dbw)-1 downto 0);
	signal s_mem_wdat   : std_logic_vector(Dbw-1 downto 0);
	
	signal s_mem_rclock : std_logic;
    signal s_mem_radd   : std_logic_vector(clog2((512*Nx*Ny+Dbw-1)/Dbw)-1 downto 0);
    signal s_mem_rbit   : std_logic_vector(clog2(Dbw)-1 downto 0);  
	signal s_mem_rdat   : std_logic_vector(Dbw-1 downto 0);
 
	-- signal s_sel_mask   : std_logic;
   
begin

	s_mem_wclock <= mem_ctrl(0);
    s_mem_wadd   <= mem_wadd(clog2((512*Nx*Ny+Dbw-1)/Dbw)-1 downto 0);
    s_mem_wdat   <= mem_wdat;
	
    s_mem_rclock <= mem_ctrl(1);  
	s_mem_radd   <= chl_sel1(clog2(512*Nx*Ny-1) downto clog2(Dbw));
	s_mem_rbit   <= chl_sel1(clog2(Dbw)-1 downto 0);
  	  
    -- Write Challenges Memory
    Write_mem: process (s_mem_wclock)
	begin
        if(rising_edge(s_mem_wclock)) then
            chl_memory(to_integer(unsigned(s_mem_wadd))) <= s_mem_wdat;
        end if;
    end process;
        
    s_mem_rdat <= chl_memory(to_integer(unsigned(s_mem_radd)));  
 
    -- Read Challenges Memory
    -- Read_mem: process(clock)
    -- begin
        -- if (reset = '1') then
 			-- sel_mask <= '0';
        -- elsif (rising_edge(clock)) then
			-- if (s_mem_rclock = '1') then
			    -- sel_mask <= s_mem_rdat(to_integer(unsigned(Dbw-1-s_mem_rbit))); 
			-- else
				-- sel_mask <= '0';
			-- end if;
        -- end if;
    -- end process; 

    -- Read Challenges Memory
    Read_mem: process(clock)
    begin
		if (rising_edge(clock)) then
			if (reset = '1') then
				sel_mask <= '0';
			else
				if (s_mem_rclock = '1') then
					sel_mask <= s_mem_rdat(to_integer(unsigned(Dbw-1-s_mem_rbit))); 
				else
					sel_mask <= '0';
				end if;
			end if;
        end if;
    end process; 

end FPGA;
