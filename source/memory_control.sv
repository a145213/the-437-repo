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

assign ccif.iload[0] = ccif.ramload;
assign ccif.dload[0] = ccif.ramload;
assign ccif.ramstore = ccif.dstore[0];

always_comb begin
  ccif.iwait[0] = 0;
  ccif.dwait[0] = 0;
  casez(ccif.ramstate)
    FREE: begin
      ccif.iwait[0] = ccif.iREN[0];
      ccif.dwait[0] = ccif.dWEN[0] || ccif.dREN[0];
    end
    BUSY: begin
      ccif.iwait[0] = 1;
      ccif.dwait[0] = 1;
    end
    ACCESS: begin
      if (ccif.dWEN[0] || ccif.dREN[0]) begin
        ccif.iwait[0] = 1;
        ccif.dwait[0] = 0;
      end
      else if (ccif.iREN[0]) begin
        ccif.iwait[0] = 0;
        ccif.dwait[0] = 1;
      end
    end
    ERROR: begin
    ccif.iwait[0] = 1;
    ccif.dwait[0] = 1;
    end
  endcase
end

always_comb begin
  ccif.ramWEN = 0;
  ccif.ramREN = 0;
  ccif.ramaddr = 0;

  if (ccif.dREN[0] == 1) begin
    ccif.ramREN[0] = 1;
    ccif.ramaddr = ccif.daddr;
  end
  else if (ccif.dWEN[0] == 1) begin
    ccif.ramWEN[0] = 1;
    ccif.ramaddr = ccif.daddr;
  end
  else if (ccif.iREN[0] == 1) begin
    ccif.ramREN[0] = 1;
    ccif.ramaddr = ccif.iaddr;
  end
end


endmodule
