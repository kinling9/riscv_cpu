//and or xor add sub andi ori xori sw lw beq jal
typedef enum bit[3:0] {UNKNOWN_INSTR, AND, OR, XOR, ADD, SUB, ANDI, ORI, XORI, SW, LW, BEQ, JAL} instr_e;
class riscv_transaction extends uvm_sequence_item;
  rand bit[1:0] ina;
  rand bit[1:0] inb;
  bit[2:0] out;

  rand instr_e instr;
  rand bit [11:0] imm;
  rand bit [31:12] imm_jal;
  rand bit [4:0] rs1;
  rand bit [4:0] rs2;
  rand bit [4:0] rd;
  constraint my_constraint {
    instr != UNKNOWN_INSTR;
    imm_jal <= 9'b1_1111_1111;
  }
  bit [31:0] pc;

  rand bit [31:0] mem_rd_data;
  bit mem_rd_req;
  bit mem_wr_req;
  bit [31:0] mem_rd_addr;
  bit [31:0] mem_wr_addr;
  bit [31:0] mem_wr_data;

  function new(string name = "");
    super.new(name);
  endfunction: new

  `uvm_object_utils_begin(riscv_transaction)
    `uvm_field_int(ina, UVM_ALL_ON)
    `uvm_field_int(inb, UVM_ALL_ON)
    `uvm_field_int(out, UVM_ALL_ON)
    `uvm_field_enum(instr_e, instr, UVM_ALL_ON)
    `uvm_field_int(imm, UVM_ALL_ON)
    `uvm_field_int(imm_jal, UVM_ALL_ON)
    `uvm_field_int(rs1, UVM_ALL_ON)
    `uvm_field_int(rs2, UVM_ALL_ON)
    `uvm_field_int(rd, UVM_ALL_ON)
    `uvm_field_int(pc, UVM_ALL_ON)
    `uvm_field_int(mem_rd_data, UVM_ALL_ON)
    `uvm_field_int(mem_rd_req, UVM_ALL_ON)
    `uvm_field_int(mem_wr_req, UVM_ALL_ON)
    `uvm_field_int(mem_rd_addr, UVM_ALL_ON)
    `uvm_field_int(mem_wr_data, UVM_ALL_ON)
    `uvm_field_int(mem_wr_addr, UVM_ALL_ON)
  `uvm_object_utils_end
endclass: riscv_transaction

class riscv_sequence extends uvm_sequence#(riscv_transaction);
  `uvm_object_utils(riscv_sequence)

  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    riscv_transaction rv_tx;
    
    repeat(5) begin
      rv_tx = riscv_transaction::type_id::create(.name("rv_tx"), .contxt(get_full_name()));

      start_item(rv_tx);
      assert(rv_tx.randomize());
      //`uvm_info("rv_sequence", rv_tx.sprint(), UVM_LOW);
      finish_item(rv_tx);
    end
  endtask: body
endclass: riscv_sequence

typedef uvm_sequencer#(riscv_transaction) riscv_sequencer;
