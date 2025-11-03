
`timescale 1 ns / 1 ps

	module SE_QUBIP_PICORV_slave_lite_v1_0_S00_AXI #
	(
		// Users to add parameters here
		parameter [0:0] 	BARREL_SHIFTER			= 0,
		parameter [0:0] 	ENABLE_MUL				= 1,
		parameter [0:0] 	ENABLE_DIV				= 1,
		parameter [0:0] 	ENABLE_FAST_MUL			= 0,
		parameter [0:0] 	ENABLE_COMPRESSED		= 1,
		parameter [0:0] 	ENABLE_IRQ				= 1,
		parameter [0:0] 	TWO_CYCLE_COMPARE		= 1,
		parameter [0:0] 	TWO_CYCLE_ALU			= 1,
		parameter integer 	MEM_WORDS				= 65536,
		parameter [31:0] 	PROGADDR_RESET			= 32'h0000_0000,
		parameter [31:0] 	PROGADDR_IRQ			= 32'h0000_0060,
		parameter [31:0] 	PERIPHERALS_BASE_ADDR	= 32'h0100_0000,
		parameter [31:0] 	SLH_KECCAK_BASE_ADDR	= 32'h0200_0000,
		parameter [31:0] 	SLH_SHA256_BASE_ADDR	= 32'h0400_0000,
		parameter [31:0] 	SLH_SHA512_BASE_ADDR	= 32'h0800_0000,
		parameter [0:0] 	IMP_SHA2				= 1,
		parameter [0:0] 	IMP_SHA3				= 1,
		parameter [0:0] 	IMP_EDDSA				= 1,
		parameter [0:0] 	IMP_X25519				= 1,
		parameter [0:0] 	IMP_TRNG				= 1,
		parameter [0:0] 	IMP_AES					= 1,
		parameter [0:0] 	IMP_MLKEM				= 1,
		parameter [0:0] 	IMP_MLDSA				= 1,
		parameter [0:0] 	IMP_SLHDSA				= 1,
		parameter integer   TRNG_SIZE               = 32768,
		// I2C Parameters
        parameter integer   IMP_I2C                 = 1,                         
        parameter [6:0]     DEVICE_ADDRESS          = 7'h1A,
        // Clock Frequency
        parameter [9:0]    IMP_CLK_FREQ             = 100,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 64,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        input wire rst,
        input wire SCL,
        input wire SDA,
        output wire output_control,
        output wire spi_sclk,
    	output wire spi_csn,
    	output wire spi_dq0_o,
    	input  wire spi_dq1_i,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	generate if (!IMP_I2C) begin: not_I2C
	   wire [63:0] cmd_data_out;
	   wire [63:0] cmd_control;
	   wire [31:0] AXI_RAM_RDATA;
	end
	endgenerate
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	integer	 byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	 //state machine varibles 
	 reg [1:0] state_write;
	 reg [1:0] state_read;
	 //State machine local parameters
	 localparam Idle = 2'b00,Raddr = 2'b10,Rdata = 2'b11 ,Waddr = 2'b10,Wdata = 2'b11;
	// Implement Write state machine
	// Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
	always @(posedge S_AXI_ACLK)                                 
	  begin                                 
	     if (S_AXI_ARESETN == 1'b0)                                 
	       begin                                 
	         axi_awready <= 0;                                 
	         axi_wready <= 0;                                 
	         axi_bvalid <= 0;                                 
	         axi_bresp <= 0;                                 
	         axi_awaddr <= 0;                                 
	         state_write <= Idle;                                 
	       end                                 
	     else                                  
	       begin                                 
	         case(state_write)                                 
	           Idle:                                      
	             begin                                 
	               if(S_AXI_ARESETN == 1'b1)                                  
	                 begin                                 
	                   axi_awready <= 1'b1;                                 
	                   axi_wready <= 1'b1;                                 
	                   state_write <= Waddr;                                 
	                 end                                 
	               else state_write <= state_write;                                 
	             end                                 
	           Waddr:        //At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state                                 
	             begin                                 
	               if (S_AXI_AWVALID && S_AXI_AWREADY)                                 
	                  begin                                 
	                    axi_awaddr <= S_AXI_AWADDR;                                 
	                    if(S_AXI_WVALID)                                  
	                      begin                                   
	                        axi_awready <= 1'b1;                                 
	                        state_write <= Waddr;                                 
	                        axi_bvalid <= 1'b1;                                 
	                      end                                 
	                    else                                  
	                      begin                                 
	                        axi_awready <= 1'b0;                                 
	                        state_write <= Wdata;                                 
	                        if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                      end                                 
	                  end                                 
	               else                                  
	                  begin                                 
	                    state_write <= state_write;                                 
	                    if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                   end                                 
	             end                                 
	          Wdata:        //At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length                                 
	             begin                                 
	               if (S_AXI_WVALID)                                 
	                 begin                                 
	                   state_write <= Waddr;                                 
	                   axi_bvalid <= 1'b1;                                 
	                   axi_awready <= 1'b1;                                 
	                 end                                 
	                else                                  
	                 begin                                 
	                   state_write <= state_write;                                 
	                   if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                 end                                              
	             end                                 
	          endcase                                 
	        end                                 
	      end                                 

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	    end 
	  else begin
	    if (S_AXI_WVALID)
	      begin
	        case ( (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement read state machine
	  always @(posedge S_AXI_ACLK)                                       
	    begin                                       
	      if (S_AXI_ARESETN == 1'b0)                                       
	        begin                                       
	         //asserting initial values to all 0's during reset                                       
	         axi_arready <= 1'b0;                                       
	         axi_rvalid <= 1'b0;                                       
	         axi_rresp <= 1'b0;                                       
	         state_read <= Idle;                                       
	        end                                       
	      else                                       
	        begin                                       
	          case(state_read)                                       
	            Idle:     //Initial state inidicating reset is done and ready to receive read/write transactions                                       
	              begin                                                
	                if (S_AXI_ARESETN == 1'b1)                                        
	                  begin                                       
	                    state_read <= Raddr;                                       
	                    axi_arready <= 1'b1;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	            Raddr:        //At this state, slave is ready to receive address along with corresponding control signals                                       
	              begin                                       
	                if (S_AXI_ARVALID && S_AXI_ARREADY)                                       
	                  begin                                       
	                    state_read <= Rdata;                                       
	                    axi_araddr <= S_AXI_ARADDR;                                       
	                    axi_rvalid <= 1'b1;                                       
	                    axi_arready <= 1'b0;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	            Rdata:        //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                       
	              begin                                           
	                if (S_AXI_RVALID && S_AXI_RREADY)                                       
	                  begin                                       
	                    axi_rvalid <= 1'b0;                                       
	                    axi_arready <= 1'b1;                                       
	                    state_read <= Raddr;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	           endcase                                       
	          end                                       
	        end                                         
	// Implement memory mapped register select and read logic generation
	generate if (IMP_I2C) begin
	   assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0) ? slv_reg0 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1) ? slv_reg1 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) ? slv_reg2 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) ? slv_reg3 :0;  
	end
	else begin
	   assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0) ? slv_reg0 : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1) ? not_I2C.cmd_data_out : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) ? not_I2C.cmd_control : (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) ? not_I2C.AXI_RAM_RDATA :0;
	end
	endgenerate
	// Add user logic here
    generate if (IMP_I2C) begin
        I2C_QUBIP #(
                  .DEVICE_ADDRESS(DEVICE_ADDRESS),
                  .BARREL_SHIFTER(BARREL_SHIFTER), 		
	    		  .ENABLE_MUL(ENABLE_MUL), 			
	    		  .ENABLE_DIV(ENABLE_DIV), 			
	    		  .ENABLE_FAST_MUL(ENABLE_FAST_MUL), 	
	    		  .ENABLE_COMPRESSED(ENABLE_COMPRESSED),	
	    		  .ENABLE_IRQ(ENABLE_IRQ), 			
	    		  .TWO_CYCLE_COMPARE(TWO_CYCLE_COMPARE),
	    		  .TWO_CYCLE_ALU(TWO_CYCLE_ALU),    
                  .MEM_WORDS(MEM_WORDS),
	    		  .PROGADDR_RESET(PROGADDR_RESET),
	    		  .PROGADDR_IRQ(PROGADDR_IRQ),
	    		  .PERIPHERALS_BASE_ADDR(PERIPHERALS_BASE_ADDR),
	    		  .SLH_KECCAK_BASE_ADDR(SLH_KECCAK_BASE_ADDR),
	    		  .SLH_SHA256_BASE_ADDR(SLH_SHA256_BASE_ADDR),
	    		  .SLH_SHA512_BASE_ADDR(SLH_SHA512_BASE_ADDR),
	    		  .IMP_SHA2(IMP_SHA2),  
	    		  .IMP_SHA3(IMP_SHA3),  
	    		  .IMP_EDDSA(IMP_EDDSA), 
	    		  .IMP_X25519(IMP_X25519),
	    		  .IMP_TRNG(IMP_TRNG),
	    		  .IMP_AES(IMP_AES),   
	    		  .IMP_MLKEM(IMP_MLKEM),
	    		  .IMP_MLDSA(IMP_MLDSA),
	    		  .IMP_SLHDSA(IMP_SLHDSA),
	    		  .TRNG_SIZE(TRNG_SIZE),
	    		  .IMP_CLK_FREQ(IMP_CLK_FREQ)
	    		  )
        		  I2C_QUBIP
	    		  (
                   .clk(S_AXI_ACLK),
                   .rst(rst),
                   .SCL(SCL),
                   .SDA(SDA),
                   .output_control(output_control),
                   .spi_sclk(spi_sclk),   
                   .spi_csn(spi_csn),    
                   .spi_dq0_o(spi_dq0_o),  
                   .spi_dq1_i(spi_dq1_i)
                   );
    end
    else begin
        //-- PICOSOC
        picosoc #(
                  .BARREL_SHIFTER(BARREL_SHIFTER), 		
	    		  .ENABLE_MUL(ENABLE_MUL), 			
	    		  .ENABLE_DIV(ENABLE_DIV), 			
	    		  .ENABLE_FAST_MUL(ENABLE_FAST_MUL), 	
	    		  .ENABLE_COMPRESSED(ENABLE_COMPRESSED),	
	    		  .ENABLE_IRQ(ENABLE_IRQ), 			
	    		  .TWO_CYCLE_COMPARE(TWO_CYCLE_COMPARE),
	    		  .TWO_CYCLE_ALU(TWO_CYCLE_ALU),    
                  .MEM_WORDS(MEM_WORDS),
	    		  .PROGADDR_RESET(PROGADDR_RESET),
	    		  .PROGADDR_IRQ(PROGADDR_IRQ),
	    		  .PERIPHERALS_BASE_ADDR(PERIPHERALS_BASE_ADDR),
	    		  .SLH_KECCAK_BASE_ADDR(SLH_KECCAK_BASE_ADDR),
	    		  .SLH_SHA256_BASE_ADDR(SLH_SHA256_BASE_ADDR),
	    		  .SLH_SHA512_BASE_ADDR(SLH_SHA512_BASE_ADDR),
	    		  .IMP_SHA2(IMP_SHA2),  
	    		  .IMP_SHA3(IMP_SHA3),  
	    		  .IMP_EDDSA(IMP_EDDSA), 
	    		  .IMP_X25519(IMP_X25519),
	    		  .IMP_TRNG(IMP_TRNG),
	    		  .IMP_AES(IMP_AES),   
	    		  .IMP_MLKEM(IMP_MLKEM),
	    		  .IMP_MLDSA(IMP_MLDSA),
	    		  .IMP_SLHDSA(IMP_SLHDSA),
	    		  .TRNG_SIZE(TRNG_SIZE),
	    		  .IMP_I2C(IMP_I2C),
	    		  .IMP_CLK_FREQ(IMP_CLK_FREQ)
	    		  )
        		  PICOSOC
	    		  (
                   .clk(S_AXI_ACLK),
                   .rst_n(S_AXI_ARESETN && !rst && !slv_reg3[31]),
                   .AXI_RAM_WEN_ADDR(slv_reg3[31:0]),
                   .AXI_RAM_WDATA(slv_reg3[63:32]),
                   .AXI_RAM_RDATA(not_I2C.AXI_RAM_RDATA),
                   .S_AXI_WVALID(S_AXI_WVALID),
                   .S_AXI_WREADY(S_AXI_WREADY),
                   .S_AXI_AWADDR(S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]),
                   .S_AXI_ARVALID(S_AXI_ARVALID),
                   .S_AXI_ARREADY(S_AXI_ARREADY),
                   .S_AXI_ARADDR(S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]),
                   .cmd_data_in(slv_reg0[63:0]),
                   .cmd_data_out(not_I2C.cmd_data_out),
                   .cmd_control(not_I2C.cmd_control),
                   .spi_sclk(spi_sclk),   
                   .spi_csn(spi_csn),    
                   .spi_dq0_o(spi_dq0_o),  
                   .spi_dq1_i(spi_dq1_i)
                   );
    end
    endgenerate
	// User logic ends

	endmodule
