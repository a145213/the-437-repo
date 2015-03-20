`include "decode_execute_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_decode_execute
(
  input logic CLK, nRST,
  decode_execute_if.de deif
);

import cpu_types_pkg::*;

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST) begin
    deif.e_RegDst <= 0;
    deif.e_ALUSrc <= 0;
    deif.e_PCSrc <= 0;
    deif.e_MemToReg <= 0;
    deif.e_dREN <= 0;
    deif.e_dWEN <= 0;
    deif.e_RegWrite <= 0;
    deif.e_halt <= 0;
    deif.e_rdat1 <= 0;
    deif.e_rdat2 <= 0;
    deif.e_sign_ext <= 0;
    deif.e_taddr <= 0;
    deif.e_rs <= 0;
    deif.e_rd <= 0;
    deif.e_rt <= 0;
    deif.e_shift_amt <= 0;
    deif.e_pc4 <= 0;
    deif.e_alu_op <= ALU_SLL;
    deif.e_check_zero <= 0;
    deif.e_check_overflow <= 0;
    deif.e_op <= RTYPE;
  end
  else if (deif.de_state == PIPE_ENABLE) begin
    deif.e_RegDst <= deif.d_RegDst;
    deif.e_ALUSrc <= deif.d_ALUSrc;
    deif.e_PCSrc <= deif.d_PCSrc;
    deif.e_MemToReg <= deif.d_MemToReg;
    deif.e_dREN <= deif.d_dREN;
    deif.e_dWEN <= deif.d_dWEN;
    deif.e_RegWrite <= deif.d_RegWrite;
    deif.e_halt <= deif.d_halt;
    deif.e_rdat1 <= deif.d_rdat1;
    deif.e_rdat2 <= deif.d_rdat2;
    deif.e_sign_ext <= deif.d_sign_ext;
    deif.e_taddr <= deif.d_taddr;
    deif.e_rs <= deif.d_rs;
    deif.e_rd <= deif.d_rd;
    deif.e_rt <= deif.d_rt;
    deif.e_shift_amt <= deif.d_shift_amt;
    deif.e_pc4 <= deif.d_pc4;
    deif.e_alu_op <= deif.d_alu_op;
    deif.e_check_zero <= deif.d_check_zero;
    deif.e_check_overflow <= deif.d_check_overflow;
    deif.e_op <= deif.d_op;
  end else if (deif.de_state == PIPE_NOP) begin
    deif.e_RegDst <= 0;
    deif.e_ALUSrc <= 0;
    deif.e_PCSrc <= 0;
    deif.e_MemToReg <= 0;
    deif.e_dREN <= 0;
    deif.e_dWEN <= 0;
    deif.e_RegWrite <= 0;
    deif.e_halt <= 0;
    deif.e_rdat1 <= 0;
    deif.e_rdat2 <= 0;
    deif.e_sign_ext <= 0;
    deif.e_taddr <= 0;
    deif.e_rs <= 0;
    deif.e_rd <= 0;
    deif.e_rt <= 0;
    deif.e_shift_amt <= 0;
    deif.e_pc4 <= 0;
    deif.e_alu_op <= ALU_SLL;
    deif.e_check_zero <= 0;
    deif.e_check_overflow <= 0;
    deif.e_op <= RTYPE;
    end
end

endmodule