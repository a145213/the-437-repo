`ifndef MEM_WRITEBACK_VH
`define MEM_WRITEBACK_VH
`include "cpu_types_pkg.vh"

interface mem_writeback_if;

  import cpu_types_pkg::*;

  // Latch states
  pipe_state_t mw_state;

  // Carry-Through Signals
  logic m_RegWrite, w_RegWrite;
  logic m_halt, w_halt;
  logic [1:0] m_MemToReg, w_MemToReg;
  regbits_t m_regWSEL, w_regWSEL;
  opcode_t m_op, w_op;
  word_t m_pc4, w_pc4;
  word_t m_rdat1, w_rdat1;
  word_t m_rdat2, w_rdat2;
  word_t m_lui, w_lui;
  word_t m_port_o, w_port_o;

  // Memory Stage Generated Signals  
  word_t m_dmemload, w_dmemload;

  // Memory-Write Back Latch
  modport mw (
    input 
            mw_state,
            m_RegWrite,
            m_halt,
            m_MemToReg,
            m_regWSEL,
            m_op,
            m_pc4,
            m_rdat1,
            m_rdat2,
            m_lui,
            m_port_o,
            m_dmemload,

    output 
            w_RegWrite,
            w_halt,
            w_MemToReg,
            w_regWSEL,
            w_op,
            w_pc4,
            w_rdat1,
            w_rdat2,
            w_lui,
            w_port_o,
            w_dmemload
  );

 endinterface

 `endif