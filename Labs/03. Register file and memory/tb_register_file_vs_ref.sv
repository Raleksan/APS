// Compares register_file with the Made-up reference (register_file_ref) every cycle.
module tb_register_file_vs_ref;
  logic        clk = 0, we;
  logic [ 4:0] wa, ra1, ra2;
  logic [31:0] wd, rd1, rd2, rd1_ref, rd2_ref;
  int errors = 0;

  register_file     dut (.clk_i(clk), .write_enable_i(we), .write_addr_i(wa), .read_addr1_i(ra1),
                         .read_addr2_i(ra2), .write_data_i(wd), .read_data1_o(rd1), .read_data2_o(rd2));
  register_file_ref gold(.clk_i(clk), .write_enable_i(we), .write_addr_i(wa), .read_addr1_i(ra1),
                         .read_addr2_i(ra2), .write_data_i(wd), .read_data1_o(rd1_ref), .read_data2_o(rd2_ref));

  always #5 clk = ~clk;

  task automatic check();
    #1;
    if (rd1 !== rd1_ref || rd2 !== rd2_ref) begin
      errors++;
      if (errors <= 10)
        $display("MISMATCH t=%0t ra1=%0d ra2=%0d: rd1=%h(ref %h) rd2=%h(ref %h)",
                 $time, ra1, ra2, rd1, rd1_ref, rd2, rd2_ref);
    end
  endtask

  task automatic step(input logic w, input logic [4:0] a, input logic [31:0] d,
                      input logic [4:0] r1, input logic [4:0] r2);
    we = w; wa = a; wd = d; ra1 = r1; ra2 = r2;
    check();          // combinational read before the edge
    @(posedge clk);
    check();          // and after the write lands
  endtask

  initial begin
    @(negedge clk);
    // every register: write a unique value, read it back on both ports with distinct addresses
    for (int i = 0; i < 32; i++) begin
      step(1, i, 32'hA5000000 | i, i, 31 - i);
      step(0, i, '0, 31 - i, i);
    end
    // x0 must stay zero; write_enable_i = 0 must not write
    step(1, 0, 32'hFFFF_FFFF, 0, 0);
    step(0, 5, 32'h1234_5678, 5, 0);
    for (int i = 0; i < 10000; i++) begin
      @(negedge clk);
      step($urandom_range(0, 1), $urandom, $urandom, $urandom, $urandom);
    end
    if (errors == 0) $display("PASS");
    else $fatal(1, "FAIL: %0d mismatches", errors);
    $finish;
  end
endmodule
