class riscv_test extends uvm_test;
		`uvm_component_utils(riscv_test)

		riscv_env rv_env;

		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction: new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			rv_env = riscv_env::type_id::create(.name("rv_env"), .parent(this));
		endfunction: build_phase

		task run_phase(uvm_phase phase);
			riscv_sequence rv_seq;

			phase.raise_objection(.obj(this));
				rv_seq = riscv_sequence::type_id::create(.name("rv_seq"), .contxt(get_full_name()));
				assert(rv_seq.randomize());
				rv_seq.start(rv_env.rv_agent.rv_seqr);
			phase.drop_objection(.obj(this));
		endtask: run_phase
endclass: riscv_test
