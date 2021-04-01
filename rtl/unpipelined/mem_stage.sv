module mem_stage (
    input             clk,
    input      [31:0] address,
    input      [31:0] data_in,
    output[31:0] data_out, //pipeline reg located in the mem module
    input      [ 1:0] access_size, //for burst reads: 0= 1 word, 1=4 words, 2=8words, 3=16 words
    input      [ 1:0] store_size, //for loads or stores: 0=1 word, 1=1/2 word, 2=1 byte --used for stores or loads
    input             read_not_write,
    input             enable,
    input             rst,
    input             mem_sign_extend, //0 is dont sign extend value read from memory, 1 is
    //control bits in
    input             r_we, //writeback
    input      [ 1:0] r_dst, //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
    input      [ 1:0] rw_d, //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
    input      [31:0] pc,
    input      [31:0] insn,
    //control bits out
    output reg        r_we_out,
    output reg [ 1:0] r_dst_out,
    output reg [ 1:0] rw_d_out,
    output reg [31:0] alu_out_flop, //pipeline register
    output reg [31:0] pc_out,
    output reg [31:0] insn_out,
    output reg [ 1:0] mem_read_size_out,
    output reg        mem_sign_extend_out,
    output reg        shit                 //output regular
);

    always_ff@(posedge clk)begin
        alu_out_flop <= address; //for use when the alu output is not for memory, bypass mem
    end
    //flop the control bits
    always_ff@(posedge clk) begin
        r_we_out            <= r_we;
        r_dst_out           <= r_dst;
        rw_d_out            <= rw_d;
        pc_out              <= pc;
        insn_out            <= insn;
        mem_read_size_out   <= store_size; //do the bit chopping in wb
        mem_sign_extend_out <= mem_sign_extend;
    end



    //data memory
    main_memory #(2048) dat_mem0ry (
        .clk           (clk           ),
        .address       (address       ),
        .data_in       (data_in       ),
        .data_out      (data_out      ), //need to modify data out for byte or hw in wb since this is already flopped
        .access_size   (access_size   ),
        .read_not_write(read_not_write),
        .busy          (              ),
        .enable        (enable        ), //fine for now
        .rst           (rst           ),
        .store_size    (store_size    ),
        .stall         ('0            )
    );
endmodule
