



module tb_puf(
    );
	parameter Nx = 1 ; //11+11+3+28
	parameter Ny   = 2;
	parameter Xo = 6;
	parameter Yo   = 15 ;
	parameter Bpc = 4 ;
	parameter Dbw    = 64;
	parameter Mnc     = 4096 ;
	parameter Nbc    = 8;
	parameter CLK_PRD        = 100 ;
	
	reg		clock;
	reg		reset;
	reg     puf_str ;
	reg     BG;
	reg     SD;
	reg    [1:0] cnfa;
	reg 	[$clog2(Mnc) : 0] n_cmps;
	reg 	[$clog2(Mnc*Bpc/Dbw-1)-1:0] puf_addr;
	wire		[$clog2(Mnc*Bpc/Dbw):0] puf_addw;
	
	wire 	puf_end;
	wire		[Dbw-1:0] puf_out;
	
	
	
	  puf DUT(
			    .clock(clock),
			    .reset(reset),
			    .puf_str(puf_str),
			    .BG(BG),
			    .SD(SD),
			    .cnfa(cnfa),
			    .n_cmps(n_cmps),
			    .puf_addr(puf_addr),
			    .puf_addw(puf_addw),
			    .puf_end(puf_end),
			    .puf_out(puf_out)
			 );  
			 
			 
			 
	initial begin 
	   clock = 1'b1;
	   forever #((CLK_PRD/2)) clock = ~clock;
    end
	
	 initial begin
       reset = 1'b1;
       puf_str = 1'b0;
       BG = 1'b0;
       SD = 1'b0;
       cnfa    = 2'b00;
       n_cmps    = 13'd128;
       puf_addr    = 512'd0;
       
	   
	   # (CLK_PRD*4)
	   #(0.8*CLK_PRD)
	   reset = 1'b0;
    end
	
	initial begin
        #(6*CLK_PRD)
		#(0.8*CLK_PRD)
		
		puf_str = 1'b1;
		
		 #(1000*CLK_PRD);
		$display("***********_____SIMULATION COMPLETED_____***********");
	    $stop;
	end
	
endmodule