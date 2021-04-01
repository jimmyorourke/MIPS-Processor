module decode (
    input              clk,
    input       [31:0] insn,
    input       [31:0] pc,
    input              stall, //for load use -to insert nop
    //go into regfile
    output wire [ 4:0] rt,
    output wire [ 4:0] rs,
    output reg  [15:0] imm16,
    output reg  [25:0] imm26,
    output reg  [ 4:0] sa,
    //c0ntro1 bits
    output reg         br,
    output reg  [ 1:0] jp,
    output reg         alu_in_b,
    output reg         dm_we,
    output reg         r_we,
    output reg  [ 1:0] r_dst,
    output reg  [ 1:0] rw_d,
    output reg  [ 1:0] i_length,
    output reg  [ 0:0] alu_op,
    output reg         i_sign_extend,
    output reg  [ 1:0] mem_read_size,
    output reg         mem_sign_extend,
    output reg  [ 1:0] hi_lo_out,
    output reg         hi_in,
    output reg         lo_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] insn_out         //pipeline reg
);

    always_ff @ (posedge clk)
        begin
            pc_out <= pc;
            if (stall) begin
                insn_out <= '0; //nop
            end
            else begin
                insn_out <= insn;
            end
        end

    assign rt = insn[20:16];
    assign rs = insn[25:21];

    always_ff @(posedge clk) begin
        imm16 <= insn [15:0];
        imm26 <= insn [25:0];
        sa    <= insn [10:6];
    end

    always_ff @(posedge clk)
        begin
            //defaults for control signals
            br              <= '0;       //branch
            jp              <= '0;     //jump 0 is no jump, 1 immediate (with shift), 2 is reg
            alu_in_b        <= '0;  //taking immediate input -1 for immediate, 0 for reg
            dm_we           <= '0;     //memory write
            r_we            <= '0;     //writeback
            r_dst           <= '0;     //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
            rw_d            <= '0;    //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
            i_length        <= '0; //0 is 16, 1 is 26, immed length, 2 for shift amount
            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
            mem_read_size   <= '0; //0 is 32bit word, 1 is halfword, 2 is byte
            mem_sign_extend <= '1;//0 is dont sign extend value read from memory, 1 is
            hi_lo_out       <= '0;//0<=whether to use alu output, 1 is use HI, 2 is LO
            hi_in           <= '0; //0 is hold value, 1 is load new value into HI
            lo_in           <= '0;//0 is hold, 1 is load new value into Lo

            $write("%h\t",pc_out);
            if (insn=='0) begin
                $display("nop");
            end
            else begin
                if (!stall) begin
                    case(insn[31:26])
                        6'b000000: begin
                            case(insn[5:0])
                                6'b000000: begin
                                    $display("sll r%d, r%d, %d",insn[15:11], insn[20:16], insn[10:6]);
                                    alu_in_b <= 1;
                                    r_we     <= 1;
                                    r_dst    <= 1;
                                    i_length <= 2'h2;
                                end
                                6'b000010: begin //SRL rd, rt, sa
                                    $display("srl r%d, r%d, %d", insn[15:11],insn[20:16],insn[10:6]);
                                    alu_in_b <= 1;
                                    r_we     <= 1;
                                    r_dst    <= 1;
                                    i_length <= 2'h2;

                                end
                                6'b000011: begin //SRA rd, rt, sa
                                    $display("sra r%d, r%d, %d",insn[15:11],insn[20:16], insn[10:6]);
                                    alu_in_b <= 1;
                                    r_we     <= 1;
                                    r_dst    <= 1;
                                    i_length <= 2'h2;

                                end
                                6'b000100: begin //SLLV rd, rt, rs
                                    $display("sllv r%d, r%d, r%d", insn[15:11], insn[20:16], insn[25:21] );
                                    r_we     <= 1;
                                    r_dst    <= 1;
                                    i_length <= 2'h2;
                                end
                                6'b000110: begin
                                    $display("srlv r%d, r%d, r%d",insn[15:11],insn[20:16], insn[25:21]);
                                    r_we     <= 1;
                                    r_dst    <= 1;
                                    i_length <= 2'h2;
                                end
                                6'b000111: begin
                                    $display("srav r%d, r%d, %d",insn[15:11],insn[20:16], insn[25:21]);
                                    r_we     <= 1;
                                    r_dst    <= 1;
                                    i_length <= 2'h2;
                                end
                                6'b001000: begin
                                    $display("jr r%d",insn[25:21]);
                                    jp <= 2'h2;

                                end
                                6'b001001: begin
                                    $display("jalr r%d, r%d",insn[15:11],insn[25:21]);
                                    jp    <= 2'h2;
                                    r_we  <= 1'b1;
                                    rw_d  <= 2'h2;
                                    r_dst <= 1'b1;
                                end
                                6'b010000: begin
                                    $display("mfhi r%d",insn[15:11]);
                                    r_we      <= 1'b1;    //writeback
                                    r_dst     <= 1'b1;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                                    rw_d      <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                                    hi_lo_out <= 2'b1;//0<=whether to use alu output, 1 is use HI, 2 is LO
                                end
                                6'b010001: begin
                                    $display("mthi r%d",insn[25:21]);
                                    hi_in <= 1'b1; //0 is hold value, 1 is load new value into HI
                                end
                                6'b010010: begin
                                    $display("mflo r%d",insn[15:11]);
                                    r_we      <= 1'b1;    //writeback
                                    r_dst     <= 1'b1;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                                    rw_d      <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                                    hi_lo_out <= 2'h2;//0<=whether to use alu output, 1 is use HI, 2 is LO

                                end
                                6'b010011: begin
                                    $display("mtlo r%d",insn[25:21]);
                                    lo_in <= 1'b1; //0 is hold value, 1 is load new value into LO

                                end
                                6'b011000: begin
                                    $display("mult r%d, r%d",insn[25:21],insn[20:16]);
                                    hi_in <= 1'b1; //0 is hold value, 1 is load new value into HI
                                    lo_in <= 1'b1;//0 is hold, 1 is load new value into Lo
                                end
                                6'b011001: begin
                                    $display("multu r%d, r%d",insn[25:21],insn[20:16]);
                                    hi_in <= 1'b1; //0 is hold value, 1 is load new value into HI
                                    lo_in <= 1'b1;//0 is hold, 1 is load new value into Lo
                                end
                                6'b011010: begin
                                    $display("div r%d, r%d",insn[25:21],insn[20:16]);
                                    hi_in <= 1'b1; //0 is hold value, 1 is load new value into HI
                                    lo_in <= 1'b1;//0 is hold, 1 is load new value into Lo

                                end
                                6'b011011: begin
                                    $display("divu r%d, r%d",insn[25:21],insn[20:16]);
                                    hi_in <= 1'b1; //0 is hold value, 1 is load new value into HI
                                    lo_in <= 1'b1;//0 is hold, 1 is load new value into Lo

                                end
                                6'b100000: begin
                                    $display("add r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from alu vs memory- 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                                end
                                6'b100001: begin
                                    $display("addu r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                                end
                                6'b100010: begin
                                    $display("sub r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                                end
                                6'b100011: begin
                                    $display("subu r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                                end
                                6'b100100: begin
                                    $display("and r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                                end
                                6'b100101: begin
                                    $display("or r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)

                                end
                                6'b100110: begin
                                    $display("xor r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)

                                end
                                6'b100111: begin
                                    $display("nor r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)

                                end
                                6'b101010: begin
                                    $display("slt r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)

                                end
                                6'b101011: begin
                                    $display("sltu r%d, r%d, r%d",insn[15:11],insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //if destination is 2nd or 3rd reg depending on instr type
                                    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)

                                end
                                default: begin
                                    $display("not implemented");
                                end

                            endcase
                        end
                        6'b000001: begin
                            case(insn[20:16])
                                5'b00000: begin
                                    $display("bltz r%d, %d",insn[25:21],insn[15:0]);
                                    br       <= 1'b1;       //branch
                                    i_length <= '0; //0 is 16, 1 is 26, immed length, 2 for shift amount

                                end
                                5'b00001: begin
                                    $display("bgez r%d, %d",insn[25:21],insn[15:0]);
                                    br       <= 1'b1;       //branch
                                    i_length <= '0; //0 is 16, 1 is 26, immed length, 2 for shift amount

                                end
                                default: begin
                                    $display("not implemented");
                                end
                            endcase
                        end
                        6'b000010: begin
                            $display("j %d",{pc[31:28],insn[25:0],2'b00});
                            jp       <= 1'b1;      //jump 0 is no jump, 1 immediate (with shift), 2 is reg
                            i_length <= 1'b1;  //0 is 16, 1 is 26, immed length, 2 for shift amount

                        end
                        6'b000011: begin
                            $display("jal %d",{pc[31:28],insn[25:0],2'b00});
                            jp       <= 1'b1;      //jump 0 is no jump, 1 immediate (with shift), 2 is reg
                            i_length <= 1'b1;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            r_dst    <= 2'h2; //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            r_we     <= 1'b1;
                            rw_d     <= 2'h2; //write back value from memory vs alu vs pc - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                        end
                        6'b000100: begin
                            $display("beq r%d, r%d, %d",insn[25:21],insn[20:16], insn[15:0]);
                            br            <= 1'b1;      //branch
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                        end
                        6'b000101: begin
                            $display("bne r%d, r%d, %d",insn[25:21],insn[20:16], insn[15:0]);
                            br            <= 1'b1;      //branch
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '1; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b000110: begin
                            $display("blez r%d, %d",insn[25:21],insn[15:0]);
                            br            <= 1'b1;      //branch
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '1; //0 is dont sign extend the immediate, 1 is sign extend


                        end
                        6'b000111: begin
                            $display("bgtz r%d, %d",insn[25:21],insn[15:0]);
                            br            <= 1'b1;      //branch
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '1; //0 is dont sign extend the immediate, 1 is sign extend


                        end
                        6'b001000: begin
                            $display("addi r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input: 1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= 1'b1; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b001001: begin //ADDIU rt, rs, immediate
                            $display("addiu r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input: 1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                        end
                        6'b001010: begin
                            $display("slti r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= 1'b1; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b001011: begin
                            $display("sltiu r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= 1'b1; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b001100: begin
                            $display("andi r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '0; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b001101: begin
                            $display("ori r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '0; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b001110: begin
                            $display("xori r%d, r%d, %d",insn[20:16],insn[25:21],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '0; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b001111: begin
                            $display("lui r%d, %d",insn[20:16],insn[15:0]);
                            alu_in_b      <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= '0;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '0; //0 is dont sign extend the immediate, 1 is sign extend

                        end
                        6'b011100: begin
                            case(insn[5:0])
                                6'b000010: begin
                                    $display("MUL r%d, r%d, r%d",insn[15:11], insn[25:21], insn[20:16]);
                                    r_we  <= 1'b1;    //writeback
                                    r_dst <= 1'b1;    //define 1 as rd, 0 as rt/s
                                    rw_d  <= '0;     //write back value from alu vs memory- 0 is computed, 1 is memory value, 2 is pc ( jalr link)

                                end
                                default: $display("not implemented");
                            endcase
                        end
                        6'b100000: begin
                            $display("lb r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b        <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we            <= 1'b1;    //writeback
                            r_dst           <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d            <= 2'h1;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length        <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size   <= 2'h2; //0 is 32bit word, 1 is halfword, 2 is byte
                            mem_sign_extend <= 1'b1; //sign extend result

                        end
                        6'b100001: begin
                            $display("lh r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b        <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we            <= 1'b1;    //writeback
                            r_dst           <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d            <= 2'h1;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length        <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size   <= 2'h1; //0 is 32bit word, 1 is halfword, 2 is byte
                            mem_sign_extend <= 1'b1; //sign extend result


                        end
                        6'b100011: begin
                            $display("lw r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b      <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we          <= 1'b1;    //writeback
                            r_dst         <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d          <= 2'h1;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length      <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size <= 2'h0; //0 is 32bit word, 1 is halfword, 2 is byte

                        end
                        6'b100100: begin
                            $display("lbu r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b        <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we            <= 1'b1;    //writeback
                            r_dst           <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d            <= 2'h1;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length        <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size   <= 2'h2; //0 is 32bit word, 1 is halfword, 2 is byte
                            mem_sign_extend <= 1'b0; //sign extend result

                        end
                        6'b100101: begin
                            $display("lhu r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b        <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            r_we            <= 1'b1;    //writeback
                            r_dst           <= '0;    //destination reg define 1 as rd, 0 as rt, 2 as r31 for link instr
                            rw_d            <= 2'h1;     //write back value from memory vs alu - 0 is computed, 1 is memory value, 2 is pc ( jalr link)
                            i_length        <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size   <= 2'h1; //0 is 32bit word, 1 is halfword, 2 is byte
                            mem_sign_extend <= 1'b0; //sign extend result

                        end
                        6'b101000: begin
                            $display("sb r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b        <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            dm_we           <= 1'b1;    //memory write
                            i_length        <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size   <= 2'h2; //0 is 32bit word, 1 is halfword, 2 is byte
                            mem_sign_extend <= '1;//0 is dont sign extend value read from memory, 1 is
                        end
                        6'b101001: begin
                            $display("sh r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b        <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            dm_we           <= 1'b1;    //memory write
                            i_length        <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size   <= 1'b1; //0 is 32bit word, 1 is halfword, 2 is byte
                            mem_sign_extend <= '1;//0 is dont sign extend value read from memory, 1 is
                        end
                        6'b101011: begin
                            $display("sw r%d, %d(%d)",insn[20:16], insn[15:0],insn[25:21]);
                            alu_in_b        <= 1'b1;   //taking immediate input -1 for immediate, 0 for reg
                            dm_we           <= 1'b1;    //memory write
                            i_length        <= '0;  //0 is 16, 1 is 26, immed length, 2 for shift amount
                            i_sign_extend   <= '1; //0 is dont sign extend the immediate, 1 is sign extend
                            mem_read_size   <= '0; //0 is 32bit word, 1 is halfword, 2 is byte
                            mem_sign_extend <= '1;//0 is dont sign extend value read from memory, 1 is

                        end
                        default: $display("not implemented");
                    endcase
                end
            end
        end

endmodule
