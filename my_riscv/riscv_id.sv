module riscv_id(
  input logic [31:0] i_instr,

  output logic [6:0] o_opcode,
  output logic [6:0] o_funct7,
  output logic [2:0] o_funct3,
  output logic [31:0] o_imm_num,
  // data given to the alu directly

  output logic o_src1_reg_en,
  output logic o_src2_reg_en,
  output logic [4:0] o_src1_reg_addr, 
  output logic [4:0] o_src2_reg_addr,
  // data prepare for alu

  output logic o_jal,
  // check if jump, use to prepare the PC input for the alu
  // jal's target is specified by the immediate num
  // thus the pc can be changed next clock

  output logic o_alures2reg,
  // check whether alu output needs to write back

  output logic o_memory2reg,
  // LW LB LH op load data from memory to register

  output logic o_mem_write,
  // SB SH SW op write data to memory from register

  output logic [4:0] o_dst_reg_addr
  // destination for alu and load's output

);

// ID stage will split the input instruction
// prepare the immediate num for the EX stage
// generate the memory read and write control signal
// prepare the signal address for input and output data

parameter OP_LUI    = 7'b0110111;
parameter OP_AUIPC  = 7'b0010111;
parameter OP_JAL    = 7'b1101111;
parameter OP_JALR   = 7'b1100111;
parameter OP_BRANCH = 7'b1100011;
parameter OP_LOAD   = 7'b0000011;
parameter OP_STORE  = 7'b0100011;
parameter OP_ALI    = 7'b0010011; // arithmetic and logical I type
parameter OP_ALR    = 7'b0110011; // arithmetic and logical R type



assign {o_funct7, o_src2_reg_addr, o_src1_reg_addr, o_funct3, o_dst_reg_addr, o_opcode} = i_instr;
// assign memory address from the opcode

enum {UKNOWN_TYPE, R_TYPE, I_TYPE, S_TYPE, B_TYPE, U_TYPE, J_TYPE} instr_type;

assign o_jal = (o_opcode == OP_JAL);
assign o_memory2reg = (o_opcode == OP_LOAD);
assign o_mem_write = (o_opcode == OP_STORE);
assign o_alures2reg = (o_opcode == OP_LUI || o_opcode == OP_AUIPC ||
                       o_opcode == OP_JAL || o_opcode == OP_JALR ||
                       o_opcode == OP_ALI || o_opcode == OP_ALR )
// load op doesn't use alu
// store and branch op don't have an rd

always_comb begin
  case(o_opcode)
    OP_LUI : instr_type <= U_TYPE;
    OP_AUIPC : instr_type <= U_TYPE;
    OP_JAL : instr_type <= J_TYPE;
    OP_JALR : instr_type <= I_TYPE;
    OP_BRANCH : instr_type <= B_TYPE;
    OP_LOAD : instr_type <= L_TYPE;
    OP_STORE : instr_type <= S_TYPE;
    OP_ALI : instr_type <= I_TYPE;
    OP_ALR : instr_type <= R_TYPE;
  endcase
end
// decide the instruction type

always_comb begin
  case(instr_type)
    I_TYPE : o_imm_num <= {{20{i_instr[31]}}, i_instr[31:20]};
    S_TYPE : o_imm_num <= {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};
    B_TYPE : o_imm_num <= {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
    U_TYPE : o_imm_num <= {i_instr[31:12], 12'h0};
    J_TYPE : o_imm_num <= {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};
    default: o_imm_num <= 0;
  endcase
end
// R type instruction don't need a immediate num

always_comb begin
  case(instr_type)
    R_TYPE : {o_src2_reg_en, o_src1_reg_en} <= 2'b11;
    I_TYPE : {o_src2_reg_en, o_src1_reg_en} <= 2'b01;
    S_TYPE : {o_src2_reg_en, o_src1_reg_en} <= 2'b11;
    B_TYPE : {o_src2_reg_en, o_src1_reg_en} <= 2'b11;
    default: {o_src2_reg_en, o_src1_reg_en} <= 2'b00;
  endcase
end
  
endmodule

