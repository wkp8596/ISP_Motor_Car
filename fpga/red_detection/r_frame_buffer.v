`timescale 1ns / 1ps

module r_frame_buffer #(
    parameter integer IMG_W = 320,
    parameter integer IMG_H = 240,
    parameter integer AW = $clog2(IMG_W * IMG_H + 6)  // ADDR WIDTH
) (
    input wire clk,
    input wire resetn,
    input wire ov7670_pclk_frame_buffer,

    //write
    input wire [AW-1:0] red_filter_waddr_r_frame_buffer,
    input wire          red_filter_wdata_r_frame_buffer,
    input wire          red_filter_we_r_frame_buffer,

    //read
    input  wire [AW-1:0] red_controller_raddr_r_frame_buffer,
    output reg           r_frame_buffer_rdata_line_buffer_1bit
);
    reg mem[0:IMG_W*IMG_H-1];

    reg sync_pclk;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            sync_pclk <= 0;
        end else begin
            sync_pclk <= ov7670_pclk_frame_buffer;
        end
    end

    //write
    always @(posedge sync_pclk) begin
        if (red_filter_we_r_frame_buffer) begin
            mem[red_filter_waddr_r_frame_buffer] <= red_filter_wdata_r_frame_buffer;
        end
    end

    //read
    always @(posedge clk) begin
        r_frame_buffer_rdata_line_buffer_1bit <= mem[red_controller_raddr_r_frame_buffer];
    end
endmodule
