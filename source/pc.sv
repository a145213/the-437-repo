// interface include
`include "pc_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module pc
(
	input CLK, nRST,
  	pc_if.pc pcif
);

// type import
import cpu_types_pkg::*;