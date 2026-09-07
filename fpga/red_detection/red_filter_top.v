`timescale 1ns / 1ps
module red_filter_top #(
    parameter integer BIT              = 1,
    parameter integer IMG_W            = 320,
    parameter integer IMG_H            = 240,
    parameter integer THRESHOLD        = 10,
    parameter integer MIN_RED_WIDTH_W  = 10,
    parameter integer MIN_RED_WIDTH_H  = 10,
    parameter integer VGA_X_FRAME_LOW  = 100,
    parameter integer VGA_X_FRAME_HIGH = 200,
    parameter integer VGA_Y_FRAME_LOW  = 80,
    parameter integer VGA_Y_FRAME_HIGH = 160,
    parameter integer AW               = $clog2(IMG_W * IMG_H + 6),
    parameter integer XW               = $clog2(IMG_W),
    parameter integer YW               = $clog2(IMG_H)
) (
    input wire clk,
    input wire resetn,

    // OV7670 카메라 입력
    input wire          ov7670_pclk_frame_buffer,
    input wire [AW-1:0] ov_mem_controller_wAddr_red_filter,
    input wire [  15:0] ov_mem_controller_wData_red_filter,
    input wire          ov_mem_controller_we_red_filter,
    input wire          ov_mem_controller_frame_end_red_controller,

    // UART handshake
    input  wire       red_decoder_tx_busy_uart_arbiter,
    output wire       red_decoder_start_uart_arbiter,
    output wire [7:0] red_decoder_tx_data_uart_arbiter 

    // Debug/verification output
    //output wire       noise_filter_sdata_roi
);

    // red_filter → r_frame_buffer
    wire [     AW-1:0] red_filter_waddr_r_frame_buffer;
    wire               red_filter_wdata_r_frame_buffer;
    wire               red_filter_we_r_frame_buffer;

    // red_controller → r_frame_buffer
    wire [     AW-1:0] red_controller_raddr_r_frame_buffer;

    // r_frame_buffer → line_buffer_1bit
    wire [    BIT-1:0] r_frame_buffer_rdata_line_buffer_1bit;

    // red_controller → line_buffer_1bit
    wire [        1:0] red_controller_line_sel_line_buffer;
    wire               red_controller_we_line_buffer;
    wire [     XW-1:0] red_controller_waddr_line_buffer;
    wire [     XW-1:0] red_controller_raddr_line_buffer;
    wire [        1:0] red_controller_swap_noise_filter;
    wire               red_controller_start_roi;

    // line_buffer_1bit → noise_filter
    wire [    BIT-1:0] line_buffer_line_data0_noise_filter;
    wire [    BIT-1:0] line_buffer_line_data1_noise_filter;
    wire [    BIT-1:0] line_buffer_line_data2_noise_filter;

    // roi → red_decoder
    wire               roi_valid_red_decoder;
    wire               roi_red_found_red_decoder;
    wire [(XW+YW)-1:0] roi_min_xy_red_decoder;
    wire [(XW+YW)-1:0] roi_max_xy_red_decoder;

    // red_filter
    red_filter #(
        .AW(AW)
    ) u_red_filter (
        .ov_mem_controller_wAddr_red_filter(ov_mem_controller_wAddr_red_filter),
        .ov_mem_controller_wData_red_filter(ov_mem_controller_wData_red_filter),
        .ov_mem_controller_we_red_filter(ov_mem_controller_we_red_filter),
        .red_filter_waddr_r_frame_buffer(red_filter_waddr_r_frame_buffer),
        .red_filter_wdata_r_frame_buffer(red_filter_wdata_r_frame_buffer),
        .red_filter_we_r_frame_buffer(red_filter_we_r_frame_buffer)
    );

    // r_frame_buffer
    r_frame_buffer #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .AW(AW)
    ) u_r_frame_buffer (
        .clk(clk),
        .resetn(resetn),
        .ov7670_pclk_frame_buffer(ov7670_pclk_frame_buffer),
        .red_filter_waddr_r_frame_buffer(red_filter_waddr_r_frame_buffer),
        .red_filter_wdata_r_frame_buffer(red_filter_wdata_r_frame_buffer),
        .red_filter_we_r_frame_buffer(red_filter_we_r_frame_buffer),
        .red_controller_raddr_r_frame_buffer(red_controller_raddr_r_frame_buffer),
        .r_frame_buffer_rdata_line_buffer_1bit      (r_frame_buffer_rdata_line_buffer_1bit)
    );

    // red_controller
    red_controller #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .AW(AW),
        .XW(XW)
    ) u_red_controller (
        .clk(clk),
        .resetn(resetn),
        .ov_mem_controller_frame_end_red_controller  (ov_mem_controller_frame_end_red_controller),
        .red_controller_raddr_r_frame_buffer         (red_controller_raddr_r_frame_buffer),
        .red_controller_we_line_buffer(red_controller_we_line_buffer),
        .red_controller_waddr_line_buffer(red_controller_waddr_line_buffer),
        .red_controller_raddr_line_buffer(red_controller_raddr_line_buffer),
        .red_controller_start_roi(red_controller_start_roi),
        .red_controller_line_sel_line_buffer         (red_controller_line_sel_line_buffer),
        .red_controller_swap_noise_filter(red_controller_swap_noise_filter)
    );

    // line_buffer_1bit
    line_buffer_1bit #(
        .BIT(BIT),
        .IMG_W(IMG_W),
        .XW(XW)
    ) u_line_buffer_1bit (
        .clk(clk),
        .red_controller_line_sel_line_buffer (red_controller_line_sel_line_buffer),
        .red_controller_we_line_buffer(red_controller_we_line_buffer),
        .red_controller_waddr_line_buffer(red_controller_waddr_line_buffer),
        .r_frame_buffer_rdata_line_buffer            (r_frame_buffer_rdata_line_buffer_1bit),
        .red_controller_raddr_line_buffer(red_controller_raddr_line_buffer),
        .line_buffer_line_data0_noise_filter         (line_buffer_line_data0_noise_filter),
        .line_buffer_line_data1_noise_filter         (line_buffer_line_data1_noise_filter),
        .line_buffer_line_data2_noise_filter         (line_buffer_line_data2_noise_filter)
    );

    // noise_filter
    noise_filter #(
        .BIT(BIT),
        .THRESHOLD(THRESHOLD)
    ) u_noise_filter (
        .clk(clk),
        .resetn(resetn),
        .line_buffer_line_data0_noise_filter         (line_buffer_line_data0_noise_filter),
        .line_buffer_line_data1_noise_filter         (line_buffer_line_data1_noise_filter),
        .line_buffer_line_data2_noise_filter         (line_buffer_line_data2_noise_filter),
        .red_controller_swap_noise_filter(red_controller_swap_noise_filter),
        .noise_filter_sdata_roi(noise_filter_sdata_roi)
    );



    roi #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .XW(XW),
        .YW(YW)
    ) u_roi (
        .clk                     (clk),
        .resetn                  (resetn),
        .noise_filter_sdata_roi  (noise_filter_sdata_roi),
        .red_controller_start_roi(red_controller_start_roi),

        .roi_valid_red_decoder(roi_valid_red_decoder),
        .roi_red_found_red_decoder(roi_red_found_red_decoder),

        .roi_min_xy_red_decoder(roi_min_xy_red_decoder),
        .roi_max_xy_red_decoder(roi_max_xy_red_decoder)
    );

    red_decoder #(
        .MIN_RED_WIDTH_W(MIN_RED_WIDTH_W),
        .MIN_RED_WIDTH_H(MIN_RED_WIDTH_H),
        .VGA_X_FRAME_LOW(VGA_X_FRAME_LOW),
        .VGA_X_FRAME_HIGH(VGA_X_FRAME_HIGH),
        .VGA_Y_FRAME_LOW(VGA_Y_FRAME_LOW),
        .VGA_Y_FRAME_HIGH(VGA_Y_FRAME_HIGH),
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .AW(AW),
        .XW(XW),
        .YW(YW)
    ) u_red_decoder (
        .clk   (clk),
        .resetn(resetn),

        .roi_min_xy_red_decoder(roi_min_xy_red_decoder),
        .roi_max_xy_red_decoder(roi_max_xy_red_decoder),

        .roi_valid_red_decoder(roi_valid_red_decoder),
        .roi_red_found_red_decoder(roi_red_found_red_decoder),

        .start  (red_decoder_start_uart_arbiter),
        .tx_data(red_decoder_tx_data_uart_arbiter),
        .tx_busy(red_decoder_tx_busy_uart_arbiter)
    );

endmodule
