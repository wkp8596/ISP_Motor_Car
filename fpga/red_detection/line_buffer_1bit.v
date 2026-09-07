`timescale 1ns / 1ps

module line_buffer_1bit #(
    parameter integer BIT = 1,
    parameter integer IMG_W = 320,
    parameter integer XW = $clog2(IMG_W)
) (
    input clk,

    input [1:0] red_controller_line_sel_line_buffer,

    input           red_controller_we_line_buffer,
    input [XW-1:0] red_controller_waddr_line_buffer,
    input [BIT-1:0] r_frame_buffer_rdata_line_buffer,

    input [XW-1:0] red_controller_raddr_line_buffer,

    output [BIT-1:0] line_buffer_line_data0_noise_filter,
    output [BIT-1:0] line_buffer_line_data1_noise_filter,
    output [BIT-1:0] line_buffer_line_data2_noise_filter
);
    reg [BIT-1:0] line0_ram[0:IMG_W-1];
    reg [BIT-1:0] line1_ram[0:IMG_W-1];
    reg [BIT-1:0] line2_ram[0:IMG_W-1];

    wire [1:0] sel;
    wire we;
    wire [XW-1:0] waddr;
    wire [BIT-1:0] wdata;
    wire [XW-1:0] raddr;

    reg [BIT-1:0] line_data0;
    reg [BIT-1:0] line_data1;
    reg [BIT-1:0] line_data2;

    assign sel = red_controller_line_sel_line_buffer;
    assign we = red_controller_we_line_buffer;
    assign waddr = red_controller_waddr_line_buffer;
    assign wdata = r_frame_buffer_rdata_line_buffer;
    assign raddr = red_controller_raddr_line_buffer;

    assign line_buffer_line_data0_noise_filter = line_data0;
    assign line_buffer_line_data1_noise_filter = line_data1;
    assign line_buffer_line_data2_noise_filter = line_data2;

    always @(posedge clk) begin
        if (we) begin
            case (sel)
                2'b00: begin
                    line0_ram[waddr] <= wdata;
                end
                2'b01: begin
                    line1_ram[waddr] <= wdata;
                end
                2'b10: begin
                    line2_ram[waddr] <= wdata;
                end
                default: begin

                end
            endcase
        end
    end

    always @(posedge clk) begin
        line_data0 <= line0_ram[raddr];
        line_data1 <= line1_ram[raddr];
        line_data2 <= line2_ram[raddr];
    end
endmodule
