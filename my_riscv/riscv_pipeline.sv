module riscv_pipeline(
  input logic clk,
  input logic rst_n,
  input logic [31:0] i_boot_addr,
  dualport_bus.master instr_master,
  dualport_bus.master mem_master
);
// 该模块用来实现流水线寄存器，并对于不同的基础组件进行连接

logic [31:0] mem_addrE; 

riscv_if IF_if(
  .clk(clk),//*
  .rst_n(rst_n),//*
  .i_ex_jmp(ex_branchM),//*
  .i_id_jmp(i_id_jmpF),
  .i_stall(i_stallF),
  .i_boot_addr(i_boot_addr),//*
  .i_ex_target(ex_targetM),//*
  .i_id_target(i_id_targetF), 
  .o_pc(o_pcF),//*
  .o_instr(o_instrF),//*
  .instr_master(instr_master)//*
);

floprc #(32) instrFD(clk,rst_n,flushFD,o_instrF,i_instrD);
floprc #(32) instrFD(clk,rst_n,flushFD,o_instrF,i_instrD);
floprc #(32) pcFD(clk,rst_n,flushFD,o_pcF,pcD);

riscv_id ID_id(
  .i_instr(i_instrD),
  .o_opcode(o_opcodeD),//*
  .o_funct7(o_funct7D),//*
  .o_funct3(o_funct3D),//*
  .o_imm_num(o_imm_numD),//*
  .o_src1_reg_en(o_src1_reg_enD),//*
  .o_src2_reg_en(o_src2_reg_enD),//*
  .o_src1_reg_addr(o_src1_reg_addrD),//*
  .o_src2_reg_addr(o_src2_reg_addrD),//*
  .o_jal(o_jalD),
  .o_alures2reg(o_alures2regD),
  .o_memory2reg(o_memory2regD),
  .o_mem_write(o_mem_writeD),
  .o_dst_reg_addr(o_dst_reg_addrD)
);

riscv_reg ID_reg (
  .clk(clk),//*
  .rst_n(rst_n),//*
  .i_re1(o_src1_reg_enD),//*
  .i_raddr1(o_src1_reg_addrD),//*
  .i_re2(o_src2_reg_enD),//*
  .i_raddr2(o_src2_reg_addrD),//*
  .i_we(i_weD),
  .i_waddr(i_waddrD),
  .i_wdata(i_wdataD),
  .o_rdata1(o_rdata1D),//*
  .o_rdata2(o_rdata2D)//*
);

floprc #(7) opcodeDE(clk,rst_n,flushDE,o_opcodeD,i_opcodeE);
floprc #(7) funct7DE(clk,rst_n,flushDE,o_funct7D,i_funct7E);
floprc #(3) funct3DE(clk,rst_n,flushDE,o_funct3D,i_funct3E);
floprc #(32) imm_numDE(clk,rst_n,flushDE,o_imm_numD,i_imm_numE);
floprc #(32) num1DE(clk,rst_n,flushDE,o_rdata1D,i_num1E);
floprc #(32) num2DE(clk,rst_n,flushDE,o_rdata2D,i_num2E);
floprc #(32) pcFD(clk,rst_n,flushFD,pcD,i_pcE);

riscv_alu EX_alu(
  .i_opcode(i_opcodeE),//*
  .i_funct7(i_funct7E),//*
  .i_funct3(i_funct3E),//*
  .i_num1(i_num1E),//*
  .i_num2(i_num2E),//*
  .i_imm_num(i_imm_numE),//*
  .i_pc(i_pcE),//*
  .o_if_branch(o_if_branchE),//*
  .o_num(o_numE),
  .o_pc(o_pcE)//*
);

assign mem_addrE = i_imm_numE + i_num1E;
floprc #(32) mem_addrEM(clk,rst_n,flushEM,mem_addrE,mem_addrM);
floprc #(1) if_branchEM(clk,rst_n,flushEM,o_if_branchE,ex_branchM);
floprc #(32) pc_targetEM(clk,rst_n,flushEM,o_pcE,ex_targetM);

module riscv_mem(
  .clk(clk),//*
  .rst_n(rst_n),//*
  .i_re(i_reM),
  .i_we(i_weM),
  .i_funct3(i_funct3M),
  .i_addr(i_addrM),
  .i_wdata(mem_addrM),//*
  .o_rdata(o_rdataM),
  .o_bus_stall(o_bus_stallM),
  .mem_master(mem_master)//*
);


endmodule