`uvm_analysis_imp_decl(_before)
`uvm_analysis_imp_decl(_after)

class riscv_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(riscv_scoreboard)

	uvm_analysis_export #(riscv_transaction) sb_export_before;
	uvm_analysis_export #(riscv_transaction) sb_export_after;

	uvm_tlm_analysis_fifo #(riscv_transaction) before_fifo;
	uvm_tlm_analysis_fifo #(riscv_transaction) after_fifo;

	riscv_transaction tx_before;
	riscv_transaction tx_after;

	function new(string name, uvm_component parent);
		super.new(name, parent);

		tx_before	= new("tx_before");
		tx_after	= new("tx_after");
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
			before_fifo.get(tx_before);
			after_fifo.get(tx_after);
			
			compare();
		end
	endtask: run

	virtual function void compare();
		`uvm_info("compare", $sformatf("PC Test:\nbefore: %d\nafter : %d", $signed(tx_before.pc), $signed(tx_after.pc)), UVM_LOW);
		if (tx_before.pc == tx_after.pc) begin
			`uvm_info("compare", $sformatf("PC Test OK!"), UVM_LOW);
		end else begin
			`uvm_info("compare", $sformatf("PC Test Failed!"), UVM_LOW);
		end

		`uvm_info("compare", $sformatf("RAM READ Test: \nbefore: mem_rd.req: %d, mem_rd.addr: %x \nafter : mem_rd.req: %d, mem_rd.addr: %x ", tx_before.mem_rd.req, tx_before.mem_rd.addr, tx_after.mem_rd.req, tx_after.mem_rd.addr), UVM_LOW);

		if (tx_before.mem_rd.req == tx_after.mem_rd.req && 
			tx_before.mem_rd.addr == tx_after.mem_rd.addr) begin
			`uvm_info("compare", $sformatf("RAM READ Test OK!"), UVM_LOW);
		end else begin
			`uvm_info("compare", $sformatf("RAM READ Test Failed!"), UVM_LOW);
		end

		`uvm_info("compare", $sformatf("RAM WRITE Test: \nbefore: mem_wr.req: %x, mem_wr.addr: %x, mem_wr.data: %x \nafter : mem_wr.req: %x, mem_wr.addr: %x, mem_wr.data: %x ", tx_before.mem_wr.req, tx_before.mem_wr.addr, tx_before.mem_wr.data, tx_after.mem_wr.req, tx_after.mem_wr.addr, tx_after.mem_wr.data), UVM_LOW);

		if (tx_before.mem_wr.req == tx_after.mem_wr.req && 
			tx_before.mem_wr.addr == tx_after.mem_wr.addr &&
			tx_before.mem_wr.data == tx_after.mem_wr.data) begin
			`uvm_info("compare", $sformatf("RAM READ Test OK!"), UVM_LOW);
		end else begin
			`uvm_info("compare", $sformatf("RAM READ Test Failed!"), UVM_LOW);
		end


	endfunction: compare
endclass: riscv_scoreboard
