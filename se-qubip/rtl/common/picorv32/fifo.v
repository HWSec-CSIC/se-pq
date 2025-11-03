////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 09/05/2025
// Design Name: fifo.v
// Module Name: fifo
// Project Name:
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2020.1
// Description: 
//		
//		Synchronous FIFO from https://www.chipverify.com/verilog/synchronous-fifo
//
// Additional Comment
//
////////////////////////////////////////////////////////////////////////////////////


module fifo #(parameter DEPTH=64, DWIDTH=64)
(
        input               	    rstn,               // Active low reset
                            	    clk,                // Clock
                            	    wr_en, 				// Write enable
                            	    rd_en, 				// Read enable
        input      [DWIDTH-1:0]     din, 				// Data written into FIFO
        output reg [DWIDTH-1:0]     dout, 				// Data read from FIFO
        output              	    empty, 				// FIFO is empty when high
                            	    full, 				// FIFO is full when high
        output [$clog2(DEPTH)-1:0]  avail               // FIFO available space
);


    reg [$clog2(DEPTH)-1:0] wptr;
    reg [$clog2(DEPTH)-1:0] rptr;

    reg [DWIDTH-1 : 0] fifo[DEPTH-1:0];

    always @ (posedge clk) begin
        if (!rstn) begin
            wptr <= 0;
        end 
        else begin
            if (wr_en & !full) begin
                fifo[wptr] <= din;
                wptr <= wptr + 1;
            end
        end
    end

    always @ (posedge clk) begin
        if (!rstn) begin
            rptr <= 0;
        end else begin
            if (rd_en & !empty) begin
                dout <= fifo[rptr];
                rptr <= rptr + 1;
            end
        end
    end

    assign avail = rptr - (wptr + 1);
    
    assign full  = (|avail == 0);
    assign empty = wptr == rptr;

endmodule