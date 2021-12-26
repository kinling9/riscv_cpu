module riscv_hazard(
  input logic clk,
  input logic rst_n,
  input logic i_src1_reg_en,
  input logic i_src2_reg_en,
  input logic [4:0] i_src1_reg_addr,
  input logic [4:0] i_src2_reg_addr,
  input logic [4:0] i_dst_reg_addrE,
  input logic [4:0] i_dst_reg_addrM,
  input logic [4:0] i_dst_reg_addrB,
  input logic i_jalD, //FIXME maybe error
  input logic i_ex_branchM,
  input logic i_bus_stallM,
  output logic o_stallFD,o_flushFD,
  output logic o_stallDE,o_flushDE,
  output logic o_stallEM,o_flushEM,
  output logic o_stallMB,o_flushMB,
  output logic o_stallF
);
// 该模块对于冒险信号进行检测，并生成对应的调度信号

logic [3:0] pipeline_stall;
logic [3:0] pipeline_flush;
logic stall_bus, stall_conflict;
assign {o_flushFD,o_flushDE,o_flushEM,o_flushMB} = pipeline_flush;
assign {o_stallFD,o_stallDE,o_stallEM,o_stallMB} = pipeline_stall;
assign o_stallF = stall_bus & stall_conflict;

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    pipeline_flush <= 4'b0000;
    stall_conflict <= 1'b1;
  end else if (i_ex_branchM) begin
    pipeline_flush <= 4'b1110;
    stall_conflict <= 1'b1;
  end else if ((i_src1_reg_en && i_src1_reg_addr != 5'b00000) ||
               (i_src2_reg_en && i_src2_reg_addr != 5'b00000)) begin
    if ((i_dst_reg_addrE == i_src1_reg_addr) || (i_dst_reg_addrE == i_src2_reg_addr)) begin
      pipeline_flush <= 4'b1100;
      stall_conflict <= 1'b0;
    end else if ((i_dst_reg_addrM == i_src1_reg_addr) || (i_dst_reg_addrM == i_src2_reg_addr)) begin
      pipeline_flush <= 4'b1100;
      stall_conflict <= 1'b0;
    end else if ((i_dst_reg_addrB == i_src1_reg_addr) || (i_dst_reg_addrB == i_src2_reg_addr)) begin
      pipeline_flush <= 4'b1100;
      stall_conflict <= 1'b0;
    end
  end else if (i_jalD) begin
    pipeline_flush <= 4'b1000;
    stall_conflict <= 1'b1;
  end else begin
    pipeline_flush <= 4'b0000;
    stall_conflict <= 1'b1;
  end
end

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    pipeline_stall <= 4'b1111;
    stall_bus <= 1;
  end else if (i_bus_stallM) begin
    pipeline_stall <= 4'b0001;
    stall_bus <= 0;
  end else begin
    pipeline_stall <= 4'b1111;
    stall_bus <= 1;
  end
end

endmodule