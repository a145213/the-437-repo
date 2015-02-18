`ifndef HAZARD_UNIT_IF_VH
`define HAZARD_UNIT_IF_VH
// all types
`include "cpu_types_pkg.vh"

interface hazard_unit_if;
    // import types
    import cpu_types_pkg::*;

    // Inputs
    //word_t instr_fetch, instr_decode;
    regbits_t rs, rt;
    regbits_t ex_wsel, mem_wsel;
    logic alu_zero;
    logic ihit, dhit;

    // Outputs
    logic PC_WEN;
    pipe_state_t fd_state, de_state, em_state, mw_state;
    
 
// Hazard Unit ports
modport hu (
        input alu_zero, ihit, dhit, rs, rt, ex_wsel, mem_wsel,
        output fd_state, de_state, em_state, mw_state, PC_WEN
);

// Hazard Unit TB
modport tb (
        output alu_zero, ihit, dhit, rs, rt, ex_wsel, mem_wsel,
        input fd_state, de_state, em_state, mw_state, PC_WEN
);

endinterface
`endif // HAZARD_UNIT_IF_VH