`timescale 1ns / 1ps

module puf_xl(
    input   clk,
    input   i_rst,
    input   [31:0]  control,
    input   [63:0]  address,
    input   [63:0]  data_in,
    output  [63:0]  data_out,
    output          end_op
    );
    
    puf_r5 #(
        .Nx(16),
        .Ny(16),
        .Xo(8),
        .Yo(15),
        .Bpc(4),
        .Dbw(32),
        .Nbc(14)
    ) puf_r5 (
        .clock      (   clk             ),
        .reset      (   control[0]      ),
        .puf_str    (   control[1]      ),
        .LH         (   control[2]      ),
        .BG         (   control[4]      ),
        .PE         (   control[5]      ),
        .n_cmps     (   control[23:6]   ), // (clog2(512*Nx*Ny) downto 0) = 17:0 ;
        .mem_ctrl   (   control[25:24]  ), // 2
        .mem_wadd   (   address[12:0]   ), // (clog2((512*Nx*Ny+Dbw-1)/Dbw)-1 downto 0) = 12 : 0
        .mem_wdat   (   data_in[31:0]   ), // (clog2(512*Nx*Ny/Dbw-1) downto 0) = 11 : 0
        .puf_addr   (   address[26:13]  ), // (clog2(512*Nx*Ny*Bpc/Dbw-1) downto 0) : 13 : 0
        .puf_addw   (   data_out[15:0]  ),  // (clog2(512*Nx*Ny*Bpc/Dbw) downto 0) : 14 : 0
        .puf_end    (   end_op          ), // 1 
        .puf_out    (   data_out[47:16] ) // 32 
    );
	
endmodule
