// Compares csr_controller with the Made-up reference (csr_controller_ref) every cycle.
module tb_csr_vs_ref;
  import csr_pkg::*;

  logic        clk_i = 0, rst_i, trap_i, write_enable_i;
  logic [ 2:0] opcode_i;
  logic [11:0] addr_i;
  logic [31:0] pc_i, mcause_i, rs1_data_i, imm_data_i;
  logic [31:0] rd, g_rd, mie, g_mie, mepc, g_mepc, mtvec, g_mtvec;
  int errors = 0, cycles = 0;

  csr_controller dut (.clk_i, .rst_i, .trap_i, .opcode_i, .addr_i, .pc_i, .mcause_i, .rs1_data_i,
    .imm_data_i, .write_enable_i, .read_data_o(rd), .mie_o(mie), .mepc_o(mepc), .mtvec_o(mtvec));
  csr_controller_ref gold (.clk_i, .rst_i, .trap_i, .opcode_i, .addr_i, .pc_i, .mcause_i, .rs1_data_i,
    .imm_data_i, .write_enable_i, .read_data_o(g_rd), .mie_o(g_mie), .mepc_o(g_mepc), .mtvec_o(g_mtvec));

  always #5 clk_i = ~clk_i;

  task automatic report(string name, logic [31:0] got, logic [31:0] exp);
    errors++;
    if (errors <= 10)
      $display("MISMATCH t=%0t op=%0d addr=%h we=%b trap=%b %s: %h (ref %h)",
               $time, opcode_i, addr_i, write_enable_i, trap_i, name, got, exp);
  endtask

  always @(negedge clk_i) if (!rst_i) begin
    #4;
    cycles++;
    if (rd    !== g_rd)    report("read_data_o", rd, g_rd);
    if (mie   !== g_mie)   report("mie_o", mie, g_mie);
    if (mepc  !== g_mepc)  report("mepc_o", mepc, g_mepc);
    if (mtvec !== g_mtvec) report("mtvec_o", mtvec, g_mtvec);
  end

  logic [11:0] addrs [6] = '{MIE_ADDR, MTVEC_ADDR, MSCRATCH_ADDR, MEPC_ADDR, MCAUSE_ADDR, 12'h300};
  logic [ 2:0] ops   [8] = '{3'd0, CSR_RW, CSR_RS, CSR_RC, 3'd4, CSR_RWI, CSR_RSI, CSR_RCI};

  task automatic drive(input logic t, input logic w, input logic [2:0] op, input logic [11:0] a);
    trap_i = t; write_enable_i = w; opcode_i = op; addr_i = a;
    pc_i = $urandom; mcause_i = $urandom; rs1_data_i = $urandom; imm_data_i = $urandom;
    @(negedge clk_i);
  endtask

  initial begin
    {trap_i, write_enable_i, opcode_i, addr_i, pc_i, mcause_i, rs1_data_i, imm_data_i} = '0;
    rst_i = 1;
    repeat (2) @(posedge clk_i);
    @(negedge clk_i) rst_i = 0;
    // every address x every opcode, written then read back
    foreach (addrs[a])
      foreach (ops[o]) begin
        drive(0, 1, ops[o], addrs[a]);
        drive(0, 0, ops[o], addrs[a]);
      end
    // trap alone, and trap together with a software write to mepc / mcause
    drive(1, 0, CSR_RW, MEPC_ADDR);
    drive(0, 0, CSR_RW, MCAUSE_ADDR);
    drive(1, 1, CSR_RW, MEPC_ADDR);
    drive(1, 1, CSR_RW, MCAUSE_ADDR);
    drive(0, 0, CSR_RW, MCAUSE_ADDR);
    // reset clears everything
    rst_i = 1; @(negedge clk_i); rst_i = 0;
    for (int i = 0; i < 30000; i++)
      drive($urandom_range(0, 9) == 0, $urandom, ops[$urandom_range(0, 7)],
            $urandom_range(0, 7) == 0 ? 12'($urandom) : addrs[$urandom_range(0, 4)]);
    if (errors == 0) $display("PASS (%0d cycles)", cycles);
    else $fatal(1, "FAIL: %0d mismatches in %0d cycles", errors, cycles);
    $finish;
  end
endmodule
