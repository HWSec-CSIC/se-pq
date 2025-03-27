--
-- roc_chl.vhd - VHDL code for PUF4R5_2.1 Challenge Generator 
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;
 
use WORK.puf_pkg.all;

entity roc_chl_r5 is
	generic(
        Nx  : integer := 4;              -- Number of columns of CLBs 
        Ny  : integer := 4);             -- Number of rows of true
    port(
		clk   : in  std_logic;
		reset : in  std_logic;
		cnf   : out std_logic_vector(7 downto 0);
        sel1  : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
        sel2  : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
        sel3  : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
        sel4  : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0));
end entity;

architecture FPGA of roc_chl_r5 is
   
    signal sel_clk  :  std_logic;
    signal s_cnf    :  std_logic_vector(7 downto 0);
    signal s_sel1   :  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
    signal s_sel2   :  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
    signal s_sel3   :  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
    signal s_sel4   :  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
    signal s_zero   :  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
    signal s_ones   :  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
    signal s_inc    :  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
    
 -- Nc = 2*Nx*floor(Ny/2)+2*floor(Nx/2);
    constant  Nc  :  integer := 2*Nx*(Ny/2)+2*(Nx/2);

begin

    s_inc  <= std_logic_vector(to_unsigned(Nc, clog2(2*Nx*Ny-1)+1));
	s_zero <= (others => '0'); 
	s_ones <= (others => '1'); 
	
	Config: process (clk, reset, s_sel1, s_ones, s_inc)  
    begin
        if reset='1' then
            s_cnf <= (others => '1');													  
            sel_clk <= '0';
        elsif rising_edge(clk) then       
            s_cnf <=  s_cnf + 1;
            if s_cnf="11111111" then
               sel_clk <= '1';
            else
               sel_clk <= '0';
            end if;
        end if;
    end process;
    
    Sel: process (sel_clk, reset, s_sel1, s_ones, s_inc)  
    begin
        if reset='1' then
            s_sel1  <= s_ones;
            s_sel2  <= s_ones + 1 + s_inc;
            s_sel3  <= s_ones + 2;
            s_sel4  <= s_ones + 4 + s_inc;            
        elsif rising_edge(sel_clk) then       
            s_sel1 <= s_sel1 + 1;
            if (s_sel1 = 2*Nx*Ny-1) then
                s_sel1 <= s_zero;
            end if;
            s_sel2 <= s_sel2 + 1;
            if (s_sel2 = 2*Nx*Ny-1) then
                s_sel2 <= s_zero;
            end if;
            s_sel3 <= s_sel3 + 1;
            if (s_sel3 = 2*Nx*Ny-1) then
                s_sel3 <= s_zero;
            end if;
            s_sel4 <= s_sel4 + 1;
            if (s_sel4 = 2*Nx*Ny-1) then
                s_sel4 <= s_zero;
            end if;
        end if;
    end process;
    
    sel1 <= s_sel1;
    sel2 <= s_sel2;
    sel3 <= s_sel3;
    sel4 <= s_sel4;
    cnf <=  s_cnf;
    
end FPGA;