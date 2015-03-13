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
  icache DUT(CLK, nRST, ccif, dcif);
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
    tb_stage = STAGE_POR;
    nRST = 0;
    
    @(negedge CLK);
    tb_stage = STAGE_CHECK_INVALID;
    nRST = 1;

    


    @(negedge CLK);
    $finish;
  end
  
  task verifySimultaneousRead(input word_t d1, input word_t d2, input logic [4:0] addr1, input logic [4:0] addr2);
    
  endtask


endmodule

program test;
endprogram
