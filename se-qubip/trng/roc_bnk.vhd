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