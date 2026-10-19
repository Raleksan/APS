module csr_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        trap_i,
  input  logic [ 2:0] opcode_i,
  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,
  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);
import csr_pkg::*;

  logic [31:0] mie, mtvec, mscratch, mepc, mcause;
  logic [31:0] write_data;

  always_comb begin
    case (opcode_i)
      CSR_RW:  write_data = rs1_data_i;
      CSR_RS:  write_data = read_data_o |  rs1_data_i;
      CSR_RC:  write_data = read_data_o & ~rs1_data_i;
      CSR_RWI: write_data = imm_data_i;
      CSR_RSI: write_data = read_data_o |  imm_data_i;
      CSR_RCI: write_data = read_data_o & ~imm_data_i;
      default: write_data = '0;
    endcase
  end

  always_comb begin
    case (addr_i)
      MIE_ADDR:      read_data_o = mie;
      MTVEC_ADDR:    read_data_o = mtvec;
      MSCRATCH_ADDR: read_data_o = mscratch;
      MEPC_ADDR:     read_data_o = mepc;
      MCAUSE_ADDR:   read_data_o = mcause;
      default:       read_data_o = '0;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      mie      <= '0;
      mtvec    <= '0;
      mscratch <= '0;
      mepc     <= '0;
      mcause   <= '0;
    end else begin
      if (write_enable_i && addr_i == MIE_ADDR)      mie      <= write_data;
      if (write_enable_i && addr_i == MTVEC_ADDR)    mtvec    <= write_data;
      if (write_enable_i && addr_i == MSCRATCH_ADDR) mscratch <= write_data;
      // a trap overrides software writes to mepc and mcause
      if (trap_i)                                    mepc     <= pc_i;
      else if (write_enable_i && addr_i == MEPC_ADDR) mepc    <= write_data;
      if (trap_i)                                      mcause <= mcause_i;
      else if (write_enable_i && addr_i == MCAUSE_ADDR) mcause <= write_data;
    end
  end

  assign mie_o   = mie;
  assign mepc_o  = mepc;
  assign mtvec_o = mtvec;

endmodule
