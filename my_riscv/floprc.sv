module flopenrc 
#(parameter WIDTH = 8) (
	logic clk,
  logic rst_n,
  logic clear,
	logic [WIDTH-1:0] d,
	logic [WIDTH-1:0] q
);

always @(posedge clk) begin
  if(~rst_n) begin
    q <= 0;
  end else if(clear) begin
    q <= 0;
  end else begin
    q <= d;
  end
end

endmodule