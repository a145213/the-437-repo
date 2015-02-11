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
  pipeline_if       plif();

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

  word_t pc, pc4, npc;

  //assign dpif.halt = cuif.halt;
  always_ff @ (posedge CLK, negedge nRST)begin
    if (!nRST)
      dpif.halt <= 0;
    else if (plif.halt_wb)
      dpif.halt <= 1;
  end

  //---------------------------i am der----------------------------------

  // fetch stage
  assign plif.en_fd = dpif.ihit && !dpif.dhit;
  //assign plif.flush_fd = !dpif.ihit || dpif.dhit;
  assign plif.flush_fd = 0;
  assign plif.instr_fet = dpif.imemload;
  assign plif.pc4_fet = pc4;

  always_comb begin
    if (plif.PCSrc_mem == 0)
      npc = pc4;
    else if (plif.PCSrc_mem == 1)
      npc = plif.baddr_mem;
    else if (plif.PCSrc_mem == 2)
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

  // decode stage
  assign plif.en_de = dpif.ihit && !dpif.dhit;
  //assign plif.flush_de = !dpif.ihit && !dpif.dhit;
  assign plif.flush_de = 0;
  r_t rtype;
  i_t itype;
  j_t jtype;
  assign rtype = plif.instr_dec;
  assign itype = plif.instr_dec;
  assign jtype = plif.instr_dec;
  assign rfif.rsel1 = rtype.rs;
  assign rfif.rsel2 = rtype.rt;
  assign rfif.WEN = plif.RegWrite_wb;
  assign seif.ExtOp = cuif.ExtOp;
  assign cuif.funct = rtype.funct;
  assign cuif.opcode = rtype.opcode;

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
  assign plif.alu_op_dec = cuif.alu_op;


  // execute stage
  assign plif.en_em = dpif.ihit && !dpif.dhit;
  //assign plif.flush_em = !dpif.ihit && !dpif.dhit;
  assign plif.flush_em = !dpif.ihit || dpif.dhit;
  //assign plif.flush_em = 0;
  assign aluif.alu_op = plif.alu_op_ex;
  assign aluif.port_a = plif.rdat1_ex;
  assign plif.port_o_ex = aluif.port_o;
  assign plif.overflow_ex = aluif.overflow;
  assign plif.zero_ex = aluif.zero;
  assign plif.lui_ex = {plif.sign_ext_ex,16'h0000};
  assign plif.jaddr_ex = {plif.pc4_ex[WORD_W-1:WORD_W-4],(plif.jaddr_ex << 2)};
  assign plif.baddr_ex = (plif.lui_ex << 2) + plif.pc4_ex;

  always_comb begin
    if (plif.ALUSrc_ex == 0)
      aluif.port_b = plif.rdat2_ex;
    else if (plif.ALUSrc_ex == 1)
      aluif.port_b = plif.sign_ext_ex;
    else
      aluif.port_b = {27'h0000000,rtype.shamt};
  end

  always_comb begin
    if (plif.RegDst_ex == 0)
      plif.regWSEL_ex = plif.rd_ex;
    else if (plif.RegDst_ex == 1)
      plif.regWSEL_ex = plif.rt_ex;
    else
      plif.regWSEL_ex = 32'd31;
  end

  // memory stage
  assign plif.en_mw = dpif.ihit || dpif.dhit;
  //assign plif.flush_mw = !dpif.ihit || dpif.dhit;
  assign plif.flush_mw = 0;
  assign dpif.dmemstore = plif.rdat2_mem;
  assign dpif.dmemaddr = plif.port_o_mem; // This is a dumb fix...why does it need to come from the execute stage???
  assign rfif.wsel = plif.regWSEL_wb;
  assign plif.dmemload_mem = dpif.dmemload;

  // write back stage
  always_comb begin
    if (plif.MemToReg_wb == 0)
      rfif.wdat = plif.dmemload_wb;
    else if (plif.MemToReg_wb == 1)
      rfif.wdat = plif.port_o_wb;
    else if (plif.MemToReg_wb == 2)
      rfif.wdat = plif.pc4_wb;
    else
      rfif.wdat = plif.lui_wb;
  end

  //--------------------------i am the der--------------------------------
  
  // control unit
  //assign cuif.opcode = opcode_t'(dpif.imemload[31:26]);
  //assign cuif.funct = funct_t'(dpif.imemload[5:0]);
  //assign cuif.alu_zero = aluif.zero;
  
  // request unit
  //assign ruif.dhit = dpif.dhit;
  //assign ruif.ihit = dpif.ihit;
  //assign cuif.iREN = 1;
  //assign ruif.iREN = cuif.iREN || dpif.ihit;
  //assign ruif.dWEN = plif.dWEN_mem;
  //assign ruif.dREN = plif.dREN_mem;
  
  assign pcif.PC_WEN = dpif.ihit & !dpif.dhit;
  always_comb begin
    /*
    if (dpif.ihit) begin
      dpif.dmemREN = plif.dREN_mem;
      dpif.dmemWEN = plif.dWEN_mem;
    end
    else if (dpif.dhit) begin
      dpif.dmemREN = 0;
      dpif.dmemWEN = 0;
    end
    */
    //dpif.dmemREN = plif.dREN_mem & !dpif.dhit;
    //dpif.dmemWEN = plif.dWEN_mem & !dpif.dhit;

    dpif.dmemREN = plif.dREN_mem;
    dpif.dmemWEN = plif.dWEN_mem;
  end
  
  //assign dpif.dmemREN = ruif.dmemREN;
  //assign dpif.dmemWEN = ruif.dmemWEN;
  assign dpif.imemaddr = pc;
  assign dpif.imemREN = 1;

  // register file
  //assign rfif.rsel1 = dpif.imemload[25:21];
  //assign rfif.rsel2 = dpif.imemload[20:16];
  //assign rfif.WEN = cuif.RegWrite;
  //assign dpif.dmemstore = rfif.rdat2;

  // ALU
  //assign aluif.alu_op = cuif.alu_op;
  //assign aluif.port_a = rfif.rdat1;
  //assign dpif.dmemaddr = aluif.port_o;



  /*// shamt mux
  always_comb begin
    if (cuif.shamt)
      seif.data_in = dpif.imemload[10:6];
    else
      seif.data_in = dpif.imemload[15:0];
  end*/
  
  /*// Jump mux
  always_comb begin
    if (cuif.Jump == 0)
      pcif.pc_input = pc_src_out;
    else if (cuif.Jump == 1)
      pcif.pc_input = aluif.port_o;
    else
      pcif.pc_input = {pc_add_4[31:28],dpif.imemload[25:0],2'b00}; 
  end
  
  // Jal mux
  always_comb begin
    if (cuif.Jal == 0)
      rfif.wdat = pcif.pc_output + 4;         // jump_out
    else if (cuif.Jal == 1)
      rfif.wdat = JAL_in;
    else
      rfif.wdat = seif.data_out << 16;
  end*/

endmodule