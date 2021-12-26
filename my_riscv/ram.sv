`ifndef PORT_INCLUDE
`define PORT_INCLUDE
`include "dualport_bus.sv"
`endif
module ram(            // 1024B
  input logic clk,
  input logic rst_n,
  input logic i_we,
  input logic [9:0] i_waddr, i_raddr,
  input logic [7:0] i_wdata,
  output logic [7:0] o_rdata
);

logic [7:0] data_ram_cell [0:1023];
    
always_ff @ (posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    o_rdata <= 0;
  end else begin
    o_rdata <= data_ram_cell[i_raddr];
  end
end

always_ff @ (posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    data_ram_cell <= '{default:'0};
  end else if (i_we) begin
    data_ram_cell[i_waddr] <= i_wdata;
  end
end

endmodule