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

endmodule

program test (
  input logic CLK,
  output logic nRST,
  cache_control_if ccif,
  cpu_ram_if ramif
);

  // assigning RAM signals
  assign ramif.ramaddr = ccif.ramaddr;
  assign ramif.ramstore = ccif.ramstore;
  assign ramif.ramREN = ccif.ramREN;
  assign ramif.ramWEN = ccif.ramWEN;

  assign ccif.ramstate = ramif.ramstate;
  assign ccif.ramload = ramif.ramload;

 initial begin
  import cpu_types_pkg::*;
  parameter PERIOD = 10;

  nRST = 0;
  #(PERIOD);
  nRST = 1;
  #(PERIOD);
  

  $display("Initializing");
  ccif.iREN = 0;
  ccif.dREN = 0;
  ccif.dWEN = 0;
  ccif.dstore = 0;
  ccif.iaddr = 0;
  ccif.daddr = 0;
  nRST = 1;

  #(PERIOD);
  ccif.iaddr = 32'h00000004;
  ccif.iREN = 1;

  if (ccif.iwait != 1) begin
    $display("iwait FAILED");
  end

  ccif.iREN = 1;

  $display("Writing to RAM");

  ccif.dstore = 32'h00001111;
  ccif.daddr = 32'h0000FFFF;
  ccif.dWEN = 1;

  if (ccif.dwait != 1) begin
    $display("dwait FAILED");
  end

  ccif.dWEN = 0;

  ccif.dREN = 1;
  $display("Reading Data from RAM");

  ccif.dREN = 0;
  $display("Read: %h", ccif.dload);

  $finish;
  end
endprogram

