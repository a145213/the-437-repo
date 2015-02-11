module sign_extender
(
	sign_extender_if.se seif
);

assign seif.data_out = seif.ExtOp ? ({{16{seif.data_in[15]}}, seif.data_in}) : 
							({16'b0000000000000000, seif.data_in});

endmodule