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
  .i_id_jmp(jalE),//*
  .i_stall(stallF),
  .i_boot_addr(i_boot_addr),//*
  .i_ex_target(ex_targetM),//*
  .i_id_target(jal_addrE),//*
  .o_pc(pcF),//*
  .o_instr(instrF),//*
  .instr_master(instr_master)//*
);

flopenrc #(32) instrFD(clk,rst_n,stallFD,flushFD,instrF,instrD);
flopenrc #(32) pcFD(clk,rst_n,stallFD,flushFD,pcF,pcD);

riscv_id ID_id(
  .i_instr(instrD),
  .o_opcode(opcodeD),//*
  .o_funct7(funct7D),//*
  .o_funct3(funct3D),//*
  .o_imm_num(imm_numD),//*
  .o_src1_reg_en(src1_reg_enD),//*
  .o_src2_reg_en(src2_reg_enD),//*
  .o_src1_reg_addr(src1_reg_addrD),//*
  .o_src2_reg_addr(src2_reg_addrD),//*
  .o_jal(jalD),
  .o_alures2reg(alures2regD),//*
  .o_memory2reg(memory2regD),//*
  .o_mem_write(mem_writeD),//*
  .o_dst_reg_addr(dst_reg_addrD)//*
);

riscv_reg ID_reg (
  .clk(clk),//*
  .rst_n(rst_n),//*
  .i_re1(src1_reg_enD),//*
  .i_raddr1(src1_reg_addrD),//*
  .i_re2(src2_reg_enD),//*
  .i_raddr2(src2_reg_addrD),//*
  .i_we(reg_weB),//*
  .i_waddr(dst_reg_addrB),//*
  .i_wdata(reg_wdataB),//*
  .o_rdata1(rdata1D),//*
  .o_rdata2(rdata2D)//*
);

assign jal_addrD = imm_numD + pcD;

flopenrc #(7) opcodeDE(clk,rst_n,stallDE,flushDE,opcodeD,opcodeE);
flopenrc #(7) funct7DE(clk,rst_n,stallDE,flushDE,funct7D,funct7E);
flopenrc #(3) funct3DE(clk,rst_n,stallDE,flushDE,funct3D,funct3E);
flopenrc #(32) imm_numDE(clk,rst_n,stallDE,flushDE,imm_numD,imm_numE);
flopenrc #(32) num1DE(clk,rst_n,stallDE,flushDE,rdata1D,num1E);
flopenrc #(32) num2DE(clk,rst_n,stallDE,flushDE,rdata2D,num2E);
flopenrc #(32) pcDE(clk,rst_n,stallDE,flushDE,pcD,pcE);
flopenrc #(1) alures2regDE(clk,rst_n,stallDE,flushDE,alures2regD,alures2regE);
flopenrc #(1) memory2regDE(clk,rst_n,stallDE,flushDE,memory2regD,memory2regE);
flopenrc #(32) dst_reg_addrDE(clk,rst_n,stallDE,flushDE,dst_reg_addrD,dst_reg_addrE);
flopenrc #(1) mem_writeDE(clk,rst_n,stallDE,flushDE,mem_writeD,mem_writeE);
flopenrc #(1) jalDE(clk,rst_n,stallDE,flushDE,jalD,jalE);
flopenrc #(32) jal_addrDE(clk,rst_n,stallDE,flushDE,jal_addrD,jal_addrE);

riscv_alu EX_alu(
  .i_opcode(opcodeE),//*
  .i_funct7(funct7E),//*
  .i_funct3(funct3E),//*
  .i_num1(num1E),//*
  .i_num2(num2E),//*
  .i_imm_num(imm_numE),//*
  .i_pc(pcE),//*
  .o_if_branch(if_branchE),//*
  .o_num(numE),//*
  .o_pc(ex_targetE)//*
);

assign mem_addrE = imm_numE + num1E;

flopenrc #(3) funct3EM(clk,rst_n,stallEM,flushEM,funct3E,funct3M);
flopenrc #(32) mem_addrEM(clk,rst_n,stallEM,flushEM,mem_addrE,mem_addrM);
flopenrc #(1) if_branchEM(clk,rst_n,stallEM,flushEM,if_branchE,ex_branchM);
flopenrc #(32) pc_targetEM(clk,rst_n,stallEM,flushEM,ex_targetE,ex_targetM);
flopenrc #(1) alures2regEM(clk,rst_n,stallEM,flushEM,alures2regE,alures2regM);
flopenrc #(1) memory2regEM(clk,rst_n,stallEM,flushEM,memory2regE,memory2regM);
flopenrc #(32) alu_numEM(clk,rst_n,stallEM,flushEM,numE,numM);
flopenrc #(32) dst_reg_addrEM(clk,rst_n,stallEM,flushEM,dst_reg_addrE,dst_reg_addrM);
flopenrc #(1) mem_writeEM(clk,rst_n,stallEM,flushEM,mem_writeE,mem_writeM);
flopenrc #(32) num2EM(clk,rst_n,stallEM,flushEM,num2E,num2M);

module riscv_mem(
  .clk(clk),//*
  .rst_n(rst_n),//*
  .i_re(memory2regM),//*
  .i_we(mem_writeM),//*
  .i_funct3(funct3M),//*
  .i_addr(mem_addrM),//*
  .i_wdata(num2M),//*
  .o_rdata(rdataM),//*
  .o_bus_stall(bus_stallM),
  .mem_master(mem_master)//*
);

flopenrc #(1) alures2regMB(clk,rst_n,stallMB,flushMB,alures2regM,alures2regB);
flopenrc #(1) memory2regMB(clk,rst_n,stallMB,flushMB,memory2regM,memory2regB);
flopenrc #(32) mem_rdataMB(clk,rst_n,stallMB,flushMB,rdataM,rdataB);
flopenrc #(32) alu_numMB(clk,rst_n,stallMB,flushMB,numM,numB);
flopenrc #(32) dst_reg_addrMB(clk,rst_n,stallMB,flushMB,dst_reg_addrM,dst_reg_addrB);

assign reg_weB = (alures2regB | memory2regB);//*
assign reg_wdataB = memory2regB ? rdataB : numB;//*


endmodule