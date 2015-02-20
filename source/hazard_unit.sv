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
  logic beq, bne, branching;
  logic jumping;

  // 
  // PC Write Enable Logic
  //
  assign huif.PC_WEN = 
            (huif.ihit & !huif.dhit) &&
            !(
              (rs_hazard || rt_hazard)
            ) ||
            jumping;

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
  assign branching = (huif.PCSrc == 1) && (beq || bne);
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
  assign jumping = (huif.PCSrc == 2) || (huif.PCSrc == 3);
  
  //
  // Fetch-Decode Latch Logic
  //
  always_comb begin
  	if (branching || jumping) begin
      huif.fd_state = PIPE_NOP;
    end else if (rs_hazard || rt_hazard) begin
      huif.fd_state = PIPE_STALL;
    end else if (huif.ihit && !huif.dhit) begin
      huif.fd_state = PIPE_ENABLE;
    end else begin
      huif.fd_state = PIPE_STALL;
    end
  end

  //
  // Decode-Execute Latch Logic
  //
  always_comb begin
  	if (branching || jumping) begin
      huif.de_state = PIPE_NOP;
    end else if (rs_hazard || rt_hazard) begin
      huif.de_state = PIPE_NOP;
    end else if (huif.ihit && !huif.dhit) begin
      huif.de_state = PIPE_ENABLE;
    end else begin
  		huif.de_state = PIPE_STALL;
  	end
  end

  //
  // Execute-Memory Latch Logic
  //
  always_comb begin
  	if (branching || jumping) begin
      huif.em_state = PIPE_NOP;
    end else if (huif.ihit && !huif.dhit) begin
  		huif.em_state = PIPE_ENABLE;
  	end else if (!huif.ihit || huif.dhit) begin
  		huif.em_state = PIPE_NOP;
  	end else begin
      huif.em_state = PIPE_STALL;
    end
  end

  //
  // Memory-Write back Latch Logic
  //
  always_comb begin
  	if (huif.ihit || huif.dhit) begin
  		huif.mw_state = PIPE_ENABLE;
  	end else begin
  		huif.mw_state = PIPE_STALL;
  	end
  end

endmodule