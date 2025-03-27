--
-- puf.vhd - VHDL code for top level PUF4R5_2.1
-- santiago@imse-cnm.csic.es (07/01/2024)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use WORK.puf_pkg.all;

entity puf_r5 is
	generic(
        Nx  : integer := 4; 	   	-- Number of columns of CLBs  (Must be a power of two!)
        Ny  : integer := 4;	        -- Number of rows of CLBs
        Xo  : integer := 6;		    -- ROQ_bank Position X           
        Yo  : integer := 15;		-- ROQ_bank Position Y           
        Bpc : integer := 4; 	   	-- Operation(4)/Characterization(32)
        Dbw : integer := 32; 	   	-- AXI4-Lite Data Bus Width
        Nbc : integer := 14);		-- Number of bits of counters    
	port (
		clock    : in  std_logic;	                                                -- Clock
		reset    : in  std_logic;	                                                -- Reset
		puf_str  : in  std_logic;	                                                -- PUF_Start
        PE       : in boolean;                                                      -- PUF/Entropy Source
        BG       : in boolean;                                                      -- Binary/Gray code																							 
        LH       : in boolean;                                                      -- Lower/Higher bits																			
		n_cmps   : in  std_logic_vector(clog2(512*Nx*Ny) downto 0);	                -- Number of comparations (<= Nº ROs)
		mem_ctrl : in  std_logic_vector(1 downto 0);                                -- Challenges Memory Control
		mem_wadd : in  std_logic_vector(clog2((512*Nx*Ny+Dbw-1)/Dbw)-1 downto 0);   -- Challenges Memory Write Address
		mem_wdat : in  std_logic_vector(Dbw-1 downto 0);                            -- Challenges Memory Write Data
		puf_addr : in  std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw-1) downto 0);	    -- PUF Read Address
		puf_addw : out std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw) downto 0);	        -- PUF Write Address
		puf_end  : out std_logic;									                -- PUF_end signal
		puf_out  : out std_logic_vector(Dbw-1 downto 0));				            -- PUF Output data
end entity;

