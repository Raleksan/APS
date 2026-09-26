module register_file
(
  input  logic          clk_i,
  input  logic          write_enable_i,

  input  logic [ 4:0]   write_addr_i,
  input  logic [ 4:0]   read_addr1_i,
  input  logic [ 4:0]   read_addr2_i,

  input  logic [31:0]   write_data_i,
  output logic [31:0]   read_data1_o,
  output logic [31:0]   read_data2_o
);

    logic [31:0] rf_mem [31:0];

    initial begin
        for (int idx = 0; idx < 32; idx++) begin
            rf_mem [idx] = '0;
        end 
    end

    always_ff @(posedge clk_i) begin : wr_ff
        if (write_enable_i) begin
            rf_mem [write_addr_i] <= write_data_i;            
        end
    end

    always_comb begin : rd_comb
        read_data1_o = rf_mem [read_addr1_i];
        read_data1_o = rf_mem [read_addr2_i];
    end

endmodule : register_file
