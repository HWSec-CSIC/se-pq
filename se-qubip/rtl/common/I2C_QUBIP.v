/**
  * @file  I2C_QUBIP.v
  * @brief I2C Slave, includes Synchronizers and a Glith Filter
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero and Pau Ortega Castro
// 
// Create Date: 09/09/2024
// Design Name: I2C_QUBIP.v
// Module Name: I2C_QUBIP
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

module I2C_QUBIP #(	
				   //-- I2C Device Address (0x1A)
				   parameter [6:0] DEVICE_ADDRESS = 7'h1A,	
				   //-- SE-QUBIP IP Cores
				   parameter IMP_SHA3             = 1,      //-- Implement SHA-3
                   parameter IMP_SHA2             = 1,      //-- Implement SHA-2
                   parameter IMP_EDDSA            = 1,      //-- Implement EDDSA
                   parameter IMP_X25519           = 1,      //-- Implement X25519
                   parameter IMP_TRNG             = 1,      //-- Implement TRNG
                   parameter IMP_AES              = 1,      //-- Implement AES
                   parameter IMP_MLKEM            = 1       //-- Implement MLKEM
				   ) 
				   (
					input wire clk,           //-- Clock Signal
					input wire rst,		      //-- Active HIGH Reset
					input wire SCL,		      //-- Serial Clock
					input wire SDA,		      //-- Seria Data,
					output reg output_control
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
	
	//-- SE-QUBIP Wires & Registers (Slave Registers)
	wire i_rst;
	wire [63:0] i_data_in;
	wire [63:0] i_add;
	wire [63:0] i_control;
	wire [63:0] o_data_out;
	wire [1:0] o_end_op;

	reg [7:0] reg_00, reg_01, reg_02, reg_03, reg_04, reg_05, reg_06,   reg_07,     //-- i_data_in   
	          reg_08, reg_09, reg_0A, reg_0B, reg_0C, reg_0D, reg_0E,   reg_0F,     //-- i_add       
	          reg_10, reg_11, reg_12, reg_13, reg_14, reg_15, reg_16,   reg_17,     //-- i_control   
	          reg_18, reg_19, reg_1A, reg_1B, reg_1C, reg_1D, reg_1E,   reg_1F,     //-- o_data_out  
	        /*reg_20, reg_21, reg_22, reg_23, reg_24, reg_25, reg_26,*/ reg_27;     //-- o_end_op -> reg_27 for compatibility with AXI-4 Drivers
    
    assign i_rst        = !rst;
    assign i_data_in    = {reg_00, reg_01, reg_02, reg_03, reg_04, reg_05, reg_06, reg_07};
    assign i_add        = {reg_08, reg_09, reg_0A, reg_0B, reg_0C, reg_0D, reg_0E, reg_0F};
    assign i_control    = {reg_10, reg_11, reg_12, reg_13, reg_14, reg_15, reg_16, reg_17};
	
	
	//------------------------------------------------------------------
    //-- SE-QUBIP
    //------------------------------------------------------------------
    
    SE_QUBIP #(
               .IMP_SHA3(IMP_SHA3),
               .IMP_SHA2(IMP_SHA2),
               .IMP_EDDSA(IMP_EDDSA),
               .IMP_X25519(IMP_X25519),
               .IMP_TRNG(IMP_TRNG),
               .IMP_AES(IMP_AES),
               .IMP_MLKEM(IMP_MLKEM)
               )
               
               SE_QUBIP
               
               (
               .i_clk(clk),
               .i_rst(i_rst),
               .i_data_in(i_data_in),
               .i_add(i_add),
               .i_control(i_control),
               .o_data_out(o_data_out),
               .o_end_op(o_end_op)
               );
	
	
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
    localparam DEFAULT_FILTER_ZERO_THRESHOLD  = 1;        //-- If <=1  are 1s => 0
    
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
            reg_12 <= 8'h00;
            reg_13 <= 8'h00;
            reg_14 <= 8'h00;
            reg_15 <= 8'h00;
            reg_16 <= 8'h00;
            reg_17 <= 8'h00;
            reg_18 <= 8'h00;
            reg_19 <= 8'h00;
            reg_1A <= 8'h00;
            reg_1B <= 8'h00;
            reg_1C <= 8'h00;
            reg_1D <= 8'h00;
            reg_1E <= 8'h00;
            reg_1F <= 8'h00;
            reg_27 <= 8'h00;
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
            8'h08: reg_08 <= input_shift;
            8'h09: reg_09 <= input_shift;
            8'h0A: reg_0A <= input_shift;
            8'h0B: reg_0B <= input_shift;
            8'h0C: reg_0C <= input_shift;
            8'h0D: reg_0D <= input_shift;
            8'h0E: reg_0E <= input_shift;
            8'h0F: reg_0F <= input_shift;
            8'h10: reg_10 <= input_shift;
            8'h11: reg_11 <= input_shift;
            8'h12: reg_12 <= input_shift;
            8'h13: reg_13 <= input_shift;
            8'h14: reg_14 <= input_shift;
            8'h15: reg_15 <= input_shift;
            8'h16: reg_16 <= input_shift;
            8'h17: reg_17 <= input_shift;
            //-- Filter Configuration Registers
            8'hFD: reg_FD <= input_shift;
            8'hFE: reg_FE <= input_shift;
            8'hFF: reg_FF <= input_shift;
	        endcase
	    end
	    //-- SE-QUBIP Output
	    else begin
	       {reg_18, reg_19, reg_1A, reg_1B, reg_1C, reg_1D, reg_1E, reg_1F} <= o_data_out;
           reg_27                                                           <= {6'b0, o_end_op};
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
            8'h00: output_shift <= reg_00;
            8'h11: output_shift <= reg_11;
            8'h12: output_shift <= reg_12;
            8'h13: output_shift <= reg_13;
            8'h14: output_shift <= reg_14;
            8'h15: output_shift <= reg_15;
            8'h16: output_shift <= reg_16;
            8'h17: output_shift <= reg_17;
            8'h18: output_shift <= reg_18;
            8'h19: output_shift <= reg_19;
            8'h1A: output_shift <= reg_1A;
            8'h1B: output_shift <= reg_1B;
            8'h1C: output_shift <= reg_1C;
            8'h1D: output_shift <= reg_1D;
            8'h1E: output_shift <= reg_1E;
            8'h1F: output_shift <= reg_1F;
            //-- End of Operation
            8'h27: output_shift <= reg_27;
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
