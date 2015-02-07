/*
  Eric Villasenor
  evillase@gmail.com

  register file test bench
*/

// mapped needs this
`include "register_file_if.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module register_file_tb;

  parameter PERIOD = 10;

  logic CLK = 0, nRST;

  // test vars
  int v1 = 1;
  int v2 = 4721;
  int v3 = 25119;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  register_file_if rfif ();
  // test program
<<<<<<< HEAD
  test PROG (CLK, nRST, rfif);
=======
  test PROG ();
>>>>>>> 7dabfc3f11bbd03f1d249da3c2c0e8ce18ffaab5
  // DUT
`ifndef MAPPED
  register_file DUT(CLK, nRST, rfif);
`else
  register_file DUT(
    .\rfif.rdat2 (rfif.rdat2),
    .\rfif.rdat1 (rfif.rdat1),
    .\rfif.wdat (rfif.wdat),
    .\rfif.rsel2 (rfif.rsel2),
    .\rfif.rsel1 (rfif.rsel1),
    .\rfif.wsel (rfif.wsel),
    .\rfif.WEN (rfif.WEN),
    .\nRST (nRST),
    .\CLK (CLK)
  );
`endif

endmodule

<<<<<<< HEAD
program test (
  input logic CLK,
  output logic nRST,
  register_file_if.tb rfif_tb
);
  
initial begin
  parameter PERIOD = 10;
  nRST = 0;
  #(PERIOD);
  nRST = 1;
  #(PERIOD);
  
  //asynchronous reset test
  rfif_tb.WEN = 1;
  rfif_tb.rsel1 = 0;
  rfif_tb.rsel2 = 0;
  for (int i = 0; i < 32; i++) begin
    rfif_tb.wsel = i;
    rfif_tb.wdat = i;
    #(PERIOD)
    if (rfif_tb.rdat1 == 0)
      $display("nRST PASSED");
    else
      $display("nRST FAILED");
  end
  
  //write test
  #(PERIOD)
  rfif_tb.WEN = 1;
  for (int i = 0; i < 32; i++) begin
    rfif_tb.wsel = i;
    rfif_tb.wdat = i + 1;
    
    #(PERIOD);
  end
  
  rfif_tb.WEN = 0;
  #(PERIOD);
    
  for (int i = 0; i < 32; i++) begin
    rfif.rsel1 = i;
    rfif.rsel2 = i;
    #(PERIOD)
    if (rfif_tb.rsel1 == 0) begin
      if (rfif_tb.rdat1 == 0)
        $display ("rdat1 Location 0 PASSED");
      else $display("rdat1 Location 0 FAILED");
    end
    else if (rfif_tb.rdat1 == i + 1)
      $display("Reading rdat1 %d PASSED", i);
    else $diplay("Reading rdat1 %d FAILED", i);
    
    if (rfif_tb.rsel2 == 0) begin
      if (rfif_tb.rdat2 == 0)
        $display ("rdat2 Location 0 PASSED");
      else $display("rdat2 Location 0 FAILED");
    end
    else if (rfif_tb.rdat2 == i + 1)
      $display("Reading rdat2 %d PASSED", i);
    else $diplay("Reading rdat2 %d FAILED", i);
    
    #(PERIOD);
    
  end
end  
=======
program test;
>>>>>>> 7dabfc3f11bbd03f1d249da3c2c0e8ce18ffaab5
endprogram

