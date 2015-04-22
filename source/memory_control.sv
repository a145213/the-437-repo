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

typedef enum logic [3:0] {
  ARBITRATE = 4'b0000,
  GRANT = 4'b0001,
  SNOOP = 4'b0010,
  BUS_RD = 4'b0011,
  BUS_RDX = 4'b0100,
  IFETCH = 4'b0101,
  IREPLY = 4'b0110,
  HALT_WRITE = 4'b0111
} bus_state;
bus_state state;
bus_state nxt_state;
logic arb, nxt_arb;
logic initiator, nxt_initiator;
logic target, nxt_target;
word_t snoopaddr, nxt_snoopaddr;
logic [CPUS-1:0] iREN, dWEN, dREN;
logic [CPUS-1:0] cctrans, ccwrite;
word_t  [CPUS-1:0] iaddr, daddr;
word_t  [CPUS-1:0] dstore;
logic [CPUS-1:0] prev_dwait;

always_ff @(posedge CLK, negedge nRST) begin
  if (!nRST) begin
    state <= ARBITRATE;
    arb <= 0;
    initiator <= 0;
    target <= 0;
    snoopaddr <= 0;
    iREN[0] <= 1'b0;
    iREN[1] <= 1'b0;
    dWEN[0] <= 1'b0;
    dWEN[1] <= 1'b0;
    dREN[0] <= 1'b0;
    dREN[1] <= 1'b0;
    cctrans[0] <= 1'b0;
    cctrans[1] <= 1'b0;
    ccwrite[0] <= 1'b0;
    ccwrite[1] <= 1'b0;
  end else begin
    state <= nxt_state;
    arb <= nxt_arb;
    initiator <= nxt_initiator;
    target <= nxt_target;
    snoopaddr <= nxt_snoopaddr;
    iREN[0] <= ccif.iREN[0];
    iREN[1] <= ccif.iREN[1];
    dWEN[0] <= ccif.dWEN[0];
    dWEN[1] <= ccif.dWEN[1];
    dREN[0] <= ccif.dREN[0];
    dREN[1] <= ccif.dREN[1];
    cctrans[0] <= ccif.cctrans[0];
    cctrans[1] <= ccif.cctrans[1];
    ccwrite[0] <= ccif.ccwrite[0];
    ccwrite[1] <= ccif.ccwrite[1];
    iaddr[0] <= ccif.iaddr[0];
    iaddr[1] <= ccif.iaddr[1];
    daddr[0] <= ccif.daddr[0];
    daddr[1] <= ccif.daddr[1];
    dstore[0] <= ccif.dstore[0];
    dstore[1] <= ccif.dstore[1];
    prev_dwait[0] <= ccif.dwait[0];
    prev_dwait[1] <= ccif.dwait[1];
  end
end

