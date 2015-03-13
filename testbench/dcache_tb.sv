/*
  Kyle Woodworth
  kwoodwor@purdue.edu

  register file test bench
*/
`include "cpu_types_pkg.vh"

// mapped needs this
`include "cache_control_if.vh"
`include "datapath_cache_if.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

// import types
import cpu_types_pkg::*;

module dcache_tb;

  parameter PERIOD = 10;

  logic CLK = 0, nRST;
  
  // ENUM for test stages
  typedef enum {
    STAGE_INIT,
    STAGE_POR,
    STAGE_TEST_INVALID,
    STAGE_TEST_DHIT,
    STAGE_FILL_BLOCK,
    STAGE_TEST_WR_DHIT,
    STAGE_TEST_WR_DMISS,
    STAGE_TEST_HALT,

    STAGE_DONE,
    STAGE_WAIT
  } TestStages;
  TestStages tb_stage;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  // bus interface
  datapath_cache_if         dcif ();
  // coherence interface
  cache_control_if          ccif ();

  // test program
  test PROG ();
  // DUT
`ifndef MAPPED
  dcache DUT(CLK, nRST, dcif, ccif);
`else
  dcache DUT(
    
  );
`endif


  initial begin
    $display("Starting testbench..");
    // Initialize variables
    tb_stage = STAGE_INIT;
    nRST = 0;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h00000000;
    
    //
    // Test ansynchronous reset
    //
    @(negedge CLK);
    tb_stage = STAGE_POR;
    nRST = 0;


    //
    // Test reading from invalid block
    //
    @(negedge CLK);
    nRST = 1;
    tb_stage = STAGE_TEST_INVALID;
    dcif.dmemREN = 1'b1;
    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'hFFFFFFF0;
    ccif.dwait = 1'b1;

    // Fill invalid block
    waitCycles(5);
    ccif.dwait = 1'b0;
    ccif.dload = 32'h5A5A5A5A;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    waitCycles(5);
    ccif.dwait = 1'b0;
    ccif.dload = 32'h11111111;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    @(negedge CLK);
    tb_stage = STAGE_TEST_DHIT;
    dcif.dmemREN = 1'b1;
    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'hFFFFFFF0;
    ccif.dwait = 1'b1;
    waitCycles(5);


    //
    // Fill the rest of the set
    //
    @(negedge CLK);
    tb_stage = STAGE_FILL_BLOCK;
    dcif.dmemREN = 1'b1;
    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'hEFFFFFF0;
    ccif.dwait = 1'b1;

    waitCycles(5);
    ccif.dwait = 1'b0;
    ccif.dload = 32'hFEEDFEED;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    waitCycles(5);
    ccif.dwait = 1'b0;
    ccif.dload = 32'h5A5A5A5A;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    @(negedge CLK);
    tb_stage = STAGE_TEST_DHIT;
    dcif.dmemREN = 1'b1;
    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'hEFFFFFF0;
    ccif.dwait = 1'b1;
    waitCycles(5);

    //
    // Test Write Hit
    //
    @(negedge CLK);
    tb_stage = STAGE_TEST_WR_DHIT;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = 32'hFFFFFFF0;
    dcif.dmemstore = 32'hDEADBEEF;
    ccif.dwait = 1'b1;

    //
    // Test Write Hit on other block
    //
    @(negedge CLK);
    //@(negedge CLK);
    tb_stage = STAGE_TEST_WR_DHIT;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = 32'hEFFFFFF4;
    dcif.dmemstore = 32'hBEEFDEAD;
    ccif.dwait = 1'b1;
    @(negedge CLK);

    //
    // Test Write Miss + Write back
    //
    @(posedge CLK);
    tb_stage = STAGE_TEST_WR_DMISS;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = 32'hEEFFFFF4;
    dcif.dmemstore = 32'hBEEFDEAD;
    ccif.dwait = 1'b1;

    waitCycles(5);
    ccif.dwait = 1'b0;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    waitCycles(5);
    ccif.dwait = 1'b0;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    // Allocate after write back
    waitCycles(5);
    ccif.dwait = 1'b0;
    ccif.dload = 32'hCAB1CAB1;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    waitCycles(5);
    ccif.dwait = 1'b0;
    ccif.dload = 32'hABCD1234;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;

    @(negedge CLK);
    tb_stage = STAGE_TEST_DHIT;
    dcif.dmemREN = 1'b1;
    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'hEFFFFFF0;
    ccif.dwait = 1'b1;
    waitCycles(5);

    //
    // Test Write Hit on invalid block
    //


    //
    // Test Write Hit on other invalid block
    //

    //
    // Test HALT Write back
    // 
    @(negedge CLK);
    tb_stage = STAGE_TEST_HALT;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b0;
    dcif.halt = 1'b1;

    ccif.dwait = 1'b1;
    @(posedge CLK);
    ccif.dwait = 1'b0;
    @(posedge CLK);
    ccif.dwait = 1'b0;
    waitCycles(32);
    
    @(negedge CLK);
    tb_stage = STAGE_DONE;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b0;
    waitCycles(10);
    $finish;
  end
  
  task verifySimultaneousRead(input word_t d1, input word_t d2, input logic [4:0] addr1, input logic [4:0] addr2);
    
  endtask

  task waitCycles(int unsigned x);
    for(int i = 0; i < x; i++)
      @(negedge CLK);
  endtask

endmodule

program test;
endprogram
