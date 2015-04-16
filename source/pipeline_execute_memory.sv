`include "execute_mem_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_execute_memory
(
  input logic CLK, nRST,
  execute_mem_if.em emif
);

import cpu_types_pkg::*;

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST) begin
    emif.m_PCSrc <= 0;
    emif.m_MemToReg <= 0;
    emif.m_dREN <= 0;
    emif.m_dWEN <= 0;
    emif.m_datomic <= 0;
    emif.m_RegWrite <= 0;
    emif.m_halt <= 0;
    emif.m_rdat1 <= 0;
    emif.m_rdat2 <= 0;
    emif.m_jaddr <= 0;
    emif.m_pc4 <= 0;
    emif.m_port_o <= 0;
    emif.m_zero <= 0;
    emif.m_overflow <= 0;
    emif.m_lui <= 0;
    emif.m_regWSEL <= 0;
    emif.m_baddr <= 0;
    emif.m_check_zero <= 0;
    emif.m_check_overflow <= 0;
    emif.m_rs <= 0;
    emif.m_rt <= 0;
    emif.m_op <= RTYPE;
  end
  else if (emif.em_state == PIPE_ENABLE) begin
    emif.m_PCSrc <= emif.e_PCSrc;
    emif.m_MemToReg <= emif.e_MemToReg;
    emif.m_dREN <= emif.e_dREN;
    emif.m_dWEN <= emif.e_dWEN;
    emif.m_datomic <= emif.e_datomic;
    emif.m_RegWrite <= emif.e_RegWrite;
    emif.m_halt <=  emif.e_halt;
    emif.m_rdat1 <= emif.e_rdat1;
    emif.m_rdat2 <= emif.e_memstore;
    emif.m_jaddr <= emif.e_jaddr;
    emif.m_pc4 <= emif.e_pc4;
    emif.m_port_o <= emif.e_port_o;
    emif.m_zero <= emif.e_zero;
    emif.m_overflow <= emif.e_overflow;
    emif.m_lui <= emif.e_lui;
    emif.m_regWSEL <= emif.e_regWSEL;
    emif.m_baddr <= emif.e_baddr;
    emif.m_check_zero <= emif.e_check_zero;
    emif.m_check_overflow <= emif.e_check_overflow;
    emif.m_rs <= emif.e_rs;
    emif.m_rt <= emif.e_rt;
    emif.m_op <= emif.e_op;
  end else if (emif.em_state == PIPE_NOP) begin
    emif.m_PCSrc <= 0;
    emif.m_MemToReg <= 0;
    emif.m_dREN <= 0;
    emif.m_dWEN <= 0;
    emif.m_datomic <=0;
    emif.m_RegWrite <= 0;
    emif.m_halt <= 0;
    emif.m_rdat1 <= 0;
    emif.m_rdat2 <= 0;
    emif.m_jaddr <= 0;
    emif.m_pc4 <= 0;
    emif.m_port_o <= 0;
    emif.m_zero <= 0;
    emif.m_overflow <= 0;
    emif.m_lui <= 0;
    emif.m_regWSEL <= 0;
    emif.m_baddr <= 0;
    emif.m_check_zero <= 0;
    emif.m_check_overflow <= 0;
    emif.m_rs <= 0;
    emif.m_rt <= 0;
    emif.m_op <= RTYPE;
  end
end

endmodule
