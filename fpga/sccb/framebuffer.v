`timescale 1ns / 1ps

module frame_buffer #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW = 8,  // DATA WIDTH
    parameter AW = $clog2(IMG_W * IMG_H)  // ADDR WIDTH
) (
    // write side (camera, pclk)
    input clk,
    input resetn,
    input ov7670_pclk_frame_buffer,
    input ov_mem_controller_we_frame_buffer,
    input [DW-1:0] gray_gray_frame_buffer,
    input [AW-1:0] ov_mem_controller_wAddr_frame_buffer,
    input [AW-1:0] buffer_controller_rAddr_frame_buffer,
    output reg [DW-1:0] frame_buffer_wData_line_buffer
);

  reg [DW-1:0] mem[0:IMG_W*IMG_H-1];

  reg sync_pclk;

  always @(posedge clk, negedge resetn) begin
      if (!resetn) begin
        sync_pclk <= 0;
      end else begin
        sync_pclk <= ov7670_pclk_frame_buffer;
      end
  end


  //write
  always @(posedge sync_pclk) begin  //mem은 원래 rst 없음
    if (ov_mem_controller_we_frame_buffer) begin
      mem[ov_mem_controller_wAddr_frame_buffer] <= gray_gray_frame_buffer;
    end
  end

  //read
  always @(posedge clk) begin
    frame_buffer_wData_line_buffer <= mem[buffer_controller_rAddr_frame_buffer];
  end

endmodule
