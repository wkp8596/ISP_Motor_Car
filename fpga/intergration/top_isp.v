`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/02 15:41:52
// Design Name: 
// Module Name: top_isp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_isp(
	input			clk													,
	input			resetn												,
    output        	dp_uart_tx_cu_uart									,
    output        	vga_ff_hsync_monitor								,
    output        	vga_ff_vsync_monitor								,
    output [11:0] 	vga_ff_data_monitor									,
    input 			button_i_btn_sccb									,
    output			sccb_scl_ov7670										,
    inout 			sccb_sda_ov7670										,
    input 			ov7670_pclk_ov_mem_controller						,
    input 			ov7670_cam_href_ov_mem_controller					,
    input 			ov7670_cam_vsync_ov_mem_controller					,
    input [7:0]		ov7670_cam_data_ov_mem_controller					,
    output 			ov_mem_controller_xclk_ov7670						,

	output			led_red												 

);
	wire 		ov_mem_controller_frame_end_buffer_controller		;
	wire [16:0]	buffer_controller_raddr_frame_buffer				;
	wire [7:0]	frame_buffer_wdata_line_buffer						;
	wire [16:0]	frame_reader_raddr_sobel_frame_buffer				;
	wire 		sobel_frame_buffer_wdata_frame_reader				;
	wire		x_axis_decoder_start_dp_uart						;
	wire [7:0]	x_axis_decoder_tx_data_dp_uart						;

	wire  			uart_busy_arbiter				;
	wire  			x_decoder_start_arbiter			;
	wire	[7:0]	x_decoder_data_arbiter			;
	wire  			red_decoder_start_arbiter		;
	wire	[7:0]	red_decoder_data_arbiter		;
	wire			arbiter_busy_red_decoder		;
	wire			arbiter_start_uart				;
	wire	[7:0]	arbiter_data_uart				;

	wire	[16:0]	sccb_wAddr_red_filter			;
	wire	[15:0]	sccb_wData_red_filter			;
	wire			sccb_we_red_filter				;

	assign led_red = &red_decoder_data_arbiter;

	sccb_top U_SCCB_TOP (
		.clk											(clk											),
		.resetn											(resetn											),
		.button_i_btn_sccb								(button_i_btn_sccb								),
		.sccb_scl_ov7670								(sccb_scl_ov7670								),
		.sccb_sda_ov7670								(sccb_sda_ov7670								),
		.ov7670_pclk_ov_mem_controller					(ov7670_pclk_ov_mem_controller					),
		.ov7670_cam_href_ov_mem_controller				(ov7670_cam_href_ov_mem_controller				),
		.ov7670_cam_vsync_ov_mem_controller				(ov7670_cam_vsync_ov_mem_controller				),
		.ov7670_cam_data_ov_mem_controller				(ov7670_cam_data_ov_mem_controller				),
		.ov_mem_controller_frame_end_buffer_controller	(ov_mem_controller_frame_end_buffer_controller	),
		.ov_mem_controller_xclk_ov7670					(ov_mem_controller_xclk_ov7670					),
		.buffer_controller_rAddr_frame_buffer			(buffer_controller_raddr_frame_buffer			),
		.frame_buffer_wData_line_buffer					(frame_buffer_wdata_line_buffer					),
		.sccb_wAddr_red_filter							(sccb_wAddr_red_filter							),
		.sccb_wData_red_filter							(sccb_wData_red_filter							),
		.sccb_we_red_filter								(sccb_we_red_filter								) 
	);

	sobel_top U_SOBEL_TOP(
		.clk												(clk											),
		.resetn												(resetn											),
		.ov_mem_controller_frame_end_buffer_controller		(ov_mem_controller_frame_end_buffer_controller	),
		.buffer_controller_raddr_frame_buffer				(buffer_controller_raddr_frame_buffer			),
		.frame_buffer_wdata_line_buffer						(frame_buffer_wdata_line_buffer					),
		.frame_reader_raddr_sobel_frame_buffer				(frame_reader_raddr_sobel_frame_buffer			),
		.sobel_frame_buffer_wdata_frame_reader				(sobel_frame_buffer_wdata_frame_reader			) 
	);

	top_x_detection U_X_DETECT(
		.clk											(clk										),
		.rst_n											(resetn										),
		.sobel_frame_buffer_wdata						(sobel_frame_buffer_wdata_frame_reader		),
		.frame_reader_raddr_sobel_frame_buffer			(frame_reader_raddr_sobel_frame_buffer		),
		.vga_ff_hsync_monitor							(vga_ff_hsync_monitor						),
		.vga_ff_vsync_monitor							(vga_ff_vsync_monitor						),
		.vga_ff_data_monitor							(vga_ff_data_monitor						),
		.x_axis_decoder_start_dp_uart					(x_decoder_start_arbiter),
		.x_axis_decoder_tx_data_dp_uart					(x_decoder_data_arbiter) 
	);

	red_filter_top U_RED_FILTER_TOP(
		.clk										(clk										),
		.resetn										(resetn										),
		.ov7670_pclk_frame_buffer					(ov7670_pclk_ov_mem_controller),
		.ov_mem_controller_wAddr_red_filter			(sccb_wAddr_red_filter),
		.ov_mem_controller_wData_red_filter			(sccb_wData_red_filter),
		.ov_mem_controller_we_red_filter			(sccb_we_red_filter),
		.ov_mem_controller_frame_end_red_controller	(ov_mem_controller_frame_end_buffer_controller),
		.red_decoder_tx_busy_uart_arbiter			(arbiter_busy_red_decoder),
		.red_decoder_start_uart_arbiter				(red_decoder_start_arbiter),
		.red_decoder_tx_data_uart_arbiter			(red_decoder_data_arbiter) 
);

	uart_arbiter U_ARBITER(
		.uart_busy_arbiter				(uart_busy_arbiter				),
		.x_decoder_start_arbiter		(x_decoder_start_arbiter		),
		.x_decoder_data_arbiter			(x_decoder_data_arbiter			),
		.red_decoder_start_arbiter		(red_decoder_start_arbiter		),
		.red_decoder_data_arbiter		(red_decoder_data_arbiter		),
		.arbiter_busy_red_decoder		(arbiter_busy_red_decoder		),
		.arbiter_start_uart				(arbiter_start_uart				),
		.arbiter_data_uart				(arbiter_data_uart				) 
	);

	dp_uart U_DP_UART(
    	.clk(clk),
    	.rst_n(resetn),
    	.x_axis_decoder_start_dp_uart(arbiter_start_uart),
    	.x_axis_decoder_tx_data_dp_uart(arbiter_data_uart),
    	.dp_uart_tx_cu_uart(dp_uart_tx_cu_uart),
		.busy				(uart_busy_arbiter)
	);
endmodule
