//and or xor add sub andi ori xori sw lw beq jal
typedef enum bit[3:0] {UNKNOWN_INSTR, AND, OR, XOR, ADD, SUB, ANDI, ORI, XORI, SW, LW, BEQ, JAL} instr_e;

typedef struct { 
  bit req;
  bit [31:0] addr;
} mem_rd_t;

typedef struct { // 
  bit req;
  bit [31:0] addr;
  bit [31:0] data;
} mem_wr_t;

class riscv_transaction extends uvm_sequence_item;
  rand instr_e instr;
  rand bit [11:0] imm;
  rand bit [31:12] imm_jal;
  rand bit [4:0] rs1;
  rand bit [4:0] rs2;
  rand bit [4:0] rd;
  constraint my_constraint {
    instr inside {[AND: JAL]};
    imm_jal inside {[0: 9'b1_1111_1111]};
    // rs1 inside {[1:3]};
    // rs2 inside {[1:3]};
    // rd inside {[1:3]};
  }
  bit [31:0] pc;

  rand bit [31:0] mem_rd_data;
  mem_rd_t mem_rd;
  mem_wr_t mem_wr;

  bit valid_instr;

  function new(string name = "");
    super.new(name);
  endfunction: new

  `uvm_object_utils_begin(riscv_transaction)
    `uvm_field_enum(instr_e, instr, UVM_ALL_ON)
    `uvm_field_int(imm, UVM_ALL_ON)
    `uvm_field_int(imm_jal, UVM_ALL_ON)
    `uvm_field_int(rs1, UVM_ALL_ON)
    `uvm_field_int(rs2, UVM_ALL_ON)
    `uvm_field_int(rd, UVM_ALL_ON)
    `uvm_field_int(pc, UVM_ALL_ON)
    `uvm_field_int(mem_rd_data, UVM_ALL_ON)
    `uvm_field_int(mem_rd.req, UVM_ALL_ON)
    `uvm_field_int(mem_rd.addr, UVM_ALL_ON)
    `uvm_field_int(mem_wr.req, UVM_ALL_ON)
    `uvm_field_int(mem_wr.data, UVM_ALL_ON)
    `uvm_field_int(mem_wr.addr, UVM_ALL_ON)
  `uvm_object_utils_end
endclass: riscv_transaction

class riscv_sequence extends uvm_sequence#(riscv_transaction);
  `uvm_object_utils(riscv_sequence)

  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    riscv_transaction rv_tx;
    
    repeat(1000) begin
      rv_tx = riscv_transaction::type_id::create(.name("rv_tx"), .contxt(get_full_name()));

      start_item(rv_tx);
      assert(rv_tx.randomize());
      //`uvm_info("rv_sequence", rv_tx.sprint(), UVM_LOW);
      finish_item(rv_tx);
    end
  endtask: body
endclass: riscv_sequence

typedef uvm_sequencer#(riscv_transaction) riscv_sequencer;
