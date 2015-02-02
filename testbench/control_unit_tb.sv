`include "control_unit_if.vh"

`timescale 1 ns / 1 ns

import cpu_types_pkg::*;

module control_unit_tb;
  parameter PERIOD = 20;

  control_unit_if cuif();
  test PROG (cuif);

  `ifndef MAPPED
    control_unit DUT(cuif);
  `else
    control_unit DUT (
      .\cuif.opcode   (cuif.opcode),
      .\cuif.funct    (cuif.funct),
      .\cuif.alu_zero (cuif.alu_zero),
      .\cuif.halt     (cuif.halt),
      .\cuif.iRen     (cuif.iRen),
      .\cuif.dRen     (cuif.dRen),
      .\cuif.dWen     (cuif.dWen),
      .\cuif.RegDst   (cuif.RegDst),
      .\cuif.MemToReg (cuif.MemToReg),
      .\cuif.MemWrite (cuif.MemWrite),
      .\cuif.MemRead  (cuif.MemRead),
      .\cuif.ExtOp    (cuif.ExtOp),
      .\cuif.alu_op   (cuif.alu_op),
      .\cuif.Jal      (cuif.Jal),
      .\cuif.PC_WEN   (cuif.PC_WEN)
  );
  `endif
  endmodule

  program test (
    control_unit_if.tb cuif_tb
  );

  initial begin
    import cpu_types_pkg::*;
    parameter PERIOD = 10;
    
    cuif_tb.opcode = RTYPE;
    #(1)
    /*
    $display("RegDst   = %d", cuif_tb.RegDst);
    $display("RegWrite = %d", cuif_tb.RegWrite);
    $display("ALUSrc   = %d", cuif_tb.ALUSrc);
    $display("MemToReg = %d", cuif_tb.MemToReg);
    $display("shamt    = %d", cuif_tb.shamt);
    $display("Jal      = %d", cuif_tb.Jal);
    $display("Jump     = %d", cuif_tb.Jump);
    $display("PCSrc    = %d", cuif_tb.PCSrc);
    $display("ExtOp    = %d", cuif_tb.ExtOp);
    $display("PC_WEN   = %d", cuif_tb.PC_WEN);
    $display("iREN     = %d", cuif_tb.iREN);
    $display("halt     = %d", cuif_tb.halt);
    */

    cuif_tb.funct = ADDU;
    #(1)
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("ADDU PASSED");
    else $display("ADDU FAILED");

    #(1)
    cuif_tb.funct = ADD;
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("ADD  PASSED");
    else $display("ADD  FAILED");

    #(1)
    cuif_tb.funct = AND;
    #(1)
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1)
      $display("AND  PASSED");
    else $display("AND  FAILED");

    #(1)
    cuif_tb.funct = JR;
    #(1)
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 1 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1)
      $display("JR   PASSED");
    else $display("JR   FAILED");

    #(1)
    cuif_tb.funct = NOR;
    #(1)
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt ==  0)
      $display("NOR  PASSED");
    else $display("NOR  FAILED");

    #(1)
    cuif_tb.funct = OR;
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("OR   PASSED");
    else $display("OR   FAILED");

    #(1)
    cuif_tb.funct = SLT;
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("SLT  PASSED");
    else $display("SLT  FAILED");

    #(1)
    cuif_tb.funct = SLTU;
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("SLTU PASSED");
    else $display("SLTU FAILED");

    #(1)
    cuif_tb.funct = SLL;
    #(1)
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 1 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("SLL  PASSED");
    else $display("SLL  FAILED");
    
    #(1)
    cuif_tb.funct = SRL;
    #(1)
    #(1)
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 1 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("SRL  PASSED");
    else $display("SRL  FAILED");

    #(1)
    cuif_tb.funct = SUBU;
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 1 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("SUBU PASSED");
    else $display("SUBU FAILED");

    #(1)
    cuif_tb.funct = SUB;
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1 && cuif_tb.halt == 0)
      $display("SUB  PASSED");
    else $display("SUB  FAILED");
  
    #(1)
    cuif_tb.funct = XOR;
    if (cuif_tb.RegDst == 1 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1)
      $display("XOR  PASSED");
    else $display("XOR  FAILED");

    #(1)
    cuif_tb.opcode = BEQ;
    cuif_tb.alu_zero = 0;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 0 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 0 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1)
      $display("BEQ  PASSED");
    else $display("BEQ  FAILED");

    #(1)
    cuif_tb.opcode = BNE;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 0 && cuif_tb.ALUSrc == 0
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 0 && cuif_tb.ExtOp == 0
        && cuif_tb.PC_WEN == 1)
      $display("BNE  PASSED");
    else $display("BNE  FAILED");

    #(1)
    cuif_tb.opcode = ADDI;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("ADDI PASSED");
    else $display("ADDI FAILED");

    #(1)
    cuif_tb.opcode = ADDIU;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("ADDIU PASSED");
    else $display("ADDIU FAILED");

    #(1)
    cuif_tb.opcode = ORI;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("ORI  PASSED");
    else $display("ORI  FAILED");

    #(1)
    cuif_tb.opcode = XORI;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("XORI PASSED");
    else $display("XORI FAILED");

    #(1)
    cuif_tb.opcode = LUI;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("LUI  PASSED");
    else $display("LUI  FAILED");

    #(1)
    cuif_tb.opcode = LW;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 1 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("LW   PASSED");
    else $display("LW   FAILED");

    #(1)
    cuif_tb.opcode = SW;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 0 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("SW   PASSED");
    else $display("SW   FAILED");

    #(1)
    cuif_tb.opcode = J;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 1
        && cuif_tb.Jump == 2 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("J    PASSED");
    else $display("J    FAILED");

    #(1)
    cuif_tb.opcode = JAL;
    cuif_tb.alu_zero = 1;
    #(1)
    if (cuif_tb.RegDst == 0 && cuif_tb.RegWrite == 1 && cuif_tb.ALUSrc == 1
        && cuif_tb.MemToReg == 0 && cuif_tb.shamt == 0 && cuif_tb.Jal == 0
        && cuif_tb.Jump == 2 && cuif_tb.PCSrc == 1 && cuif_tb.ExtOp == 1
        && cuif_tb.PC_WEN == 1)
      $display("JAL  PASSED");
    else $display("JAL  FAILED");

  end
endprogram