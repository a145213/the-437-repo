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
  //request_unit_if     ruif();
  sign_extender_if    seif();
  fetch_decode_if     fdif();
  decode_execute_if   deif();
  execute_mem_if      emif();
  mem_writeback_if    mwif();
  //pipeline_if         plif();
  hazard_unit_if      huif();
  //forwarding_unit_if  huif();

  register_file RF (CLK, nRST, rfif);
  pc #(.PC_INIT(PC_INIT)) PC (CLK, nRST, pcif);
  control_unit CU (cuif);
  //request_unit RU (CLK, nRST, ruif);
  sign_extender SE(seif);
  alu ALU (aluif);
  pipeline_fetch_decode FD (CLK, nRST, fdif);
  pipeline_decode_execute DE (CLK, nRST, deif);
  pipeline_execute_memory EM (CLK, nRST, emif);
  pipeline_memory_WB MW (CLK, nRST, mwif);
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
  assign huif.alu_zero = emif.m_zero;
  assign huif.check_zero = emif.m_check_zero;
  assign huif.d_rs = rtype.rs;
  assign huif.d_rt = rtype.rt;
  //assign huif.ex_wsel = ex_wsel;
  //assign huif.ex_wsel = regbits_t'{5'b00000};
  //assign huif.mem_wsel = plif.regWSEL_mem;
  //assign huif.mem_wsel = regbits_t'{5'b00000};
  assign huif.PCSrc = emif.m_PCSrc;
  assign huif.dWEN = emif.m_dWEN;
  assign huif.dREN = emif.m_dREN;
  assign huif.d_op = rtype.opcode;
  assign huif.e_op = deif.e_op;
  assign huif.m_op = emif.m_op;
  assign huif.w_op = mwif.w_op;
  assign huif.w_halt = mwif.w_halt;

  //
  // Forwarding Unit
  //
  assign huif.e_rs = deif.e_rs;
  assign huif.e_rt = deif.e_rt;
  assign huif.m_rs = emif.m_rs;
  assign huif.m_rt = emif.m_rt;
  assign huif.e_wsel = ex_wsel;
  //assign huif.ex_wsel = regbits_t'{5'b00000};
  assign huif.m_wsel = emif.m_regWSEL;
  assign huif.w_wsel = mwif.w_regWSEL;


  //
  // Halt latch
  // - is this needed in a pipelined design?
  //
  /*
  always_ff @ (posedge CLK, negedge nRST)begin
    if (!nRST)
      dpif.halt <= 0;
    else if (mwif.w_halt)
      dpif.halt <= 1;
  end
  */
  assign dpif.halt = mwif.w_halt;



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
      npc = emif.m_baddr;
    else if (huif.PCSrc_check == 2)
      npc = emif.m_jaddr;
    else
      npc = emif.m_rdat1;
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
  assign dpif.imemREN = !mwif.w_halt;


  //
  // Fetch-Decode Latch
  //
  assign fdif.fd_state = huif.fd_state;
  assign fdif.f_instr = dpif.imemload;
  assign fdif.f_pc4 = pc4;

  //
  // Decode Logic
  //
  assign seif.data_in = itype.imm;
  assign rtype = fdif.d_instr;
  assign itype = fdif.d_instr;
  assign jtype = fdif.d_instr;
  assign rfif.rsel1 = rtype.rs;
  assign rfif.rsel2 = rtype.rt;
  assign rfif.WEN = mwif.w_RegWrite;
  assign seif.ExtOp = cuif.ExtOp;
  assign cuif.funct = rtype.funct;
  assign cuif.opcode = rtype.opcode;

  //
  // Decode-Execute Latch
  //
  assign deif.de_state = huif.de_state;
  assign deif.d_RegDst = cuif.RegDst;
  assign deif.d_ALUSrc = cuif.ALUSrc;
  assign deif.d_PCSrc = cuif.PCSrc;
  assign deif.d_MemToReg = cuif.MemToReg;
  assign deif.d_dREN = cuif.dREN;
  assign deif.d_dWEN = cuif.dWEN;
  assign deif.d_RegWrite = cuif.RegWrite;
  assign deif.d_halt = cuif.halt;
  assign deif.d_rdat1 = rfif.rdat1;
  assign deif.d_rdat2 = rfif.rdat2;
  assign deif.d_sign_ext = seif.data_out;
  assign deif.d_taddr = jtype.addr;
  assign deif.d_rd = rtype.rd;
  assign deif.d_rt = rtype.rt;
  assign deif.d_rs = rtype.rs;
  assign deif.d_alu_op = cuif.alu_op;
  assign deif.d_check_zero = cuif.check_zero;
  assign deif.d_check_overflow = cuif.check_overflow;
  assign deif.d_shift_amt = rtype.shamt;
  assign deif.d_pc4 = fdif.d_pc4;
  assign deif.d_op = rtype.opcode;

  //
  // Execute Logic
  //
  assign aluif.alu_op = deif.e_alu_op;
  //assign aluif.port_a = plif.rdat1_ex;

  always_comb begin
    if (deif.e_ALUSrc == 0)
      aluif.port_b = pre_port_b;
    else if (deif.e_ALUSrc == 1)
      aluif.port_b = deif.e_sign_ext;
    else
      aluif.port_b = {27'h0000000,deif.e_shift_amt};
  end

  always_comb begin
    if (deif.e_RegDst == 0)
      ex_wsel = deif.e_rd;
    else if (deif.e_RegDst == 1)
      ex_wsel = deif.e_rt;
    else
      ex_wsel = 32'd31;
  end

  // Port A Forwarding Mux
  always_comb begin
    if (huif.fsel_a == 0) begin
      aluif.port_a = deif.e_rdat1;
    end else if(huif.fsel_a == 1) begin
      aluif.port_a = reg_wdat;
    end else begin
      aluif.port_a = (emif.m_MemToReg == 3)?(emif.m_lui):((emif.m_MemToReg == 0)?(dpif.dmemload):(emif.m_port_o));
    end
  end

  // Port B Forwarding Mux
  always_comb begin
    if (huif.fsel_b == 0) begin
      pre_port_b = deif.e_rdat2;
    end else if(huif.fsel_b == 1) begin
      pre_port_b = reg_wdat;
    end else begin
      pre_port_b = (emif.m_MemToReg == 3)?(emif.m_lui):((emif.m_MemToReg == 0)?(dpif.dmemload):(emif.m_port_o));
    end
  end


  //
  // Execute-Memory Latch
  //
  assign emif.em_state = huif.em_state;
  assign emif.e_port_o = aluif.port_o;
  assign emif.e_overflow = aluif.overflow;
  assign emif.e_zero = aluif.zero;
  assign emif.e_lui = {deif.e_sign_ext,16'h0000};
  assign emif.e_jaddr = {deif.e_pc4[WORD_W-1:WORD_W-4],(deif.e_sign_ext << 2)};
  assign emif.e_baddr = (deif.e_sign_ext << 2) + deif.e_pc4;
  assign emif.e_regWSEL = ex_wsel;
  assign emif.e_memstore = pre_port_b;
  assign emif.e_PCSrc = deif.e_PCSrc;
  assign emif.e_halt = deif.e_halt;
  assign emif.e_taddr = deif.e_taddr;
  assign emif.e_rdat1 = deif.e_rdat1;
  assign emif.e_rdat2 = deif.e_rdat2;
  assign emif.e_pc4 = deif.e_pc4;
  assign emif.e_sign_ext = deif.e_sign_ext;
  assign emif.e_rs = deif.e_rs;
  assign emif.e_rt = deif.e_rt;
  assign emif.e_rd = deif.e_rd;
  assign emif.e_MemToReg = deif.e_MemToReg;
  assign emif.e_check_zero = deif.e_check_zero;
  assign emif.e_check_overflow = deif.e_check_overflow;
  assign emif.e_dREN = deif.e_dREN;
  assign emif.e_dWEN = deif.e_dWEN;
  assign emif.e_RegWrite = deif.e_RegWrite;
  assign emif.e_op = deif.e_op;

  //
  // Memory Logic
  //
  //assign dpif.dmemstore = plif.rdat2_mem;
  assign dpif.dmemaddr = emif.m_port_o; 
  assign rfif.wsel = mwif.w_regWSEL;
  assign dpif.datomic = 1'b0;
  
  assign dpif.dmemWEN = emif.m_dWEN;
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

  assign dpif.dmemREN = emif.m_dREN;
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
      dpif.dmemstore = emif.m_rdat2;
    end else if (huif.fsel_sw == 1) begin
      // Need to figure out how this works
      // Fix for mergesort
      dpif.dmemstore = mwif.m_rdat2;
    end else begin
      dpif.dmemstore = mwif.w_dmemload;
    end
  end

  //
  // Memory-Write Back Logic
  //
  assign mwif.mw_state = huif.mw_state;
  assign mwif.m_dmemload = dpif.dmemload;
  assign mwif.m_halt = emif.m_halt;
  assign mwif.m_MemToReg = emif.m_MemToReg;
  assign mwif.m_RegWrite = emif.m_RegWrite;
  assign mwif.m_rdat1 = emif.m_rdat1;
  assign mwif.m_rdat2 = emif.m_rdat2;
  assign mwif.m_port_o = emif.m_port_o;
  assign mwif.m_regWSEL = emif.m_regWSEL;
  assign mwif.m_lui = emif.m_lui;
  assign mwif.m_pc4 = emif.m_pc4;
  assign mwif.m_op = emif.m_op;

  //
  // Write Back Logic
  //
  assign rfif.wdat = reg_wdat;
  always_comb begin
    if (mwif.w_MemToReg == 0)
      reg_wdat = mwif.w_dmemload;
    else if (mwif.w_MemToReg == 1)
      reg_wdat = mwif.w_port_o;
    else if (mwif.w_MemToReg == 2)
      reg_wdat = mwif.w_pc4;
    else
      reg_wdat = mwif.w_lui;
  end

  //
  // ################################################
  // ################# END PIPELINE #################
  // ################################################
  //

endmodule