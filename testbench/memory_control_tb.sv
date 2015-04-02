// mapped needs this
`include "cache_control_if.vh"
`include "cpu_ram_if.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module memory_control_tb;
  import cpu_types_pkg::*;
  parameter PERIOD = 10;
  logic CLK = 0, nRST;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  cache_control_if ccif ();
  cpu_ram_if ramif ();

  // ram
  ram ram(CLK, nRST, ramif);

  // test program
  test PROG (CLK, nRST, ccif, ramif);

  // DUT
  memory_control DUT(CLK, nRST, ccif);

    // assigning RAM signals
  assign ramif.ramaddr = ccif.ramaddr;
  assign ramif.ramstore = ccif.ramstore;
  assign ramif.ramREN = ccif.ramREN;
  assign ramif.ramWEN = ccif.ramWEN;

  assign ccif.ramstate = ramif.ramstate;
  assign ccif.ramload = ramif.ramload;

endmodule

program test (
  input logic CLK,
  output logic nRST,
  cache_control_if ccif,
  cpu_ram_if ramif
);

typedef enum {
  STAGE_INIT,
  STAGE_POR,
  STAGE_IFETCH0,
  STAGE_IFETCH1,
  STAGE_IFETCH2,
  STAGE_DFETCH0,
  STAGE_DFETCH1,
  STAGE_DFETCH2,
  STAGE_DWRITE0,
  STAGE_DWRITE1,
  STAGE_DWRITE2
} TestStages;
TestStages tb_stage;

