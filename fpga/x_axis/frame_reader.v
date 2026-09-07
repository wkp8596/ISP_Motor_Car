`timescale 1ns / 1ps

module frame_reader(


    input sobel_frame_buffer_wdata_frame_reader,
    input [9:0] vga_decoder_x_axis_frame_reader,
    input [9:0] vga_decoder_y_axis_frame_reader,
    input vga_decoder_de_frame_reader,

    output [11:0] frame_reader_data_vga_ff,
    output [9:0] frame_reader_x_axis_x_axis_decoder,
    output [9:0] frame_reader_y_axis_x_axis_decoder,
    output [16:0] frame_reader_raddr_sobel_frame_buffer

);

wire [9:0] frame_x;
wire [9:0] frame_y;
wire display_area;

assign frame_x = vga_decoder_x_axis_frame_reader >> 1;
assign frame_y = vga_decoder_y_axis_frame_reader >> 1;

assign frame_reader_x_axis_x_axis_decoder = frame_x;
assign frame_reader_y_axis_x_axis_decoder = frame_y;

assign display_area =  vga_decoder_de_frame_reader && (frame_x < 320) && (frame_y < 240);

assign frame_reader_raddr_sobel_frame_buffer = display_area ? (frame_y * 320 + frame_x) : 17'd0;

assign frame_reader_data_vga_ff = display_area ? (sobel_frame_buffer_wdata_frame_reader ? 12'hFFF : 12'h000) : 12'h000;

endmodule
