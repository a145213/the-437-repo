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

typedef enum logic [2:0] {
  ARBITRATE = 3'b000,
  SNOOP = 3'b001,
  REPLY = 3'b010,
  IFETCH = 3'b011,
  HALT_WRITE = 3'b100,
  RELAY = 3'b101
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
    snoopaddr <= 0;
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
      if ((ccif.dWEN[0] || ccif.dREN[0] || ccif.dWEN[1] || ccif.dREN[1])) begin
        if (ccif.cctrans[0] || ccif.cctrans[1]) begin
          nxt_state = SNOOP;
        end else begin
          nxt_state = HALT_WRITE;
        end
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
    HALT_WRITE: begin
      nxt_state = (ccif.dwait[initiator])?(HALT_WRITE):(ARBITRATE);
    end
    default: begin
      nxt_state = ARBITRATE;
    end
  endcase
end

// Output logic
always @(*) begin
  ccif.iwait[0] = 1'b1;
  ccif.iwait[1] = 1'b1;
  ccif.dwait[0] = 1'b1;
  ccif.dwait[1] = 1'b1;
  ccif.iload[0] = '0;
  ccif.iload[1] = '0;
  ccif.dload[0] = '0;
  ccif.dload[1] = '0;
  ccif.ccwait[0] = 1'b0;
  ccif.ccwait[1] = 1'b0;
  ccif.ccinv[0] = 1'b0;
  ccif.ccinv[1] = 1'b0;
  ccif.ccsnoopaddr[0] = '0;
  ccif.ccsnoopaddr[1] = '0;
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
        end else if (ccif.dWEN[0] && ccif.dWEN[1]) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (ccif.dWEN[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (ccif.dWEN[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b1;
        end

        // Grant INITIATOR the bus and tell all others to wait
        if (ccif.cctrans[0] || ccif.cctrans[1]) begin
          ccif.ccwait[nxt_initiator] = 1'b0;
          ccif.ccwait[nxt_target] = 1'b1;
          nxt_snoopaddr = ccif.daddr[nxt_initiator];
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
      if (ccif.ccwrite[initiator]) begin
        ccif.ccinv[target] = 1'b1;
      end
      

      // If there was a "bus hit" then we write back and
      // do a cache-to-cache cctransfer, otherwise we just
      // get the data straight from memory.
      // Use dWEN instead of ccwrite
      if (ccif.dWEN[target]) begin
        // Cache-to-cache cctransfer w/ WB
        ccif.ramWEN = ccif.dWEN[target];
        ccif.ramREN = ccif.dREN[target];
        ccif.ramaddr = ccif.daddr[target];
        ccif.ramstore = ccif.dstore[target];
        ccif.dload[initiator] = ccif.dstore[target];
        waitram(ccif.ramstate, ccif.dWEN[target], ccif.dREN[target], ccif.iREN[target], ccif.iwait[initiator], ccif.dwait[initiator]);
        waitram(ccif.ramstate, ccif.dWEN[target], ccif.dREN[target], ccif.iREN[target], ccif.iwait[target], ccif.dwait[target]);
      end else begin
        // Get data from memory
        ccif.ramWEN = ccif.dWEN[initiator];
        ccif.ramREN = ccif.dREN[initiator];
        ccif.ramaddr = ccif.daddr[initiator];
        ccif.dload[initiator] = ccif.ramload;
        waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
      end
    end
    RELAY: begin
      ccif.dload[initiator] = ccif.ramload;
    end
    IFETCH: begin
      //ccif.ramaddr = ccif.iaddr[initiator];
      //ccif.ramREN = ccif.iREN[initiator];
      //ccif.ramWEN = 1'b0;
      //ccif.iload[initiator] = ccif.ramload;
      //waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
    end
    HALT_WRITE: begin
        ccif.ramWEN = ccif.dWEN[initiator];
        ccif.ramREN = ccif.dREN[initiator];
        ccif.ramaddr = ccif.daddr[initiator];
        ccif.ramstore = ccif.dstore[initiator];
        waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
    end
  endcase
  
  if (state == IFETCH || state == ARBITRATE) begin
    ccif.ramaddr = ccif.iaddr[initiator];
    ccif.ramREN = ccif.iREN[initiator];
    ccif.ramWEN = 1'b0;
    ccif.iload[initiator] = ccif.ramload;
    waitram(ccif.ramstate, ccif.dWEN[initiator], ccif.dREN[initiator], ccif.iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
    if (ccif.ramstate == ACCESS) begin
      ccif.iwait[initiator] = 1'b0;
      ccif.dwait[initiator] = 1'b1;
    end
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