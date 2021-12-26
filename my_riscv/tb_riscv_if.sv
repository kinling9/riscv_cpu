`timescale 1ns/10ps
`include "riscv_if.sv"
module tb_riscv_if;

  logic clk;
  logic rst_n;
  logic i_ex_jmp;
  logic i_id_jmp;
  logic i_stall;
  logic [31:0] i_boot_addr;
  logic [31:0] i_ex_target;
  logic [31:0] i_id_target; 
  logic [31:0] o_pc;
  logic [31:0] o_instr;
  dualport_bus instr_master();

  riscv_if DUT(
  .clk(clk),
  .rst_n(rst_n),
  .i_ex_jmp(i_ex_jmp),
  .i_id_jmp(i_id_jmp),
  .i_stall(i_stall),
  .i_boot_addr(i_boot_addr),
  .i_ex_target(i_ex_target),
  .i_id_target(i_id_target), 
  .o_pc(o_pc),
  .o_instr(o_instr),
  .instr_master(instr_master.master)
  );
endmodule
