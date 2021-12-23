module riscv_alu(
  input logic [6:0] i_opcode,
  input logic [6:0] i_funct7,
  input logic [2:0] i_funct3,
  input logic [31:0] i_num1,
  input logic [31:0] i_num2,
  input logic [31:0] i_imm_num,
  input logic [31:0] i_pc,
  output logic o_if_branch,
  output logic [31:0] o_num,
  output logic [31:0] o_pc
);
// input and output for the alu
// i stand for input, o stand for output

// a complex alu for all functions, need processed imm input
// connect to register by datapath NOT YET
// don't get any control instructions
// these instruction will be processed by outsider module NOT YET



parameter OP_JAL    = 7'b1101111;
parameter OP_JALR   = 7'b1100111;
parameter OP_BRANCH = 7'b1100011;
parameter OP_BEQ    = 3'b000;
parameter OP_BNE    = 3'b001;
parameter OP_BLT    = 3'b100;
parameter OP_BGE    = 3'b101;
parameter OP_BLTU   = 3'b110;
parameter OP_BGEU   = 3'b111;

logic [ 4:0] shamt, shamt_rs;
logic [31:0] num1_plus_imm;
logic [31:0] pc_plus_imm;
logic signed [31:0] i_num1s, i_num2s, i_imm_nums;

assign shamt         = i_imm_num[4:0];
assign shamt_rs      = i_num2[4:0];
assign num1_plus_imm = i_num1 + i_imm_num;
assign pc_plus_imm   = i_pc + i_imm_num;
assign i_num1s       = i_num1;
assign i_num2s       = i_num2;
assign i_imm_nums    = i_imm_num;

// for JAL and BRANCH OPs, only handle o_if_branch and o_pc output
always_comb begin : PC_handle
  case(i_opcode)
    OP_JAL: begin
      o_if_branch <= 1'b1; //always jump for JAL 
      o_pc        <= i_imm_num; 
    end
    OP_JALR: begin
      o_if_branch <= 1'b1;
      o_pc        <= num1_plus_imm;
    end   
    OP_BRANCH: begin
      case(i_funct3)
        OP_BEQ:  o_if_branch <= (i_num1  == i_num2 );
        OP_BNE:  o_if_branch <= (i_num1  != i_num2 );
        OP_BLT:  o_if_branch <= (i_num1s <  i_num2s);
        OP_BGE:  o_if_branch <= (i_num1s >= i_num2s);
        OP_BLTU: o_if_branch <= (i_num1  <  i_num2 );
        OP_BGEU: o_if_branch <= (i_num1  >= i_num2 );
        default: o_if_branch <= 1'b0; // default not jump
      endcase
      o_pc        <= pc_plus_imm;
    end
    default: begin
      o_if_branch <= 1'b0; // default not jump
      o_pc        <= 32'b0;
    end
  endcase
end

// for all OPs, only handle o_num
always_comb begin : ONUM_handle
  casex({i_funct7,i_funct3,i_opcode})
    17'bxxxxxxx_xxx_0110111: o_num <= i_imm_num;     // LUI
    17'bxxxxxxx_xxx_0010111: o_num <= pc_plus_imm;   // AUIPC
    17'bxxxxxxx_xxx_110x111: o_num <= i_pc + 4;      // JAL and JALR
    17'bxxxxxxx_000_0010011: o_num <= num1_plus_imm; // ADDI
    17'bxxxxxxx_010_0010011: o_num <= (i_num1s < i_imm_nums) ? 1 : 0; //SLTI
    // just for compare, use sign-extension immediate num
    17'bxxxxxxx_011_0010011: o_num <= (i_num1 < i_imm_num) ? 1 : 0; //SLTIU
    17'bxxxxxxx_100_0010011: o_num <= i_num1 ^ i_imm_num; // XORI
    17'bxxxxxxx_110_0010011: o_num <= i_num1 | i_imm_num; // ORI
    17'bxxxxxxx_111_0010011: o_num <= i_num1 & i_imm_num; // ANDI
    17'b0000000_001_0010011: o_num <= i_num1 << shamt; // SLLI
    17'b0000000_101_0010011: o_num <= i_num1 >> shamt; // SRLI
    17'b0100000_101_0010011: o_num <= i_num1s >>> shamt; // SRAI
    17'b0000000_000_0110011: o_num <= i_num1 + i_num2; // ADD
    17'b0100000_000_0110011: o_num <= i_num1 - i_num2; // SUB
    17'b0000000_001_0110011: o_num <= i_num1 << shamt_rs; // SLL
    17'b0000000_010_0110011: o_num <= (i_num1s < i_num2s) ? 1 : 0; // SLT
    17'b0000000_011_0110011: o_num <= (i_num1 < i_num2) ? 1 : 0; // SLTU
    17'b0000000_100_0110011: o_num <= i_num1 ^ i_num2; // XOR
    17'b0000000_101_0110011: o_num <= i_num1 >> shamt_rs; // SRL
    17'b0100000_101_0110011: o_num <= i_num1s >>> shamt_rs; // SRA
    17'b0000000_110_0110011: o_num <= i_num1 | i_num2; // OR
    17'b0000000_111_0110011: o_num <= i_num1 & i_num2; // AND
    // FIXME NO fence ecall csr
    default:                 o_num <= 0; // output 0 for default
  endcase
end

endmodule


