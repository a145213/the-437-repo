`ifndef PIPELINE_IF_VH
`define PIPELINE_IF_VH
`include "cpu_types_pkg.vh"

interface pipeline_if;

  import cpu_types_pkg::*;

  // latch enables
  logic en_fd, en_de, en_em, en_mw;
  logic flush_fd, flush_de, flush_em, flush_mw;
  // fetch-decode
  word_t instr_fet;
  word_t instr_dec;
  word_t pc4_fet;
  word_t pc4_dec;

  // decode-execute
  logic [1:0] RegDst_dec;
  logic [1:0] ALUSrc_dec;
  logic [1:0] PCSrc_dec;
  logic [1:0] MemToReg_dec;
  logic dREN_dec, dWEN_dec, RegWrite_dec, halt_dec;

  word_t rdat1_dec, rdat2_dec;
  word_t sign_ext_dec, taddr_dec, jaddr_dec, rd_dec, rt_dec, shift_amt_dec;
  aluop_t alu_op_dec;

  logic [1:0] RegDst_ex;
  logic [1:0] ALUSrc_ex;
  logic [1:0] PCSrc_ex;
  logic [1:0] MemToReg_ex;
  logic dREN_ex, dWEN_ex, RegWrite_ex, halt_ex, zero_ex, overflow_ex;

  word_t rdat1_ex, rdat2_ex;
  word_t sign_ext_ex, taddr_ex, jaddr_ex, rd_ex, rt_ex, shift_amt_ex;
  word_t pc4_ex, lui_ex, regWSEL_ex, baddr_ex, port_o_ex;
  aluop_t alu_op_ex;

  // execute-memory
  logic [1:0] PCSrc_mem;
  logic [1:0] MemToReg_mem;
  logic dREN_mem, dWEN_mem, RegWrite_mem, halt_mem, RegWrite_wb, halt_wb;
  
  word_t rdat1_mem, rdat2_mem;
  word_t port_o_mem, zero_mem, overflow_mem, lui_mem, pc4_mem, 
        jaddr_mem, regWSEL_mem, baddr_mem, dmemload_mem;

  // memory-write_back
  word_t dmemload_wb, port_o_wb, lui_wb, pc4_wb, regWSEL_wb;
  logic [1:0] MemToReg_wb;

  // fetch-decode
  modport fd (
    input instr_fet, pc4_fet, en_fd, flush_fd,
    output instr_dec, pc4_dec
  );

  // decode-execute
  modport de (
    input RegDst_dec, ALUSrc_dec, PCSrc_dec, MemToReg_dec, dREN_dec, 
      dWEN_dec, RegWrite_dec, halt_dec, rdat1_dec, rdat2_dec, sign_ext_dec,
      taddr_dec, rd_dec, rt_dec, pc4_dec, alu_op_dec, shift_amt_dec, en_de, flush_de,
    output RegDst_ex, ALUSrc_ex, PCSrc_ex, MemToReg_ex, dREN_ex, 
      dWEN_ex, RegWrite_ex, halt_ex, rdat1_ex, rdat2_ex, sign_ext_ex,
      taddr_ex, rd_ex, rt_ex, shift_amt_ex, pc4_ex, alu_op_ex
  );

  // execute-memory
  modport em (
    input PCSrc_ex, dWEN_ex, dREN_ex, RegWrite_ex, halt_ex, MemToReg_ex,
      rdat1_ex, rdat2_ex, port_o_ex, zero_ex, overflow_ex, lui_ex, pc4_ex,
      jaddr_ex, regWSEL_ex, baddr_ex, en_em, flush_em,
    output PCSrc_mem, dWEN_mem, dREN_mem, RegWrite_mem, halt_mem, MemToReg_mem,
      rdat1_mem, rdat2_mem, port_o_mem, zero_mem, overflow_mem, lui_mem, 
      pc4_mem, jaddr_mem, regWSEL_mem, baddr_mem
  );

  // memory-write_back
  modport mw (
    input RegWrite_mem, halt_mem, MemToReg_mem, dmemload_mem, port_o_mem, lui_mem,
      pc4_mem, regWSEL_mem, en_mw, flush_mw,
    output RegWrite_wb, halt_wb, dmemload_wb, port_o_wb, lui_wb, pc4_wb, regWSEL_wb, MemToReg_wb
  );


 endinterface

 `endif