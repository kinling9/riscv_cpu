module riscv_alu(
  input logic [6:0] i_opcode,
  input logic [6:0] i_funct7,
  input logic [31:0] i_num1,
  input logic [31:0] i_num2,
  input logic [31:0] i_imm_num,
  input logic [31:0] i_pc,
  output logic o_if_branch,
  output logic [31:0] o_num,
  output logic [31:0] o_pc
)
// input and output for the alu