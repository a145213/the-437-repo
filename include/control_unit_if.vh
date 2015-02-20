`ifndef CONTROL_UNIT_IF_VH
`define CONTROL_UNIT_IF_VH

// ram memory types
`include "cpu_types_pkg.vh"

interface control_unit_if;
  // import types
  import cpu_types_pkg::*;
  
  opcode_t opcode;
  funct_t funct;

  logic halt;
  // ouput to request unit
  logic iREN, dWEN, dREN;

  // mux select register destination
  logic [1:0] RegDst;
  // mux select  writing from memory or ALU ouput back to Reg
  logic [1:0] MemToReg;
  // mux select PC source
  logic [1:0] PCSrc;
  // mux select ALU operand
  logic [1:0] ALUSrc;

  // register write enable
  logic RegWrite;
  // memory write enable
  logic MemWrite;
  // memory read enable
  logic MemRead;
  // zero extend or sign extend
  logic ExtOp;
  // alu zero flag
  logic alu_zero;
  // PC enable
  //logic PC_WEN;

  logic check_overflow;
  logic check_zero;

  // alu opcode
  aluop_t alu_op;
  logic overflow;

  modport cu (
    input opcode, funct, alu_zero, overflow,
    output halt, iREN, dREN, dWEN, RegDst, MemToReg, 
    PCSrc, ALUSrc, RegWrite, MemWrite, MemRead, ExtOp, alu_op, check_overflow, check_zero
  );

  modport tb (
    output opcode, funct, alu_zero, overflow,
    input halt, iREN, dREN, dWEN, RegDst, MemToReg, 
    PCSrc, ALUSrc, RegWrite, MemWrite, MemRead, ExtOp, alu_op, check_overflow, check_zero
  );

endinterface

`endif