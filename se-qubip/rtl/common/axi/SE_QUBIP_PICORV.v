
`timescale 1 ns / 1 ps

	module SE_QUBIP_PICORV # 
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
        parameter [0:0]   	IMP_I2C                 = 0,
        parameter [6:0]     DEVICE_ADDRESS          = 7'h1A,
		// SCP-03 Parameters
		parameter [0:0]   	IMP_SCP03               = 0,
        parameter [1:0]     SCP03_AES_LEN          	= 2'b01,
        parameter [255:0]   SCP03_KEY_ENC          	= 256'h000102030405060708090A0B0C0D0E0F_1011121314151617_18191A1B1C1D1E1F,
        parameter [255:0]   SCP03_KEY_MAC          	= 256'h202122232425262728292A2B2C2D2E2F_3031323334353637_38393A3B3C3D3E3F,
        // Clock Frequency
        parameter [9:0]     IMP_CLK_FREQ            = 100,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 64,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        input wire rst,
        input wire SCL,
        inout wire SDA,
        output wire spi_sclk,
    	output wire spi_csn,
    	output wire spi_dq0_o,
    	input  wire spi_dq1_i,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  clk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	SE_QUBIP_PICORV_slave_lite_v1_0_S00_AXI # ( 
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
        .DEVICE_ADDRESS(DEVICE_ADDRESS),
		.IMP_SCP03(IMP_SCP03),
		.SCP03_AES_LEN(SCP03_AES_LEN),
		.SCP03_KEY_ENC(SCP03_KEY_ENC),
		.SCP03_KEY_MAC(SCP03_KEY_MAC),
        .IMP_CLK_FREQ(IMP_CLK_FREQ),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) SE_QUBIP_PICORV_slave_lite_v1_0_S00_AXI_inst (
	    .rst(rst),
	    .SCL(SCL),
        .SDA(SDA_out),
        .output_control(output_control),
        .spi_sclk(spi_sclk),   
        .spi_csn(spi_csn),    
        .spi_dq0_o(spi_dq0_o),  
        .spi_dq1_i(spi_dq1_i),
		.S_AXI_ACLK(clk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here
	wire SDA_out;
	wire output_control;
	
    IOBUF #(
            .DRIVE(12),              // Specify the output drive strength
            .IBUF_LOW_PWR("FALSE"),  // Low Power - "TRUE", High Performance = "FALSE"
            .IOSTANDARD("LVCMOS33"), // Specify the I/O standard
            .SLEW("FAST")            // Specify the output slew rate
            ) 
            IOBUF_inst 
            (
            .O(SDA_out),            // Buffer output
            .IO(SDA),               // Buffer inout port (connect directly to top-level port)
            .I(1'b0),               // Buffer input
            .T(output_control)      // 3-state enable input, high=input, low=output
            );
	// User logic ends

	endmodule
