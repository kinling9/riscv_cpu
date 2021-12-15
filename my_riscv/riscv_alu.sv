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
)
// input and output for the alu
// i stand for input, o stand for output


parameter OP_JAL    = 7'b1101111;
parameter OP_JALR   = 7'b1100111;
parameter OP_BRANCH = 7'b1100011;
parameter OP_BEQ    = 3'b000;
parameter OP_BNE    = 3'b001;
parameter OP_BLT    = 3'b100;
parameter OP_BGE    = 3'b101;
parameter OP_BLTU   = 3'b110;
parameter OP_BGEU   = 3'b111;

assign num1_plus_imm = i_num1 + i_imm_num;
assign pc_plus_imm   = i_pc + i_imm_num;


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
        OP_BEQ:  o_if_branch <= (i_num1 == i_num2);
        OP_BNE:  o_if_branch <= (i_num1 != i_num2);
        OP_BLT:  o_if_branch <= ($signed(i_num1) <  $signed(i_num2)); // maybe not synthesizable
        OP_BGE:  o_if_branch <= ($signed(i_num1) <  $signed(i_num2));
        OP_BLTU: o_if_branch <= (i_num1 <  i_num2);
        OP_BGEU: o_if_branch <= (i_num1 >= i_num2);
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
    17'bxxxxxxx_xxx_0110111: o_num <= i_imm_num;   // LUI
    17'bxxxxxxx_xxx_0010111: o_num <= pc_plus_imm; // AUIPC
    17'bxxxxxxx_xxx_110x111: o_num <= i_pc + 4;    // JAL and JALR



  
end



