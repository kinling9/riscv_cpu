typedef enum {UNKNOWN_TYPE, R_TYPE, I_TYPE, S_TYPE, B_TYPE, J_TYPE} instr_type;

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
      (.scope("ifs"), .name("dualport_bus_instr"), .val(instr_vif)));
    void'(uvm_resource_db#(virtual dualport_bus)::read_by_name
      (.scope("ifs"), .name("dualport_bus_mem"), .val(mem_vif)));

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
        rv_tx.pc = instr_vif.rd_addr;
        rv_tx.mem_wr_addr = mem_vif.wr_addr;
        rv_tx.mem_rd_addr = mem_vif.rd_addr;
        rv_tx.mem_wr_req = mem_vif.wr_req;
        rv_tx.mem_rd_req = mem_vif.rd_req;
        rv_tx.mem_wr_data = mem_vif.wr_data;
        //Send the transaction to the analysis port
        //`uvm_info("rv_mon_before", rv_tx.sprint(), UVM_LOW);
        `uvm_info("rv_mon_before ROM", $sformatf("pc: %x, ", rv_tx.pc), UVM_LOW);
        `uvm_info("rv_mon_before read RAM", $sformatf("mem_rd_req: %x, mem_rd_addr: %x", rv_tx.mem_rd_req, rv_tx.mem_rd_addr), UVM_LOW);
        `uvm_info("rv_mon_before write RAM", $sformatf("mem_wr_req: %x, mem_wr_addr: %x, mem_wr_data: %x,", rv_tx.mem_wr_req, rv_tx.mem_wr_addr, rv_tx.mem_wr_data), UVM_LOW);
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
      (.scope("ifs"), .name("dualport_bus_instr"), .val(instr_vif)));
    void'(uvm_resource_db#(virtual dualport_bus)::read_by_name
      (.scope("ifs"), .name("dualport_bus_mem"), .val(mem_vif)));

    mon_ap_after= new(.name("mon_ap_after"), .parent(this));
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    integer counter_mon = 0, state = 0;
		instr_type instr_type_after;
    rv_tx = riscv_transaction::type_id::create
      (.name("rv_tx"), .contxt(get_full_name()));

    #30;
    forever begin
      @(posedge ctrl_vif.clk)
      begin
        rv_tx.ina = 2'b01;
        rv_tx.inb = 2'b10;
        rv_tx.out = 3'b000;
        rv_tx.instr = UNKNOWN_INSTR;
        rv_tx.rs2 = 0;
        rv_tx.rs1 = 0;
        rv_tx.rd = 0;
        rv_tx.imm = 0;
        rv_tx.imm_jal = 0;

				case (instr_vif.rd_data[6:0])
          7'b0110011 : begin 
            instr_type_after = R_TYPE;
            case (instr_vif.rd_data[14:12])
              3'b111 : rv_tx.instr = AND;
              3'b110 : rv_tx.instr = OR;
              3'b100 : rv_tx.instr = XOR;
              3'b000 : begin 
                if (instr_vif.rd_data[31:25] === 7'b0000000) begin
                  rv_tx.instr = ADD;
                end else if (instr_vif.rd_data[31:25] === 7'b0100000) begin
                  rv_tx.instr = SUB;
                end else begin 
                  rv_tx.instr = UNKNOWN_INSTR;
                end
              end
              default: rv_tx.instr = UNKNOWN_INSTR;
            endcase
          end
          7'b0010011 : begin 
            instr_type_after = I_TYPE;
            case (instr_vif.rd_data[14:12])
              3'b111 : rv_tx.instr = ANDI;
              3'b110 : rv_tx.instr = ORI;
              3'b100 : rv_tx.instr = XORI;
              default: rv_tx.instr = UNKNOWN_INSTR;
            endcase
          end
          7'b0100011 : begin 
            instr_type_after = S_TYPE;
            rv_tx.instr = SW;
          end
          7'b0000011 : begin 
            instr_type_after = I_TYPE;
            rv_tx.instr = LW;
          end
          7'b1100011 : begin 
            instr_type_after = B_TYPE;
            rv_tx.instr = BEQ;
          end
          7'b1101111 : begin 
            instr_type_after = J_TYPE;
            rv_tx.instr = JAL;
          end
          default : begin 
            instr_type_after = UNKNOWN_TYPE;
            rv_tx.instr = UNKNOWN_INSTR;
          end
        endcase

        case (instr_type_after)
          R_TYPE : begin 
            rv_tx.rs2 = instr_vif.rd_data[24:20];
            rv_tx.rs1 = instr_vif.rd_data[19:15];
            rv_tx.rd = instr_vif.rd_data[11:7];
          end
          I_TYPE : begin 
            rv_tx.imm = instr_vif.rd_data[31:20];
            rv_tx.imm_jal = {20{instr_vif.rd_data[31]}};
            rv_tx.rs1 = instr_vif.rd_data[19:15];
            rv_tx.rd = instr_vif.rd_data[11:7];
          end
          S_TYPE : begin 
            rv_tx.imm = {instr_vif.rd_data[31:25], instr_vif.rd_data[11:7]};
            rv_tx.imm_jal = {20{instr_vif.rd_data[31]}};
            rv_tx.rs2 = instr_vif.rd_data[24:20];
            rv_tx.rs1 = instr_vif.rd_data[19:15];
          end
          B_TYPE : begin 
            rv_tx.imm[11:1] = {instr_vif.rd_data[31], instr_vif.rd_data[7],
                              instr_vif.rd_data[30:25], instr_vif.rd_data[11:8]};
            rv_tx.imm_jal = {20{instr_vif.rd_data[31]}};
            rv_tx.rs2 = instr_vif.rd_data[24:20];
            rv_tx.rs1 = instr_vif.rd_data[19:15];
          end
          J_TYPE : begin 
            rv_tx.imm[11:1] = {instr_vif.rd_data[20], instr_vif.rd_data[30:21]};
            rv_tx.imm_jal[20:12] = {instr_vif.rd_data[31], instr_vif.rd_data[19:12]};
            rv_tx.imm_jal[31:21] = {12{instr_vif.rd_data[31]}};
          end
        endcase
        //`uvm_info("rv_mon_after", rv_tx.sprint(), UVM_LOW);
        
        `uvm_info("rv_mon_after", $sformatf("instr:%s, rs2:%x, rs1:%x, rd:%x, imm:%x, imm_jal:%x, instr_vif.rd_data:%x", rv_tx.instr.name(), rv_tx.rs2, rv_tx.rs1, rv_tx.rd, rv_tx.imm, {rv_tx.imm_jal, rv_tx.imm[11:1]}, instr_vif.rd_data), UVM_LOW);


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

  virtual function void execute();
    rv_tx.out = rv_tx.ina + rv_tx.inb;
  endfunction: execute

  virtual function void predictor();
    rv_tx.out = rv_tx.ina + rv_tx.inb;
  endfunction: predictor
endclass: riscv_monitor_after 
