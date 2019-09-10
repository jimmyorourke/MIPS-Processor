////////////////////////////////////////////////////////////////////////////////////////////////////////
//This is the top level module connecting each of the pipeline stages and memory and regfile components
//////////////////////////////////////////////////////////////////////////////////////////////////////
module proc_top#(
   X_FILE = "SimpleAdd.x"
   )(
	input clk,
	input rst, //for memory
	output [31:0]next_pc //output to tb to know when to stop sim
	);
   
	wire [31:0] pc_fd;
	wire [31:0] insn_fd;
	
	wire [31:0] pc_in;
	wire [31:0] jbr_target;
	wire jbr_valid;
   //this is what instruction to fetch next
   //on a branch fetch the branch target instead of pc+4
	assign pc_in = (jbr_valid) ? jbr_target : pc_fd; 
	//this goes out to the tb
	assign next_pc = pc_in;
	
   wire [4:0] rd_loc_dx;
   wire [1:0] rw_d_dx;
   
   //load use stall logic
   //Need to stall when the instruction in decode is a load 
   //and the load destination register is the same as one of the source regs of insn in fetch
   //unless the insn in fetch is a store and the matching register is the data reg for the store ->this can be bypassed instead
   //rw_d==2'h1 means its a load in decode
   //rd_loc_dx is the destination reg of the insn in decode
   //rsrc1 = rs, rsr2 =rd
   //its a store in fetch if insn 31:28 = 1010
   wire stall;
   assign stall = (rw_d_dx==2'h1 && ((insn_fd[25:21]==rd_loc_dx)||((insn_fd[20:16]==rd_loc_dx)&&(insn_fd[31:28]!=4'b1010))));
   
   //fetch stage
	fetch #(
      X_FILE)
   fetch0(
		.clk (clk), 
		.pc_out(pc_fd),
		.stall(stall),
		.pc_in(pc_in), 
		.rst (rst),
		.insn_out(insn_fd)
	);
	
	
	//c0ntro1 bits/pipeline reg connections between decode and execute stages
	wire [4:0] rt; 
	wire [4:0] rs; 
	wire [15:0] imm16_dx; 
	wire [25:0] imm26_dx;
	wire [4:0] sa_dx;
	wire br_dx;
	wire [1:0]jp_dx;
	wire alu_in_b_dx;
	wire dm_we_dx;
	wire r_we_dx;
	wire [1:0] r_dst_dx;
	
	wire [1:0] i_length_dx;
	wire [0:0] alu_op_dx;
	wire i_sign_extend_dx;
	wire [1:0]mem_read_size_dx;
	wire mem_sign_extend_dx;
	wire [1:0] hi_lo_out_dx;
	wire hi_in_dx;
	wire lo_in_dx;
	
	wire [31:0] pc_dx;
	wire [31:0] insn_dx;
	
   //decode
	decode dec0de(
		.clk (clk),
		.insn (insn_fd),
		.pc (pc_fd),
      
      //wires to reg file
		.rt (rt), 
		.rs (rs), 
      
		.imm16 (imm16_dx), 
		.imm26(imm26_dx),
		.sa (sa_dx),
      .stall (stall), //for load use stall -to insert nop
		//c0ntro1 bits -out
		.br (br_dx),
		.jp(jp_dx),
		.alu_in_b(alu_in_b_dx), 
		.dm_we(dm_we_dx), 
		.r_we(r_we_dx),
		.r_dst(r_dst_dx),
		.rw_d(rw_d_dx),
		.i_length(i_length_dx),
		.alu_op(alu_op_dx),
		.i_sign_extend(i_sign_extend_dx),
		.mem_read_size(mem_read_size_dx),
		.mem_sign_extend(mem_sign_extend_dx),
		.hi_lo_out(hi_lo_out_dx),
		.hi_in(hi_in_dx),
		.lo_in(lo_in_dx),
		.pc_out(pc_dx),
		.insn_out(insn_dx)
	);
	//for pipeline regs
	wire [31:0] rs_dx;
	wire [31:0] rt_dx;
	
	//from writeback to regfile
	wire [31:0] rd_data;
	wire [4:0] rd_loc_mw;
	wire r_we_mw;
	
   //the regfile
	reg_file reg0phile(
		.clk 		 (clk),
		.rd 		 (rd_loc_mw),
		.rs 		 (rs),
		.rt 		 (rt),
		.rd_data_in  (rd_data),
		.we			 (r_we_mw),
		.rs_out		 (rs_dx),
		.rt_out		 (rt_dx)
	);
	//what reg is the destination reg (rd,rt,r31) (ie writeback location)
   //need to determine this to check for bypassing/stalls
   assign rd_loc_dx = (r_dst_dx=='0) ? insn_dx[20:16] :
					(r_dst_dx==2'h1) ? insn_dx[15:11] : 31;
               
	
	//c0ntro1 bits/pipeline reg connections between execute and memory stages
	wire dm_we_xm;
	wire r_we_xm;
	wire [4:0] rd_loc_xm;
	wire [1:0] rw_d_xm;
	wire [1:0]mem_read_size_xm;
	wire mem_sign_extend_xm;
	wire [1:0] hi_lo_out_xm;
	
	wire [31:0] pc_xm;
	wire [31:0] insn_xm;
	wire [31:0] alu_out_xm;
	wire [31:0] rt_xm;
   
   //Bypassing
   //mx bypass:
   //if the insn in memory does a write back (r_we_xm=1) and the destination reg is the same as
   //the source reg of the insn in execute, bypass back its result
   //wx bypass:
   //if the insn in writeback does a write back (r_we_mw=1) and the destination reg is the same as
   //the source reg of the insn in execute, bypass back its result
   //otherwise use the outputs of the regfile from the decode stage
   //check for both rs and rt inputs
   wire [31:0] alu_rs_val_in;
   wire [31:0] alu_rt_val_in;
   assign alu_rs_val_in = (r_we_xm==1'b1 && rd_loc_xm== insn_dx[25:21]) ? alu_out_xm :
                              (r_we_mw==1'b1 && rd_loc_mw == insn_dx[25:21]) ? rd_data :
                                 rs_dx;
                           
   assign alu_rt_val_in = (r_we_xm==1'b1 && rd_loc_xm== insn_dx[20:16]) ? alu_out_xm :
                              (r_we_mw==1'b1 && rd_loc_mw == insn_dx[20:16]) ? rd_data :
                                 rt_dx;
   //execute
	execute exec_0(
		.clk (clk),
		.insn (insn_dx),
		.pc (pc_dx), 
		
		//from regfile or bypass
		.rs_val (alu_rs_val_in),
		.rt_val (alu_rt_val_in),
		
		.imm16 (imm16_dx), 
		.imm26 (imm26_dx),
		.sa (sa_dx),
			
		//c0ntro1 bits in
		.br (br_dx),
		.jp(jp_dx),
		.alu_in_b(alu_in_b_dx), 
		.dm_we(dm_we_dx), 
		.r_we(r_we_dx),
		.rd_loc (rd_loc_dx), //where the writeback is going to
		.rw_d(rw_d_dx),
		.i_length(i_length_dx),
		.alu_op(alu_op_dx),
		.i_sign_extend(i_sign_extend_dx),
		.mem_read_size(mem_read_size_dx),
		.mem_sign_extend(mem_sign_extend_dx),
		.hi_lo_out(hi_lo_out_dx),
		.hi_in(hi_in_dx),
		.lo_in(lo_in_dx),
		
		//control bits out 
		.dm_we_out (dm_we_xm),
		.r_we_out (r_we_xm),
		.rd_loc_out (rd_loc_xm),
		.rw_d_out (rw_d_xm),
		.mem_read_size_out (mem_read_size_xm),
		.mem_sign_extend_out (mem_sign_extend_xm),
		
		//if branch or jump is taken and the target pc
		//comb outputs ->need to update pc into fetch
		.jbr_valid(jbr_valid),
		.jbr_target(jbr_target),
		
		.pc_out(pc_xm),
		.insn_out(insn_xm),
		.alu_out_reg(alu_out_xm), //pipeline reg
		.rt_out(rt_xm)//for mem data in
	
	);
	//c0ntro1 bits/pipeline reg connections between memory and writeback stages

	wire [1:0] mem_read_size_mw;
	wire mem_sign_extend_mw;
	
	wire [1:0]rw_d_mw;		
   wire [31:0]alu_out_mw;
	wire [31:0]pc_mw;
	wire [31:0]insn_mw;
	wire [31:0]data_out_mw;
   
   //Bypassing
   //wm bypass:
   //if the insn in writeback does a write back (r_we_mw=1) and the destination reg is the same as
   //the source reg of the data for the memory insn, bypass back its result
   //otherwise use the outputs of the execute stage
   //only check on the data input
   wire [31:0] mem_data_in;
   assign mem_data_in = (r_we_mw==1'b1 && rd_loc_mw==insn_xm[20:16]) ? rd_data : rt_xm; 
   
	//data memory 
	mem_stage #(X_FILE)
   mem0ry(
		.clk(clk), 
		.address(alu_out_xm),
		.data_in(mem_data_in), //from exec or bypass
		.data_out(data_out_mw), 
		.access_size('0), //tie burst size to 1 word
		.read_not_write(~dm_we_xm), 
		.enable('1), 
		.rst(rst),
		
		.store_size(mem_read_size_xm), //for stores or loads
		.mem_sign_extend (mem_sign_extend_xm),
		//more contr01 b1ts in
		.r_we(r_we_xm),
		.rd_loc(rd_loc_xm),
		.rw_d(rw_d_xm),
		
		.pc(pc_xm),
		.insn(insn_xm),
		
		//control bits out, pipeline regs
		.r_we_out (r_we_mw),    
		.rd_loc_out (rd_loc_mw),
		.rw_d_out (rw_d_mw),		
		.alu_out_flop(alu_out_mw),
		.pc_out(pc_mw),
		.insn_out (insn_mw),
		.mem_read_size_out (mem_read_size_mw),
		.mem_sign_extend_out (mem_sign_extend_mw)
	);
	//writeback
	writeback wr1teback(
		.clk (clk),
		.rw_d (rw_d_mw),
		.alu_out(alu_out_mw),
		.data_out(data_out_mw),
		.pc(pc_mw),
		.insn (insn_mw),
		.mem_read_size (mem_read_size_mw),
		.mem_sign_extend(mem_sign_extend_mw),
		.rd_data (rd_data)
	); 
endmodule