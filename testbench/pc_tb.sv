`include "pc_if.vh"

`timescale 1 ns / 1 ns

import cpu_types_pkg::*;

module pc_tb;
  parameter PERIOD = 10;
  logic CLK = 0, nRST;

  always #(PERIOD/2) CLK++;

  pc_if pcif();
  test PROG (CLK, nRST, pcif);

  `ifndef MAPPED
    pc DUT(CLK, nRST, pcif);
  `else
    pc DUT (
      .\pcif.pc_input   (pcif.pc_input),
      .\pcif.pc_output  (pcif.pc_output),
      .\nRST            (nRST),
      .\CLK (CLK)
  );
  `endif
  endmodule

  program test (
    input logic CLK,
    output logic nRST,
    pc_if.tb pcif_tb
  );

  initial begin
    import cpu_types_pkg::*;
    parameter PERIOD = 10;
    nRST = 0;
    #(PERIOD);
    nRST = 1;
    #(PERIOD);

    pcif_tb.pc_input = 4;

    pcif_tb.PC_WEN = 0;
    #(PERIOD);
    pcif_tb.PC_WEN = 1;
    #(PERIOD);


    if (pcif_tb.pc_output != 0)
      $display("PASSED");
    else
      $display("FAILED");

    #(PERIOD);
    nRST = 0;
    #(PERIOD)

    if (pcif_tb.pc_output == 0)
      $display("nRST PASSED");
    else
      $display("nRST FAILED");

  end
endprogram