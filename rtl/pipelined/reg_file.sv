module reg_file (
    input             clk       ,
    input      [ 4:0] rd        ,
    input      [ 4:0] rs        ,
    input      [ 4:0] rt        ,
    input      [31:0] rd_data_in,
    input             we        ,
    output reg [31:0] rs_out    ,
    output reg [31:0] rt_out
);
    reg [31:0] regophile[0:31]; //32 32-bit regs

    initial begin //initialise ra, sp, s8
        regophile[31]= 32'h80088008;
        regophile[30]= 32'h12345;
        regophile[29]= 32'h80020800;
    end

    always @(posedge clk) begin
        regophile[0] <= '0;//r0 always 0
    end
    always @(posedge clk) begin
        $display("r%d: %d, r%d: %d", rs,regophile[rs],rt,regophile[rt] );
        rs_out <= regophile[rs];
        rt_out <= regophile [rt];

        if (we) begin
            if (rs == rd) begin
                rs_out <= rd_data_in;
            end
            else if (rt == rd) begin
                rt_out <= rd_data_in;
            end
            regophile[rd] <= rd_data_in;
        end

    end


endmodule