initial begin
  // Initialize variables
  tb_stage = STAGE_INIT;
  nRST = 1'b0;
  ccif.iREN[0] = 1'b0;
  ccif.iaddr[0] = 32'h00000000;
  ccif.dREN[0] = 1'b0;
  ccif.dWEN[0] = 1'b0;
  ccif.daddr[0] = 32'h00000000;
  ccif.dstore[0] = 32'h00000000;
  ccif.ccwrite[0] = 1'b0;
  ccif.cctrans[0] = 1'b0;
  ccif.iREN[1] = 1'b0;
  ccif.iaddr[1] = 32'h00000000;
  ccif.dREN[1] = 1'b0;
  ccif.dWEN[1] = 1'b0;
  ccif.daddr[1] = 32'h00000000;
  ccif.dstore[1] = 32'h00000000;
  ccif.ccwrite[1] = 1'b0;
  ccif.cctrans[1] = 1'b0;

    //
   // Test ansynchronous reset
  //
  @(negedge CLK);
  tb_stage = STAGE_POR;
  nRST = 1'b0;

    //
   // Simulate Instruction Fetches
  //
  @(negedge CLK);
  nRST = 1'b1;


  // CPU0 Instruction Fetch
  tb_stage = STAGE_IFETCH0;
  ccif.iREN[0] = 1'b1;
  ccif.iaddr[0] = 32'h00000004;
  @(negedge ccif.iwait[0]);
  @(posedge CLK);
  ccif.iREN[0] = 1'b0;


  // CPU1 Instruction Fetch
  tb_stage = STAGE_IFETCH1;
  ccif.iREN[1] = 1'b1;
  ccif.iaddr[1] = 32'h00000204;
  @(negedge ccif.iwait[1]);
  @(posedge CLK);
  ccif.iREN[1] = 1'b0;


  // CPU0 and CPU1 Instruction Fetch
  // - should go to CPU0 and then CPU1
  tb_stage = STAGE_IFETCH2;
  ccif.iREN[0] = 1'b1;
  ccif.iREN[1] = 1'b1;
  ccif.iaddr[0] = 32'h00000008;
  ccif.iaddr[1] = 32'h00000208;
  @(negedge ccif.iwait[0]);
  @(posedge CLK);
  ccif.iREN[0] = 1'b0;
  @(negedge ccif.iwait[1]);
  @(posedge CLK);
  ccif.iREN[1] = 1'b0;

    //
   // Simulate Data Fetches
  //
  // CPU0 Data Fetch (Also Bus Miss)
  @(negedge CLK);
  tb_stage = STAGE_DFETCH0;
  ccif.dREN[0] = 1'b1;
  ccif.cctrans[0] = 1'b1;
  ccif.daddr[0] = 32'h00008000;
  @(negedge CLK);
  // CC is in SNOOP state
  @(negedge CLK);
  // CC is in REPLY state
  @(negedge ccif.dwait[0]);
  @(posedge CLK);
  ccif.daddr[0] = 32'h00008004;
  @(negedge ccif.dwait[0]);
  ccif.cctrans[0] = 1'b0;
  @(posedge CLK);
  ccif.dREN[0] = 1'b0;
  
  // CPU1 Data Fetch (Also Bus Miss)
  @(negedge CLK);
  tb_stage = STAGE_DFETCH1;
  ccif.dREN[1] = 1'b1;
  ccif.cctrans[1] = 1'b1;
  ccif.daddr[1] = 32'h00008200;
  @(negedge CLK);
  // CC is in SNOOP state
  @(negedge CLK);
  // CC is in REPLY state
  @(negedge ccif.dwait[1]);
  @(posedge CLK);
  ccif.daddr[1] = 32'h00008204;
  @(negedge ccif.dwait[1]);
  ccif.cctrans[1] = 1'b0;
  @(posedge CLK);
  ccif.dREN[1] = 1'b0;

  // CPU0 and CPU1 Data Fetch
  // - should go to CPU0 and then CPU1
  @(negedge CLK);
  tb_stage = STAGE_DFETCH2;
  ccif.dREN[0] = 1'b1;
  ccif.dREN[1] = 1'b1;
  ccif.cctrans[0] = 1'b1;
  ccif.cctrans[1] = 1'b1;
  ccif.daddr[0] = 32'h00008008;
  ccif.daddr[1] = 32'h00008208;
  @(negedge CLK);
  // CC is in SNOOP state
  @(negedge CLK);
  // CC is in REPLY state
  @(negedge ccif.dwait[0]);
  @(posedge CLK);
  ccif.daddr[0] = 32'h0000800C;
  @(negedge ccif.dwait[0]);
  ccif.cctrans[0] = 1'b0;
  @(posedge CLK);
  ccif.dREN[0] = 1'b0;

  @(negedge CLK);
  // CC is in SNOOP state
  @(negedge CLK);
  // CC is in REPLY state
  @(negedge ccif.dwait[1]);
  @(posedge CLK);
  ccif.daddr[1] = 32'h0000820C;
  @(negedge ccif.dwait[1]);
  ccif.cctrans[1] = 1'b0;
  @(posedge CLK);
  ccif.dREN[1] = 1'b0;

    //
   // Simulate Simultaneous Data and Instruction Fetches
  //
  // CPU0 Data Write Bus Hit (Cache-2-Cache Transfer)
  @(negedge CLK);
  tb_stage = STAGE_DWRITE0;
  ccif.dREN[0] = 1'b1;
  ccif.cctrans[0] = 1'b1;
  ccif.ccwrite[0] = 1'b1;
  ccif.daddr[0] = 32'h00008010;
  @(negedge CLK);
  // CC is in SNOOP state
  ccif.ccwrite[1] = 1'b1;
  @(negedge CLK);
  // CC is in REPLY state
  ccif.daddr[1] = 32'h00008010;
  ccif.dWEN[1] = 1'b1;
  ccif.dstore[1] = 32'hFFFFAAAA;
  @(negedge ccif.dwait[0]);
  @(posedge CLK);
  ccif.daddr[1] = 32'h00008014;
  @(negedge ccif.dwait[0]);
  ccif.dstore[1] = 32'hFFFFBBBB;
  
  @(posedge CLK);
  ccif.cctrans[0] = 1'b0;
  ccif.ccwrite[1] = 1'b0;
  
  ccif.dREN[0] = 1'b0;
  ccif.dWEN[1] = 1'b0;

  // CPU0 and CPU1 Data Write
  // - should go to CPU1 and then CPU1

  waitCycles(10);
  dump_memory();
  $finish;
end

task waitCycles(int unsigned x);
  for(int i = 0; i < x; i++)
    @(posedge CLK);
endtask

task automatic dump_memory();
  string filename = "memcpu.hex";
  int memfd;

  ccif.daddr = 0;
  ccif.dWEN = 0;
  ccif.dREN = 0;

  memfd = $fopen(filename,"w");
  if (memfd)
    $display("Starting memory dump.");
  else
    begin $display("Failed to open %s.",filename); $finish; end

  for (int unsigned i = 0; memfd && i < 16384; i++)
  begin
    int chksum = 0;
    bit [7:0][7:0] values;
    string ihex;

    ccif.daddr = i << 2;
    ccif.dREN = 1;
    repeat (4) @(posedge CLK);
    if (ccif.dload[0] === 0)
      continue;
    values = {8'h04,16'(i),8'h00,ccif.ramload};
    foreach (values[j])
    chksum += values[j];
    chksum = 16'h100 - chksum;
    ihex = $sformatf(":04%h00%h%h",16'(i),ccif.ramload,8'(chksum));
    $fdisplay(memfd,"%s",ihex.toupper());
  end //for
  if (memfd)
  begin
    ccif.dREN = 0;
    $fdisplay(memfd,":00000001FF");
    $fclose(memfd);
    $display("Finished memory dump.");
  end
endtask

endprogram

