`ifndef PORT_INCLUDE
`define PORT_INCLUDE
`include "dualport_bus.sv"
`endif
module instr_rom(
  input logic clk,
  input logic rst_n,
  dualport_bus.slave instr_slave
);
localparam  INSTR_CNT = 30'd22;
wire [0:INSTR_CNT-1] [31:0] instr_rom_cell = {
  32'h00708093,   
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h00110863,
  // beq x1,x2,16
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00720213,  
  // addi x4,x4,7
  32'h00728293,   
  // addi x5,x5,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00708093,   
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00708093,   
  // addi x1,x1,7
  32'h00000013,   
  // addi x0,x0,0 NOP
  32'h00000013,
  // addi x0,x0,0 NOP
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'h00708093,  
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3,   
  // add  x1,x2,x3
  32'hff9ff06f,   
  // jal pc -8
  32'h00708093,   
  // addi x1,x1,7
  32'h00710113,   
  // addi x2,x2,7
  32'h002081b3    
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

  // 32'h00708093,   // 0x0000000c
  // // addi x1,x1,7
  // 32'h00000013,   
  // // addi x0,x0,0 NOP
  // 32'h00000013,
  // // addi x0,x0,0 NOP
  // 32'h00710113,   
  // // addi x2,x2,7
  // 32'h002081b3,   
  // // add  x1,x2,x3
  // 32'h00708093,  
  // // addi x1,x1,7
  // 32'h00710113,   
  // // addi x2,x2,7
  // 32'h002081b3,   
  // // add  x1,x2,x3
  // 32'hff9ff06f,   
  // // jal pc-4x4
  // 32'h00708093,   
  // // addi x1,x1,7
  // 32'h00710113,   
  // // addi x2,x2,7
  // 32'h002081b3    
  // // add  x1,x2,x3