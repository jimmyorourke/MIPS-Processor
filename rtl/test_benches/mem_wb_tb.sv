module mem_wb_tb #(parameter X_FILE="SimpleAdd.x") ();

    reg clk;
    reg rst;
    reg pc_rst;

    reg         stall;
    reg  [ 2:0] counter;
    wire        jbr_taken;
    wire [31:0] next_pc;

    // drive stall logic
    always @(posedge clk) begin
        if (next_pc == 32'h80088008) begin
            /*@(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);*/
            #20 // delay so that pipelined instructions can finish
                $stop;
        end
        /*if (rst) begin
        counter <= 0;
        stall   <= 0;
        end
        else begin
        counter <= counter+1;
        stall   <= 1;
        if (counter==4 ||jbr_taken ) begin
        counter <= 0;
        stall   <= 0;
        end
        end*/
    end

    initial begin
        clk = 0;
        rst = 1;
        pc_rst = 1;
        stall =0;
        counter=0;
    end

    always
        #5  clk =  ! clk;



    initial begin
        #15
            rst=0;


        #10;
        pc_rst = 0;


    end
    proc_top #(
        X_FILE
    ) pr0c_t0p(
        .*

    );

endmodule
