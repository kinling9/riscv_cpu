module riscv_hazard(
  input logic clk,
  input logic rst_n,
  input logic i_src1_reg_en,
  input logic i_src2_reg_en,
  input logic [31:0] i_src1_reg_addr,
  input logic [31:0] i_src2_reg_addr,
  input logic [31:0] dst_reg_addrE,
  input logic [31:0] dst_reg_addrM,
  input logic [31:0] dst_reg_addrB,
  input logic jalE,
  input logic ex_branchM,
  input logic bus_stallM,
  output logic stallFD,flushFD,
  output logic stallDE,flushDE,
  output logic stallEM,flushEM,
  output logic stallMB,flushMB,
  output logic stallF
);
// 该模块对于冒险信号进行检测，并生成对应的调度信号

logic [3:0] pipeline_stall;
logic [3:0] pipeline_flush;
always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    stallF <= 0;
    pipeline_flush <= 4'b0000;
    pipeline_stall <= 4'b1111;
  end
end
endmodule