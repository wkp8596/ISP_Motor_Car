`timescale 1ns / 1ps

module top_x_detection(

    input         clk,
    input         rst_n,

    // Sobel Frame Buffer Input
    input         sobel_frame_buffer_wdata,

    // Sobel Frame Buffer Address
    output [16:0] frame_reader_raddr_sobel_frame_buffer,

    // UART
	output		  x_axis_decoder_start_dp_uart,
	output [7:0]  x_axis_decoder_tx_data_dp_uart,

    // VGA Monitor
    output        vga_ff_hsync_monitor,
    output        vga_ff_vsync_monitor,
    output [11:0] vga_ff_data_monitor

);

// VGA Decoder -> Frame Reader
wire        vga_decoder_hsync_vga_ff;
wire        vga_decoder_vsync_vga_ff;
wire [9:0]  vga_decoder_x_axis_frame_reader;
wire [9:0]  vga_decoder_y_axis_frame_reader;
wire        vga_decoder_de_frame_reader;

// Frame Reader -> VGA FF
wire [11:0] frame_reader_data_vga_ff;

// Frame Reader -> X Decoder
wire [9:0] frame_reader_x_axis_x_axis_decoder;
wire [9:0] frame_reader_y_axis_x_axis_decoder;

VGA_Decoder u_VGA_Decoder(

    .clk(clk),
    .rst_n(rst_n),

    .vga_decoder_hsync_vga_ff(vga_decoder_hsync_vga_ff),
    .vga_decoder_vsync_vga_ff(vga_decoder_vsync_vga_ff),

    .vga_decoder_x_axis_frame_reader(vga_decoder_x_axis_frame_reader),
    .vga_decoder_y_axis_frame_reader(vga_decoder_y_axis_frame_reader),
    .vga_decoder_de_frame_reader(vga_decoder_de_frame_reader)

);

frame_reader u_frame_reader(

    .sobel_frame_buffer_wdata_frame_reader(sobel_frame_buffer_wdata),
    .vga_decoder_x_axis_frame_reader(vga_decoder_x_axis_frame_reader),
    .vga_decoder_y_axis_frame_reader(vga_decoder_y_axis_frame_reader),
    .vga_decoder_de_frame_reader(vga_decoder_de_frame_reader),
    .frame_reader_data_vga_ff(frame_reader_data_vga_ff),
    .frame_reader_x_axis_x_axis_decoder(frame_reader_x_axis_x_axis_decoder),
    .frame_reader_y_axis_x_axis_decoder(frame_reader_y_axis_x_axis_decoder),
    .frame_reader_raddr_sobel_frame_buffer(frame_reader_raddr_sobel_frame_buffer)

);

x_axis_decoder u_x_axis_decoder(

    .clk(clk),
    .rst_n(rst_n),

    .frame_reader_x_axis_x_axis_decoder(frame_reader_x_axis_x_axis_decoder),
    .frame_reader_y_axis_x_axis_decoder(frame_reader_y_axis_x_axis_decoder),

    .sobel_frame_buffer_wdata_x_axis_decoder(sobel_frame_buffer_wdata),

    .x_axis_decoder_start_dp_uart(x_axis_decoder_start_dp_uart),
    .x_axis_decoder_tx_data_dp_uart(x_axis_decoder_tx_data_dp_uart)

);
// DP UART


// VGA FF
vga_ff u_vga_ff(

    .clk(clk),
    .rst_n(rst_n),

    .vga_decoder_hsync_vga_ff(vga_decoder_hsync_vga_ff),
    .vga_decoder_vsync_vga_ff(vga_decoder_vsync_vga_ff),
    .vga_decoder_data_vga_ff(frame_reader_data_vga_ff),

    .vga_ff_hsync_monitor(vga_ff_hsync_monitor),
    .vga_ff_vsync_monitor(vga_ff_vsync_monitor),
    .vga_ff_data_monitor(vga_ff_data_monitor)

);

endmodule
