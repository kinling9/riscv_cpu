`uvm_analysis_imp_decl(_before)
`uvm_analysis_imp_decl(_after)

class riscv_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(riscv_scoreboard)

	uvm_analysis_export #(riscv_transaction) sb_export_before;
	uvm_analysis_export #(riscv_transaction) sb_export_after;

	uvm_tlm_analysis_fifo #(riscv_transaction) before_fifo;
	uvm_tlm_analysis_fifo #(riscv_transaction) after_fifo;

	riscv_transaction transaction_before;
	riscv_transaction transaction_after;

	function new(string name, uvm_component parent);
		super.new(name, parent);

		transaction_before	= new("transaction_before");
		transaction_after	= new("transaction_after");
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		sb_export_before	= new("sb_export_before", this);
		sb_export_after		= new("sb_export_after", this);

   		before_fifo		= new("before_fifo", this);
		after_fifo		= new("after_fifo", this);
	endfunction: build_phase

	function void connect_phase(uvm_phase phase);
		sb_export_before.connect(before_fifo.analysis_export);
		sb_export_after.connect(after_fifo.analysis_export);
	endfunction: connect_phase

	task run();
		forever begin
			before_fifo.get(transaction_before);
			after_fifo.get(transaction_after);
			
			compare();
		end
	endtask: run

	virtual function void compare();
		// `uvm_info("compare", {"Test: compare OK!"}, UVM_LOW);
		// if(transaction_before.out == transaction_after.out) begin
		// 	`uvm_info("compare", {"Test: OK!"}, UVM_LOW);
		// end else begin
		// 	`uvm_info("compare", {"Test: Fail!"}, UVM_LOW);
		// end
	endfunction: compare
endclass: riscv_scoreboard
