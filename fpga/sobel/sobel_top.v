`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/02 11:19:45
// Design Name: 
// Module Name: sobel_top
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


module sobel_top(
	input			clk													,
	input			resetn												,
	input			ov_mem_controller_frame_end_buffer_controller		,
	output	[16:0]	buffer_controller_raddr_frame_buffer				,
	input	[7:0]	frame_buffer_wdata_line_buffer						,
	input	[16:0]	frame_reader_raddr_sobel_frame_buffer				,
	output			sobel_frame_buffer_wdata_frame_reader				 
);
	wire			buffer_controller_we_line_buffer					;
	wire	[8:0]	buffer_controller_waddr_line_buffer					;
	wire	[8:0]	buffer_controller_raddr_line_buffer					;
	wire	[1:0]	buffer_controller_line_sel_line_buffer				;
	wire			buffer_controller_we_sobel_frame_buffer				;
	wire	[1:0]	buffer_controller_sobel_swap_sobel					;
	wire	[16:0]	buffer_controller_waddr_sobel_frame_buffer			;

	wire	[7:0]	line_buffer_line_data0_sobel						;
	wire	[7:0]	line_buffer_line_data1_sobel						;
	wire	[7:0]	line_buffer_line_data2_sobel						;

	wire			sobel_sdata_sobel_frame_buffer						;

	buffer_controller U_BC(
		.clk												(clk												),
		.resetn												(resetn												),
		.ov_mem_controller_frame_end_buffer_controller		(ov_mem_controller_frame_end_buffer_controller		),
		.buffer_controller_raddr_frame_buffer				(buffer_controller_raddr_frame_buffer				),
		.buffer_controller_we_line_buffer					(buffer_controller_we_line_buffer					),
		.buffer_controller_waddr_line_buffer				(buffer_controller_waddr_line_buffer				),
		.buffer_controller_raddr_line_buffer				(buffer_controller_raddr_line_buffer				),
		.buffer_controller_line_sel_line_buffer				(buffer_controller_line_sel_line_buffer				),
		.buffer_controller_we_sobel_frame_buffer			(buffer_controller_we_sobel_frame_buffer			),
		.buffer_controller_sobel_swap_sobel					(buffer_controller_sobel_swap_sobel					),
		.buffer_controller_waddr_sobel_frame_buffer			(buffer_controller_waddr_sobel_frame_buffer			) 
	);

	line_buffer U_LB(
		.clk												(clk												),
		.buffer_controller_line_sel_line_buffer				(buffer_controller_line_sel_line_buffer				),
		.buffer_controller_we_line_buffer					(buffer_controller_we_line_buffer					),
		.buffer_controller_waddr_line_buffer				(buffer_controller_waddr_line_buffer				),
		.frame_buffer_wdata_line_buffer						(frame_buffer_wdata_line_buffer						),
		.buffer_controller_raddr_line_buffer				(buffer_controller_raddr_line_buffer				),
		.line_buffer_line_data0_sobel						(line_buffer_line_data0_sobel						),
		.line_buffer_line_data1_sobel						(line_buffer_line_data1_sobel						),
		.line_buffer_line_data2_sobel						(line_buffer_line_data2_sobel						) 
	);

	sobel_filter U_SF(
		.clk												(clk												),
		.resetn												(resetn												),
		.line_buffer_line_data0_sobel						(line_buffer_line_data0_sobel						),
		.line_buffer_line_data1_sobel						(line_buffer_line_data1_sobel						),
		.line_buffer_line_data2_sobel						(line_buffer_line_data2_sobel						),
		.buffer_controller_swap_sobel						(buffer_controller_sobel_swap_sobel					),
		.sobel_sdata_sobel_frame_buffer						(sobel_sdata_sobel_frame_buffer						) 
	);

	sobel_frame_buffer U_SFB(
		.clk												(clk												),
		.buffer_controller_we_sobel_frame_buffer			(buffer_controller_we_sobel_frame_buffer			),
		.sobel_sdata_sobel_frame_buffer						(sobel_sdata_sobel_frame_buffer						),
		.buffer_controller_waddr_sobel_frame_buffer			(buffer_controller_waddr_sobel_frame_buffer			),
		.frame_reader_raddr_sobel_frame_buffer				(frame_reader_raddr_sobel_frame_buffer				),
		.sobel_frame_buffer_wdata_frame_reader				(sobel_frame_buffer_wdata_frame_reader				) 
	);
endmodule
