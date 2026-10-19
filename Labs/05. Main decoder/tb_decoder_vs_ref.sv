// Compares decoder with the Made-up reference (decoder_ref).
// Don't-care masks are copied from lab_05.tb_decoder.sv:441-456.
module tb_decoder_vs_ref;
  import decoder_pkg::*;

  logic [31:0] instr;
  logic [1:0]  a_sel,   g_a_sel;
  logic [2:0]  b_sel,   g_b_sel;
  logic [4:0]  alu_op,  g_alu_op;
  logic [2:0]  csr_op,  g_csr_op;
  logic        csr_we,  g_csr_we;
  logic        mem_req, g_mem_req;
  logic        mem_we,  g_mem_we;
  logic [2:0]  mem_size,g_mem_size;
  logic        gpr_we,  g_gpr_we;
  logic [1:0]  wb_sel,  g_wb_sel;
  logic        illegal, g_illegal;
  logic        branch,  g_branch;
  logic        jal,     g_jal;
  logic        jalr,    g_jalr;
  logic        mret,    g_mret;
  int errors = 0, checks = 0;

  decoder dut (.fetched_instr_i(instr), .a_sel_o(a_sel), .b_sel_o(b_sel), .alu_op_o(alu_op),
    .csr_op_o(csr_op), .csr_we_o(csr_we), .mem_req_o(mem_req), .mem_we_o(mem_we),
    .mem_size_o(mem_size), .gpr_we_o(gpr_we), .wb_sel_o(wb_sel), .illegal_instr_o(illegal),
    .branch_o(branch), .jal_o(jal), .jalr_o(jalr), .mret_o(mret));

  decoder_ref gold (.fetched_instr_i(instr), .a_sel_o(g_a_sel), .b_sel_o(g_b_sel), .alu_op_o(g_alu_op),
    .csr_op_o(g_csr_op), .csr_we_o(g_csr_we), .mem_req_o(g_mem_req), .mem_we_o(g_mem_we),
    .mem_size_o(g_mem_size), .gpr_we_o(g_gpr_we), .wb_sel_o(g_wb_sel), .illegal_instr_o(g_illegal),
    .branch_o(g_branch), .jal_o(g_jal), .jalr_o(g_jalr), .mret_o(g_mret));

  task automatic report(string name, logic [31:0] got, logic [31:0] exp);
    errors++;
    if (errors <= 10) $display("MISMATCH instr=%h %s: %h (ref %h)", instr, name, got, exp);
  endtask

  task automatic check(input logic [31:0] i);
    logic [4:0] op;
    logic [2:0] f3;
    instr = i;
    #1;
    checks++;
    op = instr[6:2];
    f3 = instr[14:12];
    if (illegal !== g_illegal) report("illegal_instr_o", illegal, g_illegal);
    if (!(op inside {MISC_MEM_OPCODE, SYSTEM_OPCODE})) begin
      if (a_sel  !== g_a_sel)  report("a_sel_o",  a_sel,  g_a_sel);
      if (b_sel  !== g_b_sel)  report("b_sel_o",  b_sel,  g_b_sel);
      if (alu_op !== g_alu_op) report("alu_op_o", alu_op, g_alu_op);
    end
    if (op == SYSTEM_OPCODE && f3 != 3'd0 && csr_op !== g_csr_op) report("csr_op_o", csr_op, g_csr_op);
    if (op inside {LOAD_OPCODE, STORE_OPCODE} && mem_size !== g_mem_size) report("mem_size_o", mem_size, g_mem_size);
    if (!(op inside {STORE_OPCODE, MISC_MEM_OPCODE, BRANCH_OPCODE}) && (op != SYSTEM_OPCODE || f3 != 3'd0)
        && wb_sel !== g_wb_sel) report("wb_sel_o", wb_sel, g_wb_sel);
    if (csr_we  !== g_csr_we)  report("csr_we_o",  csr_we,  g_csr_we);
    if (mem_req !== g_mem_req) report("mem_req_o", mem_req, g_mem_req);
    if (mem_we  !== g_mem_we)  report("mem_we_o",  mem_we,  g_mem_we);
    if (gpr_we  !== g_gpr_we)  report("gpr_we_o",  gpr_we,  g_gpr_we);
    if (branch  !== g_branch)  report("branch_o",  branch,  g_branch);
    if (jal     !== g_jal)     report("jal_o",     jal,     g_jal);
    if (jalr    !== g_jalr)    report("jalr_o",    jalr,    g_jalr);
    if (mret    !== g_mret)    report("mret_o",    mret,    g_mret);
  endtask

  initial begin
    logic [6:0] f7s [4] = '{7'h00, 7'h20, 7'h01, 7'h7f};
    // every opcode x low bits x func3 x interesting func7
    for (int op = 0; op < 32; op++)
      for (int lo = 0; lo < 4; lo++)
        for (int f3 = 0; f3 < 8; f3++)
          foreach (f7s[k])
            check({f7s[k], 5'($urandom), 5'($urandom), 3'(f3), 5'($urandom), 5'(op), 2'(lo)});
    // whole-word SYSTEM instructions and their one-bit neighbours
    check(32'h0000_0073); check(32'h0010_0073); check(32'h3020_0073);
    for (int b = 0; b < 32; b++) begin
      check(32'h3020_0073 ^ (32'b1 << b));
      check(32'h0000_0073 ^ (32'b1 << b));
      check(32'h0010_0073 ^ (32'b1 << b));
    end
    // random fields on valid opcodes, then fully random words
    for (int i = 0; i < 100000; i++)
      check({$urandom} & 32'hFFFF_FF83 | {25'b0, 5'($urandom_range(0, 31)), 2'b11});
    for (int i = 0; i < 100000; i++) check($urandom);
    if (errors == 0) $display("PASS (%0d instructions)", checks);
    else $fatal(1, "FAIL: %0d mismatches in %0d instructions", errors, checks);
    $finish;
  end
endmodule