architecture FPGA of puf_r5 is

    component puf_ctrl_r5 is
	  generic(
        Dbw : integer;              -- AXI4-Lite Data Bus Width
        Bpc : integer;              -- Operation(4)/Characterization(32)
        Nx  : integer;              -- Number of columns of CLBs 
        Ny  : integer);             -- Number of rows of CLBs
	  port (
		clock    : in std_logic;                                              -- System Clock
		reset    : in std_logic;                                              -- System Reset
		n_cmps   : in  std_logic_vector(clog2(512*Nx*Ny) downto 0);           -- Number of Comparisons 
		puf_str  : in std_logic;                                              -- PUF Start 
		cmp_end  : in std_logic;                                              -- Comparison End 
		sel_mask : in std_logic;                                              -- Challenge Selection Mask 
		sel_inc  : out std_logic;                                             -- Challenge Selection Clock
		cmp_rst  : out std_logic;                                             -- Comparison Reset 
		cmp_str  : out std_logic;                                             -- Comparison Start 
		cmp_cap  : out std_logic;                                             -- Comparison Capture Data
		puf_ldr  : out std_logic;                                             -- PUF Load Register 
		puf_wa   : out std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw) downto 0);   -- PUF Wtrite Address
	    puf_end  : out std_logic);                                            -- PUF End operation
    end component;

    component chl_mem_r5 is
	  generic(
        Dbw : integer; 	  	                                                      -- AXI4-Lite Data Bus Width
        Nx  : integer;                                                            -- Number of columns of CLBs 
        Ny  : integer);                                                           -- Number of rows of CLBs
	port (
        clock    : in  std_logic;                                                 -- System Clock
        reset    : in  std_logic;                                                 -- System Reset
		mem_ctrl : in  std_logic_vector(1 downto 0);                              -- Challenges Memory Control
		mem_wadd : in  std_logic_vector(clog2((512*Nx*Ny+Dbw-1)/Dbw)-1 downto 0); -- Challenges Memory Write Address
		mem_wdat : in  std_logic_vector(Dbw-1 downto 0);                          -- Challenges Memory Write Data
		chl_sel1 : in  std_logic_vector(clog2(512*Nx*Ny-1) downto 0);             -- Challenges Memory Read Address
	    sel_mask : out std_logic); 									              -- Delete Challenge
    end component;

    component roc_chl_r5 is
	  generic(
        Nx  : integer; 	                                            -- Number of columns of CLBs 
        Ny  : integer);	                                            -- Number of rows of CLBs
	  port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        cnf    : out std_logic_vector(7 downto 0);
		sel1   : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO1 selector
		sel2   : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO2 selector
		sel3   : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO3 selector
		sel4   : out std_logic_vector(clog2(2*Nx*Ny-1) downto 0));-- RO4 selector
    end component;
    
    component roc_en_r5 is
	  generic(
        Nx  : integer; 	                                            -- Number of columns of CLBs 
        Ny  : integer);	                                            -- Number of rows of CLBs
	  port (
        en_ro  : in  std_logic;
		sel1   : in  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO1 selector
		sel2   : in  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO2 selector
		sel3   : in  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO1 selector
		sel4   : in  std_logic_vector(clog2(2*Nx*Ny-1) downto 0);	-- RO2 selector
        en_x   : out std_logic_vector(2*Nx-1 downto 0);
        en_y   : out std_logic_vector(Ny-1 downto 0));
    end component;

	component roc_bnk_r5
	  generic(
        Nx  : integer; 	                                            -- Number of columns of CLBs 
        Ny  : integer);                                             -- Number of rows of CLBs
	  port (
        enx : in  std_logic_vector(2*Nx-1 downto 0);
        eny : in  std_logic_vector(Ny-1 downto 0);
        cnf : in  std_logic_vector(7 downto 0);
		ro  : out std_logic_vector((2*Nx*Ny)-1 downto 0));		
	end component;

    component roc_bxt_r5 is
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
    
    component puf_mem_r5 is
	generic(
        Dbw : integer; 	  	                                                -- AXI4-Lite Data Bus Width
        Bpc : integer; 	   	                                                -- Operation(4)/Characterization(32)
        Nx  : integer;                                           	        -- Number of columns of CLBs 
        Ny  : integer);                                         	        -- Number of rows of CLBs
	port (
		clk_w   : in std_logic;                                             -- Clock for Write operations
		clk_r   : in std_logic;                                             -- Clock for Read operations
		clk_sr  : in std_logic;                                             -- Clock for Shift Register
		reset   : in std_logic;                                             -- Global Reset
		cmp_out : in std_logic_vector(Bpc-1 downto 0);                      -- Comparison Output
		puf_wa  : in std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw) downto 0);   -- PUF Write Address (max: ROs*4/32) --- Char
		puf_ra  : in std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw-1) downto 0); -- PUF Read Address (max: ROs*4/32)  --- Char
	puf_out : out std_logic_vector(Dbw-1 downto 0));                    -- PUF Output (for puf_rra)
    end component;  
    
	attribute KEEP_HIERARCHY : string;
	attribute RLOC_ORIGIN    : string;

    attribute KEEP_HIERARCHY of roen  : label is "TRUE";
    attribute KEEP_HIERARCHY of robk  : label is "TRUE";
    attribute RLOC_ORIGIN of robk : label is 
                "X" & integer'image(integer(Xo)) & "Y" & integer'image(integer(Yo));
	   
    signal sel_mask  : std_logic; 
    signal sel_inc   : std_logic; 
    signal chl_sel1  : std_logic_vector(clog2(512*Nx*Ny-1) downto 0); 

	signal sel1      : std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
	signal sel2      : std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
	signal sel3      : std_logic_vector(clog2(2*Nx*Ny-1) downto 0);
	signal sel4      : std_logic_vector(clog2(2*Nx*Ny-1) downto 0);

	signal cnf       : std_logic_vector(7 downto 0);

	signal en_x      : std_logic_vector(2*Nx-1 downto 0);
    signal en_y      : std_logic_vector(Ny-1 downto 0);    
	signal ro_1      : std_logic;
	signal ro_2      : std_logic;
	signal ro_3      : std_logic;
	signal ro_4      : std_logic;
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
	
	signal puf_wa    : std_logic_vector(clog2(512*Nx*Ny*Bpc/Dbw) downto 0);
	signal puf_ldr   : std_logic;
 	signal cmp_out   : std_logic_vector(Bpc-1 downto 0);  
 	    	
