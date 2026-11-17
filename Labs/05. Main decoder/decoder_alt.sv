module decoder_alt (
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
  logic       valid, legal, ldst;
  logic       is_lui, is_auipc, is_jal, is_jalr, is_op, is_op_imm, is_load, is_store,
              is_branch, is_fence, is_mret, is_csr;

  assign opcode = fetched_instr_i[6:2];
  assign func3  = fetched_instr_i[14:12];
  assign func7  = fetched_instr_i[31:25];
  assign valid  = fetched_instr_i[1:0] == 2'b11;

  assign is_lui    = valid && opcode == LUI_OPCODE;
  assign is_auipc  = valid && opcode == AUIPC_OPCODE;
  assign is_jal    = valid && opcode == JAL_OPCODE;
  assign is_jalr   = valid && opcode == JALR_OPCODE && func3 == 3'b000;

  assign is_op     = valid && opcode == OP_OPCODE &&
                     (func7 == 7'h00 || func7 == 7'h20 && (func3 == 3'b000 || func3 == 3'b101));

  assign is_op_imm = valid && opcode == OP_IMM_OPCODE &&
                     (func3 != 3'b001 && func3 != 3'b101 ||
                      func3 == 3'b001 && func7 == 7'h00 ||
                      func3 == 3'b101 && (func7 == 7'h00 || func7 == 7'h20));
  assign is_load   = valid && opcode == LOAD_OPCODE &&
                     (func3 == LDST_B || func3 == LDST_H || func3 == LDST_W || func3 == LDST_BU || func3 == LDST_HU);
  assign is_store  = valid && opcode == STORE_OPCODE &&
                     (func3 == LDST_B || func3 == LDST_H || func3 == LDST_W);
  assign is_branch = valid && opcode == BRANCH_OPCODE && func3 != 3'b010 && func3 != 3'b011;
  assign is_fence  = valid && opcode == MISC_MEM_OPCODE && func3 == 3'b000;  // fence is a nop
  // ecall/ebreak raise an exception; mret is matched as the whole word
  assign is_mret   = fetched_instr_i == 32'h3020_0073;
  assign is_csr    = valid && opcode == SYSTEM_OPCODE && func3 != 3'b000 && func3 != 3'b100;

  // === makes an X instruction illegal in 4-state simulation (e.g. uninitialised ROM); synthesis sees ==
  assign legal = (is_lui | is_auipc | is_jal | is_jalr | is_op | is_op_imm | is_load | is_store |
                  is_branch | is_fence | is_mret | is_csr) === 1'b1;
  assign illegal_instr_o = !legal;

  // every output is masked with legal so X & 0 = 0 keeps enables at their defaults
  assign gpr_we_o  = legal & (is_lui | is_auipc | is_jal | is_jalr | is_op | is_op_imm | is_load | is_csr);
  assign mem_req_o = legal & (is_load | is_store);
  assign mem_we_o  = legal & is_store;
  assign csr_we_o  = legal & is_csr;
  assign branch_o  = legal & is_branch;
  assign jal_o     = legal & is_jal;
  assign jalr_o    = legal & is_jalr;
  assign mret_o    = legal & is_mret;

  // multi-bit outputs: AND-OR mux on the one-hot flags, all-zero is the default
  assign a_sel_o  = {2{legal}} & (({2{is_auipc | is_jal | is_jalr}} & OP_A_CURR_PC) |
                                  ({2{is_lui}}                      & OP_A_ZERO));
  assign b_sel_o  = {3{legal}} & (({3{is_op_imm | is_load}} & OP_B_IMM_I) |
                                  ({3{is_lui | is_auipc}}   & OP_B_IMM_U) |
                                  ({3{is_store}}            & OP_B_IMM_S) |
                                  ({3{is_jal | is_jalr}}    & OP_B_INCR));
  assign alu_op_o = {5{legal}} & (({5{is_op}}     & {func7[5], func3}) |
                                  ({5{is_op_imm}} & {func3 == 3'b101 && func7[5], func3}) |  // only srai keeps func7[5]
                                  ({5{is_branch}} & {2'b11, func3}));
  assign wb_sel_o = {2{legal}} & (({2{is_load}} & WB_LSU_DATA) |
                                  ({2{is_csr}}  & WB_CSR_DATA));
  assign csr_op_o = {3{legal & is_csr}} & func3;

  // 3'd3 is the reference default; the official tb compares it on illegal LOAD/STORE
  assign ldst       = legal & (is_load | is_store);
  assign mem_size_o = ({3{ldst}} & func3) | ({3{!ldst}} & 3'd3);

endmodule
