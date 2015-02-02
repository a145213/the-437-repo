`include "control_unit_if.vh"
`include "cpu_types_pkg.vh"

module control_unit
(
  control_unit_if.cu cuif
);

  import cpu_types_pkg::*;

  // R type instructions
  always_comb begin
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
  	cuif.PC_WEN = 1;
  	cuif.iREN = 1;
  	cuif.halt = 0;

  	casez (cuif.funct)
  		ADDU: cuif.alu_op = ALU_ADD;	// check for overflow in datapath
  		ADD: begin
  			cuif.alu_op = ALU_ADD;
  			cuif.halt = cuif.overflow;
  		end
  		AND: cuif.alu_op = ALU_AND;
  		JR: cuif.Jump = 1;			// double check
  		NOR: cuif.alu_op = ALU_NOR;
  		OR: cuif.alu_op = ALU_OR;
  		SLT: cuif.alu_op = ALU_SLT;
  		SLTU: cuif.alu_op = ALU_SLTU;
  		SLL: begin
  			cuif.alu_op = ALU_SLL;
  			cuif.ALUSrc = 1;
  			cuif.shamt = 1;				// needs to set ExtOp 
  		end
  		SRL: begin
  			cuif.alu_op = ALU_SRL;
  			cuif.ALUSrc = 1;
  			cuif.shamt = 1;				// needs to set ExtOp
  		end
  		SUBU: cuif.alu_op = ALU_SUB;
  		SUB: begin 
  			cuif.alu_op = ALU_SUB;
  			cuif.halt = cuif.overflow;
  		end
  		XOR: cuif.alu_op = ALU_ADD;
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
  	cuif.PC_WEN = 1;
  	cuif.dWEN = 0;
  	cuif.dREN = 0;
  	cuif.halt = 0;

 	casez (cuif.opcode)
 		BEQ: begin							//PCSrc Default to 1?
 			cuif.alu_op = ALU_SUB;
 			cuif.RegWrite = 0;
 			cuif.ALUSrc = 0;
 			cuif.ExtOp = 0;
 			if (cuif.alu_zero == 0)
 				cuif.PCSrc = 0;
 		end
 		BNE: begin
 			cuif.alu_op = ALU_SUB;
 			cuif.RegWrite = 0;
 			cuif.ALUSrc = 0;
 			cuif.ExtOp = 0;
 			if (cuif.alu_zero != 0)
 				cuif.PCSrc = 0;
 		end
 		ADDI: begin
 			cuif.alu_op = ALU_ADD;			// set ExtOp
 			cuif.halt = cuif.overflow;
 		end
 		ADDIU: begin
 			cuif.alu_op = ALU_ADD;
 		end
 		SLTI: begin
 			cuif.alu_op = ALU_SLT;;
 		end
 		SLTIU: begin
 			cuif.alu_op = ALU_SLT;
 		end
 		ANDI: begin
 			cuif.alu_op = ALU_AND;
 		end
 		ORI: begin
 			cuif.alu_op = ALU_OR;
 		end
 		XORI: begin
 			cuif.alu_op = ALU_XOR;		// set zero extend
 		end
 		LUI: begin
 			cuif.alu_op = ALU_ADD;
 			cuif.Jal = 2;
 		end
 		LW: begin
 			cuif.alu_op = ALU_ADD;
 			cuif.MemToReg = 1;				// load data from memory
 			cuif.dREN = 1;
 		end
 		SW: begin
 			cuif.alu_op = ALU_ADD;			// not sure yet
 			cuif.dWEN = 1;
 		end
 		HALT: cuif.halt = 1;

 		// J type
 		J: cuif.Jump = 2;
 		JAL: begin
 			cuif.Jump = 2;
 			cuif.Jal = 0;					// R[31] <= npc
 		end
 	endcase
 end
end
endmodule