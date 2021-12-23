module riscv_if(
  input logic clk,
  input logic rst_n,
  input logic i_ex_jmp,
  input logic i_id_jmp,
  input logic i_stall,
  input logic [31:0] i_boot_addr,
  input logic [31:0] i_ex_target,
  input logic [31:0] i_id_target, 
  output logic [31:0] o_pc,
  output logic [31:0] o_instr,
  dualport_bus.master instr_master 
);

// for hazard, ex jmp is more prior than id jmp
// pipeline flush is done outside the IF stage

// due to bus separation, we only need to consider the stall from
// bus master

logic [31:0] npc;
logic [31:0] instr_hold;
logic bus_busy;
logic stall_n;

assign instr_master.wr_req = 1'b0;     
assign instr_master.wr_be = 4'b0;
assign instr_master.wr_addr = 32'b0;
assign instr_master.wr_data = 32'b0;
// core never write via instruction bus

assign instr_master.rd_req  = 1'b1;
assign instr_master.rd_be   = 4'hf;
// core requests the input of all time

assign instr_master.rd_addr = npc;

always_comb begin
  if (i_ex_jmp) begin
    npc = i_ex_target;
  end else if (i_id_jmp) begin
    npc = i_id_target;
  end else if (bus_busy) begin
    npc = o_pc;
  end else begin
    npc = o_pc + 4;
  end
end

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    bus_busy <= 1'b0;
    stall_n <= 1'b0;
    instr_hold <= 32'b0;
  end else begin
    bus_busy <= (instr_master.rd_req & ~instr_master.rd_gnt);
    stall_n <= ~i_stall;
    instr_hold <= o_instr;
  end
end
// check the bus is busy or not

always_ff @(posedge clk or negedge rst_n) begin
  if (stall_n) begin
    o_instr <= instr_hold;
  end else if (bus_busy) begin
    o_instr <= 32'b0;
  end else begin
    o_instr <= instr_master.rd_data;
  end 
end
// launch the instructions
// for busy sequences and stall, stop the launch
// FIXME check whether the launch instr match the output pc or not

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    o_pc <= {i_boot_addr[31:2], 2'b00} - 4;
    // FIXME check the first launch pc
  end else begin
    o_pc <= npc;
  end
end
// launch the pc

endmodule

