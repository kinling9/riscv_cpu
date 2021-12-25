module flopenrc 
#(parameter WIDTH = 8) (
	input logic clk,
  input logic rst_n,
  input logic clear,
	input logic [WIDTH-1:0] d,
	output logic [WIDTH-1:0] q
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