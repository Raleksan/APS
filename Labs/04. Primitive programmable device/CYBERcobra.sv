module CYBERcobra (
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [15:0]  sw_i,
  output logic [31:0]  out_o
);
    // Program counter
    logic [31:0] pc;
    logic [31:0] pc_next;

    logic [0:0]  pc_sel;
    logic [31:0] offset_se;

    // Undecoded instruction
    logic [31:0] instr;

    // Instruction decode
    logic [4:0] write_addr;
    logic [7:0] offset_const;
    logic [4:0] read_addr_1;
    logic [4:0] read_addr_2;
    logic [4:0] alu_op;
    logic [1:0] write_source;
    logic [0:0] branch;
    logic [0:0] jump;

    logic [22:0] rf_const;

    // Register file
    logic [0:0] write_enable;

    logic [31:0] write_data;
    logic [31:0] read_data1;
    logic [31:0] read_data2;

    // ALU
    logic [0:0]  alu_flag;
    logic [31:0] alu_result;

    // Program counter
    always_ff @(posedge clk_i) begin : pc_ff
        if (rst_i)
            pc <= '0;
        else
            pc <= pc_next;
    end

    always_comb begin : pc_next_comb
        case (pc_sel)
            1'b0 : pc_next = pc + 32'd4;
            1'b1 : pc_next = pc + offset_se;
            default : pc_next = 'z;
        endcase
    end

    assign offset_se = {{22 {offset_const[7]}}, offset_const, 2'b00 };
    assign pc_sel = jump | (branch & alu_flag);

    // Instrcution memory
    instr_mem imem (
        .read_addr_i(pc),
        .read_data_o(instr)
    );

    // Instruction decode
    assign {jump, branch, write_source, alu_op, read_addr_1, read_addr_2, offset_const, write_addr} = instr;
    assign rf_const = instr [27:5];

    // Register file
    register_file register_file_inst (
    	.clk_i         (clk_i       ),
    	.write_enable_i(write_enable),
    	.write_addr_i  (write_addr  ),
    	.read_addr1_i  (read_addr_1 ),
    	.read_addr2_i  (read_addr_2 ),
    	.write_data_i  (write_data  ),
    	.read_data1_o  (read_data1  ),
    	.read_data2_o  (read_data2  )
    );

    assign write_enable = ~(branch | jump);

    always_comb begin
        case (write_source)
            2'b00 : write_data = { {9 {rf_const[22]}}, rf_const };
            2'b01 : write_data = alu_result;
            2'b10 : write_data = { {16 {sw_i[15]}}, sw_i };
            2'b11 : write_data = 32'b0;
            default : write_data = 'z;
        endcase
    end

    // ALU
    alu alu_inst (
    	.a_i     (read_data1),
    	.b_i     (read_data2),
    	.alu_op_i(alu_op    ),
    	.flag_o  (alu_flag  ),
    	.result_o(alu_result)
    );

    // Outputs
    assign out_o = read_data1;

endmodule : CYBERcobra
