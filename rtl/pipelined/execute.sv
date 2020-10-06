module execute (
    input             clk                ,
    input      [31:0] insn               ,
    input      [31:0] pc                 ,
    //from regfile
    input      [31:0] rs_val             ,
    input      [31:0] rt_val             ,
    input      [15:0] imm16              ,
    input      [25:0] imm26              ,
    input      [ 4:0] sa                 ,
    //c0ntro1 bits in
    input             br                 ,
    input      [ 1:0] jp                 ,
    input             alu_in_b           ,
    input             dm_we              ,
    input             r_we               ,
    input      [ 4:0] rd_loc             ,
    input      [ 1:0] rw_d               ,
    input      [ 1:0] i_length           ,
    input      [ 0:0] alu_op             ,
    input             i_sign_extend      ,
    input      [ 1:0] mem_read_size      ,
    input             mem_sign_extend    ,
    input      [ 1:0] hi_lo_out          ,
    input             hi_in              ,
    input             lo_in              ,
    //control bits out
    output reg        dm_we_out          ,
    output reg        r_we_out           ,
    output reg [ 4:0] rd_loc_out         ,
    output reg [ 1:0] rw_d_out           ,
    output reg [ 1:0] mem_read_size_out  ,
    output reg        mem_sign_extend_out,
    //if branch or jump is taken and the target pc
    output            jbr_valid          ,
    output     [31:0] jbr_target         ,
    output reg [31:0] pc_out             ,
    output reg [31:0] insn_out           ,
    output reg [31:0] alu_out_reg        , //pipeline reg
    output reg [31:0] rt_out
);
    /* control bits reminder
    br      //branch
    jp      //jump 0 is no jump, 1 immediate (with shift), 2 is reg
    dm_we           //memory write
    r_we        //writeback
    rd_loc  //destination register
    rw_d         //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
    i_length    //0 is 16, 1 is 26, immed length, 2 for shift amount
    i_sign_extend  //0 is dont sign extend the immediate, 1 is sign extend
    mem_read_size  //0 is 32bit word, 1 is halfword, 2 is byte
    mem_sign_extend<='1;//0 is dont sign extend value read from memory, 1 is
    hi_lo_out  //0<=whether to use alu output, 1 is use HI, 2 is LO
    hi_in  //0 is hold value, 1 is load new value into HI
    lo_in //0 is hold, 1 is load new value into Lo
    */

    //flop control bits into pipeline reg for next stage
    always_ff @(posedge clk)begin
        //control bits out
        dm_we_out           <= dm_we;
        r_we_out            <= r_we;
        rd_loc_out          <= rd_loc;
        rw_d_out            <= rw_d;
        mem_read_size_out   <= mem_read_size;
        mem_sign_extend_out <= mem_sign_extend;

        pc_out   <= pc;
        insn_out <= insn;
    end
    always_ff@(posedge clk) begin
        rt_out <= rt_val; //used for memory data input
    end
    logic [31:0] current_immed; //which immediate is being used
    always_comb
        begin
            if (i_length=='0) begin
                if (i_sign_extend=='1) begin
                    current_immed = $signed(imm16);
                end
                else current_immed=(imm16);
            end
            else if (i_length==1'b1) begin
                if (i_sign_extend=='1) begin
                    current_immed = $signed(imm26);
                end
                else current_immed=(imm26);
            end
            else begin //i_length=2;
                if (i_sign_extend=='1) begin
                    current_immed = $signed(sa);
                end
                else current_immed=(sa);
            end
        end

    wire [31:0] i2; //second input to alu
    assign i2 = (alu_in_b==0)? rt_val : current_immed;



    logic br_taken; //if the branch is taken

    assign jbr_valid  = (jp>0)|(br & br_taken);
    assign jbr_target = (br>0 )? pc + (current_immed<<2) :
        (jp==1)? {pc[31:28],imm26,2'b00} : rs_val;

    //hi and lo registers
    reg [31:0] hi_reg;
    reg [31:0] lo_reg;

    logic [31:0] alu_out;
    //assign to pipeline reg
    always_ff @(posedge clk) begin
        $display("alu output: %d, branch taken: %d, branch target: 0x%x",alu_out, jbr_valid,jbr_target);
        alu_out_reg <= alu_out;

    end

    wire [63:0] mult_res;
    wire [63:0] div_res ;
    assign mult_res = ($signed(rs_val)*$signed(rt_val));
    assign div_res  = ($signed(rs_val)/$signed(rt_val));

    //assign hi/lo regs
    always_ff @(posedge clk)
        begin
            case(insn[31:26])
                6'b000000 : begin
                    case(insn[5:0])

                        6'b010001 : begin
                            //$display("mthi r%d",insn[25:21]);
                            hi_reg <= rs_val;
                        end
                        6'b010011 : begin
                            //$display("mtlo r%d",insn[25:21]);
                            lo_reg <= rs_val;
                        end
                        6'b011000 : begin
                            //$display("mult r%d, r%d",insn[25:21],insn[20:16]);
                            hi_reg <= mult_res[63:32];
                            lo_reg <= mult_res[31:0];
                        end
                        6'b011001 : begin
                            //$display("multu r%d, r%d",insn[25:21],insn[20:16]);
                            hi_reg <= mult_res[63:32];
                            lo_reg <= mult_res[31:0];
                        end
                        6'b011010 : begin
                            //$display("div r%d, r%d",insn[25:21],insn[20:16]);
                            hi_reg <= div_res[63:32];
                            lo_reg <= div_res[31:0];

                        end
                        6'b011011 : begin
                            //$display("divu r%d, r%d",insn[25:21],insn[20:16]);
                            hi_reg = div_res[63:32];
                            lo_reg = div_res[31:0];
                        end
                        default : ;
                    endcase
                end
                default : ;
            endcase
        end



    always_comb
        begin

            if (insn=='0) begin
                ////$display("nop");
            end
            else begin
                case(insn[31:26])
                    6'b000000 : begin
                        case(insn[5:0])
                            6'b000000 : begin
                                //$display("sll r%d, r%d, %d",insn[15:11], insn[20:16], insn[10:6]);
                                alu_out = rt_val<<current_immed;
                            end
                            6'b000010 : begin //SRL rd, rt, sa
                                //$display("srl r%d, r%d, %d", insn[15:11],insn[20:16],insn[10:6]);
                                alu_out = rt_val >>current_immed;

                            end
                            6'b000011 : begin //SRA rd, rt_val, sa
                                //$display("sra r%d, r%d, %d",insn[15:11],insn[20:16], insn[10:6]);
                                alu_out = rt_val>>>current_immed;

                            end
                            6'b000100 : begin //SLLV rd, rt, rs
                                //$display("sllv r%d, r%d, r%d", insn[15:11], insn[20:16], insn[25:21] );
                                alu_out = rt_val <<rs_val[4:0];
                            end
                            6'b000110 : begin
                                //$display("srlv r%d, r%d, r%d",insn[15:11],insn[20:16], insn[25:21]);
                                alu_out = rt_val>>rs_val[4:0];
                            end
                            6'b000111 : begin
                                //$display("srav r%d, r%d, %d",insn[15:11],insn[20:16], insn[25:21]);
                                alu_out = rt_val>>>rs_val[4:0];
                            end
                            6'b001000 : begin
                                //$display("jr r%d",insn[25:21]);
                            end
                            6'b001001 : begin
                                //$display("jalr r%d, r%d",insn[15:11],insn[25:21]);
                            end
                            6'b010000 : begin
                                //$display("mfhi r%d",insn[15:11]);
                                alu_out = hi_reg;
                            end
                            6'b010001 : begin
                                //$display("mthi r%d",insn[25:21]);
                                //hi_reg=rs_val;
                            end
                            6'b010010 : begin
                                //$display("mflo r%d",insn[15:11]);
                                alu_out = lo_reg;
                            end
                            6'b010011 : begin
                                //$display("mtlo r%d",insn[25:21]);
                                //lo_reg = rs_val;
                            end
                            6'b011000 : begin
                                //$display("mult r%d, r%d",insn[25:21],insn[20:16]);
                                //hi_reg=($signed(rt_val)*$signed(rs_val))[63:32];
                                //lo_reg=($signed(rt_val)*$signed(rs_val))[31:0];
                            end
                            6'b011001 : begin
                                //$display("multu r%d, r%d",insn[25:21],insn[20:16]);
                                //hi_reg=($signed(rt_val)/$signed(rs_val))[63:32];
                                //lo_reg=($signed(rt_val)/$signed(rs_val))[31:0];
                            end
                            6'b011010 : begin
                                //$display("div r%d, r%d",insn[25:21],insn[20:16]);
                                //hi_reg=(rs_val/rt_val)[63:32];
                                //lo_reg=(rs_val/rt_val)[31:0];

                            end
                            6'b011011 : begin
                                //$display("divu r%d, r%d",insn[25:21],insn[20:16]);
                                //hi_reg=(rs_val/rt_val)[63:32];
                                //lo_reg=(rs_val/rt_val)[31:0];

                            end
                            6'b100000 : begin
                                //$display("add r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = $signed(rs_val)+$signed(rt_val);
                            end
                            6'b100001 : begin
                                //$display("addu r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = rs_val+rt_val;
                            end
                            6'b100010 : begin
                                //$display("sub r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = rs_val-rt_val;
                            end
                            6'b100011 : begin
                                //$display("subu r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = rs_val-rt_val;
                            end
                            6'b100100 : begin
                                //$display("and r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = rs_val&rt_val;
                            end
                            6'b100101 : begin
                                //$display("or r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = rs_val|rt_val;
                            end
                            6'b100110 : begin
                                //$display("xor r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = rs_val^rt_val;
                            end
                            6'b100111 : begin
                                //$display("nor r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = ~(rs_val|rt_val);
                            end
                            6'b101010 : begin
                                //$display("slt r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = ($signed(rs_val)<$signed(rt_val));
                            end
                            6'b101011 : begin
                                //$display("sltu r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                alu_out = ((rs_val)<(rt_val));

                            end
                            default : begin
                                //$display("not implemented");
                            end

                        endcase
                    end
                    6'b000001 : begin
                        case(insn[20:16])
                            5'b00000 : begin
                                //$display("bltz r%d, %d",insn[25:21],insn[15:0]);
                                br_taken = ($signed(rs_val)<0);

                            end
                            5'b00001 : begin
                                //$display("bgez r%d, %d",insn[25:21],insn[15:0]);
                                br_taken = ($signed(rs_val)>=0);

                            end
                            default : begin
                                //$display("not implemented");
                            end
                        endcase
                    end
                    6'b000010 : begin
                        //$display("j %d",{pc[31:28],insn[25:0],2'b00});
                    end
                    6'b000011 : begin
                        //$display("jal %d",{pc[31:28],insn[25:0],2'b00});
                    end
                    6'b000100 : begin
                        //$display("beq r%d, r%d, %d",insn[25:21],insn[20:16], insn[15:0]);
                        br_taken = (rs_val==rt_val);

                    end
                    6'b000101 : begin
                        //$display("bne r%d, r%d, %d",insn[25:21],insn[20:16], insn[15:0]);
                        br_taken = (rs_val!=rt_val);

                    end
                    6'b000110 : begin
                        //$display("blez r%d, %d",insn[25:21],insn[15:0]);
                        br_taken = ($signed(rs_val)<=0);
                    end
                    6'b000111 : begin
                        //$display("bgtz r%d, %d",insn[25:21],insn[15:0]);
                        br_taken = ($signed(rs_val)>0);


                    end
                    6'b001000 : begin
                        //$display("addi r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                        alu_out = $signed(rs_val)+$signed(current_immed);
                    end
                    6'b001001 : begin //ADDIU rt_val, rs, immediate
                        //$display("addiu r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                        alu_out = (rs_val)+(current_immed);
                    end
                    6'b001010 : begin
                        //$display("slti r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                        alu_out = ($signed(rs_val)<$signed(current_immed));
                    end
                    6'b001011 : begin
                        //$display("sltiu r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                        alu_out = ((rs_val)<(current_immed));
                    end
                    6'b001100 : begin
                        //$display("andi r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                        alu_out = rs_val & current_immed;
                    end
                    6'b001101 : begin
                        //$display("ori r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                        alu_out = rs_val | current_immed;
                    end
                    6'b001110 : begin
                        //$display("xori r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                        alu_out = rs_val ^ current_immed;
                    end
                    6'b001111 : begin
                        //$display("lui r%d, %d",insn[20:16],insn[15:0]);
                        alu_out = current_immed<<16;
                    end
                    6'b011100 : begin
                        case(insn[5:0])
                            6'b000010 : begin
                                //$display("MUL r%d, r%d, r%d",insn[15:11], insn[25:21], insn[20:16]);
                                alu_out = mult_res[31:0];
                            end
                            default : $display("not implemented");
                        endcase
                    end
                    6'b100000 : begin
                        //$display("lb r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                        alu_out = rs_val+$signed(current_immed);

                    end
                    6'b100001 : begin
                        //$display("lh r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                        alu_out = rs_val+$signed(current_immed);
                    end
                    6'b100011 : begin
                        //$display("lw r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                        alu_out = rs_val+$signed(current_immed);
                    end
                    6'b100100 : begin
                        //$display("lbu r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                        alu_out = rs_val+$signed(current_immed);
                    end
                    6'b100101 : begin
                        //$display("lhu r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                        alu_out = rs_val+$signed(current_immed);
                    end
                    6'b101000 : begin
                        alu_out = rs_val+$signed(current_immed);
                    end
                    6'b101001 : begin
                        alu_out = rs_val+$signed(current_immed);
                    end
                    6'b101011 : begin
                        //$display("sw r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                        alu_out = rs_val+$signed(current_immed);
                    end
                    default : $display("not implemented");
                endcase
            end
        end
endmodule
