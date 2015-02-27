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
    logic dWEN, dREN;
    regbits_t rs_ex, rt_ex, rs_mem, rt_mem;
    regbits_t wb_wsel;

    // Outputs
    logic PC_WEN;
    logic [1:0] PCSrc_check;
    pipe_state_t fd_state, de_state, em_state, mw_state;
    logic [1:0] fsel_a, fsel_b;
    logic fsel_sw;
    logic branching;
    logic jumping;

 
// Hazard Unit ports
modport hu (
        input alu_zero, ihit, dhit, rs, rt, ex_wsel, mem_wsel, PCSrc, check_zero,
        dWEN, dREN, rs_ex, rt_ex, rs_mem, rt_mem, wb_wsel,
        output fd_state, de_state, em_state, mw_state, PC_WEN, PCSrc_check,
        fsel_a, fsel_b, fsel_sw, branching, jumping
);

// Hazard Unit TB
modport tb (
        output alu_zero, ihit, dhit, rs, rt, ex_wsel, mem_wsel, PCSrc, check_zero,
        dWEN, dREN, rs_ex, rt_ex, rs_mem, rt_mem, wb_wsel,
        input fd_state, de_state, em_state, mw_state, PC_WEN, PCSrc_check,
        fsel_a, fsel_b, fsel_sw, branching, jumping
);

endinterface
`endif // HAZARD_UNIT_IF_VH