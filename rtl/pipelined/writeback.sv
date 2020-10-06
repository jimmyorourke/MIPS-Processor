module writeback (
    input               clk            ,
    //contr0l bits 1n
    input        [ 1:0] rw_d           ,
    input        [31:0] alu_out        ,
    input        [31:0] data_out       ,
    input        [31:0] pc             ,
    input        [31:0] insn           ,
    input        [ 1:0] mem_read_size  ,
    input               mem_sign_extend,
    //to the reg file
    output logic [31:0] rd_data
);

    //combinational since it writes to the regfile registers

    //Remove extra bits from lb, lh,
    always_comb
        begin
            if (rw_d == '0) begin //alu
                rd_data = alu_out;
            end
            else if (rw_d == 2'h1)begin
                if(mem_read_size=='0) begin
                    rd_data = data_out;
                end
                else if (mem_read_size==2'h1) begin //half word
                    if (mem_sign_extend=='0) begin //dont sign extend, upper bits are 0
                        rd_data = {16'h0,data_out[31:16]};
                    end
                    else rd_data = $signed(data_out[31:16]);
                end
                else begin //2,  byte read
                    if (mem_sign_extend=='0) begin //dont sign extend, upper bits are 0
                        rd_data = {24'h0,data_out[31:24]};
                    end
                    else rd_data = $signed(data_out[31:24]);
                end
            end
            else rd_data = pc;
        end
endmodule
