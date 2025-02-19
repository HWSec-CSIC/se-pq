
`timescale 1 ns / 1 ps

	module SE_QUBIP_v2_0 #
	(
		// Users to add parameters here
        parameter integer IMP_SHA2            = 1,
        parameter integer IMP_SHA3            = 1,
        parameter integer IMP_EDDSA           = 1,
        parameter integer IMP_X25519          = 1,
        parameter integer IMP_TRNG            = 1,
        parameter integer IMP_AES             = 1,
        parameter integer IMP_MLKEM           = 1,
        // I2C Parameters
        parameter integer IMP_I2C             = 1,
        parameter [6:0] DEVICE_ADDRESS        = 7'h1A,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 64,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
        input wire rst,
        input wire SCL,
        inout wire SDA,     
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
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
	SE_QUBIP_v2_0_S00_AXI # ( 
	    .IMP_SHA2(IMP_SHA2), 
        .IMP_SHA3(IMP_SHA3),
        .IMP_EDDSA(IMP_EDDSA),
        .IMP_X25519(IMP_X25519),
        .IMP_TRNG(IMP_TRNG),
        .IMP_AES(IMP_AES),
        .IMP_MLKEM(IMP_MLKEM),
        .IMP_I2C(IMP_I2C),
        .DEVICE_ADDRESS(DEVICE_ADDRESS),		
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) SE_QUBIP_v2_0_S00_AXI_inst (
	    .rst(rst),
        .SCL(SCL),
        .SDA(SDA_out),
        .output_control(output_control),		
		.S_AXI_ACLK(s00_axi_aclk),
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
