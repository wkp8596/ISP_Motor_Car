`timescale 1ns / 1ps

module ov7670_mem_controller #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW = 16,  // DATA WIDTH
    parameter AW = $clog2(IMG_W * IMG_H)  // ADDR WIDTH
) (
    input               clk,
    input               resetn,
    input               ov7670_pclk_ov_mem_controller,
    input               ov7670_cam_href_ov_mem_controller,
    input               ov7670_cam_vsync_ov_mem_controller,
    input      [   7:0] ov7670_cam_data_ov_mem_controller,
    output reg          ov_mem_controller_we_frame_buffer,
    output reg [AW-1:0] ov_mem_controller_wAddr_frame_buffer,
    output     [DW-1:0] ov_mem_controller_wData_gray,
    output reg          ov_mem_controller_frame_end_buffer_controller,
    output              ov_mem_controller_xclk_ov7670
);
  reg byteSel;
  reg [15:0] px_data;
  reg sync_pclk, sync_href, sync_vsync;
  reg [7:0] sync_cam_data;
  assign ov_mem_controller_wData_gray = px_data;

  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      sync_pclk <= 0;
      sync_href <= 0;
      sync_vsync <= 0;
      sync_cam_data <= 0;
    end else begin
      sync_pclk <= ov7670_pclk_ov_mem_controller;
      sync_href <= ov7670_cam_href_ov_mem_controller;
      sync_vsync <= ov7670_cam_vsync_ov_mem_controller;
      sync_cam_data <= ov7670_cam_data_ov_mem_controller;
    end
  end


  always @(posedge sync_pclk, negedge resetn) begin
    if (!resetn) begin
      ov_mem_controller_wAddr_frame_buffer <= 0;
      byteSel <= 1'b0;
      px_data <= 0;
      ov_mem_controller_we_frame_buffer <= 1'b0;
      ov_mem_controller_frame_end_buffer_controller <= 1'b0;
    end else begin
      ov_mem_controller_we_frame_buffer <= 1'b0;
	  ov_mem_controller_frame_end_buffer_controller <= 1'b0;
      if (ov_mem_controller_we_frame_buffer)
        ov_mem_controller_wAddr_frame_buffer <= ov_mem_controller_wAddr_frame_buffer + 1;
      if (sync_vsync) begin
        ov_mem_controller_wAddr_frame_buffer <= 0;
        byteSel <= 1'b0;
        ov_mem_controller_frame_end_buffer_controller <= 1'b1;
      end
      else if (sync_href) begin // vsync와 href는 같이 동작하면 안됨 타이밍상으로
        byteSel <= ~byteSel;
        if (!byteSel) begin	// ! delete
          px_data[15:8] <= sync_cam_data;
        end else begin
          px_data[7:0] <= sync_cam_data;
          ov_mem_controller_we_frame_buffer <= 1'b1;
        end
      end
    end
  end

  xclk_gen U_xclk_gen (  //pixel clock generator
      .clk(clk),
      .resetn(resetn),
      .pclk(ov_mem_controller_xclk_ov7670)
  );

endmodule

module xclk_gen (  //pixel clock generator
    input clk,
    input resetn,
    output reg pclk
);
  reg [1:0] p_counter;  //25MHz pixel clock from 100MHz -> 4분주

  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      p_counter <= 2'b00;
      pclk <= 1'b0;
    end else begin
      if (p_counter == 2'b11) begin
        p_counter <= 2'b00;
        pclk <= 1'b1;
      end else begin
        p_counter <= p_counter + 1;
        pclk <= 1'b0;
      end
    end
  end

endmodule
