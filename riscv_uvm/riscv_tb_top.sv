`timescale 1ns/10ps
`include "riscv_pkg.sv"
`include "riscv_pipeline.sv"
`include "control_if.sv"
`ifndef PORT_INCLUDE
`define PORT_INCLUDE
`include "dualport_bus.sv"
`endif


module riscv_tb_top;
	import uvm_pkg::*;

	//Interface declaration
	control_if ctrl_vif();
  dualport_bus instr_vif();
  dualport_bus mem_vif();

	//Connects the Interface to the DUT
  riscv_pipeline DUT(
    .clk(ctrl_vif.clk),
    .rst_n(ctrl_vif.rst_n),
    .i_boot_addr(ctrl_vif.i_boot_addr),
    .instr_master(instr_vif.master),
    .mem_master(mem_vif.master)
  );

	initial begin
		//Registers the Interface in the configuration block so that other
		//blocks can use it
		uvm_resource_db#(virtual control_if)::set
			(.scope("ifs"), .name("control_if"), .val(ctrl_vif));
    uvm_resource_db#(virtual dualport_bus)::set
			(.scope("ifs"), .name("dualport_bus_instr"), .val(instr_vif));
    uvm_resource_db#(virtual dualport_bus)::set
			(.scope("ifs"), .name("dualport_bus_mem"), .val(mem_vif));

		//Executes the test
		run_test();
	end

	//Variable initialization

  initial begin
    ctrl_vif.clk <= 1'b1;
    ctrl_vif.i_boot_addr <= 32'h0000_0000;
    ctrl_vif.rst_n <= 1'b1;
    instr_vif.rd_data <= 32'h0000_0000;
  end

  assign instr_vif.rd_gnt = instr_vif.rd_req;
  assign instr_vif.wr_gnt = instr_vif.wr_req;
  assign mem_vif.rd_gnt = mem_vif.rd_req;
  assign mem_vif.wr_gnt = mem_vif.wr_req;

  always_ff @ (mem_vif.rd_addr) begin
    mem_vif.rd_data = $random(mem_vif.rd_addr);
  end

  initial begin
    #10;
    ctrl_vif.rst_n = 1'b0;
    #10;
    ctrl_vif.rst_n = 1'b1;
  end

	//Clock generation
	always
		#5 ctrl_vif.clk = ~ctrl_vif.clk;
endmodule
