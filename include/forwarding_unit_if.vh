`ifndef FORWARDING_UNIT_IF_VH
`define FORWARDING_UNIT_IF_VH
// all types
`include "cpu_types_pkg.vh"

interface forwarding_unit_if;
    // import types
    import cpu_types_pkg::*;

    // Inputs
    regbits_t rs_ex, rt_ex, rs_mem, rt_mem;
    regbits_t ex_wsel, mem_wsel, wb_wsel;

    // Outputs
    logic [1:0] fsel_a, fsel_b;
    logic fsel_sw;

 
// Forwarding Unit ports
modport fu (
        input rs_ex, rt_ex, rs_mem, rt_mem, ex_wsel, mem_wsel, wb_wsel,
        output fsel_a, fsel_b, fsel_sw
);

// Forwarding Unit TB
modport tb (
        output rs_ex, rt_ex, rs_mem, rt_mem, ex_wsel, mem_wsel, wb_wsel,
        input fsel_a, fsel_b, fsel_sw
);

endinterface
`endif // FORWARDING_UNIT_IF_VH