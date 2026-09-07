`timescale 1ns / 1ps

module noise_filter #(
    parameter BIT = 1,
    parameter THRESHOLD = 9
) (
    input           clk,
    input           resetn,
    input [BIT-1:0] line_buffer_line_data0_noise_filter,
    input [BIT-1:0] line_buffer_line_data1_noise_filter,
    input [BIT-1:0] line_buffer_line_data2_noise_filter,

    input [1:0] red_controller_swap_noise_filter,

    output noise_filter_sdata_roi
);
    reg [BIT-1:0] line0[0:2];
    reg [BIT-1:0] line1[0:2];
    reg [BIT-1:0] line2[0:2];

    wire [BIT-1:0] line0_input;
    wire [BIT-1:0] line1_input;
    wire [BIT-1:0] line2_input;

    wire [4:0] gaussian_sum;

    /* 
    p00 + 2*p01 + p02
    +2*p10 + 4*p11 + 2*p12
    +p20 + 2*p21 + p22
    */
    assign gaussian_sum =
      {4'b0000, line0[0]}
    + {3'b000,  line0[1], 1'b0}
    + {4'b0000, line0[2]}

    + {3'b000,  line1[0], 1'b0}
    + {2'b00,   line1[1], 2'b00}
    + {3'b000,  line1[2], 1'b0}

    + {4'b0000, line2[0]}
    + {3'b000,  line2[1], 1'b0}
    + {4'b0000, line2[2]};

    /*
        0~9  → 0
        10~16 → 1
    */
    assign noise_filter_sdata_roi = (gaussian_sum > THRESHOLD) ? 1'b1 : 1'b0;

    mux_4_1 #(
        .BIT(1)
    ) U_MUX_LINE0 (
        .in0(line_buffer_line_data0_noise_filter),
        .in1(line_buffer_line_data1_noise_filter),
        .in2(line_buffer_line_data2_noise_filter),
        .in3(1'b0),
        .sel(red_controller_swap_noise_filter),
        .out(line0_input)
    );
    mux_4_1 #(
        .BIT(1)
    ) U_MUX_LINE1 (
        .in0(line_buffer_line_data1_noise_filter),
        .in1(line_buffer_line_data2_noise_filter),
        .in2(line_buffer_line_data0_noise_filter),
        .in3(1'b0),
        .sel(red_controller_swap_noise_filter),
        .out(line1_input)
    );

    mux_4_1 #(
        .BIT(1)
    ) U_MUX_LINE2 (
        .in0(line_buffer_line_data2_noise_filter),
        .in1(line_buffer_line_data0_noise_filter),
        .in2(line_buffer_line_data1_noise_filter),
        .in3(1'b0),
        .sel(red_controller_swap_noise_filter),
        .out(line2_input)
    );

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            line0[2] <= 1'b0;
            line0[1] <= 1'b0;
            line0[0] <= 1'b0;
            line1[2] <= 1'b0;
            line1[1] <= 1'b0;
            line1[0] <= 1'b0;
            line2[2] <= 1'b0;
            line2[1] <= 1'b0;
            line2[0] <= 1'b0;
        end else begin
            line0[2] <= line0[1];
            line0[1] <= line0[0];
            line0[0] <= line0_input;
            line1[2] <= line1[1];
            line1[1] <= line1[0];
            line1[0] <= line1_input;
            line2[2] <= line2[1];
            line2[1] <= line2[0];
            line2[0] <= line2_input;
        end
    end
endmodule

module mux_4_1 #(
    parameter BIT = 1
) (
    input [BIT-1:0] in0,
    input [BIT-1:0] in1,
    input [BIT-1:0] in2,
    input [BIT-1:0] in3,
    input [1:0] sel,
    output [BIT-1:0] out
);
    reg [BIT-1:0] out_r;
    assign out = out_r;
    always @(*) begin
        case (sel)
            2'b00:   out_r = in0;
            2'b01:   out_r = in1;
            2'b10:   out_r = in2;
            2'b11:   out_r = in3;
            default: out_r = 1'bx;
        endcase
    end
endmodule

