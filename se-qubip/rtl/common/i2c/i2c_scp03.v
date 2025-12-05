////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 09/09/2024
// Update Date: 27/11/2025
// Design Name: i2c_scp03.v
// Module Name: i2c_scp03
// Project Name: SE-QUBIP
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		I2C Slave for SE-QUBIP. It includes Synchronizers and a Glith Filter 
//      
//      Based on:
//          - https://github.com/jiacaiyuan/i2c_slave
//          - https://www.doulos.com/knowhow/fpga/synchronization-and-edge-detection
//          - https://www.doulos.com/knowhow/fpga/cleaning-dirty-signals/
//		
// Additional Comment:
//
// 		WRITE means MASTER write into SLAVE
// 		READ  means MASTER read  from SLAVE
//  
//      Glitch Filter Dynamic Configuration:
//          - Register 0xFD controls zero-threshold value of the Filter
//          - Register 0xFE controls one-threshold value of the Filter
//          - Register 0xFF controls width value of the Filter    
//
////////////////////////////////////////////////////////////////////////////////////

module i2c_scp03 #(	
			       //-- I2C Device Address (0x1A)
			       parameter [6:0]      DEVICE_ADDRESS          = 7'h1A,	
			       //-- SE-QUBIP Parameters
			       parameter [0:0]      BARREL_SHIFTER		    = 0,
		           parameter [0:0]      ENABLE_MUL			    = 1,
		           parameter [0:0]      ENABLE_DIV			    = 1,
		           parameter [0:0]      ENABLE_FAST_MUL		    = 0,
		           parameter [0:0]      ENABLE_COMPRESSED	    = 1,
		           parameter [0:0]      ENABLE_IRQ			    = 1,
		           parameter [0:0]      TWO_CYCLE_COMPARE	    = 1,
		           parameter [0:0]      TWO_CYCLE_ALU		    = 1,
		           parameter integer    MEM_WORDS			    = 65536,
		           parameter [31:0]     PROGADDR_RESET		    = 32'h0000_0000,
		           parameter [31:0]     PROGADDR_IRQ			= 32'h0000_0060,
		           parameter [31:0]     PERIPHERALS_BASE_ADDR	= 32'h0100_0000,
		           parameter [31:0]     SLH_KECCAK_BASE_ADDR	= 32'h0200_0000,
		           parameter [31:0]     SLH_SHA256_BASE_ADDR	= 32'h0400_0000,
		           parameter [31:0]     SLH_SHA512_BASE_ADDR	= 32'h0800_0000,
		           parameter [0:0]      IMP_SHA2				= 1,
		           parameter [0:0]      IMP_SHA3				= 1,
		           parameter [0:0]      IMP_EDDSA				= 1,
		           parameter [0:0]      IMP_X25519			    = 1,
		           parameter [0:0]      IMP_TRNG				= 1,
		           parameter [0:0]      IMP_AES				    = 1,
		           parameter [0:0]      IMP_MLKEM				= 1,
		           parameter [0:0]      IMP_MLDSA				= 1,
		           parameter [0:0]      IMP_SLHDSA			    = 1,
		           parameter integer    TRNG_SIZE               = 32768,
		           parameter [9:0]      IMP_CLK_FREQ            = 100,
                   //-- SCP-03 Parameters
                   parameter [1:0]      SCP03_AES_LEN           = 2'b1,
                   parameter [255:0]    SCP03_KEY_ENC           = 256'h000102030405060708090A0B0C0D0E0F_1011121314151617_18191A1B1C1D1E1F,
                   parameter [255:0]    SCP03_KEY_MAC           = 256'h202122232425262728292A2B2C2D2E2F_3031323334353637_38393A3B3C3D3E3F
			       ) 
			       (
			        // -- I2C Interface --
			       input wire clk,                  //-- Clock Signal
			       input wire rst,		            //-- Active HIGH Reset
			       input wire SCL,		            //-- Serial Clock
			       input wire SDA,		            //-- Seria Data,
			       output reg output_control,
       
			       // -- PMOD SF3 Interface --
    		        output wire spi_sclk,
    		        output wire spi_csn,
    		        output wire spi_dq0_o,          //-- MOSI
    		        input  wire spi_dq1_i           //-- MISO
			       );
	
	
	//------------------------------------------------------------------
	//-- Wires & Registers
	//------------------------------------------------------------------
	
	reg start_detect;								//-- Detect Start
	reg start_resetter;								//-- Reset Start
	reg stop_detect;								//-- Detect Stop
	reg stop_resetter;								//-- Reset Stop
	
	wire start_rst;                                 //-- Reset Start Condition
	wire stop_rst;                                  //-- Reset Stop Condition
	
	reg [3:0] bit_counter;							//-- Bit Counter
	reg [7:0] input_shift;							//-- Data Received
	reg master_ack;									//-- Master ACK			
	reg [7:0] output_shift;							//-- Data Sent
	// reg output_control;								//-- Output Control
	reg [7:0] index_pointer;						//-- Register Index Pointer
	
	wire lsb_bit;									//-- Last 8th bit of Data
	wire ack_bit;									//-- 9th bit ACK 
	wire address_detect;							//-- Input address match the slave
	wire rw_bit; 									//-- 0 = write | 1 = read
	wire write_strobe; 								//-- WRITE state and finish one byte

    reg [7:0]   reg_00, reg_01, reg_02, reg_03, reg_04, reg_05, reg_06, reg_07,     //-- scp_data_in    (WR)
                reg_08, reg_09, reg_0A, reg_0B, reg_0C, reg_0D, reg_0E, reg_0F,     //-- scp_data_out   (RD)
                reg_10,                                                             //-- scp_cmd_in     (WR)
                reg_11;                                                             //-- scp_status     (RD)

	//------------------------------------------------------------------
    // SCP-03 Signals
    //------------------------------------------------------------------
    
    // TRNG Input
    reg [63:0]  scp03_trng_data = 64'hCAFECAFECAFECAFE; 
    wire        scp03_trng_data_valid;

    // SCP-03 Interfaces
    wire [63:0] scp_i2c_data_in;    // From reg_00..07
    wire [7:0]  scp_i2c_cmd_in;     // From reg_10
    reg         scp_i2c_wr_strobe;  // Trigger on write to reg_10
    
    wire [63:0] scp_data_out;       // To reg_08..0F
    wire        scp_data_out_valid; // Pulse when data available
    wire [7:0]  scp_status;         // To reg_11
    reg         scp_read_req;       // Pulse when Master reads reg_0F (end of block)
    
    // Decrypted Data to PicoSoC
    wire [7:0]  se_wr_addr ;        // Target Register ID
    wire [63:0] se_data_out;        // Decrypted Data
    wire        se_wr_valid;        // Pulse to write to PicoSoC

    // Data from PicoSoc
    wire [7:0]  se_rd_addr;
    wire [63:0] se_data_in;
    wire        se_rd_valid;

    scp03 #(
            .AES_LEN(SCP03_AES_LEN),
            .KEY_ENC(SCP03_KEY_ENC),
            .KEY_MAC(SCP03_KEY_MAC)
            ) 
            scp03 
            (
            .clk            (clk),
            .rst            (rst),
            .trng_in        (scp03_trng_data),
            .trng_valid     (scp03_trng_data_valid),

            // Host Interface (I2C Registers)
            .i2c_data_in    (scp_i2c_data_in),
            .i2c_cmd_in     (scp_i2c_cmd_in),
            .i2c_wr_strobe  (scp_i2c_wr_strobe),

            // Readback Interface
            .read_req       (scp_read_req),
            .data_out       (scp_data_out),
            .data_out_valid (scp_data_out_valid),

            // Status
            .status_reg     (scp_status),

            // Secure Element Interface
            .se_wr_addr     (se_wr_addr),
            .se_data_out    (se_data_out),
            .se_wr_valid    (se_wr_valid),
            .se_rd_addr     (se_rd_addr),
            .se_data_in     (se_data_in),
            .se_rd_valid    (se_rd_valid)
            );
	
    assign scp_i2c_data_in = {reg_00, reg_01, reg_02, reg_03, reg_04, reg_05, reg_06, reg_07};
    assign scp_i2c_cmd_in  = reg_10;

    always @(posedge clk) begin
        if (rst) begin
            scp_i2c_wr_strobe   <= 0;
            scp_read_req        <= 0;
        end 
        else begin
            // Trigger on write to reg_10
            scp_i2c_wr_strobe   <= (write_strobe && (index_pointer == 8'h10) && SCL_neg);
            // Trigger on read of reg_0F (End of block)
            scp_read_req        <= (state == READ && index_pointer == 8'h0F && SCL_neg && ack_bit);
        end
    end

	
	//------------------------------------------------------------------
    //-- PICOSOC
    //------------------------------------------------------------------

    reg     [63:0]  cmd_data_in;
	wire    [63:0]  cmd_data_out;
	wire    [63:0]  cmd_control;
	reg     [63:0]  AXI_RAM_WR;
	wire    [63:0]  AXI_RAM_RD;

    reg             scp03_trng_read;
    wire    [31:0]  scp03_trng_out;
    wire            scp03_trng_valid;
    reg             scp03_trng_done_0;
    reg             scp03_trng_done_1;
    reg             scp03_trng_done_2;

    always @(posedge clk) begin
        if (rst || scp03_trng_data_valid) begin
            scp03_trng_data         <= 64'hCAFECAFECAFECAFE;
            scp03_trng_read         <= 0;
            scp03_trng_done_0       <= 0;
            scp03_trng_done_1       <= 0;
            scp03_trng_done_2       <= 0;
        end
        else if (scp03_trng_valid && !scp03_trng_read && !scp03_trng_done_2) begin
            scp03_trng_read         <= 1;
        end
        else if (scp03_trng_read && !scp03_trng_done_0) begin
            scp03_trng_done_0       <= 1;
        end
        else if (scp03_trng_done_0 && !scp03_trng_done_1) begin
            scp03_trng_data[31:0]   <= scp03_trng_out;
            scp03_trng_read         <= 0;
            scp03_trng_done_0       <= 0;
            scp03_trng_done_1       <= 1;
        end
        else if (scp03_trng_done_0 && !scp03_trng_done_2) begin
            scp03_trng_data[63:32]  <= scp03_trng_out;
            scp03_trng_read         <= 0;
            scp03_trng_done_2       <= 1;
        end
    end

    reg se_wr_valid_0;
    always @(posedge clk) se_wr_valid_0 <= se_wr_valid;

    always @(posedge clk) begin
        if (rst) begin
            cmd_data_in <= 0;
            AXI_RAM_WR  <= 0;
        end
        else if (se_wr_valid && (se_wr_addr == 0))
            cmd_data_in <= se_data_out;
        else if (se_wr_valid && (se_wr_addr == 3))
            AXI_RAM_WR[63:32] <= se_data_out[63:32];
        else if (se_wr_valid_0 && (se_wr_addr == 3))
            AXI_RAM_WR[31:0] <= se_data_out[31:0];
    end
    
    picosoc #(
              .BARREL_SHIFTER       (BARREL_SHIFTER), 		
	          .ENABLE_MUL           (ENABLE_MUL), 			
	    	  .ENABLE_DIV           (ENABLE_DIV), 			
	    	  .ENABLE_FAST_MUL      (ENABLE_FAST_MUL), 	
	    	  .ENABLE_COMPRESSED    (ENABLE_COMPRESSED),	
	    	  .ENABLE_IRQ           (ENABLE_IRQ), 			
	    	  .TWO_CYCLE_COMPARE    (TWO_CYCLE_COMPARE),
	    	  .TWO_CYCLE_ALU        (TWO_CYCLE_ALU),    
              .MEM_WORDS            (MEM_WORDS),
	    	  .PROGADDR_RESET       (PROGADDR_RESET),
	    	  .PROGADDR_IRQ         (PROGADDR_IRQ),
	    	  .PERIPHERALS_BASE_ADDR(PERIPHERALS_BASE_ADDR),
	    	  .SLH_KECCAK_BASE_ADDR (SLH_KECCAK_BASE_ADDR),
	    	  .SLH_SHA256_BASE_ADDR (SLH_SHA256_BASE_ADDR),
	    	  .SLH_SHA512_BASE_ADDR (SLH_SHA512_BASE_ADDR),
	    	  .IMP_SHA2             (IMP_SHA2),  
	    	  .IMP_SHA3             (IMP_SHA3),  
	    	  .IMP_EDDSA            (IMP_EDDSA), 
	    	  .IMP_X25519           (IMP_X25519),
	    	  .IMP_TRNG             (IMP_TRNG),
	    	  .IMP_AES              (IMP_AES),   
	    	  .IMP_MLKEM            (IMP_MLKEM),
	    	  .IMP_MLDSA            (IMP_MLDSA),
	    	  .IMP_SLHDSA           (IMP_SLHDSA),
	    	  .TRNG_SIZE            (TRNG_SIZE),
	    	  .IMP_I2C              (1),
	    	  .IMP_CLK_FREQ         (IMP_CLK_FREQ)
	    	  )
        	  PICOSOC
	    	  (
               .clk                 (clk),
               .rst_n               (!rst && !AXI_RAM_WR[63]),
               .AXI_RAM_WEN_ADDR    (AXI_RAM_WR[63:32]),
               .AXI_RAM_WDATA       (AXI_RAM_WR[31:0]),
               .AXI_RAM_RDATA       (AXI_RAM_RD),
               .S_AXI_WVALID        (se_wr_valid),
               .S_AXI_WREADY        (se_wr_valid),
               .S_AXI_AWADDR        (se_wr_addr[1:0]),
               .S_AXI_ARVALID       (se_rd_valid),
               .S_AXI_ARREADY       (se_rd_valid),
               .S_AXI_ARADDR        (se_rd_addr[1:0]),
               .cmd_data_in         (cmd_data_in),
               .cmd_data_out        (cmd_data_out),
               .cmd_control         (cmd_control),
               .spi_sclk            (spi_sclk),   
               .spi_csn             (spi_csn),    
               .spi_dq0_o           (spi_dq0_o),  
               .spi_dq1_i           (spi_dq1_i),
               .scp03_trng_read     (scp03_trng_read),
               .scp03_trng_out      (scp03_trng_out),
               .scp03_trng_valid    (scp03_trng_valid)
               ); 
               
    assign se_data_in = (se_rd_addr == 0) ? cmd_data_in     :
                        (se_rd_addr == 1) ? cmd_data_out    :
                        (se_rd_addr == 2) ? cmd_control     :
                        (se_rd_addr == 3) ? AXI_RAM_WR      :
                        (se_rd_addr == 4) ? AXI_RAM_RD      : 0;
   
	
	
	//------------------------------------------------------------------
    //-- Synchronizers & Glitch Filters
    //------------------------------------------------------------------
	
	//-- Sample SDA & SCL
	reg SDA_sync_1;
    reg SCL_sync_1;
    reg SDA_sync_2;
    reg SCL_sync_2;
    reg SDA_sync_3;
    reg SCL_sync_3;
    
    always @(posedge clk) begin
       if (rst) begin
           SDA_sync_1   <= 1'b1;
           SCL_sync_1   <= 1'b1;
           SDA_sync_2   <= 1'b1;
           SCL_sync_2   <= 1'b1;
           SDA_sync_3   <= 1'b1;
           SCL_sync_3   <= 1'b1;
       end
       else begin
           SDA_sync_1   <= SDA;
           SCL_sync_1   <= SCL;
           SDA_sync_2   <= SDA_sync_1;
           SCL_sync_2   <= SCL_sync_1;
           SDA_sync_3   <= SDA_sync_2;
           SCL_sync_3   <= SCL_sync_2;
       end
    end
    
    //-- Shift-Register Glitch Filters
    localparam MAX_FILTER_WIDTH = 20;
    reg [MAX_FILTER_WIDTH-1:0] SDA_filter;
    reg [MAX_FILTER_WIDTH-1:0] SCL_filter;
    reg SDA_r;
    reg SCL_r;
    reg SDA_prev_r;
    reg SCL_prev_r;
    
    //-- Majority Logic
    localparam DEFAULT_FILTER_WIDTH           = 6;        //-- Compare 6 values 
    localparam DEFAULT_FILTER_ONE_THRESHOLD   = 5;        //-- If >=5 are 1s => 1
    localparam DEFAULT_FILTER_ZERO_THRESHOLD  = 1;        //-- If <=1 are 1s => 0
    
    reg [$clog2(MAX_FILTER_WIDTH):0] filter_width;
    reg [$clog2(MAX_FILTER_WIDTH):0] filter_one_threshold;
    reg [$clog2(MAX_FILTER_WIDTH):0] filter_zero_threshold;
    
    reg [MAX_FILTER_WIDTH-1:0] filter_select;
    reg [$clog2(MAX_FILTER_WIDTH):0] SDA_filter_sum;
    reg [$clog2(MAX_FILTER_WIDTH):0] SCL_filter_sum;
  
    integer i_sum;
    
    always @(*) begin        
        SDA_filter_sum = 0;
        SCL_filter_sum = 0;
        for (i_sum = 0; i_sum < MAX_FILTER_WIDTH; i_sum = i_sum + 1) begin
            if (i_sum < filter_width)
                filter_select[i_sum] = 1'b1; 
            else
                filter_select[i_sum] = 1'b0;
            SDA_filter_sum = SDA_filter_sum + (SDA_filter[i_sum] & filter_select[i_sum]); 
            SCL_filter_sum = SCL_filter_sum + (SCL_filter[i_sum] & filter_select[i_sum]);
        end  
    end
    
    //-- I2C Registers for Dynamic Filter Configuration
    reg [7:0] reg_FD;   //-- Zero Threshold
    reg [7:0] reg_FE;   //-- One Threshold
    reg [7:0] reg_FF;   //-- Filter Width
    
    //-- Filter Conditions
    always @(posedge clk) begin
        if (rst) begin
            SDA_filter  <= {MAX_FILTER_WIDTH{1'b1}};
            SCL_filter  <= {MAX_FILTER_WIDTH{1'b1}};
            SDA_r       <= 1'b1;
            SCL_r       <= 1'b1;
            SDA_prev_r  <= 1'b1;
            SCL_prev_r  <= 1'b1;
            //-- Filter Default Configuration
            filter_width            <= DEFAULT_FILTER_WIDTH;
            filter_one_threshold    <= DEFAULT_FILTER_ONE_THRESHOLD;
            filter_zero_threshold   <= DEFAULT_FILTER_ZERO_THRESHOLD;
        end
        else begin
            //-- Configure Filter Width          
            if (reg_FF > MAX_FILTER_WIDTH) 
                filter_width <= MAX_FILTER_WIDTH;
            else if (reg_FF < 3)
                filter_width <= 3;
            else 
                filter_width <= reg_FF;
            
            //-- Configure Filter One Threshold
            if (reg_FE > filter_width)
                filter_one_threshold <= filter_width;
            else if (reg_FE < {1'b0, filter_width[$clog2(MAX_FILTER_WIDTH):1]})
                filter_one_threshold <= filter_width;
            else 
                filter_one_threshold <= reg_FE;
            
            //-- Configure Filter Zero Threshold
            if (reg_FD > {1'b0, filter_width[$clog2(MAX_FILTER_WIDTH):1]})
                filter_zero_threshold <= 0;
            else 
                filter_zero_threshold <= reg_FD;
            
            //-- Shift Register
            SDA_filter <= {SDA_filter[MAX_FILTER_WIDTH-2:0], SDA_sync_3};
            SCL_filter <= {SCL_filter[MAX_FILTER_WIDTH-2:0], SCL_sync_3};
            
            //-- Filter Conditions
            if (SDA_filter_sum >= filter_one_threshold)
                SDA_r <= 1'b1;
            else if (SDA_filter_sum <= filter_zero_threshold)
                SDA_r <= 1'b0;
            else 
                SDA_r <= SDA_r; 

            if (SCL_filter_sum >= filter_one_threshold)
                SCL_r <= 1'b1;
            else if (SCL_filter_sum <= filter_zero_threshold)
                SCL_r <= 1'b0;
            else 
                SCL_r <= SCL_r; 
                
            SDA_prev_r <= SDA_r;
            SCL_prev_r <= SCL_r;
        end
    end
    
	
	//------------------------------------------------------------------
    //-- Detect SCL/SDA Transitions
    //------------------------------------------------------------------

	reg SDA_pos;
	reg SDA_neg;
	reg SCL_pos;
	reg SCL_neg;
	
	always @(posedge clk) begin
	   if (rst) begin
	       SDA_pos <= 1'b0;
           SDA_neg <= 1'b0;
           SCL_pos <= 1'b0;
           SCL_neg <= 1'b0;
	   end
	   else begin
           //-- SDA Posedge
           if (SDA_r && !SDA_prev_r) 
                SDA_pos <= 1'b1;
           else
                SDA_pos <= 1'b0;
                
           //-- SDA Negedge
           if (!SDA_r && SDA_prev_r) 
                SDA_neg <= 1'b1;
           else
                SDA_neg <= 1'b0;
           
           //-- SCL Posedge
           if (SCL_r && !SCL_prev_r) 
                SCL_pos <= 1'b1;
           else
                SCL_pos <= 1'b0;
                
           //-- SCL Negedge
           if (!SCL_r && SCL_prev_r) 
                SCL_neg <= 1'b1;
           else
                SCL_neg <= 1'b0;
	   end
	end
	
	
	//------------------------------------------------------------------
	//-- Detect Start/Stop Condition
	//------------------------------------------------------------------
	
	assign start_rst = rst | start_resetter;
	assign stop_rst  = rst | stop_resetter;
	
	//-- Start Condition
	always @(posedge clk) begin // @(posedge start_rst or negedge SDA) begin
		if (start_rst)
            start_detect <= 1'b0;
        else if (SDA_neg)
			start_detect <= SCL_r;
	end
	
	//-- Reset Start
	always @(posedge clk) begin // @(posedge rst or posedge SCL) begin
		if (rst)
            start_resetter <= 1'b0;
        else if (SCL_pos)
            start_resetter <= start_detect;	
	end
	
	//-- Stop Condition
	always @(posedge clk) begin // @(posedge stop_rst or posedge SDA) begin   
		if (stop_rst)
            stop_detect <= 1'b0;
        else if (SDA_pos)
            stop_detect <= SCL_r;		
	end
	
	//-- Reset Stop
	always @(posedge clk) begin // @(posedge rst or posedge SCL) begin 
        if (rst)
            stop_resetter <= 1'b0;
        else if (SCL_pos)
            stop_resetter <= stop_detect;	
	end
	
	
	//------------------------------------------------------------------
	//-- Register Data
	//------------------------------------------------------------------
	
	assign lsb_bit = (bit_counter == 4'h7) && !start_detect;
	assign ack_bit = (bit_counter == 4'h8) && !start_detect;
	
	//-- Reset bit counter after Start or ACK
	always @(posedge clk) begin // @(negedge SCL) begin
	   //-- Counter to 9 (0 to 8) -> 8 bits + ACK
       if (SCL_neg && (ack_bit || start_detect))
           bit_counter <= 4'h0;
       else if (SCL_neg)
           bit_counter <= bit_counter + 1; 
	end
	
	//-- At posedge SCL the Data is stable
	always @(posedge clk) if (SCL_pos && !ack_bit) input_shift <= {input_shift[6:0], SDA_r};
	
	//-- Address & RW
	assign address_detect 	= (input_shift[7:1] == DEVICE_ADDRESS);
	assign rw_bit			= input_shift[0];
	
	
	//------------------------------------------------------------------
	//-- Slave-to-Master Transfer
	//------------------------------------------------------------------
	
	always @ (posedge clk) if (SCL_pos && ack_bit) master_ack <= ~SDA_r;
	
	
	//------------------------------------------------------------------
	//-- FSM States
    //------------------------------------------------------------------
	
	reg [2:0] state;
	
	localparam [2:0] IDLE 		= 0;
	localparam [2:0] DEV_ADDR	= 1;
	localparam [2:0] READ		= 2;
	localparam [2:0] IDX_PTR 	= 3;
	localparam [2:0] WRITE 		= 4;
	
	assign write_strobe = (state == WRITE) && ack_bit;
	
	always @(posedge clk) begin
		if (rst)
			state <= IDLE;
		else if (start_detect)
			state <= DEV_ADDR;
		
		else if (SCL_neg && ack_bit) begin
			case (state)
			
            IDLE: state <= IDLE;

            DEV_ADDR: begin
				//-- Address do not match
                if (!address_detect)
                    state <= IDLE;
				//-- Address match and operation is read
                else if (rw_bit)
                    state <= READ;
                //-- Address match and operation is write
				else
                    state <= IDX_PTR;
			end
			
            READ: begin
                //-- Get the master ACK
				if (master_ack)
                    state <= READ;
                //-- If no master ACK then ready to STOP
				else
                    state <= IDLE;
			end
			
			//-- Get the index and ready to write 
            IDX_PTR: state <= WRITE;

            WRITE: state <= WRITE;
			
            endcase
        end 
        
        //-- Added
        else if (/*SCL_neg &&*/ stop_detect) begin
            state <= IDLE;
        end
        //--	
	end
	
	
	//------------------------------------------------------------------
	//-- Register Transfers
    //------------------------------------------------------------------
	
	//-- Control Register Index
	always @(posedge clk) begin
		if (rst)
			index_pointer <= 8'h00;
		/*else if (SCL_neg && stop_detect)
			index_pointer <= 8'h00;*/
		//-- At the 9th bit (ACK), the input_shift has one byte
		else if (SCL_neg && ack_bit) begin
			//-- Get the inner-register index
			if (state == IDX_PTR)
				index_pointer <= input_shift;
			//-- Ready for next RW: bulk transfer of a block of data 
			else
				index_pointer <= index_pointer + 8'h01;
		end
	end
	
	//-- Control Register Write
	always @(posedge clk) begin
		if (rst) begin
			reg_00 <= 8'h00;
			reg_01 <= 8'h00;
			reg_02 <= 8'h00;
			reg_03 <= 8'h00;
			reg_04 <= 8'h00;
			reg_05 <= 8'h00;
			reg_06 <= 8'h00;
			reg_07 <= 8'h00;
			reg_08 <= 8'h00;
            reg_09 <= 8'h00;
            reg_0A <= 8'h00;
            reg_0B <= 8'h00;
            reg_0C <= 8'h00;
            reg_0D <= 8'h00;
            reg_0E <= 8'h00;
            reg_0F <= 8'h00;
            reg_10 <= 8'h00;
            reg_11 <= 8'h00;
            //-- Filter Configuration Registers
            reg_FD <= DEFAULT_FILTER_ZERO_THRESHOLD;
            reg_FE <= DEFAULT_FILTER_ONE_THRESHOLD;
            reg_FF <= DEFAULT_FILTER_WIDTH;
		end
		//-- Moment when input_shift has received one byte of Data
		else if (SCL_neg && write_strobe) begin
			case (index_pointer)
			8'h00: reg_00 <= input_shift;
	        8'h01: reg_01 <= input_shift;
	        8'h02: reg_02 <= input_shift;
	        8'h03: reg_03 <= input_shift;
	        8'h04: reg_04 <= input_shift;
            8'h05: reg_05 <= input_shift;
            8'h06: reg_06 <= input_shift;
            8'h07: reg_07 <= input_shift;
            8'h10: reg_10 <= input_shift;
            //-- Filter Configuration Registers
            8'hFD: reg_FD <= input_shift;
            8'hFE: reg_FE <= input_shift;
            8'hFF: reg_FF <= input_shift;
	        endcase
	    end
	    //-- SCP-03 Output
	    else begin
            if (scp_data_out_valid) {reg_08, reg_09, reg_0A, reg_0B, reg_0C, reg_0D, reg_0E, reg_0F}    <= scp_data_out;
            reg_11                                                                                      <= scp_status;
        end
	end
	
	//-- Control Register Read
	always @(posedge clk) begin   
		//-- Data must be loaded before the ACK bit
		if (SCL_neg && lsb_bit) begin
			case (index_pointer)
            8'h00: output_shift <= reg_00;
            8'h01: output_shift <= reg_01;
            8'h02: output_shift <= reg_02;
            8'h03: output_shift <= reg_03;
            8'h04: output_shift <= reg_04;
            8'h05: output_shift <= reg_05;
            8'h06: output_shift <= reg_06;
            8'h07: output_shift <= reg_07;
            8'h08: output_shift <= reg_08;
            8'h09: output_shift <= reg_09;
            8'h0A: output_shift <= reg_0A;
            8'h0B: output_shift <= reg_0B;
            8'h0C: output_shift <= reg_0C;
            8'h0D: output_shift <= reg_0D;
            8'h0E: output_shift <= reg_0E;
            8'h0F: output_shift <= reg_0F;
            8'h10: output_shift <= reg_10;
            8'h11: output_shift <= reg_11;
            //-- Filter Configuration Registers
            8'hFD: output_shift <= reg_FD;
            8'hFE: output_shift <= reg_FE;
            8'hFF: output_shift <= reg_FF;
			default: output_shift <= 8'h00;
			endcase
		end
		//-- Output Shift Register
		else if (SCL_neg)
			output_shift <= {output_shift[6:0], 1'b0};		
	end
	
	
	//------------------------------------------------------------------
	//-- Output Driver
    //------------------------------------------------------------------
	
	// assign SDA = (output_control) ? 1'bZ : 1'b0; 
	// assign SCL = 1'bZ;
	
	always @(posedge clk) begin   	
		if (rst)
			output_control <= 1'b1;
			
		//-- Added
		else if (stop_detect || state == IDLE)
		    output_control <= 1'b1;
		//--
		
		else if (SCL_neg && start_detect)
			output_control <= 1'b1;
		//-- Slave ACK
		else if (SCL_neg && lsb_bit)
			//-- If Address match, or master writting index pointer, or master writting Data -> generate ACK
			output_control <= !( ((state == DEV_ADDR) && address_detect) || (state == IDX_PTR) || (state == WRITE) ); 			
		//-- Deliver the first bit of the next slave-to-master transfer, if applicable.
		else if (SCL_neg && ack_bit) begin
			//-- For the Restart and send the address generate ACK -> 1'b0
			//-- For the read and master ack both slave is pull down
			if ( ((state == READ) && master_ack) || ((state == DEV_ADDR) && address_detect && rw_bit ) )
				output_control <= output_shift[7];
			else
				output_control <= 1'b1;
		end
		//-- For read send output shift to SDA
		else if (SCL_neg && state == READ)
			output_control <= output_shift[7];
		else if (SCL_neg)
			output_control <= 1'b1;
	end
	
endmodule
