module CYBERcobra (
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [15:0]  sw_i,
  output logic [31:0]  out_o
);

  logic [31:0] pc;
  logic [31:0] instr;
  logic [31:0] rd1, rd2;
  logic [31:0] alu_result;
  logic        alu_flag;
  logic [31:0] wb_data;
  logic [31:0] pc_incr;
  logic [31:0] pc_next;

  // instruction fields
  logic        j, b;
  logic [ 1:0] ws;
  logic [ 4:0] alu_op, ra1, ra2, wa;
  logic [ 7:0] offset;
  logic [22:0] rf_const;

  assign j        = instr[31];
  assign b        = instr[30];
  assign ws       = instr[29:28];
  assign alu_op   = instr[27:23];
  assign ra1      = instr[22:18];
  assign ra2      = instr[17:13];
  assign offset   = instr[12:5];
  assign rf_const = instr[27:5];
  assign wa       = instr[4:0];

  instr_mem imem (
    .read_addr_i (pc),
    .read_data_o (instr)
  );

  register_file rf (
    .clk_i          (clk_i),
    .write_enable_i (!(j || b)),
    .write_addr_i   (wa),
    .read_addr1_i   (ra1),
    .read_addr2_i   (ra2),
    .write_data_i   (wb_data),
    .read_data1_o   (rd1),
    .read_data2_o   (rd2)
  );

  alu alu (
    .a_i      (rd1),
    .b_i      (rd2),
    .alu_op_i (alu_op),
    .flag_o   (alu_flag),
    .result_o (alu_result)
  );

  always_comb begin
    case (ws)
      2'd0:    wb_data = {{9{rf_const[22]}}, rf_const};
      2'd1:    wb_data = alu_result;
      2'd2:    wb_data = {16'b0, sw_i};
      default: wb_data = '0;
    endcase
  end

  assign pc_incr = (j || (b && alu_flag)) ? {{22{offset[7]}}, offset, 2'b00} : 32'd4;

  fulladder32 pc_adder (
    .a_i     (pc),
    .b_i     (pc_incr),
    .carry_i (1'b0),
    .sum_o   (pc_next),
    .carry_o ()
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) pc <= '0;
    else       pc <= pc_next;
  end

  assign out_o = rd1;

endmodule
