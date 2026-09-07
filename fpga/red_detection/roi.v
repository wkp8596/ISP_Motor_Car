// next 있는 버전
`timescale 1ns / 1ps

module roi #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter XW = $clog2(IMG_W),  // ADDR WIDTH
    parameter YW = $clog2(IMG_H)
) (
    input  wire               clk,
    input  wire               resetn,
    input  wire               noise_filter_sdata_roi,
    input  wire               red_controller_start_roi,
    output reg                roi_valid_red_decoder,
    output reg                roi_red_found_red_decoder,
    output wire [(XW+YW)-1:0] roi_min_xy_red_decoder,
    output wire [(XW+YW)-1:0] roi_max_xy_red_decoder
);

    reg [XW-1:0] min_x, max_x, x;
    reg [YW-1:0] min_y, max_y, y;

    reg [XW-1:0] min_x_reg, max_x_reg;
    reg [YW-1:0] min_y_reg, max_y_reg;

    reg [XW-1:0] min_x_next, max_x_next;
    reg [YW-1:0] min_y_next, max_y_next;

    reg found_flag;
    reg start_flag;

    assign roi_min_xy_red_decoder = {min_x_reg, min_y_reg};
    assign roi_max_xy_red_decoder = {max_x_reg, max_y_reg};

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            x          <= 0;
            y          <= 0;

            min_x      <= 0;
            max_x      <= 0;
            min_y      <= 0;
            max_y      <= 0;

            found_flag <= 0;

            min_x_reg  <= 0;
            max_x_reg  <= 0;
            min_y_reg  <= 0;
            max_y_reg  <= 0;

            roi_valid_red_decoder  <= 0;
            roi_red_found_red_decoder  <= 0;
            start_flag <= 0;
        end else begin
            roi_valid_red_decoder <= 0;
            roi_red_found_red_decoder <= 0;
            if (red_controller_start_roi) begin
                start_flag <= 1'b1;
            end else if (start_flag) begin
                min_x <= min_x_next;
                max_x <= max_x_next;
                min_y <= min_y_next;
                max_y <= max_y_next;
                roi_valid_red_decoder <= 0;
                roi_red_found_red_decoder <= 0;
                if (noise_filter_sdata_roi) begin
                    found_flag <= 1;
                end
                if ((x == IMG_W - 1) && (y == IMG_H - 1)) begin
                    x <= 0;
                    y <= 0;
                    roi_valid_red_decoder <= 1;
                    if (found_flag || noise_filter_sdata_roi) begin
                        min_x_reg  <= min_x_next;
                        max_x_reg  <= max_x_next;
                        min_y_reg  <= min_y_next;
                        max_y_reg  <= max_y_next;
                        roi_red_found_red_decoder  <= 1'b1;
                        start_flag <= 1'b0;
                    end else begin
                        min_x_reg  <= 0;
                        max_x_reg  <= 0;
                        min_y_reg  <= 0;
                        max_y_reg  <= 0;
                        start_flag <= 0;
                    end
                    found_flag <= 0;
                end else if (x == IMG_W - 1) begin
                    x <= 0;
                    y <= y + 1;
                end else begin
                    x <= x + 1;
                end
            end


        end
    end

    always @(*) begin
        min_x_next = min_x;
        max_x_next = max_x;
        min_y_next = min_y;
        max_y_next = max_y;
        if (noise_filter_sdata_roi) begin
            if (!found_flag) begin
                min_x_next = x;
                max_x_next = x;
                min_y_next = y;
                max_y_next = y;
            end else begin
                if (min_x > x) min_x_next = x;
                if (max_x < x) max_x_next = x;
                if (min_y > y) min_y_next = y;
                if (max_y < y) max_y_next = y;
            end
        end
    end
endmodule

// next 없는 버전
// `timescale 1ns / 1ps

// module ROI #(
//     parameter IMG_W = 320,
//     parameter IMG_H = 240,
//     parameter AW = $clog2(IMG_W * IMG_H),
//     parameter XW = $clog2(IMG_W),  // ADDR WIDTH
//     parameter YW = $clog2(IMG_H)
// ) (
//     input  wire          clk,
//     input  wire          resetn,
//     input  wire          noise_filter_sdata_roi,
//     output wire [AW-1:0] roi_min_xy_red_decoder,
//     output wire [AW-1:0] roi_max_xy_red_decoder
// );
//     reg [XW-1:0] min_x, max_x, x, min_x_reg, max_x_reg, min_x_next, max_x_next;
//     reg [YW-1:0] min_y, max_y, y, min_y_reg, max_y_reg, min_y_next, max_y_next;
//     reg found_flag;

//     assign roi_min_xy_red_decoder = {min_x_reg, min_y_reg};
//     assign roi_max_xy_red_decoder = {max_x_reg, max_y_reg};

//     always @(posedge clk or negedge resetn) begin
//         if (!resetn) begin
//             min_x <= 0;
//             max_x <= 0;
//             min_y <= 0;
//             max_y <= 0;
//             found_flag <= 0;
//             min_x_reg <= 0;
//             max_x_reg <= 0;
//             min_y_reg <= 0;
//             max_y_reg <= 0;
//         end else begin
//             if (noise_filter_sdata_roi) begin
//                 if (!found_flag) begin
//                     min_x      <= x;
//                     max_x      <= x;
//                     min_y      <= y;
//                     max_y      <= y;
//                     x          <= x + 1;
//                     found_flag <= 1;
//                 end else begin
//                     if (min_x > x) begin
//                         min_x <= x;
//                     end
//                     if (max_x < x) begin
//                         max_x <= x;
//                     end
//                     if (min_y > y) begin
//                         min_y <= y;
//                     end
//                     if (max_y < y) begin
//                         max_y <= y;
//                     end
//                     if (x == IMG_W - 1) begin
//                         x <= 0;
//                         y <= y + 1;
//                         if (y == IMG_H - 1) begin
//                             y <= 0;
//                             x <= 0;
//                             found_flag <= 0;
//                             min_x_reg <= min_x;
//                             max_x_reg <= max_x;
//                             min_y_reg <= min_y;
//                             max_y_reg <= max_y;
//                         end
//                     end else begin
//                         x <= x + 1;
//                     end
//                 end
//             end else begin
//                 if (x == IMG_W - 1) begin
//                     x <= 0;
//                     y <= y + 1;
//                     if (y == IMG_H - 1) begin
//                         y <= 0;
//                         x <= 0;
//                         found_flag <= 0;
//                         min_x_reg <= min_x;
//                         max_x_reg <= max_x;
//                         min_y_reg <= min_y;
//                         max_y_reg <= max_y;
//                     end
//                 end else begin
//                     x <= x + 1;
//                 end
//             end
//         end
//     end
// endmodule
