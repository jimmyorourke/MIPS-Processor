module memory_tb ();

    reg         clock;
    reg  [31:0] address;
    reg  [31:0] data_in;
    wire [31:0] data_out;
    reg  [ 1:0] access_size;
    reg         read_not_write;
    wire        busy;
    reg         enable;
    reg         rst;

    localparam MEM_DEPTH = 44*4;

    main_memory #(MEM_DEPTH) mem0ry (.*);

    initial begin
        clock = 0;
        rst = 1;
        enable =0;
    end

    always
        #5  clock =  ! clock;

    //populate the memory from SumArray.x
    integer        i;
    reg     [31:0] load_memory[0:(MEM_DEPTH/4)];

    localparam START_ADDRESS = 32'h80020000;

    initial begin
        #15
            rst=0;
        enable=1;

        $readmemh("SumArray.x", load_memory);
        for (i = 0; i < (43); i = i +1) begin
            data_in = load_memory[i];
            if (!busy) begin
                read_not_write=1'b0;
                address=START_ADDRESS+4*i;
                if (i<32) begin
                    access_size=2'b11;
                end
                else if (i<40) begin
                    access_size=2'b10;
                end
                else if (i<43) begin
                    access_size=2'b0;
                end
            end
            #10;
        end


        for (i = 0; i < 5; i = i +1) begin
            if (!busy) begin
                read_not_write=1'b1;
                address=START_ADDRESS+4*i;
                access_size=2'b0;
            end
            #10;
        end
        for (i = 22; i < 30; i = i +4) begin
            read_not_write=1'b1;
            address=START_ADDRESS+4*i;
            access_size=2'b1;
            #40;
        end
    end

endmodule
