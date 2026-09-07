`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/04 09:21:49
// Design Name: 
// Module Name: uart_arbiter
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

//	x_axis_decoder
//	red_decoder

module uart_arbiter(
	input			uart_busy_arbiter				,
	input			x_decoder_start_arbiter			,
	input	[7:0]	x_decoder_data_arbiter			,
	input			red_decoder_start_arbiter		,
	input	[7:0]	red_decoder_data_arbiter		,
	output			arbiter_busy_red_decoder		,
	output			arbiter_start_uart				,
	output	[7:0]	arbiter_data_uart				 
);
	reg		[7:0]	uart_data;

	reg				uart_start;

	assign arbiter_busy_red_decoder = uart_busy_arbiter;
	assign arbiter_start_uart = uart_start;
	assign arbiter_data_uart = uart_data;

	always @(*) begin
		case ({x_decoder_start_arbiter, red_decoder_start_arbiter})
			2'b00:	begin
				uart_start	= 1'b0;
				uart_data	= 8'h00;
			end
			2'b01:	begin
				uart_start	= 1'b1;
				uart_data	= red_decoder_data_arbiter;
			end
			2'b10:	begin
				uart_start	= 1'b1;
				if (x_decoder_data_arbiter == 8'hff) begin
					uart_data	= 8'hfe;
				end else begin
					uart_data	= x_decoder_data_arbiter;
				end
			end
			2'b11:	begin
				uart_start	= 1'b1;
				uart_data	= red_decoder_data_arbiter;
			end
			default:begin
				uart_start	= 1'b0;
				uart_data	= 8'h00;
			end
		endcase
	end
endmodule
