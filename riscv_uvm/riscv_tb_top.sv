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
			(.scope("ifs"), .name("dualport_bus"), .val(instr_vif));
    uvm_resource_db#(virtual dualport_bus)::set
			(.scope("ifs"), .name("dualport_bus"), .val(mem_vif));

		//Executes the test
		run_test();
	end

	//Variable initialization

  initial begin
    ctrl_vif.clk = 1'b0;
    ctrl_vif.i_boot_addr = 32'h0000_0000;
    ctrl_vif.rst_n = 1'b1;
  end

	initial begin
		ctrl_vif.clk <= 1'b1;
	end

  initial begin
    #20;
    ctrl_vif.rst_n = 1'b0;
    #20;
    ctrl_vif.rst_n = 1'b1;
  end

	//Clock generation
	always
		#10 ctrl_vif.clk = ~ctrl_vif.clk;
endmodule
