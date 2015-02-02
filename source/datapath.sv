/*
  Eric Villasenor
  evillase@gmail.com

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

// data path interface
`include "datapath_cache_if.vh"

// alu op, mips op, and instruction type
`include "cpu_types_pkg.vh"

// other interfaces
`include "register_file_if.vh"
`include "pc_if.vh"
`include "control_unit_if.vh"
`include "alu_if.vh"
`include "request_unit_if.vh"
`include "sign_extender_if.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;

  // interfaces
  register_file_if  rfif();
  pc_if             pcif();
  control_unit_if   cuif();
  alu_if            aluif();
  request_unit_if   ruif();
  sign_extender_if  seif();

  register_file RF (CLK, nRST, rfif);
  pc PC (CLK, nRST, pcif);
  control_unit CU (cuif);
  request_unit RU (CLK, nRST, ruif);

  word_t shift_left;
  word_t pc, pc_add_4, pc_src_out, pc_shift;
  word_t Jump_out;
  logic [2:0] JAL_in;

  assign dpif.halt = 0;

  // control unit
  assign cuif.opcode = opcode_t'(dpif.imemload[31:26]);
  assign cuif.funct = funct_t'(dpif.imemload[5:0]);

  // request unit
  assign ruif.dhit = dpif.dhit;
  assign ruif.ihit = dpif.ihit;
  assign ruif.iREN = cuif.iREN;
  assign ruif.dWEN = cuif.dWEN;
  assign ruif.dREN = cuif.dREN;
  assign dpif.imemREN = ruif.imemREN;
  assign dpif.dmemREN = ruif.dmemREN;
  assign dpif.dmemWEN = ruif.dmemWEN;
  // register file
  assign rfif.rsel1 = dpif.imemload[25:21];
  assign rfif.rsel2 = dpif.imemload[20:16];
  assign rfif.WEN = cuif.RegWrite;
  assign dpif.dmemstore = rfif.rdat2;

  always_comb begin
    if (cuif.RegDst)
      rfif.wsel = dpif.imemload[15:11];
    else
      rfif.wsel = dpif.imemload[20:16];
  end

  // ALU
  assign aluif.port_a = rfif.rdat1;
  assign dpif.dmemaddr = aluif.port_o;

  always_comb begin
    if (cuif.ALUSrc)
      aluif.port_b = seif.data_out;
    else
      aluif.port_b = rfif.rdat2;
  end

  // shamt mux
  always_comb begin
    if (cuif.shamt)
      seif.data_in = dpif.imemload[10:6];
    else
      seif.data_in = dpif.imemload[15:0];
  end
  
  // adder and PC
  assign pcif.PC_WEN = cuif.PC_WEN;
  assign shift_left = seif.data_out << 2;
  assign pc = pcif.pc_output;

  adder pc_4 (
    .data_in1 (pc),
    .data_in2 (32'd4),
    .data_out (pc_add_4)
  );

  adder PCshift (
    .data_in1 (pc_add_4),
    .data_in2 (shift_left),
    .data_out (pc_shift)
  );

  // PCSrc mux
  always_comb begin                       // is this correct?
    if (cuif.PCSrc)
      pc_src_out = pc_add_4;
    else
      pc_src_out = pc_shift;
  end

  // Jump mux
  always_comb begin
    if (cuif.Jump == 0)
      pcif.pc_input = pc_src_out;
    else if (cuif.Jump == 1)
      pcif.pc_input = rfif.rdat2;
    else
      pcif.pc_input = {pc_add_4[31:28],dpif.imemload[25:0],2'b00}; 
  end

  // MemtoReg mux
  always_comb begin
    if (cuif.MemToReg)
      JAL_in = dpif.dmemload;             // double check the signal
    else
      JAL_in = aluif.port_o;
  end
  
  // Jal mux
  always_comb begin
    if (cuif.Jal == 0)
      rfif.wdat = Jump_out;         // jump_out
    else if (cuif.Jal == 1)
      rfif.wdat = JAL_in;
    else
      rfif.wdat = seif.data_out << 16;
  end

endmodule
