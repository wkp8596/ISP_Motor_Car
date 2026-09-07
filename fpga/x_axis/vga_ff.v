`timescale 1ns / 1ps

module vga_ff(
    input clk,
    input rst_n,

    input        vga_decoder_vsync_vga_ff,
    input        vga_decoder_hsync_vga_ff,
    input [11:0] vga_decoder_data_vga_ff,

    output reg        vga_ff_vsync_monitor,
    output reg        vga_ff_hsync_monitor,
    output reg [11:0] vga_ff_data_monitor
);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            vga_ff_vsync_monitor <= 1'b0;
            vga_ff_hsync_monitor <= 1'b0;
            vga_ff_data_monitor <= 12'd0;
        end else begin
            vga_ff_vsync_monitor <= vga_decoder_vsync_vga_ff;
            vga_ff_hsync_monitor <= vga_decoder_hsync_vga_ff;
            vga_ff_data_monitor <= vga_decoder_data_vga_ff;
        end
        
    end

endmodule