// Next state logic
always_comb begin
  nxt_state = state;
  casez(state)
    ARBITRATE: begin
      if ((dWEN[0] || dREN[0] || dWEN[1] || dREN[1])) begin
        if ((!cctrans[0] && dWEN[0]) || (!cctrans[1] && dWEN[1])) begin
          nxt_state = HALT_WRITE;
        end else begin
          nxt_state = GRANT;
        end
      end else if (iREN[0] || iREN[1]) begin
        nxt_state = IFETCH;
      end else begin
        nxt_state = ARBITRATE;
      end
    end
    GRANT: begin
      //nxt_state = (dWEN[target])?(BUS_RDX):(BUS_RD);
      nxt_state = SNOOP;
    end
    SNOOP: begin
      //nxt_state = (dWEN[target])?(BUS_RDX):(BUS_RD);
      //nxt_state = BUS_RDX;
      if (dWEN[target]) begin
        nxt_state = BUS_RDX;
      end else if (ccwrite[target]) begin
        nxt_state = BUS_RD;
      end else begin
        nxt_state = SNOOP;
      end
    end
    BUS_RD: begin
      nxt_state = (cctrans[initiator])?(BUS_RD):(ARBITRATE);
      //nxt_state = (dWEN[target])?(BUS_RDX):(nxt_state);
    end
    BUS_RDX: begin
      /*
      if (!dWEN[target]) begin
        nxt_state = BUS_RD;
      end else if (!cctrans[initiator]) begin
        nxt_state = ARBITRATE;
      end else begin
        nxt_state = BUS_RDX;
      end
      */
      nxt_state = (cctrans[initiator])?(BUS_RDX):(ARBITRATE);
      //nxt_state = (!dWEN[target])?(BUS_RD):(nxt_state);
    end
    IFETCH: begin
      nxt_state = (ccif.ramstate == ACCESS)?(IREPLY):(IFETCH);
    end
    IREPLY: begin
      nxt_state = (ARBITRATE);
    end
    HALT_WRITE: begin
      nxt_state = (ccwrite[initiator])?(HALT_WRITE):(ARBITRATE);
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
  ccif.iload[0] = 32'h00000000;
  ccif.iload[1] = 32'h00000000;
  ccif.dload[0] = 32'h00000000;
  ccif.dload[1] = 32'h00000000;
  ccif.ccwait[0] = 1'b0;
  ccif.ccwait[1] = 1'b0;
  ccif.ccinv[0] = 1'b0;
  ccif.ccinv[1] = 1'b0;
  ccif.ccsnoopaddr[0] = 32'h00000000;
  ccif.ccsnoopaddr[1] = 32'h00000000;
  ccif.ramWEN = 1'b0;
  ccif.ramREN = 1'b0;
  ccif.ramaddr = 32'h00000000;
  ccif.ramstore = 32'h00000000;
  nxt_initiator = initiator;
  nxt_target = target;
  nxt_arb = arb;
  nxt_snoopaddr = snoopaddr;

  casez(state)
    ARBITRATE: begin
      // Arbitrate between caches
      if (dWEN[0] || dREN[0] || dWEN[1] || dREN[1]) begin
        // Arbitrate between cores
        /*
        if (cctrans[0] && cctrans[1]) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (cctrans[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (cctrans[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b0;
        end else if (dWEN[0] && dWEN[1]) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (dWEN[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (dWEN[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b1;
        end
        */

        if ((!cctrans[0] && dWEN[0]) && (!cctrans[1] && dWEN[1])) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (!cctrans[0] && dWEN[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (!cctrans[1] && dWEN[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b0;
        end else if (cctrans[0] && cctrans[1]) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (cctrans[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (cctrans[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b1;
        end

        // Grant INITIATOR the bus and tell all others to wait
        if (cctrans[0] || cctrans[1]) begin
          //ccif.ccwait[nxt_initiator] = 1'b0;
          //ccif.ccwait[nxt_target] = 1'b1;
          //ccif.ccinv[nxt_target] = ccwrite[nxt_initiator];
          //nxt_snoopaddr = daddr[nxt_initiator];
          //ccif.ccsnoopaddr[nxt_target] = nxt_snoopaddr;
          
        end
        nxt_snoopaddr = daddr[nxt_initiator];

      end else if (iREN[0] || iREN[1]) begin
        // Arbitrate between cores
        if (iREN[0] && iREN[1]) begin
          nxt_initiator = arb;
          nxt_target = !arb;
          nxt_arb = !arb;
        end else if (iREN[0]) begin
          nxt_initiator = 1'b0;
          nxt_target = 1'b1;
          nxt_arb = 1'b1;
        end else if (iREN[1]) begin
          nxt_initiator = 1'b1;
          nxt_target = 1'b0;
          nxt_arb = 1'b0;
        end

        
      end
    end
    GRANT: begin
      // Grant
      ccif.ccwait[initiator] = 1'b0;
      ccif.ccwait[target] = 1'b1;

      // Snoop
      ccif.ccinv[target] = ccwrite[initiator];
      ccif.ccsnoopaddr[target] = snoopaddr;
      nxt_snoopaddr = daddr[nxt_initiator];
    end
    SNOOP: begin
      
      // Grant
      ccif.ccwait[initiator] = 1'b0;
      ccif.ccwait[target] = 1'b1;

      // Snoop
      ccif.ccinv[target] = ccwrite[initiator];
      ccif.ccsnoopaddr[target] = snoopaddr;
      nxt_snoopaddr = daddr[nxt_initiator];
      
    end
    BUS_RDX: begin
      // Grant
      ccif.ccwait[initiator] = 1'b0;
      ccif.ccwait[target] = 1'b1;

      // Snoop
      ccif.ccinv[target] = ccwrite[initiator];
      ccif.ccsnoopaddr[target] = snoopaddr;
      nxt_snoopaddr = daddr[nxt_initiator];

      // Cache-to-cache cctransfer w/ WB
      ccif.ramWEN = dWEN[target];
      ccif.ramREN = dREN[target];
      ccif.ramaddr = daddr[target];
      ccif.ramstore = dstore[target];
      ccif.dload[initiator] = ccif.dstore[target];
      waitram(ccif.ramstate, dWEN[target], dREN[target], iREN[target], ccif.iwait[initiator], ccif.dwait[initiator]);
      waitram(ccif.ramstate, dWEN[target], dREN[target], iREN[target], ccif.iwait[target], ccif.dwait[target]);
      if (ccif.ramstate == ACCESS && !prev_dwait[initiator]) begin
        ccif.dwait[initiator] = 1'b1;
        ccif.dwait[target] = 1'b1;
      end else if (ccif.ramstate != ACCESS) begin
        ccif.dwait[initiator] = 1'b1;
        ccif.dwait[target] = 1'b1;
      end else begin
        ccif.dwait[initiator] = 1'b0;
        ccif.dwait[target] = 1'b0;
      end
    end
    BUS_RD: begin
      // Grant
      ccif.ccwait[initiator] = 1'b0;
      ccif.ccwait[target] = 1'b1;
      // Snoop
      ccif.ccinv[target] = ccwrite[initiator];
      ccif.ccsnoopaddr[target] = snoopaddr;
      nxt_snoopaddr = daddr[nxt_initiator];

      // Get data from memory
      ccif.ramWEN = dWEN[initiator];
      ccif.ramREN = dREN[initiator];
      ccif.ramaddr = daddr[initiator];
      ccif.dload[initiator] = ccif.ramload;
      waitram(ccif.ramstate, dWEN[initiator], dREN[initiator], iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
      if (ccif.ramstate == ACCESS && !prev_dwait[initiator]) begin
        ccif.dwait[initiator] = 1'b1;
      end else if (ccif.ramstate != ACCESS) begin
        ccif.dwait[initiator] = 1'b1;
      end else begin
        ccif.dwait[initiator] = 1'b0;
      end
    end
    IFETCH: begin
      // Instruction Fetch
      ccif.ramaddr = ccif.iaddr[initiator];
      ccif.ramREN = iREN[initiator];
      ccif.ramWEN = 1'b0;
      ccif.iload[initiator] = ccif.ramload;
    end
    IREPLY: begin
      // Instruction Reply
      ccif.ramaddr = iaddr[initiator];
      ccif.ramREN = iREN[initiator];
      ccif.ramWEN = 1'b0;
      ccif.iload[initiator] = ccif.ramload;
      waitram(ccif.ramstate, dWEN[initiator], dREN[initiator], iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
    end
    HALT_WRITE: begin
        // Grant
      ccif.ccwait[initiator] = 1'b0;
      ccif.ccwait[target] = 1'b1;
      // Snoop
      ccif.ccinv[target] = 1'b1;
      nxt_snoopaddr = daddr[nxt_initiator];
      ccif.ccsnoopaddr[target] = snoopaddr;

      ccif.ramWEN = dWEN[initiator];
      ccif.ramREN = dREN[initiator];
      ccif.ramaddr = daddr[initiator];
      ccif.ramstore = dstore[initiator];
      waitram(ccif.ramstate, dWEN[initiator], dREN[initiator], iREN[initiator], ccif.iwait[initiator], ccif.dwait[initiator]);
      if (ccif.ramstate == ACCESS && !prev_dwait[initiator]) begin
        ccif.dwait[initiator] = 1'b1;
      end else if (ccif.ramstate != ACCESS) begin
        ccif.dwait[initiator] = 1'b1;
      end else begin
        ccif.dwait[initiator] = 1'b0;
      end
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