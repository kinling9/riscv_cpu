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
        rv_tx.pc = instr_vif.rd_addr;
        rv_tx.mem_wr.addr = mem_vif.wr_addr;
        rv_tx.mem_rd.addr = mem_vif.rd_addr;
        rv_tx.mem_wr.req = mem_vif.wr_req;
        rv_tx.mem_rd.req = mem_vif.rd_req;
        rv_tx.mem_wr.data = mem_vif.wr_data;
        //Send the transaction to the analysis port
        // `uvm_info("rv_mon_before", rv_tx.sprint(), UVM_LOW);
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

  logic [31:0] reg_ram [0:31];

  bit [4:0] rd_history[0:3] = '{0,0,0,0};
  mem_rd_t mem_rd_delay[0:4] = '{'{0,0},'{0,0},'{0,0},'{0,0},'{0,0}};
  mem_wr_t mem_wr_delay[0:4] = '{'{0,0,0},'{0,0,0},'{0,0,0},'{0,0,0},'{0,0,0}};
  integer counter_hazard;
  integer counter_hazard_nxt;
  integer counter_jal_beq;
  bit change_pc_jal_beq;
  bit accept_after_hazard; 
  // here accept_after_hazard act as enable pc+=4 after hazard, 
  // but won't accept until the hazard is fully addressed
  bit [31:0] beq_jal_pc;
  instr_type instr_type_after;
  
  //For coverage
  riscv_transaction rv_tx_cg;

  //Define coverpoints
  covergroup riscv_cg;
          rs1_cp:     coverpoint rv_tx_cg.rs1;
          rs2_cp:     coverpoint rv_tx_cg.rs2;
          rd_cp:     coverpoint rv_tx_cg.rd;
          instr_cp:     coverpoint rv_tx_cg.instr;
          imm_cp:     coverpoint rv_tx_cg.imm;
          imm_jal_cp:     coverpoint rv_tx_cg.imm_jal[20:12];
          mem_rd_data_cp:     coverpoint rv_tx_cg.mem_rd_data;
    cross rs1_cp, rs2_cp, rd_cp, instr_cp, imm_cp, imm_jal_cp, mem_rd_data_cp;
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
    counter_hazard = 0;
    counter_hazard_nxt = 0;
    counter_jal_beq = 0;
    change_pc_jal_beq = 0;
    accept_after_hazard = 0;
    
    foreach (reg_ram[i]) begin
      reg_ram[i] = 0;
    //  $display("%x", reg_ram[i]);
    end
    rv_tx = riscv_transaction::type_id::create
      (.name("rv_tx"), .contxt(get_full_name()));

    #30;
    forever begin
      @(posedge ctrl_vif.clk)
      begin
        
        rv_tx_init();
        
				instr_decode();
         
        // `uvm_info("rv_mon_after", rv_tx.sprint(), UVM_LOW);
        
        // `uvm_info("rv_mon_after", $sformatf("instr:%s, rs2:%d, rs1:%d, rd:%d, imm:%x, imm_jal:%x, instr_vif.rd_data:%x", rv_tx.instr.name(), rv_tx.rs2, rv_tx.rs1, rv_tx.rd, rv_tx.imm, {rv_tx.imm_jal, rv_tx.imm[11:1]}, instr_vif.rd_data), UVM_LOW);        
        
        // Excecute the instruction  
        // if (counter_jal_beq === 0 && (counter_hazard === 0 || counter_hazard === 1)) begin 

        if (accept_after_hazard === 1 || (counter_hazard === 0 && counter_jal_beq === 0)) begin

          if (accept_after_hazard === 1) begin
            `uvm_info("rv_mon_after", $sformatf("accept right after HAZARD!"), UVM_LOW);
            accept_after_hazard = 0;
          end

          if ((change_pc_jal_beq === 1)) begin 
            rv_tx.pc = beq_jal_pc;
            change_pc_jal_beq = 0;
          end else begin //if (counter_hazard === 0)
            rv_tx.pc += 4;
          end /* else if (counter_hazard === 1) begin
            --counter_hazard;
          end */       

          push_rd_history();
          /* foreach (rd_history[i]) begin
            $display("%d", rd_history[i]);
          end  */
          for (int i = 3; i > -1; --i) begin
            if ((!(rd_history[i] === 0)) && 
                (rv_tx.rs1 === rd_history[i] || 
                rv_tx.rs2 === rd_history[i])) begin
              if (counter_hazard === 0) begin
                accept_after_hazard = 1;
                counter_hazard = i + 1;
                `uvm_info("rv_mon_after", 
                        $sformatf("this instr causes HAZARD!"), UVM_LOW);
              end else if (i === 2) begin 
                accept_after_hazard = 0;
                counter_hazard_nxt = i + 1;
                `uvm_info("rv_mon_after", 
                        $sformatf("accept HAZARD after HAZARD!"), UVM_LOW);
              end else if (i === 1 && counter_hazard < 2) begin 
                accept_after_hazard = 0;
                counter_hazard_nxt = i;
                `uvm_info("rv_mon_after", 
                        $sformatf("accept HAZARD after HAZARD!"), UVM_LOW);
              end
              break;
              /* accept_after_hazard = 1;
              counter_hazard = i + 1; */
            end
          end     

          
          
          delay_mem();
          if (!(counter_jal_beq === 0)) begin
            --counter_jal_beq;
          end else begin
            execute();
          end
        /* end else if (accept_after_hazard === 1) begin
          rv_tx.pc += 4;
          accept_after_hazard = 0;
          `uvm_info("rv_mon_after", "REJECT because of HAZARD!", UVM_LOW);
        end */ 
        end else if (!(counter_hazard === 0)) begin 
          --counter_hazard;

          //simulate half of the pipeline moves 
          half_delay();
          
          `uvm_info("rv_mon_after", "REJECT because of HAZARD!", UVM_LOW);
          if ((counter_hazard === 0) && !(counter_hazard_nxt === 0)) begin
            counter_hazard = counter_hazard_nxt;
            accept_after_hazard = 1;
            counter_hazard_nxt = 0;
            `uvm_info("rv_mon_after", "prepare for chain HAZARD!", UVM_LOW);
          end
        end else if (!(counter_jal_beq === 0)) begin 
          --counter_jal_beq;
          delay_mem();
          push_rd_history();
          rv_tx.pc += 4;
          `uvm_info("rv_mon_after", "REJECT because of previous JAL or BEQ!", UVM_LOW);
          change_pc_jal_beq = 0;
          if ((counter_jal_beq === 1)) begin 
            change_pc_jal_beq = 1;
            --counter_jal_beq;
          end
        end

        `uvm_info("rv_mon_after", 
                  $sformatf("cur bubble: %d, potential bubble: %d", 
                  counter_hazard, counter_hazard_nxt), UVM_LOW);
        if (mem_wr_delay[0].req == 1) begin
          rv_tx.mem_wr = mem_wr_delay[0];
        end

        if (mem_rd_delay[0].req == 1) begin
          rv_tx.mem_rd = mem_rd_delay[0];
        end


        rv_tx_cg = rv_tx;

        //Coverage
        riscv_cg.sample();

        //Send the transaction to the analysis port
        //`uvm_info("rv_driver", rv_tx.sprint(), UVM_LOW);

        // `uvm_info("rv_mon_after ROM", $sformatf("pc: %d, ", $signed(rv_tx.pc)), UVM_LOW);
        // `uvm_info("rv_mon_after read RAM", $sformatf("mem_rd.req: %x, mem_rd.addr: %x", rv_tx.mem_rd.req, rv_tx.mem_rd.addr), UVM_LOW);
        // `uvm_info("rv_mon_after write RAM", $sformatf("mem_wr.req: %x, mem_wr.addr: %x, mem_wr.data: %x,", rv_tx.mem_wr.req, rv_tx.mem_wr.addr, rv_tx.mem_wr.data), UVM_LOW);
        mon_ap_after.write(rv_tx);
      end
    end
  endtask: run_phase

  
  virtual function void rv_tx_init();
    rv_tx.instr = UNKNOWN_INSTR;
    rv_tx.rs2 = 0;
    rv_tx.rs1 = 0;
    rv_tx.rd = 0;
    rv_tx.imm = 0;
    rv_tx.imm_jal = 0;
    rv_tx.mem_wr.addr = 0;
    rv_tx.mem_rd.addr = 0;
    rv_tx.mem_wr.req = 0;
    rv_tx.mem_rd.req = 0;
    rv_tx.mem_wr.data = 0;
    rv_tx.valid_instr = 0;
  endfunction: rv_tx_init;


  virtual function void instr_decode();
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
        rv_tx.rd = instr_vif.rd_data[11:7];
        rv_tx.imm_jal[20:12] = {instr_vif.rd_data[31], instr_vif.rd_data[19:12]};
        rv_tx.imm_jal[31:21] = {12{instr_vif.rd_data[31]}};
      end
    endcase
  endfunction: instr_decode;

  virtual function void execute();
    bit [31:0] imm_expand = {rv_tx.imm_jal, rv_tx.imm}; 
    rd_history[3] = rv_tx.rd;
    rv_tx.valid_instr = 1;
    case (rv_tx.instr)
      AND: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] & reg_ram[rv_tx.rs2];
      end
      OR: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] | reg_ram[rv_tx.rs2];
      end
      XOR: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] ^ reg_ram[rv_tx.rs2];
      end
      ADD: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] + reg_ram[rv_tx.rs2];
      end
      SUB: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] - reg_ram[rv_tx.rs2];
      end
      ANDI: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] & imm_expand;
      end
      ORI: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] | imm_expand;
      end
      XORI: begin 
        reg_ram[rv_tx.rd] = reg_ram[rv_tx.rs1] ^ imm_expand;
      end
      SW: begin
        mem_wr_delay[4].data = reg_ram[rv_tx.rs2];
        mem_wr_delay[4].addr = reg_ram[rv_tx.rs1] + imm_expand;
        mem_wr_delay[4].addr[1:0] = 2'b00;
        mem_wr_delay[4].req = 1;
        `uvm_info("rv_mon_after write RAM", $sformatf("rs2_data: %x, rs1_dara: %x, imm_expand: %d,",  reg_ram[rv_tx.rs2], reg_ram[rv_tx.rs1], $signed(imm_expand)), UVM_LOW);
      end
      LW: begin
        mem_rd_delay[4].addr = reg_ram[rv_tx.rs1] + imm_expand;
        // reg_ram[rv_tx.rd] = mem_vif.rd_data;
        mem_rd_delay[4].addr[1:0] = 2'b00;
        reg_ram[rv_tx.rd] = $random(int'(mem_rd_delay[4].addr));
        mem_rd_delay[4].req = 1;
        `uvm_info("rv_mon_after read RAM", $sformatf("rs1_data: %x, imm_expand: %d,",  reg_ram[rv_tx.rs1], $signed(imm_expand)), UVM_LOW);
      end
      BEQ: begin
        if (reg_ram[rv_tx.rs1] === reg_ram[rv_tx.rs2]) begin
          beq_jal_pc = rv_tx.pc + {rv_tx.imm_jal, rv_tx.imm};
          counter_jal_beq = 3;
        end
      end
      JAL: begin
        beq_jal_pc = rv_tx.pc + {rv_tx.imm_jal, rv_tx.imm};
        reg_ram[rv_tx.rd] = rv_tx.pc + 4;
        counter_jal_beq = 2;
      end
      default: begin
        `uvm_info("rv_mon_after", "UNKNOWN_INSTR", UVM_LOW);
      end
    endcase
    reg_ram[0] = 0;
  endfunction: execute

  virtual function void push_rd_history();
    rd_history[0] = rd_history[1];
    rd_history[1] = rd_history[2];
    rd_history[2] = rd_history[3];
    rd_history[3] = 0;
  endfunction: push_rd_history

  virtual function void delay_mem();
    mem_rd_delay[0] = mem_rd_delay[1];
    mem_rd_delay[1] = mem_rd_delay[2];
    mem_rd_delay[2] = mem_rd_delay[3];
    mem_rd_delay[3] = mem_rd_delay[4];
    mem_rd_delay[4] = '{0,0};

    mem_wr_delay[0] = mem_wr_delay[1];
    mem_wr_delay[1] = mem_wr_delay[2];
    mem_wr_delay[2] = mem_wr_delay[3];
    mem_wr_delay[3] = mem_wr_delay[4];
    mem_wr_delay[4] = '{0,0,0};
  endfunction: delay_mem

  virtual function void half_delay();
    mem_rd_delay[0] = mem_rd_delay[1];
    mem_rd_delay[1] = mem_rd_delay[2];
    mem_rd_delay[2] = '{0,0};

    mem_wr_delay[0] = mem_wr_delay[1];
    mem_wr_delay[1] = mem_wr_delay[2];
    mem_wr_delay[2] = '{0,0,0};

    rd_history[0] = rd_history[1];
    rd_history[1] = 0;
  endfunction: half_delay

endclass: riscv_monitor_after 
