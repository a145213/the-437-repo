`include "pipeline_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_decode_execute
(
  input logic CLK, nRST,
  pipeline_if.de deif
);

import cpu_types_pkg::*;

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST) begin
    deif.RegDst_ex <= 0;
    deif.ALUSrc_ex <= 0;
    deif.PCSrc_ex <= 0;
    deif.MemToReg_ex <= 0;
    deif.dREN_ex <= 0;
    deif.dWEN_ex <= 0;
    deif.RegWrite_ex <= 0;
    deif.halt_ex <= 0;
    deif.rdat1_ex <= 0;
    deif.rdat2_ex <= 0;
    deif.sign_ext_ex <= 0;
    deif.taddr_ex <= 0;
    deif.rs_ex <= 0;
    deif.rd_ex <= 0;
    deif.rt_ex <= 0;
    deif.shift_amt_ex <= 0;
    deif.pc4_ex <= 0;
    deif.alu_op_ex <= ALU_SLL;
    deif.check_zero_ex <= 0;
    deif.check_overflow_ex <= 0;
  end
  else if (deif.de_state == PIPE_ENABLE) begin
    deif.RegDst_ex <= deif.RegDst_dec;
    deif.ALUSrc_ex <= deif.ALUSrc_dec;
    deif.PCSrc_ex <= deif.PCSrc_dec;
    deif.MemToReg_ex <= deif.MemToReg_dec;
    deif.dREN_ex <= deif.dREN_dec;
    deif.dWEN_ex <= deif.dWEN_dec;
    deif.RegWrite_ex <= deif.RegWrite_dec;
    deif.halt_ex <= deif.halt_dec;
    deif.rdat1_ex <= deif.rdat1_dec;
    deif.rdat2_ex <= deif.rdat2_dec;
    deif.sign_ext_ex <= deif.sign_ext_dec;
    deif.taddr_ex <= deif.taddr_dec;
    deif.rs_ex <= deif.rs_dec;
    deif.rd_ex <= deif.rd_dec;
    deif.rt_ex <= deif.rt_dec;
    deif.shift_amt_ex <= deif.shift_amt_dec;
    deif.pc4_ex <= deif.pc4_dec;
    deif.alu_op_ex <= deif.alu_op_dec;
    deif.check_zero_ex <= deif.check_zero_dec;
    deif.check_overflow_ex <= deif.check_overflow_dec;
  end else if (deif.de_state == PIPE_NOP) begin
    deif.RegDst_ex <= 0;
    deif.ALUSrc_ex <= 0;
    deif.PCSrc_ex <= 0;
    deif.MemToReg_ex <= 0;
    deif.dREN_ex <= 0;
    deif.dWEN_ex <= 0;
    deif.RegWrite_ex <= 0;
    deif.halt_ex <= 0;
    deif.rdat1_ex <= 0;
    deif.rdat2_ex <= 0;
    deif.sign_ext_ex <= 0;
    deif.taddr_ex <= 0;
    deif.rs_ex <= 0;
    deif.rd_ex <= 0;
    deif.rt_ex <= 0;
    deif.shift_amt_ex <= 0;
    deif.pc4_ex <= 0;
    deif.alu_op_ex <= ALU_SLL;
    deif.check_zero_ex <= 0;
    deif.check_overflow_ex <= 0;
    end
end

endmodule