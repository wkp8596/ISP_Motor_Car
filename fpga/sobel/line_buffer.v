`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/01 14:13:34
// Design Name: 
// Module Name: line_buffer
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


module line_buffer(
	input			clk												,
	input	[1:0]	buffer_controller_line_sel_line_buffer			,
	input			buffer_controller_we_line_buffer				,
	input	[8:0]	buffer_controller_waddr_line_buffer				,
	input	[7:0]	frame_buffer_wdata_line_buffer					,
	input	[8:0]	buffer_controller_raddr_line_buffer				,
	output	[7:0]	line_buffer_line_data0_sobel					,
	output	[7:0]	line_buffer_line_data1_sobel					,
	output	[7:0]	line_buffer_line_data2_sobel					 
);
	reg		[7:0]	line0_ram[0:319];
	reg		[7:0]	line1_ram[0:319];
	reg		[7:0]	line2_ram[0:319];

	wire	[1:0]	sel			;
	wire			we			;
	wire	[8:0]	waddr		;
	wire	[7:0]	wdata		;
	wire	[8:0]	raddr		;

	reg		[7:0]	line_data0	;
	reg		[7:0]	line_data1	;
	reg		[7:0]	line_data2	;

	assign sel		= buffer_controller_line_sel_line_buffer	;
	assign we		= buffer_controller_we_line_buffer			;
	assign waddr	= buffer_controller_waddr_line_buffer		;
	assign wdata	= frame_buffer_wdata_line_buffer			;
	assign raddr	= buffer_controller_raddr_line_buffer		;

	assign line_buffer_line_data0_sobel	= line_data0			;
	assign line_buffer_line_data1_sobel	= line_data1			;
	assign line_buffer_line_data2_sobel	= line_data2			;

	always @(posedge clk) begin
		if (we && (sel == 2'b00)) begin
			line0_ram[waddr] <= wdata;
		end
	end

	always @(posedge clk) begin
		if (we && (sel == 2'b01)) begin
			line1_ram[waddr] <= wdata;
		end
	end

	always @(posedge clk) begin
		if (we && (sel == 2'b10)) begin
			line2_ram[waddr] <= wdata;
		end
	end

	always @(posedge clk) begin
		line_data0	<= line0_ram[raddr];
		line_data1	<= line1_ram[raddr];
		line_data2	<= line2_ram[raddr];
	end
endmodule
