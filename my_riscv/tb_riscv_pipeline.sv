`timescale 1ns/10ps
`include "riscv_pipeline.sv"
`include "instr_rom.sv"
`include "ram_bus.sv"

module time_unit;
	initial $timeformat(-9,1," ns",9);
endmodule

module tb_riscv_pipeline;

  logic clk;
  logic rst_n;
  logic [31:0] i_boot_addr;
  dualport_bus instr_master();
  dualport_bus mem_master();
  int counter_finish = 0;

  riscv_pipeline DUT(
    .clk(clk),
    .rst_n(rst_n),
    .i_boot_addr(i_boot_addr),
    .instr_master(instr_master.master),
    .mem_master(mem_master.master)
  );
  
  instr_rom ideal_instr(
    .clk(clk),
    .rst_n(rst_n),
    .instr_slave(instr_master.slave)
  );

  ram_bus ideal_mem(
    .clk(clk),
    .rst_n(rst_n),
    .mem_slave(mem_master.slave)
  );

  initial begin
    clk = 1'b0;
    i_boot_addr = 32'h0000_0000;
    rst_n = 1'b1;
  end

  initial begin
		forever #10 clk = ! clk;
	end

  initial begin
    #20;
    rst_n = 1'b0;
    #20;
    rst_n = 1'b1;
  end


  always@(posedge clk) begin
    counter_finish = counter_finish + 1;

    if(counter_finish == 200) $finish;
  end

endmodule