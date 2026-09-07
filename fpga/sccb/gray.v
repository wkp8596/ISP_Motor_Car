`timescale 1ns / 1ps

// module gray_filter (
//     input  logic [11:0] i_rgb,
//     output logic [11:0] o_rgb
// );
//   logic [11:0] y;

//   assign y = 77 * i_rgb[11:8] + 150 * i_rgb[7:4] + 29 * i_rgb[3:0];
//   assign o_rgb = {y[11:8], y[11:8], y[11:8]};

// endmodule

module gray_filter_pipe (
    input clk,
    input resetn,
    input [15:0] ov7670_mem_controller_i_rgb_gray,
    output reg [7:0] gray_o_rgb_frame_buffer
);
  localparam LATENCY = 2;

  // stage 1 -> 곱셈
  reg [11:0] s1_r, s1_g, s1_b, s1_rgb;

  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      s1_r   <= 0;
      s1_g   <= 0;
      s1_b   <= 0;
      s1_rgb <= 0;
    end else begin
      s1_r   <= 8'd77 * ov7670_mem_controller_i_rgb_gray[15:11];
      s1_g   <= 8'd150 * ov7670_mem_controller_i_rgb_gray[10:5];
      s1_b   <= 8'd29 * ov7670_mem_controller_i_rgb_gray[4:0];
      s1_rgb <= ov7670_mem_controller_i_rgb_gray;
    end
  end

  // stage 2 -> 덧셈 & shift 연산 & mux
  wire [15:0] y_sum;
  wire [ 3:0] gray;

  assign y_sum = s1_r + s1_g + s1_b;
  assign gray  = y_sum[15:11];  //

  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      gray_o_rgb_frame_buffer <= 0;
    end else begin
      gray_o_rgb_frame_buffer <= {gray, 4'b0000};
    end
  end


endmodule
