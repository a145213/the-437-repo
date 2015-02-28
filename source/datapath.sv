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
`include "pipeline_if.vh"
`include "hazard_unit_if.vh"
`include "forwarding_unit_if.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);
  // import types
  import cpu_types_pkg::*;

  // PC Init
  parameter PC_INIT = 0;

  //
  // Interfaces
  //
  register_file_if    rfif();
  pc_if               pcif();
  control_unit_if     cuif();
  alu_if              aluif();
  request_unit_if     ruif();
  sign_extender_if    seif();
  pipeline_if         plif();
  hazard_unit_if      huif();
  //forwarding_unit_if  huif();

  register_file RF (CLK, nRST, rfif);
  pc PC (CLK, nRST, pcif);
  control_unit CU (cuif);
  request_unit RU (CLK, nRST, ruif);
  sign_extender SE(seif);
  alu ALU (aluif);
  pipeline_memory_WB MW (CLK, nRST, plif);
  pipeline_decode_execute DE (CLK, nRST, plif);
  pipeline_execute_memory EM (CLK, nRST, plif);
  pipeline_fetch_decode FD (CLK, nRST, plif);
  hazard_unit HU (huif);
  //forwarding_unit FU (huif);

  //
  // Variables for datapath
  //
  word_t pc, pc4, npc;
  r_t rtype;
  i_t itype;
  j_t jtype;
  word_t pre_port_b;
  word_t reg_wdat;

  // "ex_wsel" is an internal signal used to connect to
  // the hazard unit for hazard detection within 
  // the execute stage
  regbits_t ex_wsel;


  //
  // Hazard Unit
  //
  assign huif.dhit = dpif.dhit;
  assign huif.ihit = dpif.ihit;
  assign huif.alu_zero = plif.zero_mem;
  assign huif.check_zero = plif.check_zero_mem;
  assign huif.rs = rtype.rs;
  assign huif.rt = rtype.rt;
  //assign huif.ex_wsel = ex_wsel;
  //assign huif.ex_wsel = regbits_t'{5'b00000};
  //assign huif.mem_wsel = plif.regWSEL_mem;
  //assign huif.mem_wsel = regbits_t'{5'b00000};
  assign huif.PCSrc = plif.PCSrc_mem;
  assign huif.dWEN = plif.dWEN_mem;
  assign huif.dREN = plif.dREN_mem;

  //
  // Forwarding Unit
  //
  assign huif.rs_ex = plif.rs_ex;
  assign huif.rt_ex = plif.rt_ex;
  assign huif.rs_mem = plif.rs_mem;
  assign huif.rt_mem = plif.rt_mem;
  assign huif.ex_wsel = ex_wsel;
  //assign huif.ex_wsel = regbits_t'{5'b00000};
  assign huif.mem_wsel = plif.regWSEL_mem;
  assign huif.wb_wsel = plif.regWSEL_wb;

  //
  // Halt latch
  // - is this needed in a pipelined design?
  //
  always_ff @ (posedge CLK, negedge nRST)begin
    if (!nRST)
      dpif.halt <= 0;
    else if (plif.halt_wb)
      dpif.halt <= 1;
  end



  //
  // ################################################
  // ################ BEGIN PIPELINE ################
  // ################################################
  //

  //
  // Fetch Logic + PC
  //
  always_comb begin
    if (huif.PCSrc_check == 0)
      npc = pc4;
    else if (huif.PCSrc_check == 1)
      npc = plif.baddr_mem;
    else if (huif.PCSrc_check == 2)
      npc = plif.jaddr_mem;
    else
      npc = plif.rdat1_mem;
  end

  assign pcif.pc_input = npc;
  assign pc = pcif.pc_output;

  adder pc_4 (
    .data_in1 (pc),
    .data_in2 (32'd4),
    .data_out (pc4)
  );

  assign pcif.PC_WEN = huif.PC_WEN;
  assign dpif.imemaddr = pc;
  assign dpif.imemREN = 1;


  //
  // Fetch-Decode Latch
  //
  assign plif.fd_state = huif.fd_state;
  assign plif.instr_fet = dpif.imemload;
  assign plif.pc4_fet = pc4;


  //
  // Decode Logic
  //
  assign rtype = plif.instr_dec;
  assign itype = plif.instr_dec;
  assign jtype = plif.instr_dec;
  assign rfif.rsel1 = rtype.rs;
  assign rfif.rsel2 = rtype.rt;
  assign rfif.WEN = plif.RegWrite_wb;
  assign seif.ExtOp = cuif.ExtOp;
  assign cuif.funct = rtype.funct;
  assign cuif.opcode = rtype.opcode;

  //
  // Decode-Execute Latch
  //
  assign plif.de_state = huif.de_state;
  assign plif.RegDst_dec = cuif.RegDst;
  assign plif.ALUSrc_dec = cuif.ALUSrc;
  assign plif.PCSrc_dec = cuif.PCSrc;
  assign plif.MemToReg_dec = cuif.MemToReg;
  assign plif.dREN_dec = cuif.dREN;
  assign plif.dWEN_dec = cuif.dWEN;
  assign plif.RegWrite_dec = cuif.RegWrite;
  assign plif.halt_dec = cuif.halt;
  assign plif.rdat1_dec = rfif.rdat1;
  assign plif.rdat2_dec = rfif.rdat2;
  assign plif.sign_ext_dec = seif.data_out;
  assign seif.data_in = itype.imm;
  assign plif.taddr_dec = jtype.addr;
  assign plif.rd_dec = rtype.rd;
  assign plif.rt_dec = rtype.rt;
  assign plif.rs_dec = rtype.rs;
  assign plif.alu_op_dec = cuif.alu_op;
  assign plif.check_zero_dec = cuif.check_zero;
  assign plif.check_overflow_dec = cuif.check_overflow;

  //
  // Execute Logic
  //
  assign aluif.alu_op = plif.alu_op_ex;
  //assign aluif.port_a = plif.rdat1_ex;

  always_comb begin
    if (plif.ALUSrc_ex == 0)
      aluif.port_b = pre_port_b;
    else if (plif.ALUSrc_ex == 1)
      aluif.port_b = plif.sign_ext_ex;
    else
      aluif.port_b = {27'h0000000,plif.shift_amt_ex};
  end

  always_comb begin
    if (plif.RegDst_ex == 0)
      ex_wsel = plif.rd_ex;
    else if (plif.RegDst_ex == 1)
      ex_wsel = plif.rt_ex;
    else
      ex_wsel = 32'd31;
  end

  // Port A Forwarding Mux
  always_comb begin
    if (huif.fsel_a == 0) begin
      aluif.port_a = plif.rdat1_ex;
    end else if(huif.fsel_a == 1) begin
      aluif.port_a = reg_wdat;
    end else begin
      aluif.port_a = (plif.MemToReg_mem == 3)?(plif.lui_mem):((plif.MemToReg_mem == 0)?(dpif.dmemload):(plif.port_o_mem));
    end
  end

  // Port B Forwarding Mux
  always_comb begin
    if (huif.fsel_b == 0) begin
      pre_port_b = plif.rdat2_ex;
    end else if(huif.fsel_b == 1) begin
      pre_port_b = reg_wdat;
    end else begin
      pre_port_b = (plif.MemToReg_mem == 3)?(plif.lui_mem):((plif.MemToReg_mem == 0)?(dpif.dmemload):(plif.port_o_mem));
    end
  end


  //
  // Execute-Memory Latch
  //
  assign plif.em_state = huif.em_state;
  assign plif.port_o_ex = aluif.port_o;
  assign plif.overflow_ex = aluif.overflow;
  assign plif.zero_ex = aluif.zero;
  assign plif.lui_ex = {plif.sign_ext_ex,16'h0000};
  assign plif.jaddr_ex = {plif.pc4_ex[WORD_W-1:WORD_W-4],(plif.sign_ext_ex << 2)};
  assign plif.baddr_ex = (plif.sign_ext_ex << 2) + plif.pc4_ex;
  assign plif.shift_amt_dec = rtype.shamt;
  assign plif.regWSEL_ex = ex_wsel;
  assign plif.memstore_ex = pre_port_b;

  //
  // Memory Logic
  //
  //assign dpif.dmemstore = plif.rdat2_mem;
  assign dpif.dmemaddr = plif.port_o_mem; 
  assign rfif.wsel = plif.regWSEL_wb;

  
  assign dpif.dmemWEN = plif.dWEN_mem;
  /*
  always_ff @(posedge CLK, negedge nRST) begin
    if (!nRST) begin
      dpif.dmemWEN <= 0;
    end else if (dpif.dhit || huif.branching || huif.jumping) begin
      dpif.dmemWEN <= 0;
    end else begin
      dpif.dmemWEN <= plif.dWEN_ex;
    end
  end
  */

  assign dpif.dmemREN = plif.dREN_mem;
  /*
  always_ff @(posedge CLK, negedge nRST) begin
    if (!nRST) begin
      dpif.dmemREN <= 0;
    end else if (dpif.dhit || huif.branching || huif.jumping) begin
      dpif.dmemREN <= 0;
    end else begin
      dpif.dmemREN <= plif.dREN_ex;
    end
  end
  */

  // Memory Store Mux
  always_comb begin
    if (huif.fsel_sw == 0) begin
      dpif.dmemstore = plif.rdat2_mem;
    end else begin
      dpif.dmemstore = plif.dmemload_wb;
    end
  end

  //
  // Memory-Write Back Logic
  //
  assign plif.mw_state = huif.mw_state;
  assign plif.dmemload_mem = dpif.dmemload;

  //
  // Write Back Logic
  //
  assign rfif.wdat = reg_wdat;
  always_comb begin
    if (plif.MemToReg_wb == 0)
      reg_wdat = plif.dmemload_wb;
    else if (plif.MemToReg_wb == 1)
      reg_wdat = plif.port_o_wb;
    else if (plif.MemToReg_wb == 2)
      reg_wdat = plif.pc4_wb;
    else
      reg_wdat = plif.lui_wb;
  end

  //
  // ################################################
  // ################# END PIPELINE #################
  // ################################################
  //

endmodule