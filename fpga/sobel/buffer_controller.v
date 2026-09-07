`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/01 14:15:01
// Design Name: 
// Module Name: buffer_controller
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


module buffer_controller(
	input			clk													,
	input			resetn												,
	input			ov_mem_controller_frame_end_buffer_controller		,
	output	[16:0]	buffer_controller_raddr_frame_buffer				,
	output			buffer_controller_we_line_buffer					,
	output	[8:0]	buffer_controller_waddr_line_buffer					,
	output	[8:0]	buffer_controller_raddr_line_buffer					,
	output	[1:0]	buffer_controller_line_sel_line_buffer				,
	output			buffer_controller_we_sobel_frame_buffer				,
	output	[1:0]	buffer_controller_sobel_swap_sobel					,
	output	[16:0]	buffer_controller_waddr_sobel_frame_buffer			 
);
	localparam IDLE	= 1'b0;
	localparam MOVE	= 1'b1;

	reg			state, nstate	;
	reg			we_lb			;
	reg			we_sb			;
	reg	[16:0]	raddr_fb		;
	reg	[16:0]	waddr_sb		;
	reg	[8:0]	waddr_lb		;
	reg	[8:0]	raddr_lb		;
	reg	[1:0]	line_sel		;
	reg	[1:0]	sobel_swap		;
	reg	[1:0]	sobel_swap_b	;

	reg	[8:0]	cnt_we			;

	assign	buffer_controller_raddr_frame_buffer				= raddr_fb	;	//	o
	assign	buffer_controller_we_line_buffer					= we_lb		;	//	o
	assign	buffer_controller_waddr_line_buffer					= waddr_lb	;	//	o
	assign	buffer_controller_raddr_line_buffer					= raddr_lb	;	//	o
	assign	buffer_controller_line_sel_line_buffer				= line_sel	;	//	o
	assign	buffer_controller_we_sobel_frame_buffer				= we_sb		;	//	o
	assign	buffer_controller_waddr_sobel_frame_buffer			= waddr_sb	;	//	x
	assign	buffer_controller_sobel_swap_sobel					= sobel_swap;	//	o

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			cnt_we	<= 0;
		end else begin
			if (raddr_fb > 646) begin
				if (cnt_we == 319) begin
					cnt_we	<= 0;
				end else begin
					cnt_we	<= cnt_we + 1;
				end
			end else begin
				cnt_we	<= 0;
			end
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			waddr_sb <= 0;
		end else begin
			if (raddr_fb > 646) begin
				waddr_sb <= waddr_sb + 1;
			end else begin
				waddr_sb <= 0;
			end
		end
	end

	always @(*) begin
		if (state != IDLE) begin
			if (cnt_we > 317) begin
				we_sb = 1'b0;
			end else begin
				we_sb = 1'b1;
			end
		end else begin
			we_sb = 1'b0;
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			sobel_swap_b	<= 2'b00;
			sobel_swap		<= 2'b00;
		end else begin
			sobel_swap		<= sobel_swap_b;
			if (state == IDLE) begin
				sobel_swap_b <= 2'b00;
			end else if (raddr_lb == 319) begin
				if (sobel_swap_b == 2'b10) begin
					sobel_swap_b <= 2'b00;
				end else begin
					sobel_swap_b <= sobel_swap_b + 1;
				end
			end
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			raddr_lb <= 0;
		end else begin
			if (raddr_fb > 641) begin
				if (raddr_lb == 320 -1) begin
					raddr_lb <= 0;
				end else begin
					raddr_lb <= raddr_lb + 1;
				end
			end else begin
				raddr_lb <= 0;
			end
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			line_sel <= 2'b00;
		end else begin
			if (state == IDLE) begin
				line_sel <= 2'b00;
			end else if (we_lb && (waddr_lb == 320 - 1)) begin
				if (line_sel == 2'b10) begin
					line_sel <= 2'b00;
				end else begin
					line_sel <= line_sel + 1;
				end
			end
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			waddr_lb <= 0;
		end else begin
			if (we_lb) begin
				if (waddr_lb == 320 - 1) begin
					waddr_lb <= 0;
				end else begin
					waddr_lb <= waddr_lb + 1;
				end
			end
		end
	end

	always @(*) begin
		if ((raddr_fb > 0) && (raddr_fb < 76801)) begin
			we_lb = 1'b1;
		end else begin
			we_lb = 1'b0;
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			raddr_fb <= 0;
		end else begin
			if (state == MOVE) begin
				raddr_fb <= raddr_fb + 1;
			end else begin
				raddr_fb <= 0;
			end
		end
	end

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			state	<= IDLE;
		end else begin
			state	<= nstate;
		end
	end

	always @(*) begin
		nstate = state;
		case (state)
			IDLE:	begin
				if (ov_mem_controller_frame_end_buffer_controller) begin
					nstate = MOVE;
				end
			end
			MOVE:	begin
				if (raddr_fb == 76805) begin	//	need to check !!
					nstate = IDLE;
				end
			end
			default:begin
				nstate = IDLE;
			end
		endcase
	end
endmodule
