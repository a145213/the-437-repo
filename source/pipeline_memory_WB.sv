`include "mem_writeback_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_memory_WB
(
  input logic CLK, nRST,
  mem_writeback_if.mw mwif
);

import cpu_types_pkg::*;

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST) begin
    mwif.w_RegWrite <= 0;
    mwif.w_halt <= 0;
    mwif.w_MemToReg <= 0;
    mwif.w_dmemload <= 0;
    mwif.w_port_o <= 0;
    mwif.w_lui <= 0;
    mwif.w_pc4 <= 0;
    mwif.w_regWSEL <= 0;
    mwif.w_rdat2 <= 0;
    mwif.w_op <= RTYPE;
  end
  else if (mwif.mw_state == PIPE_ENABLE) begin
    mwif.w_RegWrite <= mwif.m_RegWrite;
    mwif.w_halt <= mwif.m_halt;
    mwif.w_MemToReg <= mwif.m_MemToReg;
    mwif.w_dmemload <= mwif.m_dmemload;
    mwif.w_port_o <= mwif.m_port_o;
    mwif.w_lui <= mwif.m_lui;
    mwif.w_pc4 <= mwif.m_pc4;
    mwif.w_regWSEL <= mwif.m_regWSEL;
    mwif.w_rdat2 <= mwif.m_rdat2;
    mwif.w_op <= mwif.m_op;
  end 
  /* else if (mwif.mw_state == PIPE_NOP) begin
    mwif.RegWrite_wb <= 0;
    mwif.halt_wb <= 0;
    mwif.MemToReg_wb <= 0;
    mwif.dmemload_wb <= 0;
    mwif.port_o_wb <= 0;
    mwif.lui_wb <= 0;
    mwif.pc4_wb <= 0;
    mwif.regWSEL_wb <= 0;
    mwif.rdat2_wb <= 0;
    mwif.w_op <= RTYPE;
  end
  */
end

endmodule