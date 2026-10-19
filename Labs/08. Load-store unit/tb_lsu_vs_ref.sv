// Compares lsu with the Made-up reference (lsu_ref) every cycle.
// Stimulus and check masks follow lab_08.tb_lsu.sv (inputs change only while not stalled).
module tb_lsu_vs_ref;
  import decoder_pkg::*;

  logic        clk_i = 0, rst_i;
  logic        core_req_i, core_we_i, mem_ready_i;
  logic [ 2:0] core_size_i;
  logic [31:0] core_addr_i, core_wd_i, mem_rd_i;
  logic [31:0] rd, g_rd, addr, g_addr, wd, g_wd;
  logic        stall, g_stall, req, g_req, we, g_we;
  logic [ 3:0] be, g_be;
  int errors = 0, cycles = 0;

  lsu dut (.clk_i, .rst_i, .core_req_i, .core_we_i, .core_size_i, .core_addr_i, .core_wd_i,
    .core_rd_o(rd), .core_stall_o(stall), .mem_req_o(req), .mem_we_o(we), .mem_be_o(be),
    .mem_addr_o(addr), .mem_wd_o(wd), .mem_rd_i, .mem_ready_i);
  lsu_ref gold (.clk_i, .rst_i, .core_req_i, .core_we_i, .core_size_i, .core_addr_i, .core_wd_i,
    .core_rd_o(g_rd), .core_stall_o(g_stall), .mem_req_o(g_req), .mem_we_o(g_we), .mem_be_o(g_be),
    .mem_addr_o(g_addr), .mem_wd_o(g_wd), .mem_rd_i, .mem_ready_i);

  always #5 clk_i = ~clk_i;

  task automatic report(string name, logic [31:0] got, logic [31:0] exp);
    errors++;
    if (errors <= 10)
      $display("MISMATCH t=%0t req=%b we=%b size=%0d addr=%h %s: %h (ref %h)",
               $time, core_req_i, core_we_i, core_size_i, core_addr_i, name, got, exp);
  endtask

  // sampled just before each rising edge, like the official tb's assertions
  always @(negedge clk_i) if (!rst_i) begin
    #4;
    cycles++;
    if (stall !== g_stall) report("core_stall_o", stall, g_stall);
    if (req   !== g_req)   report("mem_req_o", req, g_req);
    if (we    !== g_we)    report("mem_we_o", we, g_we);
    if (core_req_i && addr !== g_addr) report("mem_addr_o", addr, g_addr);
    if (core_req_i && !core_we_i && rd !== g_rd) report("core_rd_o", rd, g_rd);
    if (core_req_i &&  core_we_i && be !== g_be) report("mem_be_o", be, g_be);
    if (core_req_i &&  core_we_i && wd !== g_wd) report("mem_wd_o", wd, g_wd);
  end

  logic [2:0] wsizes [3] = '{LDST_B, LDST_H, LDST_W};
  logic [2:0] rsizes [5] = '{LDST_B, LDST_H, LDST_W, LDST_BU, LDST_HU};

  // one request held until the stall drops; ready pattern chosen per cycle
  task automatic request(input logic w, input logic [2:0] size, input logic [31:0] a, input int ready_mode);
    core_req_i = 1; core_we_i = w; core_size_i = size; core_addr_i = a;
    core_wd_i = $urandom; mem_rd_i = $urandom;
    do begin
      mem_ready_i = ready_mode == 0 ? 1'b1 : ready_mode == 1 ? 1'b0 : 1'($urandom);
      @(negedge clk_i);
      if (ready_mode == 1) ready_mode = 0;  // wait one extra cycle, then ready
    end while (g_stall);
    core_req_i = 0;
  endtask

  initial begin
    {core_req_i, core_we_i, core_size_i, core_addr_i, core_wd_i, mem_rd_i, mem_ready_i} = '0;
    rst_i = 1;
    repeat (2) @(posedge clk_i);
    @(negedge clk_i) rst_i = 0;
    // directed: every size x every byte offset, loads and stores, three ready patterns
    for (int m = 0; m < 3; m++)
      for (int off = 0; off < 4; off++) begin
        foreach (wsizes[k]) request(1, wsizes[k], {$urandom} & ~32'h3 | off, m);
        foreach (rsizes[k]) request(0, rsizes[k], {$urandom} & ~32'h3 | off, m);
      end
    // back-to-back requests without an idle cycle
    for (int i = 0; i < 20; i++) begin
      core_req_i = 1; core_we_i = 0; core_size_i = LDST_W; core_addr_i = $urandom; mem_ready_i = 1;
      @(negedge clk_i);
    end
    // reset in the middle of a request
    core_req_i = 1; mem_ready_i = 0; @(negedge clk_i);
    rst_i = 1; @(negedge clk_i); rst_i = 0; core_req_i = 0; @(negedge clk_i);
    // random traffic in the official tb style
    for (int i = 0; i < 30000; i++) begin
      @(negedge clk_i);
      if (!g_stall) begin
        core_req_i = $urandom; core_we_i = $urandom;
        core_size_i = core_we_i ? wsizes[$urandom_range(0, 2)] : rsizes[$urandom_range(0, 4)];
        core_addr_i = $urandom; core_wd_i = $urandom; mem_rd_i = $urandom;
      end
      mem_ready_i = $urandom;
    end
    if (errors == 0) $display("PASS (%0d cycles)", cycles);
    else $fatal(1, "FAIL: %0d mismatches in %0d cycles", errors, cycles);
    $finish;
  end
endmodule
