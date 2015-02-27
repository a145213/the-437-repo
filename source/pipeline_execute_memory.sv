`include "pipeline_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_execute_memory
(
  input logic CLK, nRST,
  pipeline_if.em emif
);

import cpu_types_pkg::*;

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST) begin
    emif.PCSrc_mem <= 0;
    emif.MemToReg_mem <= 0;
    emif.dREN_mem <= 0;
    emif.dWEN_mem <= 0;
    emif.RegWrite_mem <= 0;
    emif.halt_mem <= 0;
    emif.rdat1_mem <= 0;
    emif.rdat2_mem <= 0;
    emif.jaddr_mem <= 0;
    emif.pc4_mem <= 0;
    emif.port_o_mem <= 0;
    emif.zero_mem <= 0;
    emif.overflow_mem <= 0;
    emif.lui_mem <= 0;
    emif.regWSEL_mem <= 0;
    emif.baddr_mem <= 0;
    emif.check_zero_mem <= 0;
    emif.check_overflow_mem <= 0;
    emif.rs_mem <= 0;
    emif.rt_mem <= 0;
  end
  else if (emif.em_state == PIPE_ENABLE) begin
    emif.PCSrc_mem <= emif.PCSrc_ex;
    emif.MemToReg_mem <= emif.MemToReg_ex;
    emif.dREN_mem <= emif.dREN_ex;
    emif.dWEN_mem <= emif.dWEN_ex;
    emif.RegWrite_mem <= emif.RegWrite_ex;
    emif.halt_mem <=  emif.halt_ex;
    emif.rdat1_mem <= emif.rdat1_ex;
    emif.rdat2_mem <= emif.rdat2_ex;
    emif.jaddr_mem <= emif.jaddr_ex;
    emif.pc4_mem <= emif.pc4_ex;
    emif.port_o_mem <= emif.port_o_ex;
    emif.zero_mem <= emif.zero_ex;
    emif.overflow_mem <= emif.overflow_ex;
    emif.lui_mem <= emif.lui_ex;
    emif.regWSEL_mem <= emif.regWSEL_ex;
    emif.baddr_mem <= emif.baddr_ex;
    emif.check_zero_mem <= emif.check_zero_ex;
    emif.check_overflow_mem <= emif.check_overflow_ex;
    emif.rs_mem <= emif.rs_ex;
    emif.rt_mem <= emif.rt_ex;
  end else if (emif.em_state == PIPE_NOP) begin
    emif.PCSrc_mem <= 0;
    emif.MemToReg_mem <= 0;
    emif.dREN_mem <= 0;
    emif.dWEN_mem <= 0;
    emif.RegWrite_mem <= 0;
    emif.halt_mem <= 0;
    emif.rdat1_mem <= 0;
    emif.rdat2_mem <= 0;
    emif.jaddr_mem <= 0;
    emif.pc4_mem <= 0;
    emif.port_o_mem <= 0;
    emif.zero_mem <= 0;
    emif.overflow_mem <= 0;
    emif.lui_mem <= 0;
    emif.regWSEL_mem <= 0;
    emif.baddr_mem <= 0;
    emif.check_zero_mem <= 0;
    emif.check_overflow_mem <= 0;
    emif.rs_mem <= 0;
    emif.rt_mem <= 0;
  end
end

endmodule