
`timescale 1ns / 1ps

module VGA_Decoder (
    input  clk,
    input  rst_n,

    output vga_decoder_hsync_vga_ff,
    output vga_decoder_vsync_vga_ff,
    output [9:0] vga_decoder_x_axis_frame_reader,
    output [9:0] vga_decoder_y_axis_frame_reader,
    output vga_decoder_de_frame_reader
);

wire pclk;
wire [9:0] h_count;
wire [9:0] v_count;

pclk_gen u_pclk_gen (
    .clk(clk),
    .rst_n(rst_n),
    .pclk(pclk)
);

pixel_counter u_pixel_counter (
    .clk(clk),
    .rst_n(rst_n),
    .pclk(pclk),
    .h_count(h_count),
    .v_count(v_count)
);

vga_decoder u_vga_decoder (
    .h_count(h_count),
    .v_count(v_count),
    .h_sync(vga_decoder_hsync_vga_ff),
    .v_sync(vga_decoder_vsync_vga_ff),
    .x_pixel(vga_decoder_x_axis_frame_reader),
    .y_pixel(vga_decoder_y_axis_frame_reader),
    .de(vga_decoder_de_frame_reader)
);

endmodule

module pclk_gen (
    input  clk,
    input  rst_n,
    output reg pclk
);

reg [1:0] p_counter;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      p_counter <= 2'b00;
      pclk <= 1'b0;
    end else begin
      if (p_counter == 2'd3) begin
        p_counter <= 2'b00;
        pclk <= 1'b1;
      end else begin
        p_counter <= p_counter + 1'b1;
        pclk <= 1'b0;
      end
    end
  end


endmodule

module pixel_counter (
    input clk,
    input rst_n,
    input pclk,

    output reg [9:0] h_count,
    output reg [9:0] v_count
);

    localparam H_MAX = 799;
    localparam V_MAX = 524;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else if (pclk) begin
            if (h_count == H_MAX) begin
                h_count <= 10'd0;

                if (v_count == V_MAX)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1'b1;
            end
            else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

endmodule


module vga_decoder (
    input [9:0] h_count,
    input [9:0] v_count,
    output h_sync,
    output v_sync,
    output [9:0] x_pixel,
    output [9:0] y_pixel,
    output de
);

  assign x_pixel = h_count;
  assign y_pixel = v_count;
  assign h_sync = (h_count >= 656 && h_count < 752) ? 1'b0 : 1'b1;
  assign v_sync = (v_count >= 490 && v_count < 492) ? 1'b0 : 1'b1;
  assign de = (h_count < 640 && v_count < 480) ? 1'b1 : 1'b0;

  /*
    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam H_Sync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;

    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_frame = 525;
    */

endmodule
