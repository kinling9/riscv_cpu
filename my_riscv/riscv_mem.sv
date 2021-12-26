`ifndef PORT_INCLUDE
`define PORT_INCLUDE
`include "dualport_bus.sv"
`endif
module riscv_mem(
  input logic clk,
  input logic rst_n,
  input logic i_re,
  input logic i_we,
  input logic [2:0] i_funct3,
  input logic [31:0] i_addr,
  input logic [31:0] i_wdata,
  output logic [31:0] o_rdata,
  output logic o_bus_stall,
  dualport_bus.master mem_master 
);

logic [31:0] addr_bus;
logic [1:0] addr_lsb;
// get bus and the lsb of address

logic [31:0] rdata;

logic [3:0] byte_enable;
logic [31:0] wdata;
// byte enable and possible write data

logic re_latch;
logic o_bus_stall_latch;
logic [31:0] rdata_latch;

assign o_bus_stall = (mem_master.rd_req & ~mem_master.rd_gnt) | (mem_master.wr_req & ~mem_master.wr_gnt);
// 总线无响应信号，其他组件在接收到该信号后需要停止数据的传递过程

assign addr_bus = {i_addr[31:2], 2'b00};
assign addr_lsb = i_addr[1:0];

assign mem_master.rd_req = i_re;
assign mem_master.rd_be = i_re ? byte_enable : 4'h0;
assign mem_master.rd_addr = i_re ? addr_bus : 31'b0;
assign rdata = mem_master.rd_data;

assign mem_master.wr_req = i_we;
assign mem_master.wr_be = i_we ? byte_enable : 4'h0;
assign mem_master.wr_addr = i_we ? addr_bus : 31'b0;
assign mem_master.wr_data = i_we ? wdata : 31'b0;

always_comb begin
  casex(i_funct3)
    3'bx00: begin
      if (addr_lsb == 2'b00) begin 
        byte_enable = 4'b0001;
      end else if (addr_lsb == 2'b01) begin
        byte_enable = 4'b0010;
      end else if (addr_lsb == 2'b10) begin
        byte_enable = 4'b0100;
      end else begin
        byte_enable = 4'b1000;
      end
    end
    3'bx01: begin
      if (addr_lsb == 2'b00) begin 
        byte_enable = 4'b0011;
      end else if (addr_lsb == 2'b10) begin
        byte_enable = 4'b1100;
      end else begin
        byte_enable = 4'b0000;
      end
    end
    3'b010: begin
      if (addr_lsb == 2'b00) begin 
        byte_enable = 4'b1111;
      end else begin
        byte_enable = 4'b0000;
      end   
    end
    default: begin
      byte_enable = 4'b0000;
    end
  endcase
end
// bit align for read

always_comb begin
  casex(i_funct3)
    3'bx00: begin
      if (addr_lsb == 2'b00) begin 
        wdata = {24'b0, i_wdata[7:0]};
      end else if (addr_lsb == 2'b01) begin
        wdata = {16'b0, i_wdata[7:0], 8'b0};
      end else if (addr_lsb == 2'b10) begin
        wdata = {8'b0, i_wdata[7:0], 16'b0};
      end else begin
        wdata = {i_wdata[7:0], 24'b0};
      end
    end
    3'bx01: begin
      if (addr_lsb == 2'b00) begin 
        wdata = {16'b0, i_wdata[15:0]};
      end else if (addr_lsb == 2'b10) begin
        wdata = {i_wdata[15:0], 16'b0};
      end else begin
        wdata = 32'b0;
      end
    end
    3'b010: begin
      if (addr_lsb == 2'b00) begin 
        wdata = i_wdata;
      end else begin
        wdata = 32'b0;
      end   
    end
    default: begin
      wdata = 32'b0;
    end
  endcase
end
// bit align for write


always_ff @(posedge clk or negedge rst_n) begin 
  if (~rst_n) begin
    re_latch  <= 1'b0;
    o_bus_stall_latch <= 1'b0;
    rdata_latch <= 0;
  end else begin
    re_latch  <= i_re;
    o_bus_stall_latch <= o_bus_stall;
    rdata_latch <= o_rdata;
  end
end

always_comb begin
  if(re_latch) begin
    if(~o_bus_stall_latch)
      case(i_funct3)
        3'b000: if (addr_lsb==2'b00) o_rdata <= {{24{rdata[7]}}, rdata[7:0]};
                else if(addr_lsb==2'b01) o_rdata <= {{24{rdata[15]}}, rdata[15:8]};
                else if(addr_lsb==2'b10) o_rdata <= {{24{rdata[23]}}, rdata[23:16]};
                else o_rdata <= {{24{rdata[31]}}, rdata[31:24]};
        3'b100: if (addr_lsb==2'b00) o_rdata <= {24'b0, rdata[7:0]};
                else if(addr_lsb==2'b01) o_rdata <= {24'b0, rdata[15: 8]};
                else if(addr_lsb==2'b10) o_rdata <= {24'b0, rdata[23:16]};
                else o_rdata <= {24'b0, rdata[31:24]};
        3'b001: if (addr_lsb==2'b00) o_rdata <= {{16{rdata[15]}}, rdata[15:0]};
                else if(addr_lsb==2'b10) o_rdata <= {{16{rdata[31]}}, rdata[31:16]};
                else o_rdata <= 0;
        3'b101: if (addr_lsb==2'b00) o_rdata <= {16'b0, rdata[15:0]};
                else if(addr_lsb==2'b10) o_rdata <= {16'b0, rdata[31:16]};
                else o_rdata <= 0;
        3'b010: if(addr_lsb==2'b00) o_rdata <= rdata;
                else o_rdata <= 0;
        default: o_rdata <= 0;
      endcase
      else
        o_rdata <= 0;
  end else begin
    o_rdata <= rdata_latch;
  end
end
// FIXME 时序情况未知，可能需要进一步的检查


endmodule