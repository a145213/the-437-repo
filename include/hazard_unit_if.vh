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
    logic [1:0] PCSrc;
    logic alu_zero;
    logic check_zero;
    logic ihit, dhit;

    // Outputs
    logic PC_WEN;
    logic [1:0] PCSrc_check;
    pipe_state_t fd_state, de_state, em_state, mw_state;

 
// Hazard Unit ports
modport hu (
        input alu_zero, ihit, dhit, rs, rt, ex_wsel, mem_wsel, PCSrc, check_zero,
        output fd_state, de_state, em_state, mw_state, PC_WEN, PCSrc_check
);

// Hazard Unit TB
modport tb (
        output alu_zero, ihit, dhit, rs, rt, ex_wsel, mem_wsel, PCSrc, check_zero,
        input fd_state, de_state, em_state, mw_state, PC_WEN, PCSrc_check
);

endinterface
`endif // HAZARD_UNIT_IF_VH