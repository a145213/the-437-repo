`include "control_unit_if.vh"
`include "cpu_types_pkg.vh"

module control_unit
(
  control_unit_if.cu cuif
);

  import cpu_types_pkg::*;

  // R type instructions
  always_comb begin
    cuif.halt = 0;

    cuif.RegDst = 0;
    cuif.RegWrite = 0;
    cuif.ALUSrc = 0;
    cuif.MemToReg = 0;
    cuif.shamt = 0;
    cuif.Jal = 0;
    cuif.Jump = 0;
    cuif.PCSrc = 0;
    cuif.ExtOp = 0;
    cuif.dWEN = 0;
    cuif.dREN = 0;
    cuif.halt = 0;
    cuif.iREN = 0;
    cuif.alu_op = ALU_ADD;
  
    if (cuif.opcode == RTYPE) begin
      cuif.RegDst = 1;
      cuif.RegWrite = 1;
      cuif.ALUSrc = 0;
      cuif.MemToReg = 0;
      cuif.shamt = 0;
      cuif.Jal = 1;
      cuif.Jump = 0;
      cuif.PCSrc = 1;
      cuif.ExtOp = 0;
      cuif.iREN = 1;  

    casez (cuif.funct)
      ADDU: cuif.alu_op = ALU_ADD;
      ADD: begin
        cuif.alu_op = ALU_ADD;
        cuif.halt = cuif.overflow;
      end
      AND: cuif.alu_op = ALU_AND;
      JR: cuif.Jump = 1;
      NOR: cuif.alu_op = ALU_NOR;
      OR: cuif.alu_op = ALU_OR;
      SLT: cuif.alu_op = ALU_SLT;
      SLTU: cuif.alu_op = ALU_SLTU;
      SLL: begin
        cuif.alu_op = ALU_SLL;
        cuif.ALUSrc = 2;
      end
      SRL: begin
        cuif.alu_op = ALU_SRL;
        cuif.ALUSrc = 2;
      end
      SUBU: cuif.alu_op = ALU_SUB;
      SUB: begin 
        cuif.alu_op = ALU_SUB;
        cuif.halt = cuif.overflow;
      end
      XOR: cuif.alu_op = ALU_XOR;
      default: cuif.alu_op = ALU_ADD;
    endcase
 end
 else begin
  // I type instructions
    cuif.RegDst = 0;
    cuif.RegWrite = 1;
    cuif.ALUSrc = 1;
    cuif.MemToReg = 0;
    cuif.shamt = 0;
    cuif.Jal = 1;
    cuif.Jump = 0;
    cuif.PCSrc = 1;
    cuif.ExtOp = 1;
    cuif.dWEN = 0;
    cuif.dREN = 0;
    cuif.halt = 0;

  casez (cuif.opcode)
    BEQ: begin              //PCSrc Default to 1?
      cuif.alu_op = ALU_SUB;
      cuif.RegWrite = 0;
      cuif.ALUSrc = 0;
      cuif.ExtOp = 0;
      if (cuif.alu_zero == 0)
        cuif.PCSrc = 0;
      else cuif.PCSrc = 1;
    end
    BNE: begin
      cuif.alu_op = ALU_SUB;
      cuif.RegWrite = 0;
      cuif.ALUSrc = 0;
      cuif.ExtOp = 0;
      if (cuif.alu_zero != 0)
        cuif.PCSrc = 0;
      else cuif.PCSrc = 1;
    end
    ADDI: begin
      cuif.alu_op = ALU_ADD;      // set ExtOp
      cuif.halt = cuif.overflow;
      cuif.ExtOp = 0;
    end
    ADDIU: cuif.alu_op = ALU_ADD;
    SLTI: cuif.alu_op = ALU_SLT;
    SLTIU: cuif.alu_op = ALU_SLT;
    ANDI: cuif.alu_op = ALU_AND;
    ORI: begin
      cuif.alu_op = ALU_OR;
      cuif.ExtOp = 0;
    end
    XORI: begin
      cuif.alu_op = ALU_XOR;    // set zero extend
      cuif.ExtOp = 0;
    end
    LUI: begin
      cuif.alu_op = ALU_ADD;
      cuif.Jal = 2;
    end
    LW: begin
      cuif.alu_op = ALU_ADD;
      cuif.MemToReg = 1;        // load data from memory
      cuif.dREN = 1;
      cuif.iREN = 0;
    end
    SW: begin
      cuif.alu_op = ALU_ADD;
      cuif.dWEN = 1;
      cuif.iREN = 0;
      cuif.RegWrite = 0;
    end
    HALT: begin
      cuif.halt = 1;
      cuif.iREN = 0;
    end
    // J type
    J: cuif.Jump = 2;
    JAL: begin
      cuif.Jump = 2;
      cuif.Jal = 0;
    end
    default: cuif.alu_op = ALU_ADD;
  endcase
 end
end
endmodule