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

    logic [31:0] mie;
    logic [31:0] mtvec;
    logic [31:0] mscratch;
    logic [31:0] mepc;
    logic [31:0] mcause;

    logic [31:0] wd;

    // write enables
    logic        mie_we;
    logic        mtvec_we;
    logic        mscratch_we;
    logic        mepc_we;
    logic        mcause_we;

    always_comb begin : wd_mux
        case (opcode_i)
            CSR_RW  : wd = rs1_data_i;
            CSR_RS  : wd = read_data_o | rs1_data_i;
            CSR_RC  : wd = read_data_o & ~rs1_data_i;
            CSR_RWI : wd = imm_data_i;
            CSR_RSI : wd = read_data_o | imm_data_i;
            CSR_RCI : wd = read_data_o & ~imm_data_i;
            default : wd = '0;
        endcase
    end

    always_comb begin : we_demux
        mie_we      = 1'b0;
        mtvec_we    = 1'b0;
        mscratch_we = 1'b0;
        mepc_we     = 1'b0;
        mcause_we   = 1'b0;
        case (addr_i)
            MIE_ADDR      : mie_we      = write_enable_i;
            MTVEC_ADDR    : mtvec_we    = write_enable_i;
            MSCRATCH_ADDR : mscratch_we = write_enable_i;
            MEPC_ADDR     : mepc_we     = write_enable_i;
            MCAUSE_ADDR   : mcause_we   = write_enable_i;
            default       : ;
        endcase
    end

    always_ff @(posedge clk_i) begin : csr_ff
        if (rst_i) begin
            mie      <= '0;
            mtvec    <= '0;
            mscratch <= '0;
            mepc     <= '0;
            mcause   <= '0;
        end else begin
            if (mie_we)      mie      <= wd;
            if (mtvec_we)    mtvec    <= wd;
            if (mscratch_we) mscratch <= wd;
            // Trap saves pc and cause right away
            if (trap_i)       mepc   <= pc_i;
            else if (mepc_we) mepc   <= wd;
            if (trap_i)         mcause <= mcause_i;
            else if (mcause_we) mcause <= wd;
        end
    end

    always_comb begin : rd_mux
        case (addr_i)
            MIE_ADDR      : read_data_o = mie;
            MTVEC_ADDR    : read_data_o = mtvec;
            MSCRATCH_ADDR : read_data_o = mscratch;
            MEPC_ADDR     : read_data_o = mepc;
            MCAUSE_ADDR   : read_data_o = mcause;
            default       : read_data_o = '0;
        endcase
    end

    // Outputs mapping
    assign mie_o   = mie;
    assign mepc_o  = mepc;
    assign mtvec_o = mtvec;

endmodule : csr_controller
