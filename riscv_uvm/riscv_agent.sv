class riscv_agent extends uvm_agent;
	`uvm_component_utils(riscv_agent)

	uvm_analysis_port#(riscv_transaction) agent_ap_before;
	uvm_analysis_port#(riscv_transaction) agent_ap_after;

	riscv_sequencer		rv_seqr;
	riscv_driver		rv_drvr;
	riscv_monitor_before	rv_mon_before;
	riscv_monitor_after	rv_mon_after;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		agent_ap_before	= new(.name("agent_ap_before"), .parent(this));
		agent_ap_after	= new(.name("agent_ap_after"), .parent(this));

		rv_seqr		= riscv_sequencer::type_id::create(.name("rv_seqr"), .parent(this));
		rv_drvr		= riscv_driver::type_id::create(.name("rv_drvr"), .parent(this));
		rv_mon_before	= riscv_monitor_before::type_id::create(.name("rv_mon_before"), .parent(this));
		rv_mon_after	= riscv_monitor_after::type_id::create(.name("rv_mon_after"), .parent(this));
	endfunction: build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		rv_drvr.seq_item_port.connect(rv_seqr.seq_item_export);
		rv_mon_before.mon_ap_before.connect(agent_ap_before);
		rv_mon_after.mon_ap_after.connect(agent_ap_after);
	endfunction: connect_phase
endclass: riscv_agent
