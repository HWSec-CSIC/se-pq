--
-- puf_mem.vhd - VHDL code for PUF4R5_2.1 PUF Memory
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

use WORK.puf_pkg.all;

entity puf_mem_r5 is
	generic(
        Dbw : integer := 32; 	   	                                          -- AXI4-Lite Data Bus Width
        Bpc : integer := 4; 	   	                                          -- Operation(4)/Characterization(32)
        Nx  : integer := 4;                                                   -- Number of columns of CLBs 
        Ny  : integer := 4);                                                  -- Number of rows of CLBs
	port (
		clk_w   : in std_logic;                                               -- Clock for Write operations
		clk_r   : in std_logic;                                               -- Clock for Read operations
		clk_sr  : in std_logic;                                               -- Clock for Shift Register
		reset   : in std_logic;                                               -- Global Reset
		cmp_out : in std_logic_vector(Bpc-1 downto 0);                        -- Comparison Output  
		puf_wa  : in std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw) downto 0);     -- PUF Write Address (max: ROs*8 -- ROs)
		puf_ra  : in std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw-1) downto 0);   -- PUF Read Address (max: ROs*8 -- ROs)
	puf_out : out std_logic_vector(Dbw-1 downto 0));                      -- PUF Output (for puf_rra)
end entity;

architecture FPGA of puf_mem_r5 is
 
    type ram_type is array(512*Nx*Ny*Bpc/Dbw-1 downto 0) of std_logic_vector (Dbw-1 downto 0);
    signal puf_memory  : ram_type;

    signal puf_reg_in   : std_logic_vector(Dbw-1 downto 0);  
    signal puf_reg_out  : std_logic_vector(Dbw-1 downto 0);  
   
begin

  	-- Encapsulate PUF output in 32/64-bit registers  
  	-- 
    OP1: if Bpc = 4 generate                         -- OPERATION
    process (clk_sr, reset)
    begin
        if (reset='1') then
            puf_reg_in <= (others => '0');
        elsif (rising_edge(clk_sr)) then
            puf_reg_in <= puf_reg_in(Dbw-5 downto 0) & cmp_out;
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
    OP2: if Bpc = 4 generate                         -- OPERATION
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
