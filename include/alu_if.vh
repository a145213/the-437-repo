`ifndef ALU_IF_VH
`define ALU_IF_VH
`include "cpu_types_pkg.vh"

// all types
`include "cpu_types_pkg.vh"

interface alu_if;
        // import types
        import cpu_types_pkg::*;
        
        logic overflow, zero, negative;
        aluop_t alu_op;
        word_t port_a, port_b, port_o;
 
// alu file ports
modport alu (
        input alu_op, port_a, port_b,
        output port_o, negative, zero, overflow
);

// alu file tb
modport tb (
        input port_o, negative, zero, overflow,
        output alu_op, port_a, port_b
);

endinterface
`endif