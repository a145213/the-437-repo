`ifndef HAZARD_UNIT_IF_VH
`define HAZARD_UNIT_IF_VH
// all types
`include "cpu_types_pkg.vh"

interface hazard_unit_if;
    // import types
    import cpu_types_pkg::*;

    // Inputs
    word_t instr;

    // Outputs
    logic PC_WEN;
    pipe_state_t fd_state, de_state, em_state, mw_state;
    
 
// Hazard Unit ports
modport hu (
        input instr,
        output fd_state, de_state, em_state, mw_state
);

// Hazard Unit TB
modport tb (
        output instr,
        input fd_state, de_state, em_state, mw_state
);

endinterface
`endif // HAZARD_UNIT_IF_VH