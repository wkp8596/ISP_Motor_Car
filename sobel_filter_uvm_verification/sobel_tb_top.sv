`timescale 1ns/1ps

module sobel_tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import sobel_pkg::*;

    //--------------------------------------------------------------------
    // Clock
    //--------------------------------------------------------------------
    bit clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;   // 100MHz (10ns period)

    //--------------------------------------------------------------------
    // Interface
    //--------------------------------------------------------------------
    sobel_if intf (.clk(clk));

    //--------------------------------------------------------------------
    // DUT : sobel_filter (THRESHOLD default = 95)
    //--------------------------------------------------------------------
    sobel_filter #(
        .THRESHOLD (95)
    ) u_dut (
        .clk                              (clk),
        .resetn                           (intf.resetn),
        .line_buffer_line_data0_sobel     (intf.line_data0),
        .line_buffer_line_data1_sobel     (intf.line_data1),
        .line_buffer_line_data2_sobel     (intf.line_data2),
        .buffer_controller_swap_sobel     (intf.swap),
        .sobel_sdata_sobel_frame_buffer   (intf.sdata)
    );

    //--------------------------------------------------------------------
    // Wave dump
    //--------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("sobel_tb.fsdb");
        $fsdbDumpvars(0, sobel_tb_top, "+all");
    end

    //--------------------------------------------------------------------
    // UVM config_db + run_test
    //--------------------------------------------------------------------
    initial begin
        uvm_config_db#(virtual sobel_if.DRIVER)::set(
            null, "uvm_test_top.env.agent.driver", "vif", intf);
        uvm_config_db#(virtual sobel_if.MONITOR)::set(
            null, "uvm_test_top.env.agent.monitor", "vif", intf);

        run_test();
    end

endmodule
