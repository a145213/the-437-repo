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

module icache_tb;

  parameter PERIOD = 10;

  logic CLK = 0, nRST;
  
  // ENUM for test stages
  typedef enum {
    STAGE_INIT,
    STAGE_POR,
    STAGE_CHECK_INVALID
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
  icache DUT(CLK, nRST, dcif, ccif);
`else
  icache DUT(
    
  );
`endif


  initial begin
    $display("Starting testbench..");
    // Initialize variables
    tb_stage = STAGE_INIT;
    nRST = 0;
    
    //
    // Test ansynchronous reset
    //
    @(negedge CLK);
    nRST = 0;
    
    @(negedge CLK);
    nRST = 1;

    if (nRST != 1)
      $display("nRST FAILED");
    else $display("nRST PASSED");

    ccif.iaddr = 0;
    ccif.iREN = 0;
    ccif.iwait = 1'b0;
    @(posedge CLK);
    @(posedge CLK);
    nRST = 1;
    @(posedge CLK);
    dcif.imemREN = 1;
    @(posedge CLK);
    //testcase 1: read one instruction and then read the same one again
    //also test allocate on miss
    @(posedge CLK);
    dcif.imemaddr = 32'd0;
    ccif.iload = 32'hffffffff;
    ccif.iwait = 1'b1;
    @(posedge CLK);
    ccif.iwait = 1'b0;
    @(posedge CLK);
    dcif.imemaddr = 32'd4;
    ccif.iload = 32'h00000001;
    ccif.iwait = 1'b1;
    @(posedge CLK);
    ccif.iwait = 1'b0;
    @(posedge CLK);
    dcif.imemaddr = 32'd8;
    ccif.iload = 32'h00000002;
    @(posedge CLK);
    @(posedge CLK);
    dcif.imemaddr = 32'd0;
    dcif.imemREN = 1'b1;
    @(posedge CLK);
    dcif.imemREN = 1'b0;

    //testcase 2: test same ndex different tag problem
    /*dcif.imemaddr = 32'd60;
    @(posedge CLK);
    @(posedge CLK);
    dcif.imemaddr = 32'd64;
    @(posedge CLK);
    @(posedge CLK);
    dcif.imemaddr = 32'd68;
    @(posedge CLK);
    */
    /* //load
    dcif.imemaddr = 32'h00000000;
    dcif.imemREN = 1'b1;
    dcif.halt = 1'b0;
    ccif.iwait = 1'b0;
    ccif.iload = 32'hffffffff;
    #(PERIOD*2);
    @(negedge CLK);
    ccif.iload = 32'h00000001;
    @(negedge CLK);
    ccif.iload = 32'h00000002;
    @(posedge dcif.ihit);
    ccif.iwait = 1;
    @(posedge CLK);
    dcif.imemREN = 1'b0;
    #(PERIOD*1);

    //load same index
    dcif.imemaddr = 32'hffff0000;
    dcif.imemREN = 1'b1;
    dcif.halt = 1'b0;
    ccif.iwait = 1'b0;
    ccif.iload = 32'h0000ffff;
    @(negedge CLK);
    ccif.iload = 32'hffff0001;
    @(posedge dcif.ihit);
    @(posedge CLK);
    dcif.imemREN = 1'b0;
    #(PERIOD*1);

    //read index 1
    dcif.imemaddr = 32'b00000000000000000000000000_001_0_00;
    //dcif.imemstore = 32'hbad1bad1;
    dcif.imemREN = 1'b1;
    dcif.halt = 1'b0;
    ccif.iwait = 1'b0;
    ccif.iload = 32'h00000000;
    @(negedge CLK);
    ccif.iload = 32'hffffffff;
    @(posedge dcif.ihit);
    @(posedge CLK);
    dcif.imemREN = 1'b0;
    #(PERIOD*1);

    dcif.halt = 1'b1;
    @(posedge CLK);
    @(posedge CLK);
    dcif.halt = 1'b0;
    #(PERIOD*16);
    */

    @(negedge CLK);
    $finish;
  end
  
  task verifySimultaneousRead(input word_t d1, input word_t d2, input logic [4:0] addr1, input logic [4:0] addr2);
    
  endtask


endmodule

program test;
endprogram
