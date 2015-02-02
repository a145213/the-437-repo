module sign_extender
(
	input [15:0] data_in,
	input logic ExtOp,
	output [31:0] data_out 
);

assign data_out = (ExtOp) ? {16'b1111111111111111, data_in} : 
							{16'b0000000000000000, data_in};

endmodule