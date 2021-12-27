module ram32x32 (
  input logic clk,
  input logic rst_n,
  input logic i_we,
  input logic [ 4:0] i_waddr,
  input logic [31:0] i_wdata,
  input logic [ 4:0] i_raddr1,
  input logic [ 4:0] i_raddr2,
  output logic [31:0] o_rdata1,
  output logic [31:0] o_rdata2
);
// a dual port ram for general registers

logic [31:0] data_ram_cell [0:31];
// ram data

// logic override1;
// logic override2;
// logic [31:0] ov_rdata1;
// logic [31:0] ov_rdata2;
// logic [31:0] or_rdata1;
// logic [31:0] or_rdata2;
// assign o_rdata1 = override1 ? ov_rdata1 : or_rdata1;
// assign o_rdata2 = override2 ? ov_rdata2 : or_rdata2;

// always_ff @(posedge clk) begin
//   if (i_raddr1 == i_waddr) begin
//     ov_rdata1 <= i_wdata;
//     override1 <= 1;
//   end else begin
//     override1 <= 0;
//   end
// end

// always_ff @(posedge clk) begin
//   if (i_raddr2 == i_waddr) begin
//     ov_rdata2 <= i_wdata;
//     override2 <= 1;
//   end else begin
//     override2 <= 0;
//   end
// end

always_comb begin
  if (~rst_n) begin
    data_ram_cell = '{default:'0};
    o_rdata1 = 31'b0;
    o_rdata2 = 31'b0;
  end else begin
    if (i_we) begin
      data_ram_cell[i_waddr] = i_wdata;
    end
    o_rdata1 = data_ram_cell[i_raddr1];
    o_rdata2 = data_ram_cell[i_raddr2];
  end
end

endmodule