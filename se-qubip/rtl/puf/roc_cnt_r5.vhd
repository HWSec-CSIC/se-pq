--
-- roc_cnt.vhd - VHDL code for binary/Gray counter
-- santiago@imse-cnm.csic.es (02/06/2023)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;

entity roc_cnt_r5 is
	generic(
        Nbc : integer := 4 );	-- Number of bits
	port (
		BG       : in boolean;
		clk      : in std_logic;
		rst      : in std_logic;
		count_en : in std_logic;
		full     : out std_logic;
		counter  : out std_logic_vector(Nbc-1 downto 0));
end entity;

architecture FPGA of roc_cnt_r5 is

	signal next_binary_count  : std_logic_vector (Nbc-1 downto 0);
	signal binary_count       : std_logic_vector (Nbc-1 downto 0);
	signal gray_count         : std_logic_vector (Nbc-1 downto 0);
    signal mask               : std_logic_vector (Nbc-2 downto 0);

begin

    mask(Nbc-2 downto 3) <= (others => '0');
    mask(2 downto 0) <= "100";
	
	next_binary_count <= binary_count + 1; 

	process (clk, rst, count_en)  
    begin
        if rst='1' then
			gray_count   <= (others => '0');
			binary_count <= (others => '0');
            full <= '0';       
        elsif (rising_edge(clk) and count_en='1')  then        
            binary_count <= next_binary_count;
            gray_count <= (('0' & next_binary_count(Nbc-1 downto 1)) XOR next_binary_count);
            if ( gray_count(Nbc-1)='1' and gray_count(Nbc-2 downto 0)= mask ) then
                full <= '1';           
            end if;
        end if;
    end process;
    
    counter <= binary_count when BG else gray_count;

end FPGA;

