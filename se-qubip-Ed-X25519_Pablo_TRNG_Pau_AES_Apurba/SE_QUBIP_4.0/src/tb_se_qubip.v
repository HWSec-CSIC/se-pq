



module tb_se_qubip(
    );
	parameter IMP_SHA3      = 0;
    parameter IMP_SHA2      = 0;
    parameter IMP_EDDSA     = 0;
    parameter IMP_X25519    = 0;
    parameter IMP_PUF       = 1;
	parameter CLK_PRD        = 100 ;
	
	reg		i_clk;            
	reg		i_rst;            
	reg		[63:0] i_data_in; 
	reg		[63:0] i_add;     
	reg		[63:0] i_control;
	wire 	[63:0] o_data_out;
	wire	o_end_op  ;        
	
	
	
	
	  SE_QUBIP DUT(
			    .i_clk(i_clk),
			    .i_rst(i_rst),
			    .i_data_in(i_data_in),
			    .i_add(i_add),
			    .i_control(i_control),
			    .o_data_out(o_data_out),
			    .o_end_op(o_end_op)
			 );  
			 
			 
			 
	initial begin 
	   i_clk = 1'b1;
	   forever #((CLK_PRD/2)) i_clk = ~i_clk;
    end
	
	 initial begin
       i_rst = 1'b0;
       i_data_in = 64'd0;
       i_add = 64'd0;
       i_control = 64'd0;

       
	   
	   # (CLK_PRD*4)
	   #(0.8*CLK_PRD)
	   i_rst = 1'b1;
    end
	
	initial begin
        #(6*CLK_PRD)
		#(0.8*CLK_PRD)
		i_control = 64'd3;
		#CLK_PRD
		i_control = 64'd1;
		#CLK_PRD
		i_control = 64'd4;
		#CLK_PRD
		i_add = 64'd0;
		#CLK_PRD
		i_data_in = 64'd0;
		
		#CLK_PRD
		i_control = 64'd3;
		#CLK_PRD
		i_data_in = 64'd8193;
		#CLK_PRD
		i_control = 64'd0;
		#CLK_PRD
		#CLK_PRD
		
		 #(1000*CLK_PRD);
		$display("***********_____SIMULATION COMPLETED_____***********");
	    $stop;
	end
	
endmodule