class riscv_env extends uvm_env;
	`uvm_component_utils(riscv_env)

	riscv_agent rv_agent;
	riscv_scoreboard rv_sb;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		rv_agent	= riscv_agent::type_id::create(.name("rv_agent"), .parent(this));
		rv_sb		= riscv_scoreboard::type_id::create(.name("rv_sb"), .parent(this));
	endfunction: build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		rv_agent.agent_ap_before.connect(rv_sb.sb_export_before);
		rv_agent.agent_ap_after.connect(rv_sb.sb_export_after);
	endfunction: connect_phase
endclass: riscv_env
