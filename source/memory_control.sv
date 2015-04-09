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
word_t snoopaddr, nxt_snoopaddr;

// Latch ccsnoopaddr
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
    snoopaddr <= nxt_snoopaddr;
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
      nxt_state = (ccif.cctrans[initiator] || ccif.dWEN[target])?(REPLY):(ARBITRATE);
    end
    IFETCH: begin
      nxt_state = (ccif.iwait[initiator])?(IFETCH):(ARBITRATE);
    end
    default: begin
      nxt_state = ARBITRATE;
    end
  endcase
end

// Output logic
always_comb begin
  ccif.iwait[0] = 1'b1;
  ccif.iwait[1] = 1'b1;
  ccif.dwait[0] = 1'b1;
  ccif.dwait[1] = 1'b1;
  ccif.iload = 0;
  ccif.dload = 0;
  ccif.ccwait = 0;
  ccif.ccinv = 0;
  ccif.ccsnoopaddr = 0;
  ccif.ramWEN = 0;
  ccif.ramREN = 0;
  ccif.ramaddr = 0;
  ccif.ramstore = 0;
  nxt_initiator = initiator;
  nxt_target = target;
  nxt_arb = arb;
  nxt_snoopaddr = snoopaddr;

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

        // Grant INITIATOR the bus and tell all others to wait
        ccif.ccwait[nxt_initiator] = 1'b0;
        ccif.ccwait[nxt_target] = 1'b1;
        nxt_snoopaddr = ccif.daddr[nxt_initiator];

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
    end
    SNOOP: begin
      ccif.ccwait[initiator] = 1'b0;
      ccif.ccwait[target] = 1'b1;

      // If INITIATOR is being modified (BusRdX), then 
      // let TARGET know an invalidation should take
      // place if need be.
      if (ccif.ccwrite[initiator]) begin
        ccif.ccinv[target] = 1'b1;
      end

      // Snoop the other caches
      ccif.ccsnoopaddr[target] = snoopaddr;
    end
    REPLY: begin
      ccif.ccwait[initiator] = 1'b0;
      ccif.ccwait[target] = 1'b1;

      // If there was a "bus hit" then we write back and
      // do a cache-to-cache cctransfer, otherwise we just
      // get the data straight from memory.
      // Use dWEN instead of ccwrite
      if (ccif.cctrans[initiator] && ccif.dWEN[target]) begin
        // Cache-to-cache cctransfer w/ WB
        ccif.ramWEN = ccif.dWEN[target];
        ccif.ramREN = ccif.dREN[target];
        ccif.ramaddr = ccif.daddr[target];
        ccif.ramstore = ccif.dstore[target];
        ccif.dload[initiator] = ccif.dstore[target];
        waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
        //waitram(ccif.ramstate, ccif.dWEN[target], ccif.dREN[target], ccif.iREN[target], ccif.iwait[target], ccif.dwait[target]);
      end else if (ccif.cctrans[initiator]) begin
        // Get data from memory
        ccif.ramWEN = ccif.dWEN[initiator];
        ccif.ramREN = ccif.dREN[initiator];
        ccif.ramaddr = ccif.daddr[initiator];
        ccif.dload[initiator] = ccif.ramload;
        waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
      end
    end
    IFETCH: begin
      //ccif.ramaddr = ccif.iaddr[initiator];
      //ccif.ramREN = ccif.iREN[initiator];
      //ccif.ramWEN = 1'b0;
      //ccif.iload[initiator] = ccif.ramload;
      //waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
    end
  endcase
  
  if (state == IFETCH || state == ARBITRATE) begin
    ccif.ramaddr = ccif.iaddr[initiator];
    ccif.ramREN = ccif.iREN[initiator];
    ccif.ramWEN = 1'b0;
    ccif.iload[initiator] = ccif.ramload;
    waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
  end
  
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