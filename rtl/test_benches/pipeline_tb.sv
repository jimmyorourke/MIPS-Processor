module pipeline_tb #(parameter X_FILE="SimpleAdd.x") ();

    reg clk;
    reg rst;

    wire [31:0] next_pc;

    // when to stop the sim
    always @(posedge clk) begin
        if (next_pc == 32'h80088008) begin
            #20 // delay so that pipelined instructions can finish
                $stop;
        end
    end

    initial begin
        clk = 0;
        rst = 1;
    end

    always
        #5  clk =  ! clk;

    initial begin
        #15
            rst=0;
    end

    proc_top #(
        X_FILE
    ) pr0c_t0p(
        .*
    );

endmodule
