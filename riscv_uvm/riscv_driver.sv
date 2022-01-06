class riscv_driver extends uvm_driver#(riscv_transaction);
	`uvm_component_utils(riscv_driver)

	virtual control_if ctrl_vif;
  virtual dualport_bus instr_vif;
  virtual dualport_bus mem_vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		void'(uvm_resource_db#(virtual control_if)::read_by_name
			(.scope("ifs"), .name("control_if"), .val(ctrl_vif)));
		void'(uvm_resource_db#(virtual dualport_bus)::read_by_name
			(.scope("ifs"), .name("dualport_bus"), .val(instr_vif)));
		void'(uvm_resource_db#(virtual dualport_bus)::read_by_name
			(.scope("ifs"), .name("dualport_bus"), .val(mem_vif)));

	endfunction: build_phase

	task run_phase(uvm_phase phase);
		drive();
	endtask: run_phase

	virtual task drive();
		riscv_transaction rv_tx;
		integer counter = 0, state = 0;

    #50
		forever begin
			@(posedge ctrl_vif.clk)
			begin
				seq_item_port.get_next_item(rv_tx);
        //`uvm_info("rv_driver", rv_tx.sprint(), UVM_LOW);
		    seq_item_port.item_done();
			end
		end
	endtask: drive
endclass: riscv_driver
