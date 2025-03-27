--
-- roc_en.vhd - VHDL code for PUF4R5_2.1 Enable Generator
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

use WORK.puf_pkg.all;

entity roc_en_r5 is
	generic(
        Nx  : integer := 4; 	-- Number of columns of CLBs 
        Ny  : integer := 4);	-- Number of rows of CLBs
	port (
        en_ro   : in std_logic;
		sel1    : in std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO1 selector
		sel2    : in std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO2 selector
		sel3    : in std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO3 selector
		sel4    : in std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO3 selector
        en_x    : out std_logic_vector(2*Nx-1 downto 0);
        en_y    : out std_logic_vector(Ny-1 downto 0));
end entity;

architecture FPGA of roc_en_r5 is

    signal en_x1 : std_logic_vector(2*Nx-1 downto 0);
    signal en_x2 : std_logic_vector(2*Nx-1 downto 0);
    signal en_x3 : std_logic_vector(2*Nx-1 downto 0);
    signal en_x4 : std_logic_vector(2*Nx-1 downto 0);

    signal en_y1 : std_logic_vector(Ny-1 downto 0);
    signal en_y2 : std_logic_vector(Ny-1 downto 0);
    signal en_y3 : std_logic_vector(Ny-1 downto 0);
    signal en_y4 : std_logic_vector(Ny-1 downto 0);
       
    signal selx1 : std_logic_vector(clog2(2*Nx-1) downto 0);
    signal sely1 : std_logic_vector(clog2(Ny-1) downto 0);
    signal selx2 : std_logic_vector(clog2(2*Nx-1) downto 0);
    signal sely2 : std_logic_vector(clog2(Ny-1) downto 0);
    signal selx3 : std_logic_vector(clog2(2*Nx-1) downto 0);
    signal sely3 : std_logic_vector(clog2(Ny-1) downto 0);
    signal selx4 : std_logic_vector(clog2(2*Nx-1) downto 0);
    signal sely4 : std_logic_vector(clog2(Ny-1) downto 0);
        
begin

    selx1 <= sel1(clog2(2*Nx-1) downto 0);
    selx2 <= sel2(clog2(2*Nx-1) downto 0);
    selx3 <= sel3(clog2(2*Nx-1) downto 0);
    selx4 <= sel4(clog2(2*Nx-1) downto 0);
    sely1 <= sel1(clog2(2*Nx*Ny-1) downto clog2(Nx-1)+2);
    sely2 <= sel2(clog2(2*Nx*Ny-1) downto clog2(Nx-1)+2);
    sely3 <= sel3(clog2(2*Nx*Ny-1) downto clog2(Nx-1)+2);
    sely4 <= sel4(clog2(2*Nx*Ny-1) downto clog2(Nx-1)+2);
   
	process(selx1, selx2, selx3, selx4, sely1, sely2, sely3, sely4)
	begin

	  en_x1 <= (others => '0');
	  en_x2 <= (others => '0');
	  en_x3 <= (others => '0');
	  en_x4 <= (others => '0');
	  en_y1 <= (others => '0');
	  en_y2 <= (others => '0');
	  en_y3 <= (others => '0');
	  en_y4 <= (others => '0');
	
      en_x1(to_integer(unsigned(selx1))) <= '1';
      en_x2(to_integer(unsigned(selx2))) <= '1';
      en_x3(to_integer(unsigned(selx3))) <= '1';
      en_x4(to_integer(unsigned(selx4))) <= '1';
     
      en_y1(to_integer(unsigned(sely1))) <= '1';
      en_y2(to_integer(unsigned(sely2))) <= '1';
      en_y3(to_integer(unsigned(sely3))) <= '1';
      en_y4(to_integer(unsigned(sely4))) <= '1';
       
    end process;
	
    en_x   <=  (others => '0') when en_ro = '0' 
          else en_x1 or en_x2 or en_x3 or en_x4;
       
    en_y   <=  (others => '0') when en_ro = '0' 
          else en_y1 or en_y2 or en_y3 or en_y4;
    
end FPGA;
