module data_mem
import memory_pkg::DATA_MEM_SIZE_BYTES;
import memory_pkg::DATA_MEM_SIZE_WORDS;
(
  input  logic        clk_i,
  input  logic        mem_req_i,
  input  logic        write_enable_i,
  input  logic [ 3:0] byte_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o
);

  logic [31:0] ram [DATA_MEM_SIZE_WORDS];

  // word index: drop the byte offset and the bits beyond the memory size
  logic [$clog2(DATA_MEM_SIZE_WORDS)-1:0] word_addr;
  assign word_addr = addr_i[$clog2(DATA_MEM_SIZE_BYTES)-1:2];

  always_ff @(posedge clk_i) begin
    if (mem_req_i && write_enable_i) begin
      for (int i = 0; i < 4; i++)
        if (byte_enable_i[i]) ram[word_addr][8*i +: 8] <= write_data_i[8*i +: 8];
    end
  end

  always_ff @(posedge clk_i) begin
    if (mem_req_i && !write_enable_i) read_data_o <= ram[word_addr];
  end

  assign ready_o = 1'b1;

endmodule
