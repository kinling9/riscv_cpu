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

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    data_ram_cell <= '{default:'0};
    o_rdata1 <= 31'b0;
    o_rdata2 <= 31'b0;
  end else begin
    o_rdata1 <= data_ram_cell[i_raddr1];
    o_rdata2 <= data_ram_cell[i_raddr2];
    if (i_we) begin
      data_ram_cell[i_waddr] <= i_wdata;
    end
  end
end

endmodule