begin	

	pctrl: puf_ctrl_r5
		generic map (Dbw => Dbw, Bpc => Bpc, Nx => Nx, Ny => Ny)
		port map (clock => clock, reset => reset, n_cmps => n_cmps, puf_str => puf_str,
		          cmp_end => cmp_end, sel_mask => sel_mask, sel_inc => sel_inc,
		          cmp_rst => cmp_rst, cmp_str => cmp_str, cmp_cap => cmp_cap,      		          
		          puf_ldr => puf_ldr,  puf_wa => puf_wa, puf_end => puf_end);      		          

    chl_sel1(clog2(512*Nx*Ny-1) downto 8) <= sel1;
    chl_sel1(7 downto 0) <= cnf;
    
	cmem: chl_mem_r5
		generic map (Dbw => Dbw, Nx => Nx, Ny => Ny)
		port map (clock => clock, reset => reset,
		          mem_ctrl => mem_ctrl, mem_wadd => mem_wadd, mem_wdat => mem_wdat,
		          chl_sel1 => chl_sel1, sel_mask => sel_mask);
		          		          
	rochl: roc_chl_r5
		generic map (Nx => Nx, Ny => Ny)
		port map (clk => sel_inc, reset => reset, cnf => cnf,
		          sel1 => sel1, sel2 => sel2, sel3 => sel3, sel4 => sel4);
		          		          
	roen: roc_en_r5
		generic map (Nx => Nx, Ny => Ny)
		port map (en_ro => en_ro, sel1 => sel1, sel2 => sel2, sel3 => sel3, sel4 => sel4, 
		          en_x => en_x, en_y => en_y);		

	robk: roc_bnk_r5
		generic map (Nx => Nx, Ny => Ny)
		port map (enx => en_x, eny => en_y, cnf => cnf, ro => ro_b);
	
	ro_1 <= ro_b(to_integer(unsigned(sel1(clog2(2*Nx*Ny-1) downto 0))));
	ro_2 <= ro_b(to_integer(unsigned(sel2(clog2(2*Nx*Ny-1) downto 0))));
	ro_3 <= ro_b(to_integer(unsigned(sel3(clog2(2*Nx*Ny-1) downto 0))));
	ro_4 <= ro_b(to_integer(unsigned(sel4(clog2(2*Nx*Ny-1) downto 0))));
	
    robxt_1 : roc_bxt_r5
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_1, ro2 => ro_2,
				 counter1 => counter1, counter2 => counter2, full1 => full1, full2 => full2,
				 busy => s_busy_1, rdata => rdata1);
				 
    robxt_2 : roc_bxt_r5
		generic map(Nbc => Nbc)
		port map(BG => BG, rst => cmp_rst, str => cmp_str, ro1 => ro_3, ro2 => ro_4,
				 counter1 => counter3, counter2 => counter4, full1 => full3, full2 => full4,
				 busy => s_busy_2, rdata => rdata2);

	busy    <= s_busy_1 or s_busy_2;
	en_ro   <= busy;
	cmp_end <= not busy;
	
	pmem : puf_mem_r5
		generic map (Dbw => Dbw, Bpc => Bpc, Nx => Nx, Ny => Ny)
		port map(clk_w => puf_ldr, clk_r => clock, clk_sr => busy, reset => reset, cmp_out => cmp_out, 
				 puf_wa => puf_wa, puf_ra => puf_addr, puf_out => puf_out);
 
    puf_addw <= puf_wa;
    
--  Capture comparison output   
    --
    OP: if Bpc = 4 generate             --  OPERATION
    process (cmp_cap)  
    begin
        if (rising_edge(cmp_cap)) then 
            if PE then                            --- Operation PUF
                if LH then                            -- Lower Bits
	               cmp_out(0) <= rdata1(Nbc-6);          -- bit 6(1)
	               cmp_out(1) <= rdata1(Nbc-7);          -- bit 7(1)						
	               cmp_out(2) <= rdata2(Nbc-7);          -- bit 7(2)
                else                                  -- Higher Bits
	               cmp_out(0) <= rdata1(Nbc-7);          -- bit 7(1)
	               cmp_out(1) <= rdata1(Nbc-8);          -- bit 8(1)																 
	               cmp_out(2) <= rdata2(Nbc-8);          -- bit 8(2)
	            end if;
	            cmp_out(3) <= full3;                     -- bit 0(2)
	        else                                  --- Operation Entropy Source
	            cmp_out(3) <= rdata2(1);              -- bit Nbc-1(2)
	            cmp_out(2) <= rdata2(0);              -- bit Nbc(2)
	            cmp_out(1) <= rdata1(1);              -- bit Nbc-1(1)
	            cmp_out(0) <= rdata1(0);              -- bit Nbc(1)
            end if;           	           
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

