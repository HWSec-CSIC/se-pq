`timescale 1ns / 1ps

module FIFO_IN_2 #(
    parameter FIFO_DEPTH = 512,     // Number of 64-bit words in the FIFO
    parameter INPUT_WIDTH = 64,
    parameter OUTPUT_WIDTH = 16,
    parameter RELATION = INPUT_WIDTH / OUTPUT_WIDTH,
    parameter CLOG = clog2(RELATION),
    parameter ADDR_WIDTH = 8        // Address width: log2(FIFO_DEPTH)
    )(
    input wire clk,               // Clock signal
    input wire rst,               // Reset signal (active low)
    input wire write_en,           // write enable
    input wire [INPUT_WIDTH-1:0] din,        // 64-bit input data
    input wire [7:0]  cin,        
    input wire [15:0] in_addr, // Input address (byte address)
    input wire enable,
    output reg [OUTPUT_WIDTH-1:0] dout,        // 8-bit output data
    output reg [7:0] cout,
    output reg read_en,           // Read enable
    output wire full,              // FIFO full flag
    output wire empty,             // FIFO empty flag
    output reg [15:0] read_addr,  // External read address (byte address)
    output wire action
);

    reg [INPUT_WIDTH-1:0]   mem [0:FIFO_DEPTH-1];   // FIFO memory (64-bit words)
    reg [OUTPUT_WIDTH-1:0] cmem [0:FIFO_DEPTH-1];   // FIFO memory (64-bit words)
    reg [ADDR_WIDTH-1:0] write_ptr_mem;             // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] write_ptr_ctl;             // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] read_ptr;                  // Read pointer (64-bit words)
    reg [CLOG-1:0] byte_offset;                     // Offset within 64-bit word (0-7)
    
    reg [ADDR_WIDTH-1:0] write_count;               // Write counter (64-bit words)
    
    assign full     = (write_count == FIFO_DEPTH)   ? 1 : 0;
    assign empty    = (write_count == 0)            ? 1 : 0; 
    
    reg [15:0] prev_in_addr;                        // Tracks previous input address
    reg [7:0] prev_cin;
    
    wire add_changed;
    assign add_changed = (in_addr != prev_in_addr) ? 1 : 0;
    wire control_changed;
    assign control_changed = (cin != prev_cin) ? 1 : 0;
    
    always @(posedge clk) prev_in_addr <= in_addr;
    always @(posedge clk) prev_cin     <= cin;
    
    reg action_reg;
    assign action = action_reg;
    
    // ----------------- //
    // --- FSM write --- //
    // ----------------- //
    
    //--*** STATE declaration **--//
	localparam IDLE_WRT            = 3'b000; 
	localparam OPERATION_WRT       = 3'b001; 
	localparam ADD_CHANGE          = 3'b010;
	localparam CONTROL_CHANGE      = 3'b011;
	localparam STANDBY_CONTROL     = 3'b100;
    
    //--*** STATE register **--//
	reg [2:0] current_state_wrt;
	reg [2:0] next_state_wrt;
	
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst)    
			     current_state_wrt <= IDLE_WRT;
			else
			     current_state_wrt <= next_state_wrt;
		end
		
    //--*** STATE Transition **--//
	always @*
		begin
			case (current_state_wrt)
				IDLE_WRT:
				   if (write_en)
				        next_state_wrt = OPERATION_WRT;
				   else
				        next_state_wrt = IDLE_WRT;
				OPERATION_WRT:
				   if (add_changed & in_addr != 0)
				        next_state_wrt = ADD_CHANGE;
				   else if (control_changed)
				        next_state_wrt = CONTROL_CHANGE;
				   else if (!write_en)
				        next_state_wrt = IDLE_WRT;
				   else
				        next_state_wrt = OPERATION_WRT;
				ADD_CHANGE:
				        next_state_wrt = OPERATION_WRT;
				CONTROL_CHANGE:
				        next_state_wrt = STANDBY_CONTROL;
				STANDBY_CONTROL:
				    if (add_changed)
				        next_state_wrt = OPERATION_WRT;
				    else
				        next_state_wrt = STANDBY_CONTROL;
				default:
					   next_state_wrt = IDLE_WRT;
			endcase 		
		end 
		
		// -- State Operation -- //
		always @(posedge clk) begin
            if (current_state_wrt == IDLE_WRT) begin
                write_ptr_mem <= 0;
                write_ptr_ctl <= 0;
            end 
            else if (current_state_wrt == ADD_CHANGE | current_state_wrt == CONTROL_CHANGE) begin
                write_ptr_mem <= write_ptr_mem + 1;
                write_ptr_ctl <= write_ptr_ctl + 1;
            end
            else begin
                write_ptr_mem <= write_ptr_mem;
                write_ptr_ctl <= write_ptr_ctl;
            end
        end
        
        always @(posedge clk) begin
            if (current_state_wrt == IDLE_WRT) begin
                mem[write_ptr_mem] <= 0;
                mem[write_ptr_mem] <= 0;
            end 
            else if ((current_state_wrt == OPERATION_WRT | current_state_wrt == STANDBY_CONTROL) & !control_changed) begin
                mem[write_ptr_mem]  <= din;
                cmem[write_ptr_ctl] <= cin;
            end
            else begin
                mem[write_ptr_mem]  <= mem[write_ptr_mem];
                cmem[write_ptr_ctl] <= cmem[write_ptr_ctl];
            end
        
        end
        
        
    always @(posedge clk) begin
        if(!rst) action_reg <= 0;
        else begin
            if(current_state_wrt == OPERATION_WRT)     action_reg <= 1;
            else if(current_state_wrt == IDLE_WRT)     action_reg <= 0;
            else                                       action_reg <= action_reg;
        end 
    end
        
        
    // ----------------- //
    // --- FSM read --- //
    // ----------------- //
    
    //--*** STATE declaration **--//
	localparam IDLE_RD             = 3'b000; 
	localparam OPERATION_RD        = 3'b001; 
	localparam UPDATE_BYTE         = 3'b010;
	localparam UPDATE_READ         = 3'b011;
	localparam LAST_ONE            = 3'b100;
    
    //--*** STATE register **--//
	reg [2:0] current_state_rd;
	reg [2:0] next_state_rd;
    
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst)    
			     current_state_rd <= IDLE_RD;
			else
			     current_state_rd <= next_state_rd;
		end
	
	wire end_byte;
	assign end_byte = (byte_offset == RELATION - 1) ? 1 : 0;
	
	reg ns; 
	always @(posedge clk) begin
	   if(!rst)    ns <= 0;
	   else        ns <= ns + 1;
	end
		
    //--*** STATE Transition **--//
	always @*
		begin
			case (current_state_rd)
				IDLE_RD:
				   if (!empty & enable)
				        next_state_rd = OPERATION_RD;
				   else
				        next_state_rd = IDLE_RD;
				OPERATION_RD:
				   if (!empty)
				        next_state_rd = UPDATE_BYTE;
				   else
				        next_state_rd = OPERATION_RD;
				UPDATE_BYTE:
				    if (end_byte)
				        next_state_rd = UPDATE_READ;
				    else
				        next_state_rd = UPDATE_BYTE;
				UPDATE_READ:
				    if(!write_en)
				        next_state_rd = LAST_ONE;
				    else
				        next_state_rd = OPERATION_RD;
				LAST_ONE: 
				        next_state_rd = IDLE_RD;
				default:
					   next_state_rd  = IDLE_RD;
			endcase 		
		end 
		
    // -- State Operation -- //
    always @(posedge clk) begin
                if (current_state_rd == IDLE_RD | current_state_rd == OPERATION_RD | 
                    current_state_rd == UPDATE_READ & ns)                               byte_offset <= 0;
        else    if (current_state_rd == UPDATE_BYTE & ns)                               byte_offset <= byte_offset + 1;
        else                                                                            byte_offset <= byte_offset;
    end
    
    always @(posedge clk) begin
                if (current_state_rd == IDLE_RD)                                        read_ptr <= 0;
        else    if (current_state_rd == UPDATE_READ & ns)                               read_ptr <= read_ptr + 1;
        else                                                                            read_ptr <= read_ptr;
    end
    
    always @(posedge clk) begin
        if(current_state_rd == IDLE_RD)                 read_en <= 0;
        else if(current_state_rd == OPERATION_RD)       read_en <= 1;
        else                                            read_en <= read_en;   
    end
        
    always @(posedge clk) begin
        if(!rst) begin
            dout <= 0;
            cout <= 0;
        end
        else if (current_state_rd == IDLE_RD) begin
            dout <= dout;
            cout <= cout;
        end 
        /*
        else if(empty) begin
            dout <= dout; // Extract 8-bit segment
            cout <= cout; 
        end
        */
        else begin
            dout <= mem[read_ptr][OUTPUT_WIDTH*byte_offset +: OUTPUT_WIDTH]; // Extract 8-bit segment
            cout <= cmem[read_ptr]; 
        end
    end
		
		
	wire cond_rd;
	wire cond_wr;
	assign cond_rd = (current_state_rd == UPDATE_READ) ? 1 : 0;
	assign cond_wr = (current_state_wrt == ADD_CHANGE | current_state_wrt == CONTROL_CHANGE) ? 1 : 0;	
    // write-count operation
     always @(posedge clk) begin
        
        if (!rst)                           write_count <= 0;
        else begin
                    if(cond_wr & !cond_rd)  write_count <= write_count + 1;
            else    if(!cond_wr & cond_rd)  write_count <= write_count - 1;
            else                            write_count <= write_count;
        end

    end
    
    // read_addr
    reg [7:0] prev_cout;
    wire cout_changed;
    assign cout_changed = (prev_cout != cout && prev_cout != 8'h00) ? 1 : 0; // I avoid the first one
    always @(posedge clk) prev_cout <= cout;
    
    always @(posedge clk) begin
                if (current_state_rd == IDLE_RD | cout_changed)                         read_addr <= 0;
        else    if ((   current_state_rd == UPDATE_READ | 
                        current_state_rd == UPDATE_BYTE) & ns)                          read_addr <= read_addr + 1;
        else                                                                            read_addr <= read_addr;
    end
    
    // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule


module FIFO_IN #(
    parameter FIFO_DEPTH = 512,     // Number of 64-bit words in the FIFO
    parameter INPUT_WIDTH = 64,
    parameter OUTPUT_WIDTH = 16,
    parameter RELATION = INPUT_WIDTH / OUTPUT_WIDTH,
    parameter CLOG = clog2(RELATION),
    parameter ADDR_WIDTH = 8        // Address width: log2(FIFO_DEPTH)
    )(
    input wire clk,               // Clock signal
    input wire rst,               // Reset signal (active low)
    input wire write_en,           // write enable
    input wire [INPUT_WIDTH-1:0] din,        // 64-bit input data
    input wire [7:0]  cin,        
    input wire [15:0] in_addr, // Input address (byte address)
    input wire enable,
    output reg [OUTPUT_WIDTH-1:0] dout,        // 8-bit output data
    output reg [7:0] cout,
    output reg read_en,           // Read enable
    output wire full,              // FIFO full flag
    output wire empty,             // FIFO empty flag
    output reg [15:0] read_addr, // External read address (byte address)
    output wire action
);

    reg [INPUT_WIDTH-1:0]   mem [0:FIFO_DEPTH-1];   // FIFO memory (64-bit words)
    reg [OUTPUT_WIDTH-1:0] cmem [0:FIFO_DEPTH-1];   // FIFO memory (64-bit words)
    reg [ADDR_WIDTH-1:0] write_ptr_mem;             // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] write_ptr_ctl;             // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] write_count;               // Write count (tracks filled words)
    reg [ADDR_WIDTH-1:0] read_ptr;                  // Read pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] read_ptr_reg;              // Read pointer (64-bit words)
    reg [CLOG-1:0] byte_offset;                     // Offset within 64-bit word (0-7)
    reg [CLOG-1:0] byte_offset_reg;                 // Offset within 64-bit word (0-7)
    reg [15:0] prev_in_addr;                        // Tracks previous input address
    reg [7:0] prev_cin;
    
    assign full     = (write_count == FIFO_DEPTH) ? 1 : 0;
    assign empty    = (write_count == 0)          ? 1 : 0; 
    
    reg action_reg;
    assign action = action_reg;
    
    wire add_changed;
    assign add_changed = (in_addr != prev_in_addr && in_addr != 0 && action_reg) ? 1 : 0;
    wire control_changed;
    assign control_changed = (cin != prev_cin && in_addr != 0 && action_reg) ? 1 : 0;
    
    wire ng_signal;
    negedge_detector NG (.clk(clk), .rst(rst), .signal_in(write_en), .negedge_detected(ng_signal)); // to do the last
    
    // ---- WRITING PROCESS ---- //
    always @(posedge clk) begin
        if(!rst) action_reg <= 0;
        else begin
            if(write_en | !empty)                   action_reg <= 1;
            else if(!write_en & control_changed)    action_reg <= 1;
            else                                    action_reg <= 0;
        end 
    end
    
    // Write operation triggered by input address change
    always @(posedge clk) begin
        if (!rst) begin
            write_ptr_mem <= 0;
            write_ptr_ctl <= 0;
        end 
        else if (write_en && !full) begin
            if(!control_changed) mem[write_ptr_mem]  <= din; // Store data when address changes
            if(!control_changed) cmem[write_ptr_ctl] <= cin;
            if(add_changed  | control_changed) begin
                write_ptr_mem <= write_ptr_mem + 1;
            end
            if(add_changed | control_changed) begin
                write_ptr_ctl <= write_ptr_ctl + 1;
            end
        end
        
        prev_in_addr    <= in_addr;
        prev_cin        <= cin;
    end
    
    wire cond; 
    assign cond = ((add_changed | control_changed) & write_en) | ng_signal;
    
    // write-count operation
     always @(posedge clk) begin
        
        if (!rst)                                               write_count <= 0;
        else begin
            if(empty)
                if(action_reg & cond)                           write_count <= write_count + 1;
                else                                            write_count <= write_count;
            else begin
                if (byte_offset == RELATION-1) begin
                    if   (action_reg & cond && !full)           write_count <= write_count;
                    else                                        write_count <= write_count - 1;
                end
                else begin
                    if   (action_reg & cond && !full)           write_count <= write_count + 1;
                    else                                        write_count <= write_count;
                end
            end
        end
    end
    
    
    // ---- READING PROCESS ---- //  
    reg [7:0] prev_cout;
    wire cout_changed;
    assign cout_changed = (prev_cout != cout) ? 1 : 0;
    reg [15:0] read_addr_reg;
    
    // Read operation
    always @(negedge clk) begin
        if (!rst) begin
            read_ptr <= 0;
            byte_offset <= 0;
            read_addr_reg <= 0;
        end 
        else if (!empty & enable & cout != 8'h0) begin
            // read_addr <= (read_ptr << CLOG) + byte_offset; // Calculate external read address
            
            if (byte_offset == RELATION-1) begin
                    byte_offset <= 0;
                    read_ptr <= read_ptr + 1;
                    read_addr_reg <= read_addr_reg + 1;
            end else begin
                 if(cout_changed)   begin 
                    byte_offset <= 0;
                    read_ptr <= read_ptr;
                    read_addr_reg <= 0;
                 end
                 else begin
                    byte_offset <= byte_offset + 1;
                    read_addr_reg <= read_addr_reg + 1;
                    read_ptr <= read_ptr;
                 end
            end
            
        end 
        else begin
            read_ptr <= read_ptr;
            byte_offset <= byte_offset;
            read_addr_reg <= read_addr_reg;
        end
        
         if (!rst) begin
            read_en <= 1'b0;
        end 
        else if (!empty & enable) begin
            read_en <= 1'b1;
        end 
        else begin
            read_en <= 1'b0;
        end
        
    end
    
    always @(posedge clk) begin
        
        if (!rst) begin
            dout <= 8'b0;
            cout <= 8'b0;
            // read_en <= 1'b0;
        end 
        else if (!empty & enable) begin
            // read_en <= 1'b1;
            dout <= mem[read_ptr][OUTPUT_WIDTH*byte_offset +: OUTPUT_WIDTH]; // Extract 8-bit segment
            cout <= cmem[read_ptr]; 
        end 
        else begin
            dout <= dout;
            cout <= cout;
            // read_en <= 1'b0;
        end
        
        prev_cout <= cout;
        read_addr <= read_addr_reg;
        byte_offset_reg <= byte_offset; 
        read_ptr_reg <= read_ptr; 
    end
    
      // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction
    
endmodule

module fifo_64to8 #(
    parameter FIFO_DEPTH = 128,     // Number of 64-bit words in the FIFO
    parameter ADDR_WIDTH = 8        // Address width: log2(FIFO_DEPTH)
    )(
    input wire clk,               // Clock signal
    input wire rst,               // Reset signal (active low)
    input wire write_en,           // write enable
    input wire [63:0] din,        // 64-bit input data
    input wire [7:0]  cin,        
    input wire [15:0] in_addr, // Input address (byte address)
    output reg [7:0] dout,        // 8-bit output data
    output reg [7:0] cout,
    output reg read_en,           // Read enable
    output wire full,              // FIFO full flag
    output wire empty,             // FIFO empty flag
    output reg [15:0] read_addr // External read address (byte address)
);

    reg [63:0] mem[0:FIFO_DEPTH-1]; // FIFO memory (64-bit words)
    reg [7:0] cmem[0:FIFO_DEPTH-1]; // FIFO memory (64-bit words)
    reg [ADDR_WIDTH-1:0] write_ptr_mem; // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] write_ptr_ctl; // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] write_count; // Write count (tracks filled words)
    reg [ADDR_WIDTH-1:0] read_ptr;  // Read pointer (64-bit words)
    reg [2:0] byte_offset;          // Offset within 64-bit word (0-7)
    reg [15:0] prev_in_addr;        // Tracks previous input address
    reg [7:0] prev_cin;
    
    assign full     = (write_count == FIFO_DEPTH) ? 1 : 0;
    assign empty    = (write_count == 0)          ? 1 : 0; 
    
    reg action;
    
    wire add_changed;
    assign add_changed = (in_addr != prev_in_addr && in_addr != 0 && action) ? 1 : 0;
    wire control_changed;
    assign control_changed = (cin != prev_cin && in_addr != 0 && action) ? 1 : 0;
    wire pd_signal;
    
    always @(posedge clk) begin
        if(!rst) action <= 0;
        else begin
            action <= write_en | !empty;
        end 
    end
    
    // Write operation triggered by input address change
    always @(posedge clk) begin
        if (!rst) begin
            write_ptr_mem <= 0;
            write_ptr_ctl <= 0;
        end 
        else if (write_en && !full) begin
            mem[write_ptr_mem]  <= din; // Store data when address changes
            cmem[write_ptr_ctl] <= cin;
            if(add_changed) begin
                write_ptr_mem <= write_ptr_mem + 1;
            end
            if(add_changed | control_changed) begin
                write_ptr_ctl <= write_ptr_ctl + 1;
            end
        end
        
        prev_in_addr    <= in_addr;
        prev_cin        <= cin;
    end

    // Read operation
    always @(posedge clk) begin
        if (!rst) begin
            read_ptr <= 0;
            byte_offset <= 0;
            dout <= 8'b0;
            cout <= 8'b0;
            read_en <= 1'b0;
            read_addr <= 0;
        end 
        else if (!empty) begin
            read_en <= 1'b1;
            dout <= mem[read_ptr][8*byte_offset +: 8]; // Extract 8-bit segment
            cout <= cmem[read_ptr]; 
            read_addr <= (read_ptr << 3) + byte_offset; // Calculate external read address
            if (byte_offset == 7) begin
                byte_offset <= 0;
                read_ptr <= read_ptr + 1;
            end else begin
                byte_offset <= byte_offset + 1;
            end
        end 
        else begin
            read_ptr <= 0;
            byte_offset <= 0;
            dout <= 8'b0;
            read_en <= 1'b0;
            read_addr <= 0;
        end
    end
    
    
    // I have to detect the first write_en to set the write_count in 1 otherwise there is always 1 missing data.
    posedge_detector PD (.clk(clk), .rst(rst), .signal_in(add_changed), .posedge_detected(pd_signal));
    
    // write-count operation
     always @(posedge clk) begin
        if (!rst)                                           write_count <= 0;
        else begin
            if(empty)
                if(action & add_changed)                    write_count <= write_count + 2;
                else                                        write_count <= write_count;
            else begin
                if (byte_offset == 7) begin
                    if   (action & add_changed && !full)    write_count <= write_count;
                    else                                    write_count <= write_count - 1;
                end
                else begin
                    if   (action & add_changed && !full)    write_count <= write_count + 1;
                    else                                    write_count <= write_count;
                end
            end
        end
    end
    
endmodule

module fifo_64to16 #(
    parameter FIFO_DEPTH = 64,    // Number of 64-bit words in the FIFO
    parameter ADDR_WIDTH = 8     // Address width: log2(FIFO_DEPTH)
    )(
    input wire clk,               // Clock signal
    input wire rst,               // Reset signal (active low)
    input wire write_en,           // write enable
    input wire [63:0] din,        // 64-bit input data
    input wire [7:0]  cin,
    input wire [15:0] in_addr, // Input address (byte address)
    input wire enable,
    output reg [15:0] dout,        // 16-bit output data
    output reg [7:0]  cout,
    output reg read_en,           // Read enable
    output wire full,              // FIFO full flag
    output wire empty,             // FIFO empty flag
    output reg [15:0] read_addr // External read address (byte address)
);

    reg [63:0] mem [0:FIFO_DEPTH-1]; // FIFO memory (64-bit words)
    reg [7:0] cmem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] write_ptr_mem; // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] write_ptr_ctl; // Write pointer (64-bit words)
    reg [ADDR_WIDTH-1:0] write_count; // Write count (tracks filled words)
    reg [ADDR_WIDTH-1:0] read_ptr;  // Read pointer (64-bit words)
    reg [1:0] byte_offset;          // Offset within 64-bit word (0-7)
    reg [ADDR_WIDTH-1:0] prev_in_addr; // Tracks previous input address
    reg [7:0] prev_cin;
        
    assign full     = (write_count == FIFO_DEPTH) ? 1 : 0;
    assign empty    = (write_count == 0)          ? 1 : 0; 
    
    wire add_changed;
    assign add_changed = (in_addr != prev_in_addr) ? 1 : 0;
    wire control_changed;
    assign control_changed = (cin != prev_cin) ? 1 : 0;
    
    // Write operation triggered by input address change
    always @(posedge clk) begin
        if (!rst) begin
            write_ptr_mem <= 0;
            write_ptr_ctl <= 0;
        end 
        else if (write_en && !full) begin
            mem[write_ptr_mem]  <= din;
            cmem[write_ptr_ctl] <= cin; // Store data when address changes
            
            if(add_changed) begin
                write_ptr_mem <= write_ptr_mem + 1;
            end
            if(add_changed | control_changed) begin
                write_ptr_ctl <= write_ptr_ctl + 1;
            end
        end
        
        prev_in_addr    <= in_addr;
        prev_cin        <= cin;
    end

    
    // Read operation
    always @(posedge clk) begin
        if (!rst) begin
            dout <= 0;
            cout <= 0;
            read_ptr <= 0;
            byte_offset <= 0;
            read_en <= 1'b0;
            read_addr <= 0;
        end 
        else if (!empty & enable) begin
            dout    <= mem[read_ptr][16*byte_offset +: 16];
            cout    <= cmem[read_ptr];
            read_en <= 1'b1;
            
            read_addr <= ((read_ptr << 2) + byte_offset) & 16'h000F; // Calculate external read address
            
            if (byte_offset == 3) begin
                byte_offset <= 0;
                read_ptr <= read_ptr + 1;
            end else begin
                byte_offset <= byte_offset + 1;
            end
        end 
        else begin
            dout <= 0;
            cout <= 0;
            read_ptr <= 0;
            byte_offset <= 0;
            read_en <= 1'b0;
            read_addr <= 0;
        end
    end
    
    
    // I have to detect the first write_en to set the write_count in 1 otherwise there is always 1 missing data.
    wire pd_signal;
    posedge_detector PD (.clk(clk), .rst(rst), .signal_in(add_changed), .posedge_detected(pd_signal));
    
    // write-count operation
     always @(posedge clk) begin
        if (!rst)                                           write_count <= 0;
        else begin
            if(empty)
                if(write_en & pd_signal)                    write_count <= write_count + 2;
                else                                        write_count <= write_count;
            else begin
                if (byte_offset == 3) begin
                    if   (write_en && add_changed && !full) write_count <= write_count;
                    else                                    write_count <= write_count - 1;
                end
                else begin
                    if   (write_en && add_changed && !full) write_count <= write_count + 1;
                    else                                    write_count <= write_count;
                end
            end
        end
    end
    
endmodule

module posedge_detector (
    input wire clk,            
    input wire rst,          
    input wire signal_in,     
    output reg posedge_detected 
);

    reg signal_in_d; // Delayed version of signal_in

    // Process to detect posedge
    always @(posedge clk) begin
        if (!rst) begin
            signal_in_d <= 0;
            posedge_detected <= 0;
        end else begin
            posedge_detected <= (signal_in && !signal_in_d);
            signal_in_d <= signal_in;
        end
    end

endmodule

module negedge_detector (
    input wire clk,            
    input wire rst,          
    input wire signal_in,     
    output reg negedge_detected 
);

    reg signal_in_d; // Delayed version of signal_in

    // Process to detect negedge
    always @(posedge clk) begin
        if (!rst) begin
            signal_in_d <= 0;
            negedge_detected <= 0;
        end else begin
            negedge_detected <= (!signal_in && signal_in_d);
            signal_in_d <= signal_in;
        end
    end

endmodule

module INPUT_MODULE (
    input           clk,
    input           rst,
    input [7:0]     control,
    input [63:0]    data_in,
    input [15:0]    add,
    output [15:0]   data_in_core,
    output [7:0]    control_core,
    output [15:0]   add_in
    );
    
    // -- Control signals -- //
    wire [3:0] op;
    assign op = control[3:0];
    
    wire reset;
    wire load_coins;
    wire load_sk;
    wire read_sk;
    wire load_pk;
    wire read_pk;
    wire load_ct;
    wire read_ct;
    wire load_ss;
    wire read_ss;
    wire load_hek;
    wire read_hek;
    wire load_ps;
    wire read_ps;
    wire start;
    
    assign reset        = (op == 4'b0001) ? 1 : 0;
    assign load_coins   = (op == 4'b0010) ? 1 : 0;
    assign load_sk      = (op == 4'b0011) ? 1 : 0;
    assign read_sk      = (op == 4'b0100) ? 1 : 0;
    assign load_pk      = (op == 4'b0101) ? 1 : 0;
    assign read_pk      = (op == 4'b0110) ? 1 : 0;
    assign load_ct      = (op == 4'b0111) ? 1 : 0;
    assign read_ct      = (op == 4'b1000) ? 1 : 0;
    assign load_ss      = (op == 4'b1001) ? 1 : 0;
    assign read_ss      = (op == 4'b1010) ? 1 : 0;
    assign load_hek     = (op == 4'b1011) ? 1 : 0;
    assign read_hek     = (op == 4'b1100) ? 1 : 0;
    assign load_ps      = (op == 4'b1101) ? 1 : 0;
    assign read_ps      = (op == 4'b1110) ? 1 : 0;
    assign start        = (op == 4'b1111) ? 1 : 0;
    
    // --- FIFO 64 to 8 --- //
    wire read_en_8;
    wire [7:0]  dout_8;
    wire [15:0] add_in_8;
    wire [7:0]  control_8;
    
    /*
    FIFO_IN #(
    .INPUT_WIDTH(64),
    .OUTPUT_WIDTH(8)
    ) FIFO_64_TO_8 (
        .clk(clk),
        .rst(rst & !reset),
        .write_en(load_sk | load_pk | load_ct),
        .din(data_in),
        .cin(control),
        .empty(empty_8),
        .in_addr(add),
        .enable(1),
        .read_en(read_en_8),
        .read_addr(add_in_8),
        .dout(dout_8),
        .cout(control_8),
        .action(action_8)
    );
    
    FIFO_IN_2 #(
    .INPUT_WIDTH(64),
    .OUTPUT_WIDTH(8)
    ) FIFO_64_TO_8_2 (
        .clk(clk),
        .rst(rst & !reset),
        .write_en(load_sk | load_pk | load_ct),
        .din(data_in),
        .cin(control),
        .empty(),
        .in_addr(add),
        .enable(1),
        .read_en(),
        .read_addr(),
        .dout(),
        .cout(),
        .action()
    );
    */
    
    FIFO_IN_2 #(
    .INPUT_WIDTH(64),
    .OUTPUT_WIDTH(8)
    ) FIFO_64_TO_8 (
        .clk(clk),
        .rst(rst & !reset),
        .write_en(load_sk | load_pk | load_ct),
        .din(data_in),
        .cin(control),
        .empty(empty_8),
        .in_addr(add),
        .enable(1),
        .read_en(read_en_8),
        .read_addr(add_in_8),
        .dout(dout_8),
        .cout(control_8),
        .action(action_8)
    );
    
    // --- FIFO 64 to 16 --- //
    wire read_en_16;
    wire [15:0] dout_16;
    wire [15:0] add_in_16;
    wire [7:0]  control_16;
    
    /*
    fifo_64to16 FIFO_IN_16 (
        .clk(clk),
        .rst(rst),
        .write_en(load_ss | load_coins),
        .din(data_in),
        .cin(control),
        .empty(empty_16),
        .in_addr(add),
        .enable(!read_en_8),
        .read_en(read_en_16),
        .read_addr(add_in_16),
        .dout(dout_16),
        .cout(control_16)
    );
    
    FIFO_IN #(
    .INPUT_WIDTH(64),
    .OUTPUT_WIDTH(16)
    ) FIFO_64_TO_16 (
        .clk(clk),
        .rst(rst & !reset),
        .write_en(load_ss | load_coins | load_ps | load_hek),
        .din(data_in),
        .cin(control),
        .empty(empty_16),
        .in_addr(add),
        .enable(!read_en_8),
        .read_en(read_en_16),
        .read_addr(add_in_16),
        .dout(dout_16),
        .cout(control_16),
        .action(action_16)
    );
    */
    
    FIFO_IN_2 #(
    .INPUT_WIDTH(64),
    .OUTPUT_WIDTH(16)
    ) FIFO_64_TO_16 (
        .clk(clk),
        .rst(rst & !reset),
        .write_en(load_ss | load_coins | load_ps | load_hek),
        .din(data_in),
        .cin(control),
        .empty(empty_16),
        .in_addr(add),
        .enable(!read_en_8),
        .read_en(read_en_16),
        .read_addr(add_in_16),
        .dout(dout_16),
        .cout(control_16),
        .action(action_16)
    );
    
    assign cond1 = (!read_en_8 & !read_en_16 & !action_8 & !action_16);
    assign cond2 = (read_en_8 | action_8);
    assign control_core = cond1 ? control  : (cond2 ? control_8         : control_16); 
    assign data_in_core = cond1 ? 15'h0000 : (cond2 ? {8'h00,dout_8}    : dout_16); 
    assign add_in       = cond1 ? 15'h0000 : (cond2 ? add_in_8          : add_in_16); 

endmodule

module OUTPUT_MODULE (
    input wire clk,
    input wire rst,
    input wire [15:0] din,
    input wire [15:0] add,
    input wire start,
    input wire [7:0] control,
    output wire [15:0] add_ram,
    output wire [7:0]  control_core,
    output wire [63:0] dout,      // 64-bit data output
    output wire end_op
); 

    // -- Control signals -- //
    wire [3:0] op;
    assign op = control[3:0];
   
    wire reset;
    wire load_coins;
    wire load_sk;
    wire read_sk;
    wire load_pk;
    wire read_pk;
    wire load_ct;
    wire read_ct;
    wire load_ss;
    wire read_ss;
    wire load_hek;
    wire read_hek;
    wire load_ps;
    wire read_ps;
    
    assign reset        = (op == 4'b0001) ? 1 : 0;
    assign load_coins   = (op == 4'b0010) ? 1 : 0;
    assign load_sk      = (op == 4'b0011) ? 1 : 0;
    assign read_sk      = (op == 4'b0100) ? 1 : 0;
    assign load_pk      = (op == 4'b0101) ? 1 : 0;
    assign read_pk      = (op == 4'b0110) ? 1 : 0;
    assign load_ct      = (op == 4'b0111) ? 1 : 0;
    assign read_ct      = (op == 4'b1000) ? 1 : 0;
    assign load_ss      = (op == 4'b1001) ? 1 : 0;
    assign read_ss      = (op == 4'b1010) ? 1 : 0;
    assign load_hek     = (op == 4'b1011) ? 1 : 0;
    assign read_hek     = (op == 4'b1100) ? 1 : 0;
    assign load_ps      = (op == 4'b1101) ? 1 : 0;
    assign read_ps      = (op == 4'b1110) ? 1 : 0;

    // -- Mode signals -- //
    wire [3:0] mode;
    assign mode = control[7:4];
    
    wire k_2;
    wire k_3;
    wire k_4;
    wire gen_keys;
    wire encap;
    wire decap;
    
    assign k_2          = (mode[1:0] == 2'b01) ? 1 : 0;
    assign k_3          = (mode[1:0] == 2'b10) ? 1 : 0;
    assign k_4          = (mode[1:0] == 2'b11) ? 1 : 0;
    assign gen_keys     = (mode[3:2] == 2'b01) ? 1 : 0;
    assign encap        = (mode[3:2] == 2'b10) ? 1 : 0;
    assign decap        = (mode[3:2] == 2'b11) ? 1 : 0;
    
    //--*** STATE declaration **--//
	localparam IDLE                = 8'h00; 
	localparam LOAD_EK             = 8'h01;
	localparam LOAD_PUBLICSEED     = 8'h02;
	localparam LOAD_DK             = 8'h03;
	localparam LOAD_EK_DK          = 8'h04;
	localparam LOAD_PS_DK          = 8'h05;
	localparam LOAD_HEK            = 8'h06;
	localparam LOAD_Z              = 8'h07;
	localparam DONE                = 8'h08;
	localparam LOAD_CT             = 8'h09;
	localparam LOAD_SS             = 8'h0A;
	localparam END_READ            = 8'h0B;
    
    //--*** STATE register **--//
	reg [7:0] current_state;
	reg [7:0] next_state;
	
	//--*** STATE signals **--//
	wire           ns;
	reg            counter_cycles;
	assign ns          = (counter_cycles == 1'b1)                           ? 1 : 0;
	reg end_counter;
	
	assign end_op = (current_state == DONE) ? 1 : 0;
	
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst | !start | reset)    
			     current_state <= IDLE;
			else
			     current_state <= next_state;
		end
		
    //--*** STATE Transition **--//
	always @*
		begin
			case (current_state)
				IDLE:
				   if (ns & start & gen_keys)
				        next_state = LOAD_EK;
				   else if(ns & start & encap)
				        next_state = LOAD_CT;
				   else if(ns & start & decap)
				        next_state = LOAD_SS;
				   else
				      next_state = IDLE;
				LOAD_EK:
				   if (ns & end_counter)
				      next_state = LOAD_PUBLICSEED;
				   else
				      next_state = LOAD_EK;
				LOAD_PUBLICSEED:
				    if(ns & end_counter)  
				        next_state = LOAD_DK; 
				    else    
				        next_state = LOAD_PUBLICSEED;
				LOAD_DK:
				    if(ns & end_counter)  
				        next_state = LOAD_EK_DK; 
				    else    
				        next_state = LOAD_DK;
				LOAD_EK_DK:
				    if(ns & end_counter)  
				        next_state = LOAD_PS_DK; 
				    else    
				        next_state = LOAD_EK_DK;
				LOAD_PS_DK:
				    if(ns & end_counter)  
				        next_state = LOAD_HEK; 
				    else    
				        next_state = LOAD_PS_DK;
				LOAD_HEK:
				    if(ns & end_counter)  
				        next_state = LOAD_Z; 
				    else    
				        next_state = LOAD_HEK;
				LOAD_Z:
				    if(ns & end_counter)  
				        next_state = END_READ; 
				    else    
				        next_state = LOAD_Z;
				LOAD_CT:
				    if(ns & end_counter)  
				        next_state = LOAD_SS; 
				    else    
				        next_state = LOAD_CT;
				LOAD_SS:
				    if(ns & end_counter)  
				        next_state = END_READ; 
				    else    
				        next_state = LOAD_SS;
				END_READ:
				    if(ns)  
				        next_state = DONE; 
				    else    
				        next_state = END_READ;
				DONE:
				    if(ns & !rst)  
				        next_state = IDLE; 
				    else    
				        next_state = DONE;
				default:
					next_state = IDLE;
			endcase 		
		end 
	
		
    always @(posedge clk) begin
        if(!rst | !start)   counter_cycles <= 0;
        else                counter_cycles <= counter_cycles + 1;
    end
     
    reg [15:0] val_counter;
    always @* begin
                if(gen_keys & k_2) begin
                         if(current_state == LOAD_EK)           val_counter = 768;
                    else if(current_state == LOAD_PUBLICSEED)   val_counter = 16;
                    else if(current_state == LOAD_DK)           val_counter = 768;
                    else if(current_state == LOAD_EK_DK)        val_counter = 768;
                    else if(current_state == LOAD_PS_DK)        val_counter = 16;
                    else if(current_state == LOAD_HEK)          val_counter = 16;
                    else if(current_state == LOAD_Z)            val_counter = 16;
                    else                                        val_counter = 0;
                end 
                else if(gen_keys & k_3) begin
                         if(current_state == LOAD_EK)           val_counter = 1152;
                    else if(current_state == LOAD_PUBLICSEED)   val_counter = 16;
                    else if(current_state == LOAD_DK)           val_counter = 1152;
                    else if(current_state == LOAD_EK_DK)        val_counter = 1152;
                    else if(current_state == LOAD_PS_DK)        val_counter = 16;
                    else if(current_state == LOAD_HEK)          val_counter = 16;
                    else if(current_state == LOAD_Z)            val_counter = 16;
                    else                                        val_counter = 0;
                end
                else if(gen_keys & k_4) begin
                         if(current_state == LOAD_EK)           val_counter = 1536;
                    else if(current_state == LOAD_PUBLICSEED)   val_counter = 16;
                    else if(current_state == LOAD_DK)           val_counter = 1536;
                    else if(current_state == LOAD_EK_DK)        val_counter = 1536;
                    else if(current_state == LOAD_PS_DK)        val_counter = 16;
                    else if(current_state == LOAD_HEK)          val_counter = 16;
                    else if(current_state == LOAD_Z)            val_counter = 16;
                    else                                        val_counter = 0;
                end
                else if(encap & k_2) begin
                         if(current_state == LOAD_CT)           val_counter = 768;
                    else if(current_state == LOAD_SS)           val_counter = 16;
                    else                                        val_counter = 0;
                end
                else if(encap & k_3) begin
                         if(current_state == LOAD_CT)           val_counter = 1088;
                    else if(current_state == LOAD_SS)           val_counter = 16;
                    else                                        val_counter = 0;
                end
                else if(encap & k_4) begin
                         if(current_state == LOAD_CT)           val_counter = 1568;
                    else if(current_state == LOAD_SS)           val_counter = 16;
                    else                                        val_counter = 0;
                end
                else if(decap) begin
                        if(current_state == LOAD_SS)            val_counter = 16;
                    else                                        val_counter = 0;
                end
                else                                            val_counter = 0;                     
    end
    
    reg [15:0] counter_add;
    always @(posedge clk) begin
        if(!rst | !start)           counter_add <= 0;
        else begin
            if(current_state != IDLE & ns) begin
                if(!end_counter)    counter_add <= counter_add + 1;
                else                counter_add <= 0;
            end
            else                    counter_add <= counter_add;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | !start)                       end_counter <= 0;
        else begin
            if(counter_add == val_counter - 1)  end_counter <= 1;
            else                                end_counter <= 0;
        end
    end
    assign add_ram = counter_add; 
    
    reg [7:0] rcontrol_core;
    assign control_core = rcontrol_core;
    always @* begin
                if(gen_keys & k_2) begin
                         if(current_state == LOAD_EK)           rcontrol_core = 8'h56; // read_pk
                    else if(current_state == LOAD_PUBLICSEED)   rcontrol_core = 8'h5E; // read_ps
                    else if(current_state == LOAD_DK)           rcontrol_core = 8'h54; // read_sk
                    else if(current_state == LOAD_EK_DK)        rcontrol_core = 8'h56; // read_pk
                    else if(current_state == LOAD_PS_DK)        rcontrol_core = 8'h5E; // read_ps
                    else if(current_state == LOAD_HEK)          rcontrol_core = 8'h5C; // read_hek
                    else if(current_state == LOAD_Z)            rcontrol_core = 8'h5A; // read_ss
                    else                                        rcontrol_core = control;
                end   
                else if(gen_keys & k_3) begin
                         if(current_state == LOAD_EK)           rcontrol_core = 8'h66;
                    else if(current_state == LOAD_PUBLICSEED)   rcontrol_core = 8'h6E;
                    else if(current_state == LOAD_DK)           rcontrol_core = 8'h64;
                    else if(current_state == LOAD_EK_DK)        rcontrol_core = 8'h66;
                    else if(current_state == LOAD_PS_DK)        rcontrol_core = 8'h6E;
                    else if(current_state == LOAD_HEK)          rcontrol_core = 8'h6C;
                    else if(current_state == LOAD_Z)            rcontrol_core = 8'h6A;
                    else                                        rcontrol_core = control;
                end  
                else if(gen_keys & k_4) begin
                         if(current_state == LOAD_EK)           rcontrol_core = 8'h76;
                    else if(current_state == LOAD_PUBLICSEED)   rcontrol_core = 8'h7E;
                    else if(current_state == LOAD_DK)           rcontrol_core = 8'h74;
                    else if(current_state == LOAD_EK_DK)        rcontrol_core = 8'h76;
                    else if(current_state == LOAD_PS_DK)        rcontrol_core = 8'h7E;
                    else if(current_state == LOAD_HEK)          rcontrol_core = 8'h7C;
                    else if(current_state == LOAD_Z)            rcontrol_core = 8'h7A;
                    else                                        rcontrol_core = control;
                end  
                else if(encap & k_2) begin
                         if(current_state == LOAD_CT)           rcontrol_core = 8'h98; // read_ct
                    else if(current_state == LOAD_SS)           rcontrol_core = 8'h9A; // read_ss
                    else                                        rcontrol_core = control;
                end  
                else if(encap & k_3) begin
                         if(current_state == LOAD_CT)           rcontrol_core = 8'hA8;
                    else if(current_state == LOAD_SS)           rcontrol_core = 8'hAA;
                    else                                        rcontrol_core = control;
                end  
                else if(encap & k_4) begin
                         if(current_state == LOAD_CT)           rcontrol_core = 8'hB8;
                    else if(current_state == LOAD_SS)           rcontrol_core = 8'hBA;
                    else                                        rcontrol_core = control;
                end 
                
                else if(decap & k_2) begin
                        if(current_state == LOAD_SS)            rcontrol_core = 8'hDA;
                    else                                        rcontrol_core = control;
                end
                else if(decap & k_3) begin
                        if(current_state == LOAD_SS)            rcontrol_core = 8'hEA;
                    else                                        rcontrol_core = control;
                end
                else if(decap & k_4) begin
                        if(current_state == LOAD_SS)            rcontrol_core = 8'hFA;
                    else                                        rcontrol_core = control;
                end
                
                else                                            rcontrol_core = control;
                         
    end
    
    reg     [15:0]      REG_DATA_IN_16 [3:0];
    reg     [7:0]       REG_DATA_IN_8 [7:0];
    wire    [63:0]      REG_IN_16;
    wire    [63:0]      REG_IN_8;
    
    genvar i;
    generate 
        for(i = 0; i < 4; i = i + 1) begin
            assign REG_IN_16[(16*(i+1) - 1):(16*i)] = REG_DATA_IN_16[i];
        end
        for(i = 0; i < 8; i = i + 1) begin
            assign REG_IN_8[(8*(i+1) - 1):(8*i)]    = REG_DATA_IN_8[i];
        end
    endgenerate
    
    always @(posedge clk) begin
        if(!rst | val_counter == 0) begin 
            REG_DATA_IN_16[0]          <= 0;
            REG_DATA_IN_16[1]          <= 0;
            REG_DATA_IN_16[2]          <= 0;
            REG_DATA_IN_16[3]          <= 0;
            
            REG_DATA_IN_8[0]          <= 0;
            REG_DATA_IN_8[1]          <= 0;
            REG_DATA_IN_8[2]          <= 0;
            REG_DATA_IN_8[3]          <= 0;
            REG_DATA_IN_8[4]          <= 0;
            REG_DATA_IN_8[5]          <= 0;
            REG_DATA_IN_8[6]          <= 0;
            REG_DATA_IN_8[7]          <= 0;
        end 
        else begin
            REG_DATA_IN_16[counter_add[1:0]]  <= din;    
            REG_DATA_IN_8 [counter_add[2:0]]  <= din;                 
        end
    end
    
    reg data_8;
    wire data_16;
    always @(posedge clk) begin
        if(!rst | !start) data_8 <= 0;
        else begin
            if((current_state == LOAD_EK    | current_state == LOAD_DK | 
                current_state == LOAD_EK_DK | current_state == LOAD_CT))                            data_8 <= 1;
            else                                                                                    data_8 <= 0;
        end
    end
    assign data_16 = !data_8;
    
    wire [63:0] data_in_ram;
    assign data_in_ram = (data_8) ? REG_IN_8 : REG_IN_16;
    
    reg [15:0] add_fifo;
    always @(posedge clk) begin
        if(!rst | current_state == IDLE)                                add_fifo <= 0;
        else begin
                    if(data_8  & counter_add[2:0] == 3'b111 & ns)      add_fifo <= add_fifo + 1;
            else    if(data_16 & counter_add[1:0] == 2'b11  & ns)      add_fifo <= add_fifo + 1;
            else                                                       add_fifo <= add_fifo;
        end
    end
    
    reg [15:0] add_fifo_clk; always @(posedge clk) add_fifo_clk <= add_fifo;
    
    RAM #(.SIZE(2048) ,.WIDTH(64))
    RAM_FIFO 
    (.clk(clk), .en_write(start & !end_op), .en_read(1), 
    .addr_write(add_fifo_clk), .addr_read(add),
    .data_in(data_in_ram), .data_out(dout));
    
endmodule


