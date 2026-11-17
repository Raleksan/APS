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
    logic [31:0] pc_next;

    // decoder
    logic [1:0]  a_sel;
    logic [2:0]  b_sel;
    logic [4:0]  alu_op;
    logic [2:0]  csr_op;
    logic        csr_we;
    logic        gpr_we;
    logic [1:0]  wb_sel;
    logic        illegal_instr;
    logic        branch;
    logic        jal;
    logic        jalr;
    logic        mret;

    // register file
    logic        rf_we;
    logic [31:0] wb_data;
    logic [31:0] rd1;
    logic [31:0] rd2;

    // alu
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic        flag;
    logic [31:0] alu_res;

    // immediates
    logic [31:0] imm_I;
    logic [31:0] imm_U;
    logic [31:0] imm_S;
    logic [31:0] imm_B;
    logic [31:0] imm_J;

    // register jump
    logic [31:0] jalr_target;
    logic [31:0] pc_offset;


    always_ff @(posedge clk_i) begin : pc_ff
        if (rst_i) begin
            pc <= '0;
        end else if (!stall_i) begin
            pc <= pc_next;
        end
    end

    decoder decoder (
    	.fetched_instr_i(instr_i),
    	.a_sel_o        (a_sel),
    	.b_sel_o        (b_sel),
    	.alu_op_o       (alu_op),
    	.csr_op_o       (csr_op),
    	.csr_we_o       (csr_we),
    	.mem_req_o      (mem_req_o),
    	.mem_we_o       (mem_we_o),
    	.mem_size_o     (mem_size_o),
    	.gpr_we_o       (gpr_we),
    	.wb_sel_o       (wb_sel),
    	.illegal_instr_o(illegal_instr),
    	.branch_o       (branch),
    	.jal_o          (jal),
    	.jalr_o         (jalr),
    	.mret_o         (mret)
    );

    register_file register_file (
    	.clk_i         (clk_i),
    	.write_enable_i(rf_we),
    	.write_addr_i  (instr_i[11:7]),
    	.read_addr1_i  (instr_i[19:15]),
    	.read_addr2_i  (instr_i[24:20]),
    	.write_data_i  (wb_data),
    	.read_data1_o  (rd1),
    	.read_data2_o  (rd2)
    );

    alu alu (
    	.a_i     (alu_a),
    	.b_i     (alu_b),
    	.alu_op_i(alu_op),
    	.flag_o  (flag),
    	.result_o(alu_res)
    );

    // Immediates
    assign imm_I = {{20{instr_i[31]}}, instr_i[31:20]};
    assign imm_U = {instr_i[31:12], 12'h000};
    assign imm_S = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
    assign imm_B = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
    assign imm_J = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

    always_comb begin : alu_a_mux
        case (a_sel)
            OP_A_RS1     : alu_a = rd1;
            OP_A_CURR_PC : alu_a = pc;
            default      : alu_a = '0;    // OP_A_ZERO
        endcase
    end

    always_comb begin : alu_b_mux
        case (b_sel)
            OP_B_RS2   : alu_b = rd2;
            OP_B_IMM_I : alu_b = imm_I;
            OP_B_IMM_U : alu_b = imm_U;
            OP_B_IMM_S : alu_b = imm_S;
            default    : alu_b = 32'd4;   // OP_B_INCR
        endcase
    end

    always_comb begin : wb_mux
        case (wb_sel)
            WB_LSU_DATA : wb_data = mem_rd_i;
            default     : wb_data = alu_res;
        endcase
    end

    assign rf_we = gpr_we & ~stall_i;
    assign jalr_target = rd1 + imm_I;
    assign pc_offset   = (branch & flag) ? imm_B :
                         jal             ? imm_J :
                                           32'd4;
    assign pc_next     = jalr ? {jalr_target[31:1], 1'b0} : pc + pc_offset;

    // Outputs mapping
    assign instr_addr_o = pc;
    assign mem_addr_o   = alu_res;
    assign mem_wd_o     = rd2;

endmodule
