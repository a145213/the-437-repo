`include "hazard_unit_if.vh"
`include "cpu_types_pkg.vh"

module hazard_unit
(
  hazard_unit_if.hu huif
);

  import cpu_types_pkg::*;
  
  /*
  r_t r_fetch;
  r_t r_dec;
  i_t i_fetch;
  i_t i_dec;
  assign r_fetch = huif.instr_fetch;
  assign r_dec = huif.instr_dec;
  assign i_fetch = huif.instr_fetch;
  assign i_dec = huif.instr_dec;
  */

  //
  // Variables
  //
  logic rs_hazard;
  logic rt_hazard;
  logic branch_hazard;
  logic beq_hazard;
  logic bne_hazard;
  logic beq, bne;

  logic haz_rs_ex;
  logic haz_rt_ex;
  logic haz_rs_mem;
  logic haz_rt_mem;
  logic haz_rs_wb;
  logic haz_rt_wb;

  // 
  // PC Write Enable Logic
  //
  //assign huif.PC_WEN = 
  //          (huif.ihit & !huif.dhit) ||
  //          huif.jumping;
  assign huif.PC_WEN = huif.ihit && !((huif.m_op == LW || huif.m_op == SW) && !huif.dhit);

  //
  // Hazard detections
  //
  assign rs_hazard = (huif.d_rs != 0) && ((huif.e_wsel == huif.d_rs) || (huif.m_wsel == huif.d_rs));
  assign rt_hazard = (huif.d_rt != 0) && ((huif.e_wsel == huif.d_rt) || (huif.m_wsel == huif.d_rt));

  //
  // Branch detections
  //
  assign beq_hazard = huif.check_zero && !huif.alu_zero && huif.m_op == BEQ;
  assign bne_hazard = huif.check_zero && huif.alu_zero && huif.m_op == BNE;
  assign branch_hazard = ((beq_hazard || bne_hazard) && (huif.PCSrc == 1));
  assign beq = huif.check_zero && huif.alu_zero && huif.m_op == BEQ;
  assign bne = huif.check_zero && !huif.alu_zero && huif.m_op == BNE;
  assign huif.branching = (huif.PCSrc == 1) && (beq || bne);
  always_comb begin
    if (branch_hazard) begin
      huif.PCSrc_check = 0;
    end else begin
      huif.PCSrc_check = huif.PCSrc;
    end
  end


  //
  // Jump detections
  //
  assign huif.jumping = (huif.PCSrc == 2) || (huif.PCSrc == 3);
  
  //
  // Fetch-Decode Latch Logic
  //
  always_comb begin
    huif.fd_state = PIPE_ENABLE;
    huif.de_state = PIPE_ENABLE;
    huif.em_state = PIPE_ENABLE;
    huif.mw_state = PIPE_ENABLE;

    // Stall pipes until next instruction is ready
    if (!huif.ihit) begin
      huif.fd_state = PIPE_STALL;
      huif.de_state = PIPE_STALL;
      huif.em_state = PIPE_STALL;
      huif.mw_state = PIPE_STALL;
    end
    
    // Takes care of getting multiple dhits
    // while waiting for an ihit
    if ((huif.m_op == LW || huif.m_op == SW) && huif.dhit) begin
      huif.fd_state = (huif.ihit)?(PIPE_ENABLE):(PIPE_NOP);
      huif.de_state = PIPE_ENABLE;
      huif.em_state = PIPE_ENABLE;
      huif.mw_state = PIPE_ENABLE;
    end else if ((huif.m_op == LW || huif.m_op == SW) && !huif.dhit) begin
      //huif.fd_state = (huif.ihit)?(PIPE_ENABLE):(PIPE_STALL);
      huif.fd_state = PIPE_STALL;
      huif.de_state = PIPE_STALL;
      huif.em_state = PIPE_STALL;
      huif.mw_state = PIPE_STALL;
    end


    // Takes care of branching and jumps
    if ((huif.branching || huif.jumping) && huif.ihit) begin
      huif.fd_state = PIPE_NOP;
      huif.de_state = PIPE_NOP;
      huif.em_state = PIPE_NOP;
      huif.mw_state = PIPE_ENABLE;
    end


    if (huif.w_halt) begin
      huif.fd_state = PIPE_NOP;
      huif.de_state = PIPE_NOP;
      huif.em_state = PIPE_NOP;
      huif.mw_state = PIPE_NOP;
    end
  end

  //
  // Hazard detections
  //
  assign haz_rs_ex = (huif.m_rs != 0) && (huif.w_wsel == huif.m_rs);
  assign haz_rt_ex = (huif.m_rt != 0) && (huif.w_wsel == huif.m_rt);
  assign haz_rs_mem = (huif.e_rs != 0) && (huif.m_wsel == huif.e_rs);
  assign haz_rt_mem = (huif.e_rt != 0) && (huif.m_wsel == huif.e_rt);
  assign haz_rs_wb = (huif.e_rs != 0) && (huif.w_wsel == huif.e_rs);
  assign haz_rt_wb = (huif.e_rt != 0) && (huif.w_wsel == huif.e_rt);

  //
  // ALU Port A Mux Select Logic
  //
  always_comb begin
    if (haz_rs_mem) begin
      // Forward from memory stage
      huif.fsel_a = 2'd2;
    end else if (haz_rs_wb) begin
      // Forward from write-back stage
      huif.fsel_a = 2'd1;
    end else begin
      // No forwarding
      huif.fsel_a = 2'd0;
    end
  end

  //
  // ALU Port B Mux Select Logic
  //
  always_comb begin
    if (haz_rt_mem) begin
      // Forward from memory stage
      huif.fsel_b = 2'd2;
    end else if (haz_rt_wb) begin
      // Forward from write-back stage
      huif.fsel_b = 2'd1;
    end else begin
      // No forwarding
      huif.fsel_b = 2'd0;
    end
  end

  //
  // Memory Store Mux Select Logic
  //
  always_comb begin
    if (haz_rt_ex) begin
      huif.fsel_sw = 2'd1;
    end else if (haz_rt_wb) begin
      huif.fsel_sw = 2'd0;
    end else begin
      // No forwarding
      huif.fsel_sw = 2'd0;
    end
  end

endmodule