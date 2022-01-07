class riscv_monitor_before extends uvm_monitor;
	`uvm_component_utils(riscv_monitor_before)

	uvm_analysis_port#(riscv_transaction) mon_ap_before;

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

		mon_ap_before = new(.name("mon_ap_before"), .parent(this));
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		integer counter_mon = 0, state = 0;

		riscv_transaction rv_tx;
		rv_tx = riscv_transaction::type_id::create
			(.name("rv_tx"), .contxt(get_full_name()));

    #30;
		forever begin
			@(posedge ctrl_vif.clk)
			begin
				rv_tx.out = 0;
        //Send the transaction to the analysis port
        //`uvm_info("rv_driver", rv_tx.sprint(), UVM_LOW);
        mon_ap_before.write(rv_tx);
			end
		end
	endtask: run_phase
endclass: riscv_monitor_before

class riscv_monitor_after extends uvm_monitor;
	`uvm_component_utils(riscv_monitor_after)

	uvm_analysis_port#(riscv_transaction) mon_ap_after;

	virtual control_if ctrl_vif;
  virtual dualport_bus instr_vif;
  virtual dualport_bus mem_vif;

	riscv_transaction rv_tx;
  logic [31:0] data_ram_cell [0:31];
	
	//For coverage
	riscv_transaction rv_tx_cg;

	//Define coverpoints
	covergroup riscv_cg;
      		ina_cp:     coverpoint rv_tx_cg.ina;
      		inb_cp:     coverpoint rv_tx_cg.inb;
		cross ina_cp, inb_cp;
	endgroup: riscv_cg

	function new(string name, uvm_component parent);
		super.new(name, parent);
		riscv_cg = new;
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		void'(uvm_resource_db#(virtual control_if)::read_by_name
			(.scope("ifs"), .name("control_if"), .val(ctrl_vif)));
		void'(uvm_resource_db#(virtual dualport_bus)::read_by_name
			(.scope("ifs"), .name("dualport_bus"), .val(instr_vif)));
		void'(uvm_resource_db#(virtual dualport_bus)::read_by_name
			(.scope("ifs"), .name("dualport_bus"), .val(mem_vif)));

		mon_ap_after= new(.name("mon_ap_after"), .parent(this));
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		integer counter_mon = 0, state = 0;
		rv_tx = riscv_transaction::type_id::create
			(.name("rv_tx"), .contxt(get_full_name()));

    #30;
		forever begin
			@(posedge ctrl_vif.clk)
			begin
        rv_tx.ina = 2'b01;
				rv_tx.inb = 2'b10;
				rv_tx.out = 3'b000;


		    //Predict the result
        predictor();
        rv_tx_cg = rv_tx;

        //Coverage
        riscv_cg.sample();

        //Send the transaction to the analysis port
        //`uvm_info("rv_driver", rv_tx.sprint(), UVM_LOW);
        mon_ap_after.write(rv_tx);
			end
		end
	endtask: run_phase

	virtual function void predictor();
		rv_tx.out = rv_tx.ina + rv_tx.inb;
	endfunction: predictor
endclass: riscv_monitor_after 
