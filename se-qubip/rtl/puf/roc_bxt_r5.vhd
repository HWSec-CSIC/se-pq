--
-- roc_bxt.vhd - VHDL code for PUF4R5_2.1 Bit Extractor
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use WORK.puf_pkg.all;


entity roc_bxt_r5 is
	generic(
        Nbc : integer := 14);		-- Number of bits of counters
	port (
		BG    	 : in boolean;	                               		-- Binary/Gray code
		rst      : in std_logic;	                                -- Reset
		str      : in std_logic;	                                -- Start
		ro1      : in std_logic;	                                -- RO1 clk
		ro2      : in std_logic;	                                -- RO2 clk
		counter1 : out std_logic_vector(Nbc-1 downto 0);			-- RO1 counter
		counter2 : out std_logic_vector(Nbc-1 downto 0);			-- RO2 counter		
		full1    : out std_logic;									-- RO1 full signal
		full2    : out std_logic;									-- RO2 full signal
		busy     : out std_logic;									-- Busy output signal
		rdata    : out std_logic_vector(Nbc-1 downto 0));			-- Output data
end entity;

architecture FPGA of roc_bxt_r5 is

	component roc_cnt_r5
	  generic(
        Nbc : integer);	            -- Number of bits of counter
	  port (
		BG    	 : in boolean;
		clk      : in  std_logic;
		rst      : in  std_logic;
		count_en : in  std_logic;
		counter  : out std_logic_vector(Nbc-1 downto 0);
		full     : out std_logic );
	end component;

	
	signal cfull1    : std_logic;
	signal full_1    : std_logic;
	signal nfull_1   : std_logic;
	signal cfull2    : std_logic;
	signal full_2    : std_logic;
	signal nfull_2   : std_logic;
	signal full      : std_logic;
	signal counter_1 : std_logic_vector(Nbc-1 downto 0);
    signal counter_2 : std_logic_vector(Nbc-1 downto 0);
	signal rdata1    : std_logic_vector(Nbc-1 downto 0);
    
    	
begin	

    nfull_1 <= not full_1;
    nfull_2 <= not full_2;
    
    cnt1 : roc_cnt_r5
		generic map(Nbc => Nbc)
		port map(BG => BG, clk => ro1, rst => rst, count_en => nfull_2, 
				 counter => counter_1, full => full_1);
				 
	cnt2 : roc_cnt_r5
		generic map(Nbc => Nbc)
		port map(BG => BG, clk => ro2, rst => rst, count_en =>  nfull_1,
				 counter => counter_2, full => full_2);	
		
 	-- Generate enable signal for ROs
    process (str, full, rst)
      begin
        if (rising_edge(str)) then
            busy <= '1';
        end if;
        if (full='1' or rst='1') then
            busy <= '0';
        end if;
    end process;
  
	-- Generate output signals
	counter1 <= counter_1;
	counter2 <= counter_2;
	full     <= full_1 or full_2;	

	-- Output 0 if not (full1 or full2)
	-- Output counter_2 or counter_1 if (full1 or full2)    	
	rdata1 <= counter_2 when full_1='1' else counter_1;
	rdata <= rdata1 when full='1' else (others => '0');

 	-- Active first full signal
    process (rst, full_1, full_2)
      begin
        if (rst = '1') then
            full1 <= '0';
        elsif (rising_edge(full_1) and full_2='0') then
            full1 <= '1';
        end if;
        if rst = '1' then
            full2 <= '0';
        elsif (rising_edge(full_2) and full_1='0') then
            full2 <= '1';
        end if;
    end process;
		
end FPGA;
     