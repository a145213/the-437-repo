`ifndef PC_IF_VH
`define PC_IF_VH

// ram memory types
`include "cpu_types_pkg.vh"

interface pc_if;
	// import types
	import cpu_types_pkg::*;

	logic PC_WEN;
	word_t pc_input;
	word_t pc_output;

	modport pc (
		input PC_WEN, pc_input,
		output pc_output
	);

	modport tb (
		output PC_WEN, pc_input,
		input pc_output
	);

endinterface
`endif