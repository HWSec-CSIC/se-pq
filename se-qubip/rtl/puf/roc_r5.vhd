--
-- roc.vhd - VHDL code for Configurable 4-stage ring_oscillator
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library ieee;
use ieee.std_logic_1164.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity roc_r5 is
    port(enx : in  std_logic_vector(1 downto 0);
         eny : in  std_logic;
         cnf : in  std_logic_vector(7 downto 0);
         ro  : out std_logic_vector(1 downto 0));        
end entity;

architecture FPGA of roc_r5 is
 
    signal w00, w10, w20, w30 :	std_logic;
    signal w01, w11, w21, w31 :	std_logic;
   
   	attribute ALLOW_COMBINATORIAL_LOOPS : string;  
    attribute DONT_TOUCH : string;
  
    attribute BEL  : string;
    attribute RLOC : string;

    attribute ALLOW_COMBINATORIAL_LOOPS of w00 : signal is "TRUE";       
    attribute DONT_TOUCH of w00 : signal is "TRUE"; 
    attribute DONT_TOUCH of w10 : signal is "TRUE"; 
    attribute DONT_TOUCH of w20 : signal is "TRUE"; 	
    attribute DONT_TOUCH of w30 : signal is "TRUE"; 	

    attribute ALLOW_COMBINATORIAL_LOOPS of w01 : signal is "TRUE";       
    attribute DONT_TOUCH of w01 : signal is "TRUE"; 
    attribute DONT_TOUCH of w11 : signal is "TRUE"; 
    attribute DONT_TOUCH of w21 : signal is "TRUE"; 	
    attribute DONT_TOUCH of w31 : signal is "TRUE"; 	

    attribute BEL  of and0  : label is "A6LUT"; 
    attribute BEL  of inv10 : label is "A6LUT"; 
    attribute BEL  of inv20 : label is "B6LUT"; 
    attribute BEL  of inv30 : label is "B6LUT"; 
    
    attribute RLOC of and0  : label is "X0Y0"; 
    attribute RLOC of inv10 : label is "X1Y0"; 
    attribute RLOC of inv20 : label is "X0Y0";
    attribute RLOC of inv30 : label is "X1Y0"; 

    attribute BEL  of and1  : label is "C6LUT"; 
    attribute BEL  of inv11 : label is "C6LUT"; 
    attribute BEL  of inv21 : label is "D6LUT"; 
    attribute BEL  of inv31 : label is "D6LUT"; 
    
    attribute RLOC of and1  : label is "X0Y0"; 
    attribute RLOC of inv11 : label is "X1Y0"; 
    attribute RLOC of inv21 : label is "X0Y0";
    attribute RLOC of inv31 : label is "X1Y0"; 

begin  
   
--  RO_0
	and0 : LUT6
		generic map (INIT => X"A000C000C000A000") 
		port map ( O => w00, I5 => cnf(7), I4 => cnf(6), I3 => eny, I2 => enx(0), I1 => w30, I0 => w30);	
	inv10 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w10, I5 => cnf(5), I4 => cnf(4), I3 => w00, I2 => w00, I1 => w00, I0 => w00);		
	inv20 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w20, I5 => cnf(3), I4 => cnf(2), I3 => w10, I2 => w10, I1 => w10, I0 => w10);
	inv30 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w30, I5 => cnf(1), I4 => cnf(0), I3 => w20, I2 => w20, I1 => w20, I0 => w20);

--  RO_1
	and1 : LUT6
		generic map (INIT => X"A000C000C000A000") 
		port map ( O => w01, I5 => cnf(7), I4 => cnf(6), I3 => eny, I2 => enx(1), I1 => w31, I0 => w31);		
	inv11 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w11, I5 => cnf(5), I4 => cnf(4), I3 => w01, I2 => w01, I1 => w01, I0 => w01);		
	inv21 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w21, I5 => cnf(3), I4 => cnf(2), I3 => w11, I2 => w11, I1 => w11, I0 => w11);
	inv31 : LUT6		
		generic map (INIT => X"555533330F0F00FF") 
		port map ( O => w31, I5 => cnf(1), I4 => cnf(0), I3 => w21, I2 => w21, I1 => w21, I0 => w21);

 	ro(0) <= w00;
 	ro(1) <= w01;
   
end FPGA;
