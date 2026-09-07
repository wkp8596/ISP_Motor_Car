`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/01 14:13:48
// Design Name: 
// Module Name: sobel_filter
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


module sobel_filter #(parameter THRESHOLD = 95)(
	input			clk										,
	input			resetn									,
	input	[7:0]	line_buffer_line_data0_sobel			,
	input	[7:0]	line_buffer_line_data1_sobel			,
	input	[7:0]	line_buffer_line_data2_sobel			,
	input	[1:0]	buffer_controller_swap_sobel			,
	output			sobel_sdata_sobel_frame_buffer			 
);
	reg		[7:0]	line0[0:2];
	reg		[7:0]	line1[0:2];
	reg		[7:0]	line2[0:2];

	wire	[7:0]	line0_input;
	wire	[7:0]	line1_input;
	wire	[7:0]	line2_input;

	wire	[11:0]	dx;
	wire	[11:0]	dy;

	reg		[11:0]	dx_r;
	reg		[11:0]	dy_r;

	wire	[13:0]	gradient;

	assign dx = - {1'b0, line0[0]} + {1'b0, line0[2]} - {1'b0, line1[0], 1'b0} + {1'b0, line1[2], 1'b0} - {1'b0, line2[0]} + {1'b0, line2[2]};
	assign dy = - {1'b0, line0[0]} + {1'b0, line2[0]} - {1'b0, line0[1], 1'b0} + {1'b0, line2[1], 1'b0} - {1'b0, line0[2]} + {1'b0, line2[2]};

	assign gradient = dx_r + dy_r;

	assign sobel_sdata_sobel_frame_buffer = (gradient > THRESHOLD) ? 1'b1 : 1'b0;

	mux_4_1_sobel U_MUX_LINE0(
		.in0(line_buffer_line_data0_sobel),
		.in1(line_buffer_line_data1_sobel),
		.in2(line_buffer_line_data2_sobel),
		.in3(8'h00),
		.sel(buffer_controller_swap_sobel),
		.out(line0_input) 
		);
		mux_4_1_sobel U_MUX_LINE1(
		.in0(line_buffer_line_data1_sobel),
		.in1(line_buffer_line_data2_sobel),
		.in2(line_buffer_line_data0_sobel),
		.in3(8'h00),
		.sel(buffer_controller_swap_sobel),
		.out(line1_input) 
		);

		mux_4_1_sobel U_MUX_LINE2(
		.in0(line_buffer_line_data2_sobel),
		.in1(line_buffer_line_data0_sobel),
		.in2(line_buffer_line_data1_sobel),
		.in3(8'h00),
		.sel(buffer_controller_swap_sobel),
		.out(line2_input) 
	);

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			dx_r <= 0;
			dy_r <= 0;
		end else begin
			dx_r <= dx[11] ? -dx : dx;
			dy_r <= dy[11] ? -dy : dy;
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			line0[2]	<= 8'h00;
			line0[1]	<= 8'h00;
			line0[0]	<= 8'h00;
			line1[2]	<= 8'h00;
			line1[1]	<= 8'h00;
			line1[0]	<= 8'h00;
			line2[2]	<= 8'h00;
			line2[1]	<= 8'h00;
			line2[0]	<= 8'h00;
		end else begin
			line0[2]	<= line0[1];
			line0[1]	<= line0[0];
			line0[0]	<= line0_input;
			line1[2]	<= line1[1];
			line1[1]	<= line1[0];
			line1[0]	<= line1_input;
			line2[2]	<= line2[1];
			line2[1]	<= line2[0];
			line2[0]	<= line2_input;
		end
	end
endmodule

module mux_4_1_sobel(
	input	[7:0]	in0,
	input	[7:0]	in1,
	input	[7:0]	in2,
	input	[7:0]	in3,
	input	[1:0]	sel,
	output	[7:0]	out 
);
	reg	[7:0]	out_r;
	assign out = out_r;
	always @(*) begin
		case (sel)
			2'b00:	out_r = in0;
			2'b01:	out_r = in1;
			2'b10:	out_r = in2;
			2'b11:	out_r = in3;
			default:out_r = 8'hxx;
		endcase
	end
endmodule
