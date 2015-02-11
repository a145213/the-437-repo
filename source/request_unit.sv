`include "cpu_types_pkg.vh"
`include "request_unit_if.vh"
`include "datapath_cache_if.vh"


module request_unit
(
	input logic CLK, nRST,
	request_unit_if.ru ruif
);

import cpu_types_pkg::*;

assign ruif.PC_WEN = ruif.ihit & !ruif.dhit;


always_ff @ (posedge CLK, negedge nRST) begin
	if (!nRST) begin
		ruif.dmemREN <= 0;
		ruif.dmemWEN <= 0;
	end
	else begin
		if (ruif.ihit) begin
			ruif.dmemREN <= ruif.dREN;
			ruif.dmemWEN <= ruif.dWEN;
		end
		else if (ruif.dhit) begin
			ruif.dmemREN <= 0;
			ruif.dmemWEN <= 0;
		end
	end
	

end

endmodule