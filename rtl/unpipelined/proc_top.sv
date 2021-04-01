module proc_top (
    input         clk,
    input         rst, //for memory
    input         pc_rst, //to reset pc to start address once memory is loaded
    input         stall, //from tb
    output        jbr_taken,
    output [31:0] next_pc
);

    wire [31:0] pc_fd;

    //wire stall;
    wire [31:0] insn_fd;


    //assign stall='0; //for now

    wire [31:0] pc_in;
    wire [31:0] jbr_target;
    wire        jbr_valid;
    assign pc_in = (jbr_valid) ? jbr_target : pc_fd;
    //these go out to the tb
    assign jbr_taken = jbr_valid; //take out for pipeline
    assign next_pc   = pc_in;

    fetch fetch0 (
        .clk      (clk      ),
        .pc_out   (pc_fd    ),
        .stall    (stall    ),
        .pc_in    (pc_in    ), //for now just loop pc back in
        .rst      (pc_rst   ),
        .insn_out (insn_fd  ),
        .jbr_taken(jbr_valid)  //take out later for pipeline
    );



    wire [ 4:0] rt;
    wire [ 4:0] rs;
    wire [15:0] imm16_dx;
    wire [25:0] imm26_dx;
    wire [ 4:0] sa_dx;

    //c0ntro1 bits
    wire       br_dx;
    wire [1:0] jp_dx;
    wire       alu_in_b_dx;
    wire       dm_we_dx;
    wire       r_we_dx;
    wire [1:0] r_dst_dx;
    wire [1:0] rw_d_dx;
    wire [1:0] i_length_dx;
    wire [0:0] alu_op_dx;
    wire       i_sign_extend_dx;
    wire [1:0] mem_read_size_dx;
    wire       mem_sign_extend_dx;
    wire [1:0] hi_lo_out_dx;
    wire       hi_in_dx;
    wire       lo_in_dx;

    wire [31:0] pc_dx;
    wire [31:0] insn_dx;

    decode dec0de (
        .clk            (clk               ),
        .insn           (insn_fd           ),
        .pc             (pc_fd             ),

        .rt             (rt                ),
        .rs             (rs                ),
        .imm16          (imm16_dx          ),
        .imm26          (imm26_dx          ),
        .sa             (sa_dx             ),

        //c0ntro1 bits -out
        .br             (br_dx             ),
        .jp             (jp_dx             ),
        .alu_in_b       (alu_in_b_dx       ),
        .dm_we          (dm_we_dx          ),
        .r_we           (r_we_dx           ),
        .r_dst          (r_dst_dx          ),
        .rw_d           (rw_d_dx           ),
        .i_length       (i_length_dx       ),
        .alu_op         (alu_op_dx         ),
        .i_sign_extend  (i_sign_extend_dx  ),
        .mem_read_size  (mem_read_size_dx  ),
        .mem_sign_extend(mem_sign_extend_dx),
        .hi_lo_out      (hi_lo_out_dx      ),
        .hi_in          (hi_in_dx          ),
        .lo_in          (lo_in_dx          ),
        .pc_out         (pc_dx             ),
        .insn_out       (insn_dx           )
    );
    //pipeline regs
    wire [31:0] rs_dx;
    wire [31:0] rt_dx;

    //from writeback to regfile
    wire [31:0] rd_data;
    wire [ 4:0] rd;
    wire        r_we_mw;

    reg_file reg0phile (
        .clk       (clk    ),
        .rd        (rd     ),
        .rs        (rs     ),
        .rt        (rt     ),
        .rd_data_in(rd_data),
        .we        (r_we_mw),
        .rs_out    (rs_dx  ),
        .rt_out    (rt_dx  )
    );


    //c0ntro1 bits
    wire       dm_we_xm;
    wire       r_we_xm;
    wire [1:0] r_dst_xm;
    wire [1:0] rw_d_xm;
    wire [1:0] mem_read_size_xm;
    wire       mem_sign_extend_xm;
    wire [1:0] hi_lo_out_xm;

    wire [31:0] pc_xm;
    wire [31:0] insn_xm;
    wire [31:0] alu_out_xm;
    wire [31:0] rt_xm;
    execute exec_0 (
        .clk                (clk               ),
        .insn               (insn_dx           ),
        .pc                 (pc_dx             ),

        //from regfile
        .rs_val             (rs_dx             ),
        .rt_val             (rt_dx             ),

        .imm16              (imm16_dx          ),
        .imm26              (imm26_dx          ),
        .sa                 (sa_dx             ),

        //c0ntro1 bits in
        .br                 (br_dx             ),
        .jp                 (jp_dx             ),
        .alu_in_b           (alu_in_b_dx       ),
        .dm_we              (dm_we_dx          ),
        .r_we               (r_we_dx           ),
        .r_dst              (r_dst_dx          ),
        .rw_d               (rw_d_dx           ),
        .i_length           (i_length_dx       ),
        .alu_op             (alu_op_dx         ),
        .i_sign_extend      (i_sign_extend_dx  ),
        .mem_read_size      (mem_read_size_dx  ),
        .mem_sign_extend    (mem_sign_extend_dx),
        .hi_lo_out          (hi_lo_out_dx      ),
        .hi_in              (hi_in_dx          ),
        .lo_in              (lo_in_dx          ),



        //control bits out
        .dm_we_out          (dm_we_xm          ),
        .r_we_out           (r_we_xm           ),
        .r_dst_out          (r_dst_xm          ),
        .rw_d_out           (rw_d_xm           ),
        .mem_read_size_out  (mem_read_size_xm  ),
        .mem_sign_extend_out(mem_sign_extend_xm),

        //if branch or jump is taken and the target pc
        //comb outputs ->need to update pc into fetch
        .jbr_valid          (jbr_valid         ),
        .jbr_target         (jbr_target        ),

        .pc_out             (pc_xm             ),
        .insn_out           (insn_xm           ),
        .alu_out_reg        (alu_out_xm        ), //pipeline reg
        .rt_out             (rt_xm             )  //for mem data in
    );

    wire [1:0] mem_read_size_mw;
    wire       mem_sign_extend_mw;

    wire [ 1:0] r_dst_mw;
    wire [ 1:0] rw_d_mw;
    wire [31:0] alu_out_mw;
    wire [31:0] pc_mw;
    wire [31:0] insn_mw;
    wire [31:0] data_out_mw;

    mem_stage mem0ry (
        .clk                (clk               ),
        .address            (alu_out_xm        ),
        .data_in            (rt_xm             ),
        .data_out           (data_out_mw       ),
        .access_size        ('0                ), //tie burst size to 1 word
        .read_not_write     (~dm_we_xm         ),
        .enable             ('1                ), //always enable this!!!11!!
        .rst                (rst               ),

        .store_size         (mem_read_size_xm  ), //for stores or loads
        .mem_sign_extend    (mem_sign_extend_xm),
        //more contr01 b1ts in
        .r_we               (r_we_xm           ),
        .r_dst              (r_dst_xm          ),
        .rw_d               (rw_d_xm           ),

        .pc                 (pc_xm             ),
        .insn               (insn_xm           ),

        //control bits out, pipelion regs
        .r_we_out           (r_we_mw           ),
        .r_dst_out          (r_dst_mw          ),
        .rw_d_out           (rw_d_mw           ),
        .alu_out_flop       (alu_out_mw        ),
        .pc_out             (pc_mw             ),
        .insn_out           (insn_mw           ),
        .mem_read_size_out  (mem_read_size_mw  ),
        .mem_sign_extend_out(mem_sign_extend_mw),
        .shit               (                  )
    );

    writeback wr1teback (
        .clk            (clk               ),
        //control bits in
        //.r_we (r_we_mw), to reg file
        .r_dst          (r_dst_mw          ),
        .rw_d           (rw_d_mw           ),
        .alu_out        (alu_out_mw        ),
        .data_out       (data_out_mw       ),
        .pc             (pc_mw             ),
        .insn           (insn_mw           ),
        .mem_read_size  (mem_read_size_mw  ),
        .mem_sign_extend(mem_sign_extend_mw),
        .rd_data        (rd_data           ),
        .rd             (rd                )
    );
endmodule
