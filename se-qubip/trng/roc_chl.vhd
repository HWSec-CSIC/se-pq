--
-- roc_chl.vhd - VHDL code for TRNGR4_2.0 Challenge Generator 
-- santiago@imse-cnm.csic.es (21/07/2023)
--

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

