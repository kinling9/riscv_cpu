`include "ram_32x32.sv"
module riscv_reg(
  input logic clk,
  input logic rst_n,
  input logic i_re1,
  input logic [4:0]  i_raddr1,
  input logic i_re2,
  input logic [4:0]  i_raddr2,
  input logic i_we,
  input logic [4:0] i_waddr,
  input logic [31:0] i_wdata,
  output logic [31:0] o_rdata1,
  output logic [31:0] o_rdata2
);

// control module for register 
// rs0 can't be write and it will always be 0
// use override to make sure the output is 0

// data forward will be implemented outside 

logic override1;
logic override2;
logic [31:0] ov_rdata1;
logic [31:0] ov_rdata2;
logic [31:0] or_rdata1;
logic [31:0] or_rdata2;

assign o_rdata1 = override1 ? ov_rdata1 : or_rdata1;
assign o_rdata2 = override2 ? ov_rdata2 : or_rdata2;

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    ov_rdata1 <= 0;
    override1 <= 1;
  end else begin
    if (~i_re1 || i_raddr1 == 5'b0000) begin
      ov_rdata1 <= 0;
      override1 <= 1;
    end else begin
      override1 <= 0;
    end
  end
end

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    ov_rdata2 <= 0;
    override2 <= 1;
  end else begin
    if (~i_re1 || i_raddr1 == 5'b0000) begin
      ov_rdata2 <= 0;
      override2 <= 1;
    end else begin
      override2 <= 0;
    end
  end
end

ram32x32 regfile(
  .clk(clk),
  .rst_n(rst_n),
  .i_we(i_we),
  .i_waddr(i_waddr),
  .i_wdata(i_wdata),
  .i_raddr1(i_raddr1),
  .i_raddr2(i_raddr2),
  .o_rdata1(or_rdata1),
  .o_rdata2(or_rdata2)
);

endmodule