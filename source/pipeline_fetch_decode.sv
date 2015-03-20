`include "fetch_decode_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_fetch_decode
(
  input logic CLK, nRST,
  fetch_decode_if.fd fdif
);

import cpu_types_pkg::*;

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST) begin
    fdif.d_instr <= 0;
    fdif.d_pc4 <= 0;
  end
  else if (fdif.fd_state == PIPE_ENABLE) begin
    fdif.d_instr <= fdif.f_instr;
    fdif.d_pc4 <= fdif.f_pc4;
  end else if (fdif.fd_state == PIPE_NOP) begin
    fdif.d_instr <= 0;
    fdif.d_pc4 <= 0;
  end
end

endmodule