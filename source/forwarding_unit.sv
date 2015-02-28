`include "forwarding_unit_if.vh"
`include "cpu_types_pkg.vh"

module forwarding_unit
(
  fowarding_unit_if.fu fuif
);

  import cpu_types_pkg::*;

  //
  // Variables
  //
  logic haz_rs_ex;
  logic haz_rt_ex;
  logic haz_rs_mem;
  logic haz_rt_mem;
  logic haz_rs_wb;
  logic haz_rt_wb;

  //
  // Hazard detections
  //
  assign haz_rs_ex = (fuif.rs_mem != 0) && (fuif.wb_wsel == fuif.rs_mem);
  assign haz_rt_ex = (fuif.rt_mem != 0) && (fuif.wb_wsel == fuif.rt_mem);
  assign haz_rs_mem = (fuif.rs_ex != 0) && (fuif.mem_wsel == fuif.rs_ex);
  assign haz_rt_mem = (fuif.rt_ex != 0) && (fuif.mem_wsel == fuif.rt_ex);
  assign haz_rs_wb = (fuif.rs_ex != 0) && (fuif.wb_wsel == fuif.rs_ex);
  assign haz_rt_wb = (fuif.rt_ex != 0) && (fuif.wb_wsel == fuif.rt_ex);

  //
  // ALU Port A Mux Select Logic
  //
  always_comb begin
    if (haz_rs_mem) begin
      // Forward from memory stage
      fuif.fsel_a = 2'd2;
    end else if (haz_rs_wb) begin
      // Forward from write-back stage
      fuif.fsel_a = 2'd1;
    end else begin
      // No forwarding
      fuif.fsel_a = 2'd0;
    end
  end

  //
  // ALU Port B Mux Select Logic
  //
  always_comb begin
    if (haz_rt_mem) begin
      // Forward from memory stage
      fuif.fsel_b = 2'd1;
    end else if (haz_rt_wb) begin
      // Forward from write-back stage
      fuif.fsel_b = 2'd2;
    end else begin
      // No forwarding
      fuif.fsel_b = 2'd0;
    end
  end

  //
  // Memory Store Mux Select Logic
  //
  always_comb begin
    if (haz_rt_ex) begin
      fuif.fsel_sw = 1'd1;
    end else begin
      // No forwarding
      fuif.fsel_sw = 1'd0;
    end
  end

endmodule