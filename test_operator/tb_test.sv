`timescale 1ns/10ps
`include "test.sv"

module time_unit;
	initial $timeformat(-9,1," ns",9);
endmodule

module tb_test;

  logic clk;
  logic [31:0] a;
  logic [31:0] b;
  logic [4:0] shamt;

  int counter_finish;

  test DUT(.a(a),.shamt(shamt),.b(b));

  logic        [9:0] c;
  logic signed [9:0] d;
  logic signed [9:0] a_signed;
  logic        [9:0] a_unsigned;

  initial begin
    c = 10'b11_0101_0101;
    d = c;
    a_unsigned   = d >>> 2;
    // a_unsigned = a_signed;
    // $display("a_signed = %d\n",a_signed);
    // $display("a_unsigned = %d\n",a_unsigned);
  end

  initial begin
    clk = 1'b0;
    a = 32'b0;
    shamt = 4'b0;
  end

  initial begin
		#20;
		forever #20 clk = ! clk;
	end
  

  always@(posedge clk) begin
		counter_finish = counter_finish + 1;
		
		if(counter_finish == 30) $finish;
	end

  always @(posedge clk) begin
    a = 32'b01000000_00000000_00000000_00000000;
    shamt = counter_finish;
  end
  
  always @(posedge clk) begin
    if (shamt > 1) begin
      #5;
      $display("%d >>> %d = %d\n",a,shamt,b);
      // $display("%d >>> %d = %d\n",$signed(a),shamt,$signed(a) >>> shamt);
    end
  end
endmodule
