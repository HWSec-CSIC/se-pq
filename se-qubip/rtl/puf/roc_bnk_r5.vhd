--
-- roc_bnk.vhd - VHDL code for PUF4R5_2.1 Ring_Oscillator Bank
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;

entity roc_bnk_r5 is
	generic(
        Nx : integer := 4;	        -- Number of columns of CLBs 
        Ny : integer := 4);	        -- Number of rows of CLBs
	port (
        enx : in  std_logic_vector(2*Nx-1 downto 0);
        eny : in  std_logic_vector(Ny-1 downto 0);
        cnf : in  std_logic_vector(7 downto 0);
		ro  : out std_logic_vector((2*Nx*Ny)-1 downto 0));		
end entity;

architecture FPGA of roc_bnk_r5 is  

	component roc_r5
	port(
		enx : in  std_logic_vector(1 downto 0);
		eny : in  std_logic;
        cnf : in  std_logic_vector(7 downto 0);
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
          p:    roc_r5 
                    port map(
                        enx => enx(2*x+1 downto 2*x), 
                        eny => eny(y), 
                        cnf => cnf, 
				        ro  => ro(2*x+2*y*Nx+1 downto 2*x+2*y*Nx));
                end generate y2;
              
          y1:   if(y /= (y/2)*2) generate  -- odd rows
                    attribute KEEP_HIERARCHY of p : label is "TRUE";
                    attribute RLOC of p : label is 
                        "X" & integer'image(integer((Nx-x-1)*2)) & "Y" & integer'image(integer(y));
                begin
          p:    roc_r5 
                    port map(
                        enx => enx(2*x+1 downto 2*x), 
                        eny => eny(y), 
                        cnf => cnf, 
				        ro  => ro(2*x+2*y*Nx+1 downto 2*x+2*y*Nx));
                end generate y1;  
                         
            end generate bnkx;
        end generate bnky;

end FPGA;