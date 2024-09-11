--
-- puf.vhd - VHDL code for top level TRNGR4_2.0
-- santiago@imse-cnm.csic.es (21/07/2023)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use WORK.puf_pkg.all;

entity puf is
	generic(
        Nx  : integer := 1; 	   	-- Number of columns of CLBs  (Must be a power of two!)
        Ny  : integer := 2;	        -- Number of rows of CLBs
        Xo  : integer := 6;		    -- ROQ_bank Position X           
        Yo  : integer := 15;		-- ROQ_bank Position Y           
        Bpc : integer := 4; 	   	-- Operation(4)/Characterization(32)
        Dbw : integer := 64; 	   	-- AXI4-Lite Data Bus Width
        Mnc : integer := 4096; 	   	-- Maximum number of comparisons
        Nbc : integer := 14);		-- Number of bits of counters    
	port (
		clock    : in  std_logic;	                                                -- Clock
		reset    : in  std_logic;	                                                -- Reset
		puf_str  : in  std_logic;	                                                -- PUF_Start
        BG       : in boolean;                                                      -- Binary/Gray code																							 
        SD       : in boolean;                                                      -- Same/Different location LUTs																							 
		cnfa     : in  std_logic_vector(1 downto 0);	                            -- And gate selection for ROs 
		n_cmps   : in  std_logic_vector(clog2(Mnc) downto 0);	                    -- Number of comparations (<= Nº ROs)
		puf_addr : in  std_logic_vector(clog2(Mnc*Bpc/Dbw-1) downto 0);	            -- PUF Read Address
		puf_addw : out std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);	            -- PUF Write Address
		puf_end  : out std_logic;									                -- PUF_end signal
		puf_out  : out std_logic_vector(Dbw-1 downto 0));				            -- PUF Output data
end entity;

architecture FPGA of puf is

    component puf_ctrl is
	  generic(
        Dbw : integer;              -- AXI4-Lite Data Bus Width
        Bpc : integer;              -- Operation(4)/Characterization(32)
        Mnc : integer; 	   	        -- Maximum number of comparisons
        Nx  : integer;              -- Number of columns of CLBs 
        Ny  : integer);             -- Number of rows of CLBs
	  port (
		clock    : in std_logic;                                              -- System Clock
		reset    : in std_logic;                                              -- System Reset
		n_cmps   : in  std_logic_vector(clog2(Mnc) downto 0);           -- Number of Comparisons 
		puf_str  : in std_logic;                                              -- PUF Start 
		cmp_end  : in std_logic;                                              -- Comparison End 
		sel_inc  : out std_logic;                                             -- Challenge Selection Clock
		cmp_rst  : out std_logic;                                             -- Comparison Reset 
		cmp_str  : out std_logic;                                             -- Comparison Start 
		cmp_cap  : out std_logic;                                             -- Comparison Capture Data
		puf_ldr  : out std_logic;                                             -- PUF Load Register 
		puf_wa   : out std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);   -- PUF Wtrite Address
		puf_end  : out std_logic);                                            -- PUF End operation
    end component;

    component roc_chl is
	  generic(
        Nx  : integer; 	                                            -- Number of columns of CLBs 
        Ny  : integer);	                                            -- Number of rows of CLBs
	  port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        cnf1   : out std_logic_vector(5 downto 0);
        cnf2   : out std_logic_vector(5 downto 0));  
    end component;
    
	component roc_bnk
	  generic(
        Nx  : integer; 	                                            -- Number of columns of CLBs 
        Ny  : integer);                                             -- Number of rows of CLBs
	  port (
        enx  : in  std_logic;
        eny  : in  std_logic;
        cnf1 : in  std_logic_vector(6 downto 0);
        cnf2 : in  std_logic_vector(6 downto 0);
		ro   : out std_logic_vector((2*Nx*Ny)-1 downto 0));		
	end component;

    component roc_bxt is
	  generic(
        Nbc : integer);											    -- Number of bits of counters
	  port (
		BG       : in boolean;  	                                -- Binary/Gray code
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
    end component;
    
    component puf_mem is
	generic(
        Dbw : integer; 	  	                                                -- AXI4-Lite Data Bus Width
        Bpc : integer; 	   	                                                -- Operation(4)/Characterization(32)
        Mnc : integer; 	   	                                                -- Maximum number of comparisons
        Nx  : integer;                                           	        -- Number of columns of CLBs 
        Ny  : integer);                                         	        -- Number of rows of CLBs
	port (
		clk_w   : in std_logic;                                             -- Clock for Write operations
		clk_r   : in std_logic;                                             -- Clock for Read operations
		clk_sr  : in std_logic;                                             -- Clock for Shift Register
		reset   : in std_logic;                                             -- Global Reset
		cmp_out : in std_logic_vector(Bpc-1 downto 0);                      -- Comparison Output
		puf_wa  : in std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);         -- PUF Write Address (max: ROs*4/32) --- Char
		puf_ra  : in std_logic_vector(clog2(Mnc*Bpc/Dbw-1) downto 0);       -- PUF Read Address (max: ROs*4/32)  --- Char
		puf_out : out std_logic_vector(Dbw-1 downto 0));                    -- PUF Output (for puf_rra)
    end component;  
    
	attribute KEEP_HIERARCHY : string;
	attribute RLOC_ORIGIN    : string;

    attribute KEEP_HIERARCHY of robk  : label is "TRUE";
    attribute RLOC_ORIGIN of robk : label is 
                "X" & integer'image(integer(Xo)) & "Y" & integer'image(integer(Yo));
	   
    signal sel_inc   : std_logic; 

	signal s_cnf1    : std_logic_vector(6 downto 0);
	signal s_cnf2    : std_logic_vector(6 downto 0);

	signal en_x      : std_logic_vector(2*Nx-1 downto 0);
    signal en_y      : std_logic_vector(Ny-1 downto 0);    
	signal ro_0      : std_logic;
	signal ro_1      : std_logic;
	signal ro_2      : std_logic;
	signal ro_3      : std_logic;
	signal ro_b      : std_logic_vector(2*Nx*Ny-1 downto 0);	
	signal en_ro     : std_logic;

	signal counter1  : std_logic_vector(Nbc-1 downto 0);
	signal counter2  : std_logic_vector(Nbc-1 downto 0);
	signal counter3  : std_logic_vector(Nbc-1 downto 0);
	signal counter4  : std_logic_vector(Nbc-1 downto 0);
	signal rdata1    : std_logic_vector(Nbc-1 downto 0);
	signal rdata2    : std_logic_vector(Nbc-1 downto 0);
	signal full1     : std_logic;
	signal full2     : std_logic;
	signal full3     : std_logic;
	signal full4     : std_logic;
	signal busy      : std_logic;
	signal s_busy_1  : std_logic;
	signal s_busy_2  : std_logic;
	
	signal cmp_rst   : std_logic;
	signal cmp_str   : std_logic;
	signal cmp_end   : std_logic;
	signal cmp_cap   : std_logic;
	
	signal puf_wa    : std_logic_vector(clog2(Mnc*Bpc/Dbw) downto 0);
	signal puf_ldr   : std_logic;
 	signal cmp_out   : std_logic_vector(Bpc-1 downto 0);  
 	    	
