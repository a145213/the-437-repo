`ifndef HAZARD_UNIT_IF_VH
`define HAZARD_UNIT_IF_VH
// all types
`include "cpu_types_pkg.vh"

interface hazard_unit_if;
    import cpu_types_pkg::*;

    // Inputs    
    logic alu_zero;
    logic check_zero;
    logic ihit, dhit;
    logic dWEN, dREN;
    logic w_halt;
    logic [1:0] PCSrc;
    regbits_t d_rs, e_rs, m_rs;
    regbits_t d_rt, e_rt, m_rt;
    regbits_t e_wsel, m_wsel, w_wsel;
    opcode_t d_op, e_op, m_op, w_op;

    // Outputs
    pipe_state_t fd_state, de_state, em_state, mw_state;
    logic PC_WEN;
    logic branching;
    logic jumping;
    logic fsel_sw_ex;
    logic [1:0] PCSrc_check;
    logic [1:0] fsel_a, fsel_b;
    logic [1:0] fsel_sw;

 
// Hazard Unit ports
modport hu (
        input 
                alu_zero,
                check_zero,
                ihit,
                dhit,
                dWEN,
                dREN,
                w_halt,
                PCSrc,
                d_rs, e_rs, m_rs,
                d_rt, e_rt, m_rt,
                e_wsel, m_wsel, w_wsel,
                d_op, e_op, m_op, w_op,
        output 
                fd_state, de_state, em_state, mw_state, 
                PC_WEN, 
                PCSrc_check, 
                fsel_a, 
                fsel_b, 
                fsel_sw, 
                branching, 
                jumping, 
                fsel_sw_ex
);

// Hazard Unit TB
modport tb (
        output 
                alu_zero,
                check_zero,
                ihit,
                dhit,
                dWEN,
                dREN,
                PCSrc,
                d_rs, e_rs, m_rs,
                d_rt, e_rt, m_rt,
                e_wsel, m_wsel, w_wsel,
                d_op, e_op, m_op, w_op,
        input 
                fd_state, de_state, em_state, mw_state, 
                PC_WEN, 
                PCSrc_check, 
                fsel_a, 
                fsel_b, 
                fsel_sw, 
                branching, 
                jumping, 
                fsel_sw_ex
);

endinterface
`endif // HAZARD_UNIT_IF_VH