`timescale 1ns / 1ps

module sccb_top (
		input        clk,
    input        resetn,
    //sccb
    input        button_i_btn_sccb,
    output       sccb_scl_ov7670,
    inout        sccb_sda_ov7670,
    //ov_mem_controller
    input        ov7670_pclk_ov_mem_controller,
    input        ov7670_cam_href_ov_mem_controller,
    input        ov7670_cam_vsync_ov_mem_controller,
    input  [7:0] ov7670_cam_data_ov_mem_controller,
    output       ov_mem_controller_frame_end_buffer_controller,
    output       ov_mem_controller_xclk_ov7670,

    //frame_buffer
    input  [16:0] buffer_controller_rAddr_frame_buffer,
    output [ 7:0] frame_buffer_wData_line_buffer,

    output [16:0] sccb_wAddr_red_filter,
    output [15:0] sccb_wData_red_filter,
    output        sccb_we_red_filter
);

  wire w_ov_mem_controller_we_2stage_pipe_line, w_2stage_pipe_line_we_frame_buffer;
  wire [15:0] w_ov7670_mem_controller_i_rgb_gray;
  wire [16:0] w_ov_mem_controller_wAddr_2stage_pipe_line, w_2stage_pipe_line_wAddr_frame_buffer;
  wire [7:0] w_gray_rgb_frame_buffer;

  assign sccb_we_red_filter    = w_ov_mem_controller_we_2stage_pipe_line;
  assign sccb_wAddr_red_filter = w_ov_mem_controller_wAddr_2stage_pipe_line;
  assign sccb_wData_red_filter = w_ov7670_mem_controller_i_rgb_gray;

  sccb U_sccb (
      .clk              (clk),
      .resetn           (resetn),
      .button_i_btn_sccb(button_i_btn_sccb),
      .sccb_scl_ov7670  (sccb_scl_ov7670),
      .sccb_sda_ov7670  (sccb_sda_ov7670)
  );

  ov7670_mem_controller U_ov7670_mem_controller (
      .clk(clk),
      .resetn(resetn),
      .ov7670_pclk_ov_mem_controller(ov7670_pclk_ov_mem_controller),
      .ov7670_cam_href_ov_mem_controller(ov7670_cam_href_ov_mem_controller),
      .ov7670_cam_vsync_ov_mem_controller(ov7670_cam_vsync_ov_mem_controller),
      .ov7670_cam_data_ov_mem_controller(ov7670_cam_data_ov_mem_controller),
      .ov_mem_controller_we_frame_buffer(w_ov_mem_controller_we_2stage_pipe_line),
      .ov_mem_controller_wAddr_frame_buffer(w_ov_mem_controller_wAddr_2stage_pipe_line),
      .ov_mem_controller_wData_gray(w_ov7670_mem_controller_i_rgb_gray),
      .ov_mem_controller_frame_end_buffer_controller(ov_mem_controller_frame_end_buffer_controller),
      .ov_mem_controller_xclk_ov7670(ov_mem_controller_xclk_ov7670)
  );

  gray_filter_pipe U_gray_filter_pipe (
      .clk                             (clk),
      .resetn                          (resetn),
      .ov7670_mem_controller_i_rgb_gray(w_ov7670_mem_controller_i_rgb_gray),
      .gray_o_rgb_frame_buffer         (w_gray_rgb_frame_buffer)
  );

  stage2_pipe_sync_we U_stage2_pipe_sync_WE (
      .clk   (clk),
      .resetn(resetn),
      .i_data(w_ov_mem_controller_we_2stage_pipe_line),
      .o_data(w_2stage_pipe_line_we_frame_buffer)
  );

  stage2_pipe_sync_wAddr U_stage2_pipe_sync_wAddr (
      .clk   (clk),
      .resetn(resetn),
      .i_data(w_ov_mem_controller_wAddr_2stage_pipe_line),
      .o_data(w_2stage_pipe_line_wAddr_frame_buffer)
  );

  frame_buffer U_frame_buffer (
      .clk                                 (clk),
      .resetn                              (resetn),
      .ov7670_pclk_frame_buffer            (ov7670_pclk_ov_mem_controller),
      .ov_mem_controller_we_frame_buffer   (w_2stage_pipe_line_we_frame_buffer),
      .gray_gray_frame_buffer              (w_gray_rgb_frame_buffer),
      .ov_mem_controller_wAddr_frame_buffer(w_2stage_pipe_line_wAddr_frame_buffer),
      .buffer_controller_rAddr_frame_buffer(buffer_controller_rAddr_frame_buffer),
      .frame_buffer_wData_line_buffer      (frame_buffer_wData_line_buffer)
  );

endmodule

module stage2_pipe_sync_wAddr (
    input             clk,
    input             resetn,
    input      [16:0] i_data,
    output reg [16:0] o_data
);

  reg [16:0] sync1;

  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      o_data <= 0;
      sync1  <= 0;
    end else begin
      sync1  <= i_data;
      o_data <= sync1;
    end
  end

endmodule

module stage2_pipe_sync_we (
    input      clk,
    input      resetn,
    input      i_data,
    output reg o_data
);

  reg sync1;

  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      o_data <= 0;
      sync1  <= 0;
    end else begin
      sync1  <= i_data;
      o_data <= sync1;
    end
  end

endmodule
