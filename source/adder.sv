module adder(
    data_in1,
    data_in2,
    data_out
);

	input   [31:0]  data_in1;
	input   [31:0]  data_in2;
	output  [31:0]  data_out;

	reg [31:0] data_out;
	
always_comb begin
	data_out = data_in1 + data_in2;
end

endmodule