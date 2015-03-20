/*
  Eric Villasenor
  evillase@gmail.com

  this block holds the i and d cache
*/


// interfaces
`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

// cpu types
`include "cpu_types_pkg.vh"

module caches (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  cache_control_if.caches ccif
);
  // import types
  import cpu_types_pkg::*;

  parameter CPUID = 0;

  //word_t instr;
  //word_t daddr;

  // icache
  icache #(.SETS(16), .BLKS_PER_SET(1), .WORDS_PER_BLK(1)) ICACHE(CLK, nRST, dcif, ccif);
  // dcache
  dcache #(.SETS(8), .BLKS_PER_SET(2), .WORDS_PER_BLK(2)) DCACHE(CLK, nRST, dcif, ccif);

  // Unused signals
  //assign ccif.ccwrite = 1'b0;
  //assign ccif.cctrans = 1'b0;

  // single cycle instr saver (for memory ops)
  /*
  always_ff @(posedge CLK)
  begin
    if (!nRST)
    begin
      instr <= '0;
      daddr <= '0;
    end
    else
    if (dcif.ihit)
    begin
      //instr <= ccif.iload[CPUID];
      instr <= ccif.iload;
      daddr <= dcif.dmemaddr;
    end
  end
  */


  // dcache invalidate before halt
  /*
  assign dcif.flushed = dcif.halt;

  assign dcif.ihit = (dcif.imemREN) ? ~ccif.iwait : 0;
  assign dcif.dhit = (dcif.dmemREN|dcif.dmemWEN) ? ~ccif.dwait : 0;
  assign dcif.imemload = ccif.iload;
  assign dcif.dmemload = ccif.dload;

  assign ccif.iREN = dcif.imemREN;
  assign ccif.dREN = dcif.dmemREN;
  assign ccif.dWEN = dcif.dmemWEN;
  assign ccif.dstore = dcif.dmemstore;
  assign ccif.iaddr = dcif.imemaddr;
  assign ccif.daddr = dcif.dmemaddr;
  */

endmodule
