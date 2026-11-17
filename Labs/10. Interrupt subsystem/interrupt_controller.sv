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

    // handling flags
    logic        exc_h;
    logic        irq_h;

    // mret ends the exception first, the interrupt only after it
    always_ff @(posedge clk_i) begin : exc_h_ff
        if (rst_i | mret_i) begin
            exc_h <= 1'b0;
        end else if (exception_i) begin
            exc_h <= 1'b1;
        end
    end

    always_ff @(posedge clk_i) begin : irq_h_ff
        if (rst_i | irq_ret_o) begin
            irq_h <= 1'b0;
        end else if (irq_o) begin
            irq_h <= 1'b1;
        end
    end

    // Exception wins, no nesting while any trap is handled
    assign irq_o     = irq_req_i & mie_i & ~(exception_i | exc_h | irq_h);
    assign irq_ret_o = mret_i & ~exc_h;

    // Outputs mapping
    assign irq_cause_o = 32'h8000_0010;

endmodule : interrupt_controller
