`timescale 1ns/10ps
`include "riscv_mem.sv"
module tb_riscv_mem;

  logic clk;
  logic rst_n;
  logic i_re;
  logic i_we;
  logic [2:0] i_funct3;
  logic [31:0] i_addr;
  logic [31:0] i_wdata;
  logic [31:0] o_rdata;
  logic o_bus_stall;
  dualport_bus mem_master();

  riscv_mem DUT(
  .clk(clk),
  .rst_n(rst_n),
  .i_re(i_re),
  .i_we(i_we),
  .i_funct3(i_funct3),
  .i_addr(i_addr),
  .i_wdata(i_wdata),
  .o_rdata(o_rdata),
  .o_bus_stall(o_bus_stall),
  .mem_master(mem_master.master)
  );

endmodule