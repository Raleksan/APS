module decoder (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);
    import decoder_pkg::*;

    logic [4:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [0:0] legal;

    assign opcode = fetched_instr_i [6:2];
    assign funct3 = fetched_instr_i [14:12];
    assign funct7 = fetched_instr_i [31:25];

    always_comb begin : decoding_comb
        // Set all to default
        gpr_we_o = 0;
        csr_we_o = 0;
        mem_req_o = 0;
        mem_we_o = 0;
        branch_o = 0;
        jal_o = 0;
        jalr_o = 0;
        mret_o = 0;

        legal = 0;

        a_sel_o = '0;
        b_sel_o = '0;
        alu_op_o = '0;
        csr_op_o = '0;
        mem_size_o = 3'd3;
        wb_sel_o = 0;

        illegal_instr_o = 0;

        if (fetched_instr_i[1:0] != 2'b11)
            illegal_instr_o = 1'b1;

        else case (opcode)

            OP_OPCODE : begin
                legal = funct7 == '0 || (funct7 == 7'h20 && (funct3 == 3'b000 || funct3 == 3'b101) );
                if (legal) begin
                    alu_op_o = {1'b0, funct7[5], funct3};
                    gpr_we_o = 1'b1;
                end else begin
                    illegal_instr_o = 1'b1;
                end
            end

            OP_IMM_OPCODE : begin
                case (funct3)
                    3'b001:  legal = funct7 == 7'h00;
                    3'b101:  legal = funct7 == 7'h00 || funct7 == 7'h20;
                    default: legal = 1'b1;
                endcase

                if (legal) begin
                    b_sel_o  = OP_B_IMM_I;
                    gpr_we_o = 1'b1;
                    alu_op_o = {1'b0, {funct3 == 3'b101 && funct7[5]}, funct3};
                end else begin
                    illegal_instr_o = 1'b1;
                end
            end

            LUI_OPCODE : begin
                a_sel_o  = OP_A_ZERO;
                b_sel_o  = OP_B_IMM_U;
                gpr_we_o = 1'b1;
                alu_op_o = ALU_ADD;
            end

            AUIPC_OPCODE : begin
                a_sel_o  = OP_A_CURR_PC;
                b_sel_o  = OP_B_IMM_U;
                gpr_we_o = 1'b1;
                alu_op_o = ALU_ADD;
            end

            LOAD_OPCODE : begin
                case (funct3)
                    3'b011, 3'b110, 3'b111: legal = 1'b0;
                    default : legal = 1'b1;
                endcase
                // legal = funct3 inside {LDST_B, LDST_H, LDST_W, LDST_BU, LDST_HU};

                if (legal) begin
                    a_sel_o = OP_A_RS1;
                    b_sel_o = OP_B_IMM_I;

                    mem_req_o  = 1'b1;
                    mem_size_o = funct3;

                    gpr_we_o   = 1'b1;
                    wb_sel_o   = WB_LSU_DATA;
                end else begin
                    illegal_instr_o = 1'b1;
                end
            end

            STORE_OPCODE : begin
                case (funct3)
                    LDST_B, LDST_H, LDST_W : legal = 1'b1;
                    default : legal = 1'b0;
                endcase

                if (legal) begin
                    a_sel_o = OP_A_RS1;
                    b_sel_o = OP_B_IMM_S;

                    mem_we_o   = 1'b1;
                    mem_req_o  = 1'b1;
                    mem_size_o = funct3;
                end else begin
                    illegal_instr_o = 1'b1;
                end
            end

            BRANCH_OPCODE : begin
                case (funct3)
                    3'b010, 3'b011 : legal = 1'b0;
                    default : legal = 1'b1;
                endcase

                if (legal) begin
                    alu_op_o = {2'b11, funct3};
                    branch_o = 1'b1;
                end else begin
                    illegal_instr_o = 1'b1;
                end
            end

            JAL_OPCODE : begin
                a_sel_o  = OP_A_CURR_PC;
                b_sel_o  = OP_B_INCR;
                jal_o    = 1'b1;
                gpr_we_o = 1'b1;
            end

            JALR_OPCODE : begin
                legal = (funct3 == 3'b000);

                if (legal) begin
                    a_sel_o  = OP_A_CURR_PC;
                    b_sel_o  = OP_B_INCR;
                    jalr_o   = 1'b1;
                    gpr_we_o = 1'b1;
                end else begin
                    illegal_instr_o = 1'b1;
                end
            end

            MISC_MEM_OPCODE : begin
                illegal_instr_o = (funct3 != 3'b000);
            end

            SYSTEM_OPCODE : begin
                case (funct3)
                    3'b100 : legal = 1'b0;
                    3'b000 : legal = fetched_instr_i == 32'h3020_0073;
                    default : legal = 1'b1;
                endcase

                if (fetched_instr_i == 32'h3020_0073) begin
                    mret_o = 1'b1;
                end else if (legal) begin
                    csr_op_o = funct3;
                    csr_we_o = 1'b1;

                    wb_sel_o = WB_CSR_DATA;
                    gpr_we_o = 1'b1;
                end else begin
                    illegal_instr_o = 1'b1;
                end
            end

            default: illegal_instr_o = 1'b1;
        endcase
    end

endmodule : decoder
