
`include "register_file_if.vh"
`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;

module register_file (
  input logic CLK,
  input logic nRST,
  register_file_if.rf rfif
  );
  
  word_t [31:0] register;
  
  always_ff @ (posedge CLK, negedge nRST) begin
    if (!nRST) 
      register <= '0;
    else begin
      if (rfif.WEN) begin
          if (rfif.wsel)
            register[rfif.wsel] <= rfif.wdat;
      end
    end    
  end
  
    assign rfif.rdat1 = rfif.rsel1 == 0 ? '0 : register[rfif.rsel1];
    assign rfif.rdat2 = rfif.rsel2 == 0 ? '0 : register[rfif.rsel2];

endmodule