begin	

	pctrl: puf_ctrl
		generic map (Dbw => Dbw, Bpc => Bpc, Mnc => Mnc, Nx => Nx, Ny => Ny)
		port map (clock => clock, reset => reset, n_cmps => n_cmps, puf_str => puf_str,
		          cmp_end => cmp_end, sel_inc => sel_inc,
		          cmp_rst => cmp_rst, cmp_str => cmp_str, cmp_cap => cmp_cap,      		          
		          puf_ldr => puf_ldr,  puf_wa => puf_wa, puf_end => puf_end);      		          
          		          
	rochl: roc_chl
		generic map (Nx => Nx, Ny => Ny)
		port map (clk => sel_inc, reset => reset, cnf1 => s_cnf1(5 downto 0), cnf2 => s_cnf2(5 downto 0));

	s_cnf1(6) <= cnfa(0);	          		          
	s_cnf2(6) <= cnfa(1);	
	          		          
	robk: roc_bnk
		generic map (Nx => Nx, Ny => Ny)
		port map (enx => en_ro, eny => en_ro, cnf1 => s_cnf1, cnf2 => s_cnf2, ro => ro_b);
	
	ro_0 <= ro_b(0);
	ro_1 <= ro_b(2) when SD else ro_b(3);
	ro_2 <= ro_b(1) when SD else ro_b(2);
	ro_3 <= ro_b(3) when SD else ro_b(1);
	
    robxt_1 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_0, ro2 => ro_1,
				 counter1 => counter1, counter2 => counter2, full1 => full1, full2 => full2,
				 busy => s_busy_1, rdata => rdata1);
				 
    robxt_2 : roc_bxt
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_2, ro2 => ro_3,
				 counter1 => counter3, counter2 => counter4, full1 => full3, full2 => full4,
				 busy => s_busy_2, rdata => rdata2);

	busy    <= s_busy_1 or s_busy_2;
	en_ro   <= busy;
	cmp_end <= not busy;
	
	pmem : puf_mem
		generic map (Dbw => Dbw, Bpc => Bpc, Mnc => Mnc, Nx => Nx, Ny => Ny)
		port map(clk_w => puf_ldr, clk_r => clock, clk_sr => busy, reset => reset, cmp_out => cmp_out, 
				 puf_wa => puf_wa, puf_ra => puf_addr, puf_out => puf_out);
 
    puf_addw <= puf_wa;
    
--  Capture comparison output   
    --
    OP: if Bpc = 4 generate             --  OPERATION
    process (cmp_cap)  
    begin
        if (rising_edge(cmp_cap)) then 
	        cmp_out(3) <= rdata2(1);              -- bit Nbc-1(2)
	        cmp_out(2) <= rdata2(0);              -- bit Nbc(2)
	        cmp_out(1) <= rdata1(1);              -- bit Nbc-1(1)
	        cmp_out(0) <= rdata1(0);              -- bit Nbc(1)
        end if;
    end process;	 
    end generate OP;
    --
    CH: if Bpc = 32  generate               --  CHARACTERIZATION
    process (cmp_cap)  
    begin
        if (rising_edge(cmp_cap)) then  
            cmp_out(31 downto Nbc+17) <= (others => '0');          
            cmp_out(Nbc+16) <= full1;               -- bit 0(1)
	        cmp_out(Nbc+15 downto 16) <= rdata1;    -- bits (1)
	        cmp_out(15 downto Nbc+1) <= (others => '0');
            cmp_out(Nbc) <= full3;                  -- bit 0(2)
	        cmp_out(Nbc-1 downto 0) <= rdata2;      -- bits (2)
        end if;
    end process;	 
    end generate CH;

end FPGA;

