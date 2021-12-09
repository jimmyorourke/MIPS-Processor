module fetch #(X_FILE) (
    input             clk,
    output reg [31:0] pc_out,
    input             stall,
    input      [31:0] pc_in,
    input             rst,
    output     [31:0] insn_out
);

    wire       rw;
    wire [1:0] access_size;

    assign rw          = 1'b1; // always a read for fetch stage
    assign access_size = 2'b0; // 0 represents access size of 1 word (4 bytes)

    wire [31:0] fetch_pc;

    always_ff @(posedge clk)
        begin
            if (rst) begin
                pc_out <= 32'h80020000; // prog start address
            end
            else begin
                if(!stall) begin
                    pc_out <= pc_in + 4;
                end
            end
        end


    // instruction memory
    main_memory #(
        2048,
        X_FILE
    ) inst_mem0ry (
        .clk           (clk        ),
        .address       (pc_in      ),
        .data_in       (           ),
        .data_out      (insn_out   ),
        .access_size   (access_size),
        .read_not_write(rw         ),
        .busy          (           ),
        .enable        (~stall     ), // dont fetch next insn if stalling -nops will be inserted
        .rst           (rst        ),
        .store_size    (2'b0       ),
        .stall         ('0         )
    );


endmodule
