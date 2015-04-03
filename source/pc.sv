// interface include
`include "pc_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module pc
#(
    parameter PC_INIT = 0
)
(
	input CLK, nRST,
  	pc_if.pc pcif
);

// type import
import cpu_types_pkg::*;

	always_ff @(posedge CLK, negedge nRST)
	begin
    	if (!nRST)
        	pcif.pc_output <= PC_INIT;
    else
    begin
    	if (pcif.PC_WEN) begin
        	pcif.pc_output <= pcif.pc_input;
        end
    end
  end

endmodule