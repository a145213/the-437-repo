`include "request_unit_if.vh"
`include "cpu_types_pkg.vh"
`include "datapath_cache_if.vh"

`timescale 1 ns / 1 ns

import cpu_types_pkg::*;

module request_unit_tb;
  parameter PERIOD = 10;
  logic CLK = 0, nRST;

  always #(PERIOD/2) CLK++;

  request_unit_if ruif();
  test PROG (CLK, nRST, ruif);

  `ifndef MAPPED
    request_unit DUT(CLK, nRST, ruif);
  `else
    request_unit DUT (
      .\ruif.ihit     (ruif.ihit)
      .\ruif.dhit     (ruif.dhit)
      .\ruif.dREN     (ruif.dREN)
      .\ruif.dWEN     (ruif.dWEN)
      .\ruif.iREN     (ruif.iREN)
      .\ruif.dmemREN  (ruif.dmemREN)
      .\ruif.dmemWEN  (ruif.dmemWEN)
      .\ruif.imemREN  (ruif.imemREN)
      .\ruif.PC_WEN   (ruif.PC_WEN)
      .\nRST          (nRST),
      .\CLK           (CLK)
  );
  `endif
  endmodule

  program test (
    input logic CLK,
    output logic nRST,
    request_unit_if.tb ruif_tb
  );

  initial begin
    import cpu_types_pkg::*;
    parameter PERIOD = 10;
    nRST = 0;
    #(PERIOD);
    nRST = 1;
    #(PERIOD);



    @(posedge CLK);
    ruif_tb.ihit = 1;
    ruif_tb.dREN = 0;
    ruif_tb.dWEN = 0;

    if (ruif_tb.dmemREN == ruif_tb.dREN)
      $display("dmemREN PASSED");
    else
      $display("dmemREN FAILED");

    if (ruif_tb.dmemWEN == ruif_tb.dWEN)
      $display("dmemWEN PASSED");
    else
      $display("dmemWEN FAILED");

    @(posedge CLK);
    ruif_tb.dhit = 1;
    if (ruif_tb.dmemREN == ruif_tb.dREN)
      $display("dmemREN PASSED");
    else
      $display("dmemREN FAILED");

    if (ruif_tb.dmemWEN == ruif_tb.dWEN)
      $display("dmemWEN PASSED");
    else
      $display("dmemWEN FAILED");

    @(posedge CLK);
    ruif_tb.ihit = 0;
    if (ruif_tb.dmemREN == 0)
      $display("dmemREN PASSED");
    else
      $display("dmemREN FAILED");

    if (ruif_tb.dmemWEN == 0)
      $display("dmemWEN PASSED");
    else
      $display("dmemWEN FAILED");

    @(posedge CLK);
    nRST = 0;
    if (ruif_tb.dmemREN == 0)
      $display("nRST PASSED");
    else
      $display("nRST FAILED");

    if (ruif_tb.dmemWEN == 0)
      $display("nRST PASSED");
    else
      $display("nRST FAILED");

  end
endprogram