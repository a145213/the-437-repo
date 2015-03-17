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
  int tb_ram_loc = 0;
  int tb_ram_size = 32;
  int tb_ram[32] = {
    32'h0F0F0F0F, 32'hA0A0A0A0, 32'h08008008, 32'h0000FFFF,
    32'hF0F0F0F0, 32'h0A0A0A0A, 32'h80880880, 32'hFFFF0000,
    32'hDD00DD00, 32'hDEADBEEF, 32'hFEEDFEED, 32'h00BBBB00,
    32'h00DD00DD, 32'hCAB1CAB1, 32'hBEEFDEAD, 32'hBB0000BB,
    32'h00000000, 32'h11111111, 32'h22222222, 32'h33333333,
    32'h44444444, 32'h55555555, 32'h66666666, 32'h77777777,
    32'h88888888, 32'h99999999, 32'hAAAAAAAA, 32'hBBBBBBBB,
    32'hCCCCCCCC, 32'hDDDDDDDD, 32'hEEEEEEEE, 32'hFFFFFFFF
  };
  
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
    ccif.ccwait = 1'b0;
    ccif.ccinv = 1'b0;
    ccif.ccsnoopaddr = 32'h00000000;
    dcif.halt = 1'b0;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b0;
    dcif.datomic = 1'b0;
    dcif.dmemstore = 32'h00000000;
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
    readCache(32'h88888888);

    // Fill invalid block
    fillBlocks(2);
    @(negedge dcif.dhit);
    assert(dcif.dmemload == tb_ram[0])
        $display("SUCCESSFUL read -> allocate");
    else
        $error("FAILED read -> allocate");


    @(negedge CLK);
    tb_stage = STAGE_TEST_DHIT;
    readCache(32'h8888888C); 
    @(posedge dcif.dhit);
    @(negedge dcif.dhit);
    assert(dcif.dmemload == tb_ram[1])
        $display("SUCCESSFUL read -> hit");
    else
        $error("FAILED read -> hit");


    //
    // Fill the rest of the set
    //
    @(negedge CLK);
    tb_stage = STAGE_FILL_BLOCK;
    readCache(32'hA888888C);
    // Fill invalid block
    fillBlocks(2);
    @(negedge dcif.dhit);
    assert(dcif.dmemload == tb_ram[3])
        $display("SUCCESSFUL read -> allocate");
    else
        $error("FAILED read -> hit");


    @(negedge CLK);
    tb_stage = STAGE_TEST_DHIT;
    readCache(32'hA8888888);
    @(negedge dcif.dhit);
    assert(dcif.dmemload == tb_ram[2])
        $display("SUCCESSFUL read -> hit");
    else
        $error("FAILED read -> hit");

    //
    // Test Write Hit
    //
    @(negedge CLK);
    tb_stage = STAGE_TEST_WR_DHIT;
    writeCache(32'h88888888, 32'hDEADBEEF);
    @(negedge dcif.dhit);

    //
    // Test Write Hit on other block
    //
    @(negedge CLK);
    //@(negedge CLK);
    tb_stage = STAGE_TEST_WR_DHIT;
    writeCache(32'hA888888C, 32'hBEEFDEAD);
    @(negedge dcif.dhit);

    //
    // Test Write Miss + Write back
    //
    @(negedge CLK);
    tb_stage = STAGE_TEST_WR_DMISS;
    writeCache(32'hEE888888, 32'h5A5AFFBB);
    writeBlocks(2);
    @(negedge dcif.dhit);

    @(negedge CLK);
    tb_stage = STAGE_TEST_DHIT;
    readCache(32'hEE888888); 
    @(negedge dcif.dhit);
    assert(dcif.dmemload == 32'h5A5AFFBB)
        $display("SUCCESSFUL read -> hit");
    else
        $error("FAILED read -> hit");

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

    writeBlocks(32);
    
    @(negedge CLK);
    tb_stage = STAGE_DONE;
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b0;
    waitCycles(10);
    $finish;
  end
  
  task readCache(input word_t addr);
    dcif.dmemREN = 1'b1;
    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = addr;
  endtask

  task writeCache(input word_t addr, input word_t data);
    dcif.dmemREN = 1'b0;
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = addr;
    dcif.dmemstore = data;
  endtask

  task waitCycles(int unsigned x);
    for(int i = 0; i < x; i++)
      @(negedge CLK);
  endtask

  task fillBlocks(input int num_blocks);
    for(int i = 0; i < num_blocks; i++)
        ramRead(5, (tb_ram_loc++)%tb_ram_size);
  endtask

  task ramRead(input int latency, input int idx);
    waitCycles(latency);
    ccif.dwait = 1'b0;
    ccif.dload = tb_ram[idx];
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;
  endtask

  task writeBlocks(input int num_blocks);
    for(int i = 0; i < num_blocks; i++)
        ramWrite(5);
  endtask

  task ramWrite(input int latency);
    waitCycles(latency);
    ccif.dwait = 1'b0;
    @(posedge CLK);
    #1;
    ccif.dwait = 1'b1;
    ccif.dload = 32'hBAD1BAD1;
  endtask

endmodule

program test;
endprogram


/*

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

*/