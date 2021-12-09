module writeback (
    input               clk,
    // contr0l bits 1n
    input        [ 1:0] r_dst,
    input        [ 1:0] rw_d,
    input        [31:0] alu_out,
    input        [31:0] data_out,
    input        [31:0] pc,
    input        [31:0] insn,
    input        [ 1:0] mem_read_size,
    input               mem_sign_extend,
    // to the reg file
    output logic [31:0] rd_data,
    output       [ 4:0] rd
);

    // combinational since it writes to the regfile registers
    // have to remove bits from lb, lh, etc...

    /* control bits reminder
    r_we<='0; // writeback
    r_dst <='0; // destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
    rw_d<='0; // write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
    mem_read_size<='0; // 0 is 32bit word, 1 is halfword, 2 is byte
    mem_sign_extend<='1; // 0 is dont sign extend value read from memory, 1 is
    */
    assign rd = (r_dst=='0) ? insn[20:16] :
        (r_dst==2'h1) ? insn[15:11] : 31;

    always_comb
        begin
            if (rw_d == '0) begin // alu
                rd_data = alu_out;
            end
            else if (rw_d == 2'h1)begin
                if(mem_read_size=='0) begin
                    rd_data = data_out;
                end
                else if (mem_read_size==2'h1) begin // half word
                    if (mem_sign_extend=='0) begin // dont sign extend, upper bits are 0
                        rd_data = {16'h0,data_out[31:16]};
                    end
                    else rd_data = $signed(data_out[31:16]);
                end
                else begin // 2,  byte read
                    if (mem_sign_extend=='0) begin // dont sign extend, upper bits are 0
                        rd_data = {24'h0,data_out[31:24]};
                    end
                    else rd_data = $signed(data_out[31:24]);
                end
            end
            else rd_data = pc;
        end
endmodule
