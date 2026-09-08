`ifndef SOBEL_IF_SV
`define SOBEL_IF_SV

interface sobel_if (input bit clk);

    logic         resetn;
    logic [7:0]   line_data0;
    logic [7:0]   line_data1;
    logic [7:0]   line_data2;
    logic [1:0]   swap;
    logic         sdata;

    logic         is_settle_point;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output line_data0;
        output line_data1;
        output line_data2;
        output swap;
        output is_settle_point;
        input  sdata;
    endclocking

    modport DRIVER  (clocking drv_cb, output resetn);
    modport MONITOR (input clk, resetn, line_data0, line_data1, line_data2, swap, sdata, is_settle_point);

endinterface

`endif 