`include "ram.sv"
module ram_bus(
  input logic clk,
  input logic rst_n,
  dualport_bus.slave mem_slave
);
logic [9:0] cell_rd_addr, cell_wr_addr;

assign cell_rd_addr = mem_slave.rd_addr[11:2];
assign cell_wr_addr = mem_slave.wr_addr[11:2];

assign mem_slave.rd_gnt = mem_slave.rd_req;
assign mem_slave.wr_gnt = mem_slave.wr_req;
    
ram ram_block_inst_0(
  .clk(clk),
  .rst_n(rst_n),
  .i_we(mem_slave.wr_req & mem_slave.wr_be[0]),
  .i_waddr(cell_wr_addr),
  .i_raddr(cell_rd_addr),
  .i_wdata(mem_slave.wr_data[7:0]),
  .o_rdata(mem_slave.rd_data[7:0])
);
ram ram_block_inst_1(
  .clk(clk),
  .rst_n(rst_n),
  .i_we(mem_slave.wr_req & mem_slave.wr_be[1]),
  .i_waddr(cell_wr_addr),
  .i_raddr(cell_rd_addr),
  .i_wdata(mem_slave.wr_data[15:8]),
  .o_rdata(mem_slave.rd_data[15:8])
);
ram ram_block_inst_2(
  .clk(clk),
  .rst_n(rst_n),
  .i_we(mem_slave.wr_req & mem_slave.wr_be[2]),
  .i_waddr(cell_wr_addr),
  .i_raddr(cell_rd_addr),
  .i_wdata(mem_slave.wr_data[23:16]),
  .o_rdata(mem_slave.rd_data[23:16])
);
ram ram_block_inst_3(
  .clk(clk),
  .rst_n(rst_n),
  .i_we(mem_slave.wr_req & mem_slave.wr_be[3]),
  .i_waddr(cell_wr_addr),
  .i_raddr(cell_rd_addr),
  .i_wdata(mem_slave.wr_data[31:24]),
  .o_rdata(mem_slave.rd_data[31:24])
);

endmodule