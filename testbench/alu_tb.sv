
// mapped needs this
`include "alu_if.vh"
`include "cpu_types_pkg.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module alu_tb;
  parameter PERIOD = 10;
  
  // interface
  alu_if aluif ();
  // test program
  test PROG (aluif);
  // DUT
`ifndef MAPPED
  alu DUT(aluif);
`else
  alu DUT(
    .\aluif.port_a (aluif.port_a),
    .\aluif.port_b (aluif.port_b),
    .\aluif.alu_op (aluif.alu_op),
    .\aluif.negative (aluif.negative),
    .\aluif.zero (aluif.zero),
    .\aluif.overflow (aluif.aluif.overflow),
    .\aluif.port_p (aluif.port_o)
  );
`endif

endmodule

program test (
  alu_if.tb aluif_tb
);
  
initial begin
  import cpu_types_pkg::*;
  parameter PERIOD = 10;
  
  //shift left logical test
  aluif_tb.alu_op = ALU_SLL;
  aluif_tb.port_a = 32'h1;
  aluif_tb.port_b = 32'h4;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h10)
    $display("SLL 1 PASSED");
  else
    $display("SLL 1 FAILED");
    
  #(PERIOD)
  
  //shift left logical test
  aluif_tb.alu_op = ALU_SLL;
  aluif_tb.port_a = 32'hE;
  aluif_tb.port_b = 32'h4;
  #(PERIOD);
  if (aluif_tb.port_o == 32'hE0)
    $display("SLL 2 PASSED");
  else
    $display("SLL 2 FAILED");  
    
  #(PERIOD);
  
  //shift right logical test
  aluif_tb.alu_op = ALU_SRL;
  aluif_tb.port_a = 32'h20;
  aluif_tb.port_b = 32'h4;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h2)
    $display("SRL 1 PASSED");
  else
    $display("SRL 1 FAILED");
    
  #(PERIOD);
  
  //shift right logical test
  aluif_tb.alu_op = ALU_SRL;
  aluif_tb.port_a = 32'hE0;
  aluif_tb.port_b = 32'h6;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h3)
    $display("SRL 2 PASSED");
  else
    $display("SRL 2 FAILED");
  
  #(PERIOD)
  
  //ADD test
  aluif_tb.alu_op = ALU_ADD;
  aluif_tb.port_a = 32'h20;
  aluif_tb.port_b = 32'h4;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h24)
    $display("ADD 1 PASSED");
  else
    $display("ADD 1 FAILED");
    
  #(PERIOD)
  
  //ADD test
  aluif_tb.alu_op = ALU_ADD;
  aluif_tb.port_a = 32'hE8;
  aluif_tb.port_b = 32'h2;
  #(PERIOD);
  if (aluif_tb.port_o == 32'hEA)
    $display("ADD 2 PASSED");
  else
    $display("ADD 2 FAILED");
  
  #(PERIOD)
  
  //SUB test
  aluif_tb.alu_op = ALU_SUB;
  aluif_tb.port_a = 32'h20;
  aluif_tb.port_b = 32'h4;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h1C)
    $display("SUB 1 PASSED");
  else
    $display("SUB 1 FAILED");
    
  #(PERIOD)
  
  //SUB test
  aluif_tb.alu_op = ALU_SUB;
  aluif_tb.port_a = 32'h1;
  aluif_tb.port_b = 32'h1;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h0)
    $display("SUB 2 PASSED");
  else
    $display("SUB 2 FAILED");
    
  #(PERIOD)
  
  //AND test
  aluif_tb.alu_op = ALU_AND;
  aluif_tb.port_a = 32'h20;
  aluif_tb.port_b = 32'h4;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h0)
    $display("AND 1 PASSED");
  else
    $display("AND 1 FAILED");
    
  #(PERIOD)
  
  //AND test
  aluif_tb.alu_op = ALU_AND;
  aluif_tb.port_a = 32'hE;
  aluif_tb.port_b = 32'h5;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h4)
    $display("AND 2 PASSED");
  else
    $display("AND 2 FAILED");
    
  #(PERIOD)
  
  //OR test
  aluif_tb.alu_op = ALU_OR;
  aluif_tb.port_a = 32'h2;
  aluif_tb.port_b = 32'h10;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h12)
    $display("OR  1 PASSED");
  else
    $display("OR  1 FAILED");
    
  #(PERIOD)
  
  //OR test
  aluif_tb.alu_op = ALU_OR;
  aluif_tb.port_a = 32'hE;
  aluif_tb.port_b = 32'h3;
  #(PERIOD);
  if (aluif_tb.port_o == 32'hF)
    $display("OR  2 PASSED");
  else
    $display("OR  2 FAILED");
    
  #(PERIOD)
  
  //XOR test
  aluif_tb.alu_op = ALU_XOR;
  aluif_tb.port_a = 32'hD;
  aluif_tb.port_b = 32'h4;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h9)
    $display("XOR 2 PASSED");
  else
    $display("XOR 2 FAILED");
    
  #(PERIOD)
  
  //XOR test
  aluif_tb.alu_op = ALU_XOR;
  aluif_tb.port_a = 32'h5;
  aluif_tb.port_b = 32'h2;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h7)
    $display("XOR 2 PASSED");
  else
    $display("XOR 2 FAILED");
    
  #(PERIOD)
  
  //NOR test
  aluif_tb.alu_op = ALU_NOR;
  aluif_tb.port_a = 32'hFFFFFFFF;
  aluif_tb.port_b = 32'hFFFFFFFF;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h0)
    $display("NOR 1 PASSED");
  else
    $display("NOR 1 FAILED");
    
  #(PERIOD)
  
  //NOR test
  aluif_tb.alu_op = ALU_NOR;
  aluif_tb.port_a = 32'h1;
  aluif_tb.port_b = 32'h5;
  #(PERIOD);
  if (aluif_tb.port_o == 32'hFFFFFFFA)
    $display("NOR 2 PASSED");
  else
    $display("NOR 2 FAILED");
    
  #(PERIOD)
  
  //set less than test
  aluif_tb.alu_op = ALU_SLT;
  aluif_tb.port_a = 32'h10;
  aluif_tb.port_b = 32'h2;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h0)
    $display("SLT 1 PASSED");
  else
    $display("SLT 1 FAILED");
    
  #(PERIOD)
  
  //set less than test
  aluif_tb.alu_op = ALU_SLT;
  aluif_tb.port_a = 32'h2;
  aluif_tb.port_b = 32'h2;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h0)
    $display("SLT 2 PASSED");
  else
    $display("SLT 2 FAILED");
    
  #(PERIOD)
  
  //set less than unsigned test
  aluif_tb.alu_op = ALU_SLTU;
  aluif_tb.port_a = 32'h2;
  aluif_tb.port_b = 32'h10;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h1)
    $display("SLTU 1 PASSED");
  else
    $display("SLTU 1 FAILED");
    
  #(PERIOD)
  
  //set less than unsigned test
  aluif_tb.alu_op = ALU_SLTU;
  aluif_tb.port_a = 32'h2;
  aluif_tb.port_b = 32'h2;
  #(PERIOD);
  if (aluif_tb.port_o == 32'h0)
    $display("SLTU 2 PASSED");
  else
    $display("SLTU 2 FAILED");
    
  end
endprogram