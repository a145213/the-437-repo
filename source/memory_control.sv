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
  parameter CPUS = 1;

assign ccif.iload = ccif.ramload;
assign ccif.dload = ccif.ramload;
assign ccif.ramstore = ccif.dstore;

assign ccif.ramWEN = ccif.dWEN;
assign ccif.ramREN = ccif.dREN ? 1 : (ccif.iREN & ~ccif.dWEN);

always_comb begin
  if (ccif.dWEN || ccif.dREN) 
    ccif.ramaddr = ccif.daddr;
  else ccif.ramaddr = ccif.iaddr;

  ccif.iwait = 0;
  ccif.dwait = 0;
  casez(ccif.ramstate)
    FREE: begin
      //ccif.iwait = ccif.iREN;
      //ccif.dwait = ccif.dWEN || ccif.dREN;
      ccif.iwait = 1;
      ccif.dwait = 1;
    end
    BUSY: begin
      //ccif.iwait = 1;
      //ccif.dwait = 1;
      ccif.dwait = ccif.iREN;
      ccif.iwait = ccif.dWEN || ccif.dREN;
    end
    ACCESS: begin
      if (ccif.dWEN || ccif.dREN) begin
        ccif.iwait = 1;
        ccif.dwait = 0;
      end
      else if (ccif.iREN) begin
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

/*
always_comb begin
  ccif.ramWEN = 0;
  //ccif.ramREN = 0;
 // ccif.ramaddr = 0;

  if (ccif.dREN == 1) begin
    ccif.ramREN = 1;
    ccif.ramaddr = ccif.daddr;
  end
  else if (ccif.dWEN == 1) begin
    ccif.ramWEN = 1;
    ccif.ramaddr = ccif.daddr;
  end
  else if (ccif.iREN == 1) begin
    ccif.ramREN = 1;
    ccif.ramaddr = ccif.iaddr;
  end
  ccif.ramaddr = ccif.iaddr;
  ccif.ramREN = ccif.iREN;
end
*/

endmodule
