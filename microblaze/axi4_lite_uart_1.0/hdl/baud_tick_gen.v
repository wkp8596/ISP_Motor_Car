`timescale 1ns / 1ps

module baud_tick_gen (
    input  wire        clk,
    input  wire        resetn,
    input  wire [15:0] baud_div,
    output reg         o_b_tick
);
    // localparam F_COUNT = 100_000_000 / (9600 * 16); // 주파수를 16배 올릴거라서 * 16 : 651까지임
    // localparam WIDTH = $clog2(F_COUNT);

    reg [15:0] counter_reg;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            counter_reg <= 0;
            o_b_tick    <= 0;
        end else begin
            if (baud_div == 0) begin
                counter_reg <= 0;
                o_b_tick <= 1'b0;
            end else if (counter_reg >= baud_div - 16'd1) begin
                counter_reg <= 0;
                o_b_tick <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1'b1;
                o_b_tick <= 1'b0;
            end
        end
    end
endmodule
