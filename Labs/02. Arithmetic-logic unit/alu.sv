module alu 
(
    input  logic [31:0]     a_i,
    input  logic [31:0]     b_i,
    input  logic [4:0]      alu_op_i,
    output logic            flag_o,
    output logic [31:0]     result_o
);

    import alu_opcodes_pkg::*;

    logic [31:0] add_res;
    logic [31:0] sub_res;
    logic [31:0] sll_res;
    logic [31:0] xor_res;
    logic [31:0] srl_res;
    logic [31:0] sra_res;
    logic [31:0] or_res; 
    logic [31:0] and_res;

    logic [ 0:0] slts_res;
    logic [ 0:0] sltu_res;
    logic [ 0:0] eq_res;

    assign add_res   = a_i + b_i;
    assign sub_res   = a_i - b_i;
    assign sll_res   = a_i << b_i;
    assign xor_res   = a_i ^ b_i;
    assign srl_res   = a_i >> b_i;
    assign sra_res   = a_i >>> b_i;
    assign or_res    = a_i | b_i;
    assign and_res   = a_i & b_i;
    
    assign slts_res  = $signed(a_i) < $signed(b_i);
    assign sltu_res  = a_i < b_i;
    assign eq_res    = a_i == b_i;

    always_comb begin : result_sel
        case (alu_op_i)
            ALU_ADD  : result_o = add_res;
            ALU_SUB  : result_o = sub_res;

            ALU_XOR  : result_o = xor_res;
            ALU_OR   : result_o = or_res;
            ALU_AND  : result_o = and_res;

            ALU_SRA  : result_o = sra_res;
            ALU_SRL  : result_o = srl_res;
            ALU_SLL  : result_o = sll_res;

            ALU_SLTS : result_o = slts_res;
            ALU_SLTU : result_o = sltu_res;

            default  : result_o = '0;
        endcase : result_sel
    end

    always_comb begin : flag_sel
        case (alu_op_i)
            ALU_EQ  : flag_o = eq_res;
            ALU_NE  : flag_o = !eq_res;
            ALU_LTS : flag_o = slts_res;
            ALU_GES : flag_o = !slts_res;
            ALU_LTU : flag_o = sltu_res;
            ALU_GEU : flag_o = !sltu_res;

            default : flag_o = '0;
        endcase : flag_sel
    end

endmodule
