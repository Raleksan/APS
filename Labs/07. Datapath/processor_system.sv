module processor_system(
  input  logic        clk_i,
  input  logic        rst_i
);

    logic [31:0] instr_addr_o;
    logic [31:0] instr;
    logic [31:0] mem_rd;
    logic [31:0] mem_addr;
    logic [31:0] mem_wd;
    logic        mem_req;
    logic        mem_we;
    logic        stall;
    logic        stall_reg;

    logic [2:0]  dummy_0;
    logic        dummy_1;

    assign stall = mem_req & ~stall_reg;

    always_ff @(posedge clk_i) begin : stall_ff
        if (rst_i) begin
            stall_reg <= 1'b0;
        end else begin
            stall_reg <= stall;
        end
    end

    instr_mem instr_mem (
    	.read_addr_i(instr_addr_o   ),
    	.read_data_o(instr          )
    );

    processor_core core (
    	.clk_i       (clk_i         ),
    	.rst_i       (rst_i         ),
    	.stall_i     (stall         ),
    	.instr_i     (instr         ),
    	.mem_rd_i    (mem_rd        ),
    	.instr_addr_o(instr_addr_o  ),
    	.mem_addr_o  (mem_addr      ),
    	.mem_size_o  (dummy_0       ),
    	.mem_req_o   (mem_req       ),
    	.mem_we_o    (mem_we        ),
    	.mem_wd_o    (mem_wd        )
    );

    data_mem data_mem (
    	.clk_i         (clk_i       ),
    	.mem_req_i     (mem_req     ),
    	.write_enable_i(mem_we      ),
    	.byte_enable_i (4'b1111     ),
    	.addr_i        (mem_addr    ),
    	.write_data_i  (mem_wd      ),
    	.read_data_o   (mem_rd      ),
    	.ready_o       (dummy_1     )
    );

endmodule
