module sign_extender
(
	sign_extender_if.se seif
);

assign seif.data_out = seif.ExtOp ? ({16'b1111111111111111, seif.data_in}) : 
							({16'b0000000000000000, seif.data_in});

endmodule