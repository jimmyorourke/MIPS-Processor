module fetch (
	input clk, 
	output reg[31:0] pc_out,
	input stall,
	input [31:0] pc_in,
	input rst,
	output [31:0]insn_out,
	input jbr_taken //take out for pipelining
	);
	
	wire rw;
	wire [1:0] access_size;
	
	assign rw =1'b1; //always a read for fetch stage
	assign access_size = 2'b0; //0 represents access size of 1 word (4 bytes)
	
	wire [31:0]fetch_pc;

	always_ff @(posedge clk)
	begin
		if (rst) begin
			pc_out <= 32'h80020000; //for now
		end
		else begin
			if(!stall) begin 
				pc_out <= fetch_pc + 4; //used to be pc_in
			end
			
				//pc_out <= pc_in;
			//end
		end
	end
	
	//make jump take 3 cycles -take out for pipelining
	//flop the comb signals to keep for a cycle
	reg jbr_reg;
	reg [31:0] jbr_pc;
	always_ff @( posedge clk) begin
		jbr_reg<= jbr_taken;
		jbr_pc <= pc_in; 
	end
	assign fetch_pc = (jbr_reg)? jbr_pc : pc_in;
	
	//instruction memory
	main_memory #(2048)inst_mem0ry(
		.clk(clk), 
		.address(fetch_pc), //was just pc_in
		.data_in(),
		.data_out(insn_out), 
		.access_size(access_size),
		.read_not_write(rw), 
		.busy(),
		.enable(1'b1), //fine for now
		.rst(rst),
		.store_size(2'b0),
		.stall(stall)
	);
	
	
endmodule
	