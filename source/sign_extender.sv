module sign_extender
(
	sign_extender_if.se seif
);

assign seif.data_out = seif.ExtOp ? ({{16{seif.data_in[15]}}, seif.data_in}) : 
							({16'h0000, seif.data_in});

endmodule