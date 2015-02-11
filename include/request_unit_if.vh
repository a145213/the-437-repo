`ifndef REQUEST_UNIT_IF_VH
`define REQUEST_UNIT_IF_VH

// ram memory types
`include "cpu_types_pkg.vh"

interface request_unit_if;
	// import types
	import cpu_types_pkg::*;

	logic dmemREN, dmemWEN, imemREN;
	logic ihit, dhit;
	logic dWEN, dREN, iREN;
	logic PC_WEN;

	modport ru (
		input ihit, dhit, dREN, dWEN, iREN,
		output dmemREN, dmemWEN, imemREN, PC_WEN
	);

	modport tb (
		output ihit, dhit, dREN, dWEN, iREN,
		input dmemREN, dmemWEN, imemREN, PC_WEN
	);

endinterface
`endif