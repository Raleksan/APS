// Compares interrupt_controller with the Made-up reference (interrupt_controller_ref) every cycle.
// exception_i and mret_i are never driven together: README says this cannot happen.
module tb_irq_vs_ref;
  logic        clk_i = 0, rst_i, exception_i, irq_req_i, mie_i, mret_i;
  logic        irq_ret, g_irq_ret, irq, g_irq;
  logic [31:0] cause, g_cause;
  int errors = 0, cycles = 0;

  interrupt_controller dut (.clk_i, .rst_i, .exception_i, .irq_req_i, .mie_i, .mret_i,
    .irq_ret_o(irq_ret), .irq_cause_o(cause), .irq_o(irq));
  interrupt_controller_ref gold (.clk_i, .rst_i, .exception_i, .irq_req_i, .mie_i, .mret_i,
    .irq_ret_o(g_irq_ret), .irq_cause_o(g_cause), .irq_o(g_irq));

  always #5 clk_i = ~clk_i;

  always @(negedge clk_i) if (!rst_i) begin
    #4;
    cycles++;
    if (irq !== g_irq || irq_ret !== g_irq_ret || cause !== g_cause) begin
      errors++;
      if (errors <= 10)
        $display("MISMATCH t=%0t exc=%b req=%b mie=%b mret=%b: irq=%b(ref %b) irq_ret=%b(ref %b) cause=%h(ref %h)",
                 $time, exception_i, irq_req_i, mie_i, mret_i, irq, g_irq, irq_ret, g_irq_ret, cause, g_cause);
    end
  end

  task automatic drive(input logic [3:0] v);  // {exception, irq_req, mie, mret}
    {exception_i, irq_req_i, mie_i, mret_i} = v;
    if (exception_i) mret_i = 0;
    @(negedge clk_i);
  endtask

  initial begin
    {exception_i, irq_req_i, mie_i, mret_i} = '0;
    rst_i = 1;
    repeat (2) @(posedge clk_i);
    @(negedge clk_i) rst_i = 0;
    // directed: interrupt, exception inside the interrupt handler, two mrets
    drive(4'b0110); drive(4'b0000); drive(4'b1000); drive(4'b0110);
    drive(4'b0001); drive(4'b0110); drive(4'b0001); drive(4'b0110); drive(4'b0001);
    // masked request, request during the handler, irq together with mret
    drive(4'b0100); drive(4'b0110); drive(4'b0111); drive(4'b0111); drive(4'b0000);
    // every input combination from whatever state the random walk reaches
    for (int i = 0; i < 50000; i++) begin
      if ($urandom_range(0, 999) == 0) begin rst_i = 1; @(negedge clk_i); rst_i = 0; end
      drive($urandom);
    end
    if (errors == 0) $display("PASS (%0d cycles)", cycles);
    else $fatal(1, "FAIL: %0d mismatches in %0d cycles", errors, cycles);
    $finish;
  end
endmodule
