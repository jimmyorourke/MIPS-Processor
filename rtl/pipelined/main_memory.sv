module main_memory #(
	parameter MEM_DEPTH = 1048576,
   parameter X_FILE
	)(
	input clk, 
	input [31:0] address,
	input [31:0] data_in,
	output reg [31:0] data_out, 
	input [1:0] access_size,  //for reads: 0= 1 word, 1=4 words, 2=8words, 3=16 words 
	input [1:0] store_size,//for writes: 0=1 word, 1=1/2 word, 2=1 byte
	input read_not_write, 
	output reg busy,
	input enable,
	input rst,
	input stall
	);
	
	localparam BASE_ADDRESS = 32'h80020000;	
	reg [7:0] memory [0:MEM_DEPTH-1];
	reg [31:0] local_address;
	reg [3:0] counter;
	reg read_not_write_r;
	
	integer i;
	reg [31:0] load_memory [0:(MEM_DEPTH/4)];
	initial begin
				
		$readmemh(X_FILE, load_memory);
		for (i = 0; i < (115); i = i +1) begin
			memory[4*i]   <= load_memory[i][31:24];
			memory[4*i+1] <= load_memory[i][23:16];
			memory[4*i+2] <= load_memory[i][15:8];
			memory[4*i+3] <= load_memory[i][7:0];
	
		end
	end
		
		
	always @(posedge clk)
	begin
		if (rst) begin 
			busy <= 1'b0;
			counter <= '0;
		end
		else if (enable)	begin
		
			if (counter==0) begin
				if (read_not_write) begin
					if (!stall) begin
						data_out[31:24] <= memory[address-BASE_ADDRESS];
						data_out[23:16] <= memory[address-BASE_ADDRESS+1];
						data_out[15:8]  <= memory[address-BASE_ADDRESS+2];
						data_out[7:0]   <= memory[address-BASE_ADDRESS+3];
					end
					else data_out<='0;
				end
				else if (!read_not_write) begin
					if (store_size=='0) begin //because of sw, sh, sb
						memory[address-BASE_ADDRESS]   <= data_in[31:24]; 
						memory[address-BASE_ADDRESS+1] <= data_in[23:16];
						memory[address-BASE_ADDRESS+2] <= data_in[15:8]; 
						memory[address-BASE_ADDRESS+3] <= data_in[7:0]; 
					end 
					else if (store_size==2'b1) begin
						memory[address-BASE_ADDRESS]   <= data_in[15:8]; 
						memory[address-BASE_ADDRESS+1] <= data_in[7:0];
					end
					else if (store_size==2'h2) begin
						memory[address-BASE_ADDRESS]   <= data_in[7:0];
					end
				end
				local_address 	  <= address + 4;
				busy			     <= access_size > 0; //don't set if burst=1
				counter			  <= (access_size==0) ? '0 : (1<<(access_size+1))-1;	
				read_not_write_r <= read_not_write; //hold this signal
			end
			
			else if (counter>0)begin
				if (read_not_write_r)	begin
					if (!stall) begin
						data_out[31:24] <= memory[local_address-BASE_ADDRESS];
						data_out[23:16] <= memory[local_address-BASE_ADDRESS+1];
						data_out[15:8]  <= memory[local_address-BASE_ADDRESS+2];
						data_out[7:0]   <= memory[local_address-BASE_ADDRESS+3];
					end
					else data_out<='0;
				end
				else if (!read_not_write_r) begin
					memory[local_address-BASE_ADDRESS]   <= data_in[31:24]; 
					memory[local_address-BASE_ADDRESS+1] <= data_in[23:16];
					memory[local_address-BASE_ADDRESS+2] <= data_in[15:8]; 
					memory[local_address-BASE_ADDRESS+3] <= data_in[7:0];  
				end
				local_address 	<= local_address + 4;
				counter			<= counter -1;
				busy			   <= (counter-1)>0;
			end
			
		end
	end
	
endmodule
	
	
