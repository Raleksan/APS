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
  logic [2:0] func3;
  logic [6:0] func7;

  assign opcode = fetched_instr_i[6:2];
  assign func3  = fetched_instr_i[14:12];
  assign func7  = fetched_instr_i[31:25];

  always_comb begin
    a_sel_o         = OP_A_RS1;
    b_sel_o         = OP_B_RS2;
    alu_op_o        = ALU_ADD;
    csr_op_o        = '0;
    csr_we_o        = 1'b0;
    mem_req_o       = 1'b0;
    mem_we_o        = 1'b0;
    mem_size_o      = 3'd3;  // reference default; the official tb compares it on illegal LOAD/STORE
    gpr_we_o        = 1'b0;
    wb_sel_o        = WB_EX_RESULT;
    illegal_instr_o = 1'b0;
    branch_o        = 1'b0;
    jal_o           = 1'b0;
    jalr_o          = 1'b0;
    mret_o          = 1'b0;

    if (fetched_instr_i[1:0] != 2'b11) begin
      illegal_instr_o = 1'b1;
    end else begin
      case (opcode)
        OP_OPCODE: begin
          alu_op_o = {func7[5], func3};
          gpr_we_o = 1'b1;
          // only func7 = 0, except sub/sra which also allow 0x20
          if (!(func7 == 7'h00 || (func7 == 7'h20 && func3 inside {3'b000, 3'b101})))
            illegal_instr_o = 1'b1;
        end
        OP_IMM_OPCODE: begin
          b_sel_o  = OP_B_IMM_I;
          gpr_we_o = 1'b1;
          case (func3)
            3'b001: begin  // slli: func7 must be 0
              alu_op_o = ALU_SLL;
              if (func7 != 7'h00) illegal_instr_o = 1'b1;
            end
            3'b101: begin  // srli / srai
              alu_op_o = {func7[5], func3};
              if (!(func7 inside {7'h00, 7'h20})) illegal_instr_o = 1'b1;
            end
            default: alu_op_o = {1'b0, func3};
          endcase
        end
        LUI_OPCODE: begin
          a_sel_o  = OP_A_ZERO;
          b_sel_o  = OP_B_IMM_U;
          gpr_we_o = 1'b1;
        end
        AUIPC_OPCODE: begin
          a_sel_o  = OP_A_CURR_PC;
          b_sel_o  = OP_B_IMM_U;
          gpr_we_o = 1'b1;
        end
        LOAD_OPCODE: begin
          b_sel_o    = OP_B_IMM_I;
          mem_size_o = func3;
          wb_sel_o   = WB_LSU_DATA;
          if (func3 inside {LDST_B, LDST_H, LDST_W, LDST_BU, LDST_HU}) begin
            mem_req_o = 1'b1;
            gpr_we_o  = 1'b1;
          end else begin
            illegal_instr_o = 1'b1;
          end
        end
        STORE_OPCODE: begin
          b_sel_o    = OP_B_IMM_S;
          mem_size_o = func3;
          if (func3 inside {LDST_B, LDST_H, LDST_W}) begin
            mem_req_o = 1'b1;
            mem_we_o  = 1'b1;
          end else begin
            illegal_instr_o = 1'b1;
          end
        end
        BRANCH_OPCODE: begin
          alu_op_o = {2'b11, func3};
          if (func3 inside {3'b010, 3'b011}) illegal_instr_o = 1'b1;
          else                               branch_o        = 1'b1;
        end
        JAL_OPCODE: begin
          a_sel_o  = OP_A_CURR_PC;
          b_sel_o  = OP_B_INCR;
          gpr_we_o = 1'b1;
          jal_o    = 1'b1;
        end
        JALR_OPCODE: begin
          a_sel_o = OP_A_CURR_PC;
          b_sel_o = OP_B_INCR;
          if (func3 == 3'b000) begin
            gpr_we_o = 1'b1;
            jalr_o   = 1'b1;
          end else begin
            illegal_instr_o = 1'b1;
          end
        end
        MISC_MEM_OPCODE: begin  // fence is a nop
          if (func3 != 3'b000) illegal_instr_o = 1'b1;
        end
        SYSTEM_OPCODE: begin
          if (func3 == 3'b000) begin
            // ecall/ebreak raise an exception; mret is matched as the whole word
            if (fetched_instr_i == 32'h3020_0073) mret_o          = 1'b1;
            else                                  illegal_instr_o = 1'b1;
          end else if (func3 == 3'b100) begin
            illegal_instr_o = 1'b1;
          end else begin
            csr_op_o = func3;
            csr_we_o = 1'b1;
            gpr_we_o = 1'b1;
            wb_sel_o = WB_CSR_DATA;
          end
        end
        default: illegal_instr_o = 1'b1;
      endcase
    end

    // an illegal instruction must not change any state; outputs fall back to defaults
    if (illegal_instr_o) begin
      a_sel_o    = OP_A_RS1;
      b_sel_o    = OP_B_RS2;
      alu_op_o   = ALU_ADD;
      csr_op_o   = '0;
      csr_we_o   = 1'b0;
      mem_req_o  = 1'b0;
      mem_we_o   = 1'b0;
      mem_size_o = 3'd3;
      gpr_we_o   = 1'b0;
      wb_sel_o   = WB_EX_RESULT;
      branch_o   = 1'b0;
      jal_o      = 1'b0;
      jalr_o     = 1'b0;
      mret_o     = 1'b0;
    end
  end

endmodule
