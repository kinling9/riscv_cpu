`ifndef PORT_INCLUDE
`define PORT_INCLUDE
`include "dualport_bus.sv"
`endif
module instr_rom(
  input logic clk,
  input logic rst_n,
  dualport_bus.slave instr_slave
);
localparam  INSTR_CNT = 30'd3;
wire [0:INSTR_CNT-1] [31:0] instr_rom_cell = {
  32'h00708093,   // 0x00000000
  // addi x1,x1,10
  32'h00710113,   // 0x00000004
  // addi x2,x2,10
  32'h002081b3    // 0x00000008
  // add  x1,x2,x3
};

logic [29:0] cell_rd_addr;

assign instr_slave.rd_gnt = instr_slave.rd_req;
assign instr_slave.wr_gnt = instr_slave.wr_req;
assign cell_rd_addr = instr_slave.rd_addr[31:2];
always_ff @ (posedge clk or negedge rst_n) begin
  if(~rst_n)
    instr_slave.rd_data <= 0;
  else begin
    if(instr_slave.rd_req)
      instr_slave.rd_data <= (cell_rd_addr>=INSTR_CNT) ? 0 : instr_rom_cell[cell_rd_addr];
    else
      instr_slave.rd_data <= 0;
    end
end

endmodule