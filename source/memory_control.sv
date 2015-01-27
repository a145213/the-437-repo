/*
  Eric Villasenor
  evillase@gmail.com

  this block is the coherence protocol
  and artibtration for ram
*/

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
  input CLK, nRST,
  cache_control_if.cc ccif
);
  // type import
  import cpu_types_pkg::*;

  // number of cpus for cc
  parameter CPUS = 2;

assign ccif.iload = ccif.ramload;
assign ccif.dload = ccif.ramload;
assign ccif.ramstore = ccif.dstore;

always_comb begin
  ccif.iwait = 0;
  ccif.dwait = 0;
  casez(ccif.ramstate)
    FREE: begin
      ccif.iwait = 0;
      ccif.dwait = 0;
    end
    BUSY: begin
      ccif.iwait = 1;
      ccif.dwait = 1;
    end
    ACCESS: begin
      if (ccif.dWEN[0] || ccif.dREN[0]) begin
        ccif.iwait = 1;
        ccif.dwait = 0;
      end
      else if (ccif.iREN[0]) begin
        ccif.iwait = 0;
        ccif.dwait = 1;
      end
    end
    ERROR: begin
    ccif.iwait = 1;
    ccif.dwait = 1;
    end
  endcase
end

endmodule
