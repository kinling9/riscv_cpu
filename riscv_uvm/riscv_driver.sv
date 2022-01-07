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
    //logic [31:0] instr_vif.rd_data;
    #30;
		forever begin
			@(posedge ctrl_vif.clk)
			begin
				seq_item_port.get_next_item(rv_tx);
        `uvm_info("rv_driver", rv_tx.sprint(), UVM_LOW);
        case (rv_tx.instr)
          AND: instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b111, rv_tx.rd, 7'b0110011};
          OR: instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b110, rv_tx.rd, 7'b0110011};
          XOR: instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b100, rv_tx.rd, 7'b0110011};
          ADD: instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b000, rv_tx.rd, 7'b0110011};
          SUB: instr_vif.rd_data = {7'b0100000, rv_tx.rs2, rv_tx.rs1, 3'b000, rv_tx.rd, 7'b0110011}; 
          ANDI: instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b111, rv_tx.rd, 7'b0010011};
          ORI: instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b110, rv_tx.rd, 7'b0010011};
          XORI: instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b100, rv_tx.rd, 7'b0010011};
          SW: instr_vif.rd_data = {rv_tx.imm[11:5], rv_tx.rs2, rv_tx.rs1, 3'b010, rv_tx.imm[4:0], 7'b0100011}; 
          LW: instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b010, rv_tx.rd, 7'b0000011};
          BEQ: instr_vif.rd_data = {rv_tx.imm[12], rv_tx.imm[10:5], rv_tx.rs2, rv_tx.rs1, 3'b000, rv_tx.imm[4:1], rv_tx.imm[11], 7'b1100011};
          JAL: instr_vif.rd_data = {rv_tx.imm[20], rv_tx.imm[10:1], rv_tx.imm[11], rv_tx.imm[19:12], rv_tx.rd, 7'b1101111};
          default: instr_vif.rd_data = 'h0;
        endcase
        `uvm_info("instr_vif.rd_data", $sformatf("%x", instr_vif.rd_data), UVM_LOW);


		    seq_item_port.item_done();
			end
		end
	endtask: drive
endclass: riscv_driver
