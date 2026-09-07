`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/01 14:14:34
// Design Name: 
// Module Name: sobel_frame_buffer
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


module sobel_frame_buffer #(
	parameter	IMG_H	= 240		,
	parameter	IMG_W	= 320		,
	parameter	STRIDE	= 0			 
)(
	input			clk												,
	input			buffer_controller_we_sobel_frame_buffer			,
	input			sobel_sdata_sobel_frame_buffer					,
	input	[16:0]	buffer_controller_waddr_sobel_frame_buffer		,
	input	[16:0]	frame_reader_raddr_sobel_frame_buffer			,
	output			sobel_frame_buffer_wdata_frame_reader			 
);
	reg				sf_ram[0:(IMG_H)*(IMG_W)-1];

	wire			we		;
	wire			sdata	;
	wire	[16:0]	waddr	;
	wire	[16:0]	raddr	;
	reg				wdata	;

	assign we		= buffer_controller_we_sobel_frame_buffer;
	assign sdata	= sobel_sdata_sobel_frame_buffer;
	assign waddr	= buffer_controller_waddr_sobel_frame_buffer;
	assign raddr	= frame_reader_raddr_sobel_frame_buffer;

	assign sobel_frame_buffer_wdata_frame_reader = wdata;

	always @(posedge clk) begin
		if (we) begin
			sf_ram[waddr] <= sdata;
		end
	end

	always @(posedge clk) begin
		wdata <= sf_ram[raddr];
	end
endmodule
