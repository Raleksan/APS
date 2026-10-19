module processor_core (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,
  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o
);
  import decoder_pkg::*;

  logic [31:0] pc;

  // decoder outputs
  logic [1:0] a_sel;
  logic [2:0] b_sel;
  logic [4:0] alu_op;
  logic       gpr_we;
  logic [1:0] wb_sel;
  logic       branch, jal, jalr;

  logic [31:0] rd1, rd2;
  logic [31:0] alu_a, alu_b, alu_result;
  logic        alu_flag;
  logic [31:0] wb_data;

  logic [31:0] imm_I, imm_U, imm_S, imm_B, imm_J;
  assign imm_I = {{20{instr_i[31]}}, instr_i[31:20]};
  assign imm_U = {instr_i[31:12], 12'h000};
  assign imm_S = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign imm_B = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
  assign imm_J = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

  decoder main_decoder (
    .fetched_instr_i (instr_i),
    .a_sel_o         (a_sel),
    .b_sel_o         (b_sel),
    .alu_op_o        (alu_op),
    .csr_op_o        (),
    .csr_we_o        (),
    .mem_req_o       (mem_req_o),
    .mem_we_o        (mem_we_o),
    .mem_size_o      (mem_size_o),
    .gpr_we_o        (gpr_we),
    .wb_sel_o        (wb_sel),
    .illegal_instr_o (),
    .branch_o        (branch),
    .jal_o           (jal),
    .jalr_o          (jalr),
    .mret_o          ()
  );

  register_file rf (
    .clk_i          (clk_i),
    .write_enable_i (gpr_we && !stall_i),
    .write_addr_i   (instr_i[11:7]),
    .read_addr1_i   (instr_i[19:15]),
    .read_addr2_i   (instr_i[24:20]),
    .write_data_i   (wb_data),
    .read_data1_o   (rd1),
    .read_data2_o   (rd2)
  );

  always_comb begin
    case (a_sel)
      OP_A_RS1:     alu_a = rd1;
      OP_A_CURR_PC: alu_a = pc;
      default:      alu_a = '0;
    endcase
  end

  always_comb begin
    case (b_sel)
      OP_B_RS2:   alu_b = rd2;
      OP_B_IMM_I: alu_b = imm_I;
      OP_B_IMM_U: alu_b = imm_U;
      OP_B_IMM_S: alu_b = imm_S;
      OP_B_INCR:  alu_b = 32'd4;
      default:    alu_b = '0;
    endcase
  end

  alu alu (
    .a_i      (alu_a),
    .b_i      (alu_b),
    .alu_op_i (alu_op),
    .flag_o   (alu_flag),
    .result_o (alu_result)
  );

  always_comb begin
    case (wb_sel)
      WB_EX_RESULT: wb_data = alu_result;
      WB_LSU_DATA:  wb_data = mem_rd_i;
      default:      wb_data = '0;  // CSR data arrives in lab 11
    endcase
  end

  assign mem_addr_o = alu_result;
  assign mem_wd_o   = rd2;

  logic [31:0] pc_offset, pc_next;
  assign pc_offset = jal ? imm_J : ((branch && alu_flag) ? imm_B : 32'd4);
  assign pc_next   = jalr ? ((rd1 + imm_I) & ~32'd1) : (pc + pc_offset);

  always_ff @(posedge clk_i) begin
    if (rst_i)         pc <= '0;
    else if (!stall_i) pc <= pc_next;
  end

  assign instr_addr_o = pc;

endmodule
