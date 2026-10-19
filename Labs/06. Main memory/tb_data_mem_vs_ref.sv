// Compares data_mem with the Made-up reference (data_mem_ref) every cycle.
module tb_data_mem_vs_ref;
  import memory_pkg::*;

  logic        clk = 0, req, we;
  logic [ 3:0] be;
  logic [31:0] addr, wd, rd, g_rd;
  logic        ready, g_ready;
  int errors = 0, cycles = 0;

  data_mem     dut (.clk_i(clk), .mem_req_i(req), .write_enable_i(we), .byte_enable_i(be),
                    .addr_i(addr), .write_data_i(wd), .read_data_o(rd), .ready_o(ready));
  data_mem_ref gold(.clk_i(clk), .mem_req_i(req), .write_enable_i(we), .byte_enable_i(be),
                    .addr_i(addr), .write_data_i(wd), .read_data_o(g_rd), .ready_o(g_ready));

  always #5 clk = ~clk;

  task automatic cycle(input logic r, input logic w, input logic [3:0] b,
                       input logic [31:0] a, input logic [31:0] d);
    req = r; we = w; be = b; addr = a; wd = d;
    @(posedge clk); #1;
    cycles++;
    if (rd !== g_rd || ready !== g_ready) begin
      errors++;
      if (errors <= 10)
        $display("MISMATCH t=%0t req=%b we=%b be=%b addr=%h wd=%h: rd=%h(ref %h) ready=%b(ref %b)",
                 $time, r, w, b, a, d, rd, g_rd, ready, g_ready);
    end
  endtask

  initial begin
    // fill memory so unwritten-cell init differences do not matter
    for (int i = 0; i < DATA_MEM_SIZE_WORDS; i++) cycle(1, 1, 4'hF, i * 4, $urandom);
    // every byte_enable value on one word, read back after each
    for (int b = 0; b < 16; b++) begin
      cycle(1, 1, b, 32'h8, $urandom);
      cycle(1, 0, $urandom, 32'h8, $urandom);
    end
    // first/last word, byte offsets, addresses beyond the memory size wrap
    cycle(1, 0, 0, 0, 0);
    cycle(1, 0, 0, DATA_MEM_SIZE_BYTES - 4, 0);
    cycle(1, 1, 4'hF, DATA_MEM_SIZE_BYTES + 4, 32'hDEAD_BEEF);  // wraps to word 1
    cycle(1, 0, 0, 32'h4, 0);
    cycle(1, 0, 0, 32'hFFFF_FFFC, 0);
    // no request: no write, read data holds; write without request
    cycle(0, 1, 4'hF, 32'h4, 32'h1111_1111);
    cycle(0, 0, 4'hF, 32'h8, 0);
    cycle(1, 0, 0, 32'h4, 0);
    for (int i = 0; i < 20000; i++)
      cycle($urandom_range(0, 3) != 0, $urandom_range(0, 1), $urandom, $urandom, $urandom);
    if (errors == 0) $display("PASS (%0d cycles)", cycles);
    else $fatal(1, "FAIL: %0d mismatches in %0d cycles", errors, cycles);
    $finish;
  end
endmodule
