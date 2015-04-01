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

typedef enum logic [1:0] {
  ARBITRATE = 2'b00,
  SNOOP = 2'b01,
  REPLY = 2'b10,
  IFETCH = 2'b11
} bus_state;
bus_state state;
bus_state nxt_state;
logic arb, nxt_arb;
logic initiator, nxt_initiator;
logic target, nxt_target;

always_ff @(posedge CLK, negedge nRST) begin
  if (!nRST) begin
    state <= ARBITRATE;
    arb <= 0;
    initiator <= 0;
    target <= 0;
  end else begin
    state <= nxt_state;
    arb <= nxt_arb;
    initiator <= nxt_initiator;
    target <= nxt_target;
  end
end

// Next state logic
always_comb begin
  nxt_state = state;
  casez(state)
    ARBITRATE: begin
      if (ccif.dWEN[0] || ccif.dREN[0] || ccif.dWEN[1] || ccif.dREN[1]) begin
        nxt_state = SNOOP;
      end else if (ccif.iREN[0] || ccif.iREN[1]) begin
        nxt_state = IFETCH;
      end
    end
    SNOOP: begin
      nxt_state = REPLY;
    end
    REPLY: begin
      nxt_state = (!ccif.cctrans[0] && !ccif.cctrans[1])?(ARBITRATE):(SNOOP);
    end
    IFETCH: begin

    end
    default: begin
      nxt_state = ARBITRATE;
    end
  endcase
end

// Output logic
always_comb begin
  casez(state)
    ARBITRATE: begin
      // Arbitrate between caches
      if (ccif.dWEN[0] || ccif.dREN[0] || ccif.dWEN[1] || ccif.dREN[1]) begin
        // Arbitrate between cores
        if (ccif.cctrans[0] && ccif.cctrans[1]) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (ccif.cctrans[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (ccif.cctrans[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b0;
        end
      end else if (ccif.iREN[0] || ccif.iREN[1]) begin
        // Arbitrate between cores
        if (ccif.iREN[0] && ccif.iREN[1]) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (ccif.iREN[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (ccif.iREN[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b0;
        end
      end

      // Grant INITIATOR the bus and tell all others to wait
      ccif.ccwait[nxt_initiator] = 1'b0;
      ccif.ccwait[nxt_target] = 1'b1;
    end
    SNOOP: begin
      // If INITIATOR is being modified (BusRdX), then 
      // let TARGET know an invalidation should take
      // place if need be.
      if (ccif.ccwrite[initiator]) begin
        ccif.ccinv[target] = 1'b1;
      end

      // Snoop the other caches
      ccif.ccsnoopaddr[target] = ccif.daddr[initiator];

    end
    REPLY: begin
      // If there was a "bus hit" then we write back and
      // do a cache-to-cache cctransfer, otherwise we just
      // get the data straight from memory.
      if (ccif.cctrans[0] && ccif.cctrans[1]) begin
        // Cache-to-cache cctransfer w/ WB
        ccif.ramWEN = ccif.dWEN[target];
        ccif.ramREN = ccif.dREN[target];
        ccif.ramaddr = ccif.daddr[target];
        ccif.ramstore = ccif.dstore[target];
        ccif.dload[initiator] = ccif.dstore[target];
        waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
      end else begin
        // Get data from memory
        ccif.ramWEN = ccif.dWEN[initiator];
        ccif.ramREN = ccif.dREN[initiator];
        ccif.ramaddr = ccif.daddr[initiator];
        ccif.dload[initiator] = ccif.ramload;
        waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
      end
    end
    IFETCH: begin
      ccif.ramaddr = ccif.iaddr;
      ccif.ramREN = ccif.iREN[initiator];
      ccif.ramWEN = 1'b0;
      ccif.iload[initiator] = ccif.ramload;
      waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
    end
  endcase
end

task waitram (
    input ramstate_t rstate, 
    input logic dwen, 
    input logic dren, 
    input logic iren, 
    output logic iw, 
    output logic dw
  );
  iw = 0;
  dw = 0;
  casez(rstate)
    FREE: begin
      iw = 1;
      dw = 1;
    end
    BUSY: begin
      iw = 1;
      dw = 1;
    end
    ACCESS: begin
      if (dwen || dren) begin
        iw = 1;
        dw = 0;
      end else if (iren) begin
        iw = 0;
        dw = 1;
      end
    end
    ERROR: begin
      iw = 1;
      dw = 1;
    end
  endcase
endtask

endmodule
