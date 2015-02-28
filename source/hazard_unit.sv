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
  assign huif.PC_WEN = 
            (huif.ihit & !huif.dhit) ||
            huif.jumping;

  //
  // Hazard detections
  //
  assign rs_hazard = (huif.rs != 0) && ((huif.ex_wsel == huif.rs) || (huif.mem_wsel == huif.rs));
  assign rt_hazard = (huif.rt != 0) && ((huif.ex_wsel == huif.rt) || (huif.mem_wsel == huif.rt));

  //
  // Branch detections
  //
  assign beq_hazard = huif.check_zero && !huif.alu_zero;
  assign bne_hazard = !huif.check_zero && huif.alu_zero;
  assign branch_hazard = ((beq_hazard || bne_hazard) && (huif.PCSrc == 1));
  assign beq = huif.check_zero && huif.alu_zero;
  assign bne = !huif.check_zero && !huif.alu_zero;
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
    /*
    if (branching || jumping) begin
      huif.fd_state = PIPE_NOP;
    end else if (huif.dhit && huif.dREN) begin
      huif.fd_state = PIPE_ENABLE;
    end else if (rs_hazard || rt_hazard) begin
      huif.fd_state = PIPE_STALL;
    end else if (huif.ihit && !huif.dhit) begin
      huif.fd_state = PIPE_ENABLE;
    end else begin
      huif.fd_state = PIPE_STALL;
    end
    */


    if (huif.branching || huif.jumping) begin
      huif.fd_state = PIPE_NOP;
    end else if (huif.ihit) begin
      huif.fd_state = PIPE_ENABLE;
    end else if (huif.dhit && huif.dREN) begin
      huif.fd_state = PIPE_NOP;
    end else if (!huif.dhit && huif.dWEN) begin
      huif.fd_state = PIPE_STALL;
    end else begin
      huif.fd_state = PIPE_ENABLE;
    end
  end

  //
  // Decode-Execute Latch Logic
  //
  always_comb begin
    /*
  	if (branching || jumping) begin
      huif.de_state = PIPE_NOP;
    end else if (huif.dhit && huif.dREN) begin
      huif.de_state = PIPE_ENABLE;
    end else if (rs_hazard || rt_hazard) begin
      huif.de_state = PIPE_NOP;
    end else if (huif.ihit && !huif.dhit) begin
      huif.de_state = PIPE_ENABLE;
    end else begin
  		huif.de_state = PIPE_STALL;
  	end
    */

    if (huif.branching || huif.jumping) begin
      huif.de_state = PIPE_NOP;
    end else if (huif.ihit) begin
      huif.de_state = PIPE_ENABLE;
    end else if (huif.dhit && huif.dREN) begin
      huif.de_state = PIPE_ENABLE;
    end else if (!huif.dhit && huif.dWEN) begin
      huif.de_state = PIPE_STALL;
    end else begin
      huif.de_state = PIPE_ENABLE;
    end
  end

  //
  // Execute-Memory Latch Logic
  //
  always_comb begin
    /*
  	if (branching || jumping) begin
      huif.em_state = PIPE_NOP;
    end else if (huif.dhit && huif.dREN) begin
      huif.em_state = PIPE_ENABLE;
    end else if (huif.ihit && !huif.dhit) begin
  		huif.em_state = PIPE_ENABLE;
  	end else if (!huif.ihit || huif.dhit) begin
  		huif.em_state = PIPE_STALL;
  	end else begin
      huif.em_state = PIPE_STALL;
    end
    */
    if (huif.branching || huif.jumping) begin
      huif.em_state = PIPE_NOP;
    end else if (huif.ihit) begin
      huif.em_state = PIPE_ENABLE;
    end else if (huif.dhit && huif.dREN) begin
      huif.em_state = PIPE_ENABLE;
    end else if (!huif.dhit && huif.dWEN) begin
      huif.em_state = PIPE_STALL;
    end else begin
      huif.em_state = PIPE_ENABLE;
    end
  end

  //
  // Memory-Write back Latch Logic
  //
  always_comb begin
  /*
    if (huif.ihit) begin
      huif.mw_state = PIPE_ENABLE;
    end else if (huif.dhit && huif.dREN) begin
      huif.mw_state = PIPE_ENABLE;
    end else if (!huif.dhit && huif.dWEN) begin
      huif.mw_state = PIPE_STALL;
  	end else begin
  		huif.mw_state = PIPE_STALL;
  	end
    */
    if (huif.ihit) begin
      huif.mw_state = PIPE_ENABLE;
    end else if (huif.dhit && huif.dREN) begin
      huif.mw_state = PIPE_ENABLE;
    end else if (!huif.dhit && huif.dWEN) begin
      huif.mw_state = PIPE_STALL;
    end else begin
      huif.mw_state = PIPE_ENABLE;
    end
  end


  //
  // Hazard detections
  //
  assign haz_rs_ex = (huif.rs_mem != 0) && (huif.wb_wsel == huif.rs_mem);
  assign haz_rt_ex = (huif.rt_mem != 0) && (huif.wb_wsel == huif.rt_mem);
  assign haz_rs_mem = (huif.rs_ex != 0) && (huif.mem_wsel == huif.rs_ex);
  assign haz_rt_mem = (huif.rt_ex != 0) && (huif.mem_wsel == huif.rt_ex);
  assign haz_rs_wb = (huif.rs_ex != 0) && (huif.wb_wsel == huif.rs_ex);
  assign haz_rt_wb = (huif.rt_ex != 0) && (huif.wb_wsel == huif.rt_ex);

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
      huif.fsel_sw = 2'd2;
    end else begin
      // No forwarding
      huif.fsel_sw = 2'd0;
    end
  end

endmodule