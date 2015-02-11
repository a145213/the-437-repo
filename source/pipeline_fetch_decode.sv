`include "pipeline_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_fetch_decode
(
  input logic CLK, nRST,
  pipeline_if.fd fdif
);

always_ff @ (posedge CLK, negedge nRST) begin
  if (!nRST || fdif.flush_fd) begin
    fdif.instr_dec <= 0;
    fdif.pc4_dec <= 0;
  end
  else if (fdif.en_fd) begin
    fdif.instr_dec <= fdif.instr_fet;
    fdif.pc4_dec <= fdif.pc4_fet;

  end
end

endmodule