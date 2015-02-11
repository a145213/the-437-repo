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

	always_ff @(posedge CLK, negedge nRST)
	begin
    	if (!nRST)
        	pcif.pc_output <= 32'b0;
    else
    begin
    	if (pcif.PC_WEN) begin
        	pcif.pc_output <= pcif.pc_input;
        end
    end
  end

endmodule