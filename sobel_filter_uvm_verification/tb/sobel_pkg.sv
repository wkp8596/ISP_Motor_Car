`ifndef SOBEL_PKG_SV
`define SOBEL_PKG_SV

package sobel_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "sobel_seq_item.sv"
    `include "sobel_sequencer.sv"
    `include "sobel_driver.sv"
    `include "sobel_monitor.sv"
    `include "sobel_agent.sv"
    `include "sobel_coverage.sv"

    `include "sobel_module_seq.sv"
    `include "sobel_module_scoreboard.sv"
    `include "sobel_module_env.sv"
    `include "sobel_module_test.sv"

endpackage

`endif