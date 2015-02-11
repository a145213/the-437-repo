`ifndef SIGN_EXTENDER_IF_VH
`define SIGN_EXTENDER_IF_VH

`include "cpu_types_pkg.vh"

interface sign_extender_if;
	// import types
	import cpu_types_pkg::*;

	logic [IMM_W-1:0] data_in;
	logic ExtOp;
	word_t data_out;

	modport se (
		input data_in, ExtOp,
		output data_out
	);	

endinterface
`endif