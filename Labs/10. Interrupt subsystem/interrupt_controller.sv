module interrupt_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic        irq_req_i,
  input  logic        mie_i,
  input  logic        mret_i,
  output logic        irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

  // set while an exception / interrupt handler runs
  logic exc_h, irq_h;

  // exceptions take priority; no new interrupt while any handler runs
  assign irq_o       = irq_req_i && mie_i && !(exception_i || exc_h || irq_h);
  // mret leaves the exception handler first, then the interrupt handler
  assign irq_ret_o   = mret_i && !exc_h;
  assign irq_cause_o = 32'h8000_0010;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      exc_h <= 1'b0;
      irq_h <= 1'b0;
    end else begin
      if (mret_i)           exc_h <= 1'b0;
      else if (exception_i) exc_h <= 1'b1;
      if (irq_ret_o)        irq_h <= 1'b0;
      else if (irq_o)       irq_h <= 1'b1;
    end
  end

endmodule
