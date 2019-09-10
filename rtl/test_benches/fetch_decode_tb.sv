module fetch_decode_tb;
	
	reg clk; 
	reg rst;
	reg pc_rst;
	
	
	
	
	initial begin
		clk = 0; 
		rst = 1;
		pc_rst = 1;
	end 
	
	always  
		#5  clk =  ! clk;
		
	
	
	initial begin
		#15 
		rst=0;
		
		
		#10;
		pc_rst = 0;
    	
	end
	proc_top pr0c_t0p(
		.clk (clk), 
		.rst (rst),
		.pc_rst (rst)
	);
	 
endmodule