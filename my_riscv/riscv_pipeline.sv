module riscv_pipeline(
  dualport_bus.master instr_master,
);
// 该模块用来实现流水线寄存器，并对于不同的基础组件进行连接

riscv_alu EX_alu(
  .i_opcode(i_opcodeE),
  .i_funct7(i_funct7E),
  .i_funct3(i_funct3E),
  .i_num1(i_num1E),
  .i_num2(i_num2E),
  .i_imm_num(i_imm_numE),
  .i_pc(i_pcE),
  .o_if_branch(o_if_branchE),
  .o_num(o_numE),
  .o_pc(o_pcE)
);

endmodule