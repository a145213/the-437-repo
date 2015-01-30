// mapped needs this
`include "cache_control_if.vh"
`include "cpu_ram_if.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module memory_control_tb;

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


 initial begin
  import cpu_types_pkg::*;
  parameter PERIOD = 10;

  /*nRST = 0;
  #(PERIOD);
  nRST = 1;
  #(PERIOD);
  */

  $display("Initializing...");
  ccif.iREN[0] = 0;
  ccif.dREN[0] = 0;
  ccif.dWEN[0] = 0;
  ccif.dstore[0] = 0;
  ccif.iaddr[0] = 0;
  ccif.daddr[0] = 0;
  nRST = 1;

  #(PERIOD);
  ccif.iaddr[0] = 32'h00000004;
  ccif.iREN[0] = 1;

  #(1)

  if (ccif.iwait[0] != 1)
    $display("iwait FAILED");
  else $display("iwait PASSED");

  ccif.dstore[0] = 32'habcdabcd;
  ccif.daddr[0] = 32'h0000FFFF;
  $display("Write %h", ccif.dstore[0]);
  ccif.dWEN[0] = 1;

  #(1)
  
  if (ccif.dwait[0] != 1)
    $display("dwait FAILED");
  else $display("dwait PASSED");

  #(PERIOD * 4)
  ccif.dWEN[0] = 0;
  #(PERIOD * 4) 
  ccif.dREN[0] = 1;
  #(PERIOD * 4)
  ccif.dREN[0] = 0;
  $display("Read: %h", ccif.dload[0]);

  #(PERIOD * 4)
  ccif.daddr = 32'h0000FFCC;
  ccif.dstore = 32'hcdcdcdcd;
  $display("Write %h", ccif.dstore[0]);
  ccif.dWEN = 1;
  #(PERIOD * 4)
  ccif.dWEN = 0;
  #(PERIOD * 4)
  ccif.dREN = 1;
  #(PERIOD * 4)
  ccif.dREN = 0;
  $display("Read: %h", ccif.dload[0]);
  dump_memory();
  $finish;
  end

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
    if (ccif.dload === 0)
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

