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
  logic ex_hazard;
  logic mem_hazard;
  logic rs_hazard;
  logic rt_hazard;

  // 
  // PC Write Enable Logic
  //
  assign huif.PC_WEN = 
            (huif.ihit & !huif.dhit) &&
            !(
              (rs_hazard || rt_hazard)
            );

  //
  // Hazard detections
  //
  assign ex_hazard = (huif.ex_wsel == huif.rs) || (huif.ex_wsel == huif.rt);
  assign mem_hazard = (huif.mem_wsel == huif.rs) || (huif.mem_wsel == huif.rt);
  assign rs_hazard = (huif.rs != 0) && ((huif.ex_wsel == huif.rs) || (huif.mem_wsel == huif.rs));
  assign rt_hazard = (huif.rt != 0) && ((huif.ex_wsel == huif.rt) || (huif.mem_wsel == huif.rt));

  //
  // Fetch-Decode Latch Logic
  //
  always_comb begin
  	if (rs_hazard || rt_hazard) begin
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
  	if (rs_hazard || rt_hazard) begin
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
  	if (huif.ihit && !huif.dhit) begin
  		huif.em_state = PIPE_ENABLE;
  	end else if (!huif.ihit || huif.dhit) begin
  		huif.em_state = PIPE_NOP;
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