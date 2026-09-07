`timescale 1ns / 1ps
module stepmotor_controller (
    input wire clk,
    input wire resetn,
    input wire enable,
    input wire dir,
    input wire [19:0] STEP_TICKS, // 100_000_000 / 200 19bit

    output reg [3:0] motor_out
);

    // STEP_HZ = 400이면
    // 1 step = 2.5 ms

    reg [19:0] step_cnt;
    reg [1:0] phase;

    // Step timing
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            step_cnt <= 0;
            phase    <= 0;
        end else begin
            if (!enable) begin
                step_cnt <= 0;
                phase    <= 0;
            end else begin
                if (step_cnt == STEP_TICKS - 1) begin
                    step_cnt <= 0;

                    if (dir) phase <= phase + 1'b1;
                    else phase <= phase - 1'b1;
                end else begin
                    step_cnt <= step_cnt + 1'b1;
                end
            end
        end
    end

    // 28BYJ-48 Half-Step Sequence
    always @(*) begin
        if (!enable) begin
            motor_out = 4'b0000;
        end else begin
            case (phase)
                3'd0: motor_out = 4'b1001;
                3'd1: motor_out = 4'b0011;
                3'd2: motor_out = 4'b0110;
                3'd3: motor_out = 4'b1100;
                default: motor_out = 4'b0000;
                // 3'd0: motor_out = 4'b0001;
                // 3'd1: motor_out = 4'b0011;
                // 3'd2: motor_out = 4'b0010;
                // 3'd3: motor_out = 4'b0110;
                // 3'd4: motor_out = 4'b0100;
                // 3'd5: motor_out = 4'b1100;
                // 3'd6: motor_out = 4'b1000;
                // 3'd7: motor_out = 4'b1001;
                // default: motor_out = 4'b0000;
            endcase
        end
    end

endmodule
