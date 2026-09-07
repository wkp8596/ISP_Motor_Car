`timescale 1ns / 1ps

module red_decoder #(
    parameter MIN_RED_WIDTH_W = 10,
    parameter MIN_RED_WIDTH_H = 10,
    parameter VGA_X_FRAME_LOW = 100,
    parameter VGA_X_FRAME_HIGH = 200,
    parameter VGA_Y_FRAME_LOW = 80,
    parameter VGA_Y_FRAME_HIGH = 160,
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter AW = $clog2(IMG_W * IMG_H),
    parameter XW = $clog2(IMG_W),  // ADDR WIDTH
    parameter YW = $clog2(IMG_H)
) (
    input wire clk,
    input wire resetn,

    input wire [(XW+YW)-1:0] roi_min_xy_red_decoder,
    input wire [(XW+YW)-1:0] roi_max_xy_red_decoder,

    input wire roi_valid_red_decoder,
    input wire roi_red_found_red_decoder,

    output reg        start,
    output reg  [7:0] tx_data,
    input  wire       tx_busy
);
    // state
    localparam IDLE = 3'd0;
    localparam TAKE = 3'd1;
    localparam WAIT = 3'd2;
    localparam SEND = 3'd3;
    localparam WAIT_UNRED = 3'd4;
    reg [2:0] state;

    // x,y로 들어오는 좌표 분리
    wire [XW-1:0] min_x;
    wire [XW-1:0] max_x;
    wire [YW-1:0] min_y;
    wire [YW-1:0] max_y;

    assign min_x = roi_min_xy_red_decoder[(XW+YW)-1:YW];
    assign min_y = roi_min_xy_red_decoder[YW-1:0];
    assign max_x = roi_max_xy_red_decoder[(XW+YW)-1:YW];
    assign max_y = roi_max_xy_red_decoder[YW-1:0];

    // red_detect를 위해 x_width, y_width 추출
    wire [XW-1:0] x_width;
    wire [YW-1:0] y_width;
    wire          red_detect;

    assign x_width = max_x - min_x + 1;
    assign y_width = max_y - min_y + 1;

    assign red_detect = ((x_width >= MIN_RED_WIDTH_W) && (y_width >= MIN_RED_WIDTH_H));

    // 들어오는 좌표의 center 계산
    wire [XW-1:0] center_x;
    wire [YW-1:0] center_y;

    assign center_x = min_x + ((max_x - min_x) >> 1);
    assign center_y = min_y + ((max_y - min_y) >> 1);

    // vga 화면의 중심 범위에서 red detect 감지
    wire vga_center_detect;

    assign vga_center_detect = ((center_x >= VGA_X_FRAME_LOW)&&(center_x <= VGA_X_FRAME_HIGH)&&(center_y >= VGA_Y_FRAME_LOW)&&(center_y <= VGA_Y_FRAME_HIGH));

    // state
    reg [7:0] tx_data_reg;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE;
            start <= 1'b0;
            tx_data <= 8'd0;
            tx_data_reg <= 8'd0;
        end else begin
            start <= 1'b0;
            case (state)
                IDLE: begin
                    start <= 1'b0;
                    tx_data <= 8'd0;
                    tx_data_reg <= 8'd0;
                    if (roi_valid_red_decoder && roi_red_found_red_decoder && red_detect && vga_center_detect) begin
                        state <= TAKE;
                    end
                end
                TAKE: begin
                    tx_data_reg <= 8'hff;
                    if (!tx_busy) begin
                        state <= SEND;
                    end else begin
                        state <= WAIT;
                    end
                end
                WAIT: begin
                    if (!tx_busy) begin
                        state <= SEND;
                    end
                end
                SEND: begin
                    tx_data <= tx_data_reg;
                    start   <= 1'b1;
                    state   <= WAIT_UNRED;
                end
                WAIT_UNRED: begin
                    start <= 1'b1;
                    if (roi_valid_red_decoder && !red_detect) begin
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
