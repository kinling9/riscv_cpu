module test(
  input logic [31:0] a,
  input logic [4:0] shamt,
  output logic [31:0] b
);

logic signed [31:0] a_s;

assign a_s = a;

always_comb begin : test
  b   <= a_s >>> shamt;
end

endmodule
