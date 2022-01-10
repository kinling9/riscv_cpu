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
      (.scope("ifs"), .name("dualport_bus_instr"), .val(instr_vif)));
    void'(uvm_resource_db#(virtual dualport_bus)::read_by_name
      (.scope("ifs"), .name("dualport_bus_mem"), .val(mem_vif)));

  endfunction: build_phase

  task run_phase(uvm_phase phase);
    drive();
  endtask: run_phase

  virtual task drive();
    riscv_transaction rv_tx;
    integer counter = 0, state = 0;
    //logic [31:0] instr_vif.rd_data;
    #20;
    forever begin
      @(negedge ctrl_vif.clk) begin
        seq_item_port.get_next_item(rv_tx);
        //`uvm_info("rv_driver", rv_tx.sprint(), UVM_LOW);
        //`uvm_info("rv_driver", $sformatf("%d%d%d%d%d%d%d",instr_vif.rd_data[6],instr_vif.rd_data[5],instr_vif.rd_data[4],instr_vif.rd_data[3],instr_vif.rd_data[2],instr_vif.rd_data[1],instr_vif.rd_data[0]), UVM_LOW);

        case (rv_tx.instr)
          AND: begin
						instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b111, rv_tx.rd, 7'b0110011};
						`uvm_info("rv_driver", $sformatf("and %d %d to %d", rv_tx.rs1,rv_tx.rs2,rv_tx.rd), UVM_LOW);
					end
          OR: begin
            instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b110, rv_tx.rd, 7'b0110011};
						`uvm_info("rv_driver", $sformatf("or %d %d to %d", rv_tx.rs1,rv_tx.rs2,rv_tx.rd), UVM_LOW);
          end
          XOR: begin
            instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b100, rv_tx.rd, 7'b0110011};
            `uvm_info("rv_driver", $sformatf("xor %d %d to %d", rv_tx.rs1,rv_tx.rs2,rv_tx.rd), UVM_LOW);
          end
          ADD: begin
            instr_vif.rd_data = {7'b0000000, rv_tx.rs2, rv_tx.rs1, 3'b000, rv_tx.rd, 7'b0110011};
            `uvm_info("rv_driver", $sformatf("add %d %d to %d", rv_tx.rs1,rv_tx.rs2,rv_tx.rd), UVM_LOW);
          end
          SUB: begin
            instr_vif.rd_data = {7'b0100000, rv_tx.rs2, rv_tx.rs1, 3'b000, rv_tx.rd, 7'b0110011}; 
            `uvm_info("rv_driver", $sformatf("sub %d %d to %d", rv_tx.rs1,rv_tx.rs2,rv_tx.rd), UVM_LOW);
          end
          ANDI: begin
            instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b111, rv_tx.rd, 7'b0010011};
            `uvm_info("rv_driver", $sformatf("andi %d with %d to %d", rv_tx.rs1,$signed(rv_tx.imm),rv_tx.rd), UVM_LOW);
          end
          ORI: begin
            instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b110, rv_tx.rd, 7'b0010011};
            `uvm_info("rv_driver", $sformatf("ori %d with %d to %d", rv_tx.rs1,$signed(rv_tx.imm),rv_tx.rd), UVM_LOW);
          end
          XORI: begin
            instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b100, rv_tx.rd, 7'b0010011};
            `uvm_info("rv_driver", $sformatf("xori %d with %d to %d", rv_tx.rs1,$signed(rv_tx.imm),rv_tx.rd), UVM_LOW);
          end
          SW: begin
            instr_vif.rd_data = {rv_tx.imm[11:5], rv_tx.rs2, rv_tx.rs1, 3'b010, rv_tx.imm[4:0], 7'b0100011}; 
            `uvm_info("rv_driver", $sformatf("store to address %d + %d from %d", rv_tx.rs1,$signed(rv_tx.imm),rv_tx.rs2), UVM_LOW);
          end
          LW: begin
            instr_vif.rd_data = {rv_tx.imm, rv_tx.rs1, 3'b010, rv_tx.rd, 7'b0000011};
            `uvm_info("rv_driver", $sformatf("load from address %d + %d to %d", rv_tx.rs1,$signed(rv_tx.imm),rv_tx.rd), UVM_LOW);
          end
          BEQ: begin
            instr_vif.rd_data = {rv_tx.imm_jal[12], rv_tx.imm[10:5], rv_tx.rs2, rv_tx.rs1, 3'b000, rv_tx.imm[4:1], rv_tx.imm[11], 7'b1100011};
            `uvm_info("rv_driver", $sformatf("check equ of %d and %d and jump to %d", rv_tx.rs1,rv_tx.rs2, $signed({rv_tx.imm_jal[12], rv_tx.imm[11:1], 1'b0})), UVM_LOW);
          end
          JAL: begin
            // instr_vif.rd_data = {rv_tx.imm_jal[20], rv_tx.imm[10:1], rv_tx.imm[11], rv_tx.imm_jal[19:12], rv_tx.rd, 7'b1101111};
            instr_vif.rd_data = {rv_tx.imm_jal[20], rv_tx.imm[10:1], rv_tx.imm[11], rv_tx.imm_jal[19:12], 5'b00000, 7'b1101111};
            `uvm_info("rv_driver", $sformatf("jump to %d", $signed({rv_tx.imm_jal[20:12], rv_tx.imm[11:1], 1'b0})), UVM_LOW);
          end
          default: begin
            instr_vif.rd_data = 0;
          end
        endcase
        
        //`uvm_info("rv_driver", $sformatf("instr:%s, rs2:%x, rs1:%x, rd:%x, imm:%x, imm_jal:%x, instr_vif.rd_data:%x", rv_tx.instr.name(), rv_tx.rs2, rv_tx.rs1, rv_tx.rd, rv_tx.imm, rv_tx.imm_jal, instr_vif.rd_data), UVM_LOW);
        `uvm_info("rv_driver", $sformatf("instr_vif.rd_data:%x", instr_vif.rd_data), UVM_LOW);

        // mem_vif.rd_data = rv_tx.mem_rd_data;

        seq_item_port.item_done();
      end
    end
  endtask: drive
endclass: riscv_driver
