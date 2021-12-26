`timescale 1ns/10ps
`include "riscv_pipeline.sv"
module tb_riscv_pipeline;

  logic clk;
  logic rst_n;
  logic [31:0] i_boot_addr;
  dualport_bus instr_master();
  dualport_bus mem_master();

  riscv_pipeline DUT(
    .clk(clk),
    .rst_n(rst_n),
    .i_boot_addr(i_boot_addr),
    .instr_master(instr_master.master),
    .mem_master(mem_master.master)
  );
  
endmodule