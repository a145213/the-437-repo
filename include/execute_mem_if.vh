`ifndef EXECUTE_MEM_VH
`define EXECUTE_MEM_VH
`include "cpu_types_pkg.vh"

interface execute_mem_if;

  import cpu_types_pkg::*;

  // Latch states
  pipe_state_t em_state;

  // Carry-Through Signals
  logic e_dREN, m_dREN;
  logic e_dWEN, m_dWEN;
  logic e_datomic, m_datomic;
  logic e_RegWrite, m_RegWrite;
  logic e_halt, m_halt;
  logic e_check_zero, m_check_zero;
  logic e_check_overflow, m_check_overflow;
  logic [1:0] e_PCSrc, m_PCSrc;
  logic [1:0] e_MemToReg, m_MemToReg;
  regbits_t e_rs, m_rs;
  regbits_t e_rd, m_rd;
  regbits_t e_rt, m_rt;
  opcode_t e_op, m_op;
  word_t e_pc4, m_pc4;
  word_t e_rdat1, m_rdat1;
  word_t e_rdat2, m_rdat2;
  word_t e_sign_ext, m_sign_ext;
  word_t e_taddr, m_taddr;

  // Execute Stage Generated Signals
  logic e_zero, m_zero;
  logic e_overflow, m_overflow;
  regbits_t e_regWSEL, m_regWSEL;
  word_t e_lui, m_lui;
  word_t e_baddr, m_baddr;
  word_t e_jaddr, m_jaddr;
  word_t e_port_o, m_port_o;
  word_t e_memstore, m_memstore;


  // Execute-Memory Latch
  modport em (
    input 
            em_state,
            e_dREN,
            e_dWEN,
	    e_datomic,
            e_RegWrite,
            e_halt,
            e_check_zero,
            e_check_overflow,
            e_PCSrc,
            e_MemToReg,
            e_rs,
            e_rd,
            e_rt,
            e_op,
            e_pc4,
            e_rdat1,
            e_rdat2,
            e_sign_ext,
            e_taddr,
            e_zero,
            e_overflow,
            e_regWSEL,
            e_lui,
            e_baddr,
            e_jaddr,
            e_port_o,
            e_memstore,
    output 
            m_dREN,
            m_dWEN,
	    m_datomic,
            m_RegWrite,
            m_halt,
            m_check_zero,
            m_check_overflow,
            m_PCSrc,
            m_MemToReg,
            m_rs,
            m_rd,
            m_rt,
            m_op,
            m_pc4,
            m_rdat1,
            m_rdat2,
            m_sign_ext,
            m_taddr,
            m_zero,
            m_overflow,
            m_regWSEL,
            m_lui,
            m_baddr,
            m_jaddr,
            m_port_o,
            m_memstore
  );

 endinterface

 `endif
