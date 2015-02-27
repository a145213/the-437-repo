`include "pipeline_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_memory_WB
(
  input logic CLK, nRST,
  pipeline_if.mw mwif
);

import cpu_types_pkg::*;

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST) begin
    mwif.RegWrite_wb <= 0;
    mwif.halt_wb <= 0;
    mwif.MemToReg_wb <= 0;
    mwif.dmemload_wb <= 0;
    mwif.port_o_wb <= 0;
    mwif.lui_wb <= 0;
    mwif.pc4_wb <= 0;
    mwif.regWSEL_wb <= 0;
    mwif.rdat2_wb <= 0;
  end
  else if (mwif.mw_state == PIPE_ENABLE) begin
    mwif.RegWrite_wb <= mwif.RegWrite_mem;
    mwif.halt_wb <= mwif.halt_mem;
    mwif.MemToReg_wb <= mwif.MemToReg_mem;
    mwif.dmemload_wb <= mwif.dmemload_mem;
    mwif.port_o_wb <= mwif.port_o_mem;
    mwif.lui_wb <= mwif.lui_mem;
    mwif.pc4_wb <= mwif.pc4_mem;
    mwif.regWSEL_wb <= mwif.regWSEL_mem;
    mwif.rdat2_wb <= mwif.rdat2_mem;
  end else if (mwif.mw_state == PIPE_NOP) begin
    mwif.RegWrite_wb <= 0;
    mwif.halt_wb <= 0;
    mwif.MemToReg_wb <= 0;
    mwif.dmemload_wb <= 0;
    mwif.port_o_wb <= 0;
    mwif.lui_wb <= 0;
    mwif.pc4_wb <= 0;
    mwif.regWSEL_wb <= 0;
    mwif.rdat2_wb <= 0;
  end
end

endmodule