`ifndef FETCH_DECODE_IF_VH
`define FETCH_DECODE_IF_VH
`include "cpu_types_pkg.vh"

interface fetch_decode_if;

  import cpu_types_pkg::*;

  // Latch states
  pipe_state_t fd_state;

  // Fetch Stage Generated Signals
  word_t f_instr, d_instr;
  word_t f_pc4, d_pc4;

  // Fetch-Decode Latch
  modport fd (
    input 
            fd_state,
            f_instr,
            f_pc4,
    output 
            d_instr, 
            d_pc4
  );

 endinterface

 `endif