/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
/* 
`ifndef PICORV32_REGS
`ifdef PICORV32_V
`error "picosoc.v must be read before picorv32.v!"
`endif
`define PICORV32_REGS picosoc_regs
`endif */

`ifndef PICOSOC_MEM
`define PICOSOC_MEM picosoc_mem
`endif

// this macro can be used to check if the verilog files in your
// design are read in the correct order.
`define PICOSOC_V

module picosoc (
				input  wire 		clk,			        //-- Clock Signal
				input  wire 		rst_n,			        //-- Reset Active Low
				//- External Firmware Loader Interface
				input  wire [31:0] 	AXI_RAM_WEN_ADDR,       //-- {rst, write, read, 5'b0, addr}  
				input  wire [31:0]	AXI_RAM_WDATA,			//-- Data to write into RAM
				output wire [31:0] 	AXI_RAM_RDATA,  		//-- Data read from RAM
				//-- AXI-4 Lite Signals
				input  wire 		S_AXI_WVALID,
				input  wire 		S_AXI_WREADY,
				input  wire [1:0] 	S_AXI_AWADDR,
				input  wire 		S_AXI_ARVALID,
				input  wire 		S_AXI_ARREADY,
				input  wire [1:0] 	S_AXI_ARADDR,
				//-- AXI-4 Lite Command Interface
                input  wire [63:0] 	cmd_data_in,            //-- Data from Host to FW
                output reg  [63:0] 	cmd_data_out,           //-- Data from FW to Host
                output reg  [63:0] 	cmd_control             //-- Control register set by FW
				);

	//==========================================================================
	//-- PARAMETERS
	//==========================================================================
	//-- CPU Core Configuration
	parameter [0:0] BARREL_SHIFTER 		= 0;
	parameter [0:0] ENABLE_MUL 			= 1;
	parameter [0:0] ENABLE_DIV 			= 1;
	parameter [0:0] ENABLE_FAST_MUL 	= 0;
	parameter [0:0] ENABLE_COMPRESSED 	= 1;
	parameter [0:0] ENABLE_COUNTERS 	= 1;
	parameter [0:0] ENABLE_IRQ 			= 1;
	parameter [0:0] ENABLE_IRQ_QREGS 	= 1;
	parameter [0:0] TWO_CYCLE_COMPARE   = 1;
	parameter [0:0] TWO_CYCLE_ALU       = 1;

	//-- Memory Configuration
	parameter integer MEM_WORDS 		= 65536;				// 65536 words = 256 KiB
	parameter [31:0] STACKADDR 			= (4*MEM_WORDS);       	// end of memory
	parameter [31:0] PROGADDR_RESET 	= 32'h 0000_0000; 		// All memory in BRAM
	parameter [31:0] PROGADDR_IRQ 		= 32'h 0000_0060;		// Interrupt Address

	//==========================================================================
	//-- INITIAL RESET GENERATION
	//==========================================================================
	// Generate a stable internal reset `resetn` that de-asserts a few cycles
    // after the external `rst_n` goes high, ensuring a clean startup.
	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt && rst_n;

	always @(posedge clk) begin
		if (!rst_n)
			reset_cnt <= 0;
		else 
			reset_cnt <= reset_cnt + !resetn;
	end

	//==========================================================================
	//-- MEMORY INTERFACE
	//==========================================================================
	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	wire [31:0] mem_rdata;

	//==========================================================================
	//-- PICORV32 CPU CORE
	//==========================================================================
	
	(* keep_hierarchy = "yes" *) picorv32 #(
			                                .STACKADDR(STACKADDR),
			                                .PROGADDR_RESET(PROGADDR_RESET),
			                                .PROGADDR_IRQ(PROGADDR_IRQ),
			                                .BARREL_SHIFTER(BARREL_SHIFTER),
			                                .COMPRESSED_ISA(ENABLE_COMPRESSED),
			                                .ENABLE_COUNTERS(ENABLE_COUNTERS),
			                                .ENABLE_MUL(ENABLE_MUL),
			                                .ENABLE_DIV(ENABLE_DIV),
			                                .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
			                                .ENABLE_IRQ(ENABLE_IRQ),
			                                .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS),
			                                .TWO_CYCLE_COMPARE(TWO_CYCLE_COMPARE),
			                                .TWO_CYCLE_ALU(TWO_CYCLE_ALU)
			                                ) 
			                                CPU 
			                                (
				                            .clk(clk),
				                            .resetn(resetn),
				                            .mem_valid(mem_valid),
				                            .mem_instr(mem_instr),
				                            .mem_ready(mem_ready),
				                            .mem_addr(mem_addr),
				                            .mem_wdata(mem_wdata),
				                            .mem_wstrb(mem_wstrb),
				                            .mem_rdata(mem_rdata),
				                            .irq(irq)
				                            );

	//==========================================================================
	//-- PERIPHERAL ADDRESS MAP
	//==========================================================================
	// --- Peripherals Starting Address
	parameter [31:0] PERIPHERALS_BASE_ADDR	= 32'h0100_0000;
	// --- Command Processor Registers --- //
	parameter [7:0] CMD_CONTROL_1		  	= 8'h00;		reg cmd_control_1_sel; 			//-- CMD Control Register [31:0]	
	parameter [7:0] CMD_CONTROL_2		  	= 8'h04;		reg cmd_control_2_sel;  		//-- CMD Control Register [63:32]
	parameter [7:0] CMD_WRITE_1		    	= 8'h08;		reg cmd_write_1_sel;    		//-- AXI-4 Lite Slave writes to Master [31:0]
	parameter [7:0] CMD_WRITE_2		    	= 8'h0C;		reg cmd_write_2_sel;    		//-- AXI-4 Lite Slave writes to Master [63:32]
	parameter [7:0] CMD_READ_1		     	= 8'h10;		reg cmd_read_1_sel;	 	 		//-- AXI-4 Lite Slave reads from Master [31:0]
	parameter [7:0] CMD_READ_2		     	= 8'h14;		reg cmd_read_2_sel;	 	 		//-- AXI-4 Lite Slave reads from Master [63:32]
	parameter [7:0] CMD_WAIT_READ		  	= 8'h18;		reg cmd_wait_read_sel;	 		//-- picorv32 waits for 1 AXI-4 Lite Slave read from Master
	parameter [7:0] CMD_WAIT_WRITE		 	= 8'h1C;		reg cmd_wait_write_sel; 		//-- picorv32 waits for 1 AXI-4 Lite Slave write from Master
	parameter [7:0] CMD_WAIT_N_READS		= 8'h20;		reg cmd_wait_n_reads_sel;		//-- picorv32 waits for n AXI-4 Lite Slave read from Master
	parameter [7:0] CMD_WAIT_N_WRITES		= 8'h24;		reg cmd_wait_n_writes_sel;		//-- picorv32 waits for n AXI-4 Lite Slave write from Master
	// --- Secure Element (SE) Registers --- //
	parameter [7:0] SE_DATA_IN_1		   	= 8'h28;		reg se_data_in_1_sel;  	 		//-- SE data_in[31:0]
	parameter [7:0] SE_DATA_IN_2		   	= 8'h2C;		reg se_data_in_2_sel;  	 		//-- SE data_in[63:32]
	parameter [7:0] SE_ADDR_1		      	= 8'h30;		reg se_addr_1_sel;     	 		//-- SE addr[31:0]
	parameter [7:0] SE_ADDR_2		      	= 8'h34;		reg se_addr_2_sel;     	 		//-- SE addr[63:32]
	parameter [7:0] SE_CONTROL_1		   	= 8'h38;		reg se_control_1_sel;  	 		//-- SE control[31:0]
	parameter [7:0] SE_CONTROL_2		   	= 8'h3C;		reg se_control_2_sel;  	 		//-- SE control[63:32]
	parameter [7:0] SE_DATA_OUT_1		  	= 8'h40;		reg se_data_out_1_sel; 	 		//-- SE data_out[31:0]
	parameter [7:0] SE_DATA_OUT_2		  	= 8'h44;		reg se_data_out_2_sel; 	 		//-- SE data_out[63:32]
	parameter [7:0] SE_END_OP		      	= 8'h48;		reg se_end_op_sel;     	 		//-- SE end_op
	parameter [7:0] SE_ADDR_IN_LIMIT		= 8'h4C;		reg se_addr_in_limit_sel;		//-- SE address limit for Input FIFO
	parameter [7:0] SE_ADDR_OUT_LIMIT		= 8'h50;		reg se_addr_out_limit_sel;		//-- SE address limit for Output FIFO
	parameter [7:0] SE_INTERFACE			= 8'h54;		reg se_interface_sel;			//-- SE address limit for Output FIFO
	// --- FIFO Interface Registers --- //
	parameter [7:0] FIFO_IO_ENABLE			= 8'h58;		reg fifo_io_en_sel; 			//-- {fifo_out_swap_endianness, fifo_in_swap_endianness, 
	parameter [7:0] FIFOS_INFO				= 8'h5C;		reg fifos_info_sel; 			//-- {fifo_out_avail, fifo_in_avail, fifo_out_empty, fifo
	parameter [7:0] FIFO_IN_WR		        = 8'h60;		reg fifo_in_wr_sel;		 		//-- Write to Input FIFO
	parameter [7:0] FIFO_IN_WR_DATA_1		= 8'h64;		reg fifo_in_wr_data_1_sel;		//-- Write to Input FIFO [31:0]
	parameter [7:0] FIFO_IN_WR_DATA_2		= 8'h68;		reg fifo_in_wr_data_2_sel;		//-- Write to Input FIFO [63:32]
	parameter [7:0] FIFO_IN_RD		        = 8'h6C;		reg fifo_in_rd_sel;		 		//-- Read from Input FIFO
	parameter [7:0] FIFO_IN_RD_DATA_1		= 8'h70;		reg fifo_in_rd_data_1_sel;		//-- Read from Input FIFO [31:0]
	parameter [7:0] FIFO_IN_RD_DATA_2		= 8'h74;		reg fifo_in_rd_data_2_sel;		//-- Read from Input FIFO [63:32]
	parameter [7:0] FIFO_OUT_WR		        = 8'h78;		reg fifo_out_wr_sel;			//-- Write to Output FIFO
	parameter [7:0] FIFO_OUT_WR_DATA_1		= 8'h7C;		reg fifo_out_wr_data_1_sel;		//-- Write to Output FIFO [31:0]
	parameter [7:0] FIFO_OUT_WR_DATA_2		= 8'h80;		reg fifo_out_wr_data_2_sel;		//-- Write to Output FIFO [63:32]
	parameter [7:0] FIFO_OUT_RD		        = 8'h84;		reg fifo_out_rd_sel;			//-- Read from Output FIFO
	parameter [7:0] FIFO_OUT_RD_DATA_1		= 8'h88;		reg fifo_out_rd_data_1_sel;		//-- Read from Output FIFO [31:0]
	parameter [7:0] FIFO_OUT_RD_DATA_2		= 8'h8C;		reg fifo_out_rd_data_2_sel;		//-- Read from Output FIFO [63:32]
	// --- DMA Registers --- //
	parameter [7:0] DMA_DST_ADDR			= 8'h90;		reg dma_dst_addr_sel;			//-- DMA Destination Address			
	parameter [7:0] DMA_SRC_ADDR			= 8'h94;		reg dma_src_addr_sel;			//-- DMA Source Address	
	parameter [7:0] DMA_LEN_BYTES			= 8'h98;		reg dma_len_bytes_sel;			//-- DMA Length in bytes	
	parameter [7:0] DMA_MEMCPY				= 8'h9C;		reg dma_memcpy_sel;				//-- DMA Memory copy aligned	
	parameter [7:0] DMA_MEMSET				= 8'hA0;		reg dma_memset_sel;				//-- DMA Memory set aligned	
	parameter [7:0] DMA_MEMCMP				= 8'hA4;		reg dma_memcmp_sel;				//-- DMA Memory compare aligned
	parameter [7:0] DMA_SWAP_ENDIANNESS		= 8'hA8;		reg dma_swap_endianness_sel;	//-- DMA Swap Endianness
	// --- WDT Registers --- //
	parameter [7:0] WDT_START				= 8'hAC;		reg wdt_start_sel;				//-- Set and Start Watchdog Timer
	parameter [7:0] WDT_STOP				= 8'hB0;		reg wdt_stop_sel;				//-- Stop Watchdog Timer
	// --- Debug Registers --- //
	parameter [7:0] SW_DEBUG_0		 		= 8'hB4;		reg sw_debug_0_sel;  			//-- Software Debug Variable #0
	parameter [7:0] SW_DEBUG_1				= 8'hB8;		reg sw_debug_1_sel;				//-- Software Debug Variable #1
	parameter [7:0] SW_DEBUG_2				= 8'hBC;		reg sw_debug_2_sel;				//-- Software Debug Variable #2
	parameter [7:0] SW_DEBUG_3				= 8'hC0;		reg sw_debug_3_sel;				//-- Software Debug Variable #3
	parameter [7:0] SW_DEBUG_4				= 8'hC4;		reg sw_debug_4_sel;				//-- Software Debug Variable #4
	// --- TRNG Register --- //
	parameter [7:0] TRNG_READ				= 8'hC8;		reg trng_read_sel;				//-- TRNG Output Data
	parameter [7:0] TRNG_OCCP				= 8'hCC;		reg trng_occp_sel;				//-- TRNG Memory Occupation
	// --- Secure Memory Register --- //
	parameter [7:0] SECMEM_ADDR				= 8'hD0;		reg secmem_addr_sel;			//-- Secure Memory Address
	parameter [7:0] SECMEM_DATA_IN			= 8'hD4;		reg secmem_data_in_sel;			//-- Secure Memory Input Data
	parameter [7:0] SECMEM_DATA_OUT			= 8'hD8;		reg secmem_data_out_sel;		//-- Secure Memory Output Data
	// --- Implementation Info Register --- //
	parameter [7:0] IMP_INFO				= 8'hDC;		reg imp_info_sel;				//-- Implementation Info
	// --- Peripherals Final Address
	parameter [31:0] PERIPHERALS_FINAL_ADDR	= PERIPHERALS_BASE_ADDR + IMP_INFO;

	//==========================================================================
	//-- SLH-DSA ADDRESS MAP
	//==========================================================================
	parameter [31:0] SLH_KECCAK_BASE_ADDR = 32'h0200_0000;	reg slh_keccak_sel;				//-- Keccak Starting Address
	parameter [31:0] SLH_SHA256_BASE_ADDR = 32'h0400_0000;	reg slh_sha256_sel;				//-- SHA256 Starting Address
	parameter [31:0] SLH_SHA512_BASE_ADDR = 32'h0800_0000;	reg slh_sha512_sel;				//-- SHA512 Starting Address
	
	//-- For writing sel must be 1 cycle. For reading sel must be 2 cycles.
	reg slh_delay;

	always @(posedge clk) slh_delay <= peripheral_valid;

	wire slh_done = ((slh_keccak_sel | slh_sha256_sel | slh_sha512_sel) & (mem_wstrb == 0)) ? slh_delay	: 
					( slh_keccak_sel | slh_sha256_sel | slh_sha512_sel) 					? 1'b1		: 1'b0;

	//==========================================================================
    //-- ADDRESS DECODER (PERIPHERAL SELECT SIGNALS)
    //==========================================================================
	// --- Pipeline Registers for Peripheral Access ---
	// reg [31:0] peripheral_addr;
	reg [31:0] peripheral_wdata;
	reg [31:0] peripheral_addr;
	reg [3:0]  peripheral_wstrb;
	reg        peripheral_valid;
	reg        peripheral_write; // A flag to indicate a write operation

	wire peripheral_sel 	= mem_addr[24];
	wire peripheral_wait 	= |{cmd_wait_read_sel,
								cmd_wait_write_sel,
								cmd_wait_n_reads_sel,
								cmd_wait_n_writes_sel,
								dma_memcpy_sel,
								dma_memset_sel,
								dma_memcmp_sel,
								trng_read_sel,
								(slh_keccak_sel | slh_sha256_sel | slh_sha512_sel) & (mem_wstrb == 0)};

	// --- Stage 1: Decode and Latch ---
	always @(posedge clk) begin
    	// Latch the CPU's request on every valid bus cycle that isn't for RAM.
    	if (mem_valid && (mem_addr > 4*MEM_WORDS) && (!peripheral_valid || peripheral_wait)) begin
    	    peripheral_valid 		<= 1'b1;
    	    peripheral_wdata 		<= mem_wdata;
			peripheral_addr			<= mem_addr;
    	    peripheral_wstrb 		<= mem_wstrb;
    	    peripheral_write 		<= |mem_wstrb;
			// --- Command Processor Registers --- //
			cmd_control_1_sel  		<= peripheral_sel && (mem_addr[7:2] == CMD_CONTROL_1[7:2]);    		
			cmd_control_2_sel  		<= peripheral_sel && (mem_addr[7:2] == CMD_CONTROL_2[7:2]);    		
			cmd_write_1_sel    		<= peripheral_sel && (mem_addr[7:2] == CMD_WRITE_1[7:2]);    		
			cmd_write_2_sel    		<= peripheral_sel && (mem_addr[7:2] == CMD_WRITE_2[7:2]);    		
			cmd_read_1_sel	 	 	<= peripheral_sel && (mem_addr[7:2] == CMD_READ_1[7:2]);   			
			cmd_read_2_sel	 	 	<= peripheral_sel && (mem_addr[7:2] == CMD_READ_2[7:2]);   			
			cmd_wait_read_sel	 	<= peripheral_sel && (mem_addr[7:2] == CMD_WAIT_READ[7:2]);   		
			cmd_wait_write_sel 		<= peripheral_sel && (mem_addr[7:2] == CMD_WAIT_WRITE[7:2]);   		
			cmd_wait_n_reads_sel	<= peripheral_sel && (mem_addr[7:2] == CMD_WAIT_N_READS[7:2]);   	
			cmd_wait_n_writes_sel 	<= peripheral_sel && (mem_addr[7:2] == CMD_WAIT_N_WRITES[7:2]);   	
			// --- Secure Element (SE) Registers --- //
			se_data_in_1_sel  	    <= peripheral_sel && (mem_addr[7:2] == SE_DATA_IN_1[7:2]);    		
			se_data_in_2_sel  	    <= peripheral_sel && (mem_addr[7:2] == SE_DATA_IN_2[7:2]);    		
			se_addr_1_sel     	    <= peripheral_sel && (mem_addr[7:2] == SE_ADDR_1[7:2]);    			
			se_addr_2_sel     	    <= peripheral_sel && (mem_addr[7:2] == SE_ADDR_2[7:2]);    			
			se_control_1_sel  	    <= peripheral_sel && (mem_addr[7:2] == SE_CONTROL_1[7:2]);    		
			se_control_2_sel  	    <= peripheral_sel && (mem_addr[7:2] == SE_CONTROL_2[7:2]);    		
			se_data_out_1_sel 	    <= peripheral_sel && (mem_addr[7:2] == SE_DATA_OUT_1[7:2]);    		
			se_data_out_2_sel 	    <= peripheral_sel && (mem_addr[7:2] == SE_DATA_OUT_2[7:2]);    		
			se_end_op_sel     	    <= peripheral_sel && (mem_addr[7:2] == SE_END_OP[7:2]);    			
			se_addr_in_limit_sel	<= peripheral_sel && (mem_addr[7:2] == SE_ADDR_IN_LIMIT[7:2]);      
			se_addr_out_limit_sel	<= peripheral_sel && (mem_addr[7:2] == SE_ADDR_OUT_LIMIT[7:2]);    	
			se_interface_sel		<= peripheral_sel && (mem_addr[7:2] == SE_INTERFACE[7:2]);    		
			// --- FIFO Interface Registers --- //
			fifo_io_en_sel 			<= peripheral_sel && (mem_addr[7:2] == FIFO_IO_ENABLE[7:2]);        	
			fifos_info_sel 			<= peripheral_sel && (mem_addr[7:2] == FIFOS_INFO[7:2]);            	
			fifo_in_wr_sel		    <= peripheral_sel && (mem_addr[7:2] == FIFO_IN_WR[7:2]);            	
			fifo_in_wr_data_1_sel  	<= peripheral_sel && (mem_addr[7:2] == FIFO_IN_WR_DATA_1[7:2]);     	
			fifo_in_wr_data_2_sel  	<= peripheral_sel && (mem_addr[7:2] == FIFO_IN_WR_DATA_2[7:2]);     	
			fifo_in_rd_sel		    <= peripheral_sel && (mem_addr[7:2] == FIFO_IN_RD[7:2]);            	
			fifo_in_rd_data_1_sel 	<= peripheral_sel && (mem_addr[7:2] == FIFO_IN_RD_DATA_1[7:2]);     	
			fifo_in_rd_data_2_sel  	<= peripheral_sel && (mem_addr[7:2] == FIFO_IN_RD_DATA_2[7:2]);     	
			fifo_out_wr_sel			<= peripheral_sel && (mem_addr[7:2] == FIFO_OUT_WR[7:2]);           	
			fifo_out_wr_data_1_sel 	<= peripheral_sel && (mem_addr[7:2] == FIFO_OUT_WR_DATA_1[7:2]);    	
			fifo_out_wr_data_2_sel 	<= peripheral_sel && (mem_addr[7:2] == FIFO_OUT_WR_DATA_2[7:2]);    	
			fifo_out_rd_sel			<= peripheral_sel && (mem_addr[7:2] == FIFO_OUT_RD[7:2]);           	
			fifo_out_rd_data_1_sel 	<= peripheral_sel && (mem_addr[7:2] == FIFO_OUT_RD_DATA_1[7:2]);    	
			fifo_out_rd_data_2_sel 	<= peripheral_sel && (mem_addr[7:2] == FIFO_OUT_RD_DATA_2[7:2]);    	
			// --- DMA Registers --- //
			dma_dst_addr_sel		<= peripheral_sel && (mem_addr[7:2] == DMA_DST_ADDR[7:2]);        	
			dma_src_addr_sel		<= peripheral_sel && (mem_addr[7:2] == DMA_SRC_ADDR[7:2]);        	
			dma_len_bytes_sel		<= peripheral_sel && (mem_addr[7:2] == DMA_LEN_BYTES[7:2]);        	
			dma_memcpy_sel			<= peripheral_sel && (mem_addr[7:2] == DMA_MEMCPY[7:2]);        	
			dma_memset_sel			<= peripheral_sel && (mem_addr[7:2] == DMA_MEMSET[7:2]);        	
			dma_memcmp_sel			<= peripheral_sel && (mem_addr[7:2] == DMA_MEMCMP[7:2]);      
			dma_swap_endianness_sel	<= peripheral_sel && (mem_addr[7:2] == DMA_SWAP_ENDIANNESS[7:2]);      
			// --- WDT Registers --- //
			wdt_start_sel			<= peripheral_sel && (mem_addr[7:2] == WDT_START[7:2]);        		
			wdt_stop_sel			<= peripheral_sel && (mem_addr[7:2] == WDT_STOP[7:2]);        		
			// --- Debug Registers --- //
			sw_debug_0_sel    		<= peripheral_sel && (mem_addr[7:2] == SW_DEBUG_0[7:2]);        		
			sw_debug_1_sel			<= peripheral_sel && (mem_addr[7:2] == SW_DEBUG_1[7:2]);      
			sw_debug_2_sel			<= peripheral_sel && (mem_addr[7:2] == SW_DEBUG_2[7:2]);      
			sw_debug_3_sel			<= peripheral_sel && (mem_addr[7:2] == SW_DEBUG_3[7:2]);      
			sw_debug_4_sel			<= peripheral_sel && (mem_addr[7:2] == SW_DEBUG_4[7:2]); 
			// --- TRNG Registers --- //
			trng_read_sel    		<= peripheral_sel && (mem_addr[7:2] == TRNG_READ[7:2]);
			trng_occp_sel    		<= peripheral_sel && (mem_addr[7:2] == TRNG_OCCP[7:2]); 
			// --- Secure Memory Register --- //
			secmem_addr_sel			<= peripheral_sel && (mem_addr[7:2] == SECMEM_ADDR[7:2]);
			secmem_data_in_sel		<= peripheral_sel && (mem_addr[7:2] == SECMEM_DATA_IN[7:2]);
			secmem_data_out_sel		<= peripheral_sel && (mem_addr[7:2] == SECMEM_DATA_OUT[7:2]);
			// --- Implementation Info Register --- //
			imp_info_sel			<= peripheral_sel && (mem_addr[7:2] == IMP_INFO[7:2]); 
			// --- SLH-DSA Registers --- //
			slh_keccak_sel			<= mem_addr[25];
			slh_sha256_sel			<= mem_addr[26];
			slh_sha512_sel			<= mem_addr[27]; 
    	end 
		else begin
    	    peripheral_valid 		<= 0;
    	    peripheral_wdata 		<= 0;
			peripheral_addr			<= 0;
    	    peripheral_wstrb 		<= 0;
    	    peripheral_write 		<= 0;
			// --- Command Processor Registers --- //
			cmd_control_1_sel  		<= 0;
			cmd_control_2_sel  		<= 0;
			cmd_write_1_sel    		<= 0;
			cmd_write_2_sel    		<= 0;
			cmd_read_1_sel	 	 	<= 0;
			cmd_read_2_sel	 	 	<= 0;
			cmd_wait_read_sel	 	<= 0;
			cmd_wait_write_sel 		<= 0;
			cmd_wait_n_reads_sel	<= 0;
			cmd_wait_n_writes_sel 	<= 0;
			// --- Secure Element (SE) Registers --- //
			se_data_in_1_sel  	    <= 0;
			se_data_in_2_sel  	    <= 0;
			se_addr_1_sel     	    <= 0;
			se_addr_2_sel     	    <= 0;
			se_control_1_sel  	    <= 0;
			se_control_2_sel  	    <= 0;
			se_data_out_1_sel 	    <= 0;
			se_data_out_2_sel 	    <= 0;
			se_end_op_sel     	    <= 0;
			se_addr_in_limit_sel	<= 0;
			se_addr_out_limit_sel	<= 0;
			se_interface_sel		<= 0;
			// --- FIFO Interface Registers --- //
			fifo_io_en_sel 			<= 0;
			fifos_info_sel 			<= 0;
			fifo_in_wr_sel		    <= 0;
			fifo_in_wr_data_1_sel  	<= 0;
			fifo_in_wr_data_2_sel  	<= 0;
			fifo_in_rd_sel		    <= 0;
			fifo_in_rd_data_1_sel 	<= 0;
			fifo_in_rd_data_2_sel  	<= 0;
			fifo_out_wr_sel			<= 0;
			fifo_out_wr_data_1_sel 	<= 0;
			fifo_out_wr_data_2_sel 	<= 0;
			fifo_out_rd_sel			<= 0;
			fifo_out_rd_data_1_sel 	<= 0;
			fifo_out_rd_data_2_sel 	<= 0;
			// --- DMA Registers --- //
			dma_dst_addr_sel		<= 0;
			dma_src_addr_sel		<= 0;
			dma_len_bytes_sel		<= 0;
			dma_memcpy_sel			<= 0;
			dma_memset_sel			<= 0;
			dma_memcmp_sel			<= 0;
			dma_swap_endianness_sel	<= 0;
			// --- WDT Registers --- //
			wdt_start_sel			<= 0;
			wdt_stop_sel			<= 0;
			// --- Debug Registers --- //
			sw_debug_0_sel    		<= 0;
			sw_debug_1_sel			<= 0;
			sw_debug_2_sel			<= 0;
			sw_debug_3_sel			<= 0;
			sw_debug_4_sel			<= 0;
			// --- TRNG Registers --- //
			trng_read_sel    		<= 0;
			trng_occp_sel    		<= 0;
			// --- Secure Memory Register --- //
			secmem_addr_sel			<= 0;
			secmem_data_in_sel		<= 0;
			secmem_data_out_sel		<= 0;
			// --- Implementation Info Register --- //
			imp_info_sel			<= 0; 
			// --- SLH-DSA Registers --- //
			slh_keccak_sel			<= 0;
			slh_sha256_sel			<= 0;
			slh_sha512_sel			<= 0; 
    	end
	end

	//==========================================================================
    //-- INTERRUPTS
    //==========================================================================
	reg [31:0] irq;
	reg  irq_wdt;			//-- WDT Interrupt
	wire irq_dma;			//-- DMA Interrupt: unaligned dst, unaligned src, unaligned len, zero len
	wire irq_illaddr;		//-- Illegal Address Interrupt

	always @* begin
		irq 	= 0;
		irq[3] 	= irq_wdt;
		irq[4]	= irq_dma;
		irq[5] 	= irq_illaddr;
	end

	assign irq_dma 		= 	irq_dma_unaligned_dst | irq_dma_unaligned_src | irq_dma_unaligned_len;
	assign irq_illaddr 	= 	((mem_addr > STACKADDR) 						&& (mem_addr < PERIPHERALS_BASE_ADDR)) 	|| 
							((mem_addr > PERIPHERALS_FINAL_ADDR) 			&& (mem_addr < SLH_KECCAK_BASE_ADDR)) 	|| 
							((mem_addr > SLH_KECCAK_BASE_ADDR + 10'h3FF)	&& (mem_addr < SLH_SHA256_BASE_ADDR)) 	|| 
							((mem_addr > SLH_SHA256_BASE_ADDR + 10'h3FF) 	&& (mem_addr < SLH_SHA512_BASE_ADDR)) 	||
							( mem_addr > SLH_SHA512_BASE_ADDR + 10'h3FF);

	//==========================================================================
    //-- WATCHDOG TIMER INTERRUPT
    //==========================================================================
	parameter [31:0] WDT_DEFAULT_TIMER = 32'h00FFFFFF; // 2^24 cycles @ 100 MHz ~ 0.167s

	reg [31:0] wdt_counter;
	reg wdt_en;
	reg wdt_en_delay;

	always @(posedge clk) wdt_en_delay <= wdt_en;

	reg is_cmd_se_code;
	always @(posedge clk) is_cmd_se_code <= (cmd_control[31:0] == 3);

	always @(posedge clk) begin
		if (!resetn) begin
			irq_wdt		<= 0;
			wdt_counter	<= WDT_DEFAULT_TIMER;
			wdt_en 		<= 0;
		end
		else if (wdt_start_sel) begin
			irq_wdt		<= 0;
			wdt_counter <= peripheral_wdata;
			wdt_en 		<= 1;
		end
		else if (wdt_stop_sel) begin
			irq_wdt		<= 0;
			wdt_counter <= WDT_DEFAULT_TIMER;
			wdt_en 		<= 0;
		end
		else if (wdt_en || (!mem_ready && !is_cmd_se_code)) begin
			if (wdt_counter > 0) begin
				wdt_counter <= wdt_counter - 1;
			end
			else begin
				irq_wdt <= 1;
				wdt_en	<= 0;
			end
		end
		else begin
			irq_wdt 	<= 0;
			wdt_counter <= WDT_DEFAULT_TIMER;
			wdt_en 		<= 0;
		end
	end

	//==========================================================================
	//-- DMA CONTROLLER
	//==========================================================================
	reg [31:0] dma_dst_addr;
	reg [31:0] dma_src_addr;
	reg [31:0] dma_len_bytes;
	reg [31:0] dma_memset_value;
	reg dma_swap_endianness;

	always @(posedge clk) begin
		if (!resetn) begin
			dma_dst_addr 		<= 0;
			dma_src_addr 		<= 0;
			dma_len_bytes 		<= 0;
			dma_memset_value	<= 0;
			dma_swap_endianness	<= 0;
		end
		else if (irq_dma) begin
			dma_dst_addr 		<= 0;
			dma_src_addr 		<= 0;
			dma_len_bytes 		<= 0;
			dma_memset_value 	<= 0;
			dma_swap_endianness	<= 0;
		end
		else begin
			if (dma_dst_addr_sel 		&& peripheral_write) dma_dst_addr 			<= peripheral_wdata;
			if (dma_src_addr_sel 		&& peripheral_write) dma_src_addr 			<= peripheral_wdata;
			if (dma_len_bytes_sel 		&& peripheral_write) dma_len_bytes 			<= {peripheral_wdata[29:0], 2'b0};
			if (dma_memset_sel 			&& peripheral_write) dma_memset_value 		<= peripheral_wdata;
			if (dma_swap_endianness_sel && peripheral_write) dma_swap_endianness 	<= peripheral_wdata[0];
		end
	end

	//-- Interrupts
	wire irq_dma_unaligned_dst = (dma_dst_addr [1:0] != 0);
	wire irq_dma_unaligned_src = (dma_src_addr [1:0] != 0);
	wire irq_dma_unaligned_len = (dma_len_bytes[1:0] != 0);

	//-- State machine definitions
	localparam DMA_FSM_IDLE       	= 3'd0;
	localparam DMA_FSM_SETUP      	= 3'd1; // Calculate start/end addresses
	localparam DMA_FSM_MEMCPY_FWD 	= 3'd2; // Memcpy, forward direction
	localparam DMA_FSM_MEMCPY_REV 	= 3'd3; // Memcpy, reverse direction
	localparam DMA_FSM_MEMSET     	= 3'd4;
	localparam DMA_FSM_MEMCMP     	= 3'd5;
	localparam DMA_FSM_DONE			= 3'd6;

	reg [2:0] dma_state;
		
	reg  [31:0] dma_addr_wr;
	reg  [31:0] dma_addr_rd;
	reg  [31:0] dma_addr_end;
	wire [31:0] dma_data_wr;
	wire [31:0] dma_data_rd;
	reg  [3:0]  dma_wstrb;
	reg  dma_memcpy_done;
	reg  dma_memset_done;
	reg  dma_memcmp_done;
	reg  [1:0] dma_memcmp_result;
	
	//-- If src and dst do not overlap or if (src > dst) then order is forward (1) otherwise reverse (0)
	reg dma_memcpy_order;   
	reg dma_memcmp_is_eq;
	reg dma_memcmp_is_bg;

	assign dma_data_wr = (dma_swap_endianness) ? {dma_data_rd[7:0], dma_data_rd[15:8], dma_data_rd[23:16], dma_data_rd[31:24]} : dma_data_rd;

	always @(posedge clk) begin
		if (!resetn) begin
			dma_addr_wr			<= 0;
			dma_addr_rd			<= 0;
			dma_addr_end		<= 0;
			dma_wstrb			<= 0;
			dma_memcpy_done		<= 0;
			dma_memset_done 	<= 0;
			dma_memcmp_done 	<= 0;
			dma_memcmp_result 	<= 0;
			dma_memcpy_order	<= 0;
			dma_memcmp_is_eq	<= 0;
			dma_memcmp_is_bg	<= 0;
			dma_state			<= DMA_FSM_IDLE;
		end
		else begin
			dma_memcpy_order <= ((dma_src_addr > dma_dst_addr) || (dma_src_addr + dma_len_bytes <= dma_dst_addr));
			dma_memcmp_is_eq <= (ram_rdata == dma_data_rd);
			dma_memcmp_is_bg <= (ram_rdata > dma_data_rd);
			
			case(dma_state)

			(DMA_FSM_IDLE): begin
				dma_addr_wr <= dma_dst_addr;
				dma_addr_rd <= dma_src_addr;
				if (dma_memcpy_sel || dma_memset_sel || dma_memcmp_sel) dma_state <= DMA_FSM_SETUP;
			end

			(DMA_FSM_SETUP): begin
				if (dma_memcpy_sel && dma_memcpy_order) begin
					dma_addr_wr 	<= dma_dst_addr - 4;
					dma_addr_rd 	<= dma_src_addr;
					dma_addr_end	<= dma_dst_addr + dma_len_bytes - 4;
					dma_state		<= DMA_FSM_MEMCPY_FWD;
				end
				else if (dma_memcpy_sel) begin
					dma_addr_wr 	<= dma_dst_addr + dma_len_bytes;
					dma_addr_rd 	<= dma_src_addr + dma_len_bytes - 4;
					dma_addr_end	<= dma_dst_addr;
					dma_state		<= DMA_FSM_MEMCPY_REV;
				end
				else if (dma_memset_sel) begin
					dma_addr_wr 	<= dma_dst_addr;
					dma_wstrb 		<= 4'b1111;
					dma_addr_end	<= dma_dst_addr + dma_len_bytes - 4;
					dma_state		<= DMA_FSM_MEMSET;
				end
				else begin
					dma_addr_wr 	<= dma_dst_addr;
					dma_addr_rd 	<= dma_src_addr;
					dma_addr_end	<= dma_dst_addr + dma_len_bytes;
					dma_state		<= DMA_FSM_MEMCMP;
				end
			end

			(DMA_FSM_MEMCPY_FWD): begin
				dma_wstrb <= 4'b1111;
				if (dma_addr_wr < dma_addr_end) begin
                    dma_addr_wr <= dma_addr_wr + 4;
					dma_addr_rd <= dma_addr_rd + 4;
                end 
				else begin
					dma_wstrb 		<= 0;
					dma_memcpy_done <= 1'b1;
                    dma_state 		<= DMA_FSM_DONE;
                end
			end

			(DMA_FSM_MEMCPY_REV): begin
				dma_wstrb <= 4'b1111;
				if (dma_addr_wr > dma_addr_end) begin
                    dma_addr_wr <= dma_addr_wr - 4;
					dma_addr_rd <= dma_addr_rd - 4;
                end 
				else begin
					dma_wstrb 		<= 0;
					dma_memcpy_done <= 1'b1;
                    dma_state 		<= DMA_FSM_DONE;
                end
			end

			(DMA_FSM_MEMSET): begin
				if (dma_addr_wr < dma_addr_end) begin
                    dma_addr_wr <= dma_addr_wr + 4;
                end 
				else begin
					dma_wstrb 		<= 0;
					dma_memset_done <= 1'b1;
                    dma_state 		<= DMA_FSM_DONE;
                end
			end

			(DMA_FSM_MEMCMP): begin
				if ((dma_addr_wr < dma_addr_end) && dma_memcmp_is_eq) begin
                    dma_addr_wr <= dma_addr_wr + 4;
					dma_addr_rd <= dma_addr_rd + 4;
                end 
				else begin
					if (dma_memcmp_is_eq) 		dma_memcmp_result <= 0;
					else if (dma_memcmp_is_bg)	dma_memcmp_result <= 1;
					else 						dma_memcmp_result <= 2;
					dma_memcmp_done <= 1'b1;
                    dma_state 		<= DMA_FSM_DONE;
                end
			end

			(DMA_FSM_DONE): begin
				dma_memcpy_done		<= 0;
				dma_memset_done 	<= 0;
				dma_memcmp_done 	<= 0;
				dma_memcmp_result 	<= 0;
				if ((dma_memcpy_sel || dma_memset_sel || dma_memcmp_sel) == 0) dma_state <= DMA_FSM_IDLE;
			end

			endcase
		end
	end

	//==========================================================================
	//-- FW RAM
	//==========================================================================
	reg ram_ready;
	
	reg  [3:0]  ram_wen;
	reg  [21:0] ram_addr;
	reg  [31:0] ram_wdata;
	wire [31:0] ram_rdata;
	
	//-- RAM can be written by the CPU, DMA, or the external loader. Loader has priority during reset.
	always @(*) begin
	    if 		(AXI_RAM_WEN_ADDR[30] && !resetn) 								ram_wen = 4'b1111;
	    else if (mem_valid && !mem_ready && (mem_addr < (4 * MEM_WORDS)))       ram_wen = mem_wstrb;
	    else if (dma_memcpy_sel || dma_memset_sel || dma_memcmp_sel)			ram_wen = dma_wstrb;
		else 																	ram_wen = 4'b0;

	    if 		((AXI_RAM_WEN_ADDR[30] || AXI_RAM_WEN_ADDR[29]) && !resetn)		ram_addr = AXI_RAM_WEN_ADDR[23:2];
	    else if (dma_memcpy_sel || dma_memset_sel || dma_memcmp_sel)			ram_addr = dma_addr_wr[23:2];
	    else 																	ram_addr = mem_addr[23:2];

	    if 		(AXI_RAM_WEN_ADDR[30] && !resetn) 								ram_wdata = AXI_RAM_WDATA;
	    else if (dma_memcpy_sel || dma_memcmp_sel)								ram_wdata = dma_data_wr;
		else if (dma_memset_sel)												ram_wdata = dma_memset_value;
	    else																	ram_wdata = mem_wdata;
	end

	assign AXI_RAM_RDATA = ram_rdata;

	always @(posedge clk) ram_ready <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;

	/* `PICOSOC_MEM #(
				  .WORDS(MEM_WORDS)
				  ) 
				  memory 
				  (
				   .clk(clk),
				   // PORT A
				   .wen_a(ram_wen),
				   .addr_a(ram_addr),
				   .wdata_a(ram_wdata),
				   .rdata_a(ram_rdata),
				   // PORT B (used by DMA to do parallel read/writes)
				   .wen_b(4'b0),
				   .addr_b(dma_addr_rd[23:2]),
				   .wdata_b(32'b0),
				   .rdata_b(dma_data_rd)
				   ); */

	(* keep_hierarchy = "yes" *) picoram #(
			                               .WORDS(MEM_WORDS)
			                               )
			                               PICORAM
			                               (
				                             .clk(clk),
				                             // PORT A
				                             .wr_en_A(ram_wen),
				                             .addr_A(ram_addr),
				                             .data_in_A(ram_wdata),
				                             .data_out_A(ram_rdata),
				                             // PORT B
				                             .wr_en_B(4'b0),
				                             .addr_B(dma_addr_rd[23:2]),
				                             .data_in_B(32'b0),
				                             .data_out_B(dma_data_rd)
			                               );
	
	//==========================================================================
	//-- SOFTWARE DEBUG REGISTERS
	//==========================================================================
	reg [31:0] sw_debug_0;
	reg [31:0] sw_debug_1;
	reg [31:0] sw_debug_2;
	reg [31:0] sw_debug_3;
	reg [31:0] sw_debug_4;

	wire [127:0] sw_debug_ascii = {sw_debug_4, sw_debug_3, sw_debug_2, sw_debug_1};

	always @(posedge clk) begin
	   	if (!resetn) begin
			sw_debug_0 <= 0;
			sw_debug_1 <= 0;
			sw_debug_2 <= 0;
			sw_debug_3 <= 0;
			sw_debug_4 <= 0;
		end
		else if (sw_debug_0_sel && peripheral_write)
			sw_debug_0 <= peripheral_wdata;	
		else if (sw_debug_1_sel && peripheral_write)
			sw_debug_1 <= peripheral_wdata;
		else if (sw_debug_2_sel && peripheral_write)
			sw_debug_2 <= peripheral_wdata;
		else if (sw_debug_3_sel && peripheral_write)
			sw_debug_3 <= peripheral_wdata;
		else if (sw_debug_4_sel && peripheral_write)
			sw_debug_4 <= peripheral_wdata;
	end

	//==========================================================================
	//-- CMD COMMAND INTERFACE LOGIC
	//==========================================================================
	// --- Command Register Logic --- //
	always @(posedge clk) begin
	   	if (!resetn) begin
			cmd_data_out         <= 0;
	    	cmd_control          <= 0;
		end
		//-- Manual
		else if (cmd_control_1_sel && peripheral_write)
	    	cmd_control[31:0] 	<= peripheral_wdata;
		else if (cmd_control_2_sel && peripheral_write)
	    	cmd_control[63:32] 	<= peripheral_wdata;
	   	else if (cmd_write_1_sel && peripheral_write)
			cmd_data_out[31:0] 	<= peripheral_wdata;
		else if (cmd_write_2_sel && peripheral_write)
			cmd_data_out[63:32] <= peripheral_wdata; 
		//-- Automatic FIFO
		else if (fifo_out_rd_en_delay)									// When FW reads from the output FIFO, the data is
			cmd_data_out		<= fifo_out_dout_swap_endianness;		// placed in cmd_data_out for the host to read.
		//-- Interrupts
		else if (irq_wdt & !wdt_en_delay) 
			cmd_data_out 		<= {irq, mem_addr}; 
		else if (irq_dma)
			cmd_data_out		<= {irq, {29'b0, irq_dma_unaligned_dst, irq_dma_unaligned_src, irq_dma_unaligned_len}};
		else if (irq_illaddr)
			cmd_data_out		<= {irq, mem_addr}; 
	end
    
	// --- AXI Strobe Generation for Host Commands --- //
    // This logic detects a 64-bit command (two 32-bit transfers) from the host
    // and generates a single-cycle strobe for other blocks to use.
    reg cmd_write_done_0;
    reg cmd_write_done;

	reg cmd_read_done_0;
	reg cmd_read_done;
	
	localparam TARGET_WRITE_REG = 2'h0;
	localparam TARGET_READ_REG  = 2'h1;
	
	//-- Write detection logic
	always @(posedge clk) begin
        if (!resetn) begin
            cmd_write_done_0    <= 1'b0;
            cmd_write_done      <= 1'b0;
        end
        else if (S_AXI_WVALID && S_AXI_WREADY) begin
            // Extract the register index from the address
            if (S_AXI_AWADDR == TARGET_WRITE_REG) begin
                cmd_write_done_0 	<= 1'b1;   	// A write event occurred
                if (cmd_write_done_0)       	// Wait to the 2nd 32-bit package
                    cmd_write_done 	<= 1;
            end
        end 
        else if (cmd_write_done) begin
            cmd_write_done_0    <= 1'b0;
            cmd_write_done      <= 1'b0;
        end
    end
    
	//-- Read detection logic
    always @(posedge clk) begin
        if (!resetn) begin
        	cmd_read_done_0	  <= 1'b0;
			cmd_read_done 	  <= 1'b0;
		end
        else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
            // Latch the read address event
            if (S_AXI_ARADDR == TARGET_READ_REG) begin
            	cmd_read_done_0		<= 1'b1;  		// A read event occurred		
				if (cmd_read_done_0)       			// Wait to the 2nd 32-bit package
                    cmd_read_done <= 1;
			end
        end 
        else if (cmd_read_done) begin
            cmd_read_done_0 	<= 1'b0;
			cmd_read_done 		<= 1'b0;
        end
		else if (cmd_n_reads_done) begin
			cmd_read_done_0    <= 1'b0;
            cmd_read_done      <= 1'b0;
		end
    end

	// --- Wait for N Reads/Writes Logic --- //
	reg [31:0] cmd_n_reads;
	reg [31:0] cmd_n_writes;
	reg [31:0] cmd_reads_counter;
	reg [31:0] cmd_writes_counter;
	reg cmd_n_reads_done;
	reg cmd_n_writes_done;

	always @(posedge clk) begin
		if (!resetn) begin
			cmd_n_reads			<= 0;
			cmd_reads_counter	<= 0;
			cmd_n_reads_done 	<= 0;
		end
		else if (cmd_wait_n_reads_sel && (cmd_n_reads == 0)) begin
			cmd_n_reads 		<= peripheral_wdata;
		end
		else if (cmd_wait_n_reads_sel && (cmd_reads_counter < cmd_n_reads) && cmd_read_done) begin
			cmd_reads_counter 	<= cmd_reads_counter + 1;
		end
		else if (cmd_wait_n_reads_sel && (cmd_reads_counter == cmd_n_reads)) begin
			cmd_n_reads_done 	<= 1;
		end
		else if (!cmd_wait_n_reads_sel) begin
			cmd_n_reads			<= 0;
			cmd_reads_counter 	<= 0;
			cmd_n_reads_done 	<= 0;
		end
	end

	always @(posedge clk) begin
		if (!resetn) begin
			cmd_n_writes		<= 0;
			cmd_writes_counter	<= 0;
			cmd_n_writes_done 	<= 0;
		end
		else if (cmd_wait_n_writes_sel && (cmd_n_writes == 0)) begin
			cmd_n_writes 		<= peripheral_wdata;
		end
		else if (cmd_wait_n_writes_sel && (cmd_writes_counter < cmd_n_writes) && cmd_write_done) begin
			cmd_writes_counter 	<= cmd_writes_counter + 1;
		end
		else if (cmd_wait_n_writes_sel && (cmd_writes_counter == cmd_n_writes)) begin
			cmd_n_writes_done 	<= 1;
		end
		else if (!cmd_wait_n_writes_sel) begin
			cmd_n_writes		<= 0;
			cmd_writes_counter 	<= 0;
			cmd_n_writes_done 	<= 0;
		end
	end
    
	//==========================================================================
    //-- INPUT FIFO (Host -> FW)
    //==========================================================================
    integer i;
    
	parameter FIFO_IN_DEPTH 	= 128;
	parameter FIFO_IN_DWIDTH 	= 64;

	reg fifo_in_en;
	reg fifo_in_swap_endianness;
	reg  fifo_in_wr_en;
	reg  fifo_in_rd_en;
	reg  [63:0] fifo_in_din;
	reg  [63:0] fifo_in_din_swap_endianness;
	wire [63:0] fifo_in_dout;
	wire fifo_in_empty;
	wire fifo_in_full;
	wire [$clog2(FIFO_IN_DEPTH)-1:0] fifo_in_avail;
	
	//-- Optional endianness swapping
	always @(*) begin
	   if (fifo_in_swap_endianness) begin
	       for (i = 0; i < 8; i = i + 1) begin 
               fifo_in_din_swap_endianness[(7-i)*8+:8] = fifo_in_din[i*8+:8];
           end
	   end
	   else
	       fifo_in_din_swap_endianness = fifo_in_din;
	end

	//-- FIFO INPUT Instantiation
	fifo #(
		   .DEPTH(FIFO_IN_DEPTH),
		   .DWIDTH(FIFO_IN_DWIDTH)
		   )
		   FIFO_IN
		   (
			.rstn(resetn),
			.clk(clk),
			.wr_en(fifo_in_wr_en),
		    .rd_en(fifo_in_rd_en),
			.din(fifo_in_din_swap_endianness),
			.dout(fifo_in_dout),
			.empty(fifo_in_empty),
			.full(fifo_in_full),
			.avail(fifo_in_avail)
		   );

	//-- Input FIFO Control Logic
	always @(posedge clk) begin
	   	if (!resetn) begin
			fifo_in_en               <= 0;
	        fifo_in_swap_endianness  <= 0;
	    end
		else if (fifo_io_en_sel && peripheral_write) begin
	    	fifo_in_en               <= peripheral_wdata[0];
	    	fifo_in_swap_endianness  <= peripheral_wdata[2];
	    end
	end

	//-- Input FIFO Write Logic
	always @(posedge clk) begin
		fifo_in_wr_en 	<= 0;

		// Automatic write from Host
		if (cmd_write_done && fifo_in_en) begin
			fifo_in_wr_en 	<= 1;
			fifo_in_din		<= cmd_data_in;
		end
		// Manual write from FW
		else if (fifo_in_wr_sel) begin
		    fifo_in_wr_en 	<= 1;
		end
		if (fifo_in_wr_data_1_sel) begin
		    fifo_in_din[31:0]  <= peripheral_wdata;
		end
		else if (fifo_in_wr_data_2_sel) begin
		    fifo_in_din[63:32] <= peripheral_wdata;
		end
	end

	//-- Input FIFO Read Logic (from FW or SE)
	reg fifo_in_rd_en_delay;
	always @(posedge clk) begin
		fifo_in_rd_en		<= 0;
		fifo_in_rd_en_delay <= fifo_in_rd_en;
		
		if ((fifo_in_en && !fifo_in_empty && se_addr[31:0] < se_addr_in_limit && !fifo_in_rd_en && !fifo_in_rd_en_delay) || fifo_in_rd_sel) begin	//-- Wait till load is available and delay 1 extra cycle or fifo_in_rd_sel
			fifo_in_rd_en		<= 1;
		end
	end


	//==========================================================================
    //-- SECURE ELEMENT (SE) INTERFACE
	//==========================================================================
	//-- Cryptographic Primitives
	parameter [0:0] IMP_SHA2    = 1;
    parameter [0:0] IMP_SHA3    = 1;
    parameter [0:0] IMP_EDDSA   = 1;
    parameter [0:0] IMP_X25519  = 1;
	parameter [0:0] IMP_TRNG	= 1;
    parameter [0:0] IMP_AES     = 1;
    parameter [0:0] IMP_MLKEM  	= 1;
	parameter [0:0] IMP_MLDSA	= 1;
	parameter [0:0] IMP_SLHDSA	= 1;

    reg  [63:0] se_data_in;
    reg  [63:0] se_addr;
    reg  [63:0] se_control;
    wire [63:0] se_data_out;
    wire [1:0] se_end_op;

	reg [31:0] se_addr_in_limit;
	reg [31:0] se_addr_out_limit;

	reg se_interface;

	always @(posedge clk) begin
		if (!resetn) begin
			se_addr_in_limit 	<= 0;
			se_addr_out_limit 	<= 0;
			se_interface		<= 0;
		end
		else begin
			if (se_addr_in_limit_sel  	&& peripheral_write) se_addr_in_limit  	<= peripheral_wdata;
			if (se_addr_out_limit_sel 	&& peripheral_write) se_addr_out_limit 	<= peripheral_wdata;
			if (se_interface_sel 		&& peripheral_write) se_interface 		<= peripheral_wdata[0];
		end
	end
    
	//-- SE Register Write Logic
	reg first_addr_delay;			// Delay correction for 1st address

    always @(posedge clk) begin
	   	if (!resetn) begin
	   	    se_data_in  		<= 0;
	   	    se_addr[31:0]   	<= 0;
	   	    se_control  		<= 0;
			first_addr_delay 	<= 0;
	   	end
		else begin
			// Manual writes from firmware
	   		if (se_data_in_1_sel && peripheral_write) se_data_in[31:0]    <= peripheral_wdata;
	   		if (se_data_in_2_sel && peripheral_write) se_data_in[63:32]   <= peripheral_wdata;
	   		if (se_addr_1_sel 	 && peripheral_write) se_addr[31:0]       <= peripheral_wdata;
			if (se_control_1_sel && peripheral_write) se_control[31:0]    <= peripheral_wdata;
	   		if (se_control_2_sel && peripheral_write) se_control[63:32]   <= peripheral_wdata;

			// Automatic write from Input FIFO to SE
			if (fifo_in_rd_en_delay && se_addr[31:0] < se_addr_in_limit) begin
				se_data_in 			<= fifo_in_dout;
				se_addr[31:0] 		<= (first_addr_delay) ? se_addr[31:0] + 1 : se_addr[31:0]; 		// Increase the write address
				se_control[2]		<= (!se_interface) ? 1 : se_control[2];							// Active Write 
				first_addr_delay 	<= 1;
			end
			else if (fifo_in_en && se_addr[31:0] < se_addr_in_limit && !se_interface) begin
				se_control[2] 	<= 0;
			end
			else if (se_addr[31:0] == se_addr_in_limit) begin
				first_addr_delay <= 0;
			end
		end
	end
	
	//-- Secure Element Instantiation
    (* keep_hierarchy = "yes" *) SE_QUBIP #(
                                            .IMP_SHA2(IMP_SHA2), 
                                            .IMP_SHA3(IMP_SHA3),
                                            .IMP_EDDSA(IMP_EDDSA),
                                            .IMP_X25519(IMP_X25519),
                                            .IMP_AES(IMP_AES),
                                            .IMP_MLKEM (IMP_MLKEM)
                                            )
                                            SE_QUBIP
                                            (
                                             .i_clk(clk),
                                             .i_rst(resetn),
                                             .i_data_in(se_data_in),
                                             .i_add(se_addr), 
                                             .i_control(se_control),
                                             .o_data_out(se_data_out),
                                             .o_end_op(se_end_op)
                                             );

	
	//==========================================================================
    //-- OUTPUT FIFO (FW -> Host)
    //==========================================================================
	parameter FIFO_OUT_DEPTH	= 128;
	parameter FIFO_OUT_DWIDTH 	= 64;

	reg fifo_out_en;
	reg fifo_out_swap_endianness;
	reg  fifo_out_wr_en;
	reg  fifo_out_rd_en;
	reg  [63:0] fifo_out_din;
	wire [63:0] fifo_out_dout;
	reg  [63:0] fifo_out_dout_swap_endianness;
	wire fifo_out_empty;
	wire fifo_out_full;
	wire [$clog2(FIFO_IN_DEPTH)-1:0] fifo_out_avail;

	//-- Optional endianness swapping
    always @(*) begin
	   if (fifo_out_swap_endianness) begin
	       for (i = 0; i < 8; i = i + 1) begin 
               fifo_out_dout_swap_endianness[(7-i)*8+:8] = fifo_out_dout[i*8+:8];
           end
	   end
	   else
	       fifo_out_dout_swap_endianness = fifo_out_dout;
	end

	//-- FIFO OUTPUT Instantiation
	fifo #(
		   .DEPTH(FIFO_OUT_DEPTH),
		   .DWIDTH(FIFO_OUT_DWIDTH)
		   )
		   FIFO_OUT
		   (
			.rstn(resetn),
			.clk(clk),
			.wr_en(fifo_out_wr_en),
		    .rd_en(fifo_out_rd_en),
			.din(fifo_out_din),
			.dout(fifo_out_dout),
			.empty(fifo_out_empty),
			.full(fifo_out_full),
			.avail(fifo_out_avail)
		   );

	//-- Output FIFO Control Logic
	always @(posedge clk) begin
	   	if (!resetn) begin
			fifo_out_en               <= 0;
	        fifo_out_swap_endianness  <= 0;
	    end
		else if (fifo_io_en_sel && peripheral_write) begin
	    	fifo_out_en               <= peripheral_wdata[1];
	    	fifo_out_swap_endianness  <= peripheral_wdata[3];
	    end
	end

	//-- Output FIFO Write Logic
	always @(posedge clk) begin
	   	fifo_out_wr_en 	<= 0;

	   	// Automatic write from SE to Output FIFO
		if ((se_control[3] || se_interface) && !fifo_out_full && fifo_out_en && se_addr[63:32] < se_addr_out_limit && !fifo_out_wr_en) begin //-- Wait till read is available
			fifo_out_wr_en 	<= 1;
			fifo_out_din	<= se_data_out;
			se_addr[63:32] 	<= se_addr[63:32] + 1; 	// Increase the read address
		end
		// Manual write from firmware
		else if (fifo_out_wr_sel) begin
            fifo_out_wr_en <= 1'b1;
		end
		// Manual data loading from firmware
		if (fifo_out_wr_data_1_sel) fifo_out_din[31:0] 			<= peripheral_wdata;
		if (fifo_out_wr_data_2_sel) fifo_out_din[63:32]			<= peripheral_wdata;
		// SE read address update (manual)
		if (se_addr_2_sel && peripheral_write) se_addr[63:32] 	<= peripheral_wdata;
	end

	//-- Output FIFO Read Logic (from Host or FW)
	reg fifo_out_rd_en_delay;
	always @(posedge clk) begin
		fifo_out_rd_en			<= 0;
		fifo_out_rd_en_delay	<= fifo_out_rd_en;

		if ((cmd_read_done && fifo_out_en) || (cmd_control_1_sel && peripheral_wdata[3:0] == 6 && fifo_out_en) || fifo_out_rd_sel) begin //-- Advance the rptr 1 position
			fifo_out_rd_en	 	<= 1;
		end
	end

	//==========================================================================
    //-- RO TRNG
    //==========================================================================
	parameter TRNG_SIM		= 1;				// 	0
	parameter TRNG_UNITS 	= 4;     			// 	4
    parameter BANK_UNITS 	= 8;     			// 	8
    parameter TRNG_SIZE  	= 262144;			// 	262144
    parameter BLOCK_SIZE 	= 32;    			// 	32
    parameter CG_TYPE    	= 1;     			// 	1
    parameter Dbw        	= 32;    			// 	32
    parameter Bpc        	= 4;     			// 	2
    parameter Nbc        	= 8;				// 	8

	localparam MEM_DEPTH  = TRNG_SIZE / Dbw;
    localparam ADDR_WIDTH = $clog2(MEM_DEPTH);

	reg  trng_read;
	wire trng_valid;
	wire [ADDR_WIDTH-1:0] trng_occp;
	wire [BLOCK_SIZE-1:0] trng_out;

	generate if (IMP_TRNG) begin: TRNG
		(* keep_hierarchy = "yes" *) trng #(
											.TRNG_SIM(TRNG_SIM),
											.TRNG_UNITS(TRNG_UNITS),
											.BANK_UNITS(BANK_UNITS),
											.TRNG_SIZE(TRNG_SIZE),										
											.BLOCK_SIZE(BLOCK_SIZE),
											.CG_TYPE(CG_TYPE),
											.Dbw(Dbw),
											.Bpc(Bpc),
											.Nbc(Nbc)										
											)
											TRNG
											(
			   								.clock(clk),
			   								.reset(!resetn),
			   								.SD(1'b0),
											.trng_ren(1'b1),
											.trng_read(trng_read),
											.trng_valid(trng_valid),
											.trng_occp(trng_occp),
											.trng_out(trng_out)
											);
	end
	endgenerate

	//-- Assert trng_read and trng_read_done when trng_valid
	reg trng_read_done;

	always @(posedge clk) begin
		if (!resetn)
			trng_read <= 0;
		else if (trng_read_sel && trng_valid && !trng_read && !trng_read_done)
			trng_read <= 1;
		else
			trng_read <= 0;
	end

	always @(posedge clk) begin
		if (!resetn)
			trng_read_done <= 0;
		else if (trng_read)
			trng_read_done <= 1;
		else if (!trng_read_sel)
			trng_read_done <= 0;
	end
	      
	//==========================================================================
    //-- SLH-DSA HASH MODULES
    //==========================================================================
    wire [31:0] keccak_rdata;
	wire [31:0] sha256_rdata;
	wire [31:0] sha512_rdata;

	generate if (IMP_SLHDSA) begin: SLHDSA
    	(* keep_hierarchy = "yes" *) keccak_sloth KECCAK_SLOTH (
    	    					   								.clk(clk),
    	    					   								.rst(!resetn),
    	    					   								.sel(slh_keccak_sel),
    	    					   								.wen(peripheral_wstrb),
    	    					   								.addr(peripheral_addr[8:2]),
    	    					   								.wdata(peripheral_wdata),
    	    					   								.rdata(keccak_rdata)
    							   								);


		(* keep_hierarchy = "yes" *) sha256_sloth SHA256_SLOTH (
    	    					   								.clk(clk),
    	    					   								.rst(!resetn),
    	    					   								.sel(slh_sha256_sel),
    	    					   								.wen(peripheral_wstrb),
    	    					   								.addr(peripheral_addr[8:2]),
    	    					   								.wdata(peripheral_wdata),
    	    					   								.rdata(sha256_rdata)
    							   								);


		(* keep_hierarchy = "yes" *) sha512_sloth SHA512_SLOTH (
    	    					   								.clk(clk),
    	    					   								.rst(!resetn),
    	    					   								.sel(slh_sha512_sel),
    	    					   								.wen(peripheral_wstrb),
    	    					   								.addr(peripheral_addr[8:2]),
    	    					   								.wdata(peripheral_wdata),
    	    					   								.rdata(sha512_rdata)
    							   								);
	end
	endgenerate

	//==========================================================================
    //-- SECURE MEMORY
    //==========================================================================

	reg [31:0] secmem_addr;
	wire [31:0] secmem_data_out;

	always @(posedge clk) begin
		if (!resetn) 
			secmem_addr <= 0;
		else if (secmem_addr_sel)
			secmem_addr <= peripheral_wdata;
	end

	genram #(
			 .AW(10),
			 .DW(32)
			 )
			 SECURE_MEMORY
			 (
			  .clk_A(clk),
			  .wr_A(secmem_data_in_sel),
			  .addr_A(secmem_addr),
			  .data_in_A(peripheral_wdata),
			  .data_out_A(secmem_data_out)
			 );


	//==========================================================================
    //-- IMPLEMENTATION INFO
    //==========================================================================
	wire [31:0] imp_info = {23'b0, IMP_SLHDSA, IMP_MLDSA, IMP_MLKEM, IMP_AES, IMP_TRNG, IMP_X25519, IMP_EDDSA, IMP_SHA3, IMP_SHA2};

	//==========================================================================
    //-- MEMORY BUS MUXING LOGIC
    //==========================================================================
	//-- mem_ready is asserted when any memory-mapped peripheral is ready to respond to the CPU.
	wire single_cycle_peripheral_ready;
	wire multi_cycle_peripheral_ready;
	wire peripheral_ready; 

	//-- One single cycle peripherals
	wire is_single_cycle_op = |{cmd_control_1_sel, cmd_control_2_sel, 
								cmd_write_1_sel, cmd_write_2_sel, 
								cmd_read_1_sel, cmd_read_2_sel, 

								se_data_in_1_sel, se_data_in_2_sel, 
								se_addr_1_sel, se_addr_2_sel, 
								se_control_1_sel, se_control_2_sel, 
								se_data_out_1_sel, se_data_out_2_sel, 
								se_end_op_sel, 
								se_addr_in_limit_sel, se_addr_out_limit_sel,
								se_interface_sel,

								fifo_io_en_sel, fifos_info_sel, 
								fifo_in_wr_sel,
								fifo_in_wr_data_1_sel, fifo_in_wr_data_2_sel,
								fifo_in_rd_sel,
								fifo_in_rd_data_1_sel, fifo_in_rd_data_2_sel,
								fifo_out_wr_sel,
								fifo_out_wr_data_1_sel, fifo_out_wr_data_2_sel,
								fifo_out_rd_sel,
								fifo_out_rd_data_1_sel, fifo_out_rd_data_2_sel,

								dma_dst_addr_sel,
								dma_src_addr_sel,
								dma_len_bytes_sel,
								dma_swap_endianness_sel,

								wdt_start_sel,
								wdt_stop_sel,

								sw_debug_0_sel,
								sw_debug_1_sel,
								sw_debug_2_sel,
								sw_debug_3_sel,
								sw_debug_4_sel,
								
								trng_occp_sel,

								secmem_addr_sel,
								secmem_data_in_sel,
								secmem_data_out_sel,

								imp_info_sel
								};
	
	assign single_cycle_peripheral_ready = is_single_cycle_op;

	//-- Multiple cycles peripherals
	assign multi_cycle_peripheral_ready = |{cmd_wait_read_sel & cmd_read_done,
											cmd_wait_write_sel & cmd_write_done,
											cmd_wait_n_reads_sel & cmd_n_reads_done,
											cmd_wait_n_writes_sel & cmd_n_writes_done,

											dma_memcpy_sel & dma_memcpy_done,
											dma_memset_sel & dma_memset_done,
											dma_memcmp_sel & dma_memcmp_done,
											
											trng_read_sel & trng_read_done,
											
											(slh_keccak_sel | slh_sha256_sel | slh_sha512_sel) & slh_done
											};

	assign peripheral_ready = single_cycle_peripheral_ready | multi_cycle_peripheral_ready;

	assign mem_ready = (ram_ready) | (|irq) | (peripheral_ready);


	//-- mem_rdata multiplexes the read data from the selected peripheral to the CPU.
	reg [31:0] peripheral_rdata;

	always @(*) begin
		case(1'b1)

		(cmd_control_1_sel): 		peripheral_rdata = cmd_control[31:0];
		(cmd_control_2_sel): 		peripheral_rdata = cmd_control[63:32];
		(cmd_write_1_sel): 			peripheral_rdata = cmd_data_out[31:0];
		(cmd_write_2_sel): 			peripheral_rdata = cmd_data_out[63:32];
		(cmd_read_1_sel): 			peripheral_rdata = cmd_data_in[31:0];
		(cmd_read_2_sel): 			peripheral_rdata = cmd_data_in[63:32];

		(se_data_in_1_sel): 		peripheral_rdata = se_data_in[31:0];        
		(se_data_in_2_sel): 		peripheral_rdata = se_data_in[63:32];       
		(se_addr_1_sel):			peripheral_rdata = se_addr[31:0];           
		(se_addr_2_sel):			peripheral_rdata = se_addr[63:32];          
		(se_control_1_sel):			peripheral_rdata = se_control[31:0];        
		(se_control_2_sel):			peripheral_rdata = se_control[63:32];       
		(se_data_out_1_sel): 		peripheral_rdata = se_data_out[31:0];       
		(se_data_out_2_sel): 		peripheral_rdata = se_data_out[63:32];      
		(se_end_op_sel):			peripheral_rdata = {30'h0, se_end_op};      
		(se_addr_in_limit_sel):		peripheral_rdata = se_addr_in_limit;		
		(se_addr_out_limit_sel):	peripheral_rdata = se_addr_out_limit;		

		(fifo_io_en_sel):			peripheral_rdata = {fifo_out_swap_endianness, fifo_in_swap_endianness, fifo_out_en, fifo_in_en};
		(fifos_info_sel):			peripheral_rdata = {fifo_out_avail, fifo_in_avail, fifo_out_empty, fifo_out_full, fifo_in_empty, fifo_in_full};
		(fifo_in_rd_data_1_sel):	peripheral_rdata = fifo_in_dout[31:0];    
		(fifo_in_rd_data_2_sel):	peripheral_rdata = fifo_in_dout[63:32];   
		(fifo_out_rd_data_1_sel):	peripheral_rdata = fifo_out_dout[31:0];  
		(fifo_out_rd_data_2_sel):	peripheral_rdata = fifo_out_dout[63:32];

		(dma_dst_addr_sel):			peripheral_rdata = dma_dst_addr;								
		(dma_src_addr_sel):			peripheral_rdata = dma_src_addr;						
		(dma_len_bytes_sel):		peripheral_rdata = dma_len_bytes;							
		(dma_memcmp_sel):			peripheral_rdata = (dma_memcmp_result[1]) ? 32'hFFFFFFFF : dma_memcmp_result;

		(sw_debug_0_sel):			peripheral_rdata = sw_debug_0;
		(sw_debug_1_sel):			peripheral_rdata = sw_debug_1;
		(sw_debug_2_sel):			peripheral_rdata = sw_debug_2;
		(sw_debug_3_sel):			peripheral_rdata = sw_debug_3;
		(sw_debug_4_sel):			peripheral_rdata = sw_debug_4;

		(trng_read_sel):			peripheral_rdata = trng_out;
		(trng_occp_sel):			peripheral_rdata = trng_occp;

		(slh_keccak_sel):			peripheral_rdata = keccak_rdata;
		(slh_sha256_sel):			peripheral_rdata = sha256_rdata;
		(slh_sha512_sel):			peripheral_rdata = sha512_rdata;

		(secmem_addr_sel):			peripheral_rdata = secmem_addr;
		(secmem_data_out_sel):		peripheral_rdata = secmem_data_out;

		(imp_info_sel):				peripheral_rdata = imp_info;

		default:					peripheral_rdata = 32'h0000_0000;			

		endcase
	end

	assign mem_rdata = (ram_ready) ? ram_rdata : peripheral_rdata;


endmodule

// Implementation note:
// Replace the following two modules with wrappers for your SRAM cells.
/*
module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule 
*/

/* module picosoc_mem #(
	parameter integer WORDS = 4096
) (
	input clk,
	input [3:0] wen,
	input [21:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];

	initial $readmemh("fw/bin/firmware.hex", mem);

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
	end
endmodule */
/*
module picosoc_mem #(
	parameter integer WORDS = 4096
) (
	input wire clk,
    // Port A signals
	input wire [3:0]  wen_a,
	input wire [21:0] addr_a,
	input wire [31:0] wdata_a,
	output reg [31:0] rdata_a,
    // Port B signals
    input wire [3:0]  wen_b,
	input wire [21:0] addr_b,
	input wire [31:0] wdata_b,
	output reg [31:0] rdata_b
);
	// The core memory array
    reg [31:0] mem [0:WORDS-1];

	// Firmware is loaded through Port A during initialization
	initial $readmemh("fw/bin/firmware.hex", mem);

	// --- Port A Logic ---
	// Handles reads and writes from Port A
	always @(posedge clk) begin
		// Read operation (combinatorial read-first behavior)
		rdata_a <= mem[addr_a];
		// Write operation with byte-enables
		if (wen_a[0]) mem[addr_a][ 7: 0] <= wdata_a[ 7: 0];
		if (wen_a[1]) mem[addr_a][15: 8] <= wdata_a[15: 8];
		if (wen_a[2]) mem[addr_a][23:16] <= wdata_a[23:16];
		if (wen_a[3]) mem[addr_a][31:24] <= wdata_a[31:24];
	end 

    // --- Port B Logic ---
	// Handles reads and writes from Port B
    always @(posedge clk) begin
        // Read operation (combinatorial read-first behavior)
		rdata_b <= mem[addr_b];
		// Write operation with byte-enables
		if (wen_b[0]) mem[addr_b][ 7: 0] <= wdata_b[ 7: 0];
		if (wen_b[1]) mem[addr_b][15: 8] <= wdata_b[15: 8];
		if (wen_b[2]) mem[addr_b][23:16] <= wdata_b[23:16];
		if (wen_b[3]) mem[addr_b][31:24] <= wdata_b[31:24];
    end

endmodule
*/
