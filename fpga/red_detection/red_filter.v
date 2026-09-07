`timescale 1ns / 1ps

module red_filter #(
    parameter integer AW = 17
) (
    input  wire [AW-1:0] ov_mem_controller_wAddr_red_filter,
    input  wire [15:0] ov_mem_controller_wData_red_filter,
    input  wire        ov_mem_controller_we_red_filter,
    output wire [AW-1:0] red_filter_waddr_r_frame_buffer,
    output reg         red_filter_wdata_r_frame_buffer,
    output wire        red_filter_we_r_frame_buffer
);
    wire [4:0] red;
    wire [5:0] green;
    wire [4:0] blue;

    assign red = ov_mem_controller_wData_red_filter[15:11];
    assign green = ov_mem_controller_wData_red_filter[10:5];
    assign blue = ov_mem_controller_wData_red_filter[4:0];
    assign red_filter_waddr_r_frame_buffer = ov_mem_controller_wAddr_red_filter;
    assign red_filter_we_r_frame_buffer = ov_mem_controller_we_red_filter;

    always @(*) begin
        if (red >= 5'd18 && green <= 6'd24 && blue <= 5'd12) begin
            red_filter_wdata_r_frame_buffer = 1'b1;
        end else begin
            red_filter_wdata_r_frame_buffer = 1'b0;
        end
    end
endmodule
