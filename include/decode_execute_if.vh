`ifndef DECODE_EXECUTE_IF_VH
`define DECODE_EXECUTE_IF_VH
`include "cpu_types_pkg.vh"

interface decode_execute_if;

  import cpu_types_pkg::*;

  // Latch states
  pipe_state_t de_state;

  // Carry-Through Signals
  word_t d_pc4, e_pc4;

  // Decode Stage Generated Signals
  logic d_dREN, e_dREN;
  logic d_dWEN, e_dWEN;
  logic d_datomic, e_datomic;
  logic d_RegWrite, e_RegWrite;
  logic d_halt, e_halt;
  logic d_check_zero, e_check_zero;
  logic d_check_overflow, e_check_overflow;
  logic [1:0] d_RegDst, e_RegDst;
  logic [1:0] d_ALUSrc, e_ALUSrc;
  logic [1:0] d_PCSrc, e_PCSrc;
  logic [1:0] d_MemToReg, e_MemToReg;
  aluop_t d_alu_op, e_alu_op;
  logic [SHAM_W-1:0] d_shift_amt, e_shift_amt;
  regbits_t d_rs, e_rs;
  regbits_t d_rd, e_rd;
  regbits_t d_rt, e_rt;
  opcode_t d_op, e_op;
  word_t d_rdat1, e_rdat1;
  word_t d_rdat2, e_rdat2;
  word_t d_sign_ext, e_sign_ext;
  word_t d_taddr, e_taddr;

  // Decode-Execute Latch
  modport de (
    input 
            de_state,
            d_pc4,
            d_RegDst,
            d_ALUSrc,
            d_PCSrc,
            d_MemToReg,
            d_dREN,
            d_dWEN,
	    d_datomic,
            d_RegWrite,
            d_halt,
            d_check_zero,
            d_check_overflow,
            d_alu_op,
            d_shift_amt,
            d_rs,
            d_rd,
            d_rt,
            d_op,
            d_rdat1,
            d_rdat2,
            d_sign_ext,
            d_taddr,
    output 
            e_pc4,
            e_RegDst,
            e_ALUSrc,
            e_PCSrc,
            e_MemToReg,
            e_dREN,
            e_dWEN,
	    e_datomic,
            e_RegWrite,
            e_halt,
            e_check_zero,
            e_check_overflow,
            e_alu_op,
            e_shift_amt,
            e_rs,
            e_rd,
            e_rt,
            e_op,
            e_rdat1,
            e_rdat2,
            e_sign_ext,
            e_taddr
  );

 endinterface

 `endif
